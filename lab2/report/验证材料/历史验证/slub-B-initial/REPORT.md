# ucore Lab2 简化 SLUB：实现与实际验证

## 交付与改动

完整源码目录为同级 `lab2_new/`，压缩包为 `lab2_buddy_slub.zip`。相对上一轮已验证 Buddy 工程，本次核心改动恰好四个文件：

| 文件 | 改动 |
|---|---|
| `kern/mm/slub.c` | 新增单核 SLUB、页内元数据、对象分配释放及自检 |
| `kern/mm/slub.h` | 新增四个公开接口及 `USE_SLUB` 依赖 `USE_BUDDY` 的编译检查 |
| `kern/mm/pmm.h` | 恢复 KADDR，完善物理/虚拟/描述符边界检查，新增 page2kva、kva2page |
| `kern/init/init.c` | USE_SLUB 下，在 pmm_init 后调用 slub_init 和 slub_check |

哈希比对确认其他原始文件完全不变，包括 Buddy、A 的初始化与 Best-Fit 实现、`pmm.c`、`struct Page` 所在的 `memlayout.h`、Makefile 及原评分代码。附加验证代码和日志位于 `validation/`，不参与常规内核编译。

`SLUB代码修改.patch` 只包含上述四个文件的变化，应用基线是上一轮的 Buddy 版本。

## 对象和元数据布局

- 小对象容量类别为 16、32、64、128、256、512、1024、2048 字节。
- 每个小对象页的开头保存独立页头与 256 位位图；RV64 下页头按 16 字节向上对齐后为 96 字节。用户对象从页头之后开始，各槽完整拥有对应容量。
- 例如 2048 字节类别每页一个槽，仍提供完整 2048 字节可写容量；元数据不占用该容量。
- 各类别用活动页链表记录所有存活 slab，通过位图寻找空闲槽；无可用槽时向 Buddy 申请 1 页。
- 大于 2048 字节的对象申请 `ceil((size + header_size)/4096)` 页，页头保存对象容量、页描述符和原始申请页数。Buddy 可以进一步向上取整，释放时仍传原始申请页数，归还完整块。
- 元数据直接保存在取得的页中，不调用 kmalloc，不修改 Page 布局或 Buddy 私有状态。
- slub_init 只初始化静态链表与类别，不预占动态页，且只允许首次初始化。

## 边界与回收约定

- 成功返回的指针按 16 字节对齐，至少有 size 字节可写，不与其他存活对象重叠。
- kmalloc(0) 返回 NULL；kfree(NULL) 不做操作。
- 计算 size 加页头前先检查溢出；页数取整使用除法和余数，避免再次加 4095 导致溢出。
- 底层申请失败时不注册任何新页头或对象；取得页后不再执行可能失败的动态分配，因此不存在部分构造后的泄漏。
- 小对象页的最后一个对象释放后，先从活动链表移除页头，再立即归还 Buddy。大对象也先移除归属记录，再完整释放底层块。
- kfree 先搜索活动页/大对象记录确认归属，不把任意传入指针向下取整后读取页头。归还页后立即返回，不再读取页头或其链表指针。
- 错误指针、对象内部指针、重复释放触发 panic；调用者必须只释放仍存活的返回指针。
- 地址转换使用现有 PHYSICAL_MEMORY_OFFSET。KADDR/PADDR 的内核可转换范围为 `[KERNEL_BEGIN_PADDR, min(npage*4096, PHYSICAL_MEMORY_END))` 对应的高地址直接映射；描述符转换单独检查 `[pages, pages+(npage-nbase))`。
- pa2page 额外检查物理页号下界，允许取得 DRAM 内保留页的描述符，但 KADDR 不允许把 OpenSBI 区域转换为本接口的内核对象地址。

## 实际构建与运行结果

环境：WSL2 Linux，RISC-V ELF GCC，QEMU 7.0.0 / OpenSBI v1.0。

| 验证 | 实际结果 |
|---|---|
| 默认配置干净构建 | 通过，退出码 0 |
| 默认 Best-Fit 启动 | 通过，check_alloc_page 成功 |
| Buddy 配置干净构建与启动 | 通过，Buddy 全部自检成功 |
| Buddy + SLUB 干净构建与启动 | 通过，Buddy 与 SLUB 全部自检成功 |
| USE_SLUB 未启用 USE_BUDDY | 按预期编译报错 `USE_SLUB requires USE_BUDDY` |
| 默认原评分 + 外部 QEMU 启动适配器 | 20/20，评分代码未修改 |
| SLUB QEMU 自检结束空闲页数 | 恢复到本配置初始的 31,926 页 |
| 主机补充随机测试 | 12,000 次混合操作通过，存活对象不重叠且数据保持 |
| 主机 ASan / UBSan | 有效操作测试未报告错误 |
| 已释放页访问检测 | 归还的底层页立即设为 PROT_NONE，未发现释放后访问 |
| 实际 pmm.h 转换代码 | 256 页起点/末字节往返测试通过 |
| 地址转换负向测试 | 16 类非法输入均被 panic 拒绝，返回 73 |
| 对象释放负向测试 | 6 类非法释放均被拒绝，返回 73 |

QEMU 内核自检的实际输出：

```text
slub_check: conversions, zero and overflow requests passed
slub_check: all classes, alignment, non-overlap and data passed
slub_check: multiple slabs, reuse and immediate reclaim passed
slub_check: large object returned complete rounded block
slub_check: exhaustion, rollback and live data preservation passed
slub_check() succeeded! restored 31926 free pages
```

本配置比上一轮 Buddy 内核多了 SLUB 代码和静态数据，启动时可用页总数因内核体积而变化。泄漏判断比较同一配置自检前后的页数，本轮恢复到 31,926 页。

QEMU 验证程序在运行 12 秒、收集到全部成功标记后终止内核；内核正常完成初始化后本就进入无限循环。该限时结束不表示自检失败。

## 自检覆盖

1. NULL、零长度、加法溢出和明显超大请求不改变空闲页数。
2. 页描述符、物理地址、虚拟地址及页末字节往返一致。
3. 33 种尺寸覆盖所有容量类别与临界值，包括 2048/2049、4095/4096/4097、8192/8193 字节。
4. 写满小对象的完整类别容量，并读回全部字节，验证页头未侵占承诺容量、不同对象互不覆盖。
5. 40 个 128 字节对象跨页分配，释放槽位后获得同一地址，乱序释放后立即归还所有空页。
6. 8192 字节加页头需要原始 n=3，Buddy 实占 4 页；写入读回后释放，确认完整 4 页归还。
7. 保留一个有数据的对象后耗尽 Buddy：新类别和大对象申请失败，原有 slab 的空槽仍能分配，存活数据不变；结束后所有页归还。

## 运行与复现

在 WSL/Linux 中进入解压后的工程根目录。更换宏配置前须 make clean，原 Makefile 不跟踪命令行宏变化。

```bash
# 默认 Best-Fit
make clean
make -j2
make qemu

# Buddy
make clean
make -j2 DEFS="-DUSE_BUDDY"
make qemu DEFS="-DUSE_BUDDY"

# Buddy + SLUB（启动即运行全部自检）
make clean
make -j2 DEFS="-DUSE_BUDDY -DUSE_SLUB"
make qemu DEFS="-DUSE_BUDDY -DUSE_SLUB"
```

手动退出 QEMU：Ctrl+A，再按 X。

自动构建、启动三种配置并检查输出：

```bash
python3 validation/run_checks.py
```

默认评分在本机继续使用上一轮验证过的外部启动适配器。原评分的 generic loader 启动方式在本机 QEMU/OpenSBI 下未进入内核，该问题已在上一轮用未修改原始包复现；本轮未修改评分文件。

```bash
chmod +x validation/qemu_grade_compat.py
make grade QEMU="$(pwd)/validation/qemu_grade_compat.py"
```

主机补充测试只为实际 Buddy/SLUB 源码适配用户态地址映射与页保护；真实高地址转换已由 QEMU 及单独的实际 pmm.h 测试覆盖，不能把用户态映射适配测试当作真实 MMU 验证。

```bash
mkdir -p validation/slub_validation
gcc -std=gnu99 -O1 -g -Wall -Werror -Wno-unused -fno-builtin \
    -fsanitize=address,undefined -fno-omit-frame-pointer \
    -I libs -I kern/mm -I kern/debug \
    validation/slub_host_test.c -o validation/slub_validation/slub_host_test
./validation/slub_validation/slub_host_test

gcc -std=gnu99 -O1 -g -Wall -Werror -Wno-unused -fno-builtin \
    -fsanitize=address,undefined -fno-omit-frame-pointer \
    -I libs -I kern/mm -I kern/debug \
    validation/slub_conversion_test.c -o validation/slub_validation/slub_conversion_test
python3 validation/run_slub_negative.py
```

负向测试故意触发 panic，并检查返回码 73；有效操作测试预期返回 0。完整日志与源码完整性记录位于 `validation/logs/`。

## 简化范围

实现面向本实验的单核环境，没有多核锁、每 CPU 缓存或 NUMA 支持。小对象分配扫描活动页及位图，释放扫描活动归属记录；本次重点是正确性与可验证性。调用者仍需遵守对象生命周期；对象地址被再次分配后的旧指针误用属于调用者错误。
