#include <pmm.h>
#include <best_fit_pmm.h>
#include <stdio.h>

void test_best_fit_extra(void) {
    assert(pmm_manager == &best_fit_pmm_manager);
    size_t total = nr_free_pages();
    assert(total > 32);
    struct Page *arena = alloc_pages(total);
    assert(arena != NULL && nr_free_pages() == 0);

    // Four separated holes; insert them in a non-address order.
    free_pages(arena + 15, 5);
    free_pages(arena, 8);
    free_pages(arena + 22, 3);
    free_pages(arena + 10, 3);
    assert(nr_free_pages() == 19);
    // Smallest fitting size wins; equal sizes choose the lower address.
    assert(alloc_pages(2) == arena + 10);
    assert(alloc_page() == arena + 12);
    assert(alloc_pages(3) == arena + 22);
    assert(alloc_pages(4) == arena + 15);
    assert(alloc_pages(6) == arena);
    assert(nr_free_pages() == 3);
    // The remaining holes have sizes 2 and 1, so a 3-page request must fail.
    assert(alloc_pages(3) == NULL && nr_free_pages() == 3);
    assert(alloc_page() == arena + 19);
    assert(alloc_pages(2) == arena + 6);
    assert(nr_free_pages() == 0 && alloc_page() == NULL);
    cprintf("[Extra] Best-Fit selection/split/fragmentation: PASS\n");

    // A newly freed middle block must join both neighbouring blocks.
    free_pages(arena + 2, 2);
    free_pages(arena + 6, 2);
    free_pages(arena + 4, 2);
    assert(nr_free_pages() == 6);
    assert(PageProperty(arena + 2) && arena[2].property == 6);
    assert(!PageProperty(arena + 4) && !PageProperty(arena + 6));
    assert(alloc_pages(6) == arena + 2);
    assert(nr_free_pages() == 0);
    cprintf("[Extra] Best-Fit two-sided coalescing: PASS\n");

    // Register several new, reserved regions out of order, then bridge the gap.
    // Only descriptors are touched; the underlying physical pages are not used.
    for (size_t i = 0; i < 12; i++) {
        SetPageReserved(arena + i);
    }
    pmm_manager->init_memmap(arena + 8, 4);
    pmm_manager->init_memmap(arena, 4);
    pmm_manager->init_memmap(arena + 4, 4);
    assert(nr_free_pages() == 12);
    assert(PageProperty(arena) && arena->property == 12);
    assert(alloc_pages(12) == arena);
    assert(nr_free_pages() == 0);
    cprintf("[Extra] Best-Fit multi-region registration: PASS\n");

    free_pages(arena, total);
    assert(nr_free_pages() == total);
    assert(PageProperty(arena) && arena->property == total);
    assert(alloc_pages(total + 1) == NULL);
    cprintf("[Extra] Best-Fit accounting/restoration: PASS\n");
}
