/* Supplemental userspace test of the real Buddy and SLUB implementations.
 * Only the kernel's high virtual mapping and console/platform plumbing are
 * adapted. Real pmm.h conversions are separately exercised by QEMU tests.
 * Every returned Buddy block is readable/writable; every freed block becomes
 * PROT_NONE immediately, detecting accesses to released slab metadata. */
#include "../kern/mm/buddy_pmm.c"

extern int printf(const char *, ...);
extern int vprintf(const char *, va_list);
extern void exit(int) __attribute__((noreturn));
extern void *mmap(void *, unsigned long, int, int, int, long);
extern int mprotect(void *, unsigned long, int);
extern int munmap(void *, unsigned long);

#define HOST_PAGES 1024
#define HOST_START 512
static struct Page host_descriptors[HOST_PAGES];
static unsigned char *host_arena;
struct Page *pages = host_descriptors;
size_t npage;
const size_t nbase = 0x80000;
uint64_t va_pa_offset = PHYSICAL_MEMORY_OFFSET;
const struct pmm_manager *pmm_manager = &buddy_pmm_manager;

int cprintf(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    int result = vprintf(fmt, ap);
    __builtin_va_end(ap);
    return result;
}

void __panic(const char *file, int line, const char *fmt, ...) {
    printf("PANIC %s:%d: ", file, line);
    va_list ap;
    va_start(ap, fmt);
    vprintf(fmt, ap);
    __builtin_va_end(ap);
    printf("\n");
    exit(73);
}

struct Page *alloc_pages(size_t n) {
    struct Page *page = buddy_alloc_pages(n);
    if (page != NULL) {
        unsigned int order;
        assert(buddy_request_order(n, &order));
        assert(mprotect(host_arena + (page - pages) * PGSIZE,
                        buddy_block_size(order) * PGSIZE, 3) == 0);
    }
    return page;
}

void free_pages(struct Page *page, size_t n) {
    unsigned int order;
    assert(buddy_request_order(n, &order));
    unsigned char *address = host_arena + (page - pages) * PGSIZE;
    size_t bytes = buddy_block_size(order) * PGSIZE;
    buddy_free_pages(page, n);
    assert(mprotect(address, bytes, 0) == 0);
}

size_t nr_free_pages(void) { return buddy_nr_free_pages(); }

static void *host_page2kva(struct Page *page) {
    size_t index = buddy_page_index(page);
    return host_arena + index * PGSIZE;
}

static struct Page *host_kva2page(void *address) {
    uintptr_t value = (uintptr_t)address, start = (uintptr_t)host_arena;
    assert(value >= start && value - start < HOST_PAGES * PGSIZE);
    return &pages[(value - start) / PGSIZE];
}

#define page2kva host_page2kva
#define kva2page host_kva2page
#undef KADDR
#undef PADDR
#define KADDR(pa) ((void *)(host_arena + ((uintptr_t)(pa) - (nbase << PGSHIFT))))
#define PADDR(kva) ((uintptr_t)(kva) - (uintptr_t)host_arena + (nbase << PGSHIFT))
#include "../kern/mm/slub.c"

static unsigned int random_state = 0x1937a28b;
static unsigned int next_random(void) {
    random_state = random_state * 1664525U + 1013904223U;
    return random_state;
}

static void random_test(void) {
    void *live[96] = {0};
    size_t sizes[96] = {0};
    unsigned char values[96] = {0};
    size_t initial = nr_free_pages();
    unsigned int failures = 0;
    for (unsigned int step = 0; step < 12000; step++) {
        unsigned int slot = (next_random() >> 16) % 96;
        if (live[slot] != NULL) {
            slub_test_read(live[slot], sizes[slot], values[slot]);
            kfree(live[slot]);
            live[slot] = NULL;
        } else {
            size_t size = 1 + ((next_random() >> 16) % 16000);
            size_t before = nr_free_pages();
            void *object = kmalloc(size);
            if (object == NULL) {
                assert(nr_free_pages() == before);
                failures++;
            } else {
                assert(((uintptr_t)object & 15) == 0);
                for (unsigned int j = 0; j < 96; j++) {
                    if (live[j] != NULL) {
                        uintptr_t a = (uintptr_t)object, b = (uintptr_t)live[j];
                        assert(a < b ? size <= b - a : sizes[j] <= a - b);
                    }
                }
                live[slot] = object;
                sizes[slot] = size;
                values[slot] = (unsigned char)next_random();
                memset(object, values[slot], size);
            }
        }
        if (step % 127 == 0) {
            slub_validate();
            buddy_validate();
            for (unsigned int j = 0; j < 96; j++) {
                if (live[j] != NULL) {
                    slub_test_read(live[j], sizes[j], values[j]);
                }
            }
        }
    }
    for (unsigned int j = 0; j < 96; j++) {
        if (live[j] != NULL) {
            slub_test_read(live[j], sizes[j], values[j]);
            kfree(live[j]);
        }
    }
    assert(nr_free_pages() == initial);
    slub_validate();
    buddy_validate();
    printf("HOST: 12000 random SLUB operations passed (%u allocation failures)\n", failures);
}

int main(int argc, char **argv) {
    npage = nbase + HOST_PAGES;
    host_arena = mmap(NULL, HOST_PAGES * PGSIZE, 0, 0x22, -1, 0);
    assert(host_arena != (void *)-1);
    buddy_init();
    for (size_t i = 0; i < HOST_PAGES; i++) {
        pages[i].flags = 0;
        SetPageReserved(pages + i);
        pages[i].property = 0;
        set_page_ref(pages + i, 0);
        list_init(&pages[i].page_link);
    }
    buddy_init_memmap(pages + HOST_START, HOST_PAGES - HOST_START);
    size_t initial = nr_free_pages();
    slub_init();
    assert(nr_free_pages() == initial);
    if (argc > 1) {
        void *p = kmalloc(32), *q = kmalloc(32);
        assert(p != NULL && q != NULL);
        switch (argv[1][0]) {
        case 's': kfree((char *)p + 1); break;
        case 'd': kfree(p); kfree(p); break; /* Slab still has q. */
        case 'f': kfree(p); kfree(q); kfree(p); break; /* Header is PROT_NONE. */
        case 'l': p = kmalloc(8192); kfree((char *)p + 16); break;
        case 'b': p = kmalloc(8192); kfree(p); kfree(p); break;
        case 'i': kfree((void *)1); break;
        default: return 2;
        }
        printf("ERROR: invalid free accepted\n");
        return 1;
    }
    slub_check();
    buddy_validate();
    random_test();
    assert(nr_free_pages() == initial);
    assert(munmap(host_arena, HOST_PAGES * PGSIZE) == 0);
    printf("HOST: no access to PROT_NONE freed pages; all pages restored\n");
    return 0;
}
