# 操作系统实验报告

## 实验基本信息

| 项目 | 内容 |
|------|------|
| **实验名称** | Lab 3：断，都可以断 |
| **小组成员** | 2412979-单馨淼 2413015-孙若晴 2411356-华轩宁|
| **完成日期** | 2026/11/04|

# Lab 3 实验报告：Trap 底层汇编



### 小组分工

| 成员 | 负责的练习/模块 |
|------|----------------|
| 2412979-单馨淼 | 模块一：Trap 上下文恢复与 Trap 入口 |
| 2411356-华轩宁 | 模块二中的异常处理与测试：exception_handler()、补充检查及与模块一的本地整合 |
| | |

---

## 一、实验目的

异常处理与测试的主要目标如下：

1. 理解异常发生后，CPU 如何记录异常原因和故障指令地址，以及这些信息如何进入 `struct trapframe`。
2. 实现非法指令和断点异常的识别、信息输出与返回地址调整，使程序能够继续执行异常指令之后的代码。
3. 对其他异常调用已有函数输出现场，保持返回地址不变。
4. 使用课程原有测试和最小补充测试，检查异常处理与已有入口、现场恢复代码之间的配合，并区分函数直接调用与真实异常测试的覆盖范围。

---

## 二、实验环境

你们使用的 AI 工具

| 成员 | AI 编程工具 | 底层模型 | 备注 |
|------|------------|---------|------|
| 2412979-单馨淼 | | | |
| 2411356-华轩宁 | Codex | GPT-6 | 使用 Codex 辅助完成异常处理代码 |
| | | | |


---

## 三、实验整体逻辑分析

### 2.1 本章节的逻辑主线

异常发生后，CPU 把原因写入 `scause`，把故障指令地址写入 `sepc`，再进入 `stvec` 指向的入口。入口保存现场后调用 `trap()`，由 `trap_dispatch()` 区分中断和异常，再把同步异常交给 `exception_handler()`。处理函数根据现场中的 `cause` 输出信息，并在实验要求跳过故障指令时更新 `epc`。后续恢复代码把这个返回地址写回 `sepc`，最后由 `sret` 返回。

本部分实现 C 语言异常处理函数，并与模块一的入口和寄存器恢复流程衔接。

### 2.2 功能的逐步实现

1. **准备基础环境**：沿用 Lab2 的内存初始化与页分配功能，为内核运行提供基础，使后续 Trap 处理能够在已有的内存环境中展开。
2. **完成 Trap 入口和现场恢复**：依据已有的 `SAVE_ALL` 实现 `RESTORE_ALL`，并在 `__alltraps` 中把现场地址传给 C 语言处理函数。处理结束后恢复寄存器，通过 `sret` 返回，建立完整的 Trap 进入与返回流程。
3. **实现中断与异常处理**：在入口能够正确传递现场的基础上，根据 `cause` 区分中断和异常，分别处理时钟中断、非法指令、断点及其他情况；需要跳过的异常指令还要按实际长度调整 `epc`。
4. **形成持续时钟中断流程**：初始化时钟，在每次时钟中断后设置下一次事件，完成计数、统计输出及达到规定次数后的关机行为，使单次中断处理连接成持续运行的流程。
5. **进行整体测试**：待各模块整合完成后，统一检查异常返回、寄存器恢复和持续时钟中断，再运行课程评分，确认入口、处理函数与返回流程之间的配合。

---

## 四、实验内容与实现

### 功能模块一：Trap 上下文恢复与 Trap 入口

**负责人：** 2412979-单馨淼

#### 模块功能描述

**需要实现/修改的函数：**

位于 `kern/trap/trapentry.S`，需要实现以下汇编功能：

- `RESTORE_ALL`：汇编宏，按现场布局恢复 `sstatus`、`sepc` 和通用寄存器，最后恢复栈指针 `sp`。
- `__alltraps`：Trap 入口，在保存现场后，将当前 Trap Frame 地址作为参数传给 `trap(struct trapframe *tf)`。

**功能说明：**

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

#### 最终提示词

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

#### 实现迭代过程

## 5. 实际问题与解决过程

### 5.1 Lab 3 依赖 Lab 2 已完成代码

starter code 中保留了 Lab 2 的物理内存管理占位内容，直接构建会在 `page_init()` 和页分配器处失败。实验目录以 Lab 3 starter code 为骨架，迁入仓库中已经完成的 Lab 2 页初始化和分配器实现，同时保留 Lab 3 新增的中断保护代码。

### 5.2 QEMU 启动参数不兼容

starter code 使用 `-device loader,file=bin/ucore.img,addr=0x80200000` 启动。本机的 QEMU 6.2 与 OpenSBI 0.9 在该参数下把下一跳地址设置为 `0x0`，内核没有开始执行。改用 `-kernel bin/ucore.img` 后，OpenSBI 把下一跳地址设置为 `0x80200000`，内核正常启动。

### 5.3 断点指令长度

首次临时测试把 `sepc` 增加 4，返回后测试报告寄存器上下文失败。反汇编显示工具链把 `ebreak` 编码为 2 字节的压缩指令 `0x9002`。测试桩将 `sepc` 增加 2 后，程序从紧随断点的第一条校验指令继续执行，测试通过。


---

### 功能模块二：异常处理与测试

### 函数一
**负责人：**

---

### 函数二

**负责人：** 2411356-华轩宁

#### 模块功能描述

**需要实现/修改的函数：**

```c
void exception_handler(struct trapframe *tf);
```

该函数位于 `kern/trap/trap.c`。同时在 `kern/trap/trap.h` 增加公开声明，并在 `trap.c` 增加已有分发代码所需的 `interrupt_handler()` 前置声明。

**功能说明：**

输入是已有 Trap 入口保存的有效现场。函数通过 `tf->cause` 识别异常类型，输出要求的信息，必要时调整 `tf->epc`，然后交回原有 Trap 返回流程。

| 异常类型 | 本次处理 | 返回位置调整及依据 |
|----------|----------|--------------------|
| `CAUSE_ILLEGAL_INSTRUCTION` | 输出 `Illegal instruction at ...` | 课程测试使用 `.word 0x0000007b`，长度为 4 字节，因此 `epc += 4` |
| `CAUSE_BREAKPOINT` | 输出 `Breakpoint at ...` | 读取故障指令的首个 16 位半字；最低两位为 `11` 时跳过 4 字节，否则跳过 2 字节，覆盖本实验的 ebreak 与 c.ebreak |
| 其他异常 | 调用已有 `print_trapframe(tf)` | 保持 epc 不变 |

课程源代码中的 `ebreak` 可能被工具链编码成 2 字节的 `c.ebreak`（`0x9002`）；普通 `ebreak` 的编码是 `0x00100073`，占 4 字节。断点处理需要根据实际编码决定返回位置，否则可能跳过断点后第一条校验指令。

实现代码如下：

```c
void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
        case CAUSE_ILLEGAL_INSTRUCTION:
            cprintf("Illegal instruction at 0x%016lx\n", tf->epc);
            /* Lab3 tests use .word 0x0000007b, a 32-bit custom opcode.
             * This is the lab's skip policy, not general illegal-op recovery. */
            tf->epc += 4;
            break;
        case CAUSE_BREAKPOINT:
            cprintf("Breakpoint at 0x%016lx\n", tf->epc);
            /* ebreak = 0x00100073; c.ebreak = 0x9002. Read only the
             * first halfword so a compressed breakpoint needs no next page. */
            tf->epc += (*(const uint16_t *)tf->epc & 3) == 3 ? 4 : 2;
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
```

#### 最终提示词

异常处理使用以下任务提示词求。

````markdown
[PROMPT]
请完成 uCore RISC-V Lab3 的“异常处理与测试”任务，实际修改工程文件。

工程目录：E:\os-labs\lab3\lab3_new
实验指导书：E:\os-labs\lab3\lab3流程.pdf

在 kern/trap/trap.c 中实现 exception_handler()，处理非法指令、
断点及其他异常。

先阅读指导书、实际代码和原有测试，确认当前实现状态，再补充缺失功能。
已有的正确代码保留。
今年无需完成旧版 Challenge，包括用户态与内核态切换测试。

[RELY]
结合以下现有定义、接口和测试实现：
1. kern/trap/trap.c 中的 trap_dispatch()、trap()、
   print_trapframe() 及已有处理逻辑。
2. kern/trap/trap.h 中的 struct trapframe，
   特别是 cause、epc 和寄存器现场字段。
3. libs/riscv.h 中的异常原因常量和相关定义。
4. kern/trap/trapentry.S 中的 SAVE_ALL、RESTORE_ALL、
   __alltraps 和 __trapret，理解现场传递与返回流程。
5. tools/test_lab3.c、tools/test_lab3_context.S、
   tools/test_lab3.h、tools/grade.sh、tools/inject.py 和 Makefile，
   核对测试注入方式、期望输出、指令长度和运行命令。

整体测试时，按需检查时钟初始化、中断处理和内存初始化是否具备。
以指导书、实际代码和原有测试为依据。

[GUARANTEE]
实现并保持以下接口：
void exception_handler(struct trapframe *tf);

输入为已有 Trap 入口保存并传入的有效现场。
函数根据 tf->cause 识别异常，完成规定的信息输出和必要的
tf->epc 更新，再交回已有 Trap 返回流程。

完成后应保证：
1. 正确识别并处理非法指令和断点异常。
2. 对本实验要求跳过的异常指令，正确更新返回位置，
   避免反复执行同一条异常指令。
3. 对其他未要求专门处理的异常，调用已有的
   print_trapframe(tf) 输出现场。
4. 保持 struct trapframe 布局、公开接口和已有分发、
   入口、恢复、中断处理逻辑不被擅自改动。
5. 测试与正常运行流程分开，默认启动不自动执行补充异常测试。

[SPECIFICATION]
Pre-Condition：
- 检查当前工程、已有修改和依赖功能的完成状态。

Case 1：非法指令异常
- 识别 CAUSE_ILLEGAL_INSTRUCTION。
- 按指导书和原有测试要求输出异常信息。
- 根据本实验实际使用的指令编码及长度更新 tf->epc，
  说明判断依据。
- 验证处理后能执行异常指令之后的代码。

Case 2：断点异常
- 识别 CAUSE_BREAKPOINT。
- 按规定输出断点信息。
- 核对测试实际使用的断点指令长度，正确更新 tf->epc。
- 验证异常处理后继续执行，并结合原有测试检查寄存器恢复。

Case 3：其他异常
- 调用 print_trapframe(tf) 输出现场。
- 不无条件增加 epc，不自行扩展处理功能。

Case 4：修改范围与依赖
- 正式功能修改以 exception_handler() 为主，
  必要时增加最少的头文件或辅助函数，并说明原因。
- 如依赖尚未完成，说明具体缺失及影响，继续完成可独立进行的工作。
- 如需隔离测试，使用独立目录或副本，记录与正式工程的差异。

Case 5：测试与整体验证
- 优先阅读并使用课程原有测试。
- 依赖齐备后执行编译、make qemu 和 make grade。
- 检查断点与非法指令处理后能否继续执行、
  寄存器恢复是否正确，以及其他异常的现场输出。
- 整体测试同时核对持续时钟中断和原评分要求，
  发现其他模块问题时提供复现步骤及定位依据。
- 对原有测试未覆盖的关键异常行为，按需增加最小补充测试。
- 区分直接调用 exception_handler() 的检查与真实触发异常的
  QEMU 测试。

Case 6：验证记录与现场演示
- 在 E:\os-labs\lab3\verification\c-exception 下保存必要的
  测试说明、实际命令、原始日志和结果汇总。
- 明确区分通过、失败、未运行和因依赖缺失而无法执行的项目。
- 如使用隔离副本或环境适配，说明差异并分别记录结果。
- 准备解释异常入口、cause 与 epc 的含义、
  更新 epc 的原因和长度依据，以及如何证明异常处理后继续执行。

Post-Condition：
交付异常处理实现、必要的补充测试、验证记录和现场演示说明。

最后说明：
1. 修改了哪些文件以及修改原因；
2. 实现对应指导书的哪些内容；
3. 各类异常的处理方式和返回位置更新依据；
4. 实际执行的检查、结果及覆盖范围；
5. 尚未验证的内容和下一步。
````


#### 实现迭代过程

实现过程如下。

##### 核对框架并实现异常处理

最初的独立 Lab3 工程中，`exception_handler()` 还没有实现，入口恢复、中断处理和部分内存依赖也不完整。因此先依据已有的 `struct trapframe`、原因常量和测试用例完成可以独立实现的异常分支。

实现前核对了非法指令测试的 `.word 0x0000007b`，以及课程上下文测试中 `ebreak` 的实际编码。断点处理根据编码区分 2 字节和 4 字节。

**最终结果：** 完成异常处理实现。

---


## 五、测试与验证

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

**测试截图：**

---

## 六、实验总结与收获

### 对操作系统的理解

## 6. 知识点

Trap 上下文保存对应操作系统原理中的中断现场保护。原理课描述的是保存处理器状态、执行处理程序、恢复状态三个阶段；本实验把这三个阶段落实为栈上的 `struct trapframe`、C 函数 `trap()` 和汇编返回路径。

Trap Frame 与普通函数栈帧的区别在于保存范围。普通函数按照 ABI 只保存调用约定要求的寄存器；Trap 可以发生在任意指令之间，因此入口必须保存可能被处理过程改写的处理器状态。

`sret` 不只是一次普通跳转。它读取 `sepc` 决定返回地址，并根据 `sstatus.SPP`、`sstatus.SPIE` 更新特权级和中断使能状态。由此，CSR 恢复和通用寄存器恢复共同构成完整的 Trap 返回。

RISC-V 的 Trap 委托机制决定某类中断或异常最终进入 M 模式还是 S 模式。本实验直接处理的是已经委托到 S 模式的 Trap；委托关系由 OpenSBI 和相关 CSR 建立，不体现在 `RESTORE_ALL` 的指令序列中。


### 异常处理部分的理解与收获

| 实验中的内容 | 对应 OS 原理 | 本次理解 |
|--------------|-------------|----------|
| cause 区分异常原因 | 中断与异常的分类处理 | 处理函数根据异常原因选择对应行为，中断由 trap_dispatch 分发给 interrupt_handler |
| epc 保存并更新故障位置 | 异常返回与恢复执行流 | 本实验的非法指令和断点属于同步异常，保存位置指向故障指令；实验选择跳过时，必须按实际长度更新返回位置 |
| 使用已有 trapframe | 现场保护和恢复 | C 函数调整现场中的返回地址，入口汇编恢复寄存器并执行 sret，二者共同完成异常返回 |
| 未知异常打印现场 | 异常诊断与恢复策略 | 通过现场输出定位异常，保留故障位置供后续分析 |

OS 原理中还有本部分没有实现的内容：进程调度与时间片切换、缺页后的页面调入、系统调用参数检查和完整用户态保护。

### AI 协作开发的经验

以下经验来自异常处理的实现过程。

1. 提示词需要把实际接口和原有测试一起交给 AI。仅写“处理断点”容易忽略压缩指令，明确要求核对编码与长度后，才能让返回地址的修改有依据。

---
