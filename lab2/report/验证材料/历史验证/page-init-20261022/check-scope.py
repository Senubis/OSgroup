from pathlib import Path
import difflib
import hashlib
import json

out = Path(__file__).resolve().parent
root = out.parent.parent / 'lab2_new'
pairs = [('before/entry.S', 'kern/init/entry.S'),
         ('before/Makefile', 'Makefile'), ('before/pmm.c', 'kern/mm/pmm.c')]
diffs, stats, checks = [], [], {}
for backup, rel in pairs:
    before, after = (out / backup).read_bytes(), (root / rel).read_bytes()
    old, new = before.decode('utf-8').splitlines(True), after.decode('utf-8').splitlines(True)
    diffs.extend(difflib.unified_diff(old, new, fromfile='before/' + rel, tofile=rel))
    matcher = difflib.SequenceMatcher(a=old, b=new)
    added = deleted = 0
    for tag, i, j, k, l in matcher.get_opcodes():
        if tag != 'equal':
            deleted += j - i
            added += l - k
    if added or deleted:
        stats.append(f'{added}\t{deleted}\t{rel}\n')
    checks[rel] = dict(unchanged=before == after,
                      before_sha256=hashlib.sha256(before).hexdigest(),
                      after_sha256=hashlib.sha256(after).hexdigest())
checks['original_test_copied_verbatim'] = (
    (root / 'tools/test_lab2.c').read_bytes() ==
    (out / 'test-tree/kern/debug/test_lab2.c').read_bytes())
checks['maintained_files_match_test_tree_except_instrumented_pmm'] = all(
    p.read_bytes() == (out / 'test-tree' / p.relative_to(root)).read_bytes()
    for p in root.rglob('*') if p.is_file()
    and p.relative_to(root).parts[0] not in ('obj', 'bin')
    and p.relative_to(root).as_posix() != 'kern/mm/pmm.c'
)
assert checks['kern/mm/pmm.c']['unchanged']
assert checks['original_test_copied_verbatim']
assert checks['maintained_files_match_test_tree_except_instrumented_pmm']
(out / 'changes.diff').write_text(''.join(diffs), encoding='utf-8', newline='\n')
(out / 'source-numstat.txt').write_text(''.join(stats), encoding='utf-8', newline='\n')
(out / 'scope.json').write_text(json.dumps(checks, indent=2), encoding='utf-8')
print(json.dumps(checks, indent=2))
print('Source-only numstat (verification artifacts and build outputs are separate):')
print(''.join(stats))
