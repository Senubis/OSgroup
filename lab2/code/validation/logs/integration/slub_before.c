#include <slub.h>
#include <buddy_pmm.h>
#include <list.h>
#include <stdio.h>
#include <string.h>

#define SLUB_CLASSES 8
#define SLUB_MIN_SIZE 16
#define SLUB_MAX_SIZE 2048
#define SLUB_BITMAP_WORDS 4
#define SLUB_MAGIC 0x534c55424c414232ULL

/* All metadata is BEFORE the payload. Even a 2048-byte slot has its full
 * promised capacity; no per-object header is hidden inside that capacity.
 * The same page-local header records the original Buddy n for large objects.
 * No allocation metadata uses kmalloc or changes struct Page. */
struct slub_block {
    uint64_t magic;
    list_entry_t link;
    struct Page *page;
    size_t npages;
    size_t capacity;
    unsigned int class_index;
    unsigned int slots;
    unsigned int inuse;
    uint64_t used[SLUB_BITMAP_WORDS];
};

#define SLUB_DATA_OFFSET ((sizeof(struct slub_block) + 15) & ~(size_t)15)

struct slub_cache {
    size_t capacity;
    list_entry_t slabs;
};

static struct slub_cache slub_caches[SLUB_CLASSES];
static list_entry_t slub_large;
static bool slub_ready;

static void *
slub_payload(struct slub_block *block) {
    return (char *)block + SLUB_DATA_OFFSET;
}

static bool
slub_slot_used(struct slub_block *block, unsigned int slot) {
    return (block->used[slot / 64] & ((uint64_t)1 << (slot % 64))) != 0;
}

/* Check the addition BEFORE doing it; avoid overflow in ceil(bytes/PGSIZE).
 * Buddy handles rounding npages and returning NULL for insufficient blocks. */
static bool
slub_large_pages(size_t size, size_t *npages) {
    if (size > (size_t)-1 - SLUB_DATA_OFFSET) {
        return 0;
    }
    size_t bytes = size + SLUB_DATA_OFFSET;
    *npages = bytes / PGSIZE + (bytes % PGSIZE != 0);
    return 1;
}

static struct slub_block *
slub_new_block(size_t capacity, unsigned int class_index, size_t npages) {
    struct Page *page = alloc_pages(npages);
    if (page == NULL) {
        return NULL;
    }
    struct slub_block *block = page2kva(page);
    memset(block, 0, sizeof(*block));
    block->magic = SLUB_MAGIC;
    block->page = page;
    block->npages = npages;
    block->capacity = capacity;
    block->class_index = class_index;
    list_init(&block->link);
    /* There are no fallible operations after obtaining the Buddy block:
     * constructing this in-place header requires no further allocation. */
    return block;
}

void
slub_init(void) {
    assert(!slub_ready);
    assert(pmm_manager == &buddy_pmm_manager);
    assert(SLUB_DATA_OFFSET < PGSIZE);
    assert((PGSIZE - SLUB_DATA_OFFSET) / SLUB_MIN_SIZE <=
           SLUB_BITMAP_WORDS * 64);
    size_t before = nr_free_pages();
    for (unsigned int i = 0; i < SLUB_CLASSES; i++) {
        slub_caches[i].capacity = (size_t)SLUB_MIN_SIZE << i;
        list_init(&slub_caches[i].slabs);
    }
    list_init(&slub_large);
    slub_ready = 1;
    assert(nr_free_pages() == before);
}

void *
kmalloc(size_t size) {
    if (size == 0) {
        return NULL;
    }
    assert(slub_ready);
    if (size > SLUB_MAX_SIZE) {
        size_t npages;
        if (!slub_large_pages(size, &npages)) {
            return NULL;
        }
        struct slub_block *block = slub_new_block(size, SLUB_CLASSES, npages);
        if (block == NULL) {
            return NULL;
        }
        block->slots = block->inuse = 1;
        list_add(&slub_large, &block->link);
        return slub_payload(block);
    }

    unsigned int class_index = 0;
    while (slub_caches[class_index].capacity < size) {
        class_index++;
    }
    struct slub_cache *cache = &slub_caches[class_index];
    struct slub_block *block = NULL;
    for (list_entry_t *le = list_next(&cache->slabs); le != &cache->slabs;
         le = list_next(le)) {
        struct slub_block *candidate = to_struct(le, struct slub_block, link);
        assert(candidate->magic == SLUB_MAGIC);
        if (candidate->inuse < candidate->slots) {
            block = candidate;
            break;
        }
    }
    if (block == NULL) {
        block = slub_new_block(cache->capacity, class_index, 1);
        if (block == NULL) {
            return NULL;
        }
        block->slots = (PGSIZE - SLUB_DATA_OFFSET) / cache->capacity;
        list_add(&cache->slabs, &block->link);
    }
    for (unsigned int slot = 0; slot < block->slots; slot++) {
        if (!slub_slot_used(block, slot)) {
            block->used[slot / 64] |= (uint64_t)1 << (slot % 64);
            block->inuse++;
            return (char *)slub_payload(block) + slot * cache->capacity;
        }
    }
    panic("SLUB: free-slot count is inconsistent");
}

void
kfree(void *ptr) {
    if (ptr == NULL) {
        return;
    }
    assert(slub_ready);
    uintptr_t address = (uintptr_t)ptr;
    /* Consult ONLY currently live headers. Do not round ptr down and inspect
     * arbitrary, reserved, or already released physical memory. */
    for (unsigned int i = 0; i < SLUB_CLASSES; i++) {
        list_entry_t *head = &slub_caches[i].slabs;
        for (list_entry_t *le = list_next(head); le != head; le = list_next(le)) {
            struct slub_block *block = to_struct(le, struct slub_block, link);
            assert(block->magic == SLUB_MAGIC);
            uintptr_t start = (uintptr_t)slub_payload(block);
            if (address < start || address - start >= block->slots * block->capacity) {
                continue;
            }
            size_t offset = address - start;
            assert(offset % block->capacity == 0);
            unsigned int slot = offset / block->capacity;
            assert(slub_slot_used(block, slot) && block->inuse > 0);
            block->used[slot / 64] &= ~((uint64_t)1 << (slot % 64));
            block->inuse--;
            if (block->inuse == 0) {
                struct Page *page = block->page;
                list_del_init(&block->link);
                block->magic = 0;
                free_pages(page, 1);
                /* No header or list pointer may be accessed after this free. */
            }
            return;
        }
    }
    for (list_entry_t *le = list_next(&slub_large); le != &slub_large;
         le = list_next(le)) {
        struct slub_block *block = to_struct(le, struct slub_block, link);
        assert(block->magic == SLUB_MAGIC);
        if (ptr == slub_payload(block)) {
            struct Page *page = block->page;
            size_t npages = block->npages;
            list_del_init(&block->link);
            block->magic = 0;
            free_pages(page, npages);
            return;
        }
    }
    panic("SLUB: invalid or already freed pointer %016lx", address);
}

static void
slub_validate(void) {
    for (unsigned int i = 0; i <= SLUB_CLASSES; i++) {
        list_entry_t *head = i == SLUB_CLASSES ? &slub_large : &slub_caches[i].slabs;
        size_t visited = 0;
        for (list_entry_t *le = list_next(head); le != head; le = list_next(le)) {
            assert(++visited <= npage - nbase);
            assert(list_prev(list_next(le)) == le);
            assert(list_next(list_prev(le)) == le);
            struct slub_block *block = to_struct(le, struct slub_block, link);
            assert(block->magic == SLUB_MAGIC && block->class_index == i);
            assert(page2kva(block->page) == (void *)block);
            assert(kva2page(block) == block->page);
            assert(block->page->property == block->npages);
            assert(((uintptr_t)slub_payload(block) & 15) == 0);
            if (i == SLUB_CLASSES) {
                size_t npages;
                assert(block->capacity > SLUB_MAX_SIZE);
                assert(slub_large_pages(block->capacity, &npages));
                assert(block->npages == npages && block->inuse == 1);
            } else {
                assert(block->capacity == slub_caches[i].capacity);
                assert(block->npages == 1);
                assert(block->slots == (PGSIZE - SLUB_DATA_OFFSET) / block->capacity);
                assert(block->inuse > 0 && block->inuse <= block->slots);
                unsigned int used = 0;
                for (unsigned int slot = 0; slot < SLUB_BITMAP_WORDS * 64; slot++) {
                    if (slub_slot_used(block, slot)) {
                        assert(slot < block->slots);
                        used++;
                    }
                }
                assert(used == block->inuse);
            }
        }
    }
}

static size_t
slub_test_capacity(size_t size) {
    size_t capacity = SLUB_MIN_SIZE;
    if (size > SLUB_MAX_SIZE) {
        return size;
    }
    while (capacity < size) {
        capacity <<= 1;
    }
    return capacity;
}

static void
slub_test_read(void *ptr, size_t size, unsigned char value) {
    unsigned char *bytes = ptr;
    for (size_t i = 0; i < size; i++) {
        assert(bytes[i] == value);
    }
}

void
slub_check(void) {
    assert(slub_ready);
    size_t initial = nr_free_pages();
    assert(list_empty(&slub_large));
    for (unsigned int i = 0; i < SLUB_CLASSES; i++) {
        assert(list_empty(&slub_caches[i].slabs));
    }
    assert(kmalloc(0) == NULL);
    kfree(NULL);
    assert(kmalloc((size_t)-1) == NULL);
    assert(kmalloc((size_t)-1 - SLUB_DATA_OFFSET + 1) == NULL);
    assert(kmalloc(PHYSICAL_MEMORY_END) == NULL);
    assert(nr_free_pages() == initial);

    struct Page *page = alloc_page();
    assert(page != NULL);
    void *kva = page2kva(page);
    assert(KADDR(page2pa(page)) == kva);
    assert(PADDR(kva) == page2pa(page));
    assert(kva2page(kva) == page);
    assert(kva2page((char *)kva + PGSIZE - 1) == page);
    free_page(page);
    cprintf("slub_check: conversions, zero and overflow requests passed\n");

    const size_t requests[] = {
        1, 15, 16, 17, 31, 32, 33, 63, 64, 65, 127, 128, 129,
        255, 256, 257, 511, 512, 513, 1023, 1024, 1025, 2047, 2048,
        2049, 3999, 4000, 4095, 4096, 4097, 8192, 8193, 65537
    };
    void *objects[sizeof(requests) / sizeof(requests[0])];
    unsigned int count = sizeof(requests) / sizeof(requests[0]);
    for (unsigned int i = 0; i < count; i++) {
        objects[i] = kmalloc(requests[i]);
        assert(objects[i] != NULL && ((uintptr_t)objects[i] & 15) == 0);
        size_t capacity = slub_test_capacity(requests[i]);
        for (unsigned int j = 0; j < i; j++) {
            uintptr_t a = (uintptr_t)objects[i], b = (uintptr_t)objects[j];
            assert(a < b ? capacity <= b - a : slub_test_capacity(requests[j]) <= a - b);
        }
        /* Write the FULL class capacity, not just the requested small size. */
        memset(objects[i], (unsigned char)(i + 1), capacity);
    }
    slub_validate();
    for (unsigned int i = 0; i < count; i++) {
        slub_test_read(objects[i], slub_test_capacity(requests[i]), i + 1);
    }
    for (unsigned int i = count; i > 0; i--) {
        kfree(objects[i - 1]);
    }
    assert(nr_free_pages() == initial);
    slub_validate();
    cprintf("slub_check: all classes, alignment, non-overlap and data passed\n");

    void *batch[40];
    for (unsigned int i = 0; i < 40; i++) {
        batch[i] = kmalloc(128);
        assert(batch[i] != NULL);
        memset(batch[i], i + 1, 128);
    }
    size_t slots = (PGSIZE - SLUB_DATA_OFFSET) / 128;
    assert(nr_free_pages() == initial - (40 / slots + (40 % slots != 0)));
    void *hole = batch[39];
    kfree(hole);
    batch[39] = kmalloc(128);
    assert(batch[39] == hole);
    memset(batch[39], 40, 128);
    slub_validate();
    for (unsigned int i = 0; i < 40; i++) {
        unsigned int j = (i * 17) % 40;
        slub_test_read(batch[j], 128, j + 1);
        kfree(batch[j]);
    }
    assert(nr_free_pages() == initial);
    cprintf("slub_check: multiple slabs, reuse and immediate reclaim passed\n");

    /* 8192-byte payload plus metadata needs n=3, which Buddy rounds to 4.
     * kfree must return that full block using the ORIGINAL Buddy n=3. */
    void *large = kmalloc(2 * PGSIZE);
    assert(large != NULL && nr_free_pages() == initial - 4);
    memset(large, 0xa5, 2 * PGSIZE);
    slub_test_read(large, 2 * PGSIZE, 0xa5);
    kfree(large);
    assert(nr_free_pages() == initial);
    cprintf("slub_check: large object returned complete rounded block\n");

    /* Exhaust Buddy while keeping a live object. Failure must not leak a
     * partially constructed slab or alter existing objects/free slots. */
    void *held = kmalloc(32);
    assert(held != NULL);
    memset(held, 0x5a, 32);
    list_entry_t drained;
    list_init(&drained);
    size_t drained_count = 0;
    while ((page = alloc_page()) != NULL) {
        list_add(&drained, &page->page_link);
        drained_count++;
    }
    assert(nr_free_pages() == 0 && drained_count == initial - 1);
    assert(kmalloc(64) == NULL && kmalloc(8193) == NULL);
    assert(kmalloc((size_t)-1) == NULL && nr_free_pages() == 0);
    void *reused = kmalloc(32);
    assert(reused != NULL && reused != held);
    memset(reused, 0xa6, 32);
    slub_test_read(held, 32, 0x5a);
    slub_test_read(reused, 32, 0xa6);
    kfree(reused);
    assert(nr_free_pages() == 0);
    slub_validate();
    while (!list_empty(&drained)) {
        page = le2page(list_next(&drained), page_link);
        list_del_init(&page->page_link);
        free_page(page);
    }
    slub_test_read(held, 32, 0x5a);
    kfree(held);
    assert(nr_free_pages() == initial);
    slub_validate();
    cprintf("slub_check: exhaustion, rollback and live data preservation passed\n");
    cprintf("slub_check() succeeded! restored %lu free pages\n", initial);
}
