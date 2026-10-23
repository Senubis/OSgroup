#!/bin/bash
set -euxo pipefail
cd /mnt/e/os-labs/lab2/lab2_new
out=/mnt/e/os-labs/lab2/verification/page-init-20261022
exec > >(tee "$out/make-qemu-check.log") 2>&1
set +e
timeout 20s make qemu 'KOBJS=$(filter-out obj/kern/mm/best_fit_pmm.o,$(call read_packet,kernel libs))' > "$out/make-qemu-console.log" 2>&1
status=$?
set -e
cat "$out/make-qemu-console.log"
echo "make_qemu_status=$status"
test "$status" = 124
grep -F 'check_alloc_page() succeeded!' "$out/make-qemu-console.log"
! grep -Ei 'panic|FAIL' "$out/make-qemu-console.log"
