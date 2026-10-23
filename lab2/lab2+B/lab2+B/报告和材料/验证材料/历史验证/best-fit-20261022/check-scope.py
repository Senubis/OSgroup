from pathlib import Path
import difflib, hashlib, json
out = Path(__file__).resolve().parent
root = out.parent.parent / 'lab2_new'
before = json.loads((out / 'before-manifest.json').read_text())
after = {p.relative_to(root).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
         for p in root.rglob('*') if p.is_file()
         and p.relative_to(root).parts[0] not in ('obj', 'bin')}
changed = sorted(k for k in before.keys() | after.keys() if before.get(k) != after.get(k))
assert changed == ['kern/mm/best_fit_pmm.c', 'kern/mm/pmm.c'], changed
old_best = (out / 'before/best_fit_pmm.c').read_text()
new_best = (root / 'kern/mm/best_fit_pmm.c').read_text()
anchor = '// Framework tests:'
assert old_best[old_best.index(anchor):] == new_best[new_best.index(anchor):]
old_pmm = (out / 'before/pmm.c').read_text()
new_pmm = (root / 'kern/mm/pmm.c').read_text()
assert old_pmm.replace('pmm_manager = &default_pmm_manager;',
                       'pmm_manager = &best_fit_pmm_manager;') == new_pmm
diffs, stats = [], []
for rel, backup in [('kern/mm/best_fit_pmm.c', 'best_fit_pmm.c'), ('kern/mm/pmm.c', 'pmm.c')]:
    a = (out / 'before' / backup).read_text().splitlines(True)
    b = (root / rel).read_text().splitlines(True)
    diffs.extend(difflib.unified_diff(a, b, fromfile='before/' + rel, tofile=rel))
    add = delete = 0
    for tag, i, j, k, l in difflib.SequenceMatcher(a=a, b=b).get_opcodes():
        if tag != 'equal':
            delete += j - i
            add += l - k
    stats.append(f'{add}\t{delete}\t{rel}\n')
(out / 'changes.diff').write_text(''.join(diffs), encoding='utf-8')
(out / 'source-numstat.txt').write_text(''.join(stats), encoding='utf-8')
result = dict(maintained_files_checked=len(before), changed=changed,
              original_basic_and_best_fit_checks_unchanged=True,
              pmm_only_manager_selection_changed=True,
              page_init_and_boot_fixes_and_public_headers_unchanged=True)
(out / 'scope.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
print(json.dumps(result, indent=2))
print(''.join(stats))
