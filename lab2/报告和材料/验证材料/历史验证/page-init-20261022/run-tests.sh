#!/bin/bash
set -euxo pipefail
out=/mnt/e/os-labs/lab2/verification/page-init-20261022
exec > >(tee "$out/tests.log") 2>&1
if [ ! -d "$out/test-tree" ]; then
    python3 "$out/prepare-tests.py"
fi
cd "$out/test-tree"
make -j2 'KOBJS=$(filter-out obj/kern/mm/best_fit_pmm.o,$(call read_packet,kernel libs))'
for ram in 64 128 256; do
    set +e
    timeout 30s qemu-system-riscv64 -machine virt -m "${ram}M" -nographic -bios default -kernel bin/ucore.img > "$out/test-${ram}M.log" 2>&1
    status=$?
    set -e
    echo "RAM=${ram}M qemu_status=$status"
    test "$status" = 124
    cat "$out/test-${ram}M.log"
    grep -F '[Extra] Page Init: PASS' "$out/test-${ram}M.log"
    grep -F 'check_alloc_page() succeeded!' "$out/test-${ram}M.log"
    if [ "$ram" -le 128 ]; then
        grep -F '[Test 1] Page Init: PASS' "$out/test-${ram}M.log"
    fi
    ! grep -Ei 'panic|FAIL' "$out/test-${ram}M.log"
done
echo 'ALL INITIALIZATION CHECKS PASSED'
