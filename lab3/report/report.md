# Lab 3 实验报告：Trap 底层汇编

姓名：单馨淼  
学号：2412979

## 1. 本阶段内容

本阶段完成 `kern/trap/trapentry.S` 中的 Trap 底层汇编：

1. 根据 `SAVE_ALL` 实现 `RESTORE_ALL`。
2. 在 `__alltraps` 中把当前 Trap Frame 的地址作为参数传给 `trap()`。
3. 从 `trap()` 返回后恢复 Trap 上下文，并通过 `sret` 返回被中断的执行流。
4. 使用交叉编译、反汇编和 QEMU 上下文测试验证恢复结果。

## 2. 实现过程

### 2.1 Trap Frame 布局

`SAVE_ALL` 在栈上分配 `36 * REGBYTES` 字节。RV64 中 `REGBYTES` 为 8，因此一个 Trap Frame 占 288 字节。偏移 `0` 到 `31` 保存通用寄存器 `x0` 到 `x31`，偏移 `32` 到 `35` 依次保存 `sstatus`、`sepc`、`sbadaddr` 和 `scause`。

`x2` 是栈指针。进入 Trap 时，`SAVE_ALL` 先把原栈指针写入 `sscratch`，分配 Trap Frame 后再把原栈指针保存到偏移 `2 * REGBYTES`。因此恢复阶段不能先修改 `sp`，否则后续 `LOAD` 会失去 Trap Frame 的基址。

### 2.2 RESTORE_ALL

恢复顺序如下：

1. 从偏移 32 和 33 读取 `sstatus`、`sepc`，写回对应 CSR。
2. 恢复 `x1` 以及 `x3` 到 `x31`。
3. 最后从偏移 2 恢复 `x2/sp`。

`sbadaddr` 和 `scause` 描述本次 Trap 的原因，不参与返回状态恢复。`sret` 使用已经写回的 `sepc` 作为返回地址，并依据 `sstatus` 恢复 Trap 前的特权级与中断状态。

### 2.3 __alltraps

`SAVE_ALL` 执行后，`sp` 指向完整的 `struct trapframe`。RISC-V 调用约定使用 `a0` 传递第一个参数，因此入口代码执行：

```asm
move a0, sp
jal trap
```

这与 `void trap(struct trapframe *tf)` 的函数签名一致。`trap()` 返回后，执行流继续进入相邻的 `__trapret`，由 `RESTORE_ALL` 和 `sret` 完成返回。

## 3. Spec 与 Prompt

### 3.1 Spec

本阶段的约束是：

- Trap Frame 布局必须与现有 `SAVE_ALL` 和 `struct trapframe` 完全一致。
- `RESTORE_ALL` 必须恢复 `sstatus`、`sepc` 和 Trap 前的通用寄存器值。
- `sp` 必须最后恢复。
- `__alltraps` 必须把 Trap Frame 指针作为 `trap()` 的第一个参数。
- 返回路径必须经过 `__trapret`，并以 `sret` 结束。
- 只填写 `lab3 function1` 标记处，不实现中断与异常处理模块，不实现 Challenge。

### 3.2 Prompt

使用的 Prompt 核心内容是：

> 分析现有 `SAVE_ALL`、`struct pushregs` 和 `struct trapframe` 的字段顺序，在 `lab3 function1` 标记处生成严格对称的 `RESTORE_ALL`；恢复 CSR 后按原偏移恢复通用寄存器，最后恢复 `sp`。在 `__alltraps` 中按照 RISC-V ABI 把当前 `sp` 作为 `trap()` 的第一个参数。不得修改函数签名，不得实现 function2 或 Challenge，并给出汇编和 QEMU 验证方法。

这个 Prompt 把数据布局、调用约定、改动范围和验证条件放在同一组约束中，生成结果可以直接与源码结构和反汇编结果核对。

## 4. 验证

### 4.1 汇编与反汇编

使用 `riscv64-unknown-elf-gcc` 单独编译 `trapentry.S`。反汇编结果显示：

- 入口执行 `addi sp, sp, -288`，与 36 个 64 位字段一致。
- 调用前执行 `mv a0, sp` 和 `jal trap`。
- 返回路径写回 `sstatus` 和 `sepc`。
- `sp` 在其他通用寄存器之后恢复。
- 最后一条指令为 `sret`。

### 4.2 QEMU 上下文测试

在临时验证副本中加入仅用于返回断点的异常处理桩，运行 starter code 自带的 `test_lab3_register_context`。测试在 Trap 前为 `t0-t2`、`s0-s11`、`a1-a7` 和 `t3-t6` 写入不同值，执行 `ebreak`，返回后逐一比较。

最终输出为：

```text
Breakpoint at 0xc0201a28
[Test 1] Trap entry and breakpoint return: PASS (35/35)
```

该结果说明 Trap 处理函数调用没有破坏被测试的寄存器值，`sepc` 调整后程序也从断点后的正确位置继续执行。

## 5. 实际问题与解决过程

### 5.1 Lab 3 依赖 Lab 2 已完成代码

starter code 中保留了 Lab 2 的物理内存管理占位内容，直接构建会在 `page_init()` 和页分配器处失败。实验目录以 Lab 3 starter code 为骨架，迁入仓库中已经完成的 Lab 2 页初始化和分配器实现，同时保留 Lab 3 新增的中断保护代码。

### 5.2 QEMU 启动参数不兼容

starter code 使用 `-device loader,file=bin/ucore.img,addr=0x80200000` 启动。本机的 QEMU 6.2 与 OpenSBI 0.9 在该参数下把下一跳地址设置为 `0x0`，内核没有开始执行。改用 `-kernel bin/ucore.img` 后，OpenSBI 把下一跳地址设置为 `0x80200000`，内核正常启动。

### 5.3 断点指令长度

首次临时测试把 `sepc` 增加 4，返回后测试报告寄存器上下文失败。反汇编显示工具链把 `ebreak` 编码为 2 字节的压缩指令 `0x9002`。测试桩将 `sepc` 增加 2 后，程序从紧随断点的第一条校验指令继续执行，测试通过。

## 6. 知识点

Trap 上下文保存对应操作系统原理中的中断现场保护。原理课描述的是保存处理器状态、执行处理程序、恢复状态三个阶段；本实验把这三个阶段落实为栈上的 `struct trapframe`、C 函数 `trap()` 和汇编返回路径。

Trap Frame 与普通函数栈帧的区别在于保存范围。普通函数按照 ABI 只保存调用约定要求的寄存器；Trap 可以发生在任意指令之间，因此入口必须保存可能被处理过程改写的处理器状态。

`sret` 不只是一次普通跳转。它读取 `sepc` 决定返回地址，并根据 `sstatus.SPP`、`sstatus.SPIE` 更新特权级和中断使能状态。由此，CSR 恢复和通用寄存器恢复共同构成完整的 Trap 返回。

RISC-V 的 Trap 委托机制决定某类中断或异常最终进入 M 模式还是 S 模式。本实验直接处理的是已经委托到 S 模式的 Trap；委托关系由 OpenSBI 和相关 CSR 建立，不体现在 `RESTORE_ALL` 的指令序列中。
