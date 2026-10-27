set pagination off
set confirm off
set architecture riscv:rv64
file /mnt/e/os-labs/lab2/lab2_new/bin/kernel
target remote 127.0.0.1:12349
hbreak *0x80200034
continue
printf "\n--- identity entry before satp ---\n"
x/gx 0x80205010
stepi
printf "\n--- instruction fetch after satp works ---\n"
info registers pc satp
x/i $pc
stepi
info registers pc
delete breakpoints
hbreak kern_init
continue
printf "\n--- high virtual entry reached ---\n"
info registers pc sp satp
detach
quit
