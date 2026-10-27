#!/bin/bash
set -ux
cd /mnt/e/os-labs/lab2/lab2_new
out=/mnt/e/os-labs/lab2/verification/page-init-20261022
exec > >(tee "$out/debug-boot.log") 2>&1
qemu-system-riscv64 -machine virt -nographic -bios default -kernel bin/ucore.img -S -gdb tcp:127.0.0.1:12349 > "$out/debug-console.log" 2>&1 &
qemu_pid=$!
trap 'kill "$qemu_pid" 2>/dev/null; wait "$qemu_pid" 2>/dev/null' EXIT
timeout 45s gdb-multiarch -q -batch -x "$out/boot.gdb"
echo "gdb_status=$?"
