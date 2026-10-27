#!/bin/bash
set -euxo pipefail
cd /mnt/e/os-labs/lab2/lab2_new
out=/mnt/e/os-labs/lab2/verification/best-fit-20261022
exec > >(tee "$out/verify.log") 2>&1
# Full default build: do not filter out any allocator objects.
make -B -j2
set +e
timeout 30s make qemu > "$out/kernel-console.log" 2>&1
status=$?
set -e
cat "$out/kernel-console.log"
echo "qemu_status=$status"
test "$status" = 124
grep -F 'memory management: best_fit_pmm_manager' "$out/kernel-console.log"
grep -F 'check_alloc_page() succeeded!' "$out/kernel-console.log"
! grep -Ei 'panic|FAIL' "$out/kernel-console.log"
