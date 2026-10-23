# Lab2 Best-Fit 连续物理内存分配：实现与验证

日期：2026-10-22，Asia/Shanghai。工程：`E:\os-labs\lab2\lab2_new`。

## 实现内容与指导书对应

对应指导书《lab2流程.pdf》第 3 页“功能模块二：物理内存分配功能 / 任务二：实现 Best-Fit 连续物理内存分配算法”。按其要求参考 `default_pmm.c`，自行补齐管理器状态、各管理函数及注册结构，并在 `pmm.c` 切换当前管理器。没有改动原有 `basic_check()`、`best_fit_check()`。

维护源码只改两个文件：

- `kern/mm/best_fit_pmm.c`：在 `lab2 function2-2` 标记处增加实现，原测试代码整体保留。
- `kern/mm/pmm.c`：只把管理器从 `default_pmm_manager` 切换为 `best_fit_pmm_manager`。

完整补丁见 `changes.diff`。物理内存初始化 `page_init()`、`entry.S` 的启动页表修复、Makefile 的 `-kernel` 启动修复、公共接口、`Page` 结构及现有宏定义均未修改。新增的 `free_list`、`nr_free` 只是分配器内部的状态别名，与 First-Fit 的写法一致。

## 实现思路

空闲链表按物理地址递增排序，每个空闲块只有首页设置 `PG_property`，其 `property` 保存连续页数。

| 接口 | 实际实现 |
| --- | --- |
| 初始化 | 初始化链表头，空闲页数清零 |
| 空闲区域登记 | 检查原页为保留状态，清除标志、长度及引用计数，再按地址登记并合并邻接块 |
| 分配 | 遍历空闲块，选择长度不小于申请量的最小块；遇到完全匹配即可停止。长度相同时保留地址较低者 |
| 分裂 | 从选中块的低地址端分配；剩余部分成为新的空闲块，留在原有链表位置；扣减空闲页数 |
| 释放 | 重置本次释放页的状态，按地址插入；先与前块合并，再与后块合并；本次释放页数只计入一次 |
| 空闲页计数 | 返回当前空闲物理页总数 |
| 自检 | `.check` 注册到未经修改的 `best_fit_check()`，其中仍调用原有 `basic_check()` |

总空闲页数足够但没有足够大的连续块时，分配返回 `NULL`。合并后清除失效块头的属性标志和长度，避免其仍被当成空闲块首页。

查找采用线性遍历，空闲块数为 B 时，分配和按地址插入的最坏复杂度为 O(B)。没有做性能基准测试，也没有为提高复杂度引入新的数据结构。

## 问题描述、原始错误与原因分析

修改前完整默认构建失败，不能正常生成包含 Best-Fit 的内核。`baseline.log` 保存了实际命令、版本和原始输出：

```text
+ make -j2
kern/mm/best_fit_pmm.c:24:36: error: 'free_list' undeclared (first use in this function)
kern/mm/best_fit_pmm.c:28:34: error: 'nr_free' undeclared (first use in this function)
make: *** [Makefile:116: obj/kern/mm/best_fit_pmm.o] Error 1
```

注：以上只摘录关键错误，实际 shell 命令前缀和完整错误均以 `baseline.log` 为准。

已确认原因：Best-Fit 文件最初只有测试函数，缺少测试所引用的空闲链表和页数状态，也没有分配器接口实现、管理器注册结构。该问题属于本次待完成的 Best-Fit 模块，不是初始化代码或此前启动修复的回归。

解决策略：补齐内部状态、接口函数和注册结构，切换当前管理器。没有通过删除测试、关闭 `-Werror` 或排除 Best-Fit 目标文件规避错误。

## 实际命令与验证方式

本轮从 PowerShell 实际调用了以下脚本，脚本均保存在本目录：

```powershell
python lab2/verification/best-fit-20261022/snapshot.py
wsl -d Ubuntu -- bash /mnt/e/os-labs/lab2/verification/best-fit-20261022/baseline.sh
wsl -d Ubuntu -- bash /mnt/e/os-labs/lab2/verification/best-fit-20261022/verify.sh
wsl -d Ubuntu -- bash /mnt/e/os-labs/lab2/verification/best-fit-20261022/run-tests.sh
python lab2/verification/best-fit-20261022/check-scope.py
```

Bash 脚本用 `set -x` 记录实际展开命令；QEMU 完整输出另存原始日志。关键构建命令：

```sh
make -B -j2
timeout 30s make qemu
```

与前一模块验证不同，本轮成功构建没有传入过滤 `KOBJS` 的参数，没有排除 Best-Fit 或 First-Fit 文件。`make -B` 强制重新编译全部对象，避免复用旧对象导致误判。

进一步验证在独立的 `test-tree` 副本进行：使用工程原有 `tools/inject.py` 注入课程 `test_page_init()`、`test_best_fit()`；原测试文件按字节核对，没有改写。在副本添加 `extra_checks.c` 和一个调用，维护工程未注入测试代码。

```sh
make -j2 DEFS=-Ducore_test
timeout 30s qemu-system-riscv64 -machine virt -m 64M -nographic -bios default -kernel bin/ucore.img
timeout 30s qemu-system-riscv64 -machine virt -m 128M -nographic -bios default -kernel bin/ucore.img
```

`ucore_test` 开启原有 `best_fit_check()` 内的计分输出。`grading: 6 / 6 points` 是该自检内部的检查点结果，不是整个 Lab2 的总分。

## 验证结果

| 实际检查 | 结果 | 证据 |
| --- | --- | --- |
| 修改前完整默认构建 | 失败，Best-Fit 状态未定义 | `baseline.log` |
| 修改后强制完整默认构建 | 全部编译、链接及镜像生成成功，无文件排除 | `verify.log` |
| 原工程 `make qemu` | 输出 Best-Fit 管理器名称，原有分配释放自检成功 | `kernel-console.log` |
| 64 MiB 测试副本 | 原有自检 6/6；课程初始化和管理器检查 PASS；四项额外检查 PASS | `test-64M.log` |
| 128 MiB 测试副本 | 原有自检 6/6；课程初始化和管理器检查 PASS；四项额外检查 PASS | `test-128M.log` |

关键原始输出：

```text
memory management: best_fit_pmm_manager
grading: 6 / 6 points
check_alloc_page() succeeded!
[Test 1] Page Init: PASS
[Test 2] Best-Fit: PASS
[Extra] Best-Fit selection/split/fragmentation: PASS
[Extra] Best-Fit two-sided coalescing: PASS
[Extra] Best-Fit multi-region registration: PASS
[Extra] Best-Fit accounting/restoration: PASS
```

额外检查包括：创建 8、3、5、3 页的四个非相邻空闲块并以乱序释放；验证最小块选择、同大小时选择低地址、分裂余块再利用；验证剩余总数为 3 页但分成 2+1 时申请连续 3 页失败；验证释放中间块能同时合并两侧；验证多段保留页区域乱序登记和合并；验证耗尽、超量申请失败及最终页数恢复。

QEMU 在初始化和检查完成后仍进入内核原有无限循环，由 `timeout` 在 30 秒终止，退出码为 124。脚本除检查退出码外，还要求所有预期 PASS 和成功标记存在，并检查没有 `panic`/`FAIL`，不会将单纯超时视为通过。

## 范围核对与未验证项

修改前为 39 个维护文件保存了 SHA-256。最终比较确认只有上述两个源码文件改变；原 `basic_check()` 与 `best_fit_check()` 所在的整个后缀逐字一致；`pmm.c` 恰好只有管理器选择一行变化。公共头文件、初始化函数和已验证启动修复保持不变。证据在 `scope.json`、`scope-check.log`。

源码补丁为两个文件，增加 123 行、删除 1 行，其中 Best-Fit 增加 122 行，管理器切换为一行替换。因需补齐全部管理接口，使用 2 文件/160 行的明确源码预算，检查通过。统计只覆盖维护源码，独立证据脚本、日志和测试副本不计入该源码预算。工作区没有 Git 仓库，范围通过快照比较确认。

```powershell
python C:/Users/hxn59/.codex/skills/code-quality-workflow/scripts/check_patch_scope.py --preset custom --max-files 2 --max-lines 160 --fail-on-warning --numstat-file lab2/verification/best-fit-20261022/source-numstat.txt
```

未运行完整 `make grade`。已检查到 `tools/grade.sh` 仍独立硬编码旧 loader 参数，本轮没有修改评分驱动，而是直接使用原课程注入工具和测试函数验证，不能声称取得原评分脚本总分。

未单独运行 `make test` 目标；测试副本使用等价的 `ucore_test` 编译开关运行原有检查。未做真实硬件测试、长时间随机压力测试、并发分配测试或无效释放行为测试。256 MiB 配置本轮未重跑，不以之前 First-Fit 下的结果证明新分配器在该配置通过。

流程回执：沿用 `code-quality-workflow` 的局部实现与验证流程、`consult-tavernweave-library` 的 `ST-A0` 检查清单；路由快照 `2026-08-18`，没有采用额外设计候选。目标为完成本模块；红线为保持原测试、公共定义、初始化与启动修复；验收为完整构建、实际内核自检和独立边界检查及可追溯输出。没有安装工具、推送或发布操作。
