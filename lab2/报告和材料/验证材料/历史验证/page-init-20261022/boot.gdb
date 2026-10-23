set pagination off
set confirm off
set architecture riscv:rv64
target remote 127.0.0.1:12349
hbreak *0x80200000
continue
printf "\n--- physical kernel entry ---\n"
info registers pc a0 a1
x/20i $pc
delete breakpoints
hbreak *0x80200034
continue
printf "\n--- before enabling satp ---\n"
info registers pc t0 satp stvec
x/4gx 0x80205000
x/gx 0x80205ff8
delete breakpoints
stepi
printf "\n--- immediately after satp ---\n"
info registers pc satp
stepi
printf "\n--- next instruction ---\n"
info registers pc scause sepc stval stvec
detach
quit
