# Lab2 物理内存初始化验证记录

验证日期：2026-10-22（Asia/Shanghai）。工作目录：`E:\os-labs\lab2\lab2_new`。

结论：本轮已修复两个互相独立的启动阻塞，内核能进入 `kern_init()`，物理内存初始化和现有 First-Fit 分配/释放自检通过。64 MiB、128 MiB 通过未经修改的课程 `test_page_init()`；256 MiB 通过管理上限专项检查。完整 Lab2 仍有未完成的 Best-Fit 作业，不能表述为整个 Lab2 已通过。

## 实际表现与预期表现（Pre-change Baseline / Behavior Contract）

实际：旧 Makefile 的 QEMU 命令只有 OpenSBI 日志；上轮改用 `-kernel` 后仍未看到内核输出。

预期：OpenSBI 跳转到物理入口 `0x80200000`，内核开启分页后仍能继续取指，再跳到高地址的 `kern_init()`；随后输出 `DTB Init`、物理内存范围及 `check_alloc_page() succeeded!`。

本轮重新采集了修改前日志、GDB 单步结果和反汇编，而不是把上轮未确认的判断当成结论。

环境实际查询：WSL Ubuntu；RISC-V GCC 14.2.0；QEMU 10.2.1；QEMU 默认固件输出 OpenSBI v1.8。版本原始输出见 `baseline.log`。

## 已确认的原因（Evidence and Gate Decision）

### 1. 旧 loader 参数没有为本机 OpenSBI 提供正确的内核下一跳

旧命令是：

```sh
qemu-system-riscv64 -machine virt -nographic -bios default \
  -device loader,file=bin/ucore.img,addr=0x80200000
```

`before-loader.log` 和修复启动页表后的对照 `after-old-loader.log` 均输出：

```text
Domain0 Next Address        : 0x0000000000000000
```

改用 `-kernel bin/ucore.img` 后，固件输出：

```text
Domain0 Next Address        : 0x0000000080200000
```

GDB 也确实在 `0x80200000` 命中断点。因此在本机所测固件/QEMU 组合中，旧 loader 命令不能正确进入内核，`-kernel` 能提供正确入口。这不是所有旧版 QEMU/固件行为的普遍结论。

### 2. 开启分页到跳高地址之间缺少低地址映射

原启动页表只有第 511 项有效，映射高地址 `0xffffffffc0000000` 到物理 `0x80000000`。开启分页时 CPU 还在物理入口附近以低地址执行；该低地址对应根页表第 2 项，原来为零。

修改前 GDB 原始输出（`debug-boot.log`）：

```text
--- before enabling satp ---
pc             0x80200034
satp           0x0
0x80205010:    0x0000000000000000
0x80205ff8:    0x00000000200000cf
--- immediately after satp ---
pc             0x80200038
satp           0x8000000000080205
Cannot access memory at address 0x80200038
```

`satp` 是 CPU 保存当前页表位置和分页模式的寄存器。写入它会开启地址转换，但不会自动把 PC（下一条指令的地址）换成内核高地址。原来“加一条 nop”的注释不能修复缺失的映射。

修改后 GDB 原始输出（`confirm-boot.log`）：

```text
0x80205010:    0x00000000200000cf
--- instruction fetch after satp works ---
pc             0x80200038
=> 0x80200038: sfence.vma
pc             0x8020003c
--- high virtual entry reached ---
pc             0xffffffffc02000d6 <kern_init>
sp             0xffffffffc0205000
gdb_status=0
```

这是同一位置修改前后能否读取和执行指令的直接对照。缺失过渡映射已确认；本次没有独立采集故障时的 `scause` 数值，不把某个具体异常编号称作原始观测结果。

## 本轮修改及理由（Change Summary）

维护源码只改两处，完整补丁在 `changes.diff`：

1. `kern/init/entry.S`：为根页表第 2 项增加恒等映射，即低地址 `0x80000000..0xbfffffff` 仍访问同值物理地址。它让开启分页后的取指可以继续，随后沿原有代码跳到内核高地址。第 511 项高地址映射保持原样；整个根页表仍为 512 项、4096 字节。改正“已完美完成虚拟内存切换”和 nop 的误导注释。
2. `Makefile`：将 `qemu`、`debug`、`test` 三个启动入口中的 loader 参数统一替换为 `-kernel $(UCOREIMG)`，让固件获知内核入口。实际运行验证覆盖 `make qemu`；`make debug`、`make test` 这两个目标本身没有单独运行。

`kern/mm/pmm.c` 本轮没有再次改动。前后 SHA-256 相同，记录在 `scope.json`。上轮写入的 `page_init()` 在本轮得到实际运行验证。

原始 `tools/test_lab2.c`、`tools/test_lab2.h` 没有改写。验证脚本在 `test-tree` 独立副本中按字节复制测试，并仅在副本的 `pmm.c` 中插入测试调用。额外检查在 `extra_checks.c`。`scope.json` 核对了原测试副本一致，及测试副本中其他维护文件与真实工程一致。

Best-Fit 未实现造成默认构建报错；本轮所有成功构建均明确使用下面的命令行变量排除其目标文件。没有给 Best-Fit 补假实现，也没有关闭 `-Werror`。

```sh
make -j2 'KOBJS=$(filter-out obj/kern/mm/best_fit_pmm.o,$(call read_packet,kernel libs))'
```

## 实际验证及结果（Verification Results）

| 检查 | 实际结果 | 原始证据 |
| --- | --- | --- |
| 修改前默认 `make -j2` | 失败：Best-Fit 的 `free_list`、`nr_free` 未定义 | `baseline.log` |
| 排除未完成 Best-Fit 后构建 | RISC-V 编译、链接、镜像生成成功 | `verify.log`、`tests-attempt1.log` |
| 原工程、默认 128 MiB QEMU | DTB 初始化、内存初始化、分配释放自检成功 | `after-console.log` |
| 修复后 GDB 单步 | 越过开启分页，命中高地址 `kern_init` | `confirm-boot.log` |
| 修复后仍用旧 loader 参数 | 下一跳仍为零，无 `DTB Init` | `after-old-loader.log` |
| 64 MiB：课程原测试 + 额外检查 | 两项 PASS，自检成功 | `test-64M.log` |
| 128 MiB：课程原测试 + 额外检查 | 两项 PASS，自检成功 | `test-128M.log` |
| 256 MiB：管理上限专项 | 额外检查 PASS，自检成功；原测试明确 SKIP | `test-256M.log` |
| 实际 `make qemu` 入口 | 内核输出与分配释放自检成功 | `make-qemu-check.log`、`make-qemu-console.log` |

128 MiB 关键原始输出：

```text
[Test 1] Page Init: PASS
[Extra] Page Init: PASS (descriptors=32768 free=31929 first=0x80347000 limit=0x88000000)
check_alloc_page() succeeded!
```

64 MiB 输出描述符数量 16384、空闲页数量 15705、首个空闲页 `0x802a7000`、管理终点 `0x84000000`。128/256 MiB 均输出描述符数量 32768、空闲页数量 31929、首个空闲页 `0x80347000`、管理终点 `0x88000000`。

课程原测试检查偏移值、设备树内存信息、`npage`、描述符对齐与位置、空闲页数量合理性、内核尾页保留、描述符数组保留、地址换算往返。额外检查逐页验证保留范围和引用计数，核对准确空闲页数量、空闲块长度和管理上限；还测试超量申请失败、申请全部空闲页、耗尽后申请失败以及全部释放后数量恢复。

256 MiB 的原测试假定 `npage == PPN(设备树内存终点)`，与本题要求按框架上限截断的场景不一致。因此该配置明确跳过原测试，使用额外测试断言管理终点为 `PHYSICAL_MEMORY_END=0x88000000`。没有改原测试或把 SKIP 写成 PASS。64/128 MiB 配置实际运行原测试并通过。

每次 QEMU 达到预设限时后由 `timeout` 结束，退出码为 124。内核本来就在初始化完成后无限循环，不能单凭这个退出码判断成功；脚本同时要求成功日志存在并检查没有 `panic`/`FAIL`。

保留的失败尝试：首轮 64 MiB 在 8 秒时尚在输出内存范围，未到测试 PASS，检查脚本失败。原始输出在 `test-64M-timeout-8s.log`、`tests-attempt1.log`，未覆盖。改用 30 秒限时后，三种内存配置全部完成。未测定该机器每轮启动耗时变化的具体原因，不将首次超时称作初始化算法错误。

## 仍未确认的猜测与未覆盖范围（Residual Risk or Stop Reason）

- WSL 启动时有 localhost 代理转发提示；同样提示下编译、GDB、QEMU 自检均成功，没有证据证明它是本故障原因。
- 未调查不同旧版 QEMU/OpenSBI 是否会自动为 loader 指定内核入口，不推广本机结论。
- 未运行完整 `make grade` 或 Best-Fit 测试，完整默认构建仍会被未完成 Best-Fit 挡住。
- 未在真实 RISC-V 板上测试，也未注入损坏设备树、64 位范围溢出、描述符空间不足等异常输入来执行所有 panic 分支。
- 此启动恒等映射会继续保留在当前启动页表中；本轮没有实现切换完成后回收低地址映射。后续若有严格限制低地址映射的要求，需要另行处理。

## 保存的命令与复现方式

关键执行脚本均保存在本目录；Bash 脚本通过 `set -x` 将实际展开后的命令及输出写入对应 `.log`，并单独保存 QEMU/GDB 原始输出。修复前文件在 `before/`，源码补丁在 `changes.diff`。`before-kernel-trace.log` 是修改前指令跟踪；由于跟踪输出较慢且限时结束，不能仅据其最后一条指令定位挂点，定位以 GDB 对照为准。

本轮实际在 PowerShell 调用的关键入口如下（这些调用已执行，不是仅建议运行）：

```powershell
wsl -d Ubuntu -- bash /mnt/e/os-labs/lab2/verification/page-init-20261022/baseline.sh
wsl -d Ubuntu -- bash /mnt/e/os-labs/lab2/verification/page-init-20261022/debug-boot.sh
wsl -d Ubuntu -- bash /mnt/e/os-labs/lab2/verification/page-init-20261022/verify.sh
wsl -d Ubuntu -- bash /mnt/e/os-labs/lab2/verification/page-init-20261022/run-tests.sh
wsl -d Ubuntu -- bash /mnt/e/os-labs/lab2/verification/page-init-20261022/confirm-boot.sh
wsl -d Ubuntu -- bash /mnt/e/os-labs/lab2/verification/page-init-20261022/check-make-qemu.sh
python lab2/verification/page-init-20261022/check-scope.py
```

注意：`baseline.sh` 和 `debug-boot.sh` 是修改前实际执行的命令记录，当前源码已修复，重跑不会重现原状态。`prepare-tests.py` 拒绝覆盖已存在的测试副本；`run-tests.sh` 已允许复用本次副本。如果未来源码改变，先检查副本差异并使用新的证据目录，不应拿旧副本证明新源码通过。

当前直接启动的命令（在 WSL 的 `/mnt/e/os-labs/lab2/lab2_new` 内执行）：

```sh
make qemu 'KOBJS=$(filter-out obj/kern/mm/best_fit_pmm.o,$(call read_packet,kernel libs))'
```

看到成功日志后，按 `Ctrl+A`，再按 `X` 退出 QEMU。

## 范围检查与流程回执（Authorized Scope and Patch Budget / Final Scope Check）

目标：修复本次启动阻塞并验证物理内存初始化。红线：不完成或改写 Best-Fit、不削弱原课程测试、不扩大到其他实验。验收：GDB 证明到达内核，初始化相关测试实际运行，原始输出可查看。

决策为 `Local Fix / Local Fix Only`：修改启动这条行为路径中的两个维护文件；新增验证材料与测试副本保存在独立目录。前后源码统计为两文件、增加 9 行/删除 7 行。`pmm.c` 哈希不变。

工作区没有 Git 仓库；全工作区 Git 范围检查实际失败，错误为 `git rev-parse --show-toplevel failed: fatal: not a git repository`。随后使用修改前副本生成源码 numstat，并运行：

```powershell
python C:/Users/hxn59/.codex/skills/code-quality-workflow/scripts/check_patch_scope.py --preset local-fix --fail-on-warning --numstat-file lab2/verification/page-init-20261022/source-numstat.txt
```

结果见 `source-budget-check.log`：源码补丁在 2 文件/80 行预算内，无警告。该结果只覆盖传入的维护源码快照，不代表 Git 已检查整个工作区；新增验证脚本、日志、测试副本和编译产物不包含在这个源码计数中。

技能回执：主路线 `code-quality-workflow`；按要求读取 `consult-tavernweave-library` 与 `ST-A0`（v1.1.0）；路由快照版本 `2026-08-18`。本任务未采纳路由器返回的不相关设计候选。用户本轮已授权排查、必要修改、保存命令及验证结果，无安装、推送或发布操作。自动化测试通过不代替用户人工验收。
