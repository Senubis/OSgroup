# 小组 Lab3 分支：异常处理本地整合

日期：2026-11-04。

## 下载位置与修改范围

仓库来源：`https://github.com/Senubis/OSgroup.git`，下载分支 `lab3`。

独立本地仓库：`E:\os-labs\OSgroup-lab3`。

实际工程：`E:\os-labs\OSgroup-lab3\lab3\code`。

下载时提交：`a490e4ab6ec13e55eace760fce6a1192b09b02db`，说明为 `lab3: implement trap entry and restore`。该提交一次加入整个 lab3 目录，Git 能看到提交后的文件及提交信息，不能还原队友每一次未提交的编辑过程。

代码与 `lab3/report/report.md` 一致表明：队友已完成模块一的 RESTORE_ALL 和 __alltraps 调用 trap。内存初始化与分配器也已经存在；模块二处理函数仍为空。因此你的异常处理与她的入口恢复没有代码重叠，没有需要取舍的修改冲突。

本次只改了以下两个跟踪文件，全部是新增行：

| 文件 | 改动 | 原因 |
| --- | --- | --- |
| lab3/code/kern/trap/trap.c | 新增 22 行 | 整合上轮 exception_handler 原文，以及供既有分发代码使用的中断函数前置声明 |
| lab3/code/kern/trap/trap.h | 新增 1 行 | 声明公开的 exception_handler 接口 |

队友的 trapentry.S、报告和其他源文件保持下载时内容。未改中断实现、内存代码、启动汇编、Makefile 或课程测试；默认启动没有新增异常测试。旧的 `E:\os-labs\lab3\lab3_new` 保留。本次没有创建提交或 push，修改处于本地未暂存状态。

## 异常处理行为

非法指令输出 `Illegal instruction at ...`，根据课程 `.word 0x0000007b` 的 4 字节长度把 epc 加 4。断点输出 `Breakpoint at ...`，根据故障指令首半字的最低两位区分 2 字节 c.ebreak 和 4 字节 ebreak。其他异常只调用已有 print_trapframe，不修改 epc。

本次没有搬入上轮隔离环境里的其他模块实现。interrupt_handler 的前置声明仅满足已有 C 分发的声明要求，不是中断功能实现。

## 验证方式与日志

所有验证文件和副本都放在本目录，位于 Git 仓库外，避免把临时适配混入小组代码。

`integration.patch` 保存了两处待审查修改。`preserved-teammate.log` 记录对队友汇编和报告运行 `git diff --exit-code HEAD -- ...` 返回 0。`git-diff-check-windows.log` 无输出，说明差异格式检查通过。`history.log` 保存下载提交。

主测试命令为：

```powershell
wsl -d Ubuntu -- python3 /mnt/e/os-labs/lab3/verification/c-exception/team-integration-20261104/verify.py
```

脚本会拒绝覆盖已有验证副本；需要重新完整验证时应使用新的记录目录。可单独重跑 `check_direct.py`。具体命令、工作目录、退出码在日志头尾和 `results.json` 中。

### 直接检查

`direct.log`：使用新下载工程的真实头文件与整合后的异常函数原文，验证非法指令加 4、两种断点加 2/4、输出前缀，以及 13 类其他异常只输出一次且整个现场不变。检查通过。该检查没有真实触发 CPU 异常。

### 无适配构建

在 `unadapted/` 这个未经源码适配的整合副本运行 make，当前 WSL 工具链首先报不认识 CSR 名称 `sbadaddr`，见 `unadapted-build.log`。

继续仅增加编译参数 `DEFS+=-Dsbadaddr=stval` 后，所有源文件可以编译，链接报 `undefined reference to interrupt_handler`，见 `alias-build.log`。这说明中断处理仍待小组其他工作完成，不代表异常函数有编译错误。实际仓库没有因此修改队友汇编或补写中断模块。

### 真实异常与模块一配合

`context/`、`illegal/`、`extra/` 都从本次整合工程复制而来。它们保留队友 trapentry.S 的原始字节，并在构建成功后由脚本再次断言与仓库逐字节相同。使用 `-Dsbadaddr=stval` 编译参数适配工具链，没有改写她的指令。

测试副本额外差异如下，全部不在待提交代码中：

1. 启动 entry.S 增加低地址恒等映射，供现代 QEMU 在开启分页后跳往高地址前取指；QEMU 命令直接使用 `-kernel`。
2. 使用原 tools/inject.py 注入测试；在异常测试之后暂停，避免进入未完成的时钟中断流程。
3. 添加仅供课程测试直接调用的 interrupt_handler 测试桩，输出软件中断与未知中断信息。它没有时钟处理，不能算作中断模块完成。
4. context、illegal 使用仓库原有测试 C/汇编；extra 仅在验证副本替换测试 C，复用上轮的 `test_extra.c`，真实触发 illegal32、c.ebreak16、ebreak32，并对其他异常直接调用后比较现场。

原始输出分别在 `context-qemu.log`、`illegal-qemu.log`、`extra-qemu.log`，最终检查点结果在 `results.json`。使用 40 秒观察窗口，返回 124 表示 timeout 按时停止；是否通过以检查点是否全部出现为准。

本次结果：三个运行用例的全部检查点均通过。课程上下文用例输出 PASS (35/35)，非法指令用例输出 PASS (25/25)；这些是两个独立用例的通过标记，不是完整评分结果。额外用例输出三种真实异常后的 continuation PASS、直接调用兜底现场不变 PASS 和 EXTRA ALL PASS。

课程上下文汇编显式比较 26 个通用寄存器（t0-t6、s0-s11、a1-a7），没有穷尽验证所有 CSR 和全部寄存器；兜底输出检查是在直接调用下完成，没有真实触发未知异常后强制继续执行。

## 未完成范围

本次没有运行或宣称整合版完整 make grade 100/100。完整链接仍受 interrupt_handler 缺失阻挡；时钟持续中断、定次关机和默认启动整体运行未验证。后续由对应任务补齐中断处理并解决环境启动兼容后，再在完整工程上重新运行 make、make qemu 和 make grade。

上轮 100/100 属于上轮补齐依赖的隔离副本，不能直接转移到本次小组整合版。未进行人工现场验收、旧 Challenge 或用户态/内核态切换测试。
