# Lab3 模块一 AI 辅助学习与实验记录

负责人：2412979-单馨淼
实验内容：Trap 底层汇编（Assembly）

以下内容根据实际对话、代码阅读和实验操作过程整理。记录只涉及 `RESTORE_ALL`、`__alltraps`、Trap 上下文传递、`sret` 返回和恢复验证；指导书中的 Challenge 为旧版遗留内容，本次不完成。

# 用户提问 1

先不要修改代码。请先在 WSL 中确认实验环境能不能使用、仓库能不能访问，再阅读仓库和指导书。我的任务只有 Lab3 的 A 部分：根据已有的 `SAVE_ALL` 实现 `RESTORE_ALL`，实现 `__alltraps`，把 Trap Context 传给 `trap()`，最后用 `sret` 返回。请说明需要掌握的知识、需要修改的文件，以及这个模块和其他模块之间的依赖关系。不确定的地方先指出，不要擅自完成指导书没有要求的内容。

# AI 回答 1

已先完成环境和仓库检查，没有修改代码。

WSL 可以访问 Windows 下的实验目录，`D:\ML\OSlab2` 对应 `/mnt/d/ML/OSlab2`。仓库可以读取，当前实验分支为 `lab3`。模块一的主体集中在 Trap 入口汇编文件，现有 `SAVE_ALL`、Trap Frame 定义和 C 语言 `trap()` 是实现时的直接依据。

本模块需要掌握四组知识：

1. RISC-V Trap 发生后，硬件只自动更新少量 CSR，不会自动保存 32 个通用寄存器。
2. 汇编入口需要把寄存器和 CSR 按 `struct trapframe` 的布局保存到栈上，C 代码才能把栈顶地址解释为 Trap Context。
3. 调用 `trap()` 前必须遵守 RISC-V 调用约定，把 Trap Frame 指针放进参数寄存器 `a0`。
4. 返回前要恢复 `sstatus`、`sepc` 和通用寄存器，最后执行 `sret`。`sret` 根据 `sepc` 恢复执行位置，并根据 `sstatus` 恢复特权级和中断状态。

预期的控制流是：

```text
发生 Trap
    ↓
跳到 __alltraps
    ↓
SAVE_ALL 在内核栈构造 Trap Frame
    ↓
a0 = sp，把 Trap Frame 指针传给 trap()
    ↓
trap() 完成分发和处理
    ↓
RESTORE_ALL 恢复 CSR 和通用寄存器
    ↓
sret 返回 sepc 指向的位置
```

模块一只需要改 Trap 入口汇编。测试完整内核时会依赖 Lab2 已完成的内存管理代码；仓库中的 Lab3 初始版本还可能因为模块二没有实现而无法直接完成整套测试。这些依赖不扩大模块一的实现范围，可以先进行汇编编译、反汇编检查和隔离的 Trap 往返测试。

# 用户提问 2

请先不要写答案代码。结合现有 `SAVE_ALL` 和 `struct trapframe`，解释 Trap Frame 的布局。为什么一共有 36 个槽位？`RESTORE_ALL` 应该按什么顺序恢复？为什么 `sp` 必须最后恢复？

# AI 回答 2

`SAVE_ALL` 和 `RESTORE_ALL` 必须共享同一套内存布局。RV64 中每个寄存器占 8 字节，因此 36 个槽位共占 `36 × 8 = 288` 字节。

| 槽位 | 内容 | 数量 |
| --- | --- | ---: |
| 0～31 | `x0`～`x31` | 32 |
| 32 | `sstatus` | 1 |
| 33 | `sepc` | 1 |
| 34 | `sbadaddr` | 1 |
| 35 | `scause` | 1 |

四个 CSR 中，返回路径必须写回的是 `sstatus` 和 `sepc`：

- `sepc` 决定 `sret` 后从哪条指令继续执行。
- `sstatus` 中的 `SPP`、`SPIE` 等字段决定返回的特权级和中断状态。
- `scause` 和 `sbadaddr` 用于描述本次 Trap 的原因和相关地址，供处理函数读取，不负责控制 `sret` 的返回状态。

恢复时可以采用下面的顺序：

1. 从 Trap Frame 读取 `sstatus` 和 `sepc`，写回对应 CSR。
2. 恢复除 `x0`、`x2` 以外的通用寄存器。
3. 最后从 `x2` 对应的槽位恢复 `sp`。

`x0` 恒为 0，不需要恢复。`x2` 就是 `sp`，而当前 `sp` 同时还是 Trap Frame 的基址。若过早改写 `sp`，后续的 `LOAD offset(sp)` 会改用 Trap 前的栈地址，无法继续读取当前 Trap Frame。因此必须等其他字段都读取完成后再恢复 `sp`。恢复 `sp` 也就同时释放了这块 Trap Frame。

这个顺序不是任意约定，而是由“`sp` 既是待恢复寄存器，又是当前数据结构基址”这一事实决定的。

# 用户提问 3

现在解释 `__alltraps`。为什么把 `sp` 放进 `a0` 就能把 Trap Context 传给 `trap()`？`jal trap` 会覆盖 `ra`，为什么不会破坏 Trap 前的 `ra`？`sret` 又具体使用哪些状态完成返回？

# AI 回答 3

`SAVE_ALL` 执行完成后，`sp` 指向 Trap Frame 的首地址。C 函数原型中的第一个参数按照 RISC-V ABI 由 `a0` 传递，因此在调用 `trap()` 前执行 `move a0, sp`，C 代码收到的参数就是当前 Trap Frame 指针。

`jal trap` 会把本次函数调用的返回地址写入当前的 `ra`，但 Trap 发生前的 `ra` 已经由 `SAVE_ALL` 保存到 Trap Frame 的 `x1` 槽位。`trap()` 返回后，`RESTORE_ALL` 会从该槽位重新装载原来的 `ra`，所以 C 函数调用对 `ra` 的临时改写不会泄漏到被中断的程序中。

入口和返回的骨架应当是：

```asm
__alltraps:
    SAVE_ALL
    move a0, sp
    jal trap

__trapret:
    RESTORE_ALL
    sret
```

`sret` 主要使用已经恢复的 `sepc` 和 `sstatus`：

- 把程序计数器设置为 `sepc`。
- 根据 `sstatus.SPP` 决定返回到 S 模式还是 U 模式。
- 用 `sstatus.SPIE` 恢复中断使能状态，并按体系结构规则更新相关状态位。

因此，正确执行 `sret` 的前提不是只有一条 `sret` 指令，而是 Trap Frame 中的寄存器、`sepc` 和 `sstatus` 都在此前被正确恢复。

# 用户提问 4

请把前面的分析整理成一个可以直接约束实现过程的提示词，然后按提示词完成模块一。要求只修改 A 部分，不实现 Challenge，不顺手修改模块二或其他代码。完成后说明实际改了什么，但先不要推送。

# AI 回答 4

可以使用下面的实现提示词：

```text
[PROMPT]
在当前 Lab3 仓库中完成 Trap 底层汇编模块，只实现指导书要求的 A 部分。

[SCOPE]
1. 依据现有 SAVE_ALL 和 struct trapframe 实现 RESTORE_ALL。
2. 实现 __alltraps，在栈上构造 Trap Context，并把其地址作为第一个参数传给 trap()。
3. trap() 返回后恢复 Trap Context，使用 sret 返回。
4. 验证通用寄存器、sp、sepc、sstatus 和程序执行状态可以正确恢复。

[RELY]
1. 以仓库现有 SAVE_ALL 的保存顺序为唯一布局依据。
2. 以 trap.h 中 struct trapframe 的字段顺序核对偏移。
3. RV64 下 REGBYTES 为 8，Trap Frame 共 36 个槽位。
4. 按 RISC-V ABI 使用 a0 传递第一个参数。

[GUARANTEE]
1. 不恢复 x0。
2. sstatus 和 sepc 必须在 sret 前写回。
3. sp 是当前 Trap Frame 的寻址基址，必须最后恢复。
4. SAVE_ALL 保存的 Trap 前 ra 必须由 RESTORE_ALL 恢复。
5. 不实现 Challenge，不修改模块二，不重构无关代码。

[VERIFY]
1. 单独编译 Trap 汇编并检查反汇编结果。
2. 构造可控寄存器值触发 Trap，处理后比较返回前后的寄存器。
3. 检查 sret 后是否从预期 sepc 继续执行。
4. 若完整构建被其他模块阻断，记录依赖，并使用隔离测试验证模块一。
```

按照该提示词，实际实现内容如下：

1. 新增 `RESTORE_ALL` 宏，使用与 `SAVE_ALL` 完全相同的偏移读取 Trap Frame。
2. 将槽位 32 和 33 中的值分别写回 `sstatus` 和 `sepc`。
3. 恢复 `x1`、`x3`～`x31`，跳过恒为 0 的 `x0`，把 `x2/sp` 留到最后恢复。
4. 在 `__alltraps` 中先执行 `SAVE_ALL`，再令 `a0 = sp` 并调用 `trap()`。
5. `trap()` 返回后进入统一返回路径，执行 `RESTORE_ALL` 和 `sret`。

没有实现 Challenge，也没有修改模块二、Trap 分发逻辑或无关代码。此时只保留本地修改，等待验证后再决定是否提交。

# 用户提问 5

怎样验证“寄存器和程序执行状态能够正确恢复”？请实际检查。若测试失败，要区分是模块一错误、启动方式错误，还是测试本身的假设错误，并把排错过程讲清楚。

# AI 回答 5

验证分成静态检查和动态检查两部分。

静态检查先单独编译 Trap 入口汇编，再查看反汇编结果，确认：

1. Trap Frame 的分配大小为 288 字节。
2. 保存和恢复使用相同偏移。
3. `sstatus`、`sepc` 在 `sret` 前写回。
4. `sp` 最后恢复。
5. 调用 `trap()` 前 `a0` 指向 Trap Frame。
6. 返回路径最后一条特权指令为 `sret`。

这一步通过，说明汇编可以被工具链接受，且指令顺序和布局符合设计。

动态检查使用临时测试上下文给通用寄存器写入可识别的值，触发断点 Trap，在处理函数中检查 Trap Frame，再返回并比较寄存器。临时测试只服务于验证，没有并入实验代码。

第一次启动时使用了指导材料中的 `-device loader` 方式，但 OpenSBI 显示 `Next Address` 为 0，内核没有进入预期入口。这属于镜像装载方式问题。改用 QEMU 的 `-kernel bin/ucore.img` 后，内核能够进入测试入口。

随后测试在断点返回位置失败。反汇编显示汇编器把 `ebreak` 编码成压缩指令 `0x9002`，长度为 2 字节，而临时处理函数最初按普通 4 字节指令执行 `sepc += 4`，导致返回地址越过了下一条指令。把临时测试中的断点步长改为 2 字节后，返回位置正确。这个修正针对测试桩对指令长度的错误假设，不是修改 `RESTORE_ALL`。

最终测试输出包含：

```text
Breakpoint at 0xc0201a28
[Test 1] Trap entry and breakpoint return: PASS (35/35)
```

`35/35` 表明测试覆盖的通用寄存器和关键状态全部匹配；断点处理后还能从预期位置继续执行，说明 `sepc`、`sstatus` 和 `sret` 组成的返回路径有效。

完整 Lab3 初始工程的构建还依赖 Lab2 内存管理实现和当时尚未完成的模块二，因此没有把其他模块造成的构建阻断算作模块一失败。模块一已经通过独立汇编检查和隔离的 Trap 往返测试。

# 用户提问 6

最后请总结我应该真正掌握的知识，并给出可以写进实验报告的操作过程和结论。不要加入只为了防止反驳、但后面没有展开的句子。

# AI 回答 6

本模块的核心不是机械地补全一组 `LOAD`，而是保证 Trap 入口与返回遵守同一个上下文协议。

需要掌握的知识可以归纳为以下五点：

1. Trap 发生时，硬件保存的是控制状态，完整的通用寄存器现场必须由软件保存。
2. `SAVE_ALL` 的保存顺序、`struct trapframe` 的字段顺序和 `RESTORE_ALL` 的恢复偏移必须一致。
3. `sp` 在返回阶段具有双重身份：它既是待恢复的 `x2`，也是当前 Trap Frame 的基址，因此必须最后恢复。
4. 汇编通过 `a0` 把 Trap Frame 指针交给 C 函数；`ra` 可以被 `jal` 临时覆盖，是因为 Trap 前的 `ra` 已经保存在 Trap Frame 中。
5. `sret` 依赖恢复后的 `sepc` 和 `sstatus`。寄存器恢复、CSR 恢复和 `sret` 共同构成完整的 Trap 返回。

实验操作过程可以写为：先依据 `SAVE_ALL` 和 `struct trapframe` 核对 36 个槽位的布局，再实现对称的 `RESTORE_ALL`；随后在 `__alltraps` 中保存现场，将 `sp` 作为 Trap Context 指针通过 `a0` 传给 `trap()`；处理完成后恢复 CSR 和通用寄存器，并执行 `sret`。验证时先单独编译和反汇编 Trap 入口，再用临时上下文测试寄存器恢复和断点返回。测试过程中修正了 QEMU 镜像装载方式，并依据反汇编把压缩 `ebreak` 的返回步长改为 2 字节。

实验结论可以写为：`RESTORE_ALL` 能够按 Trap Frame 布局恢复 `sstatus`、`sepc` 和通用寄存器，`__alltraps` 能够把正确的 Trap Context 传给 `trap()`；Trap 处理完成后，测试程序通过 `sret` 从预期位置继续执行，隔离测试结果为 `PASS (35/35)`。







# Lab3 B 部分：作业讲解、代码修改与代码说明

负责人：2413015-孙若晴

## 1．用户

这是lab3的作业内容，请你查看代码和图片。我要做的是B部分，你先给我讲解一下我需要做什么


## 2．助手

结合图片和代码，**你负责 B：中断处理机制，核心是让内核持续接收时钟中断，完成计数、定期输出和自动关机。**

可以把定时器理解为一个“闹钟”：到达设定时间，CPU 暂停当前程序，执行你的处理函数；处理结束后，再继续原来的程序。

**1．你主要负责哪个函数**

主要文件是压缩包内的 `lab3/code/kern/trap/trap.c`，重点函数为：

```c
void interrupt_handler(struct trapframe *tf)
```

`tf` 保存了本次中断发生时的现场，包括中断原因、寄存器状态、返回地址等。你主要读取其中的 `tf->cause`，判断发生了什么中断。

整个流程是：

```text
时钟到点
   ↓
进入 Trap，保存现场                 ← A 负责
   ↓
trap() → trap_dispatch()
   ↓
interrupt_handler(tf)              ← 你负责
   ↓
恢复现场，返回原来的程序             ← A 负责
```

**2．你需要实现的四项核心逻辑**

**第一项：识别中断类型。**

`tf->cause` 同时包含“是否为中断”的标志和具体原因编号。处理时先去掉最高位的标志，再用 `switch` 分类。

你的重点分支是：

```c
case IRQ_S_TIMER:
```

它表示 **S 模式（监督者模式）的时钟中断**，也是这个实验中内核要响应的时钟中断。

**第二项：设置下一次时钟事件。**

每次处理时钟中断时，调用：

```c
clock_set_next_event();
```

这个函数在 `clock.c` 中，内部通过 `sbi_set_timer()`，把下一次触发时刻设置为“当前时间加上一个时间间隔”。

为什么每次都要调用？因为要形成下面这个连续过程：

```text
设置第一次事件 → 到点中断 → 设置下一次事件 → 再次中断 → ……
```

初始化负责第一次设置，你负责让后续中断持续发生。

**第三项：累计中断次数。**

每次进入时钟中断分支，执行：

```c
ticks++;
```

`ticks` 是 `clock.c` 中的全局变量，由时钟初始化函数清零，表示**累计发生了多少次时钟中断**。

注意两个区别：

- `ticks` 是中断次数，不直接等于秒数。
- 只有时钟中断才增加这个计数，其他中断不应增加。

**第四项：定期输出，达到阈值后关机。**

代码中两个配置分别控制打印间隔和关机条件：

```c
#define TICK_NUM 100
#define SHUTDOWN_AFTER 10
```

按这个配置：

| 条件 | 应执行的行为 |
|---|---|
| 每收到一次时钟中断 | `ticks` 加 1 |
| 每累计 100 次 | 调用 `print_ticks()` 输出一次 |
| 累计 10 组，即 1000 次 | 调用 `sbi_shutdown()` 关机 |

判断“是否累计到一组”，可以使用：

```c
ticks % TICK_NUM == 0
```

判断累计了多少组，可以使用：

```c
ticks / TICK_NUM
```

这里的 `print_ticks()` 输出固定文本 `100 ticks`，所以运行时应看到 10 行相同的 `100 ticks`。**图片没有明确规定具体次数，100 和 10 是代码中的配置，若老师另有数值要求，应按要求调整。**

**3．你的处理逻辑可以概括为**

```text
读取并识别中断原因
   ↓
如果是 S 模式时钟中断
   ├─ 设置下一次时钟事件
   ├─ ticks 加 1
   └─ 判断是否到达统计节点
          ├─ 到达：输出统计信息
          └─ 达到关机阈值：请求关机
```

此外，其他已定义中断可以输出相应提示；遇到未知中断，可以打印原因编号，并用 `print_trapframe(tf)` 输出现场，方便定位问题。

**4．你需要注意的分工和验证**

你与 C 都在 `trap.c` 中工作，需要协调各自的函数修改。C 负责 `exception_handler()` 中的非法指令和断点异常；你的重点是 `interrupt_handler()`。

**时钟中断处理应保持 `tf->epc` 不变。**它保存返回执行的位置，处理完时钟中断后，应继续被打断的执行流程。

验证时，你主要检查：

- 工程能够编译，内核启动后出现时钟初始化提示。
- 时钟中断能持续发生，`ticks` 持续增加。
- 按规定间隔输出统计信息。
- 达到规定次数后自动关机。
- 与 A 的现场恢复流程配合正常，中断返回后程序能够继续运行。

因此，你需要交付的内容主要是：**`interrupt_handler()` 的实现、时钟计数与关机的运行截图或日志，以及对上述处理流程的说明。**

---

## 3．用户

```csharp
[PROMPT]
任务：修改 lab3/code/kern/trap/trap.c，实现 B 部分
interrupt_handler()，完成中断分类、时钟计数、定时器重设、
统计输出和自动关机。
操作要求：直接修改实际文件，保留 A、C 已有代码。
输出要求：说明修改内容，提供编译和运行验证结果。

[RELY]
- struct trapframe：使用 cause 判断中断原因。
- libs/riscv.h：提供 IRQ_S_TIMER 等中断类型宏。
- ticks：已有全局时钟中断计数器。
- clock_set_next_event()：设置下一次时钟事件。
- print_ticks()：输出统计信息。
- print_trapframe()：输出未知中断现场。
- sbi_shutdown()：执行关机。
- 本次配置：TICK_NUM=100，SHUTDOWN_AFTER=10。

[GUARANTEE]
必须实现：
void interrupt_handler(struct trapframe *tf);

允许添加必要头文件和内部宏，不改变函数签名、
Trap 现场布局及已有异常处理逻辑。

[SPECIFICATION]
Pre-Condition：
tf 指向有效现场，时钟及相关接口已初始化。

Post-Condition：
正确处理中断，保持现场和返回地址不变；
正常处理后返回，达到阈值时关机。

Case 1：时钟中断
设置下一次事件，ticks 增加一次；每 100 次输出一次，
累计输出 10 次后关机。

Case 2：其他已知中断
输出对应类型提示，不修改时钟计数。

Case 3：未知中断
输出原因编号，并打印完整 Trap 现场。

Requirements：
正确排除 cause 最高位的中断标志，不修改 tf->epc。
通过编译、正常运行及原有评分验证，不修改测试条件。
```

## 4．助手

已修改实际文件 [trap.c](/C:/Users/HP/Documents/ChatGPT/OS2026/OSgroup/lab3/code/kern/trap/trap.c:87)，改动仅限 `interrupt_handler()`，A、C 代码和测试条件保持不变。

处理逻辑包括：

- 清除 `cause` 最高位标志后分类，保留原始现场和 `tf->epc`。
- 时钟中断每次计数一次，每 100 次打印一次，1000 次后关机。
- 在统计输出后重设定时器，避免串口打印消耗下一次间隔。
- 为已知中断输出提示，未知中断输出编号和完整现场。

验证结果：

| 检查 | 结果 |
|---|---|
| 编译 | 通过 |
| 正常运行 | 输出 10 行 `100 ticks` 后自动关机 |
| 原有评分 | **100/100** |

初轮评分出现 `ticks=201` 与预期文本不匹配；调整定时器重设顺序后，完整评分通过，未修改测试条件。

[验证记录与日志说明](/C:/Users/HP/Documents/ChatGPT/OS2026/lab3-b-verification/b-20261105/verification.md)

---

## 5．用户

讲解一下我负责部分的代码

## 6．助手

你负责的核心函数是 [trap.c 中的 `interrupt_handler()`](/C:/Users/HP/Documents/ChatGPT/OS2026/OSgroup/lab3/code/kern/trap/trap.c:87)。它接收中断现场，判断中断类型，然后执行对应处理。其中最重要的是 **S 模式时钟中断：计数、打印、安排下一次事件、达到阈值后关机。**

下面按代码的执行顺序讲。

**1．函数参数 `tf` 是什么**

```c
void interrupt_handler(struct trapframe *tf)
```

`tf` 是一个指针，指向保存中断现场的 `struct trapframe`。

你需要关注两个字段：

| 字段 | 含义 | 你的使用方式 |
|---|---|---|
| `tf->cause` | 为什么进入 Trap | 读取它，判断中断类型 |
| `tf->epc` | Trap 返回后继续执行的位置 | 保持不变 |

进入这个函数前，A 负责的汇编已经保存了寄存器等状态，并把现场地址传给 C 函数。

调用关系是：

```text
__alltraps
    ↓
trap(tf)
    ↓
trap_dispatch(tf)
    ↓
interrupt_handler(tf)
```

其中 `trap_dispatch()` 先区分“中断”和“异常”，再决定调用你的函数还是 C 负责的 `exception_handler()`。

**2．先从 `cause` 中提取中断原因编号**

```c
const uintptr_t interrupt_flag =
    (uintptr_t)1 << (sizeof(uintptr_t) * 8 - 1);

const uintptr_t cause = tf->cause & ~interrupt_flag;
```

`tf->cause` 不是一个单纯的编号，它的结构可以理解为：

```text
最高位：是否为中断
其余位：具体原因编号
```

以 RV64 的 S 模式时钟中断为例：

```text
原始值：0x8000000000000005
        ↑              ↑
     中断标志         原因编号 5
```

第一条语句构造一个“只有最高位是 1”的数：

```c
(uintptr_t)1 << (sizeof(uintptr_t) * 8 - 1)
```

逐步看：

- `uintptr_t` 是能容纳指针数值的无符号整数类型。
- RV64 中它通常占 8 字节，即 64 位。
- `sizeof(uintptr_t) * 8 - 1` 得到 `63`。
- 把 `1` 左移 63 位，就得到 `0x8000000000000000`。

先把 `1` 转为 `uintptr_t`，是为了让移位在正确的整数宽度上执行。

第二条语句：

```c
tf->cause & ~interrupt_flag
```

`~interrupt_flag` 的最高位是 0，其余位都是 1。按位与之后，**只清除最高位，保留原因编号**：

```text
0x8000000000000005
清除最高位
                  ↓
0x0000000000000005
```

结果放在局部变量 `cause` 中，**没有改写 `tf->cause`**，因此打印现场时还能看到原始原因值。`const` 表示这两个局部变量在初始化后不再被修改。

**3．用 `switch` 区分中断类型**

```c
switch (cause) {
    ...
}
```

提取原因编号之后，用 `riscv.h` 中的宏进行匹配。

例如：

```c
case IRQ_S_SOFT:
    cprintf("Supervisor software interrupt\n");
    break;
```

含义是：如果这是监督者软件中断，就输出对应提示，然后离开 `switch`。

代码中的主要类别包括：

| 宏的后缀 | 含义 |
|---|---|
| `SOFT` | 软件中断 |
| `TIMER` | 时钟中断 |
| `EXT` | 外部中断 |

此外，代码还为 `IRQ_COP` 和 `IRQ_HOST` 输出对应提示。

**这些提示分支没有执行 `ticks++`，因此其他类型的中断不会被算成时钟中断。**这些分支提供的是基本识别和提示，并没有实现完整的设备处理流程。

**4．核心：处理 `IRQ_S_TIMER`**

你的时钟分支是：

```c
case IRQ_S_TIMER:
    ticks++;

    if (ticks % TICK_NUM == 0) {
        print_ticks();
    }

    clock_set_next_event();

    if (ticks >= TICK_NUM * SHUTDOWN_AFTER) {
        sbi_shutdown();
    }
    break;
```

可以拆成四步理解。

**① 记录本次时钟中断**

```c
ticks++;
```

`ticks` 在 [clock.c](/C:/Users/HP/Documents/ChatGPT/OS2026/OSgroup/lab3/code/kern/driver/clock.c:7) 中定义：

```c
volatile size_t ticks;
```

它记录从时钟初始化开始，累计处理了多少次时钟中断。`clock_init()` 会把它初始化为 0。

这里的 `volatile` 告诉编译器：这个变量可能被当前正常执行流程之外的中断处理修改，读取时需要考虑其实际内存值。它本身不保证操作是原子的。

注意，**`ticks` 表示中断次数，不是秒数**；每次进入这个时钟分支只增加一次。

**② 每 100 次输出一次**

```c
if (ticks % TICK_NUM == 0) {
    print_ticks();
}
```

配置是：

```c
#define TICK_NUM 100
```

`%` 是取余运算。当 `ticks` 能被 100 整除时，条件成立：

```text
ticks = 99   → 余数 99 → 不打印
ticks = 100  → 余数 0  → 打印
ticks = 101  → 余数 1  → 不打印
ticks = 200  → 余数 0  → 打印
```

`print_ticks()` 中的普通输出语句是：

```c
cprintf("%d ticks\n", TICK_NUM);
```

它打印的是 `TICK_NUM`，所以每次都显示：

```text
100 ticks
```

这表示“又经过了 100 次中断”，而不是显示累计总数。打印后也没有清零 `ticks`，它仍然继续累计。

另外，`print_ticks()` 中的 `#ifdef DEBUG_GRADE` 是条件编译代码；只有定义这个宏时，才会额外执行测试结束提示和 `panic()`。

**③ 设置下一次时钟事件**

```c
clock_set_next_event();
```

它的实现是：

```c
void clock_set_next_event(void) {
    sbi_set_timer(get_cycles() + timebase);
}
```

虽然函数名叫 `get_cycles()`，这里实际使用的是 `rdtime` 指令，读取时间计数值。接着加上 `timebase`，通过 SBI 请求设置新的定时器截止时刻。

含义就是：

```text
下一次触发时刻 = 当前时间 + 一个间隔
```

初始化负责安排第一次事件；你的处理函数负责安排后续事件，从而形成：

```text
初始化设置事件 → 时钟中断 → 设置下一次事件 → 时钟中断 → ……
```

这里把重设操作放在统计输出之后，是为了让下一次间隔从输出结束后开始计算，避免串口打印较慢时，下一次事件在本次处理返回前就到期。

**④ 达到 1000 次后关机**

```c
if (ticks >= TICK_NUM * SHUTDOWN_AFTER) {
    sbi_shutdown();
}
```

两个配置是：

```c
#define TICK_NUM 100
#define SHUTDOWN_AFTER 10
```

因此阈值为：

```text
100 × 10 = 1000 次时钟中断
```

第 1000 次中断时，执行顺序是：

```text
ticks 增加到 1000
    ↓
打印第 10 行 “100 ticks”
    ↓
设置下一次时钟事件
    ↓
调用 sbi_shutdown() 请求关机
```

`sbi_shutdown()` 通过 SBI 向底层固件发出关机请求；在实验的 QEMU 环境中，表现为模拟器退出。

**5．未知中断怎么处理**

```c
default:
    cprintf("Unknown interrupt: cause %lu\n",
            (unsigned long)cause);
    print_trapframe(tf);
    break;
```

没有匹配到任何已知类型时，执行 `default`：

1. 打印去掉最高位标志后的原因编号。
2. 打印完整 Trap 现场，包含通用寄存器、状态、返回地址和原始原因值等信息。

这是为了帮助排查问题。**打印现场是诊断行为，并不意味着已经消除了未知中断的来源。**

**6．为什么你不修改 `tf->epc`**

时钟中断是计时事件，正常程序只是暂时被打断。处理结束后，应从保存的返回位置继续执行，因此你的函数不调整 `tf->epc`。

而 C 负责的非法指令、断点等异常，可能需要按实验策略跳过触发异常的指令，所以会调整 `epc`。

你的函数正常返回后，执行流会回到 A 的汇编返回路径，由它恢复现场并执行 `sret`。代码中的 `break` 只是离开 `switch`；**真正从 Trap 返回的操作是后面的 `sret`**。









# Lab3 模块二 异常处理与测试 AI 辅助学习与实验记录
负责人：2411356-华轩宁
# 用户提问 1

我负责 Lab3 的异常处理与测试。指导书和代码在这个目录，请先不要修改代码。帮我找出我需要完成哪些函数、哪些已经由框架提供，以及大概需要理解哪些知识。

14:17

# AI 回答 1

用时 2分钟 9秒

已经对照指导书和当前代码检查过。按你负责“异常处理与测试”的分工，你主要需要实现 exception_handler()，并在队友完成异常入口、寄存器恢复和中断处理后做联合测试。 本次没有修改项目代码，也没有编译或运行测试。

指导书依据：E:\os-labs\lab3\lab3流程.pdf

1．你需要完成什么

你要补的函数位于 [trap.c 第 83 行附近 (line 83)](E:/os-labs/lab3/lab3_new/kern/trap/trap.c:83)，目前这里只有 //lab3 function2 YOUR CODE，函数本身还没写出来：
void exception_handler(struct trapframe *tf);
tf 可以理解为“异常发生时的现场记录”，里面保存了异常原因、指令地址和各寄存器的值。
处理情况	你需要完成的行为
非法指令，`CAUSE_ILLEGAL_INSTRUCTION`，原因码为 2	输出规定的提示信息，正确推进 tf->epc，让程序能越过本次测试的非法指令继续运行
断点，`CAUSE_BREAKPOINT`，原因码为 3	输出断点信息，按实际指令长度推进 tf->epc，返回后继续运行
其他异常	调用已有的 print_trapframe(tf) 输出现场；指导书不要求实现完整的异常恢复

这里最关键的是 tf->epc 决定返回后从哪里执行。如果只打印信息，没有跳过触发异常的测试指令，返回后就可能再次触发同一异常，形成死循环。

也不能把所有情况都简单写成“地址加 4”：指导书明确要求考虑指令长度。当前非法指令测试明确使用 4 字节指令；断点测试的指令长度需要结合实际生成的机器码确认。

2．哪些已经提供，哪些还需要队友补
部分	当前状态	作用及与你的关系
struct trapframe、`struct pushregs`	已提供	定义现场记录的布局，你直接使用
SAVE_ALL	已实现	把寄存器和异常信息保存到栈上
idt_init()	已实现	设置异常入口地址
trap()、`trap_dispatch()`	已实现	把事件分给中断处理函数或异常处理函数
print_trapframe()、`print_regs()`	已实现	输出现场，供你的兜底分支调用
RESTORE_ALL	留空	恢复现场，属于汇编部分
__alltraps 中调用 C 函数的部分	留空	把现场记录传给 trap()
interrupt_handler()	尚未实现	处理时钟等中断，属于中断处理部分
时钟初始化、设置下一次时钟事件、开关中断接口	已实现	给中断处理和联合测试使用

可以从 [trap.h (line 41)](E:/os-labs/lab3/lab3_new/kern/trap/trap.h:41) 看现场结构，从 [trapentry.S (line 3)](E:/os-labs/lab3/lab3_new/kern/trap/trapentry.S:3) 看保存、调用和恢复过程。

所以，你写完异常函数，并不代表整个 Lab3 就能运行。 断点返回测试同时依赖队友的入口和恢复代码；它失败时，需要一起判断是哪一段出了问题。

3．你负责的测试大概有哪些

目录已经提供测试代码和评分脚本，三组检查如下，见 [grade.sh (line 56)](E:/os-labs/lab3/lab3_new/tools/grade.sh:56)。
测试	分值	主要检查什么
入口、寄存器恢复、断点返回	35	触发断点后能否返回，测试设置的寄存器值是否保留
非法指令返回与兜底处理	25	能否跳过非法指令；软件中断、未知中断及其他异常是否输出预期信息
持续时钟中断	40	能否持续收到中断，输出 100 ticks，并累计到 ticks=200

你后续的测试工作主要是：
1. 确认异常真的发生了：能看到 Breakpoint at、`Illegal instruction at` 等预期输出。
2. 确认处理完能继续执行：不能只看到异常提示，还要看到后面的测试通过信息。
3. 与队友做联合验证：检查寄存器恢复、持续时钟中断及总评分。
4. 保存真实证据：记录测试命令、输出、截图，以及失败原因和修复过程，供报告使用。
测试函数已经放在 [test_lab3.c (line 14)](E:/os-labs/lab3/lab3_new/tools/test_lab3.c:14)。`make grade` 会复制代码到临时目录，再加入测试；不过它也会先清理当前目录的构建产物，所以本次没有执行。

有一个需要之后和队友核对的差异：指导书要求达到规定次数后关机，但当前代码没有定义 SHUTDOWN_AFTER，现有评分脚本也没有验证关机行为。 因此，自动评分通过后，仍需要另外核对指导书的关机要求。

4．你需要理解哪些知识

建议按下面的顺序学，每项先理解到能解释本实验的行为即可。
知识	大白话解释	本次需要理解到什么程度
Trap、中断、异常	Trap 是统一叫法；中断通常来自定时器等事件，异常由当前指令触发	能解释为什么时钟和非法指令进入不同函数
scause / tf->cause	记录“为什么停下来”	最高位区分中断和异常，其余部分给出原因码
sepc / tf->epc	记录“处理完从哪里继续”	能解释为什么异常测试需要推进地址，而时钟中断不能随意推进
指令长度	一条指令实际占多少字节	知道 RISC-V 中可能有 2 字节和 4 字节指令，不能统一猜偏移
上下文与 Trap frame	把原来运行程序的现场保存下来	知道 C 函数会使用寄存器，所以必须先保存、最后恢复
sstatus 与 sret	保存返回所需的状态，并执行异常返回	知道 sret 根据保存的状态和地址返回，不是普通函数的 ret
时钟重新设置	每次响铃后预约下一次响铃	能判断为什么只计数、不设置下一次事件，会导致持续测试失败

你应当能顺着下面这条调用路线讲清楚：
指令触发异常
→ __alltraps
→ SAVE_ALL 保存现场
→ trap(tf)
→ trap_dispatch(tf)
→ exception_handler(tf)       ← 你主要实现这里
→ 返回汇编入口
→ RESTORE_ALL 恢复现场
→ sret 从更新后的地址继续执行
另外，指导书后半部分讲到用户态返回，但本次内核中的异常测试也可能返回内核态，不要把“异常返回”一律理解成“回到用户态”。

建议第一步先读懂 trapframe 中的 cause 和 epc，再看 trap_dispatch() 怎样调用你的函数；这两处理解清楚，就能开始独立整理异常处理的实现要求。

14:19

# 用户提问 2

cause 和 epc 分别是什么？能结合这份代码讲一遍异常发生到返回的过程吗？

14:30

# AI 回答 2

cause 记录“为什么发生异常”，`epc` 记录“处理完以后从哪个地址继续执行”。 在这份代码里，它们都是异常现场记录 struct trapframe 的成员。

先把硬件寄存器和 C 结构体中的字段对应起来：
硬件寄存器	保存到内存后的字段	本次用途
scause	tf->cause	判断发生了哪种中断或异常
sepc	tf->epc	保存、调整返回后的执行地址

1．`cause`：发生了什么

例如，CPU 执行到非法指令时，硬件会把原因码 2 写入 scause；执行到断点指令时，原因码是 3。代码里已有对应名称：
CAUSE_ILLEGAL_INSTRUCTION   // 2：非法指令
CAUSE_BREAKPOINT            // 3：断点
此外，`scause` 的最高位用来区分两大类事件：
- 最高位为 1：中断，例如时钟中断。
- 最高位为 0：异常，例如非法指令、断点。
这就是 [trap.c (line 86)](E:/os-labs/lab3/lab3_new/kern/trap/trap.c:86) 中这段判断的依据：
if ((intptr_t)tf->cause < 0) {
    interrupt_handler(tf);
} else {
    exception_handler(tf);
}
这里把 cause 转成有符号整数。当前是 64 位系统，最高位为 1 时，按有符号整数解释就会成为负数，因此 < 0 表示进入中断处理分支。

2．`epc`：处理完从哪里继续

对于本实验的非法指令和断点异常，硬件保存的 sepc 指向触发异常的那条指令。

假设一条 4 字节的非法指令位于地址 0x80201000：
0x80201000：非法指令       ← sepc 保存这个地址
0x80201004：下一条指令
如果异常处理函数只打印提示，没有调整返回地址，那么返回后又会执行 0x80201000 的非法指令，于是再次进入异常处理。

本实验要求跳过这种测试指令，因此需要把 tf->epc 调整到下一条指令。这里的偏移取决于实际指令长度，不能把所有异常统一加 4。

下面把这些字段放进完整流程。

3．第一步：CPU 发现异常，先记录关键信息

假设执行到断点指令。

硬件会完成与进入 S 模式处理程序有关的动作，包括：
- 把断点指令地址写入 sepc。
- 把断点原因码 3 写入 scause。
- 更新 sstatus 中的中断使能和原特权级信息。
- 跳到 stvec 指定的入口。
你们的 idt_init() 已经设置好了这个入口：
write_csr(stvec, &__alltraps);
所以接下来进入 __alltraps。

注意，硬件不会自动把全部通用寄存器保存进 trapframe，这需要下面的汇编代码完成。

4．第二步：`SAVE_ALL` 把现场保存到栈上

[trapentry.S (line 65)](E:/os-labs/lab3/lab3_new/kern/trap/trapentry.S:65) 的入口首先执行：
__alltraps:
    SAVE_ALL
SAVE_ALL 会在栈上预留空间，保存通用寄存器，并读取几个与异常有关的硬件寄存器：
csrr s1, sstatus
csrr s2, sepc
csrr s3, sbadaddr
csrr s4, scause
然后按固定位置把它们存入内存：
STORE s1, 32*REGBYTES(sp)
STORE s2, 33*REGBYTES(sp)
STORE s3, 34*REGBYTES(sp)
STORE s4, 35*REGBYTES(sp)
这些位置与 [trap.h (line 41)](E:/os-labs/lab3/lab3_new/kern/trap/trap.h:41) 中的结构体对应：
struct trapframe {
    struct pushregs gpr;  // 32 个通用寄存器槽位
    uintptr_t status;
    uintptr_t epc;
    uintptr_t badvaddr;
    uintptr_t cause;
};
因此，保存完成后：
tf->epc   = 进入异常时读取的 sepc
tf->cause = 进入异常时读取的 scause
此时它们是内存中的现场副本。修改 tf->epc，并不会立即改变硬件的 sepc。

5．第三步：汇编把现场交给 C 函数

接下来，`__alltraps` 需要把这份现场记录的地址作为参数，调用：
trap(tf);
这一段正是当前代码里尚未补全的部分。按 RISC-V 的函数调用约定，第一个参数通过 a0 传递，因此队友需要让 a0 指向刚保存的 trapframe，再调用 trap()。

进入 C 后，路径是：
trap(tf)
  → trap_dispatch(tf)
    → exception_handler(tf)
因为这是断点异常，`cause` 的最高位为 0，所以进入你负责的异常处理函数。

6．第四步：你的函数处理异常，调整返回位置

你的 exception_handler() 需要根据 tf->cause 判断具体异常。

对于断点：
1. 识别 CAUSE_BREAKPOINT。
2. 输出规定的断点信息。
3. 根据断点指令的实际长度，推进 tf->epc。
4. 正常返回。
这里，你是在告诉后续恢复代码：
“现场大体照原样恢复，但继续执行的位置改成断点后面的指令。”

对于未要求专门处理的异常，指导书要求调用已有的 print_trapframe(tf) 输出现场。输出现场本身不代表异常已经恢复；如果原故障仍存在，返回后仍可能再次触发。

7．第五步：恢复现场，再执行 sret

C 函数依次返回后，执行流回到汇编：
__trapret:
    RESTORE_ALL
    sret
RESTORE_ALL 目前也还留空。它应当与 SAVE_ALL 对应，从现场记录中恢复通用寄存器，并把保存的 status、可能已经被你修改的 epc 写回相应硬件寄存器。

于是形成这条关键路径：
CPU 将异常指令地址写入 sepc
→ SAVE_ALL 将 sepc 保存为 tf->epc
→ 你的函数调整 tf->epc
→ RESTORE_ALL 将 tf->epc 写回 sepc
→ sret 跳到 sepc 指定的位置
最后的 sret 根据保存的状态决定返回哪个特权级，并从 sepc 指定的地址继续执行。本实验如果是在内核中触发断点，处理后可以返回内核继续执行。

对比来看，时钟中断通常保留原来的 epc：原程序只是暂时被打断，没有一条需要跳过的故障指令，应该从保存的位置接着运行。

你负责的核心就是中间这一步：读 cause 判断发生了什么，再按实验要求决定怎样处理 epc。 当前入口调用、异常处理和现场恢复都还有空缺，上面描述的是补全后应当形成的流程。

14:30

# 用户提问 3

1.”需要专门处理的异常“包括什么？2.测试中的指令是不是4字节？也就是说处理断点和异常的时候也要从断开的下一条指令开始执行？

16:41

# AI 回答 3

用时 1分钟 15秒

本实验需要专门处理的是“非法指令”和“断点”两类异常；这两类测试处理后都要跳到下一条指令，但指令长度不一定相同。

1．“需要专门处理的异常”包括什么？

按这份指导书，你的 exception_handler() 需要区分：
异常	cause	本实验要求
非法指令	2	输出 Illegal instruction at ...，推进 epc，继续执行
断点	3	输出 Breakpoint at ...，推进 epc，继续执行
其他异常	其他值	调用 print_trapframe(tf) 输出现场，不要求实现具体恢复

所以不需要你在 Lab3 中实现缺页处理、非法访存恢复等完整功能。

另外，测试里有一段：
tf.cause = 20;
exception_handler(&tf);
这是人为构造一个现场记录，直接调用你的函数，检查其他异常是否会走兜底输出；它没有真的执行一条触发原因码 20 的指令，也没有经过 sret 返回。

2．测试指令是不是 4 字节？

要分开看。

非法指令测试明确写在 [test_lab3.c (line 14)](E:/os-labs/lab3/lab3_new/tools/test_lab3.c:14) 中：
asm volatile(".word 0x0000007b");
这里确定是 4 字节，所以对于这条测试指令：
原 epc → 非法指令
epc + 4 → 下一条指令
断点测试在 [test_lab3_context.S (line 34)](E:/os-labs/lab3/lab3_new/tools/test_lab3_context.S:34) 中写的是：
ebreak
仅看这个写法，还不能确定最终占 4 字节。 RISC-V 有普通的 4 字节断点指令，也有压缩的 2 字节断点指令；汇编器是否生成压缩形式，取决于构建设置。当前 Makefile 没有明确指定 -march，因此要查看实际生成的机器码才能确认。本次没有完成这项编译核验。
实际生成的断点指令	长度	应推进的地址
普通 ebreak	4 字节	epc + 4
压缩 c.ebreak	2 字节	epc + 2

3．所以异常处理后，都从下一条指令执行吗？

对本实验这两类主动触发的异常测试，是的。 测试故意放入非法指令或断点，要求你识别、打印信息、跳过它，再执行后面的检查代码。

但不能推广到所有异常：
- 本实验的非法指令、断点测试：跳过触发异常的指令。
- 时钟中断：保留 epc，从被打断的位置继续，不能随意跳过指令。
- 缺页异常等情况：通常在修复问题后，重新执行原来的指令。例如先补上缺失的页面，再重试刚才的访存。
因此，你写代码时应当按“具体异常的要求”决定是否推进 epc，而不是在函数末尾对所有异常统一加 4。

17:39

# 用户提问 4

[PROMPT]
请完成 uCore RISC-V Lab3 的“异常处理与测试”任务，实际修改工程文件。

工程目录：E:\os-labs\lab3\lab3_new\
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

17:51

# AI 回答 4

用时 11m 57s

已实际补齐异常处理。**直接检查和隔离环境测试通过；正式工程整体仍被其他依赖阻挡。**

- 修改了 [trap.c (line 88)](/E:/os-labs/lab3/lab3_new/kern/trap/trap.c:88)，实现异常分类；[trap.h (line 50)](/E:/os-labs/lab3/lab3_new/kern/trap/trap.h:50) 增加函数声明。原有分发、现场布局和入口恢复代码保持原样。
- 非法指令输出信息后 `epc += 4`，依据课程测试的 `.word 0x0000007b`。断点根据编码跳过 2 或 4 字节；已确认课程 `ebreak` 实际编译为 2 字节。其他异常调用 `print_trapframe(tf)`，不修改返回地址。
- 直接调用检查通过；隔离副本课程评分 **100/100**，覆盖断点返回、指定寄存器恢复、非法指令返回和持续时钟至 `ticks=200`。补充 QEMU 测试确认两种长度断点及非法指令之后的代码均能执行。
- 正式工程编译首先遇到 `sbadaddr` 工具链兼容错误，另有入口恢复、中断处理及内存初始化缺失。隔离适配没有覆盖回正式工程，默认启动没有加入异常测试。
- 尚未验证正式工程完整运行、定次关机；未做旧 Challenge。下一步应集成其他模块后，在正式工程重新编译、启动和评分。

完整命令、原始日志、隔离差异及覆盖边界见 [验证报告](/E:/os-labs/lab3/verification/c-exception/REPORT.md)；答辩讲解和复演步骤见 [现场演示说明](/E:/os-labs/lab3/verification/c-exception/DEMO.md)。实现对应指导书“功能模块二”的异常处理部分。E:/os-labs/lab3/lab3流程.pdf















