#!/bin/bash
set -ux
cd /mnt/e/os-labs/lab2/lab2_new
out=/mnt/e/os-labs/lab2/verification/page-init-20261022
exec > >(tee "$out/baseline.log") 2>&1
date -Iseconds
uname -a
riscv64-unknown-elf-gcc --version
qemu-system-riscv64 --version
command -v gdb-multiarch riscv64-unknown-elf-gdb gdb
make -j2
echo "default_make_status=$?"
make -j2 'KOBJS=$(filter-out obj/kern/mm/best_fit_pmm.o,$(call read_packet,kernel libs))'
echo "filtered_make_status=$?"
timeout 8s qemu-system-riscv64 -machine virt -nographic -bios default -device loader,file=bin/ucore.img,addr=0x80200000 > "$out/before-loader.log" 2>&1
echo "loader_status=$?"
timeout 8s qemu-system-riscv64 -machine virt -nographic -bios default -kernel bin/ucore.img -d in_asm -D "$out/before-kernel-trace.log" > "$out/before-kernel.log" 2>&1
echo "kernel_status=$?"
tail -60 "$out/before-kernel-trace.log"
riscv64-unknown-elf-objdump -d bin/kernel > "$out/before-disassembly.txt"
