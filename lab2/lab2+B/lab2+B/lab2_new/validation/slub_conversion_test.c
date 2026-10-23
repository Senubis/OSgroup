/* Test the actual pmm.h conversion code, without replacing any conversions.
 * Returned kernel addresses are checked numerically, never dereferenced. */
#include <pmm.h>
#include <stdarg.h>

extern int printf(const char *, ...);
extern int vprintf(const char *, va_list);
extern void exit(int) __attribute__((noreturn));

static struct Page descriptors[768];
struct Page *pages = descriptors;
size_t npage = 0x80000 + 768;
const size_t nbase = 0x80000;
uint64_t va_pa_offset = PHYSICAL_MEMORY_OFFSET;

void __panic(const char *file, int line, const char *fmt, ...) {
    printf("PANIC %s:%d: ", file, line);
    va_list ap;
    va_start(ap, fmt);
    vprintf(fmt, ap);
    __builtin_va_end(ap);
    printf("\n");
    exit(73);
}

int main(int argc, char **argv) {
    uintptr_t pa_end = npage << PGSHIFT;
    uintptr_t kva_end = pa_end + PHYSICAL_MEMORY_OFFSET;
    if (argc > 1) {
        unsigned int test = (argv[1][0] - '0') * 10 + argv[1][1] - '0';
        switch (test) {
        case 0: (void)KADDR(KERNEL_BEGIN_PADDR - 1); break;
        case 1: (void)KADDR(pa_end); break;
        case 2: (void)KADDR(PHYSICAL_MEMORY_END); break;
        case 3: (void)KADDR((uintptr_t)-1); break;
        case 4: (void)PADDR(KERNBASE - 1); break;
        case 5: (void)PADDR(kva_end); break;
        case 6: (void)PADDR(KERNTOP); break;
        case 7: (void)PADDR((uintptr_t)-1); break;
        case 8: (void)page2kva(pages + 768); break;
        case 9: (void)page2kva((struct Page *)((uintptr_t)pages - sizeof(struct Page))); break;
        case 10: (void)page2kva((struct Page *)((uintptr_t)(pages + 512) + 1)); break;
        case 11: (void)pa2page((nbase << PGSHIFT) - 1); break;
        case 12: (void)pa2page(pa_end); break;
        case 13: (void)kva2page(NULL); break;
        case 14: (void)kva2page((void *)kva_end); break;
        case 15: va_pa_offset = 0; (void)KADDR(KERNEL_BEGIN_PADDR); break;
        default: return 2;
        }
        printf("ERROR: invalid conversion accepted\n");
        return 1;
    }
    assert(KADDR(KERNEL_BEGIN_PADDR) == (void *)KERNBASE);
    assert(PADDR(KERNBASE) == KERNEL_BEGIN_PADDR);
    assert(KADDR(pa_end - 1) == (void *)(kva_end - 1));
    assert(PADDR(kva_end - 1) == pa_end - 1);
    assert(pa2page(nbase << PGSHIFT) == pages);
    for (size_t i = 512; i < 768; i++) {
        void *kva = page2kva(pages + i);
        assert(kva2page(kva) == pages + i);
        assert(kva2page((char *)kva + PGSIZE - 1) == pages + i);
        assert(PADDR(kva) == page2pa(pages + i));
    }
    printf("CONVERSIONS: 256 page and end-byte round trips passed\n");
    return 0;
}
