# 操作系统实验报告

## 实验基本信息

| 项目 | 内容 |
|------|------|
| **实验名称** | Lab4：虚拟内存页操作与内核线程管理 |
| **小组成员** | 2412979-单馨淼 2413015-孙若晴 2411356-华轩宁|
| **完成日期** | |

### 小组分工

| 成员 | 负责的练习/模块 |
|------|----------------|
| 2411356-华轩宁 | 功能模块一：虚拟内存页操作 |
| 2412979-单馨淼 | 功能模块二：进程创建及初始化 |
| 2413015-孙若晴 | 功能模块三：进程调度与上下文切换 |


---

## 一、实验目的

本阶段完成虚拟内存页操作与内核进程创建，实验目的如下。

1. 理解 Sv39 多级页表如何建立虚拟页与物理页之间的映射关系。
2. 实现页映射的建立、替换、权限更新和撤销，维护页表项与物理页引用计数的一致性。
3. 理解 TLB（处理器缓存的地址翻译结果）与页表的关系，掌握映射变化后进行缓存失效处理的必要性。
4. 理解进程控制块、内核栈、trapframe 和 context 在内核线程创建过程中的作用。
5. 实现 idleproc 与 initproc 的初始化，建立新内核线程第一次运行所需的寄存器和栈状态。
6. 通过 WSL 编译与 QEMU 运行检查进程创建结果。

---

## 二、实验环境

| 成员 | AI 编程工具 | 底层模型 | 备注 |
|------|------------|---------|------|
| 2411356-华轩宁 | Codex | GPT6.1-Sol | AI 协助源码分析、代码实现、验证脚本及报告整理 |
| 2412979-单馨淼 | Codex | GPT6.1-Sol | AI 协助进程创建代码分析、实现、WSL/QEMU 验证及报告整理 |
| 2413015-孙若晴 | Codex | GPT6.2-Sol | AI 协助调度实现、QEMU/GDB 验证、启动缺页排查及报告整理 |



---

## 三、实验整体逻辑分析

### 3.1 本章节的逻辑主线

页映射操作需要同时维护三种状态：页表记录虚拟地址对应的物理页及访问权限；引用计数记录物理页仍被多少次引用；TLB 保存 CPU 最近使用的地址翻译。只更新页表而不维护引用计数，可能造成提前释放或泄漏；映射变化后不处理 TLB，则可能继续使用旧地址翻译。

### 3.2 功能的逐步实现

1. **A：虚拟内存页操作。** 先核对已有页表查询、物理页分配和引用计数接口，再实现插入与删除映射，最后分别检查软件页表状态和真实访问路径。
2. **B：进程创建及初始化。** 初始化进程控制块和全局进程表，创建 idleproc 与 initproc，并为 initproc 准备首次运行所需的内核栈、trapframe 和 context。

3. **C：进程调度与上下文切换。** 在本地中断保护下选出可运行线程，更新当前进程和页表，最后恢复目标线程的寄存器上下文，使 `initproc` 从 `idleproc` 接过 CPU。

---

## 四、实验内容与实现

### 功能模块一：虚拟内存页操作

**负责人：** 2411356-华轩宁

#### 模块功能描述

**需要实现/修改的函数：**

```c
int page_insert(pde_t *pgdir, struct Page *page,
                uintptr_t la, uint32_t perm);
void page_remove(pde_t *pgdir, uintptr_t la);

// 文件内部的删除辅助函数。
static void page_remove_pte(pde_t *pgdir, uintptr_t la, pte_t *ptep);
```

上述函数位于 `kern/mm/pmm.c`。另为已有 `tlb_invalidate()` 中的 `sfence.vma` 内联汇编补充 `memory` 编译器屏障，约束相关内存访问的编译器重排。

**功能说明：**

`page_insert()` 把指定物理页映射到目标虚拟页，支持首次映射、同页重映射、权限更新及替换旧物理页；`page_remove()` 撤销已有映射。删除时引用计数归零才释放物理页，未映射地址和重复删除均安全返回。

本模块复用 `get_pte()` 查找或创建中间页表，复用 `pte_create()` 编码叶子页表项。当前框架中的 `pte_create()` 已自动添加有效位 `PTE_V`，传入的是物理页号而非物理地址。

#### 最终提示词

```text
[PROMPT]
请完成 uCore RISC-V Lab4 的功能模块一：虚拟内存页操作，实际修改工程。
先阅读指导书、项目指令、源码和原有测试，核对实际工程及已有实现。
在 kern/mm/pmm.c 中实现 page_insert、page_remove 及必要的删除辅助函数。

[RELY]
依赖当前工程的 Sv39 多级页表结构、pde_t、pte_t、struct Page、
页表权限位、页大小及地址转换宏。
核对 get_pte、get_page、pte_create、pte2page、page_ref 系列、
alloc_page、free_page、tlb_invalidate 和 flush_tlb 的实际语义。
读取 check_pgdir、check_boot_pgdir、tools/test_lab4.c、Makefile
及评分注入脚本。
调用方提供有效的页表根、已分配的物理页及符合框架约定的参数。
前置依赖缺失时明确记录位置和影响。

[GUARANTEE]
保持公开接口、Page 布局、课程测试断言和其他成员代码不变。
成功建立映射时返回 0，获取页表项失败时返回 -E_NO_MEM。
正确处理首次映射、同页重映射、权限更新、异页替换和删除。
维护引用计数，避免同页重映射时误释放，避免重复删除造成重复释放。
更新映射后调用框架的 TLB 失效接口。
测试结果区分正式工程、主机替身环境、QEMU 测试副本和诊断副本。

[SPECIFICATION]
Pre-Condition：确认工程、已有修改、辅助函数语义和前置依赖状态。
Case 1：插入先调用 get_pte(pgdir, la, 1)，失败立即返回错误；中间页表的失败处理遵循已有 get_pte 契约。
Case 2：目标无有效映射时，增加一次引用，写入物理页号和权限。
Case 3：目标已映射同一物理页时，引用计数净变化为 0，更新权限。
Case 4：目标已映射其他页时，正确撤销旧引用，归零才释放，
再完成新映射，并处理 TLB。
Case 5：删除使用 get_pte(pgdir, la, 0)，不创建中间表；有效映射
统一由辅助函数减引用、归零释放、清项并使 TLB 失效。
Case 6：空映射与重复删除安全返回。
Case 7：优先执行课程原测试；按需补最小边界验证。依赖或环境阻塞时
保留日志。
Post-Condition：交付实现、实际验证记录、报告材料和交接说明，
列出失败与未验证项.
```

#### 实现要求说明 specification

| 场景 | 预期行为 |
|------|----------|
| 目标尚无映射 | 建立映射，物理页引用增加一次 |
| 同一地址再次映射同一页 | 更新权限，引用计数净变化为零，不释放该页 |
| 同一地址改映射另一页 | 解除旧引用，必要时释放旧页，建立新映射 |
| 同一物理页映射多个地址 | 每个映射分别计入引用，删除一个不影响其他映射 |
| 获取目标页表项失败 | 返回 `-E_NO_MEM`，目标页引用不变 |
| 删除有效映射 | 减引用、必要时释放、清空目标项、处理 TLB |
| 删除未映射地址或重复删除 | 安全返回，不分配新页表，不重复释放 |

#### 实现思路

`page_insert()` 先执行 `get_pte(pgdir, la, 1)`。若返回空指针，立即返回 `-E_NO_MEM`。此时还未增加目标物理页的引用。若创建第二层中间表失败，已经创建的第一层表按原 `get_pte()` 契约保留。

取得目标项后，先增加新物理页的一次引用。如果原项有效且指向同一物理页，就抵消刚增加的引用；若指向其他物理页，则调用 `page_remove_pte()` 删除旧映射。最后用 `pte_create(page2ppn(page), perm)` 写入新项并处理 TLB。

同页重映射不能简单地先删除再重建。旧映射可能是该页的最后一次引用，先删除会使引用归零并释放该页；再写回就会把已释放的页重新用于映射。

`page_remove()` 使用 `get_pte(pgdir, la, 0)`，只查询已有页表。内部辅助函数检查有效位，有效时减少一次引用，计数归零才释放，随后清空页表项并使 TLB 失效。

#### 实现迭代过程

##### 第一阶段：功能模块一 的实现与隔离验证

正式工程最初因 Lab2/Lab3 前置缺项无法正常构建，评分注入还受 `proc_init()` 缺失阻塞。因此先通过主机侧测试检查 功能模块一 的逻辑，使用替身代替分配器、地址转换和 TLB。原样提取的 `check_pgdir()`、课程 PMM 测试和最小补充边界检查均通过。

验证过程中，脚本最初未能提取指针返回函数，头文件搜索顺序也出现冲突，调整提取规则和搜索路径后解决。初期 QEMU 隔离启动未获得测试输出，后续结合前置代码补齐继续排查。

##### 第二阶段：补齐前置代码并检查真实访问

后续将既有 Lab2/Lab3 成果中的内存初始化、最佳适应分配器、中断/异常处理及寄存器恢复补入正式工程，并进行启动和编译适配。沿用 Lab4 的 `Page` 布局、功能模块一 实现、原测试和 `forkrets`，为后续线程模块整合准备运行条件。

补齐后，正式工程全部 C/汇编源文件生成目标文件，最终链接仍因 `proc_init()` 和 `cpu_idle()` 未定义停止。原评分注入因 `proc_init()` 缺失停止，未取得正式分数。

为独立检查内存模块，测试副本使用真实迁入分配器和 功能模块一 实现，通过单独入口运行内存检查，不调用 B/C。QEMU 中 `check_alloc_page()`、`check_pgdir()` 通过，随后 `check_boot_pgdir()` 写入虚拟地址 `0x100` 时触发存储缺页异常，`cause=15`。

检查发现，原 `get_pte()` 为两层中间页表项设置 `PTE_U | PTE_V`，原 `check_pgdir()` 又要求根项的 U 位为 1。RISC-V 标准要求此类非叶子项的 U 位清零，框架设置与标准页表格式存在冲突。这解释了两种检查结果的差异：`check_pgdir()` 检查表项内容，而后续写入由 CPU 实际遍历页表，触发了格式检查。

独立诊断副本在异常后仅清除两层中间项 U 位、刷新 TLB 并重试同一条指令，随后原 `check_boot_pgdir()`、`kmalloc_init()` 和课程 PMM 测试通过，进一步支持了对中间项 U 位问题的定位。

中间页表项的相关规则见 [RISC-V 官方特权级规范](https://docs.riscv.org/reference/isa/priv/supervisor.html)。

**当前进度：** 功能模块一 的映射和引用计数逻辑通过主机侧检查，QEMU 已通过分配器检查和 `check_pgdir()`。功能模块二已完成，功能模块三完成后再进行完整调度与整组评分。

### 功能模块二：进程创建及初始化

**负责人：** 2412979-单馨淼

#### 模块功能描述

本模块在 `kern/process/proc.c` 中实现以下函数：

```c
static struct proc_struct *alloc_proc(void);
static int copy_mm(uint32_t clone_flags, struct proc_struct *proc);
static void copy_thread(struct proc_struct *proc, uintptr_t esp,
                        struct trapframe *tf);
int kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags);
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf);
void proc_init(void);
```

`alloc_proc()` 初始化进程控制块的状态、PID、内核栈、地址空间、上下文和链表节点。`proc_init()` 初始化进程链表与 PID 哈希表，建立 pid 为 0 的 idleproc，再通过 `kernel_thread()` 和 `do_fork()` 创建 pid 为 1 的 initproc。

`kernel_thread()` 把线程函数和参数放入 `s0`、`s1`，把首次执行地址设为 `kernel_thread_entry`。`copy_thread()` 把 trapframe 放在新内核栈顶部，令 `context.ra` 指向 `forkret`、`context.sp` 指向 trapframe。调度到新线程后，执行路径为 `forkret -> forkrets -> __trapret -> kernel_thread_entry -> init_main`。

`do_fork()` 依次分配进程控制块和内核栈，处理地址空间，复制线程现场，分配 PID，加入进程链表及哈希表，最后把子进程设为可运行。分配失败时按已取得资源的逆序释放。Lab4 当前只创建内核线程，因此 `copy_mm()` 检查当前进程没有用户地址空间后返回。

#### 最终提示词

```text
[PROMPT]
完成 uCore RISC-V Lab4 功能模块二“进程创建及初始化”，只修改指导书要求的 proc.c 练习二区域，不实现练习三。

[RELY]
先核对 proc_struct、trapframe、context、kernel_thread_entry、forkret、forkrets、__trapret、进程链表、PID 哈希表、内核栈分配和课程测试断言。沿用已完成的功能模块一及 Lab2/Lab3 前置代码。

[GUARANTEE]
初始化 PCB 的全部字段；建立 idleproc 和 initproc；保持新线程首次运行链路与 RISC-V sret 恢复规则一致；do_fork 失败时释放已经分配的资源；不实现 cpu_idle、proc_run 或其他练习三内容；不 push。

[SPECIFICATION]
alloc_proc 返回 PROC_UNINIT、pid=-1 且上下文清零的 PCB。
kernel_thread 把函数、参数、状态寄存器和入口地址写入临时 trapframe。
copy_thread 把 trapframe 放到内核栈顶，子进程 a0 为 0；传入栈为 0 时，恢复后的 sp 指向该 trapframe。
do_fork 完成父子关系、内核栈、地址空间、现场、PID、链表、哈希表和 RUNNABLE 状态设置。
proc_init 建立 pid=0 的 idleproc 与 pid=1 的 initproc。
在 WSL 中编译，并在不修改正式练习三代码的临时副本中运行课程进程创建断言。
```

#### 实现迭代过程

首先对照指导书、本地 `lab4` 目录和 GitHub 最新代码。最新代码已完成功能模块一，`proc.c` 中功能模块二和功能模块三仍为占位区。本地与 GitHub 最新 `proc.c` 的有效内容一致，因此同一份练习二实现写入两处，运行验证使用包含功能模块一成果的 GitHub 最新代码副本。

实现时先初始化 PCB，再完成 `kernel_thread()`、`copy_thread()` 和 `do_fork()`。其中 `copy_thread()` 对内核线程的空栈参数进行转换，使恢复后的 `sp` 指向新线程内核栈中的 trapframe。PID 分配和链表插入放在关中断区间，插入完成后调用 `wakeup_proc()`。

WSL 全量重编时，所有 C/汇编文件均生成目标文件，最终链接只报告 `cpu_idle` 未定义。`cpu_idle` 属于功能模块三，本批没有写入正式代码。随后在临时副本中加入不参与调度的 `cpu_idle` 验证桩和课程 `Process Create` 断言。临时内核构建成功，QEMU 输出 `[Test Lab4] Process Create PASS`，之后继续响应时钟中断。验证完成后删除临时副本。

### 功能模块三：进程调度与上下文切换

**负责人：** 2413015-孙若晴

#### 模块功能描述

本模块将处理器从 `idleproc` 切换到已经创建的 `initproc`，并使新线程进入 `init_main()`。四个接口分布在以下三个文件中。

| 文件 | 接口 | 实现内容 |
|------|------|----------|
| `kern/process/proc.c` | `cpu_idle()` | 持续检查 `current->need_resched`，有调度请求时调用 `schedule()`。 |
| `kern/schedule/sched.c` | `schedule()` | 在关闭本地中断后清除当前线程的调度请求，循环查找首个 `PROC_RUNNABLE` 线程，跳过链表头。`idleproc` 的链表节点自环，调度从表头开始。没有可运行线程时选中 `idleproc`，选中后增加 `runs`，目标变化时调用 `proc_run()`。 |
| `kern/process/proc.c` | `proc_run()` | 目标与 `current` 相同时直接返回。切换时在同一个本地中断临界区内更新 `current`、把目标根页表的物理页号写入 Sv39 `satp`、刷新 TLB，并调用 `switch_to()`。原线程恢复执行后恢复其进入临界区前的中断状态。 |
| `kern/process/switch.S` | `switch_to()` | 按 `struct context` 的 RV64 字段顺序保存和恢复 `ra`、`sp` 与 `s0`–`s11`。`ret` 跳到目标上下文的返回地址。 |

首次运行时，`copy_thread()` 已经为 `initproc` 设置好 `context.ra`、`context.sp` 和 trapframe。实际执行路径为 `cpu_idle → schedule → proc_run → switch_to → forkret → forkrets → __trapret → kernel_thread_entry → init_main`。曾经运行过的线程从先前保存的返回地址继续执行。

#### 最终提示词

```text
[PROMPT]
完成 RISC-V uCore 模块三「进程调度」，让 initproc 从 idleproc 接过 CPU。

直接在项目中补全 kern/process/proc.c 的 cpu_idle()、proc_run()，kern/schedule/sched.c 的 schedule()，以及 kern/process/switch.s 的 switch_to()。文件名以仓库为准，保留现有接口和其他逻辑。完成后用工程已有的构建和 QEMU 目标验证，报告实际结果。

[RELY]
以源码为准，核对 proc.h 中的进程字段及 context 布局。复用 proc_list、current、idleproc、PROC_RUNNABLE、链表接口和本地中断接口。参照 pmm.c 的 enable_paging() 写入 Sv39 satp，并使用工程的 TLB 刷新接口。首次运行复用 forkret → forkrets → __trapret。

[GUARANTEE]
void cpu_idle(void);
void schedule(void);
void proc_run(struct proc_struct *proc);
void switch_to(struct context *from, struct context *to);

[SPECIFICATION]
cpu_idle()
- Pre-Condition：初始化完成，current 为 idleproc。
- Post-Condition：持续检查 need_resched，置位时调用 schedule()。

schedule()
- Pre-Condition：当前线程和进程链表已初始化。
- Post-Condition：清除当前线程的 need_resched，循环选择下一个 PROC_RUNNABLE 线程，无候选时选 idleproc。增加选中线程的 runs，仅在目标变化时切换。
- Requirements：选择和切换在本地关中断期间完成，返回时恢复原中断状态。

proc_run()
- Pre-Condition：目标线程可运行，页表和上下文已准备好。
- Post-Condition：目标等于 current 时直接返回。否则在本地关中断期间更新 current、切换 Sv39 页表、刷新 TLB 并调用 switch_to()。原线程恢复执行后恢复原中断状态。

switch_to()
- Pre-Condition：from 可写，to 已初始化或保存过。
- Post-Condition：按 struct context 的实际偏移保存和恢复 ra、sp、s0–s11，通过 ret 进入目标线程的首次入口或恢复原执行位置。
```

#### 实现迭代过程

1. 对照接口并实现切换。 从 `proc_init()` 和 `copy_thread()` 核对 `idleproc` 的调度标志、进程链表约定和 `initproc` 首次运行的入口。按 `struct context` 的字段布局写入汇编保存与恢复指令，再接入 `proc_run()`、`schedule()` 和 `cpu_idle()`。临时副本使用 `make` 成功编译。
2. 诊断首次启动缺页。 首次 `make qemu` 在 `check_boot_pgdir()` 写入虚拟地址 `0x100` 时触发存储缺页。结合模块一已有记录，在 QEMU 调试运行中观察到两级非叶子项的 `U` 位均为 1。在 GDB 中临时清除这两个位后，断点依次到达 `cpu_idle()`、`switch_to()`、`forkret()`、`__trapret` 和 `init_main()`，并确认切换时 `current` 已指向 PID 1，且本地中断关闭。
3. 修复框架中的非叶子项编码。 在 `kern/mm/pmm.c` 中将 `get_pte()` 的两处非叶子项创建改为调用现有 `ptd_create()`，并将 `check_pgdir()` 中的一处断言改为检查根页表项的 `U` 位为 0。改动共三行。直接运行 `make qemu` 后，内存自检通过，`initproc` 打印 `Hello world!!`。 
4. 确认线程主体返回后的行为。 核对原始工程和评分脚本后确认，`init_main()` 返回后经 `kernel_thread_entry` 调用 `do_exit()` 并出现 `process exit!!` 是 Lab 4 的预期行为。保留框架中的 `do_exit()`。 

### Challenge 1：中断状态的保存与恢复

`local_intr_save(intr_flag)` 和 `local_intr_restore(intr_flag)` 定义在 `kern/sync/sync.h`。它们用于进入临界区前保存中断状态并关闭中断，退出时按原状态恢复。临界区是需要保护的一段操作，例如修改进程链表或切换当前进程。

#### 保存与关闭的实现

`local_intr_save(intr_flag)` 将 `__intr_save()` 的返回值赋给 `intr_flag`。函数读取 `sstatus` 寄存器并检查 `SSTATUS_SIE` 位：原来为 1 时，调用 `intr_disable()` 清除该位，返回 1；原来为 0 时，保持关闭状态并返回 0。因此，保存变量记录的是进入前是否开启中断，而不是整个寄存器。

`intr_disable()` 位于 `kern/driver/intr.c`，通过 `clear_csr(sstatus, SSTATUS_SIE)` 关闭本核在 S 模式下的相应中断响应。保存宏使用 `do { ... } while (0)` 包装，使其在条件分支等位置能够作为一条完整语句使用。

#### 恢复的实现

`local_intr_restore(intr_flag)` 调用 `__intr_restore()`：保存值为 1 时，通过 `intr_enable()` 设置 `sstatus.SIE`；保存值为 0 时，不执行开中断操作。在临界区内保持中断关闭的正常用法下，状态变化如下。

| 进入前中断状态 | 保存值 | 临界区内 | 退出后状态 |
|----------------|--------|----------|------------|
| 开启 | 1 | 关闭 | 开启 |
| 关闭 | 0 | 关闭 | 关闭 |

退出时按原状态恢复，可以避免内层操作提前打开外层已经关闭的中断。例如，外层保存值为 1 并关闭中断，内层保存时得到 0；内层恢复后仍保持关闭，直到外层恢复时才重新开启。嵌套使用需要各层独立保存状态，并按进入顺序的逆序恢复。

这一机制通过阻止本核中断处理程序插入执行，保护相关操作的连续性。


### Challenge 2：分页模式与 get_pte 接口设计

#### 两段相似代码的原因

本工程采用 Sv39 三级页表，虚拟地址的有效部分包含三个 9 位索引和一个 12 位页内偏移。`get_pte()` 分别使用 `PDX1(la)`、`PDX0(la)` 和 `PTX(la)` 逐级定位目标项。

```text
根页表
  → PDX1：找到指向下一层页表的中间项
  → PDX0：找到指向最末级页表的中间项
  → PTX：找到目标页表项并返回其地址
```

前两级都需要检查下一层页表是否存在。存在时取得下一层页表地址；不存在时，若 `create=false` 就返回 `NULL`，若 `create=true` 则分配物理页、设置引用计数、清零新页表并建立中间项。因此，两段代码的结构相似，分别处理不同层级和索引。

最后一级返回目标页表项地址，由调用者填写或查询数据页映射。返回非空表示目标项的位置已经找到，是否存在有效映射还需要检查表项内容。

不同分页模式的基本结构如下。

| 模式 | 适用架构 | 页表层数 | 各级索引位数 | 页表项大小 | 每张页表项数 | 基本页大小 |
|------|----------|----------|--------------|------------|--------------|------------|
| Sv32 | RV32 | 2 | 10、10 | 4 字节 | 1024 | 4 KiB |
| Sv39 | RV64 | 3 | 9、9、9 | 8 字节 | 512 | 4 KiB |
| Sv48 | RV64 | 4 | 9、9、9、9 | 8 字节 | 512 | 4 KiB |

三种模式都通过多级索引完成地址翻译。页表项大小影响每张页表的项数，进而决定每级索引的位数；支持的虚拟地址范围扩大时，需要更多索引位或更多层级。对于本函数按基本页查找的路径，Sv39 需要经过两层中间项，这正是两段相似代码出现的原因。

#### 查找与分配是否应当拆分

当前接口通过 `create` 参数同时支持两种用途：`create=false` 只查找，适合查询和删除；`create=true` 允许创建缺失的中间页表，适合插入映射。这种设计可以复用遍历逻辑，调用也较简洁，适合本实验固定层级的页表管理。

不足之处是函数可能分配内存和修改页表，调用者需要注意参数含义。返回 `NULL` 也有不同原因：只查找时可能是路径不存在，允许创建时可能是分配失败。此外，第一层创建成功、下一层分配失败时，当前实现会保留已创建的中间页表，调用者需要理解这一失败行为。

如果需要更清晰地区分查询和修改，可以提供 `lookup_pte()` 和 `ensure_pte()` 两个对外接口，内部共用遍历辅助函数。前者只查找，后者保证所需路径存在，并明确规定分配失败后的处理方式。这样既便于阅读调用点，也避免维护两套重复的遍历代码。

因此，本实验保留带 `create` 参数的接口是合理的；后续支持多种分页模式、更细的错误报告或并发管理时，拆分对外接口更有价值。


---

## 五、测试与验证

### 功能模块一 部分验证

各项测试结果及运行环境如下，截图在本节末尾补充。

| 检查 | 已有结果 | 结果范围 |
|------|----------|----------|
| 正式工程 `make -j2` | 全部源文件编译通过，最终链接失败 | 仅剩功能模块三的 `cpu_idle` 未定义 |
| 原 `make grade`，独立源码副本 | 注入阶段停止 | 缺少 `proc_init()`，无正式评分结果 |
| 主机侧 `check_pgdir()` | 通过 | 地址转换、分配器及 TLB 使用测试替身 |
| 主机侧课程 PMM 测试 | 输出 `[Test PMM] PASS` | 在主机替身环境中运行课程 PMM 测试逻辑 |
| 主机侧最小边界检查 | 通过 | 覆盖重复删除、同页权限更新、异页替换及两级分配失败等 |
| QEMU 测试副本 | 分配器检查、`check_pgdir()` 通过 | 真实迁入分配器；入口绕开 B/C；后续低地址写入缺页 |
| QEMU 独立诊断副本 | 清除中间项 U 位后，后续内存检查通过 | 含诊断专用异常处理，未迁入正式工程 |
| 完整线程启动、调度和整组评分 | 未完成 | 待其他模块及框架问题处理后统一验证 |

### 功能模块二 部分验证

| 检查 | 结果 | 结果范围 |
|------|------|----------|
| `git diff --check -- lab4/code/kern/process/proc.c` | 通过 | 练习二源码无空白错误 |
| WSL 全量重编 | `proc.c` 编译通过 | 正式链接仅受未实现的 `cpu_idle` 阻塞 |
| 临时验证内核构建 | 通过 | 仅加入不调度的 `cpu_idle` 验证桩 |
| QEMU 进程创建断言 | `[Test Lab4] Process Create PASS` | 检查 idleproc、initproc、父子关系、状态、内核栈和 context |

临时验证没有调用调度器，也没有运行 initproc，因此不构成功能模块三的验证。功能模块三完成后再检查 `forkret -> forkrets -> __trapret` 的实际切换与 initproc 输出。

**后续测试：** 在正式工程中验证真实 TLB 刷新效果、已有缓存时的映射替换、撤销后的访问异常及低内存分配失败路径；其他模块完成后进行线程联调和整组评分。多核地址翻译同步尚未测试。


### 其他模块及整组验证

在模块三合入并修复启动缺页后，通过 WSL 在原工程目录运行 `make qemu` 和 `make grade`。以下是正式联调结果。

`make qemu` 无需 GDB，内存自检通过，`initproc` 进入 `init_main()`。串口输出节选如下。

```text
check_pgdir() succeeded!
check_boot_pgdir() succeeded!
this initproc, pid = 1, name = "init"
To U: "Hello world!!".
To U: "en.., Bye, Bye. :)"
kernel panic at kern/process/proc.c:208:
    process exit!!.
```

`make grade` 退出码为 0。调度用例创建两个测试内核线程，让它们主动调用 `schedule()`，并检查两个线程均获得过 CPU。

| 评分项 | 结果 | 得分 |
|--------|------|------|
| `check PMM` | `OK` | 10/10 |
| `check Process Create` | `OK` | 10/10 |
| `check Schedule` | `OK` | 10/10 |
| **总分** | **全部通过** | **30/30** |

评分脚本注入的测试线程返回类型为 `void`，与 `kernel_thread()` 要求的 `int` 不一致。编译时出现函数指针类型警告，评分正常完成。

**测试截图：**

---

## 六、实验总结与收获

### 对操作系统的理解

#### 功能模块一 部分对应的知识点

| 实验中的内容 | 对应的 OS 原理 | 联系与本次范围 |
|--------------|---------------|----------------|
| Sv39 多级页表查询 | 虚拟地址到物理地址的转换 | 软件建立页表，处理器按规定格式逐级查找物理页 |
| 页映射的建立和撤销 | 地址空间管理 | 通过修改叶子页表项维护虚拟页与物理页的对应关系 |
| 引用计数与释放 | 共享资源管理 | 最后一次引用撤销后才释放；同页重映射必须保持引用不变 |
| 权限位更新 | 内存访问保护 | 叶子权限与中间项保留位职责不同，不能混用 |
| `sfence.vma` | TLB 与页表一致性 | 更新页表后使旧地址翻译失效 |

功能模块一 的关键理解是：页表项、物理页引用计数和 TLB 必须配合维护。同页重映射看似只修改权限，也可能因为处理顺序不当而释放仍需使用的物理页。检查时既要看数据结构，也要通过真实读写确认硬件能使用这张页表。

#### 重要但未在功能模块一中实现或验证的知识点

按需分页、页面置换与交换、写时复制、完整用户地址空间管理和多核 TLB 同步，是虚拟内存管理中进一步需要学习的内容。本次 功能模块一 集中完成基础页映射操作，线程创建、调度和上下文切换由其他模块补充。

#### 功能模块二 部分对应的知识点

| 实验中的内容 | 对应的 OS 原理 | 本次实现 |
|--------------|---------------|----------|
| `proc_struct` 初始化 | 进程控制块 | 保存状态、PID、内核栈、地址空间和切换现场 |
| `do_fork()` | 进程创建与资源管理 | 按顺序取得资源，失败时逆序回收 |
| trapframe 与 context | 首次运行和上下文切换 | context 进入 `forkret`，trapframe 恢复完整寄存器现场 |
| idleproc 与 initproc | 内核启动阶段的基础进程 | 建立 pid 0 与 pid 1，并把 initproc 置为可运行 |

功能模块二的关键是同时准备管理状态和执行现场。进程链表、PID 与父子关系描述“它是谁”，内核栈、trapframe 和 context 决定“它第一次从哪里开始执行”。

#### 功能模块三 部分对应的知识点

| 实验中的内容 | 对应的 OS 原理 | 本次实现 |
|--------------|---------------|----------|
| `schedule()` 扫描 `proc_list` | 就绪线程选择 | 从当前线程之后循环查找，所有普通线程均不可运行时选择 `idleproc`。 |
| `local_intr_save()` 与 `local_intr_restore()` | 单核临界区 | 避免切换期间被本地中断打断，使进程指针、地址空间和执行现场同步交接。 |
| `satp` 与 `flush_tlb()` | 地址空间切换 | 先设置目标线程的根页表，再刷新地址转换缓存。 |
| `switch_to()` 与 `__trapret` | 上下文与 trapframe | `switch_to()` 恢复内核调用上下文。新线程随后通过 trapframe 恢复首次执行所需的现场。 |

### AI 协作开发的经验

#### 功能模块一 部分

本次使用四段式提示词分别明确任务、依赖、保证和具体处理场景。实现前先核对 `pte_create()` 如何添加有效位、引用计数接口如何配合释放操作，再据此组织代码，减少接口理解偏差。

验证采用主机逻辑检查和 QEMU 运行检查相结合的方式：前者便于覆盖引用计数和分配失败等分支，后者用于检查实际地址访问。此次从软件检查通过到真实写入缺页的差异，帮助定位了中间页表项 U 位问题，也说明两种测试各有作用。

AI 协助完成了代码实现、前置代码整合、测试脚本和报告整理。协作过程中，清晰的函数约定和具体的测试输出有助于检查生成代码、定位问题，并把实现过程整理成可复查的实验记录。

#### 功能模块二 部分

实现前先沿 `switch_to`、`forkret`、`forkrets`、`__trapret` 和 `kernel_thread_entry` 追踪首次运行路径，再确定各寄存器字段，避免只按函数名填空。验证时将正式构建和临时运行检查分开：正式工程保留练习三占位，临时副本只用于解除链接阻塞并执行练习二断言。

#### 功能模块三 部分

先用四段式提示词明确接口、依赖、状态变化和验证方式，再对照源码确认链表哨兵、`struct context` 的字段偏移以及 `pgdir` 的地址含义。把这些约定写进提示词，可以减少 C 与汇编之间的接口错误。

初次运行受内存自检缺页阻塞时，先用 QEMU 异常日志定位访问地址，再通过 GDB 验证单独清除两级非叶子项的 `U` 位能否继续启动。修复后复跑普通启动和评分，分别确认线程主体输出与调度用例通过。

