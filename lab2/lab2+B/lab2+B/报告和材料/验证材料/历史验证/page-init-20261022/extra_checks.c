#include <pmm.h>
#include <dtb.h>
#include <stdio.h>

void test_page_init_extra(void) {
    extern char end[];
    uint64_t reported_end = get_memory_base() + get_memory_size();
    uintptr_t maxpa = ROUNDDOWN((uintptr_t)(reported_end < PHYSICAL_MEMORY_END
                              ? reported_end : PHYSICAL_MEMORY_END), PGSIZE);
    size_t count = PPN(maxpa) - nbase;
    uintptr_t first_free = ROUNDUP(PADDR(pages + count), PGSIZE);
    size_t expected_free = (maxpa - first_free) / PGSIZE;
    assert(va_pa_offset == PHYSICAL_MEMORY_OFFSET);
    assert(npage == PPN(maxpa));
    assert((uintptr_t)pages == ROUNDUP((uintptr_t)end, PGSIZE));
    assert(nr_free_pages() == expected_free);
    assert(PageProperty(pa2page(first_free)));
    assert(pa2page(first_free)->property == expected_free);

    for (size_t i = 0; i < count; i++) {
        struct Page *p = pages + i;
        uintptr_t pa = (nbase + i) * PGSIZE;
        assert(page2pa(p) == pa);
        assert(pa2page(pa) == p);
        assert(page_ref(p) == 0);
        if (pa < first_free) {
            assert(PageReserved(p));
            assert(p->property == 0 && !PageProperty(p));
        } else {
            assert(!PageReserved(p));
            if (pa != first_free) {
                assert(!PageProperty(p) && p->property == 0);
            }
        }
    }
    assert(alloc_pages(expected_free + 1) == NULL);
    struct Page *all = alloc_pages(expected_free);
    assert(all == pa2page(first_free));
    assert(nr_free_pages() == 0);
    assert(alloc_page() == NULL);
    free_pages(all, expected_free);
    assert(nr_free_pages() == expected_free);
    assert(PageProperty(all) && all->property == expected_free);
    cprintf("[Extra] Page Init: PASS (descriptors=%lu free=%lu first=0x%lx limit=0x%lx)\n",
            count, expected_free, first_free, maxpa);
}
