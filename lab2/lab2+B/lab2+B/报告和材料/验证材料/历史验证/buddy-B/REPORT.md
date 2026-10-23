# ucore Lab2 Buddy 实现与验证

## 交付内容

- `lab2_buddy/`：可直接使用的工程源码。
- `lab2_buddy.zip`：同一工程的压缩包，不包含旧 `obj/`、`bin/`。
- `Buddy代码修改.patch`：仅包含 Buddy 实现与管理器选择的三个文件变更。
- 工程内 `validation/`：附加主机测试、QEMU 启动适配器及实际日志；不参与正常内核编译。

## 实际修改范围

1. 新增 `kern/mm/buddy_pmm.c`。
2. 新增 `kern/mm/buddy_pmm.h`。
3. 修改 `kern/mm/pmm.c`：条件引入 Buddy 头文件，并用 `USE_BUDDY` 选择管理器；未定义时仍选 Best-Fit。

已逐文件比对修改前 SHA-256：其他原始源码保持不变。移除新增的条件包含和选择分支后，`pmm.c` 与原文件文本完全一致。A 的 `page_init()`、First-Fit、Best-Fit、公开结构与接口、Makefile、原评分代码均未修改。本次没有实现 SLUB。

## 实现约定

- 使用真实 `struct Page`、`pmm_manager` 和 `list.h`，所有辅助函数和回调均为 `static`，只导出 `buddy_pmm_manager`。
- 阶数按页数计算，最小块为 1 页，即 4096 字节。伙伴通过物理页号 XOR 块页数定位，并在访问描述符前检查上下界。
- 仅注册 `page_init()` 传入的可用区域，描述符上界为 `npage-nbase`；根据物理对齐拆分，保留全部尾页，支持多段及相邻区域注册。
- 使用空闲的私有标志位 2、3、4 表示受管页、已分配页、分配首部，不改变公开标志定义或 `Page` 布局。
- 空闲块首部的 `property` 保存块页数；分配块首部保存原始申请 `n`；尾页有分配标记。申请 3 页实际占用 4 页，必须调用 `free_pages(head, 3)` 归还完整 4 页。
- 非法释放（错误原始 n、部分释放、重复释放、保留页、零长度、越界描述符）触发断言。只接受原始整块释放。
- 0、溢出、超过支持大小、超过描述符容量、空闲不足或碎片导致无适合块时，申请返回 NULL，不修改状态。
- 合并要求伙伴在有效范围内、为受管空闲块首部且大小相同；不会跨保留区合并。
- `buddy_check()` 检查链表、块对齐、分配不重叠、描述符覆盖、页数计数及充分合并，并实际执行申请和释放。

## 实际验证结果

环境：WSL2 Linux，`riscv64-unknown-elf-gcc`，QEMU 7.0.0，OpenSBI v1.0。

| 验证项 | 结果 |
|---|---|
| 默认配置干净编译 | 通过，包含新 Buddy 源文件的编译 |
| 默认 Best-Fit QEMU 启动 | 通过，输出 `check_alloc_page() succeeded!` |
| Buddy 配置干净编译 | 通过，`DEFS=-DUSE_BUDDY` |
| Buddy QEMU 启动及自检 | 全部通过，最终恢复 31,928 个空闲页 |
| 主机初始化组合测试 | 2,080 组起点/长度组合通过，包含非对齐起点、非 2 的幂长度及尾页 |
| 主机多段注册测试 | 相邻段合并、保留区空洞、最后一个描述符通过 |
| 主机随机测试 | 20,000 次混合申请/释放通过，检查重叠与计数 |
| 主机 ASan / UBSan | 有效操作测试未报告错误 |
| 非法释放测试 | 六类均按预期由断言拒绝，进程返回 73 |
| 不带适配器的原始 `make grade` | 0/20；未修改的原始压缩包在同一环境中也是 0/20 |
| 外部启动适配后的原始默认评分 | 20/20；评分源码及断言保持原样 |

QEMU 启动测试在看到成功标记后由验证程序限时停止。内核本来会在初始化后进入无限循环，因此限时结束不是自检失败。日志中不存在内核 panic 或断言失败。

## 原评分环境问题

原评分使用 `-device loader,file=bin/ucore.img,addr=0x80200000` 加载镜像。本机 QEMU 7.0.0/OpenSBI v1.0 在该方式下输出 `Domain0 Next Address : 0x0000000000000000`，未进入内核；原始包可复现相同结果。工程自身 `make qemu` 使用的 `-kernel` 启动方式可以正常进入内核。

附加的 `validation/qemu_grade_compat.py` 仅把上述 loader 参数转换成对应 `-kernel` 参数，保留其余评分参数。不改 `tools/grade.sh`、`tools/inject.py`、`tools/test_lab2.c` 或 Makefile。使用该外部适配器后，原评分得到 20/20。

## 运行命令

以下命令在 WSL/Linux 内、工程根目录执行。更换配置前需要 `make clean`，因为原 Makefile 不跟踪命令行宏变化。

```bash
# 默认配置：保留 A 的 Best-Fit
make clean
make -j2
make qemu

# Buddy：启动即运行 buddy_check()
make clean
make -j2 DEFS=-DUSE_BUDDY
make qemu DEFS=-DUSE_BUDDY
```

QEMU 使用 `Ctrl+A`，再按 `X` 退出。

```bash
# 默认原评分；若环境兼容，可直接运行
make clean
make grade

# 本机 QEMU/OpenSBI 的启动适配方式
chmod +x validation/qemu_grade_compat.py
make grade QEMU="$(pwd)/validation/qemu_grade_compat.py"
```

评分是 Best-Fit 专用检查，不要给 `make grade` 传 `DEFS=-DUSE_BUDDY` 来判断 Buddy 的正确性。

```bash
# 使用实际 Buddy 源码和 ucore 头文件的主机测试
gcc -std=gnu99 -O1 -g -Wall -Werror -Wno-unused -fno-builtin \
    -fsanitize=address,undefined -fno-omit-frame-pointer \
    -I libs -I kern/mm -I kern/debug \
    validation/buddy_host_test.c -o validation/buddy_host_test
./validation/buddy_host_test
```

六个负向用例可分别运行 `./validation/buddy_host_test n`、`p`、`d`、`r`、`z`、`b`；预期输出 assertion failed 并返回 73，分别表示错误 n、部分释放、重复释放、保留页、零长度和越界释放。

## 边界与限制

实现面向本 Lab 的单核、启动期物理页管理环境，未增加并发锁。每块大小受现有 `unsigned int property` 的可表示范围约束，超过支持范围会直接返回 NULL；本实验 128 MiB 物理内存不触及该限制。取整后产生的内部碎片计入实际占用页数。
