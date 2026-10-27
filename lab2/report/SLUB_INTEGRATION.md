# SLUB 自检完善与集成验证报告

## 本轮改动

直接修改实际工程的 `kern/mm/slub.c`：重写 `slub_check()`，并增加 static 测试辅助函数。与本轮修改前的全部源码逐文件比对，只有这个文件发生变化；该文件中分配器实现、初始化、释放逻辑及已有 `slub_validate()` 也保持原样。

Buddy 自检、A 的代码、原评分逻辑、公开接口、Page 布局均未修改。本轮未发现新的分配器实现缺陷，因此没有分配器修复；修改内容全部属于测试增强。

原始自检副本保存在新日志目录的 `slub_before.c`，本轮差异见 `SLUB自检修改.patch`。完整工程见 `lab2_slub_integrated.zip`，全部本轮验证证据见 `SLUB集成验证日志.zip`。

## 覆盖表

| 用户要求 | 阶段 | 关键断言与数据操作 | 本轮 QEMU 结果 |
|---|---|---|---|
| Case 1：零长度、NULL | T01、T02 | kmalloc(0)==NULL，kfree(NULL) 不改变页数；有效页及页末地址往返 | 通过 |
| Case 1：各类别边界、2049/4096/4097 | T02 | 34 个尺寸，包含每个 2 的幂边界前后，以及计入页头后恰好一页的前/中/后三个尺寸 | 通过 |
| Case 2：至少 16 字节对齐、不重叠 | T02、T04、T05、T07 | 检查每个新地址对齐，并逐对检查所有存活对象的完整容量范围 | 通过 |
| Case 2：完整数据与存活数据保持 | T02、T04、T05、T06、T07 | 对完整请求范围写入随偏移变化的字节模式；小对象额外写满整个类别容量；每次分配/释放后读回其他存活对象 | 通过 |
| Case 3：跨页与槽复用 | T04 | 页头 96 字节，128 字节类别每页 31 槽；填满两页共 62 个对象，释放唯一槽后必须获得相同地址，页数不变 | 通过 |
| Case 3：空页立即回收 | T03、T04 | 分别验证全部 8 类的最后一次释放立刻返还一页；另一页对象存活时回收第一页，检查存活数据并再次扩页 | 通过 |
| Case 3：大对象完整释放 | T05 | 7 种大对象同时存活，按“请求+页头→原始页数→Buddy 取整”检查每次页数变化；8192 字节需原始 3 页、实际 4 页，释放完整返还 | 通过 |
| Case 3：乱序释放 | T02、T04、T05 | 使用低/高索引交替的排列，避免固定乘数与对象数量不互质导致遗漏；逐次检查其他对象 | 通过 |
| Case 4：内存不足 | T06 | 保留一个有空槽的小对象页、一个满页类别及一个大对象，耗尽剩余 Buddy 页；新类别、已满类别和大对象申请都失败 | 通过 |
| Case 4：失败不影响已有对象 | T02、T06 | 每次失败后页数不变、元数据一致、所有存活数据正确；Buddy 耗尽时既有 slab 的空槽仍可申请 | 通过 |
| Case 4：溢出 | T02、T06 | SIZE_MAX、页头加法溢出首值、加法恰好不溢出但无法分配的值、最高位请求及超物理容量请求 | 通过 |
| Post-Condition：全部释放、缓存无悬挂引用 | 每阶段结束、T07 | 页数精确恢复，所有缓存及大对象链表 next/prev 均指向各自表头 | 通过 |
| Post-Condition：后续分配正常 | T07 | 全部 8 类与两个大对象同时分配、写读、释放，连续重复两轮并再次确认缓存清空 | 通过 |

## 有界记录和容量计算

- 普通对象测试固定最多 64 条记录；最大同时使用 62 条，不根据物理内存大小创建堆数组。
- 写读采用逐字节模式 `seed + offset*37 + (offset>>8)*11`，通过 volatile 字节访问读回，覆盖末字节及全部承诺容量。
- 使用真实 RISC-V 构建选项额外生成 `-fstack-usage` 记录：最大的单个测试函数静态栈帧为 1872 字节，slub_check 自身为 208 字节；完整记录见 `slub_stack.su`。这些数值是单函数栈帧，不冒充整个调用链的精确峰值。
- 跨页槽数量依据 `(PGSIZE-SLUB_DATA_OFFSET)/capacity` 计算，计入页头，不使用 `4096/capacity` 的错误容量。
- 大对象页成本依据请求加页头取整到页，再取整到 Buddy 的 2 的幂块，所有测试尺寸均为固定有界值。
- 耗尽测试复用已有 `Page.page_link` 记录直接申请的页；申请循环最多为起始空闲页数，释放循环精确为实际记录数，并检查链表最终双向归位。起始空闲页数不超过 `npage-nbase`。
- 固定的同时存活用例要求至少 128 个空闲页，本 Lab 实际有 31,926 页；测试开始明确检查该条件，不通过时不会伪报完整覆盖。
- 已释放对象的记录立即设为 NULL，后续检查只读仍存活对象。

## 实际执行结果：分别区分编译、运行、断言

环境：WSL2 Linux，xPack RISC-V GCC 13.2.0，QEMU 7.0.0 / OpenSBI v1.0。版本原始输出见 `toolchain_versions.log`。

| 实际命令或步骤 | 编译状态 | 运行状态 | 断言/评分状态 |
|---|---|---|---|
| 默认 `make clean` 后 `make -j2` | 成功，退出 0 | 不适用 | 未运行内核 |
| 默认原样 `make grade` | 评分副本成功编译、链接 | 未进入 ucore，命令退出 2 | 内核评分断言未执行，原脚本报告 0/20 |
| 对照 `make grade QEMU=外部适配器` | 成功 | 进入默认 Best-Fit 内核 | 原评分逻辑通过，20/20，退出 0 |
| `make clean` 后 Buddy 构建 | 成功，退出 0 | 不适用 | 不适用 |
| `make qemu DEFS="-DUSE_BUDDY"` | 已构建成功 | 进入内核并完成初始化 | 原 Buddy 自检和 check_alloc_page 均通过 |
| `make clean` 后 Buddy+SLUB 构建 | 成功，退出 0 | 不适用 | 不适用 |
| `make qemu DEFS="-DUSE_BUDDY -DUSE_SLUB"` | 已构建成功 | 进入内核并完成初始化 | Buddy 自检保留并通过，SLUB T01～T07 全通过 |
| 主机 GCC + ASan/UBSan 构建 | 成功，退出 0 | 不适用 | 不适用 |
| 主机运行补充验证 | 不适用 | 正常退出 0 | 同一组增强自检及 12,000 次随机操作通过，未报告 ASan/UBSan 错误 |

每次配置切换前均实际执行 make clean。QEMU 两次启动由验证程序在 12 秒后终止，因为实验内核初始化后正常进入无限循环；成功判据是此前所有规定成功标记已出现且无内核 panic/断言失败，不把超时解释成进程返回 0。

## QEMU 原始关键输出

以下来自本轮 `slub_boot.log`，并非预期输出模板：

```text
buddy_check() succeeded!
check_alloc_page() succeeded!
slub_check: begin free=31926 header=96 records=64
[SLUB T01] PASS zero, NULL and page-address round trips
[SLUB T02] PASS boundaries, full data, alignment, non-overlap, overflow
[SLUB T03] PASS immediate empty-page reclaim for all 8 classes
[SLUB T04] PASS cross-page slots, exact reuse, partial slab reclaim, shuffle
[SLUB T05] PASS metadata-aware large-page costs and complete shuffled frees
[SLUB T06] PASS bounded exhaustion, failed new/full/large allocations, live data
[SLUB T07] PASS empty cache links and two rounds of later allocations
slub_check() succeeded! stages=7 restored 31926 free pages
```

自检前后空闲页数均为 **31,926**。主机保护页环境中则从 **512** 恢复到 **512**，并继续完成随机测试。主机测试只适配用户态地址映射；实际内核转换与 Buddy/SLUB 接入由 QEMU 集成运行验证。

## 保留的问题复现与处理说明

本轮确实重新执行了不带覆盖参数的原始 make grade，没有用适配命令冒充原命令通过。它成功编译评分副本，但输出缺少两个测试的 PASS，得到 0/20。

保留的 `default_grade_raw_serial.log` 显示：

```text
Domain0 Next Address      : 0x0000000000000000
```

该串口日志只有 OpenSBI 输出，没有 ucore 内核初始化输出。原评分脚本使用 generic loader 加载镜像，在本机的 QEMU/OpenSBI 组合中没有设置正确的固件后继入口；与此前记录的启动兼容问题一致。

处理方式仍是已有外部适配器，将对应 loader 参数转换为 QEMU 的 -kernel 参数；未修改 Makefile、评分脚本、注入脚本或评分断言。对照评分得到 20/20，分别保留原始失败和适配成功日志。此问题属于评分启动环境故障，本轮没有为它修改分配器。

## 本轮未执行的检查

- 原样 make grade 中的内核评分断言因未进入内核而未执行；已明确记录为“未执行”，不是通过。
- 上一轮单独的 16 类地址转换负向输入、6 类非法 kfree 输入，以及 USE_SLUB 缺少 USE_BUDDY 的编译负向用例，本轮未重复执行；本轮不引用它们作为新增通过结果。
- 未执行多核或真实硬件验证；实现和本轮用例面向当前单核 Lab 环境。

## 复现命令

在 WSL/Linux 的工程根目录依次执行：

```bash
make clean
make grade

# 即使原评分受启动兼容问题影响，也继续分别验证下面两种配置。
make clean
make -j2 DEFS="-DUSE_BUDDY"
make qemu DEFS="-DUSE_BUDDY"

make clean
make -j2 DEFS="-DUSE_BUDDY -DUSE_SLUB"
make qemu DEFS="-DUSE_BUDDY -DUSE_SLUB"
```

QEMU 手动退出：Ctrl+A，再按 X。外部适配对照：

```bash
chmod +x validation/qemu_grade_compat.py
make grade QEMU="$(pwd)/validation/qemu_grade_compat.py"
```

自动执行及保留日志：

```bash
python3 validation/run_checks.py
```

该脚本会保留原始 make grade 的失败结果后继续执行其余配置；应逐项读取 results.json，不能把脚本结束当作原始评分通过。

## 日志索引

| 文件 | 用途 |
|---|---|
| `default_build.log` | 默认配置独立编译结果 |
| `default_grade_raw.log` | 要求原样执行的原始评分失败输出 |
| `default_grade_raw_serial.log` | 原评分固件未跳入内核的串口复现 |
| `default_grade_compatible.log` | 外部启动适配后的 20/20 对照 |
| `buddy_clean.log`、`buddy_build.log`、`buddy_boot.log` | Buddy 配置切换、编译和真实启动 |
| `slub_clean.log`、`slub_build.log`、`slub_boot.log` | Buddy+SLUB 配置切换、编译和真实启动 |
| `host_compile.log`、`host_runtime.log` | 主机编译及保护页、ASan/UBSan 验证 |
| `slub_stack.su` | 真实 RISC-V 编译生成的静态栈帧记录 |
| `results.json`、`summary.json` | 逐项退出状态、运行与断言状态，以及恢复页数 |
| `before_hashes.json`、`source_integrity.json` | 改动前文件哈希及本轮变更范围证明 |
| `slub_before.c` | 本轮修改前自检源码，便于审查差异 |
