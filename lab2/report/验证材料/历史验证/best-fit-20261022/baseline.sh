#!/bin/bash
set -ux
cd /mnt/e/os-labs/lab2/lab2_new
out=/mnt/e/os-labs/lab2/verification/best-fit-20261022
exec > >(tee "$out/baseline.log") 2>&1
date -Iseconds
riscv64-unknown-elf-gcc --version
qemu-system-riscv64 --version
make -j2
echo "baseline_make_status=$?"
