"""Run the literal requested commands; preserve failures and raw serial logs."""
from pathlib import Path
import json
import os
import re
import shutil
import signal
import subprocess
import time

work = Path(__file__).resolve().parent
root = work.parent
logs = work / 'slub_integration'
logs.mkdir(exist_ok=True)
results = []


def run(name, command, timeout=90, markers=None, allow_failure=False):
    path = logs / (name + '.log')
    start = time.monotonic()
    with path.open('wb') as output:
        process = subprocess.Popen(command, cwd=root, stdout=output,
                                   stderr=subprocess.STDOUT, start_new_session=True)
        timed_out = False
        try:
            code = process.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            timed_out = True
            code = None
        finally:
            try:
                os.killpg(process.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
            process.wait()
    output = path.read_text(errors='replace')
    serial = Path('/tmp/lab2_grade/.qemu.out')
    if 'grade' in command and serial.exists():
        shutil.copyfile(serial, logs / (name + '_serial.log'))
    if markers is None:
        passed = code == 0 and not timed_out
        assertions = 'not_checked'
        kernel_entered = None
    else:
        kernel_entered = 'memory management:' in output
        passed = (code == 0 or timed_out) and all(m in output for m in markers)
        passed = passed and 'kernel panic' not in output and 'assertion failed' not in output
        assertions = 'passed' if passed else 'not_confirmed'
    if 'grade' in command:
        if 'Total Score: 20/20' in output:
            kernel_entered = True
            assertions = 'passed_via_original_grader'
        elif serial.exists() and 'memory management:' not in serial.read_text(errors='replace'):
            kernel_entered = False
            assertions = 'not_executed'
    if name == 'slub_boot':
        before = re.search(r'slub_check: begin free=(\d+)', output)
        after = re.search(r'slub_check\(\) succeeded! stages=7 restored (\d+)', output)
        passed = passed and before is not None and after is not None
        passed = passed and before.group(1) == after.group(1)
        assertions = 'passed' if passed else 'not_confirmed'
    result = dict(name=name, command=command, exit_code=code, timed_out=timed_out,
                  passed=passed, kernel_entered=kernel_entered, assertions=assertions,
                  seconds=round(time.monotonic()-start, 2))
    results.append(result)
    (logs / 'results.json').write_text(json.dumps(results, indent=2))
    print(json.dumps(result), flush=True)
    if not passed:
        print(output[-6000:], flush=True)
        if not allow_failure:
            raise SystemExit(1)


run('default_clean', ['make', 'clean'])
run('default_build', ['make', '-j2'])
# This exact invocation is mandatory and is never silently replaced by an adapter.
run('default_grade_raw', ['make', 'grade'], allow_failure=True)
adapter = work / 'qemu_grade_compat.py'
adapter.chmod(0o755)
run('default_grade_compatible', ['make', 'grade', 'QEMU=' + str(adapter)])
assert 'Total Score: 20/20' in (logs / 'default_grade_compatible.log').read_text()

for name, defs in [('buddy', '-DUSE_BUDDY'), ('slub', '-DUSE_BUDDY -DUSE_SLUB')]:
    run(name + '_clean', ['make', 'clean'])
    run(name + '_build', ['make', '-j2', 'DEFS=' + defs])
    markers = ['memory management: buddy_pmm_manager', 'buddy_check() succeeded!',
               'check_alloc_page() succeeded!', 'satp physical address:']
    if name == 'slub':
        markers += ['[SLUB T%02d] PASS' % i for i in range(1, 8)]
        markers.append('slub_check() succeeded! stages=7 restored')
    run(name + '_boot', ['make', 'qemu', 'DEFS=' + defs], timeout=12, markers=markers)

run('toolchain_versions', ['sh', '-c',
    'riscv64-unknown-elf-gcc --version; qemu-system-riscv64 --version; uname -a'])
