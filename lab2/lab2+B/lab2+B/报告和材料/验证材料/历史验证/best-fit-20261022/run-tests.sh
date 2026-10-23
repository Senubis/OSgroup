#!/bin/bash
set -euxo pipefail
out=/mnt/e/os-labs/lab2/verification/best-fit-20261022
exec > >(tee "$out/tests.log") 2>&1
python3 "$out/prepare-tests.py"
cd "$out/test-tree"
make -j2 DEFS=-Ducore_test
for ram in 64 128; do
    set +e
    timeout 30s qemu-system-riscv64 -machine virt -m "${ram}M" -nographic -bios default -kernel bin/ucore.img > "$out/test-${ram}M.log" 2>&1
    status=$?
    set -e
    cat "$out/test-${ram}M.log"
    echo "RAM=${ram}M qemu_status=$status"
    test "$status" = 124
    grep -F 'grading: 6 / 6 points' "$out/test-${ram}M.log"
    grep -F 'check_alloc_page() succeeded!' "$out/test-${ram}M.log"
    grep -F '[Test 1] Page Init: PASS' "$out/test-${ram}M.log"
    grep -F '[Test 2] Best-Fit: PASS' "$out/test-${ram}M.log"
    test "$(grep -c '^\[Extra\].*PASS' "$out/test-${ram}M.log")" = 4
    ! grep -Ei 'panic|FAIL' "$out/test-${ram}M.log"
done
echo 'ALL BEST-FIT CHECKS PASSED'
