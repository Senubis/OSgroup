from pathlib import Path
import hashlib, json
out = Path(__file__).resolve().parent
root = out.parent.parent / 'lab2_new'
manifest = {p.relative_to(root).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in root.rglob('*') if p.is_file()
            and p.relative_to(root).parts[0] not in ('obj', 'bin')}
(out / 'before-manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
print(f'Snapshotted {len(manifest)} maintained files before edits.')
