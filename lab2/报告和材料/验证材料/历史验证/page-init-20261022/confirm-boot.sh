#!/bin/bash
set -ux
cd /mnt/e/os-labs/lab2/lab2_new
out=/mnt/e/os-labs/lab2/verification/page-init-20261022
exec > >(tee "$out/confirm-boot.log") 2>&1
qemu-system-riscv64 -machine virt -nographic -bios default -kernel bin/ucore.img -S -gdb tcp:127.0.0.1:12349 > "$out/after-debug-console.log" 2>&1 &
qemu_pid=$!
trap 'kill "$qemu_pid" 2>/dev/null; wait "$qemu_pid" 2>/dev/null' EXIT
timeout 45s gdb-multiarch -q -batch -x "$out/after-boot.gdb"
gdb_status=$?
echo "gdb_status=$gdb_status"
kill "$qemu_pid" 2>/dev/null
wait "$qemu_pid" 2>/dev/null
trap - EXIT
test "$gdb_status" = 0 || exit "$gdb_status"
timeout 8s qemu-system-riscv64 -machine virt -nographic -bios default -device loader,file=bin/ucore.img,addr=0x80200000 > "$out/after-old-loader.log" 2>&1
echo "old_loader_status=$?"
grep -F 'Domain0 Next Address' "$out/after-old-loader.log"
if grep -q 'DTB Init' "$out/after-old-loader.log"; then exit 1; fi
echo 'Old loader still does not enter kernel; -kernel is required in this environment.'
