#!/usr/bin/env python3
"""QEMU 7/OpenSBI compatibility adapter; original grading sources stay intact.

The supplied grader loads a raw kernel with generic loader only. On this host
that leaves OpenSBI's next address at zero. Use QEMU's -kernel boot protocol
for exactly that argument; preserve every other grading option unchanged.
Pass this executable as the Makefile QEMU variable, never edit grade.sh.
"""
import os
import sys

args = []
i = 1
while i < len(sys.argv):
    arg = sys.argv[i]
    if arg == '-device' and i + 1 < len(sys.argv):
        device = sys.argv[i + 1]
        if device.startswith('loader,file=') and device.endswith(',addr=0x80200000'):
            filename = device[len('loader,file='):-len(',addr=0x80200000')]
            args.extend(['-kernel', filename])
            i += 2
            continue
    args.append(arg)
    i += 1
os.execvp('qemu-system-riscv64', ['qemu-system-riscv64'] + args)
