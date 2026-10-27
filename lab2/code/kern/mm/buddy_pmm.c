#include <buddy_pmm.h>
#include <list.h>
#include <stdio.h>

/* Private Page flags: public Page layout and public flag definitions stay intact.
 * Free heads: PG_property set, property = block size in pages.
 * Allocated heads: BUDDY_HEAD set, property = ORIGINAL request size.
 * All allocated pages, including rounded-up tails, carry BUDDY_ALLOCATED.
 * Free interior pages have property zero and no head flag. */
#define BUDDY_MANAGED   (1UL << 2)
#define BUDDY_ALLOCATED (1UL << 3)
#define BUDDY_HEAD      (1UL << 4)
/* A free block size must fit the existing unsigned int Page.property. */
#define BUDDY_ORDERS    (sizeof(((struct Page *)0)->property) * 8)
#define BUDDY_MAX_ORDER (BUDDY_ORDERS - 1)

static list_entry_t buddy_free[BUDDY_ORDERS];
static size_t buddy_free_count;
static size_t buddy_managed_count;

static size_t
buddy_block_size(unsigned int order) {
    assert(order < BUDDY_ORDERS);
    return (size_t)1 << order;
}

/* Validate descriptor bounds before pointer arithmetic or dereferencing. */
static size_t
buddy_page_index(struct Page *page) {
    uintptr_t address = (uintptr_t)page, first = (uintptr_t)pages;
    assert(pages != NULL && npage > nbase);
    assert(address >= first);
    assert((address - first) % sizeof(struct Page) == 0);
    size_t index = (address - first) / sizeof(struct Page);
    assert(index < npage - nbase);
    return index;
}

/* No shifts or additions can overflow, including for SIZE_MAX requests. */
static bool
buddy_request_order(size_t n, unsigned int *order) {
    if (n == 0 || npage <= nbase || n > npage - nbase ||
        n > buddy_block_size(BUDDY_MAX_ORDER)) {
        return 0;
    }
    unsigned int k = 0;
    while (buddy_block_size(k) < n) {
        k++;
    }
    *order = k;
    return 1;
}

/* XOR uses PHYSICAL page numbers, never the address of a descriptor. */
static struct Page *
buddy_partner(struct Page *base, unsigned int order) {
    size_t size = buddy_block_size(order);
    size_t partner_ppn = page2ppn(base) ^ size;
    if (partner_ppn < nbase || partner_ppn >= npage ||
        size > npage - partner_ppn) {
        return NULL;
    }
    return &pages[partner_ppn - nbase];
}

static bool
buddy_is_free_block(struct Page *base, size_t size) {
    return base != NULL && (base->flags & BUDDY_MANAGED) &&
           !(base->flags & (BUDDY_ALLOCATED | BUDDY_HEAD)) &&
           !PageReserved(base) && PageProperty(base) &&
           base->property == size;
}

/* Insert and coalesce; callers alone update the total free-page count. */
static void
buddy_insert(struct Page *base, unsigned int order) {
    while (order < BUDDY_MAX_ORDER) {
        struct Page *partner = buddy_partner(base, order);
        if (!buddy_is_free_block(partner, buddy_block_size(order))) {
            break;
        }
        list_del_init(&partner->page_link);
        ClearPageProperty(partner);
        partner->property = 0;
        if (partner < base) {
            base = partner;
        }
        order++;
    }
    base->property = buddy_block_size(order);
    SetPageProperty(base);
    list_add(&buddy_free[order], &base->page_link);
}

static void
buddy_init(void) {
    for (unsigned int order = 0; order < BUDDY_ORDERS; order++) {
        list_init(&buddy_free[order]);
    }
    buddy_free_count = buddy_managed_count = 0;
}

static void
buddy_init_memmap(struct Page *base, size_t n) {
    size_t index = buddy_page_index(base);
    assert(n > 0 && n <= (npage - nbase) - index);
    /* Validate the entire range before changing any descriptor. */
    for (size_t i = 0; i < n; i++) {
        assert(PageReserved(base + i));
        assert(!(base[i].flags & BUDDY_MANAGED));
    }
    for (size_t i = 0; i < n; i++) {
        base[i].flags = BUDDY_MANAGED;
        base[i].property = 0;
        set_page_ref(base + i, 0);
        list_init(&base[i].page_link);
    }
    buddy_free_count += n;
    buddy_managed_count += n;
    while (n != 0) {
        unsigned int order = 0;
        size_t ppn = page2ppn(base);
        while (order < BUDDY_MAX_ORDER &&
               buddy_block_size(order + 1) <= n &&
               (ppn & (buddy_block_size(order + 1) - 1)) == 0) {
            order++;
        }
        size_t size = buddy_block_size(order);
        buddy_insert(base, order);
        base += size;
        n -= size;
    }
}

static struct Page *
buddy_alloc_pages(size_t n) {
    unsigned int order;
    if (!buddy_request_order(n, &order)) {
        return NULL;
    }
    size_t size = buddy_block_size(order);
    if (size > buddy_free_count) {
        return NULL;
    }
    unsigned int found = order;
    while (found < BUDDY_ORDERS && list_empty(&buddy_free[found])) {
        found++;
    }
    if (found == BUDDY_ORDERS) {
        return NULL; /* Fragmented: enough total pages, no suitable block. */
    }
    struct Page *base = le2page(list_next(&buddy_free[found]), page_link);
    list_del_init(&base->page_link);
    ClearPageProperty(base);
    base->property = 0;
    while (found > order) {
        found--;
        struct Page *right = base + buddy_block_size(found);
        right->property = buddy_block_size(found);
        SetPageProperty(right);
        list_add(&buddy_free[found], &right->page_link);
    }
    for (size_t i = 0; i < size; i++) {
        assert(base[i].flags == BUDDY_MANAGED);
        assert(base[i].property == 0);
        base[i].flags |= BUDDY_ALLOCATED;
        set_page_ref(base + i, 0);
    }
    base->flags |= BUDDY_HEAD;
    base->property = n;
    buddy_free_count -= size;
    return base;
}

static void
buddy_free_pages(struct Page *base, size_t n) {
    size_t index = buddy_page_index(base);
    unsigned int order;
    assert(buddy_request_order(n, &order));
    size_t size = buddy_block_size(order);
    assert(size <= (npage - nbase) - index);
    assert((page2ppn(base) & (size - 1)) == 0);
    /* Exact original n is required even if another n has the same order. */
    assert(base->property == n);
    assert(base->flags == (BUDDY_MANAGED | BUDDY_ALLOCATED | BUDDY_HEAD));
    for (size_t i = 1; i < size; i++) {
        assert(base[i].flags == (BUDDY_MANAGED | BUDDY_ALLOCATED));
        assert(base[i].property == 0);
    }
    for (size_t i = 0; i < size; i++) {
        base[i].flags = BUDDY_MANAGED;
        base[i].property = 0;
        set_page_ref(base + i, 0);
        list_init(&base[i].page_link);
    }
    buddy_free_count += size;
    buddy_insert(base, order);
}

static size_t
buddy_nr_free_pages(void) {
    return buddy_free_count;
}

/* Check every listed block and every managed descriptor, including tails.
 * This verifies accounting, physical alignment, disjointness and maximal
 * coalescing without touching reserved descriptors or allocating metadata. */
static void
buddy_validate(void) {
    size_t listed = 0, free_pages_seen = 0, managed = 0;
    size_t allocated = 0, allocated_blocks = 0;
    for (unsigned int order = 0; order < BUDDY_ORDERS; order++) {
        list_entry_t *head = &buddy_free[order], *le = list_next(head);
        size_t nodes = 0, size = buddy_block_size(order);
        while (le != head) {
            assert(++nodes <= npage - nbase);
            assert(list_prev(list_next(le)) == le);
            assert(list_next(list_prev(le)) == le);
            struct Page *base = le2page(le, page_link);
            size_t index = buddy_page_index(base);
            assert(size <= (npage - nbase) - index);
            assert((page2ppn(base) & (size - 1)) == 0);
            assert(buddy_is_free_block(base, size));
            for (size_t i = 1; i < size; i++) {
                assert(base[i].flags == BUDDY_MANAGED);
                assert(base[i].property == 0);
            }
            if (order < BUDDY_MAX_ORDER) {
                assert(!buddy_is_free_block(buddy_partner(base, order), size));
            }
            listed += size;
            le = list_next(le);
        }
    }
    for (size_t i = 0; i < npage - nbase; i++) {
        struct Page *base = &pages[i];
        if (!(base->flags & BUDDY_MANAGED)) {
            continue;
        }
        managed++;
        assert(!PageReserved(base));
        if (!(base->flags & BUDDY_ALLOCATED)) {
            free_pages_seen++;
            assert(!(base->flags & BUDDY_HEAD));
        } else {
            allocated++;
            assert(!PageProperty(base));
            if (base->flags & BUDDY_HEAD) {
                unsigned int order;
                assert(buddy_request_order(base->property, &order));
                size_t size = buddy_block_size(order);
                assert(size <= npage - nbase - i);
                assert((page2ppn(base) & (size - 1)) == 0);
                for (size_t j = 1; j < size; j++) {
                    assert(base[j].flags == (BUDDY_MANAGED | BUDDY_ALLOCATED));
                    assert(base[j].property == 0);
                }
                allocated_blocks += size;
            }
        }
    }
    assert(listed == free_pages_seen && listed == buddy_free_count);
    assert(allocated_blocks == allocated);
    assert(managed == buddy_managed_count);
    assert(listed + allocated == managed);
}

static void
buddy_check(void) {
    size_t initial = nr_free_pages();
    size_t original_blocks[BUDDY_ORDERS];
    assert(initial > 0);
    buddy_validate();
    for (unsigned int order = 0; order < BUDDY_ORDERS; order++) {
        size_t count = 0;
        list_entry_t *head = &buddy_free[order];
        for (list_entry_t *le = list_next(head); le != head; le = list_next(le)) {
            count++;
        }
        original_blocks[order] = count;
    }

    assert(alloc_pages(0) == NULL);
    assert(alloc_pages((size_t)-1) == NULL);
    assert(alloc_pages((size_t)1 << (sizeof(size_t) * 8 - 1)) == NULL);
    assert(alloc_pages(buddy_block_size(BUDDY_MAX_ORDER) + 1) == NULL);
    assert(alloc_pages(npage - nbase + 1) == NULL);
    assert(alloc_pages(initial + 1) == NULL);
    assert(nr_free_pages() == initial);
    buddy_validate();
    cprintf("buddy_check: invalid requests passed\n");

    bool has_large_block = 0;
    for (unsigned int order = 5; order < BUDDY_ORDERS; order++) {
        if (!list_empty(&buddy_free[order])) {
            has_large_block = 1;
        }
    }
    if (has_large_block) {
        const size_t requests[] = {1, 2, 3, 5, 8};
        const unsigned int release_order[] = {2, 0, 4, 1, 3};
        struct Page *blocks[5];
        size_t used = 0;
        for (unsigned int i = 0; i < 5; i++) {
            unsigned int order;
            assert(buddy_request_order(requests[i], &order));
            size_t size = buddy_block_size(order);
            blocks[i] = alloc_pages(requests[i]);
            assert(blocks[i] != NULL && blocks[i]->property == requests[i]);
            assert(page_ref(blocks[i]) == 0 && !PageProperty(blocks[i]));
            assert((page2pa(blocks[i]) & (size * PGSIZE - 1)) == 0);
            for (unsigned int j = 0; j < i; j++) {
                unsigned int other_order;
                assert(buddy_request_order(requests[j], &other_order));
                assert(blocks[i] + size <= blocks[j] ||
                       blocks[j] + buddy_block_size(other_order) <= blocks[i]);
            }
            used += size;
            assert(nr_free_pages() == initial - used);
        }
        buddy_validate();
        for (unsigned int i = 0; i < 5; i++) {
            unsigned int j = release_order[i];
            free_pages(blocks[j], requests[j]);
        }
        assert(nr_free_pages() == initial);
        buddy_validate();
        cprintf("buddy_check: rounded allocations and unordered frees passed\n");
    }

    /* Exhaust all free pages, forcing every initial block to split to order 0.
     * Allocated page_link is unused by the allocator, so it holds the test's
     * live allocations without a large stack array or heap dependency. */
    list_entry_t live;
    list_init(&live);
    size_t count = 0;
    struct Page *page;
    while ((page = alloc_page()) != NULL) {
        assert(page_ref(page) == 0 && page->property == 1);
        set_page_ref(page, 1); /* A duplicate allocation must fail this check. */
        list_add(&live, &page->page_link);
        assert(++count <= initial);
        assert(nr_free_pages() == initial - count);
    }
    assert(count == initial && nr_free_pages() == 0);
    assert(alloc_page() == NULL && alloc_pages(3) == NULL);
    buddy_validate();
    cprintf("buddy_check: splitting, unique pages and exhaustion passed\n");

    /* Free only odd physical pages: every order-0 buddy stays allocated.
     * An order-1 request must fail even with many total free pages. */
    list_entry_t *le = list_next(&live);
    size_t odd = 0;
    while (le != &live) {
        list_entry_t *next = list_next(le);
        page = le2page(le, page_link);
        if (page2ppn(page) & 1) {
            list_del_init(le);
            free_page(page);
            odd++;
        }
        le = next;
    }
    assert(nr_free_pages() == odd);
    assert(alloc_pages(2) == NULL);
    assert(nr_free_pages() == odd);
    buddy_validate();
    if (odd != 0) {
        page = alloc_page();
        assert(page != NULL && (page2ppn(page) & 1));
        free_page(page);
    }
    cprintf("buddy_check: fragmentation failure leaves state unchanged\n");

    while (!list_empty(&live)) {
        page = le2page(list_next(&live), page_link);
        list_del_init(&page->page_link);
        free_page(page);
    }
    assert(nr_free_pages() == initial);
    buddy_validate();
    for (unsigned int order = 0; order < BUDDY_ORDERS; order++) {
        size_t blocks = 0;
        list_entry_t *head = &buddy_free[order];
        for (le = list_next(head); le != head; le = list_next(le)) {
            blocks++;
        }
        assert(blocks == original_blocks[order]);
    }
    cprintf("buddy_check: multilevel coalescing restored all %lu pages\n", initial);
    cprintf("buddy_check() succeeded!\n");
}

const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};
