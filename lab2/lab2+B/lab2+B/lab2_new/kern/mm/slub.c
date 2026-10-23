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

/* Fixed-size object records keep stack usage independent of physical RAM.
 * Exhaustion uses at most 'initial' existing Page.page_link records instead
 * of a heap allocation or an unbounded pointer array. */
#define SLUB_TEST_RECORDS 64
struct slub_test_object {
    void *ptr;
    size_t capacity;
    unsigned char seed;
};

static unsigned char
slub_test_byte(size_t offset, unsigned char seed) {
    return (unsigned char)(seed + offset * 37 + (offset >> 8) * 11);
}

static void
slub_test_pattern(struct slub_test_object *object, bool write) {
    volatile unsigned char *bytes = object->ptr;
    assert(bytes != NULL);
    for (size_t i = 0; i < object->capacity; i++) {
        unsigned char expected = slub_test_byte(i, object->seed);
        if (write) {
            bytes[i] = expected;
        } else {
            assert(bytes[i] == expected);
        }
    }
}

static void
slub_test_add(struct slub_test_object *objects, unsigned int count, size_t size) {
    assert(count < SLUB_TEST_RECORDS);
    struct slub_test_object *object = &objects[count];
    object->ptr = kmalloc(size);
    object->capacity = slub_test_capacity(size);
    object->seed = (unsigned char)(count * 13 + 7);
    assert(object->ptr != NULL && ((uintptr_t)object->ptr & 15) == 0);
    for (unsigned int i = 0; i < count; i++) {
        if (objects[i].ptr != NULL) {
            uintptr_t a = (uintptr_t)object->ptr, b = (uintptr_t)objects[i].ptr;
            assert(a < b ? object->capacity <= b - a : objects[i].capacity <= a - b);
        }
    }
    slub_test_pattern(object, 1); /* Full class capacity or entire large request. */
}

static void
slub_test_live(struct slub_test_object *objects, unsigned int count) {
    assert(count <= SLUB_TEST_RECORDS);
    for (unsigned int i = 0; i < count; i++) {
        if (objects[i].ptr != NULL) {
            slub_test_pattern(&objects[i], 0);
        }
    }
}

static void
slub_test_drop(struct slub_test_object *object) {
    slub_test_pattern(object, 0);
    kfree(object->ptr);
    object->ptr = NULL; /* Never inspect or read an object after freeing it. */
}

static void
slub_test_clean(size_t initial) {
    assert(nr_free_pages() == initial);
    slub_validate();
    assert(list_next(&slub_large) == &slub_large);
    assert(list_prev(&slub_large) == &slub_large);
    for (unsigned int i = 0; i < SLUB_CLASSES; i++) {
        list_entry_t *head = &slub_caches[i].slabs;
        assert(list_next(head) == head && list_prev(head) == head);
        assert(slub_caches[i].capacity == ((size_t)SLUB_MIN_SIZE << i));
    }
}

static void
slub_test_failed_requests(struct slub_test_object *live, unsigned int count) {
    const size_t requests[] = {
        (size_t)-1,
        (size_t)-1 - SLUB_DATA_OFFSET + 1, /* Header addition overflows. */
        (size_t)-1 - SLUB_DATA_OFFSET,     /* Addition fits, page request cannot. */
        (size_t)1 << (sizeof(size_t) * 8 - 1),
        PHYSICAL_MEMORY_END
    };
    size_t before = nr_free_pages();
    assert(kmalloc(0) == NULL);
    kfree(NULL);
    for (unsigned int i = 0; i < sizeof(requests) / sizeof(requests[0]); i++) {
        assert(kmalloc(requests[i]) == NULL);
        assert(nr_free_pages() == before);
        slub_test_live(live, count);
        slub_validate();
    }
    assert(nr_free_pages() == before);
}

static void
slub_test_boundaries(size_t initial) {
    const size_t requests[] = {
        1, 15, 16, 17, 31, 32, 33, 63, 64, 65, 127, 128, 129,
        255, 256, 257, 511, 512, 513, 1023, 1024, 1025, 2047, 2048,
        2049, PGSIZE - SLUB_DATA_OFFSET - 1, PGSIZE - SLUB_DATA_OFFSET,
        PGSIZE - SLUB_DATA_OFFSET + 1, 4095, 4096, 4097, 8192, 8193, 65537
    };
    struct slub_test_object objects[SLUB_TEST_RECORDS] = {{0}};
    unsigned int count = sizeof(requests) / sizeof(requests[0]);
    assert(count <= SLUB_TEST_RECORDS);
    for (unsigned int i = 0; i < count; i++) {
        slub_test_add(objects, i, requests[i]);
        slub_test_live(objects, i + 1); /* New allocations preserve all live data. */
    }
    slub_validate();
    slub_test_failed_requests(objects, count);
    /* Alternate low/high indices: a permutation for ANY count, no gcd assumption. */
    for (unsigned int i = 0; i < count; i++) {
        unsigned int j = (i & 1) ? count - 1 - i / 2 : i / 2;
        slub_test_drop(&objects[j]);
        slub_test_live(objects, count);
    }
    slub_test_clean(initial);
    cprintf("[SLUB T02] PASS boundaries, full data, alignment, non-overlap, overflow\n");
}

static void
slub_test_empty_pages(size_t initial) {
    for (unsigned int i = 0; i < SLUB_CLASSES; i++) {
        struct slub_test_object object[1] = {{0}};
        slub_test_add(object, 0, (size_t)SLUB_MIN_SIZE << i);
        assert(nr_free_pages() == initial - 1);
        slub_test_drop(object);
        slub_test_clean(initial); /* Each category must release its empty slab NOW. */
    }
    cprintf("[SLUB T03] PASS immediate empty-page reclaim for all 8 classes\n");
}

static void
slub_test_cross_page(size_t initial) {
    struct slub_test_object objects[SLUB_TEST_RECORDS] = {{0}};
    size_t slots = (PGSIZE - SLUB_DATA_OFFSET) / 128;
    unsigned int count = slots * 2;
    assert(slots >= 2 && count <= SLUB_TEST_RECORDS);
    for (unsigned int i = 0; i < count; i++) {
        slub_test_add(objects, i, 128);
    }
    struct Page *first = kva2page(objects[0].ptr);
    struct Page *second = kva2page(objects[slots].ptr);
    assert(first != second && nr_free_pages() == initial - 2);
    for (unsigned int i = 0; i < count; i++) {
        assert(kva2page(objects[i].ptr) == (i < slots ? first : second));
    }
    /* Both slabs are full, so the freed slot is the ONLY available one. */
    unsigned int hole_index = slots + slots / 2;
    void *hole = objects[hole_index].ptr;
    slub_test_drop(&objects[hole_index]);
    objects[hole_index].ptr = kmalloc(128);
    assert(objects[hole_index].ptr == hole);
    assert(nr_free_pages() == initial - 2);
    slub_test_pattern(&objects[hole_index], 1);
    slub_test_live(objects, count);
    for (unsigned int i = 0; i < slots; i++) {
        unsigned int j = (i & 1) ? slots - 1 - i / 2 : i / 2;
        slub_test_drop(&objects[j]);
        assert(nr_free_pages() == initial - (i + 1 == slots ? 1 : 2));
        slub_test_live(objects, count); /* Other slab survives the first slab's free. */
    }
    slub_validate();
    /* Refill after a whole slab was removed, while the second slab is full. */
    struct slub_test_object refill[1] = {{0}};
    slub_test_add(refill, 0, 128);
    assert(nr_free_pages() == initial - 2);
    slub_test_live(objects, count);
    slub_test_drop(refill);
    assert(nr_free_pages() == initial - 1);
    for (unsigned int i = 0; i < slots; i++) {
        unsigned int j = slots + ((i & 1) ? slots - 1 - i / 2 : i / 2);
        slub_test_drop(&objects[j]);
        slub_test_live(objects, count);
    }
    slub_test_clean(initial);
    cprintf("[SLUB T04] PASS cross-page slots, exact reuse, partial slab reclaim, shuffle\n");
}

static size_t
slub_test_large_cost(size_t size) {
    assert(size <= (size_t)-1 - SLUB_DATA_OFFSET - PGSIZE);
    size_t needed = (size + SLUB_DATA_OFFSET + PGSIZE - 1) / PGSIZE;
    size_t rounded = 1;
    while (rounded < needed) {
        assert(rounded <= (size_t)-1 / 2);
        rounded <<= 1;
    }
    return rounded;
}

static void
slub_test_large_objects(size_t initial) {
    const size_t requests[] = {
        2049, 4096, 4097, 8192,
        3 * PGSIZE - SLUB_DATA_OFFSET,
        3 * PGSIZE - SLUB_DATA_OFFSET + 1, 65537
    };
    struct slub_test_object objects[SLUB_TEST_RECORDS] = {{0}};
    unsigned int count = sizeof(requests) / sizeof(requests[0]);
    size_t used = 0;
    assert(slub_test_large_cost(8192) == 4); /* Original Buddy n=3. */
    for (unsigned int i = 0; i < count; i++) {
        slub_test_add(objects, i, requests[i]);
        used += slub_test_large_cost(requests[i]);
        assert(nr_free_pages() == initial - used);
        slub_test_live(objects, i + 1);
    }
    slub_validate();
    for (unsigned int i = 0; i < count; i++) {
        unsigned int j = (i & 1) ? count - 1 - i / 2 : i / 2;
        slub_test_drop(&objects[j]);
        used -= slub_test_large_cost(requests[j]);
        assert(nr_free_pages() == initial - used);
        slub_test_live(objects, count);
    }
    slub_test_clean(initial);
    cprintf("[SLUB T05] PASS metadata-aware large-page costs and complete shuffled frees\n");
}

static void
slub_test_exhaustion(size_t initial) {
    struct slub_test_object held[3] = {{0}};
    slub_test_add(held, 0, 32);    /* Free slots remain in this slab. */
    slub_test_add(held, 1, 2048);  /* This class's slab is full. */
    slub_test_add(held, 2, 4097);  /* A live multi-page object. */
    size_t used = 2 + slub_test_large_cost(4097);
    assert(nr_free_pages() == initial - used);
    list_entry_t drained;
    list_init(&drained);
    size_t drained_count = 0;
    for (size_t i = 0; i < initial; i++) {
        struct Page *page = alloc_page();
        if (page == NULL) {
            break;
        }
        list_add(&drained, &page->page_link);
        drained_count++;
    }
    assert(drained_count <= initial && drained_count <= npage - nbase);
    assert(drained_count == initial - used && nr_free_pages() == 0);
    assert(alloc_page() == NULL);
    const size_t failures[] = {64, 2048, 8193};
    for (unsigned int i = 0; i < sizeof(failures) / sizeof(failures[0]); i++) {
        assert(kmalloc(failures[i]) == NULL);
        assert(nr_free_pages() == 0);
        slub_test_live(held, 3);
        slub_validate();
    }
    slub_test_failed_requests(held, 3);
    void *reused = kmalloc(32);
    assert(reused != NULL && reused != held[0].ptr && ((uintptr_t)reused & 15) == 0);
    memset(reused, 0xa6, 32);
    slub_test_read(reused, 32, 0xa6);
    slub_test_live(held, 3);
    kfree(reused);
    assert(nr_free_pages() == 0);
    size_t restored = 0;
    while (restored < drained_count) {
        assert(!list_empty(&drained));
        struct Page *page = le2page(list_next(&drained), page_link);
        list_del_init(&page->page_link);
        free_page(page);
        restored++;
    }
    assert(list_next(&drained) == &drained && list_prev(&drained) == &drained);
    assert(nr_free_pages() == initial - used);
    slub_test_live(held, 3);
    slub_test_drop(&held[1]);
    assert(nr_free_pages() == initial - used + 1);
    slub_test_live(held, 3);
    slub_test_drop(&held[2]);
    assert(nr_free_pages() == initial - 1);
    slub_test_drop(&held[0]);
    slub_test_clean(initial);
    cprintf("[SLUB T06] PASS bounded exhaustion, failed new/full/large allocations, live data\n");
}

static void
slub_test_after_cleanup(size_t initial) {
    for (unsigned int round = 0; round < 2; round++) {
        struct slub_test_object objects[SLUB_TEST_RECORDS] = {{0}};
        unsigned int count = SLUB_CLASSES + 2;
        for (unsigned int i = 0; i < SLUB_CLASSES; i++) {
            slub_test_add(objects, i, (size_t)SLUB_MIN_SIZE << i);
        }
        slub_test_add(objects, SLUB_CLASSES, 2049);
        slub_test_add(objects, SLUB_CLASSES + 1, 4097);
        assert(nr_free_pages() == initial - SLUB_CLASSES -
               slub_test_large_cost(2049) - slub_test_large_cost(4097));
        slub_validate();
        for (unsigned int i = count; i > 0; i--) {
            slub_test_drop(&objects[i - 1]);
            slub_test_live(objects, count);
        }
        slub_test_clean(initial);
    }
    cprintf("[SLUB T07] PASS empty cache links and two rounds of later allocations\n");
}

void
slub_check(void) {
    assert(slub_ready);
    size_t initial = nr_free_pages();
    /* The Lab's 128 MiB setup has ample room for the fixed concurrent cases. */
    assert(initial >= 128 && initial <= npage - nbase);
    slub_test_clean(initial);
    cprintf("slub_check: begin free=%lu header=%lu records=%d\n",
            initial, (size_t)SLUB_DATA_OFFSET, SLUB_TEST_RECORDS);
    assert(kmalloc(0) == NULL);
    kfree(NULL);
    struct Page *page = alloc_page();
    assert(page != NULL);
    void *kva = page2kva(page);
    assert(KADDR(page2pa(page)) == kva && PADDR(kva) == page2pa(page));
    assert(kva2page(kva) == page && kva2page((char *)kva + PGSIZE - 1) == page);
    free_page(page);
    slub_test_clean(initial);
    cprintf("[SLUB T01] PASS zero, NULL and page-address round trips\n");
    slub_test_boundaries(initial);
    slub_test_empty_pages(initial);
    slub_test_cross_page(initial);
    slub_test_large_objects(initial);
    slub_test_exhaustion(initial);
    slub_test_after_cleanup(initial);
    slub_test_clean(initial);
    cprintf("slub_check() succeeded! stages=7 restored %lu free pages\n", initial);
}
