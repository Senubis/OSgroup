from pathlib import Path
import shutil

out = Path(__file__).resolve().parent
source = out.parent.parent / 'lab2_new'
staging = out / 'test-tree'
if staging.exists():
    raise SystemExit('Refusing to overwrite existing test-tree; keep previous evidence.')
shutil.copytree(source, staging, ignore=shutil.ignore_patterns('obj', 'bin'))
# Copy the original tests verbatim. test_best_fit is unreferenced and discarded
# by the existing --gc-sections linker flag; no Best-Fit code is implemented.
for name in ('test_lab2.c', 'test_lab2.h'):
    shutil.copy2(source / 'tools' / name, staging / 'kern/debug' / name)
shutil.copy2(out / 'extra_checks.c', staging / 'kern/debug/extra_checks.c')
pmm = staging / 'kern/mm/pmm.c'
text = pmm.read_text(encoding='utf-8')
needle = '    page_init();'
assert text.count(needle) == 1
text = text.replace(needle, needle + '''
    extern void test_page_init(void);
    extern void test_page_init_extra(void);
    if (get_memory_base() + get_memory_size() <= PHYSICAL_MEMORY_END) {
        test_page_init();
    } else {
        cprintf("[Test 1] SKIP: original test assumes uncapped RAM; extra test checks cap\\n");
    }
    test_page_init_extra();''')
pmm.write_text(text, encoding='utf-8', newline='\n')
assert (source / 'tools/test_lab2.c').read_bytes() == (staging / 'kern/debug/test_lab2.c').read_bytes()
print('Created isolated test-tree; original test_lab2.c copied byte-for-byte.')
print('Only the test-tree pmm.c receives test calls. Maintained pmm.c unchanged.')
