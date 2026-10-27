#!/bin/bash
set -euxo pipefail
cd /mnt/e/os-labs/lab2/lab2_new
out=/mnt/e/os-labs/lab2/verification/page-init-20261022
exec > >(tee "$out/verify.log") 2>&1
make -j2 'KOBJS=$(filter-out obj/kern/mm/best_fit_pmm.o,$(call read_packet,kernel libs))'
set +e
timeout 8s qemu-system-riscv64 -machine virt -nographic -bios default -kernel bin/ucore.img > "$out/after-console.log" 2>&1
status=$?
set -e
cat "$out/after-console.log"
echo "qemu_status=$status"
test "$status" = 124
grep -F 'check_alloc_page() succeeded!' "$out/after-console.log"
! grep -Ei 'panic|FAIL' "$out/after-console.log"
