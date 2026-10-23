from pathlib import Path
import json
import subprocess

work = Path(__file__).resolve().parent
logs = work / 'slub_validation'
rows = []


def run(name, binary, args, expected):
    result = subprocess.run([str(logs / binary)] + args,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    (logs / (name + '.log')).write_bytes(result.stdout)
    row = dict(name=name, exit_code=result.returncode,
               passed=result.returncode == expected)
    rows.append(row)
    print(json.dumps(row), flush=True)
    if result.returncode != expected:
        print(result.stdout.decode(errors='replace'), flush=True)
        raise SystemExit(1)


for case in ['s', 'd', 'f', 'l', 'b', 'i']:
    run('invalid_free_' + case, 'slub_host_test', [case], 73)
run('conversion_valid', 'slub_conversion_test', [], 0)
for case in range(16):
    run('conversion_invalid_%02d' % case, 'slub_conversion_test', ['%02d' % case], 73)
(logs / 'negative_results.json').write_text(json.dumps(rows, indent=2))
