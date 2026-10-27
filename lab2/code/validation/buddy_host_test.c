/* Host-side tests include the REAL implementation and real ucore headers.
 * Only console/panic and the platform's global memory descriptors are stubbed.
 * This file is not installed into or compiled by the kernel project. */
#include "../kern/mm/buddy_pmm.c"

extern int vprintf(const char *, va_list);
extern int printf(const char *, ...);
extern void exit(int) __attribute__((noreturn));

#define TEST_PAGES 512
static struct Page descriptors[TEST_PAGES];
struct Page *pages = descriptors;
size_t npage;
const size_t nbase = 0x80000;
uint64_t va_pa_offset;
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

struct Page *alloc_pages(size_t n) { return pmm_manager->alloc_pages(n); }
void free_pages(struct Page *base, size_t n) { pmm_manager->free_pages(base, n); }
size_t nr_free_pages(void) { return pmm_manager->nr_free_pages(); }

static void reset(void) {
    npage = nbase + TEST_PAGES;
    buddy_init();
    for (size_t i = 0; i < TEST_PAGES; i++) {
        descriptors[i].flags = 0;
        SetPageReserved(&descriptors[i]);
        descriptors[i].property = 0;
        set_page_ref(&descriptors[i], 0);
        list_init(&descriptors[i].page_link);
    }
}

static void bounds_and_tail_tests(void) {
    size_t cases = 0;
    for (size_t start = 0; start < 32; start++) {
        for (size_t length = 1; length <= 65; length++) {
            reset();
            buddy_init_memmap(pages + start, length);
            assert(nr_free_pages() == length);
            buddy_validate();
            struct Page *allocated[65];
            unsigned int seen[TEST_PAGES] = {0};
            for (size_t i = 0; i < length; i++) {
                struct Page *p = alloc_page();
                assert(p != NULL);
                size_t index = p - pages;
                assert(index >= start && index < start + length);
                assert(seen[index]++ == 0);
                allocated[i] = p;
            }
            assert(alloc_page() == NULL && nr_free_pages() == 0);
            buddy_validate();
            for (size_t i = length; i > 0; i--) {
                free_page(allocated[i - 1]);
            }
            assert(nr_free_pages() == length);
            buddy_validate();
            for (size_t i = 0; i < TEST_PAGES; i++) {
                if (i < start || i >= start + length) {
                    assert(PageReserved(pages + i));
                }
            }
            cases++;
        }
    }
    printf("HOST: %llu alignment/tail cases passed\n", (unsigned long long)cases);
}

static void registration_tests(void) {
    reset();
    buddy_init_memmap(pages + 5, 7);
    buddy_init_memmap(pages + 12, 20); /* Adjacent registration must coalesce. */
    buddy_init_memmap(pages + 50, 79); /* Reserved hole must remain untouched. */
    buddy_init_memmap(pages + 511, 1); /* Final descriptor must be usable. */
    assert(nr_free_pages() == 107);
    buddy_validate();
    buddy_check();
    assert(nr_free_pages() == 107);
    assert(PageReserved(pages + 4));
    assert(PageReserved(pages + 32));
    assert(PageReserved(pages + 49));
    assert(PageReserved(pages + 129));
    assert(PageReserved(pages + 510));
    printf("HOST: adjacent maps, holes and last descriptor passed\n");
}

static unsigned int random_state = 0x5f372a91;
static unsigned int next_random(void) {
    random_state = random_state * 1664525U + 1013904223U;
    return random_state;
}

static void randomized_tests(void) {
    reset();
    buddy_init_memmap(pages + 3, 333);
    struct Page *live[128] = {0};
    size_t requests[128] = {0};
    unsigned int occupied[TEST_PAGES] = {0};
    for (unsigned int step = 0; step < 20000; step++) {
        unsigned int slot = (next_random() >> 16) % 128;
        if (live[slot] != NULL) {
            unsigned int order;
            assert(buddy_request_order(requests[slot], &order));
            size_t size = buddy_block_size(order), index = live[slot] - pages;
            for (size_t j = 0; j < size; j++) {
                assert(occupied[index + j] == 1);
                occupied[index + j] = 0;
            }
            free_pages(live[slot], requests[slot]);
            live[slot] = NULL;
        } else {
            size_t request = 1 + ((next_random() >> 16) % 35);
            size_t before = nr_free_pages();
            struct Page *p = alloc_pages(request);
            if (p == NULL) {
                assert(nr_free_pages() == before);
            } else {
                unsigned int order;
                assert(buddy_request_order(request, &order));
                size_t size = buddy_block_size(order), index = p - pages;
                assert(index >= 3 && index + size <= 336);
                for (size_t j = 0; j < size; j++) {
                    assert(occupied[index + j] == 0);
                    occupied[index + j] = 1;
                }
                assert(nr_free_pages() == before - size);
                live[slot] = p;
                requests[slot] = request;
            }
        }
        if (step % 97 == 0) {
            buddy_validate();
        }
    }
    for (unsigned int i = 0; i < 128; i++) {
        if (live[i] != NULL) {
            free_pages(live[i], requests[i]);
        }
    }
    assert(nr_free_pages() == 333);
    buddy_validate();
    buddy_check();
    printf("HOST: 20000 randomized operations passed\n");
}

int main(int argc, char **argv) {
    if (argc > 1) {
        reset();
        buddy_init_memmap(pages + 3, 333);
        struct Page *p = alloc_pages(3);
        assert(p != NULL);
        switch (argv[1][0]) {
        case 'n': free_pages(p, 4); break; /* Same rounded size, wrong original n. */
        case 'p': free_pages(p + 1, 1); break; /* Partial free of an interior page. */
        case 'd': free_pages(p, 3); free_pages(p, 3); break;
        case 'r': free_pages(pages, 1); break; /* Reserved descriptor. */
        case 'z': free_pages(p, 0); break;
        case 'b': free_pages(pages + TEST_PAGES, 1); break;
        default: return 2;
        }
        printf("ERROR: invalid free was accepted\n");
        return 1;
    }
    bounds_and_tail_tests();
    registration_tests();
    randomized_tests();
    printf("HOST: all valid-operation tests passed\n");
    return 0;
}
