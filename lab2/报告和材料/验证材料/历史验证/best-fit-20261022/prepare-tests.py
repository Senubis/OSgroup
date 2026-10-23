from pathlib import Path
import shutil, subprocess
out = Path(__file__).resolve().parent
source = out.parent.parent / 'lab2_new'
staging = out / 'test-tree'
if staging.exists():
    raise SystemExit('Refusing to overwrite an existing test-tree.')
shutil.copytree(source, staging, ignore=shutil.ignore_patterns('obj', 'bin'))
# Use the existing course injector without editing it or the course tests.
subprocess.run(['python3', str(source / 'tools/inject.py'), str(staging)], check=True)
shutil.copy2(out / 'extra_checks.c', staging / 'kern/test/extra_checks.c')
pmm = staging / 'kern/mm/pmm.c'
text = pmm.read_text()
needle = '    test_best_fit();'
assert text.count(needle) == 1
text = text.replace(needle, needle + '\n    extern void test_best_fit_extra(void);\n    test_best_fit_extra();')
pmm.write_text(text)
for name in ('test_lab2.c', 'test_lab2.h'):
    assert (source / 'tools' / name).read_bytes() == (staging / 'kern/test' / name).read_bytes()
print('Course tests copied verbatim; additional test calls exist only in test-tree.')
