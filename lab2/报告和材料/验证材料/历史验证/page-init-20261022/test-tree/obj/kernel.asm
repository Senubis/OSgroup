
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00006297          	auipc	t0,0x6
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0206000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00006297          	auipc	t0,0x6
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0206008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02052b7          	lui	t0,0xc0205
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # The identity mapping below keeps instruction fetch valid until the high jump.
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d628293          	addi	t0,t0,214 # ffffffffc02000d6 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16 # ffffffffc0204ff0 <bootstack+0x1ff0>
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00002517          	auipc	a0,0x2
ffffffffc0200050:	e7450513          	addi	a0,a0,-396 # ffffffffc0201ec0 <etext>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f4000ef          	jal	ffffffffc020014a <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07c58593          	addi	a1,a1,124 # ffffffffc02000d6 <kern_init>
ffffffffc0200062:	00002517          	auipc	a0,0x2
ffffffffc0200066:	e7e50513          	addi	a0,a0,-386 # ffffffffc0201ee0 <etext+0x20>
ffffffffc020006a:	0e0000ef          	jal	ffffffffc020014a <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00002597          	auipc	a1,0x2
ffffffffc0200072:	e5258593          	addi	a1,a1,-430 # ffffffffc0201ec0 <etext>
ffffffffc0200076:	00002517          	auipc	a0,0x2
ffffffffc020007a:	e8a50513          	addi	a0,a0,-374 # ffffffffc0201f00 <etext+0x40>
ffffffffc020007e:	0cc000ef          	jal	ffffffffc020014a <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00006597          	auipc	a1,0x6
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0206018 <free_area>
ffffffffc020008a:	00002517          	auipc	a0,0x2
ffffffffc020008e:	e9650513          	addi	a0,a0,-362 # ffffffffc0201f20 <etext+0x60>
ffffffffc0200092:	0b8000ef          	jal	ffffffffc020014a <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00006597          	auipc	a1,0x6
ffffffffc020009a:	fe258593          	addi	a1,a1,-30 # ffffffffc0206078 <end>
ffffffffc020009e:	00002517          	auipc	a0,0x2
ffffffffc02000a2:	ea250513          	addi	a0,a0,-350 # ffffffffc0201f40 <etext+0x80>
ffffffffc02000a6:	0a4000ef          	jal	ffffffffc020014a <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00000717          	auipc	a4,0x0
ffffffffc02000ae:	02c70713          	addi	a4,a4,44 # ffffffffc02000d6 <kern_init>
ffffffffc02000b2:	00006797          	auipc	a5,0x6
ffffffffc02000b6:	3c578793          	addi	a5,a5,965 # ffffffffc0206477 <end+0x3ff>
ffffffffc02000ba:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000bc:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c0:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c2:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c6:	95be                	add	a1,a1,a5
ffffffffc02000c8:	85a9                	srai	a1,a1,0xa
ffffffffc02000ca:	00002517          	auipc	a0,0x2
ffffffffc02000ce:	e9650513          	addi	a0,a0,-362 # ffffffffc0201f60 <etext+0xa0>
}
ffffffffc02000d2:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d4:	a89d                	j	ffffffffc020014a <cprintf>

ffffffffc02000d6 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d6:	00006517          	auipc	a0,0x6
ffffffffc02000da:	f4250513          	addi	a0,a0,-190 # ffffffffc0206018 <free_area>
ffffffffc02000de:	00006617          	auipc	a2,0x6
ffffffffc02000e2:	f9a60613          	addi	a2,a2,-102 # ffffffffc0206078 <end>
int kern_init(void) {
ffffffffc02000e6:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000e8:	8e09                	sub	a2,a2,a0
ffffffffc02000ea:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ec:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000ee:	5c1010ef          	jal	ffffffffc0201eae <memset>
    dtb_init();
ffffffffc02000f2:	7c0000ef          	jal	ffffffffc02008b2 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f6:	7b2000ef          	jal	ffffffffc02008a8 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fa:	00003517          	auipc	a0,0x3
ffffffffc02000fe:	bee50513          	addi	a0,a0,-1042 # ffffffffc0202ce8 <etext+0xe28>
ffffffffc0200102:	07c000ef          	jal	ffffffffc020017e <cputs>

    print_kerninfo();
ffffffffc0200106:	f45ff0ef          	jal	ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010a:	662010ef          	jal	ffffffffc020176c <pmm_init>

    /* do nothing */
    while (1)
ffffffffc020010e:	a001                	j	ffffffffc020010e <kern_init+0x38>

ffffffffc0200110 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200110:	1141                	addi	sp,sp,-16
ffffffffc0200112:	e022                	sd	s0,0(sp)
ffffffffc0200114:	e406                	sd	ra,8(sp)
ffffffffc0200116:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200118:	792000ef          	jal	ffffffffc02008aa <cons_putc>
    (*cnt) ++;
ffffffffc020011c:	401c                	lw	a5,0(s0)
}
ffffffffc020011e:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200120:	2785                	addiw	a5,a5,1
ffffffffc0200122:	c01c                	sw	a5,0(s0)
}
ffffffffc0200124:	6402                	ld	s0,0(sp)
ffffffffc0200126:	0141                	addi	sp,sp,16
ffffffffc0200128:	8082                	ret

ffffffffc020012a <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020012a:	1101                	addi	sp,sp,-32
ffffffffc020012c:	862a                	mv	a2,a0
ffffffffc020012e:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200130:	00000517          	auipc	a0,0x0
ffffffffc0200134:	fe050513          	addi	a0,a0,-32 # ffffffffc0200110 <cputch>
ffffffffc0200138:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc020013a:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013c:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020013e:	159010ef          	jal	ffffffffc0201a96 <vprintfmt>
    return cnt;
}
ffffffffc0200142:	60e2                	ld	ra,24(sp)
ffffffffc0200144:	4532                	lw	a0,12(sp)
ffffffffc0200146:	6105                	addi	sp,sp,32
ffffffffc0200148:	8082                	ret

ffffffffc020014a <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020014a:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014c:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
ffffffffc0200150:	f42e                	sd	a1,40(sp)
ffffffffc0200152:	f832                	sd	a2,48(sp)
ffffffffc0200154:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200156:	862a                	mv	a2,a0
ffffffffc0200158:	004c                	addi	a1,sp,4
ffffffffc020015a:	00000517          	auipc	a0,0x0
ffffffffc020015e:	fb650513          	addi	a0,a0,-74 # ffffffffc0200110 <cputch>
ffffffffc0200162:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc0200164:	ec06                	sd	ra,24(sp)
ffffffffc0200166:	e0ba                	sd	a4,64(sp)
ffffffffc0200168:	e4be                	sd	a5,72(sp)
ffffffffc020016a:	e8c2                	sd	a6,80(sp)
ffffffffc020016c:	ecc6                	sd	a7,88(sp)
    int cnt = 0;
ffffffffc020016e:	c202                	sw	zero,4(sp)
    va_start(ap, fmt);
ffffffffc0200170:	e41a                	sd	t1,8(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200172:	125010ef          	jal	ffffffffc0201a96 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200176:	60e2                	ld	ra,24(sp)
ffffffffc0200178:	4512                	lw	a0,4(sp)
ffffffffc020017a:	6125                	addi	sp,sp,96
ffffffffc020017c:	8082                	ret

ffffffffc020017e <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc020017e:	1101                	addi	sp,sp,-32
ffffffffc0200180:	ec06                	sd	ra,24(sp)
ffffffffc0200182:	e822                	sd	s0,16(sp)
ffffffffc0200184:	87aa                	mv	a5,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200186:	00054503          	lbu	a0,0(a0)
ffffffffc020018a:	c905                	beqz	a0,ffffffffc02001ba <cputs+0x3c>
ffffffffc020018c:	e426                	sd	s1,8(sp)
ffffffffc020018e:	00178493          	addi	s1,a5,1
ffffffffc0200192:	8426                	mv	s0,s1
    cons_putc(c);
ffffffffc0200194:	716000ef          	jal	ffffffffc02008aa <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200198:	87a2                	mv	a5,s0
ffffffffc020019a:	00044503          	lbu	a0,0(s0)
ffffffffc020019e:	0405                	addi	s0,s0,1
ffffffffc02001a0:	f975                	bnez	a0,ffffffffc0200194 <cputs+0x16>
    (*cnt) ++;
ffffffffc02001a2:	9f85                	subw	a5,a5,s1
    cons_putc(c);
ffffffffc02001a4:	4529                	li	a0,10
    (*cnt) ++;
ffffffffc02001a6:	0027841b          	addiw	s0,a5,2
ffffffffc02001aa:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc02001ac:	6fe000ef          	jal	ffffffffc02008aa <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001b0:	60e2                	ld	ra,24(sp)
ffffffffc02001b2:	8522                	mv	a0,s0
ffffffffc02001b4:	6442                	ld	s0,16(sp)
ffffffffc02001b6:	6105                	addi	sp,sp,32
ffffffffc02001b8:	8082                	ret
    cons_putc(c);
ffffffffc02001ba:	4529                	li	a0,10
ffffffffc02001bc:	6ee000ef          	jal	ffffffffc02008aa <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc02001c0:	4405                	li	s0,1
}
ffffffffc02001c2:	60e2                	ld	ra,24(sp)
ffffffffc02001c4:	8522                	mv	a0,s0
ffffffffc02001c6:	6442                	ld	s0,16(sp)
ffffffffc02001c8:	6105                	addi	sp,sp,32
ffffffffc02001ca:	8082                	ret

ffffffffc02001cc <test_page_init_extra>:
#include <pmm.h>
#include <dtb.h>
#include <stdio.h>

void test_page_init_extra(void) {
ffffffffc02001cc:	711d                	addi	sp,sp,-96
ffffffffc02001ce:	ec86                	sd	ra,88(sp)
ffffffffc02001d0:	e8a2                	sd	s0,80(sp)
ffffffffc02001d2:	e4a6                	sd	s1,72(sp)
ffffffffc02001d4:	e0ca                	sd	s2,64(sp)
ffffffffc02001d6:	fc4e                	sd	s3,56(sp)
ffffffffc02001d8:	f852                	sd	s4,48(sp)
ffffffffc02001da:	f456                	sd	s5,40(sp)
ffffffffc02001dc:	f05a                	sd	s6,32(sp)
ffffffffc02001de:	ec5e                	sd	s7,24(sp)
ffffffffc02001e0:	e862                	sd	s8,16(sp)
ffffffffc02001e2:	e466                	sd	s9,8(sp)
    extern char end[];
    uint64_t reported_end = get_memory_base() + get_memory_size();
ffffffffc02001e4:	243000ef          	jal	ffffffffc0200c26 <get_memory_base>
ffffffffc02001e8:	842a                	mv	s0,a0
ffffffffc02001ea:	247000ef          	jal	ffffffffc0200c30 <get_memory_size>
    uintptr_t maxpa = ROUNDDOWN((uintptr_t)(reported_end < PHYSICAL_MEMORY_END
ffffffffc02001ee:	47c5                	li	a5,17
    uint64_t reported_end = get_memory_base() + get_memory_size();
ffffffffc02001f0:	942a                	add	s0,s0,a0
    uintptr_t maxpa = ROUNDDOWN((uintptr_t)(reported_end < PHYSICAL_MEMORY_END
ffffffffc02001f2:	07ee                	slli	a5,a5,0x1b
ffffffffc02001f4:	0087f363          	bgeu	a5,s0,ffffffffc02001fa <test_page_init_extra+0x2e>
ffffffffc02001f8:	843e                	mv	s0,a5
                              ? reported_end : PHYSICAL_MEMORY_END), PGSIZE);
    size_t count = PPN(maxpa) - nbase;
ffffffffc02001fa:	00003a97          	auipc	s5,0x3
ffffffffc02001fe:	cd6aba83          	ld	s5,-810(s5) # ffffffffc0202ed0 <nbase>
    uintptr_t maxpa = ROUNDDOWN((uintptr_t)(reported_end < PHYSICAL_MEMORY_END
ffffffffc0200202:	777d                	lui	a4,0xfffff
ffffffffc0200204:	8c79                	and	s0,s0,a4
    size_t count = PPN(maxpa) - nbase;
ffffffffc0200206:	00c45593          	srli	a1,s0,0xc
ffffffffc020020a:	41558b33          	sub	s6,a1,s5
    uintptr_t first_free = ROUNDUP(PADDR(pages + count), PGSIZE);
ffffffffc020020e:	00006997          	auipc	s3,0x6
ffffffffc0200212:	e6298993          	addi	s3,s3,-414 # ffffffffc0206070 <pages>
ffffffffc0200216:	0009b603          	ld	a2,0(s3)
ffffffffc020021a:	002b1693          	slli	a3,s6,0x2
ffffffffc020021e:	96da                	add	a3,a3,s6
ffffffffc0200220:	068e                	slli	a3,a3,0x3
ffffffffc0200222:	96b2                	add	a3,a3,a2
ffffffffc0200224:	c02007b7          	lui	a5,0xc0200
ffffffffc0200228:	32f6e463          	bltu	a3,a5,ffffffffc0200550 <test_page_init_extra+0x384>
ffffffffc020022c:	00006517          	auipc	a0,0x6
ffffffffc0200230:	e3453503          	ld	a0,-460(a0) # ffffffffc0206060 <va_pa_offset>
ffffffffc0200234:	6c05                	lui	s8,0x1
ffffffffc0200236:	fffc0b93          	addi	s7,s8,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc020023a:	40ab8bb3          	sub	s7,s7,a0
ffffffffc020023e:	9bb6                	add	s7,s7,a3
ffffffffc0200240:	00ebfbb3          	and	s7,s7,a4
    size_t expected_free = (maxpa - first_free) / PGSIZE;
    assert(va_pa_offset == PHYSICAL_MEMORY_OFFSET);
ffffffffc0200244:	57f5                	li	a5,-3
    size_t expected_free = (maxpa - first_free) / PGSIZE;
ffffffffc0200246:	417404b3          	sub	s1,s0,s7
    assert(va_pa_offset == PHYSICAL_MEMORY_OFFSET);
ffffffffc020024a:	07fa                	slli	a5,a5,0x1e
    size_t expected_free = (maxpa - first_free) / PGSIZE;
ffffffffc020024c:	80b1                	srli	s1,s1,0xc
    assert(va_pa_offset == PHYSICAL_MEMORY_OFFSET);
ffffffffc020024e:	2ef51263          	bne	a0,a5,ffffffffc0200532 <test_page_init_extra+0x366>
    assert(npage == PPN(maxpa));
ffffffffc0200252:	00006a17          	auipc	s4,0x6
ffffffffc0200256:	e16a0a13          	addi	s4,s4,-490 # ffffffffc0206068 <npage>
ffffffffc020025a:	000a3783          	ld	a5,0(s4)
ffffffffc020025e:	26f59d63          	bne	a1,a5,ffffffffc02004d8 <test_page_init_extra+0x30c>
    assert((uintptr_t)pages == ROUNDUP((uintptr_t)end, PGSIZE));
ffffffffc0200262:	00007797          	auipc	a5,0x7
ffffffffc0200266:	e1578793          	addi	a5,a5,-491 # ffffffffc0207077 <end+0xfff>
ffffffffc020026a:	8ff9                	and	a5,a5,a4
ffffffffc020026c:	24f61763          	bne	a2,a5,ffffffffc02004ba <test_page_init_extra+0x2ee>
    assert(nr_free_pages() == expected_free);
ffffffffc0200270:	4f0010ef          	jal	ffffffffc0201760 <nr_free_pages>
ffffffffc0200274:	22951463          	bne	a0,s1,ffffffffc020049c <test_page_init_extra+0x2d0>
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0200278:	000a3883          	ld	a7,0(s4)
ffffffffc020027c:	00cbdc93          	srli	s9,s7,0xc
ffffffffc0200280:	1d1cf463          	bgeu	s9,a7,ffffffffc0200448 <test_page_init_extra+0x27c>
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0200284:	415c87b3          	sub	a5,s9,s5
ffffffffc0200288:	00279913          	slli	s2,a5,0x2
ffffffffc020028c:	0009b583          	ld	a1,0(s3)
ffffffffc0200290:	993e                	add	s2,s2,a5
ffffffffc0200292:	090e                	slli	s2,s2,0x3
ffffffffc0200294:	01258733          	add	a4,a1,s2
    assert(PageProperty(pa2page(first_free)));
ffffffffc0200298:	671c                	ld	a5,8(a4)
ffffffffc020029a:	8b89                	andi	a5,a5,2
ffffffffc020029c:	26078c63          	beqz	a5,ffffffffc0200514 <test_page_init_extra+0x348>
    assert(pa2page(first_free)->property == expected_free);
ffffffffc02002a0:	01076783          	lwu	a5,16(a4) # fffffffffffff010 <end+0x3fdf8f98>
ffffffffc02002a4:	24979963          	bne	a5,s1,ffffffffc02004f6 <test_page_init_extra+0x32a>

    for (size_t i = 0; i < count; i++) {
ffffffffc02002a8:	0a0b0263          	beqz	s6,ffffffffc020034c <test_page_init_extra+0x180>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02002ac:	ccccd7b7          	lui	a5,0xccccd
ffffffffc02002b0:	ccd78793          	addi	a5,a5,-819 # ffffffffcccccccd <end+0xcac6c55>
ffffffffc02002b4:	02079693          	slli	a3,a5,0x20
ffffffffc02002b8:	96be                	add	a3,a3,a5
ffffffffc02002ba:	00ca9613          	slli	a2,s5,0xc
ffffffffc02002be:	4501                	li	a0,0
ffffffffc02002c0:	4801                	li	a6,0
ffffffffc02002c2:	a00d                	j	ffffffffc02002e4 <test_page_init_extra+0x118>
        uintptr_t pa = (nbase + i) * PGSIZE;
        assert(page2pa(p) == pa);
        assert(pa2page(pa) == p);
        assert(page_ref(p) == 0);
        if (pa < first_free) {
            assert(PageReserved(p));
ffffffffc02002c4:	1a070d63          	beqz	a4,ffffffffc020047e <test_page_init_extra+0x2b2>
            assert(p->property == 0 && !PageProperty(p));
ffffffffc02002c8:	4998                	lw	a4,16(a1)
ffffffffc02002ca:	10071363          	bnez	a4,ffffffffc02003d0 <test_page_init_extra+0x204>
ffffffffc02002ce:	8b89                	andi	a5,a5,2
ffffffffc02002d0:	10079063          	bnez	a5,ffffffffc02003d0 <test_page_init_extra+0x204>
    for (size_t i = 0; i < count; i++) {
ffffffffc02002d4:	0805                	addi	a6,a6,1
ffffffffc02002d6:	02850513          	addi	a0,a0,40
ffffffffc02002da:	9662                	add	a2,a2,s8
ffffffffc02002dc:	02858593          	addi	a1,a1,40
ffffffffc02002e0:	070b0663          	beq	s6,a6,ffffffffc020034c <test_page_init_extra+0x180>
ffffffffc02002e4:	40355793          	srai	a5,a0,0x3
ffffffffc02002e8:	02d787b3          	mul	a5,a5,a3
ffffffffc02002ec:	97d6                	add	a5,a5,s5
    return page2ppn(page) << PGSHIFT;
ffffffffc02002ee:	07b2                	slli	a5,a5,0xc
        assert(page2pa(p) == pa);
ffffffffc02002f0:	12c79d63          	bne	a5,a2,ffffffffc020042a <test_page_init_extra+0x25e>
    if (PPN(pa) >= npage) {
ffffffffc02002f4:	00c65713          	srli	a4,a2,0xc
ffffffffc02002f8:	15177863          	bgeu	a4,a7,ffffffffc0200448 <test_page_init_extra+0x27c>
    return &pages[PPN(pa) - nbase];
ffffffffc02002fc:	41570733          	sub	a4,a4,s5
ffffffffc0200300:	00271793          	slli	a5,a4,0x2
ffffffffc0200304:	97ba                	add	a5,a5,a4
ffffffffc0200306:	078e                	slli	a5,a5,0x3
        assert(pa2page(pa) == p);
ffffffffc0200308:	10a79263          	bne	a5,a0,ffffffffc020040c <test_page_init_extra+0x240>
        assert(page_ref(p) == 0);
ffffffffc020030c:	419c                	lw	a5,0(a1)
ffffffffc020030e:	0e079063          	bnez	a5,ffffffffc02003ee <test_page_init_extra+0x222>
            assert(PageReserved(p));
ffffffffc0200312:	659c                	ld	a5,8(a1)
ffffffffc0200314:	0017f713          	andi	a4,a5,1
        if (pa < first_free) {
ffffffffc0200318:	fb7666e3          	bltu	a2,s7,ffffffffc02002c4 <test_page_init_extra+0xf8>
        } else {
            assert(!PageReserved(p));
ffffffffc020031c:	14071263          	bnez	a4,ffffffffc0200460 <test_page_init_extra+0x294>
            if (pa != first_free) {
ffffffffc0200320:	facb8ae3          	beq	s7,a2,ffffffffc02002d4 <test_page_init_extra+0x108>
                assert(!PageProperty(p) && p->property == 0);
ffffffffc0200324:	8b89                	andi	a5,a5,2
ffffffffc0200326:	e399                	bnez	a5,ffffffffc020032c <test_page_init_extra+0x160>
ffffffffc0200328:	499c                	lw	a5,16(a1)
ffffffffc020032a:	d7cd                	beqz	a5,ffffffffc02002d4 <test_page_init_extra+0x108>
ffffffffc020032c:	00002697          	auipc	a3,0x2
ffffffffc0200330:	e8468693          	addi	a3,a3,-380 # ffffffffc02021b0 <etext+0x2f0>
ffffffffc0200334:	00002617          	auipc	a2,0x2
ffffffffc0200338:	ccc60613          	addi	a2,a2,-820 # ffffffffc0202000 <etext+0x140>
ffffffffc020033c:	02000593          	li	a1,32
ffffffffc0200340:	00002517          	auipc	a0,0x2
ffffffffc0200344:	c7850513          	addi	a0,a0,-904 # ffffffffc0201fb8 <etext+0xf8>
ffffffffc0200348:	2de000ef          	jal	ffffffffc0200626 <__panic>
            }
        }
    }
    assert(alloc_pages(expected_free + 1) == NULL);
ffffffffc020034c:	00148513          	addi	a0,s1,1
ffffffffc0200350:	3f8010ef          	jal	ffffffffc0201748 <alloc_pages>
ffffffffc0200354:	2a051963          	bnez	a0,ffffffffc0200606 <test_page_init_extra+0x43a>
    struct Page *all = alloc_pages(expected_free);
ffffffffc0200358:	8526                	mv	a0,s1
ffffffffc020035a:	3ee010ef          	jal	ffffffffc0201748 <alloc_pages>
    if (PPN(pa) >= npage) {
ffffffffc020035e:	000a3783          	ld	a5,0(s4)
ffffffffc0200362:	8a2a                	mv	s4,a0
ffffffffc0200364:	0efcf263          	bgeu	s9,a5,ffffffffc0200448 <test_page_init_extra+0x27c>
    return &pages[PPN(pa) - nbase];
ffffffffc0200368:	0009b783          	ld	a5,0(s3)
ffffffffc020036c:	97ca                	add	a5,a5,s2
    assert(all == pa2page(first_free));
ffffffffc020036e:	26f51c63          	bne	a0,a5,ffffffffc02005e6 <test_page_init_extra+0x41a>
    assert(nr_free_pages() == 0);
ffffffffc0200372:	3ee010ef          	jal	ffffffffc0201760 <nr_free_pages>
ffffffffc0200376:	24051863          	bnez	a0,ffffffffc02005c6 <test_page_init_extra+0x3fa>
    assert(alloc_page() == NULL);
ffffffffc020037a:	4505                	li	a0,1
ffffffffc020037c:	3cc010ef          	jal	ffffffffc0201748 <alloc_pages>
ffffffffc0200380:	22051363          	bnez	a0,ffffffffc02005a6 <test_page_init_extra+0x3da>
    free_pages(all, expected_free);
ffffffffc0200384:	85a6                	mv	a1,s1
ffffffffc0200386:	8552                	mv	a0,s4
ffffffffc0200388:	3cc010ef          	jal	ffffffffc0201754 <free_pages>
    assert(nr_free_pages() == expected_free);
ffffffffc020038c:	3d4010ef          	jal	ffffffffc0201760 <nr_free_pages>
ffffffffc0200390:	1e951b63          	bne	a0,s1,ffffffffc0200586 <test_page_init_extra+0x3ba>
    assert(PageProperty(all) && all->property == expected_free);
ffffffffc0200394:	008a3783          	ld	a5,8(s4)
ffffffffc0200398:	8b89                	andi	a5,a5,2
ffffffffc020039a:	1c078663          	beqz	a5,ffffffffc0200566 <test_page_init_extra+0x39a>
ffffffffc020039e:	010a6783          	lwu	a5,16(s4)
ffffffffc02003a2:	1c979263          	bne	a5,s1,ffffffffc0200566 <test_page_init_extra+0x39a>
    cprintf("[Extra] Page Init: PASS (descriptors=%lu free=%lu first=0x%lx limit=0x%lx)\n",
ffffffffc02003a6:	8722                	mv	a4,s0
            count, expected_free, first_free, maxpa);
}
ffffffffc02003a8:	6446                	ld	s0,80(sp)
ffffffffc02003aa:	60e6                	ld	ra,88(sp)
ffffffffc02003ac:	6906                	ld	s2,64(sp)
ffffffffc02003ae:	79e2                	ld	s3,56(sp)
ffffffffc02003b0:	7a42                	ld	s4,48(sp)
ffffffffc02003b2:	7aa2                	ld	s5,40(sp)
ffffffffc02003b4:	6c42                	ld	s8,16(sp)
ffffffffc02003b6:	6ca2                	ld	s9,8(sp)
    cprintf("[Extra] Page Init: PASS (descriptors=%lu free=%lu first=0x%lx limit=0x%lx)\n",
ffffffffc02003b8:	86de                	mv	a3,s7
ffffffffc02003ba:	8626                	mv	a2,s1
}
ffffffffc02003bc:	6be2                	ld	s7,24(sp)
ffffffffc02003be:	64a6                	ld	s1,72(sp)
    cprintf("[Extra] Page Init: PASS (descriptors=%lu free=%lu first=0x%lx limit=0x%lx)\n",
ffffffffc02003c0:	85da                	mv	a1,s6
}
ffffffffc02003c2:	7b02                	ld	s6,32(sp)
    cprintf("[Extra] Page Init: PASS (descriptors=%lu free=%lu first=0x%lx limit=0x%lx)\n",
ffffffffc02003c4:	00002517          	auipc	a0,0x2
ffffffffc02003c8:	ec450513          	addi	a0,a0,-316 # ffffffffc0202288 <etext+0x3c8>
}
ffffffffc02003cc:	6125                	addi	sp,sp,96
    cprintf("[Extra] Page Init: PASS (descriptors=%lu free=%lu first=0x%lx limit=0x%lx)\n",
ffffffffc02003ce:	bbb5                	j	ffffffffc020014a <cprintf>
            assert(p->property == 0 && !PageProperty(p));
ffffffffc02003d0:	00002697          	auipc	a3,0x2
ffffffffc02003d4:	da068693          	addi	a3,a3,-608 # ffffffffc0202170 <etext+0x2b0>
ffffffffc02003d8:	00002617          	auipc	a2,0x2
ffffffffc02003dc:	c2860613          	addi	a2,a2,-984 # ffffffffc0202000 <etext+0x140>
ffffffffc02003e0:	45f1                	li	a1,28
ffffffffc02003e2:	00002517          	auipc	a0,0x2
ffffffffc02003e6:	bd650513          	addi	a0,a0,-1066 # ffffffffc0201fb8 <etext+0xf8>
ffffffffc02003ea:	23c000ef          	jal	ffffffffc0200626 <__panic>
        assert(page_ref(p) == 0);
ffffffffc02003ee:	00002697          	auipc	a3,0x2
ffffffffc02003f2:	d5a68693          	addi	a3,a3,-678 # ffffffffc0202148 <etext+0x288>
ffffffffc02003f6:	00002617          	auipc	a2,0x2
ffffffffc02003fa:	c0a60613          	addi	a2,a2,-1014 # ffffffffc0202000 <etext+0x140>
ffffffffc02003fe:	45e5                	li	a1,25
ffffffffc0200400:	00002517          	auipc	a0,0x2
ffffffffc0200404:	bb850513          	addi	a0,a0,-1096 # ffffffffc0201fb8 <etext+0xf8>
ffffffffc0200408:	21e000ef          	jal	ffffffffc0200626 <__panic>
        assert(pa2page(pa) == p);
ffffffffc020040c:	00002697          	auipc	a3,0x2
ffffffffc0200410:	d2468693          	addi	a3,a3,-732 # ffffffffc0202130 <etext+0x270>
ffffffffc0200414:	00002617          	auipc	a2,0x2
ffffffffc0200418:	bec60613          	addi	a2,a2,-1044 # ffffffffc0202000 <etext+0x140>
ffffffffc020041c:	45e1                	li	a1,24
ffffffffc020041e:	00002517          	auipc	a0,0x2
ffffffffc0200422:	b9a50513          	addi	a0,a0,-1126 # ffffffffc0201fb8 <etext+0xf8>
ffffffffc0200426:	200000ef          	jal	ffffffffc0200626 <__panic>
        assert(page2pa(p) == pa);
ffffffffc020042a:	00002697          	auipc	a3,0x2
ffffffffc020042e:	cee68693          	addi	a3,a3,-786 # ffffffffc0202118 <etext+0x258>
ffffffffc0200432:	00002617          	auipc	a2,0x2
ffffffffc0200436:	bce60613          	addi	a2,a2,-1074 # ffffffffc0202000 <etext+0x140>
ffffffffc020043a:	45dd                	li	a1,23
ffffffffc020043c:	00002517          	auipc	a0,0x2
ffffffffc0200440:	b7c50513          	addi	a0,a0,-1156 # ffffffffc0201fb8 <etext+0xf8>
ffffffffc0200444:	1e2000ef          	jal	ffffffffc0200626 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0200448:	00002617          	auipc	a2,0x2
ffffffffc020044c:	c4860613          	addi	a2,a2,-952 # ffffffffc0202090 <etext+0x1d0>
ffffffffc0200450:	06a00593          	li	a1,106
ffffffffc0200454:	00002517          	auipc	a0,0x2
ffffffffc0200458:	c5c50513          	addi	a0,a0,-932 # ffffffffc02020b0 <etext+0x1f0>
ffffffffc020045c:	1ca000ef          	jal	ffffffffc0200626 <__panic>
            assert(!PageReserved(p));
ffffffffc0200460:	00002697          	auipc	a3,0x2
ffffffffc0200464:	d3868693          	addi	a3,a3,-712 # ffffffffc0202198 <etext+0x2d8>
ffffffffc0200468:	00002617          	auipc	a2,0x2
ffffffffc020046c:	b9860613          	addi	a2,a2,-1128 # ffffffffc0202000 <etext+0x140>
ffffffffc0200470:	45f9                	li	a1,30
ffffffffc0200472:	00002517          	auipc	a0,0x2
ffffffffc0200476:	b4650513          	addi	a0,a0,-1210 # ffffffffc0201fb8 <etext+0xf8>
ffffffffc020047a:	1ac000ef          	jal	ffffffffc0200626 <__panic>
            assert(PageReserved(p));
ffffffffc020047e:	00002697          	auipc	a3,0x2
ffffffffc0200482:	ce268693          	addi	a3,a3,-798 # ffffffffc0202160 <etext+0x2a0>
ffffffffc0200486:	00002617          	auipc	a2,0x2
ffffffffc020048a:	b7a60613          	addi	a2,a2,-1158 # ffffffffc0202000 <etext+0x140>
ffffffffc020048e:	45ed                	li	a1,27
ffffffffc0200490:	00002517          	auipc	a0,0x2
ffffffffc0200494:	b2850513          	addi	a0,a0,-1240 # ffffffffc0201fb8 <etext+0xf8>
ffffffffc0200498:	18e000ef          	jal	ffffffffc0200626 <__panic>
    assert(nr_free_pages() == expected_free);
ffffffffc020049c:	00002697          	auipc	a3,0x2
ffffffffc02004a0:	bcc68693          	addi	a3,a3,-1076 # ffffffffc0202068 <etext+0x1a8>
ffffffffc02004a4:	00002617          	auipc	a2,0x2
ffffffffc02004a8:	b5c60613          	addi	a2,a2,-1188 # ffffffffc0202000 <etext+0x140>
ffffffffc02004ac:	45c1                	li	a1,16
ffffffffc02004ae:	00002517          	auipc	a0,0x2
ffffffffc02004b2:	b0a50513          	addi	a0,a0,-1270 # ffffffffc0201fb8 <etext+0xf8>
ffffffffc02004b6:	170000ef          	jal	ffffffffc0200626 <__panic>
    assert((uintptr_t)pages == ROUNDUP((uintptr_t)end, PGSIZE));
ffffffffc02004ba:	00002697          	auipc	a3,0x2
ffffffffc02004be:	b7668693          	addi	a3,a3,-1162 # ffffffffc0202030 <etext+0x170>
ffffffffc02004c2:	00002617          	auipc	a2,0x2
ffffffffc02004c6:	b3e60613          	addi	a2,a2,-1218 # ffffffffc0202000 <etext+0x140>
ffffffffc02004ca:	45bd                	li	a1,15
ffffffffc02004cc:	00002517          	auipc	a0,0x2
ffffffffc02004d0:	aec50513          	addi	a0,a0,-1300 # ffffffffc0201fb8 <etext+0xf8>
ffffffffc02004d4:	152000ef          	jal	ffffffffc0200626 <__panic>
    assert(npage == PPN(maxpa));
ffffffffc02004d8:	00002697          	auipc	a3,0x2
ffffffffc02004dc:	b4068693          	addi	a3,a3,-1216 # ffffffffc0202018 <etext+0x158>
ffffffffc02004e0:	00002617          	auipc	a2,0x2
ffffffffc02004e4:	b2060613          	addi	a2,a2,-1248 # ffffffffc0202000 <etext+0x140>
ffffffffc02004e8:	45b9                	li	a1,14
ffffffffc02004ea:	00002517          	auipc	a0,0x2
ffffffffc02004ee:	ace50513          	addi	a0,a0,-1330 # ffffffffc0201fb8 <etext+0xf8>
ffffffffc02004f2:	134000ef          	jal	ffffffffc0200626 <__panic>
    assert(pa2page(first_free)->property == expected_free);
ffffffffc02004f6:	00002697          	auipc	a3,0x2
ffffffffc02004fa:	bf268693          	addi	a3,a3,-1038 # ffffffffc02020e8 <etext+0x228>
ffffffffc02004fe:	00002617          	auipc	a2,0x2
ffffffffc0200502:	b0260613          	addi	a2,a2,-1278 # ffffffffc0202000 <etext+0x140>
ffffffffc0200506:	45c9                	li	a1,18
ffffffffc0200508:	00002517          	auipc	a0,0x2
ffffffffc020050c:	ab050513          	addi	a0,a0,-1360 # ffffffffc0201fb8 <etext+0xf8>
ffffffffc0200510:	116000ef          	jal	ffffffffc0200626 <__panic>
    assert(PageProperty(pa2page(first_free)));
ffffffffc0200514:	00002697          	auipc	a3,0x2
ffffffffc0200518:	bac68693          	addi	a3,a3,-1108 # ffffffffc02020c0 <etext+0x200>
ffffffffc020051c:	00002617          	auipc	a2,0x2
ffffffffc0200520:	ae460613          	addi	a2,a2,-1308 # ffffffffc0202000 <etext+0x140>
ffffffffc0200524:	45c5                	li	a1,17
ffffffffc0200526:	00002517          	auipc	a0,0x2
ffffffffc020052a:	a9250513          	addi	a0,a0,-1390 # ffffffffc0201fb8 <etext+0xf8>
ffffffffc020052e:	0f8000ef          	jal	ffffffffc0200626 <__panic>
    assert(va_pa_offset == PHYSICAL_MEMORY_OFFSET);
ffffffffc0200532:	00002697          	auipc	a3,0x2
ffffffffc0200536:	aa668693          	addi	a3,a3,-1370 # ffffffffc0201fd8 <etext+0x118>
ffffffffc020053a:	00002617          	auipc	a2,0x2
ffffffffc020053e:	ac660613          	addi	a2,a2,-1338 # ffffffffc0202000 <etext+0x140>
ffffffffc0200542:	45b5                	li	a1,13
ffffffffc0200544:	00002517          	auipc	a0,0x2
ffffffffc0200548:	a7450513          	addi	a0,a0,-1420 # ffffffffc0201fb8 <etext+0xf8>
ffffffffc020054c:	0da000ef          	jal	ffffffffc0200626 <__panic>
    uintptr_t first_free = ROUNDUP(PADDR(pages + count), PGSIZE);
ffffffffc0200550:	00002617          	auipc	a2,0x2
ffffffffc0200554:	a4060613          	addi	a2,a2,-1472 # ffffffffc0201f90 <etext+0xd0>
ffffffffc0200558:	45ad                	li	a1,11
ffffffffc020055a:	00002517          	auipc	a0,0x2
ffffffffc020055e:	a5e50513          	addi	a0,a0,-1442 # ffffffffc0201fb8 <etext+0xf8>
ffffffffc0200562:	0c4000ef          	jal	ffffffffc0200626 <__panic>
    assert(PageProperty(all) && all->property == expected_free);
ffffffffc0200566:	00002697          	auipc	a3,0x2
ffffffffc020056a:	cea68693          	addi	a3,a3,-790 # ffffffffc0202250 <etext+0x390>
ffffffffc020056e:	00002617          	auipc	a2,0x2
ffffffffc0200572:	a9260613          	addi	a2,a2,-1390 # ffffffffc0202000 <etext+0x140>
ffffffffc0200576:	02b00593          	li	a1,43
ffffffffc020057a:	00002517          	auipc	a0,0x2
ffffffffc020057e:	a3e50513          	addi	a0,a0,-1474 # ffffffffc0201fb8 <etext+0xf8>
ffffffffc0200582:	0a4000ef          	jal	ffffffffc0200626 <__panic>
    assert(nr_free_pages() == expected_free);
ffffffffc0200586:	00002697          	auipc	a3,0x2
ffffffffc020058a:	ae268693          	addi	a3,a3,-1310 # ffffffffc0202068 <etext+0x1a8>
ffffffffc020058e:	00002617          	auipc	a2,0x2
ffffffffc0200592:	a7260613          	addi	a2,a2,-1422 # ffffffffc0202000 <etext+0x140>
ffffffffc0200596:	02a00593          	li	a1,42
ffffffffc020059a:	00002517          	auipc	a0,0x2
ffffffffc020059e:	a1e50513          	addi	a0,a0,-1506 # ffffffffc0201fb8 <etext+0xf8>
ffffffffc02005a2:	084000ef          	jal	ffffffffc0200626 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02005a6:	00002697          	auipc	a3,0x2
ffffffffc02005aa:	c9268693          	addi	a3,a3,-878 # ffffffffc0202238 <etext+0x378>
ffffffffc02005ae:	00002617          	auipc	a2,0x2
ffffffffc02005b2:	a5260613          	addi	a2,a2,-1454 # ffffffffc0202000 <etext+0x140>
ffffffffc02005b6:	02800593          	li	a1,40
ffffffffc02005ba:	00002517          	auipc	a0,0x2
ffffffffc02005be:	9fe50513          	addi	a0,a0,-1538 # ffffffffc0201fb8 <etext+0xf8>
ffffffffc02005c2:	064000ef          	jal	ffffffffc0200626 <__panic>
    assert(nr_free_pages() == 0);
ffffffffc02005c6:	00002697          	auipc	a3,0x2
ffffffffc02005ca:	c5a68693          	addi	a3,a3,-934 # ffffffffc0202220 <etext+0x360>
ffffffffc02005ce:	00002617          	auipc	a2,0x2
ffffffffc02005d2:	a3260613          	addi	a2,a2,-1486 # ffffffffc0202000 <etext+0x140>
ffffffffc02005d6:	02700593          	li	a1,39
ffffffffc02005da:	00002517          	auipc	a0,0x2
ffffffffc02005de:	9de50513          	addi	a0,a0,-1570 # ffffffffc0201fb8 <etext+0xf8>
ffffffffc02005e2:	044000ef          	jal	ffffffffc0200626 <__panic>
    assert(all == pa2page(first_free));
ffffffffc02005e6:	00002697          	auipc	a3,0x2
ffffffffc02005ea:	c1a68693          	addi	a3,a3,-998 # ffffffffc0202200 <etext+0x340>
ffffffffc02005ee:	00002617          	auipc	a2,0x2
ffffffffc02005f2:	a1260613          	addi	a2,a2,-1518 # ffffffffc0202000 <etext+0x140>
ffffffffc02005f6:	02600593          	li	a1,38
ffffffffc02005fa:	00002517          	auipc	a0,0x2
ffffffffc02005fe:	9be50513          	addi	a0,a0,-1602 # ffffffffc0201fb8 <etext+0xf8>
ffffffffc0200602:	024000ef          	jal	ffffffffc0200626 <__panic>
    assert(alloc_pages(expected_free + 1) == NULL);
ffffffffc0200606:	00002697          	auipc	a3,0x2
ffffffffc020060a:	bd268693          	addi	a3,a3,-1070 # ffffffffc02021d8 <etext+0x318>
ffffffffc020060e:	00002617          	auipc	a2,0x2
ffffffffc0200612:	9f260613          	addi	a2,a2,-1550 # ffffffffc0202000 <etext+0x140>
ffffffffc0200616:	02400593          	li	a1,36
ffffffffc020061a:	00002517          	auipc	a0,0x2
ffffffffc020061e:	99e50513          	addi	a0,a0,-1634 # ffffffffc0201fb8 <etext+0xf8>
ffffffffc0200622:	004000ef          	jal	ffffffffc0200626 <__panic>

ffffffffc0200626 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200626:	00006317          	auipc	t1,0x6
ffffffffc020062a:	a0a32303          	lw	t1,-1526(t1) # ffffffffc0206030 <is_panic>
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc020062e:	715d                	addi	sp,sp,-80
ffffffffc0200630:	ec06                	sd	ra,24(sp)
ffffffffc0200632:	f436                	sd	a3,40(sp)
ffffffffc0200634:	f83a                	sd	a4,48(sp)
ffffffffc0200636:	fc3e                	sd	a5,56(sp)
ffffffffc0200638:	e0c2                	sd	a6,64(sp)
ffffffffc020063a:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc020063c:	00030363          	beqz	t1,ffffffffc0200642 <__panic+0x1c>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc0200640:	a001                	j	ffffffffc0200640 <__panic+0x1a>
    is_panic = 1;
ffffffffc0200642:	e822                	sd	s0,16(sp)
ffffffffc0200644:	00006797          	auipc	a5,0x6
ffffffffc0200648:	9ec78793          	addi	a5,a5,-1556 # ffffffffc0206030 <is_panic>
ffffffffc020064c:	4685                	li	a3,1
    va_start(ap, fmt);
ffffffffc020064e:	1038                	addi	a4,sp,40
ffffffffc0200650:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200652:	862e                	mv	a2,a1
ffffffffc0200654:	85aa                	mv	a1,a0
ffffffffc0200656:	00002517          	auipc	a0,0x2
ffffffffc020065a:	c8250513          	addi	a0,a0,-894 # ffffffffc02022d8 <etext+0x418>
    is_panic = 1;
ffffffffc020065e:	c394                	sw	a3,0(a5)
    va_start(ap, fmt);
ffffffffc0200660:	e43a                	sd	a4,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200662:	ae9ff0ef          	jal	ffffffffc020014a <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200666:	65a2                	ld	a1,8(sp)
ffffffffc0200668:	8522                	mv	a0,s0
ffffffffc020066a:	ac1ff0ef          	jal	ffffffffc020012a <vcprintf>
    cprintf("\n");
ffffffffc020066e:	00002517          	auipc	a0,0x2
ffffffffc0200672:	c8a50513          	addi	a0,a0,-886 # ffffffffc02022f8 <etext+0x438>
ffffffffc0200676:	ad5ff0ef          	jal	ffffffffc020014a <cprintf>
ffffffffc020067a:	6442                	ld	s0,16(sp)
ffffffffc020067c:	b7d1                	j	ffffffffc0200640 <__panic+0x1a>

ffffffffc020067e <pa2page.part.0>:
static inline struct Page *pa2page(uintptr_t pa) {
ffffffffc020067e:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0200680:	00002617          	auipc	a2,0x2
ffffffffc0200684:	a1060613          	addi	a2,a2,-1520 # ffffffffc0202090 <etext+0x1d0>
ffffffffc0200688:	06a00593          	li	a1,106
ffffffffc020068c:	00002517          	auipc	a0,0x2
ffffffffc0200690:	a2450513          	addi	a0,a0,-1500 # ffffffffc02020b0 <etext+0x1f0>
static inline struct Page *pa2page(uintptr_t pa) {
ffffffffc0200694:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0200696:	f91ff0ef          	jal	ffffffffc0200626 <__panic>

ffffffffc020069a <test_page_init>:
#include <dtb.h>
#include <test_lab2.h>

void
test_page_init(void)
{
ffffffffc020069a:	7179                	addi	sp,sp,-48
ffffffffc020069c:	f406                	sd	ra,40(sp)
ffffffffc020069e:	f022                	sd	s0,32(sp)
ffffffffc02006a0:	ec26                	sd	s1,24(sp)
    extern char end[];
    uint64_t mem_base = get_memory_base();
ffffffffc02006a2:	584000ef          	jal	ffffffffc0200c26 <get_memory_base>
ffffffffc02006a6:	842a                	mv	s0,a0
    uint64_t mem_size = get_memory_size();
    uintptr_t end_pa;

    /* 1. va_pa_offset must be set to the virtual/physical mapping offset */
    if (va_pa_offset != PHYSICAL_MEMORY_OFFSET) {
ffffffffc02006a8:	00006497          	auipc	s1,0x6
ffffffffc02006ac:	9b848493          	addi	s1,s1,-1608 # ffffffffc0206060 <va_pa_offset>
    uint64_t mem_size = get_memory_size();
ffffffffc02006b0:	580000ef          	jal	ffffffffc0200c30 <get_memory_size>
    if (va_pa_offset != PHYSICAL_MEMORY_OFFSET) {
ffffffffc02006b4:	6098                	ld	a4,0(s1)
ffffffffc02006b6:	57f5                	li	a5,-3
ffffffffc02006b8:	07fa                	slli	a5,a5,0x1e
ffffffffc02006ba:	14f71163          	bne	a4,a5,ffffffffc02007fc <test_page_init+0x162>
        cprintf("[Test 1] Page Init: FAIL (va_pa_offset)\n");
        return;
    }

    /* 2. the device tree must report a valid physical memory range */
    if (mem_base == 0 || mem_size == 0) {
ffffffffc02006be:	12040663          	beqz	s0,ffffffffc02007ea <test_page_init+0x150>
ffffffffc02006c2:	12050463          	beqz	a0,ffffffffc02007ea <test_page_init+0x150>
ffffffffc02006c6:	e84a                	sd	s2,16(sp)
    /* 3. npage must equal the page number of the reported memory end,
     *    and the upper bound must exceed the DRAM start page number */
    {
        uint64_t mem_end = mem_base + mem_size;
        size_t expect_npage = PPN(mem_end);
        if (npage != expect_npage || npage <= nbase) {
ffffffffc02006c8:	00006917          	auipc	s2,0x6
ffffffffc02006cc:	9a090913          	addi	s2,s2,-1632 # ffffffffc0206068 <npage>
ffffffffc02006d0:	00093583          	ld	a1,0(s2)
        uint64_t mem_end = mem_base + mem_size;
ffffffffc02006d4:	9522                	add	a0,a0,s0
        size_t expect_npage = PPN(mem_end);
ffffffffc02006d6:	00c55613          	srli	a2,a0,0xc
        if (npage != expect_npage || npage <= nbase) {
ffffffffc02006da:	12c59a63          	bne	a1,a2,ffffffffc020080e <test_page_init+0x174>
ffffffffc02006de:	00002417          	auipc	s0,0x2
ffffffffc02006e2:	7f243403          	ld	s0,2034(s0) # ffffffffc0202ed0 <nbase>
ffffffffc02006e6:	12b47463          	bgeu	s0,a1,ffffffffc020080e <test_page_init+0x174>
ffffffffc02006ea:	e052                	sd	s4,0(sp)
            return;
        }
    }

    /* 4. pages must be non-null, page-aligned, and located after the kernel `end` */
    if (pages == NULL) {
ffffffffc02006ec:	00006a17          	auipc	s4,0x6
ffffffffc02006f0:	984a0a13          	addi	s4,s4,-1660 # ffffffffc0206070 <pages>
ffffffffc02006f4:	000a3783          	ld	a5,0(s4)
ffffffffc02006f8:	14078963          	beqz	a5,ffffffffc020084a <test_page_init+0x1b0>
        cprintf("[Test 1] Page Init: FAIL (pages NULL)\n");
        return;
    }
    if (((uintptr_t)pages % PGSIZE) != 0) {
ffffffffc02006fc:	03479713          	slli	a4,a5,0x34
ffffffffc0200700:	12071e63          	bnez	a4,ffffffffc020083c <test_page_init+0x1a2>
        cprintf("[Test 1] Page Init: FAIL (pages not page-aligned)\n");
        return;
    }
    if ((uintptr_t)pages < (uintptr_t)ROUNDUP((uintptr_t)end, PGSIZE)) {
ffffffffc0200704:	00007717          	auipc	a4,0x7
ffffffffc0200708:	97370713          	addi	a4,a4,-1677 # ffffffffc0207077 <end+0xfff>
ffffffffc020070c:	76fd                	lui	a3,0xfffff
ffffffffc020070e:	e44e                	sd	s3,8(sp)
ffffffffc0200710:	8f75                	and	a4,a4,a3
ffffffffc0200712:	00006997          	auipc	s3,0x6
ffffffffc0200716:	96698993          	addi	s3,s3,-1690 # ffffffffc0206078 <end>
        cprintf("[Test 1] Page Init: FAIL (pages before kernel end)\n");
ffffffffc020071a:	00002517          	auipc	a0,0x2
ffffffffc020071e:	cd650513          	addi	a0,a0,-810 # ffffffffc02023f0 <etext+0x530>
    if ((uintptr_t)pages < (uintptr_t)ROUNDUP((uintptr_t)end, PGSIZE)) {
ffffffffc0200722:	0ae7ec63          	bltu	a5,a4,ffffffffc02007da <test_page_init+0x140>
        return;
    }

    /* 5. the free area must have been built: some free pages, not more than total */
    {
        size_t free_now = nr_free_pages();
ffffffffc0200726:	03a010ef          	jal	ffffffffc0201760 <nr_free_pages>
        if (free_now == 0 || free_now > (npage - nbase)) {
ffffffffc020072a:	0e050c63          	beqz	a0,ffffffffc0200822 <test_page_init+0x188>
ffffffffc020072e:	00093703          	ld	a4,0(s2)
ffffffffc0200732:	408707b3          	sub	a5,a4,s0
ffffffffc0200736:	0ea7e663          	bltu	a5,a0,ffffffffc0200822 <test_page_init+0x188>
            return;
        }
    }

    /* 6. the kernel-image tail page must not be handed to the allocator */
    end_pa = PADDR((uintptr_t)end);
ffffffffc020073a:	c0200537          	lui	a0,0xc0200
ffffffffc020073e:	14a9e563          	bltu	s3,a0,ffffffffc0200888 <test_page_init+0x1ee>
ffffffffc0200742:	609c                	ld	a5,0(s1)
ffffffffc0200744:	40f989b3          	sub	s3,s3,a5
    if (PPN(end_pa) >= npage) {
ffffffffc0200748:	00c9d993          	srli	s3,s3,0xc
ffffffffc020074c:	10e9f663          	bgeu	s3,a4,ffffffffc0200858 <test_page_init+0x1be>
    return &pages[PPN(pa) - nbase];
ffffffffc0200750:	408989b3          	sub	s3,s3,s0
ffffffffc0200754:	000a3683          	ld	a3,0(s4)
ffffffffc0200758:	00299613          	slli	a2,s3,0x2
ffffffffc020075c:	964e                	add	a2,a2,s3
ffffffffc020075e:	060e                	slli	a2,a2,0x3
        cprintf("[Test 1] Page Init: FAIL (end pa out of range)\n");
        return;
    }
    if (!PageReserved(pa2page(end_pa))) {
ffffffffc0200760:	00c685b3          	add	a1,a3,a2
ffffffffc0200764:	658c                	ld	a1,8(a1)
ffffffffc0200766:	8985                	andi	a1,a1,1
ffffffffc0200768:	0e058d63          	beqz	a1,ffffffffc0200862 <test_page_init+0x1c8>
        return;
    }

    /* 7. the pages occupied by the page-descriptor array must stay reserved too */
    {
        uintptr_t pages_pa = PADDR((uintptr_t)pages);
ffffffffc020076c:	10a6e063          	bltu	a3,a0,ffffffffc020086c <test_page_init+0x1d2>
ffffffffc0200770:	40f687b3          	sub	a5,a3,a5
        if (PPN(pages_pa) >= npage) {
ffffffffc0200774:	83b1                	srli	a5,a5,0xc
            cprintf("[Test 1] Page Init: FAIL (pages pa out of range)\n");
ffffffffc0200776:	00002517          	auipc	a0,0x2
ffffffffc020077a:	d5a50513          	addi	a0,a0,-678 # ffffffffc02024d0 <etext+0x610>
        if (PPN(pages_pa) >= npage) {
ffffffffc020077e:	04e7fe63          	bgeu	a5,a4,ffffffffc02007da <test_page_init+0x140>
ffffffffc0200782:	8f81                	sub	a5,a5,s0
            return;
        }
        if (!PageReserved(pa2page(pages_pa))) {
ffffffffc0200784:	00279593          	slli	a1,a5,0x2
ffffffffc0200788:	97ae                	add	a5,a5,a1
ffffffffc020078a:	078e                	slli	a5,a5,0x3
ffffffffc020078c:	96be                	add	a3,a3,a5
ffffffffc020078e:	669c                	ld	a5,8(a3)
            cprintf("[Test 1] Page Init: FAIL (pages array not reserved)\n");
ffffffffc0200790:	00002517          	auipc	a0,0x2
ffffffffc0200794:	d7850513          	addi	a0,a0,-648 # ffffffffc0202508 <etext+0x648>
        if (!PageReserved(pa2page(pages_pa))) {
ffffffffc0200798:	8b85                	andi	a5,a5,1
ffffffffc020079a:	c3a1                	beqz	a5,ffffffffc02007da <test_page_init+0x140>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020079c:	ccccd7b7          	lui	a5,0xccccd
ffffffffc02007a0:	ccd78793          	addi	a5,a5,-819 # ffffffffcccccccd <end+0xcac6c55>
ffffffffc02007a4:	02079693          	slli	a3,a5,0x20
ffffffffc02007a8:	96be                	add	a3,a3,a5
ffffffffc02007aa:	40365793          	srai	a5,a2,0x3
ffffffffc02007ae:	02d787b3          	mul	a5,a5,a3
ffffffffc02007b2:	97a2                	add	a5,a5,s0
    if (PPN(pa) >= npage) {
ffffffffc02007b4:	07b2                	slli	a5,a5,0xc
ffffffffc02007b6:	83b1                	srli	a5,a5,0xc
ffffffffc02007b8:	0ce7f663          	bgeu	a5,a4,ffffffffc0200884 <test_page_init+0x1ea>
    return &pages[PPN(pa) - nbase];
ffffffffc02007bc:	8f81                	sub	a5,a5,s0
ffffffffc02007be:	00279713          	slli	a4,a5,0x2
ffffffffc02007c2:	97ba                	add	a5,a5,a4
ffffffffc02007c4:	078e                	slli	a5,a5,0x3

    /* 8. page2pa / pa2page round-trip must be correct */
    {
        struct Page *q = pa2page(end_pa);
        if (pa2page(page2pa(q)) != q) {
            cprintf("[Test 1] Page Init: FAIL (roundtrip)\n");
ffffffffc02007c6:	00002517          	auipc	a0,0x2
ffffffffc02007ca:	d7a50513          	addi	a0,a0,-646 # ffffffffc0202540 <etext+0x680>
        if (pa2page(page2pa(q)) != q) {
ffffffffc02007ce:	00f61663          	bne	a2,a5,ffffffffc02007da <test_page_init+0x140>
            return;
        }
    }

    cprintf("[Test 1] Page Init: PASS\n");
ffffffffc02007d2:	00002517          	auipc	a0,0x2
ffffffffc02007d6:	d9650513          	addi	a0,a0,-618 # ffffffffc0202568 <etext+0x6a8>
ffffffffc02007da:	6942                	ld	s2,16(sp)
ffffffffc02007dc:	69a2                	ld	s3,8(sp)
ffffffffc02007de:	6a02                	ld	s4,0(sp)
}
ffffffffc02007e0:	7402                	ld	s0,32(sp)
ffffffffc02007e2:	70a2                	ld	ra,40(sp)
ffffffffc02007e4:	64e2                	ld	s1,24(sp)
ffffffffc02007e6:	6145                	addi	sp,sp,48
    cprintf("[Test 1] Page Init: PASS\n");
ffffffffc02007e8:	b28d                	j	ffffffffc020014a <cprintf>
}
ffffffffc02007ea:	7402                	ld	s0,32(sp)
ffffffffc02007ec:	70a2                	ld	ra,40(sp)
ffffffffc02007ee:	64e2                	ld	s1,24(sp)
        cprintf("[Test 1] Page Init: FAIL (dtb mem 0)\n");
ffffffffc02007f0:	00002517          	auipc	a0,0x2
ffffffffc02007f4:	b4050513          	addi	a0,a0,-1216 # ffffffffc0202330 <etext+0x470>
}
ffffffffc02007f8:	6145                	addi	sp,sp,48
    cprintf("[Test 1] Page Init: PASS\n");
ffffffffc02007fa:	ba81                	j	ffffffffc020014a <cprintf>
}
ffffffffc02007fc:	7402                	ld	s0,32(sp)
ffffffffc02007fe:	70a2                	ld	ra,40(sp)
ffffffffc0200800:	64e2                	ld	s1,24(sp)
        cprintf("[Test 1] Page Init: FAIL (va_pa_offset)\n");
ffffffffc0200802:	00002517          	auipc	a0,0x2
ffffffffc0200806:	afe50513          	addi	a0,a0,-1282 # ffffffffc0202300 <etext+0x440>
}
ffffffffc020080a:	6145                	addi	sp,sp,48
    cprintf("[Test 1] Page Init: PASS\n");
ffffffffc020080c:	ba3d                	j	ffffffffc020014a <cprintf>
}
ffffffffc020080e:	7402                	ld	s0,32(sp)
            cprintf("[Test 1] Page Init: FAIL (npage=%lu expect=%lu)\n",
ffffffffc0200810:	6942                	ld	s2,16(sp)
}
ffffffffc0200812:	70a2                	ld	ra,40(sp)
ffffffffc0200814:	64e2                	ld	s1,24(sp)
            cprintf("[Test 1] Page Init: FAIL (npage=%lu expect=%lu)\n",
ffffffffc0200816:	00002517          	auipc	a0,0x2
ffffffffc020081a:	b4250513          	addi	a0,a0,-1214 # ffffffffc0202358 <etext+0x498>
}
ffffffffc020081e:	6145                	addi	sp,sp,48
            cprintf("[Test 1] Page Init: FAIL (npage=%lu expect=%lu)\n",
ffffffffc0200820:	b22d                	j	ffffffffc020014a <cprintf>
}
ffffffffc0200822:	7402                	ld	s0,32(sp)
            cprintf("[Test 1] Page Init: FAIL (nr_free=%lu)\n",
ffffffffc0200824:	6942                	ld	s2,16(sp)
ffffffffc0200826:	69a2                	ld	s3,8(sp)
ffffffffc0200828:	6a02                	ld	s4,0(sp)
}
ffffffffc020082a:	70a2                	ld	ra,40(sp)
ffffffffc020082c:	64e2                	ld	s1,24(sp)
            cprintf("[Test 1] Page Init: FAIL (nr_free=%lu)\n",
ffffffffc020082e:	85aa                	mv	a1,a0
ffffffffc0200830:	00002517          	auipc	a0,0x2
ffffffffc0200834:	bf850513          	addi	a0,a0,-1032 # ffffffffc0202428 <etext+0x568>
}
ffffffffc0200838:	6145                	addi	sp,sp,48
            cprintf("[Test 1] Page Init: FAIL (nr_free=%lu)\n",
ffffffffc020083a:	ba01                	j	ffffffffc020014a <cprintf>
        cprintf("[Test 1] Page Init: FAIL (pages not page-aligned)\n");
ffffffffc020083c:	6942                	ld	s2,16(sp)
    cprintf("[Test 1] Page Init: PASS\n");
ffffffffc020083e:	6a02                	ld	s4,0(sp)
        cprintf("[Test 1] Page Init: FAIL (pages not page-aligned)\n");
ffffffffc0200840:	00002517          	auipc	a0,0x2
ffffffffc0200844:	b7850513          	addi	a0,a0,-1160 # ffffffffc02023b8 <etext+0x4f8>
ffffffffc0200848:	bf61                	j	ffffffffc02007e0 <test_page_init+0x146>
        cprintf("[Test 1] Page Init: FAIL (pages NULL)\n");
ffffffffc020084a:	6942                	ld	s2,16(sp)
    cprintf("[Test 1] Page Init: PASS\n");
ffffffffc020084c:	6a02                	ld	s4,0(sp)
        cprintf("[Test 1] Page Init: FAIL (pages NULL)\n");
ffffffffc020084e:	00002517          	auipc	a0,0x2
ffffffffc0200852:	b4250513          	addi	a0,a0,-1214 # ffffffffc0202390 <etext+0x4d0>
ffffffffc0200856:	b769                	j	ffffffffc02007e0 <test_page_init+0x146>
        cprintf("[Test 1] Page Init: FAIL (end pa out of range)\n");
ffffffffc0200858:	00002517          	auipc	a0,0x2
ffffffffc020085c:	c1050513          	addi	a0,a0,-1008 # ffffffffc0202468 <etext+0x5a8>
ffffffffc0200860:	bfad                	j	ffffffffc02007da <test_page_init+0x140>
        cprintf("[Test 1] Page Init: FAIL (kernel tail not reserved)\n");
ffffffffc0200862:	00002517          	auipc	a0,0x2
ffffffffc0200866:	c3650513          	addi	a0,a0,-970 # ffffffffc0202498 <etext+0x5d8>
ffffffffc020086a:	bf85                	j	ffffffffc02007da <test_page_init+0x140>
        uintptr_t pages_pa = PADDR((uintptr_t)pages);
ffffffffc020086c:	00001617          	auipc	a2,0x1
ffffffffc0200870:	72460613          	addi	a2,a2,1828 # ffffffffc0201f90 <etext+0xd0>
ffffffffc0200874:	05000593          	li	a1,80
ffffffffc0200878:	00002517          	auipc	a0,0x2
ffffffffc020087c:	bd850513          	addi	a0,a0,-1064 # ffffffffc0202450 <etext+0x590>
ffffffffc0200880:	da7ff0ef          	jal	ffffffffc0200626 <__panic>
ffffffffc0200884:	dfbff0ef          	jal	ffffffffc020067e <pa2page.part.0>
    end_pa = PADDR((uintptr_t)end);
ffffffffc0200888:	00005697          	auipc	a3,0x5
ffffffffc020088c:	7f068693          	addi	a3,a3,2032 # ffffffffc0206078 <end>
ffffffffc0200890:	00001617          	auipc	a2,0x1
ffffffffc0200894:	70060613          	addi	a2,a2,1792 # ffffffffc0201f90 <etext+0xd0>
ffffffffc0200898:	04400593          	li	a1,68
ffffffffc020089c:	00002517          	auipc	a0,0x2
ffffffffc02008a0:	bb450513          	addi	a0,a0,-1100 # ffffffffc0202450 <etext+0x590>
ffffffffc02008a4:	d83ff0ef          	jal	ffffffffc0200626 <__panic>

ffffffffc02008a8 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc02008a8:	8082                	ret

ffffffffc02008aa <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc02008aa:	0ff57513          	zext.b	a0,a0
ffffffffc02008ae:	5500106f          	j	ffffffffc0201dfe <sbi_console_putchar>

ffffffffc02008b2 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02008b2:	711d                	addi	sp,sp,-96
    cprintf("DTB Init\n");
ffffffffc02008b4:	00002517          	auipc	a0,0x2
ffffffffc02008b8:	cd450513          	addi	a0,a0,-812 # ffffffffc0202588 <etext+0x6c8>
void dtb_init(void) {
ffffffffc02008bc:	ec86                	sd	ra,88(sp)
ffffffffc02008be:	e8a2                	sd	s0,80(sp)
    cprintf("DTB Init\n");
ffffffffc02008c0:	88bff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02008c4:	00005597          	auipc	a1,0x5
ffffffffc02008c8:	73c5b583          	ld	a1,1852(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc02008cc:	00002517          	auipc	a0,0x2
ffffffffc02008d0:	ccc50513          	addi	a0,a0,-820 # ffffffffc0202598 <etext+0x6d8>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02008d4:	00005417          	auipc	s0,0x5
ffffffffc02008d8:	73440413          	addi	s0,s0,1844 # ffffffffc0206008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02008dc:	86fff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02008e0:	600c                	ld	a1,0(s0)
ffffffffc02008e2:	00002517          	auipc	a0,0x2
ffffffffc02008e6:	cc650513          	addi	a0,a0,-826 # ffffffffc02025a8 <etext+0x6e8>
ffffffffc02008ea:	861ff0ef          	jal	ffffffffc020014a <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02008ee:	601c                	ld	a5,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02008f0:	00002517          	auipc	a0,0x2
ffffffffc02008f4:	cd050513          	addi	a0,a0,-816 # ffffffffc02025c0 <etext+0x700>
    if (boot_dtb == 0) {
ffffffffc02008f8:	12078463          	beqz	a5,ffffffffc0200a20 <dtb_init+0x16e>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc02008fc:	5775                	li	a4,-3
ffffffffc02008fe:	077a                	slli	a4,a4,0x1e
ffffffffc0200900:	97ba                	add	a5,a5,a4
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200902:	4398                	lw	a4,0(a5)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200904:	f456                	sd	s5,40(sp)
ffffffffc0200906:	00ff0ab7          	lui	s5,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020090a:	0107569b          	srliw	a3,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020090e:	0087559b          	srliw	a1,a4,0x8
ffffffffc0200912:	0187151b          	slliw	a0,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200916:	0086969b          	slliw	a3,a3,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020091a:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020091e:	0187571b          	srliw	a4,a4,0x18
ffffffffc0200922:	8f49                	or	a4,a4,a0
ffffffffc0200924:	16c2                	slli	a3,a3,0x30
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200926:	0155f5b3          	and	a1,a1,s5
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020092a:	8dd9                	or	a1,a1,a4
    if (magic != 0xd00dfeed) {
ffffffffc020092c:	d00e0637          	lui	a2,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200930:	92c1                	srli	a3,a3,0x30
ffffffffc0200932:	8dd5                	or	a1,a1,a3
    if (magic != 0xd00dfeed) {
ffffffffc0200934:	eed60713          	addi	a4,a2,-275 # ffffffffd00dfeed <end+0xfed9e75>
ffffffffc0200938:	0ee59963          	bne	a1,a4,ffffffffc0200a2a <dtb_init+0x178>
ffffffffc020093c:	4794                	lw	a3,8(a5)
ffffffffc020093e:	47d8                	lw	a4,12(a5)
ffffffffc0200940:	e4a6                	sd	s1,72(sp)
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200942:	0106d59b          	srliw	a1,a3,0x10
ffffffffc0200946:	0107561b          	srliw	a2,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020094a:	0086d41b          	srliw	s0,a3,0x8
ffffffffc020094e:	0087549b          	srliw	s1,a4,0x8
ffffffffc0200952:	0186981b          	slliw	a6,a3,0x18
ffffffffc0200956:	0187151b          	slliw	a0,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020095a:	0085959b          	slliw	a1,a1,0x8
ffffffffc020095e:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200962:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200966:	0186d69b          	srliw	a3,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020096a:	0104949b          	slliw	s1,s1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020096e:	0187571b          	srliw	a4,a4,0x18
ffffffffc0200972:	15c2                	slli	a1,a1,0x30
ffffffffc0200974:	1642                	slli	a2,a2,0x30
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200976:	01547433          	and	s0,s0,s5
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020097a:	00d866b3          	or	a3,a6,a3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020097e:	0154f4b3          	and	s1,s1,s5
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200982:	8f49                	or	a4,a4,a0
ffffffffc0200984:	91c1                	srli	a1,a1,0x30
ffffffffc0200986:	9241                	srli	a2,a2,0x30
ffffffffc0200988:	8c55                	or	s0,s0,a3
ffffffffc020098a:	8cd9                	or	s1,s1,a4
ffffffffc020098c:	8c4d                	or	s0,s0,a1
ffffffffc020098e:	8cd1                	or	s1,s1,a2
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200990:	1402                	slli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200992:	1482                	slli	s1,s1,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200994:	9001                	srli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200996:	9081                	srli	s1,s1,0x20
ffffffffc0200998:	e0ca                	sd	s2,64(sp)
ffffffffc020099a:	fc4e                	sd	s3,56(sp)
ffffffffc020099c:	f05a                	sd	s6,32(sp)
ffffffffc020099e:	ec5e                	sd	s7,24(sp)
ffffffffc02009a0:	e862                	sd	s8,16(sp)
ffffffffc02009a2:	f852                	sd	s4,48(sp)
ffffffffc02009a4:	e466                	sd	s9,8(sp)
    int in_memory_node = 0;
ffffffffc02009a6:	4b81                	li	s7,0
        switch (token) {
ffffffffc02009a8:	4b0d                	li	s6,3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02009aa:	943e                	add	s0,s0,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02009ac:	94be                	add	s1,s1,a5
        switch (token) {
ffffffffc02009ae:	4991                	li	s3,4
ffffffffc02009b0:	4c05                	li	s8,1
ffffffffc02009b2:	4909                	li	s2,2
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02009b4:	4018                	lw	a4,0(s0)
ffffffffc02009b6:	00440a13          	addi	s4,s0,4
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02009ba:	0107569b          	srliw	a3,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02009be:	0087579b          	srliw	a5,a4,0x8
ffffffffc02009c2:	0187161b          	slliw	a2,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02009c6:	0086969b          	slliw	a3,a3,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02009ca:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02009ce:	0187571b          	srliw	a4,a4,0x18
ffffffffc02009d2:	16c2                	slli	a3,a3,0x30
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02009d4:	0157f7b3          	and	a5,a5,s5
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02009d8:	8f51                	or	a4,a4,a2
ffffffffc02009da:	92c1                	srli	a3,a3,0x30
ffffffffc02009dc:	8fd9                	or	a5,a5,a4
ffffffffc02009de:	8fd5                	or	a5,a5,a3
        switch (token) {
ffffffffc02009e0:	09678963          	beq	a5,s6,ffffffffc0200a72 <dtb_init+0x1c0>
ffffffffc02009e4:	00fb6963          	bltu	s6,a5,ffffffffc02009f6 <dtb_init+0x144>
ffffffffc02009e8:	05878b63          	beq	a5,s8,ffffffffc0200a3e <dtb_init+0x18c>
ffffffffc02009ec:	01279763          	bne	a5,s2,ffffffffc02009fa <dtb_init+0x148>
ffffffffc02009f0:	4b81                	li	s7,0
ffffffffc02009f2:	8452                	mv	s0,s4
ffffffffc02009f4:	b7c1                	j	ffffffffc02009b4 <dtb_init+0x102>
ffffffffc02009f6:	ff378ee3          	beq	a5,s3,ffffffffc02009f2 <dtb_init+0x140>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02009fa:	00002517          	auipc	a0,0x2
ffffffffc02009fe:	c8e50513          	addi	a0,a0,-882 # ffffffffc0202688 <etext+0x7c8>
ffffffffc0200a02:	f48ff0ef          	jal	ffffffffc020014a <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200a06:	64a6                	ld	s1,72(sp)
ffffffffc0200a08:	6906                	ld	s2,64(sp)
ffffffffc0200a0a:	79e2                	ld	s3,56(sp)
ffffffffc0200a0c:	7a42                	ld	s4,48(sp)
ffffffffc0200a0e:	7aa2                	ld	s5,40(sp)
ffffffffc0200a10:	7b02                	ld	s6,32(sp)
ffffffffc0200a12:	6be2                	ld	s7,24(sp)
ffffffffc0200a14:	6c42                	ld	s8,16(sp)
ffffffffc0200a16:	6ca2                	ld	s9,8(sp)
ffffffffc0200a18:	00002517          	auipc	a0,0x2
ffffffffc0200a1c:	ca850513          	addi	a0,a0,-856 # ffffffffc02026c0 <etext+0x800>
}
ffffffffc0200a20:	6446                	ld	s0,80(sp)
ffffffffc0200a22:	60e6                	ld	ra,88(sp)
ffffffffc0200a24:	6125                	addi	sp,sp,96
    cprintf("DTB init completed\n");
ffffffffc0200a26:	f24ff06f          	j	ffffffffc020014a <cprintf>
}
ffffffffc0200a2a:	6446                	ld	s0,80(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200a2c:	7aa2                	ld	s5,40(sp)
}
ffffffffc0200a2e:	60e6                	ld	ra,88(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200a30:	00002517          	auipc	a0,0x2
ffffffffc0200a34:	bb050513          	addi	a0,a0,-1104 # ffffffffc02025e0 <etext+0x720>
}
ffffffffc0200a38:	6125                	addi	sp,sp,96
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200a3a:	f10ff06f          	j	ffffffffc020014a <cprintf>
                int name_len = strlen(name);
ffffffffc0200a3e:	8552                	mv	a0,s4
ffffffffc0200a40:	3d8010ef          	jal	ffffffffc0201e18 <strlen>
ffffffffc0200a44:	8caa                	mv	s9,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200a46:	4619                	li	a2,6
ffffffffc0200a48:	8552                	mv	a0,s4
ffffffffc0200a4a:	00002597          	auipc	a1,0x2
ffffffffc0200a4e:	bbe58593          	addi	a1,a1,-1090 # ffffffffc0202608 <etext+0x748>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200a52:	00840a13          	addi	s4,s0,8
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200a56:	430010ef          	jal	ffffffffc0201e86 <strncmp>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200a5a:	2c81                	sext.w	s9,s9
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200a5c:	00153513          	seqz	a0,a0
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200a60:	9a66                	add	s4,s4,s9
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200a62:	00abe533          	or	a0,s7,a0
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200a66:	ffca7a13          	andi	s4,s4,-4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200a6a:	00050b9b          	sext.w	s7,a0
        switch (token) {
ffffffffc0200a6e:	8452                	mv	s0,s4
ffffffffc0200a70:	b791                	j	ffffffffc02009b4 <dtb_init+0x102>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200a72:	405c                	lw	a5,4(s0)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200a74:	00c40a13          	addi	s4,s0,12
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200a78:	0107d71b          	srliw	a4,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200a7c:	0087d69b          	srliw	a3,a5,0x8
ffffffffc0200a80:	01879c9b          	slliw	s9,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200a84:	0087171b          	slliw	a4,a4,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200a88:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200a8c:	0187d79b          	srliw	a5,a5,0x18
ffffffffc0200a90:	1742                	slli	a4,a4,0x30
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200a92:	0156f6b3          	and	a3,a3,s5
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200a96:	00fcecb3          	or	s9,s9,a5
ffffffffc0200a9a:	9341                	srli	a4,a4,0x30
ffffffffc0200a9c:	00dcecb3          	or	s9,s9,a3
ffffffffc0200aa0:	00ececb3          	or	s9,s9,a4
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200aa4:	000b9b63          	bnez	s7,ffffffffc0200aba <dtb_init+0x208>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200aa8:	1c82                	slli	s9,s9,0x20
ffffffffc0200aaa:	020cdc93          	srli	s9,s9,0x20
ffffffffc0200aae:	0a0d                	addi	s4,s4,3
ffffffffc0200ab0:	9a66                	add	s4,s4,s9
ffffffffc0200ab2:	ffca7a13          	andi	s4,s4,-4
        switch (token) {
ffffffffc0200ab6:	8452                	mv	s0,s4
ffffffffc0200ab8:	bdf5                	j	ffffffffc02009b4 <dtb_init+0x102>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200aba:	441c                	lw	a5,8(s0)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200abc:	00002597          	auipc	a1,0x2
ffffffffc0200ac0:	b5458593          	addi	a1,a1,-1196 # ffffffffc0202610 <etext+0x750>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200ac4:	0087d69b          	srliw	a3,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200ac8:	0107d71b          	srliw	a4,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200acc:	0187951b          	slliw	a0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200ad0:	0087171b          	slliw	a4,a4,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200ad4:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200ad8:	0187d79b          	srliw	a5,a5,0x18
ffffffffc0200adc:	1742                	slli	a4,a4,0x30
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200ade:	0156f6b3          	and	a3,a3,s5
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200ae2:	8d5d                	or	a0,a0,a5
ffffffffc0200ae4:	9341                	srli	a4,a4,0x30
ffffffffc0200ae6:	8d55                	or	a0,a0,a3
ffffffffc0200ae8:	8d59                	or	a0,a0,a4
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200aea:	1502                	slli	a0,a0,0x20
ffffffffc0200aec:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200aee:	9526                	add	a0,a0,s1
ffffffffc0200af0:	35e010ef          	jal	ffffffffc0201e4e <strcmp>
ffffffffc0200af4:	f955                	bnez	a0,ffffffffc0200aa8 <dtb_init+0x1f6>
ffffffffc0200af6:	47bd                	li	a5,15
ffffffffc0200af8:	fb97f8e3          	bgeu	a5,s9,ffffffffc0200aa8 <dtb_init+0x1f6>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200afc:	00c43703          	ld	a4,12(s0)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200b00:	01443783          	ld	a5,20(s0)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200b04:	00002517          	auipc	a0,0x2
ffffffffc0200b08:	b1450513          	addi	a0,a0,-1260 # ffffffffc0202618 <etext+0x758>
           fdt32_to_cpu(x >> 32);
ffffffffc0200b0c:	42075813          	srai	a6,a4,0x20
ffffffffc0200b10:	4207d593          	srai	a1,a5,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200b14:	01085e9b          	srliw	t4,a6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200b18:	02875613          	srli	a2,a4,0x28
ffffffffc0200b1c:	0287d693          	srli	a3,a5,0x28
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200b20:	00070e1b          	sext.w	t3,a4
ffffffffc0200b24:	0007889b          	sext.w	a7,a5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200b28:	01859f9b          	slliw	t6,a1,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200b2c:	0105d31b          	srliw	t1,a1,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200b30:	0188139b          	slliw	t2,a6,0x18
ffffffffc0200b34:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200b38:	0188581b          	srliw	a6,a6,0x18
ffffffffc0200b3c:	0185df1b          	srliw	t5,a1,0x18
ffffffffc0200b40:	008e9e9b          	slliw	t4,t4,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200b44:	0106161b          	slliw	a2,a2,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200b48:	010e529b          	srliw	t0,t3,0x10
ffffffffc0200b4c:	0103e3b3          	or	t2,t2,a6
ffffffffc0200b50:	01efef33          	or	t5,t6,t5
ffffffffc0200b54:	0108d59b          	srliw	a1,a7,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200b58:	01567633          	and	a2,a2,s5
ffffffffc0200b5c:	0087549b          	srliw	s1,a4,0x8
ffffffffc0200b60:	0087d41b          	srliw	s0,a5,0x8
ffffffffc0200b64:	0156f733          	and	a4,a3,s5
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200b68:	0083131b          	slliw	t1,t1,0x8
ffffffffc0200b6c:	1ec2                	slli	t4,t4,0x30
ffffffffc0200b6e:	007666b3          	or	a3,a2,t2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200b72:	018e1f9b          	slliw	t6,t3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200b76:	030ede93          	srli	t4,t4,0x30
ffffffffc0200b7a:	0082981b          	slliw	a6,t0,0x8
ffffffffc0200b7e:	018e5e1b          	srliw	t3,t3,0x18
ffffffffc0200b82:	01e767b3          	or	a5,a4,t5
ffffffffc0200b86:	0085959b          	slliw	a1,a1,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200b8a:	01889f1b          	slliw	t5,a7,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200b8e:	1342                	slli	t1,t1,0x30
ffffffffc0200b90:	0188d89b          	srliw	a7,a7,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200b94:	0104949b          	slliw	s1,s1,0x10
ffffffffc0200b98:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200b9c:	01d6e733          	or	a4,a3,t4
ffffffffc0200ba0:	03035313          	srli	t1,t1,0x30
ffffffffc0200ba4:	011f66b3          	or	a3,t5,a7
ffffffffc0200ba8:	03059613          	slli	a2,a1,0x30
ffffffffc0200bac:	1842                	slli	a6,a6,0x30
ffffffffc0200bae:	01cfe5b3          	or	a1,t6,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200bb2:	0154f4b3          	and	s1,s1,s5
ffffffffc0200bb6:	01547433          	and	s0,s0,s5
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200bba:	03085813          	srli	a6,a6,0x30
ffffffffc0200bbe:	0067e7b3          	or	a5,a5,t1
ffffffffc0200bc2:	8c55                	or	s0,s0,a3
ffffffffc0200bc4:	9241                	srli	a2,a2,0x30
ffffffffc0200bc6:	8ccd                	or	s1,s1,a1
ffffffffc0200bc8:	0104e4b3          	or	s1,s1,a6
ffffffffc0200bcc:	8c51                	or	s0,s0,a2
           fdt32_to_cpu(x >> 32);
ffffffffc0200bce:	1702                	slli	a4,a4,0x20
ffffffffc0200bd0:	1782                	slli	a5,a5,0x20
ffffffffc0200bd2:	9381                	srli	a5,a5,0x20
ffffffffc0200bd4:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200bd6:	1482                	slli	s1,s1,0x20
ffffffffc0200bd8:	1402                	slli	s0,s0,0x20
ffffffffc0200bda:	8c5d                	or	s0,s0,a5
ffffffffc0200bdc:	8cd9                	or	s1,s1,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200bde:	d6cff0ef          	jal	ffffffffc020014a <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200be2:	85a6                	mv	a1,s1
ffffffffc0200be4:	00002517          	auipc	a0,0x2
ffffffffc0200be8:	a5450513          	addi	a0,a0,-1452 # ffffffffc0202638 <etext+0x778>
ffffffffc0200bec:	d5eff0ef          	jal	ffffffffc020014a <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200bf0:	01445613          	srli	a2,s0,0x14
ffffffffc0200bf4:	85a2                	mv	a1,s0
ffffffffc0200bf6:	00002517          	auipc	a0,0x2
ffffffffc0200bfa:	a5a50513          	addi	a0,a0,-1446 # ffffffffc0202650 <etext+0x790>
ffffffffc0200bfe:	d4cff0ef          	jal	ffffffffc020014a <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200c02:	009405b3          	add	a1,s0,s1
ffffffffc0200c06:	15fd                	addi	a1,a1,-1
ffffffffc0200c08:	00002517          	auipc	a0,0x2
ffffffffc0200c0c:	a6850513          	addi	a0,a0,-1432 # ffffffffc0202670 <etext+0x7b0>
ffffffffc0200c10:	d3aff0ef          	jal	ffffffffc020014a <cprintf>
        memory_base = mem_base;
ffffffffc0200c14:	00005797          	auipc	a5,0x5
ffffffffc0200c18:	4297b623          	sd	s1,1068(a5) # ffffffffc0206040 <memory_base>
        memory_size = mem_size;
ffffffffc0200c1c:	00005797          	auipc	a5,0x5
ffffffffc0200c20:	4087be23          	sd	s0,1052(a5) # ffffffffc0206038 <memory_size>
ffffffffc0200c24:	b3cd                	j	ffffffffc0200a06 <dtb_init+0x154>

ffffffffc0200c26 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200c26:	00005517          	auipc	a0,0x5
ffffffffc0200c2a:	41a53503          	ld	a0,1050(a0) # ffffffffc0206040 <memory_base>
ffffffffc0200c2e:	8082                	ret

ffffffffc0200c30 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc0200c30:	00005517          	auipc	a0,0x5
ffffffffc0200c34:	40853503          	ld	a0,1032(a0) # ffffffffc0206038 <memory_size>
ffffffffc0200c38:	8082                	ret

ffffffffc0200c3a <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200c3a:	00005797          	auipc	a5,0x5
ffffffffc0200c3e:	3de78793          	addi	a5,a5,990 # ffffffffc0206018 <free_area>
ffffffffc0200c42:	e79c                	sd	a5,8(a5)
ffffffffc0200c44:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200c46:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200c4a:	8082                	ret

ffffffffc0200c4c <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200c4c:	00005517          	auipc	a0,0x5
ffffffffc0200c50:	3dc56503          	lwu	a0,988(a0) # ffffffffc0206028 <free_area+0x10>
ffffffffc0200c54:	8082                	ret

ffffffffc0200c56 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0200c56:	cd49                	beqz	a0,ffffffffc0200cf0 <default_alloc_pages+0x9a>
    if (n > nr_free) {
ffffffffc0200c58:	00005597          	auipc	a1,0x5
ffffffffc0200c5c:	3d05a583          	lw	a1,976(a1) # ffffffffc0206028 <free_area+0x10>
ffffffffc0200c60:	86aa                	mv	a3,a0
ffffffffc0200c62:	00005617          	auipc	a2,0x5
ffffffffc0200c66:	3b660613          	addi	a2,a2,950 # ffffffffc0206018 <free_area>
ffffffffc0200c6a:	02059793          	slli	a5,a1,0x20
ffffffffc0200c6e:	9381                	srli	a5,a5,0x20
ffffffffc0200c70:	00a7eb63          	bltu	a5,a0,ffffffffc0200c86 <default_alloc_pages+0x30>
    list_entry_t *le = &free_list;
ffffffffc0200c74:	87b2                	mv	a5,a2
ffffffffc0200c76:	a029                	j	ffffffffc0200c80 <default_alloc_pages+0x2a>
        if (p->property >= n) {
ffffffffc0200c78:	ff87e703          	lwu	a4,-8(a5)
ffffffffc0200c7c:	00d77763          	bgeu	a4,a3,ffffffffc0200c8a <default_alloc_pages+0x34>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200c80:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200c82:	fec79be3          	bne	a5,a2,ffffffffc0200c78 <default_alloc_pages+0x22>
        return NULL;
ffffffffc0200c86:	4501                	li	a0,0
}
ffffffffc0200c88:	8082                	ret
        if (page->property > n) {
ffffffffc0200c8a:	ff87a303          	lw	t1,-8(a5)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0200c8e:	0007b803          	ld	a6,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200c92:	0087b883          	ld	a7,8(a5)
ffffffffc0200c96:	02031713          	slli	a4,t1,0x20
ffffffffc0200c9a:	9301                	srli	a4,a4,0x20
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200c9c:	01183423          	sd	a7,8(a6)
    next->prev = prev;
ffffffffc0200ca0:	0108b023          	sd	a6,0(a7)
        struct Page *p = le2page(le, page_link);
ffffffffc0200ca4:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc0200ca8:	00068e1b          	sext.w	t3,a3
        if (page->property > n) {
ffffffffc0200cac:	02e6f963          	bgeu	a3,a4,ffffffffc0200cde <default_alloc_pages+0x88>
            struct Page *p = page + n;
ffffffffc0200cb0:	00269713          	slli	a4,a3,0x2
ffffffffc0200cb4:	9736                	add	a4,a4,a3
ffffffffc0200cb6:	070e                	slli	a4,a4,0x3
ffffffffc0200cb8:	972a                	add	a4,a4,a0
            SetPageProperty(p);
ffffffffc0200cba:	6714                	ld	a3,8(a4)
            p->property = page->property - n;
ffffffffc0200cbc:	41c3033b          	subw	t1,t1,t3
ffffffffc0200cc0:	00672823          	sw	t1,16(a4)
            SetPageProperty(p);
ffffffffc0200cc4:	0026e693          	ori	a3,a3,2
ffffffffc0200cc8:	e714                	sd	a3,8(a4)
            list_add(prev, &(p->page_link));
ffffffffc0200cca:	01870693          	addi	a3,a4,24
    prev->next = next->prev = elm;
ffffffffc0200cce:	00d8b023          	sd	a3,0(a7)
ffffffffc0200cd2:	00d83423          	sd	a3,8(a6)
    elm->next = next;
ffffffffc0200cd6:	03173023          	sd	a7,32(a4)
    elm->prev = prev;
ffffffffc0200cda:	01073c23          	sd	a6,24(a4)
        ClearPageProperty(page);
ffffffffc0200cde:	ff07b703          	ld	a4,-16(a5)
        nr_free -= n;
ffffffffc0200ce2:	41c585bb          	subw	a1,a1,t3
ffffffffc0200ce6:	ca0c                	sw	a1,16(a2)
        ClearPageProperty(page);
ffffffffc0200ce8:	9b75                	andi	a4,a4,-3
ffffffffc0200cea:	fee7b823          	sd	a4,-16(a5)
ffffffffc0200cee:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0200cf0:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200cf2:	00002697          	auipc	a3,0x2
ffffffffc0200cf6:	9e668693          	addi	a3,a3,-1562 # ffffffffc02026d8 <etext+0x818>
ffffffffc0200cfa:	00001617          	auipc	a2,0x1
ffffffffc0200cfe:	30660613          	addi	a2,a2,774 # ffffffffc0202000 <etext+0x140>
ffffffffc0200d02:	02f00593          	li	a1,47
ffffffffc0200d06:	00002517          	auipc	a0,0x2
ffffffffc0200d0a:	9da50513          	addi	a0,a0,-1574 # ffffffffc02026e0 <etext+0x820>
default_alloc_pages(size_t n) {
ffffffffc0200d0e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200d10:	917ff0ef          	jal	ffffffffc0200626 <__panic>

ffffffffc0200d14 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200d14:	711d                	addi	sp,sp,-96
ffffffffc0200d16:	e0ca                	sd	s2,64(sp)
    return listelm->next;
ffffffffc0200d18:	00005917          	auipc	s2,0x5
ffffffffc0200d1c:	30090913          	addi	s2,s2,768 # ffffffffc0206018 <free_area>
ffffffffc0200d20:	00893783          	ld	a5,8(s2)
ffffffffc0200d24:	ec86                	sd	ra,88(sp)
ffffffffc0200d26:	e8a2                	sd	s0,80(sp)
ffffffffc0200d28:	e4a6                	sd	s1,72(sp)
ffffffffc0200d2a:	fc4e                	sd	s3,56(sp)
ffffffffc0200d2c:	f852                	sd	s4,48(sp)
ffffffffc0200d2e:	f456                	sd	s5,40(sp)
ffffffffc0200d30:	f05a                	sd	s6,32(sp)
ffffffffc0200d32:	ec5e                	sd	s7,24(sp)
ffffffffc0200d34:	e862                	sd	s8,16(sp)
ffffffffc0200d36:	e466                	sd	s9,8(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d38:	2f278963          	beq	a5,s2,ffffffffc020102a <default_check+0x316>
    int count = 0, total = 0;
ffffffffc0200d3c:	4401                	li	s0,0
ffffffffc0200d3e:	4481                	li	s1,0
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200d40:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200d44:	8b09                	andi	a4,a4,2
ffffffffc0200d46:	2e070663          	beqz	a4,ffffffffc0201032 <default_check+0x31e>
        count ++, total += p->property;
ffffffffc0200d4a:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200d4e:	679c                	ld	a5,8(a5)
ffffffffc0200d50:	2485                	addiw	s1,s1,1
ffffffffc0200d52:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d54:	ff2796e3          	bne	a5,s2,ffffffffc0200d40 <default_check+0x2c>
    }
    assert(total == nr_free_pages());
ffffffffc0200d58:	89a2                	mv	s3,s0
ffffffffc0200d5a:	207000ef          	jal	ffffffffc0201760 <nr_free_pages>
ffffffffc0200d5e:	73351a63          	bne	a0,s3,ffffffffc0201492 <default_check+0x77e>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d62:	4505                	li	a0,1
ffffffffc0200d64:	1e5000ef          	jal	ffffffffc0201748 <alloc_pages>
ffffffffc0200d68:	8a2a                	mv	s4,a0
ffffffffc0200d6a:	46050463          	beqz	a0,ffffffffc02011d2 <default_check+0x4be>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d6e:	4505                	li	a0,1
ffffffffc0200d70:	1d9000ef          	jal	ffffffffc0201748 <alloc_pages>
ffffffffc0200d74:	89aa                	mv	s3,a0
ffffffffc0200d76:	72050e63          	beqz	a0,ffffffffc02014b2 <default_check+0x79e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200d7a:	4505                	li	a0,1
ffffffffc0200d7c:	1cd000ef          	jal	ffffffffc0201748 <alloc_pages>
ffffffffc0200d80:	8aaa                	mv	s5,a0
ffffffffc0200d82:	4c050863          	beqz	a0,ffffffffc0201252 <default_check+0x53e>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200d86:	2d3a0663          	beq	s4,s3,ffffffffc0201052 <default_check+0x33e>
ffffffffc0200d8a:	2caa0463          	beq	s4,a0,ffffffffc0201052 <default_check+0x33e>
ffffffffc0200d8e:	2ca98263          	beq	s3,a0,ffffffffc0201052 <default_check+0x33e>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200d92:	000a2783          	lw	a5,0(s4)
ffffffffc0200d96:	2c079e63          	bnez	a5,ffffffffc0201072 <default_check+0x35e>
ffffffffc0200d9a:	0009a783          	lw	a5,0(s3)
ffffffffc0200d9e:	2c079a63          	bnez	a5,ffffffffc0201072 <default_check+0x35e>
ffffffffc0200da2:	411c                	lw	a5,0(a0)
ffffffffc0200da4:	2c079763          	bnez	a5,ffffffffc0201072 <default_check+0x35e>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200da8:	00005797          	auipc	a5,0x5
ffffffffc0200dac:	2c87b783          	ld	a5,712(a5) # ffffffffc0206070 <pages>
ffffffffc0200db0:	ccccd6b7          	lui	a3,0xccccd
ffffffffc0200db4:	ccd68693          	addi	a3,a3,-819 # ffffffffcccccccd <end+0xcac6c55>
ffffffffc0200db8:	02069613          	slli	a2,a3,0x20
ffffffffc0200dbc:	40fa0733          	sub	a4,s4,a5
ffffffffc0200dc0:	9636                	add	a2,a2,a3
ffffffffc0200dc2:	870d                	srai	a4,a4,0x3
ffffffffc0200dc4:	02c70733          	mul	a4,a4,a2
ffffffffc0200dc8:	00002597          	auipc	a1,0x2
ffffffffc0200dcc:	1085b583          	ld	a1,264(a1) # ffffffffc0202ed0 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200dd0:	00005697          	auipc	a3,0x5
ffffffffc0200dd4:	2986b683          	ld	a3,664(a3) # ffffffffc0206068 <npage>
ffffffffc0200dd8:	06b2                	slli	a3,a3,0xc
ffffffffc0200dda:	972e                	add	a4,a4,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ddc:	0732                	slli	a4,a4,0xc
ffffffffc0200dde:	2ad77a63          	bgeu	a4,a3,ffffffffc0201092 <default_check+0x37e>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200de2:	40f98733          	sub	a4,s3,a5
ffffffffc0200de6:	870d                	srai	a4,a4,0x3
ffffffffc0200de8:	02c70733          	mul	a4,a4,a2
ffffffffc0200dec:	972e                	add	a4,a4,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200dee:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200df0:	4ed77163          	bgeu	a4,a3,ffffffffc02012d2 <default_check+0x5be>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200df4:	40f507b3          	sub	a5,a0,a5
ffffffffc0200df8:	878d                	srai	a5,a5,0x3
ffffffffc0200dfa:	02c787b3          	mul	a5,a5,a2
ffffffffc0200dfe:	97ae                	add	a5,a5,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e00:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200e02:	32d7f863          	bgeu	a5,a3,ffffffffc0201132 <default_check+0x41e>
    assert(alloc_page() == NULL);
ffffffffc0200e06:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200e08:	00093c03          	ld	s8,0(s2)
ffffffffc0200e0c:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0200e10:	00005b17          	auipc	s6,0x5
ffffffffc0200e14:	218b2b03          	lw	s6,536(s6) # ffffffffc0206028 <free_area+0x10>
    elm->prev = elm->next = elm;
ffffffffc0200e18:	01293023          	sd	s2,0(s2)
ffffffffc0200e1c:	01293423          	sd	s2,8(s2)
    nr_free = 0;
ffffffffc0200e20:	00005797          	auipc	a5,0x5
ffffffffc0200e24:	2007a423          	sw	zero,520(a5) # ffffffffc0206028 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200e28:	121000ef          	jal	ffffffffc0201748 <alloc_pages>
ffffffffc0200e2c:	2e051363          	bnez	a0,ffffffffc0201112 <default_check+0x3fe>
    free_page(p0);
ffffffffc0200e30:	8552                	mv	a0,s4
ffffffffc0200e32:	4585                	li	a1,1
ffffffffc0200e34:	121000ef          	jal	ffffffffc0201754 <free_pages>
    free_page(p1);
ffffffffc0200e38:	854e                	mv	a0,s3
ffffffffc0200e3a:	4585                	li	a1,1
ffffffffc0200e3c:	119000ef          	jal	ffffffffc0201754 <free_pages>
    free_page(p2);
ffffffffc0200e40:	8556                	mv	a0,s5
ffffffffc0200e42:	4585                	li	a1,1
ffffffffc0200e44:	111000ef          	jal	ffffffffc0201754 <free_pages>
    assert(nr_free == 3);
ffffffffc0200e48:	00005717          	auipc	a4,0x5
ffffffffc0200e4c:	1e072703          	lw	a4,480(a4) # ffffffffc0206028 <free_area+0x10>
ffffffffc0200e50:	478d                	li	a5,3
ffffffffc0200e52:	2af71063          	bne	a4,a5,ffffffffc02010f2 <default_check+0x3de>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200e56:	4505                	li	a0,1
ffffffffc0200e58:	0f1000ef          	jal	ffffffffc0201748 <alloc_pages>
ffffffffc0200e5c:	89aa                	mv	s3,a0
ffffffffc0200e5e:	26050a63          	beqz	a0,ffffffffc02010d2 <default_check+0x3be>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200e62:	4505                	li	a0,1
ffffffffc0200e64:	0e5000ef          	jal	ffffffffc0201748 <alloc_pages>
ffffffffc0200e68:	8aaa                	mv	s5,a0
ffffffffc0200e6a:	3c050463          	beqz	a0,ffffffffc0201232 <default_check+0x51e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200e6e:	4505                	li	a0,1
ffffffffc0200e70:	0d9000ef          	jal	ffffffffc0201748 <alloc_pages>
ffffffffc0200e74:	8a2a                	mv	s4,a0
ffffffffc0200e76:	38050e63          	beqz	a0,ffffffffc0201212 <default_check+0x4fe>
    assert(alloc_page() == NULL);
ffffffffc0200e7a:	4505                	li	a0,1
ffffffffc0200e7c:	0cd000ef          	jal	ffffffffc0201748 <alloc_pages>
ffffffffc0200e80:	36051963          	bnez	a0,ffffffffc02011f2 <default_check+0x4de>
    free_page(p0);
ffffffffc0200e84:	4585                	li	a1,1
ffffffffc0200e86:	854e                	mv	a0,s3
ffffffffc0200e88:	0cd000ef          	jal	ffffffffc0201754 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200e8c:	00893783          	ld	a5,8(s2)
ffffffffc0200e90:	23278163          	beq	a5,s2,ffffffffc02010b2 <default_check+0x39e>
    assert((p = alloc_page()) == p0);
ffffffffc0200e94:	4505                	li	a0,1
ffffffffc0200e96:	0b3000ef          	jal	ffffffffc0201748 <alloc_pages>
ffffffffc0200e9a:	30a99c63          	bne	s3,a0,ffffffffc02011b2 <default_check+0x49e>
    assert(alloc_page() == NULL);
ffffffffc0200e9e:	4505                	li	a0,1
ffffffffc0200ea0:	0a9000ef          	jal	ffffffffc0201748 <alloc_pages>
ffffffffc0200ea4:	2e051763          	bnez	a0,ffffffffc0201192 <default_check+0x47e>
    assert(nr_free == 0);
ffffffffc0200ea8:	00005797          	auipc	a5,0x5
ffffffffc0200eac:	1807a783          	lw	a5,384(a5) # ffffffffc0206028 <free_area+0x10>
ffffffffc0200eb0:	2c079163          	bnez	a5,ffffffffc0201172 <default_check+0x45e>
    free_page(p);
ffffffffc0200eb4:	854e                	mv	a0,s3
ffffffffc0200eb6:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200eb8:	01893023          	sd	s8,0(s2)
ffffffffc0200ebc:	01793423          	sd	s7,8(s2)
    nr_free = nr_free_store;
ffffffffc0200ec0:	01692823          	sw	s6,16(s2)
    free_page(p);
ffffffffc0200ec4:	091000ef          	jal	ffffffffc0201754 <free_pages>
    free_page(p1);
ffffffffc0200ec8:	8556                	mv	a0,s5
ffffffffc0200eca:	4585                	li	a1,1
ffffffffc0200ecc:	089000ef          	jal	ffffffffc0201754 <free_pages>
    free_page(p2);
ffffffffc0200ed0:	8552                	mv	a0,s4
ffffffffc0200ed2:	4585                	li	a1,1
ffffffffc0200ed4:	081000ef          	jal	ffffffffc0201754 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200ed8:	4515                	li	a0,5
ffffffffc0200eda:	06f000ef          	jal	ffffffffc0201748 <alloc_pages>
ffffffffc0200ede:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200ee0:	26050963          	beqz	a0,ffffffffc0201152 <default_check+0x43e>
    assert(!PageProperty(p0));
ffffffffc0200ee4:	651c                	ld	a5,8(a0)
ffffffffc0200ee6:	8b89                	andi	a5,a5,2
ffffffffc0200ee8:	54079563          	bnez	a5,ffffffffc0201432 <default_check+0x71e>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200eec:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200eee:	00093b83          	ld	s7,0(s2)
ffffffffc0200ef2:	00893b03          	ld	s6,8(s2)
ffffffffc0200ef6:	01293023          	sd	s2,0(s2)
ffffffffc0200efa:	01293423          	sd	s2,8(s2)
    assert(alloc_page() == NULL);
ffffffffc0200efe:	04b000ef          	jal	ffffffffc0201748 <alloc_pages>
ffffffffc0200f02:	50051863          	bnez	a0,ffffffffc0201412 <default_check+0x6fe>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200f06:	05098a13          	addi	s4,s3,80
ffffffffc0200f0a:	8552                	mv	a0,s4
ffffffffc0200f0c:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200f0e:	00005c17          	auipc	s8,0x5
ffffffffc0200f12:	11ac2c03          	lw	s8,282(s8) # ffffffffc0206028 <free_area+0x10>
    nr_free = 0;
ffffffffc0200f16:	00005797          	auipc	a5,0x5
ffffffffc0200f1a:	1007a923          	sw	zero,274(a5) # ffffffffc0206028 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200f1e:	037000ef          	jal	ffffffffc0201754 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200f22:	4511                	li	a0,4
ffffffffc0200f24:	025000ef          	jal	ffffffffc0201748 <alloc_pages>
ffffffffc0200f28:	4c051563          	bnez	a0,ffffffffc02013f2 <default_check+0x6de>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200f2c:	0589b783          	ld	a5,88(s3)
ffffffffc0200f30:	8b89                	andi	a5,a5,2
ffffffffc0200f32:	4a078063          	beqz	a5,ffffffffc02013d2 <default_check+0x6be>
ffffffffc0200f36:	0609a503          	lw	a0,96(s3)
ffffffffc0200f3a:	478d                	li	a5,3
ffffffffc0200f3c:	48f51b63          	bne	a0,a5,ffffffffc02013d2 <default_check+0x6be>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200f40:	009000ef          	jal	ffffffffc0201748 <alloc_pages>
ffffffffc0200f44:	8aaa                	mv	s5,a0
ffffffffc0200f46:	46050663          	beqz	a0,ffffffffc02013b2 <default_check+0x69e>
    assert(alloc_page() == NULL);
ffffffffc0200f4a:	4505                	li	a0,1
ffffffffc0200f4c:	7fc000ef          	jal	ffffffffc0201748 <alloc_pages>
ffffffffc0200f50:	44051163          	bnez	a0,ffffffffc0201392 <default_check+0x67e>
    assert(p0 + 2 == p1);
ffffffffc0200f54:	415a1f63          	bne	s4,s5,ffffffffc0201372 <default_check+0x65e>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200f58:	4585                	li	a1,1
ffffffffc0200f5a:	854e                	mv	a0,s3
ffffffffc0200f5c:	7f8000ef          	jal	ffffffffc0201754 <free_pages>
    free_pages(p1, 3);
ffffffffc0200f60:	8552                	mv	a0,s4
ffffffffc0200f62:	458d                	li	a1,3
ffffffffc0200f64:	7f0000ef          	jal	ffffffffc0201754 <free_pages>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200f68:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0200f6c:	02898c93          	addi	s9,s3,40
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200f70:	8b89                	andi	a5,a5,2
ffffffffc0200f72:	3e078063          	beqz	a5,ffffffffc0201352 <default_check+0x63e>
ffffffffc0200f76:	0109aa83          	lw	s5,16(s3)
ffffffffc0200f7a:	4785                	li	a5,1
ffffffffc0200f7c:	3cfa9b63          	bne	s5,a5,ffffffffc0201352 <default_check+0x63e>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200f80:	008a3783          	ld	a5,8(s4)
ffffffffc0200f84:	8b89                	andi	a5,a5,2
ffffffffc0200f86:	3a078663          	beqz	a5,ffffffffc0201332 <default_check+0x61e>
ffffffffc0200f8a:	010a2703          	lw	a4,16(s4)
ffffffffc0200f8e:	478d                	li	a5,3
ffffffffc0200f90:	3af71163          	bne	a4,a5,ffffffffc0201332 <default_check+0x61e>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200f94:	8556                	mv	a0,s5
ffffffffc0200f96:	7b2000ef          	jal	ffffffffc0201748 <alloc_pages>
ffffffffc0200f9a:	36a99c63          	bne	s3,a0,ffffffffc0201312 <default_check+0x5fe>
    free_page(p0);
ffffffffc0200f9e:	85d6                	mv	a1,s5
ffffffffc0200fa0:	7b4000ef          	jal	ffffffffc0201754 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200fa4:	4509                	li	a0,2
ffffffffc0200fa6:	7a2000ef          	jal	ffffffffc0201748 <alloc_pages>
ffffffffc0200faa:	34aa1463          	bne	s4,a0,ffffffffc02012f2 <default_check+0x5de>

    free_pages(p0, 2);
ffffffffc0200fae:	4589                	li	a1,2
ffffffffc0200fb0:	7a4000ef          	jal	ffffffffc0201754 <free_pages>
    free_page(p2);
ffffffffc0200fb4:	85d6                	mv	a1,s5
ffffffffc0200fb6:	8566                	mv	a0,s9
ffffffffc0200fb8:	79c000ef          	jal	ffffffffc0201754 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200fbc:	4515                	li	a0,5
ffffffffc0200fbe:	78a000ef          	jal	ffffffffc0201748 <alloc_pages>
ffffffffc0200fc2:	89aa                	mv	s3,a0
ffffffffc0200fc4:	48050763          	beqz	a0,ffffffffc0201452 <default_check+0x73e>
    assert(alloc_page() == NULL);
ffffffffc0200fc8:	8556                	mv	a0,s5
ffffffffc0200fca:	77e000ef          	jal	ffffffffc0201748 <alloc_pages>
ffffffffc0200fce:	2e051263          	bnez	a0,ffffffffc02012b2 <default_check+0x59e>

    assert(nr_free == 0);
ffffffffc0200fd2:	00005797          	auipc	a5,0x5
ffffffffc0200fd6:	0567a783          	lw	a5,86(a5) # ffffffffc0206028 <free_area+0x10>
ffffffffc0200fda:	2a079c63          	bnez	a5,ffffffffc0201292 <default_check+0x57e>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200fde:	854e                	mv	a0,s3
ffffffffc0200fe0:	4595                	li	a1,5
    nr_free = nr_free_store;
ffffffffc0200fe2:	01892823          	sw	s8,16(s2)
    free_list = free_list_store;
ffffffffc0200fe6:	01793023          	sd	s7,0(s2)
ffffffffc0200fea:	01693423          	sd	s6,8(s2)
    free_pages(p0, 5);
ffffffffc0200fee:	766000ef          	jal	ffffffffc0201754 <free_pages>
    return listelm->next;
ffffffffc0200ff2:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200ff6:	01278963          	beq	a5,s2,ffffffffc0201008 <default_check+0x2f4>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200ffa:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200ffe:	679c                	ld	a5,8(a5)
ffffffffc0201000:	34fd                	addiw	s1,s1,-1
ffffffffc0201002:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201004:	ff279be3          	bne	a5,s2,ffffffffc0200ffa <default_check+0x2e6>
    }
    assert(count == 0);
ffffffffc0201008:	26049563          	bnez	s1,ffffffffc0201272 <default_check+0x55e>
    assert(total == 0);
ffffffffc020100c:	46041363          	bnez	s0,ffffffffc0201472 <default_check+0x75e>
}
ffffffffc0201010:	60e6                	ld	ra,88(sp)
ffffffffc0201012:	6446                	ld	s0,80(sp)
ffffffffc0201014:	64a6                	ld	s1,72(sp)
ffffffffc0201016:	6906                	ld	s2,64(sp)
ffffffffc0201018:	79e2                	ld	s3,56(sp)
ffffffffc020101a:	7a42                	ld	s4,48(sp)
ffffffffc020101c:	7aa2                	ld	s5,40(sp)
ffffffffc020101e:	7b02                	ld	s6,32(sp)
ffffffffc0201020:	6be2                	ld	s7,24(sp)
ffffffffc0201022:	6c42                	ld	s8,16(sp)
ffffffffc0201024:	6ca2                	ld	s9,8(sp)
ffffffffc0201026:	6125                	addi	sp,sp,96
ffffffffc0201028:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc020102a:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020102c:	4401                	li	s0,0
ffffffffc020102e:	4481                	li	s1,0
ffffffffc0201030:	b32d                	j	ffffffffc0200d5a <default_check+0x46>
        assert(PageProperty(p));
ffffffffc0201032:	00001697          	auipc	a3,0x1
ffffffffc0201036:	6c668693          	addi	a3,a3,1734 # ffffffffc02026f8 <etext+0x838>
ffffffffc020103a:	00001617          	auipc	a2,0x1
ffffffffc020103e:	fc660613          	addi	a2,a2,-58 # ffffffffc0202000 <etext+0x140>
ffffffffc0201042:	0bd00593          	li	a1,189
ffffffffc0201046:	00001517          	auipc	a0,0x1
ffffffffc020104a:	69a50513          	addi	a0,a0,1690 # ffffffffc02026e0 <etext+0x820>
ffffffffc020104e:	dd8ff0ef          	jal	ffffffffc0200626 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201052:	00001697          	auipc	a3,0x1
ffffffffc0201056:	73668693          	addi	a3,a3,1846 # ffffffffc0202788 <etext+0x8c8>
ffffffffc020105a:	00001617          	auipc	a2,0x1
ffffffffc020105e:	fa660613          	addi	a2,a2,-90 # ffffffffc0202000 <etext+0x140>
ffffffffc0201062:	08a00593          	li	a1,138
ffffffffc0201066:	00001517          	auipc	a0,0x1
ffffffffc020106a:	67a50513          	addi	a0,a0,1658 # ffffffffc02026e0 <etext+0x820>
ffffffffc020106e:	db8ff0ef          	jal	ffffffffc0200626 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201072:	00001697          	auipc	a3,0x1
ffffffffc0201076:	73e68693          	addi	a3,a3,1854 # ffffffffc02027b0 <etext+0x8f0>
ffffffffc020107a:	00001617          	auipc	a2,0x1
ffffffffc020107e:	f8660613          	addi	a2,a2,-122 # ffffffffc0202000 <etext+0x140>
ffffffffc0201082:	08b00593          	li	a1,139
ffffffffc0201086:	00001517          	auipc	a0,0x1
ffffffffc020108a:	65a50513          	addi	a0,a0,1626 # ffffffffc02026e0 <etext+0x820>
ffffffffc020108e:	d98ff0ef          	jal	ffffffffc0200626 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201092:	00001697          	auipc	a3,0x1
ffffffffc0201096:	75e68693          	addi	a3,a3,1886 # ffffffffc02027f0 <etext+0x930>
ffffffffc020109a:	00001617          	auipc	a2,0x1
ffffffffc020109e:	f6660613          	addi	a2,a2,-154 # ffffffffc0202000 <etext+0x140>
ffffffffc02010a2:	08d00593          	li	a1,141
ffffffffc02010a6:	00001517          	auipc	a0,0x1
ffffffffc02010aa:	63a50513          	addi	a0,a0,1594 # ffffffffc02026e0 <etext+0x820>
ffffffffc02010ae:	d78ff0ef          	jal	ffffffffc0200626 <__panic>
    assert(!list_empty(&free_list));
ffffffffc02010b2:	00001697          	auipc	a3,0x1
ffffffffc02010b6:	7ae68693          	addi	a3,a3,1966 # ffffffffc0202860 <etext+0x9a0>
ffffffffc02010ba:	00001617          	auipc	a2,0x1
ffffffffc02010be:	f4660613          	addi	a2,a2,-186 # ffffffffc0202000 <etext+0x140>
ffffffffc02010c2:	0a600593          	li	a1,166
ffffffffc02010c6:	00001517          	auipc	a0,0x1
ffffffffc02010ca:	61a50513          	addi	a0,a0,1562 # ffffffffc02026e0 <etext+0x820>
ffffffffc02010ce:	d58ff0ef          	jal	ffffffffc0200626 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02010d2:	00001697          	auipc	a3,0x1
ffffffffc02010d6:	65668693          	addi	a3,a3,1622 # ffffffffc0202728 <etext+0x868>
ffffffffc02010da:	00001617          	auipc	a2,0x1
ffffffffc02010de:	f2660613          	addi	a2,a2,-218 # ffffffffc0202000 <etext+0x140>
ffffffffc02010e2:	09f00593          	li	a1,159
ffffffffc02010e6:	00001517          	auipc	a0,0x1
ffffffffc02010ea:	5fa50513          	addi	a0,a0,1530 # ffffffffc02026e0 <etext+0x820>
ffffffffc02010ee:	d38ff0ef          	jal	ffffffffc0200626 <__panic>
    assert(nr_free == 3);
ffffffffc02010f2:	00001697          	auipc	a3,0x1
ffffffffc02010f6:	75e68693          	addi	a3,a3,1886 # ffffffffc0202850 <etext+0x990>
ffffffffc02010fa:	00001617          	auipc	a2,0x1
ffffffffc02010fe:	f0660613          	addi	a2,a2,-250 # ffffffffc0202000 <etext+0x140>
ffffffffc0201102:	09d00593          	li	a1,157
ffffffffc0201106:	00001517          	auipc	a0,0x1
ffffffffc020110a:	5da50513          	addi	a0,a0,1498 # ffffffffc02026e0 <etext+0x820>
ffffffffc020110e:	d18ff0ef          	jal	ffffffffc0200626 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201112:	00001697          	auipc	a3,0x1
ffffffffc0201116:	12668693          	addi	a3,a3,294 # ffffffffc0202238 <etext+0x378>
ffffffffc020111a:	00001617          	auipc	a2,0x1
ffffffffc020111e:	ee660613          	addi	a2,a2,-282 # ffffffffc0202000 <etext+0x140>
ffffffffc0201122:	09800593          	li	a1,152
ffffffffc0201126:	00001517          	auipc	a0,0x1
ffffffffc020112a:	5ba50513          	addi	a0,a0,1466 # ffffffffc02026e0 <etext+0x820>
ffffffffc020112e:	cf8ff0ef          	jal	ffffffffc0200626 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201132:	00001697          	auipc	a3,0x1
ffffffffc0201136:	6fe68693          	addi	a3,a3,1790 # ffffffffc0202830 <etext+0x970>
ffffffffc020113a:	00001617          	auipc	a2,0x1
ffffffffc020113e:	ec660613          	addi	a2,a2,-314 # ffffffffc0202000 <etext+0x140>
ffffffffc0201142:	08f00593          	li	a1,143
ffffffffc0201146:	00001517          	auipc	a0,0x1
ffffffffc020114a:	59a50513          	addi	a0,a0,1434 # ffffffffc02026e0 <etext+0x820>
ffffffffc020114e:	cd8ff0ef          	jal	ffffffffc0200626 <__panic>
    assert(p0 != NULL);
ffffffffc0201152:	00001697          	auipc	a3,0x1
ffffffffc0201156:	75668693          	addi	a3,a3,1878 # ffffffffc02028a8 <etext+0x9e8>
ffffffffc020115a:	00001617          	auipc	a2,0x1
ffffffffc020115e:	ea660613          	addi	a2,a2,-346 # ffffffffc0202000 <etext+0x140>
ffffffffc0201162:	0c500593          	li	a1,197
ffffffffc0201166:	00001517          	auipc	a0,0x1
ffffffffc020116a:	57a50513          	addi	a0,a0,1402 # ffffffffc02026e0 <etext+0x820>
ffffffffc020116e:	cb8ff0ef          	jal	ffffffffc0200626 <__panic>
    assert(nr_free == 0);
ffffffffc0201172:	00001697          	auipc	a3,0x1
ffffffffc0201176:	72668693          	addi	a3,a3,1830 # ffffffffc0202898 <etext+0x9d8>
ffffffffc020117a:	00001617          	auipc	a2,0x1
ffffffffc020117e:	e8660613          	addi	a2,a2,-378 # ffffffffc0202000 <etext+0x140>
ffffffffc0201182:	0ac00593          	li	a1,172
ffffffffc0201186:	00001517          	auipc	a0,0x1
ffffffffc020118a:	55a50513          	addi	a0,a0,1370 # ffffffffc02026e0 <etext+0x820>
ffffffffc020118e:	c98ff0ef          	jal	ffffffffc0200626 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201192:	00001697          	auipc	a3,0x1
ffffffffc0201196:	0a668693          	addi	a3,a3,166 # ffffffffc0202238 <etext+0x378>
ffffffffc020119a:	00001617          	auipc	a2,0x1
ffffffffc020119e:	e6660613          	addi	a2,a2,-410 # ffffffffc0202000 <etext+0x140>
ffffffffc02011a2:	0aa00593          	li	a1,170
ffffffffc02011a6:	00001517          	auipc	a0,0x1
ffffffffc02011aa:	53a50513          	addi	a0,a0,1338 # ffffffffc02026e0 <etext+0x820>
ffffffffc02011ae:	c78ff0ef          	jal	ffffffffc0200626 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02011b2:	00001697          	auipc	a3,0x1
ffffffffc02011b6:	6c668693          	addi	a3,a3,1734 # ffffffffc0202878 <etext+0x9b8>
ffffffffc02011ba:	00001617          	auipc	a2,0x1
ffffffffc02011be:	e4660613          	addi	a2,a2,-442 # ffffffffc0202000 <etext+0x140>
ffffffffc02011c2:	0a900593          	li	a1,169
ffffffffc02011c6:	00001517          	auipc	a0,0x1
ffffffffc02011ca:	51a50513          	addi	a0,a0,1306 # ffffffffc02026e0 <etext+0x820>
ffffffffc02011ce:	c58ff0ef          	jal	ffffffffc0200626 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02011d2:	00001697          	auipc	a3,0x1
ffffffffc02011d6:	55668693          	addi	a3,a3,1366 # ffffffffc0202728 <etext+0x868>
ffffffffc02011da:	00001617          	auipc	a2,0x1
ffffffffc02011de:	e2660613          	addi	a2,a2,-474 # ffffffffc0202000 <etext+0x140>
ffffffffc02011e2:	08600593          	li	a1,134
ffffffffc02011e6:	00001517          	auipc	a0,0x1
ffffffffc02011ea:	4fa50513          	addi	a0,a0,1274 # ffffffffc02026e0 <etext+0x820>
ffffffffc02011ee:	c38ff0ef          	jal	ffffffffc0200626 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011f2:	00001697          	auipc	a3,0x1
ffffffffc02011f6:	04668693          	addi	a3,a3,70 # ffffffffc0202238 <etext+0x378>
ffffffffc02011fa:	00001617          	auipc	a2,0x1
ffffffffc02011fe:	e0660613          	addi	a2,a2,-506 # ffffffffc0202000 <etext+0x140>
ffffffffc0201202:	0a300593          	li	a1,163
ffffffffc0201206:	00001517          	auipc	a0,0x1
ffffffffc020120a:	4da50513          	addi	a0,a0,1242 # ffffffffc02026e0 <etext+0x820>
ffffffffc020120e:	c18ff0ef          	jal	ffffffffc0200626 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201212:	00001697          	auipc	a3,0x1
ffffffffc0201216:	55668693          	addi	a3,a3,1366 # ffffffffc0202768 <etext+0x8a8>
ffffffffc020121a:	00001617          	auipc	a2,0x1
ffffffffc020121e:	de660613          	addi	a2,a2,-538 # ffffffffc0202000 <etext+0x140>
ffffffffc0201222:	0a100593          	li	a1,161
ffffffffc0201226:	00001517          	auipc	a0,0x1
ffffffffc020122a:	4ba50513          	addi	a0,a0,1210 # ffffffffc02026e0 <etext+0x820>
ffffffffc020122e:	bf8ff0ef          	jal	ffffffffc0200626 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201232:	00001697          	auipc	a3,0x1
ffffffffc0201236:	51668693          	addi	a3,a3,1302 # ffffffffc0202748 <etext+0x888>
ffffffffc020123a:	00001617          	auipc	a2,0x1
ffffffffc020123e:	dc660613          	addi	a2,a2,-570 # ffffffffc0202000 <etext+0x140>
ffffffffc0201242:	0a000593          	li	a1,160
ffffffffc0201246:	00001517          	auipc	a0,0x1
ffffffffc020124a:	49a50513          	addi	a0,a0,1178 # ffffffffc02026e0 <etext+0x820>
ffffffffc020124e:	bd8ff0ef          	jal	ffffffffc0200626 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201252:	00001697          	auipc	a3,0x1
ffffffffc0201256:	51668693          	addi	a3,a3,1302 # ffffffffc0202768 <etext+0x8a8>
ffffffffc020125a:	00001617          	auipc	a2,0x1
ffffffffc020125e:	da660613          	addi	a2,a2,-602 # ffffffffc0202000 <etext+0x140>
ffffffffc0201262:	08800593          	li	a1,136
ffffffffc0201266:	00001517          	auipc	a0,0x1
ffffffffc020126a:	47a50513          	addi	a0,a0,1146 # ffffffffc02026e0 <etext+0x820>
ffffffffc020126e:	bb8ff0ef          	jal	ffffffffc0200626 <__panic>
    assert(count == 0);
ffffffffc0201272:	00001697          	auipc	a3,0x1
ffffffffc0201276:	78668693          	addi	a3,a3,1926 # ffffffffc02029f8 <etext+0xb38>
ffffffffc020127a:	00001617          	auipc	a2,0x1
ffffffffc020127e:	d8660613          	addi	a2,a2,-634 # ffffffffc0202000 <etext+0x140>
ffffffffc0201282:	0f200593          	li	a1,242
ffffffffc0201286:	00001517          	auipc	a0,0x1
ffffffffc020128a:	45a50513          	addi	a0,a0,1114 # ffffffffc02026e0 <etext+0x820>
ffffffffc020128e:	b98ff0ef          	jal	ffffffffc0200626 <__panic>
    assert(nr_free == 0);
ffffffffc0201292:	00001697          	auipc	a3,0x1
ffffffffc0201296:	60668693          	addi	a3,a3,1542 # ffffffffc0202898 <etext+0x9d8>
ffffffffc020129a:	00001617          	auipc	a2,0x1
ffffffffc020129e:	d6660613          	addi	a2,a2,-666 # ffffffffc0202000 <etext+0x140>
ffffffffc02012a2:	0e700593          	li	a1,231
ffffffffc02012a6:	00001517          	auipc	a0,0x1
ffffffffc02012aa:	43a50513          	addi	a0,a0,1082 # ffffffffc02026e0 <etext+0x820>
ffffffffc02012ae:	b78ff0ef          	jal	ffffffffc0200626 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012b2:	00001697          	auipc	a3,0x1
ffffffffc02012b6:	f8668693          	addi	a3,a3,-122 # ffffffffc0202238 <etext+0x378>
ffffffffc02012ba:	00001617          	auipc	a2,0x1
ffffffffc02012be:	d4660613          	addi	a2,a2,-698 # ffffffffc0202000 <etext+0x140>
ffffffffc02012c2:	0e500593          	li	a1,229
ffffffffc02012c6:	00001517          	auipc	a0,0x1
ffffffffc02012ca:	41a50513          	addi	a0,a0,1050 # ffffffffc02026e0 <etext+0x820>
ffffffffc02012ce:	b58ff0ef          	jal	ffffffffc0200626 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02012d2:	00001697          	auipc	a3,0x1
ffffffffc02012d6:	53e68693          	addi	a3,a3,1342 # ffffffffc0202810 <etext+0x950>
ffffffffc02012da:	00001617          	auipc	a2,0x1
ffffffffc02012de:	d2660613          	addi	a2,a2,-730 # ffffffffc0202000 <etext+0x140>
ffffffffc02012e2:	08e00593          	li	a1,142
ffffffffc02012e6:	00001517          	auipc	a0,0x1
ffffffffc02012ea:	3fa50513          	addi	a0,a0,1018 # ffffffffc02026e0 <etext+0x820>
ffffffffc02012ee:	b38ff0ef          	jal	ffffffffc0200626 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02012f2:	00001697          	auipc	a3,0x1
ffffffffc02012f6:	6c668693          	addi	a3,a3,1734 # ffffffffc02029b8 <etext+0xaf8>
ffffffffc02012fa:	00001617          	auipc	a2,0x1
ffffffffc02012fe:	d0660613          	addi	a2,a2,-762 # ffffffffc0202000 <etext+0x140>
ffffffffc0201302:	0df00593          	li	a1,223
ffffffffc0201306:	00001517          	auipc	a0,0x1
ffffffffc020130a:	3da50513          	addi	a0,a0,986 # ffffffffc02026e0 <etext+0x820>
ffffffffc020130e:	b18ff0ef          	jal	ffffffffc0200626 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201312:	00001697          	auipc	a3,0x1
ffffffffc0201316:	68668693          	addi	a3,a3,1670 # ffffffffc0202998 <etext+0xad8>
ffffffffc020131a:	00001617          	auipc	a2,0x1
ffffffffc020131e:	ce660613          	addi	a2,a2,-794 # ffffffffc0202000 <etext+0x140>
ffffffffc0201322:	0dd00593          	li	a1,221
ffffffffc0201326:	00001517          	auipc	a0,0x1
ffffffffc020132a:	3ba50513          	addi	a0,a0,954 # ffffffffc02026e0 <etext+0x820>
ffffffffc020132e:	af8ff0ef          	jal	ffffffffc0200626 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201332:	00001697          	auipc	a3,0x1
ffffffffc0201336:	63e68693          	addi	a3,a3,1598 # ffffffffc0202970 <etext+0xab0>
ffffffffc020133a:	00001617          	auipc	a2,0x1
ffffffffc020133e:	cc660613          	addi	a2,a2,-826 # ffffffffc0202000 <etext+0x140>
ffffffffc0201342:	0db00593          	li	a1,219
ffffffffc0201346:	00001517          	auipc	a0,0x1
ffffffffc020134a:	39a50513          	addi	a0,a0,922 # ffffffffc02026e0 <etext+0x820>
ffffffffc020134e:	ad8ff0ef          	jal	ffffffffc0200626 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201352:	00001697          	auipc	a3,0x1
ffffffffc0201356:	5f668693          	addi	a3,a3,1526 # ffffffffc0202948 <etext+0xa88>
ffffffffc020135a:	00001617          	auipc	a2,0x1
ffffffffc020135e:	ca660613          	addi	a2,a2,-858 # ffffffffc0202000 <etext+0x140>
ffffffffc0201362:	0da00593          	li	a1,218
ffffffffc0201366:	00001517          	auipc	a0,0x1
ffffffffc020136a:	37a50513          	addi	a0,a0,890 # ffffffffc02026e0 <etext+0x820>
ffffffffc020136e:	ab8ff0ef          	jal	ffffffffc0200626 <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201372:	00001697          	auipc	a3,0x1
ffffffffc0201376:	5c668693          	addi	a3,a3,1478 # ffffffffc0202938 <etext+0xa78>
ffffffffc020137a:	00001617          	auipc	a2,0x1
ffffffffc020137e:	c8660613          	addi	a2,a2,-890 # ffffffffc0202000 <etext+0x140>
ffffffffc0201382:	0d500593          	li	a1,213
ffffffffc0201386:	00001517          	auipc	a0,0x1
ffffffffc020138a:	35a50513          	addi	a0,a0,858 # ffffffffc02026e0 <etext+0x820>
ffffffffc020138e:	a98ff0ef          	jal	ffffffffc0200626 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201392:	00001697          	auipc	a3,0x1
ffffffffc0201396:	ea668693          	addi	a3,a3,-346 # ffffffffc0202238 <etext+0x378>
ffffffffc020139a:	00001617          	auipc	a2,0x1
ffffffffc020139e:	c6660613          	addi	a2,a2,-922 # ffffffffc0202000 <etext+0x140>
ffffffffc02013a2:	0d400593          	li	a1,212
ffffffffc02013a6:	00001517          	auipc	a0,0x1
ffffffffc02013aa:	33a50513          	addi	a0,a0,826 # ffffffffc02026e0 <etext+0x820>
ffffffffc02013ae:	a78ff0ef          	jal	ffffffffc0200626 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02013b2:	00001697          	auipc	a3,0x1
ffffffffc02013b6:	56668693          	addi	a3,a3,1382 # ffffffffc0202918 <etext+0xa58>
ffffffffc02013ba:	00001617          	auipc	a2,0x1
ffffffffc02013be:	c4660613          	addi	a2,a2,-954 # ffffffffc0202000 <etext+0x140>
ffffffffc02013c2:	0d300593          	li	a1,211
ffffffffc02013c6:	00001517          	auipc	a0,0x1
ffffffffc02013ca:	31a50513          	addi	a0,a0,794 # ffffffffc02026e0 <etext+0x820>
ffffffffc02013ce:	a58ff0ef          	jal	ffffffffc0200626 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02013d2:	00001697          	auipc	a3,0x1
ffffffffc02013d6:	51668693          	addi	a3,a3,1302 # ffffffffc02028e8 <etext+0xa28>
ffffffffc02013da:	00001617          	auipc	a2,0x1
ffffffffc02013de:	c2660613          	addi	a2,a2,-986 # ffffffffc0202000 <etext+0x140>
ffffffffc02013e2:	0d200593          	li	a1,210
ffffffffc02013e6:	00001517          	auipc	a0,0x1
ffffffffc02013ea:	2fa50513          	addi	a0,a0,762 # ffffffffc02026e0 <etext+0x820>
ffffffffc02013ee:	a38ff0ef          	jal	ffffffffc0200626 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02013f2:	00001697          	auipc	a3,0x1
ffffffffc02013f6:	4de68693          	addi	a3,a3,1246 # ffffffffc02028d0 <etext+0xa10>
ffffffffc02013fa:	00001617          	auipc	a2,0x1
ffffffffc02013fe:	c0660613          	addi	a2,a2,-1018 # ffffffffc0202000 <etext+0x140>
ffffffffc0201402:	0d100593          	li	a1,209
ffffffffc0201406:	00001517          	auipc	a0,0x1
ffffffffc020140a:	2da50513          	addi	a0,a0,730 # ffffffffc02026e0 <etext+0x820>
ffffffffc020140e:	a18ff0ef          	jal	ffffffffc0200626 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201412:	00001697          	auipc	a3,0x1
ffffffffc0201416:	e2668693          	addi	a3,a3,-474 # ffffffffc0202238 <etext+0x378>
ffffffffc020141a:	00001617          	auipc	a2,0x1
ffffffffc020141e:	be660613          	addi	a2,a2,-1050 # ffffffffc0202000 <etext+0x140>
ffffffffc0201422:	0cb00593          	li	a1,203
ffffffffc0201426:	00001517          	auipc	a0,0x1
ffffffffc020142a:	2ba50513          	addi	a0,a0,698 # ffffffffc02026e0 <etext+0x820>
ffffffffc020142e:	9f8ff0ef          	jal	ffffffffc0200626 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201432:	00001697          	auipc	a3,0x1
ffffffffc0201436:	48668693          	addi	a3,a3,1158 # ffffffffc02028b8 <etext+0x9f8>
ffffffffc020143a:	00001617          	auipc	a2,0x1
ffffffffc020143e:	bc660613          	addi	a2,a2,-1082 # ffffffffc0202000 <etext+0x140>
ffffffffc0201442:	0c600593          	li	a1,198
ffffffffc0201446:	00001517          	auipc	a0,0x1
ffffffffc020144a:	29a50513          	addi	a0,a0,666 # ffffffffc02026e0 <etext+0x820>
ffffffffc020144e:	9d8ff0ef          	jal	ffffffffc0200626 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201452:	00001697          	auipc	a3,0x1
ffffffffc0201456:	58668693          	addi	a3,a3,1414 # ffffffffc02029d8 <etext+0xb18>
ffffffffc020145a:	00001617          	auipc	a2,0x1
ffffffffc020145e:	ba660613          	addi	a2,a2,-1114 # ffffffffc0202000 <etext+0x140>
ffffffffc0201462:	0e400593          	li	a1,228
ffffffffc0201466:	00001517          	auipc	a0,0x1
ffffffffc020146a:	27a50513          	addi	a0,a0,634 # ffffffffc02026e0 <etext+0x820>
ffffffffc020146e:	9b8ff0ef          	jal	ffffffffc0200626 <__panic>
    assert(total == 0);
ffffffffc0201472:	00001697          	auipc	a3,0x1
ffffffffc0201476:	59668693          	addi	a3,a3,1430 # ffffffffc0202a08 <etext+0xb48>
ffffffffc020147a:	00001617          	auipc	a2,0x1
ffffffffc020147e:	b8660613          	addi	a2,a2,-1146 # ffffffffc0202000 <etext+0x140>
ffffffffc0201482:	0f300593          	li	a1,243
ffffffffc0201486:	00001517          	auipc	a0,0x1
ffffffffc020148a:	25a50513          	addi	a0,a0,602 # ffffffffc02026e0 <etext+0x820>
ffffffffc020148e:	998ff0ef          	jal	ffffffffc0200626 <__panic>
    assert(total == nr_free_pages());
ffffffffc0201492:	00001697          	auipc	a3,0x1
ffffffffc0201496:	27668693          	addi	a3,a3,630 # ffffffffc0202708 <etext+0x848>
ffffffffc020149a:	00001617          	auipc	a2,0x1
ffffffffc020149e:	b6660613          	addi	a2,a2,-1178 # ffffffffc0202000 <etext+0x140>
ffffffffc02014a2:	0c000593          	li	a1,192
ffffffffc02014a6:	00001517          	auipc	a0,0x1
ffffffffc02014aa:	23a50513          	addi	a0,a0,570 # ffffffffc02026e0 <etext+0x820>
ffffffffc02014ae:	978ff0ef          	jal	ffffffffc0200626 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02014b2:	00001697          	auipc	a3,0x1
ffffffffc02014b6:	29668693          	addi	a3,a3,662 # ffffffffc0202748 <etext+0x888>
ffffffffc02014ba:	00001617          	auipc	a2,0x1
ffffffffc02014be:	b4660613          	addi	a2,a2,-1210 # ffffffffc0202000 <etext+0x140>
ffffffffc02014c2:	08700593          	li	a1,135
ffffffffc02014c6:	00001517          	auipc	a0,0x1
ffffffffc02014ca:	21a50513          	addi	a0,a0,538 # ffffffffc02026e0 <etext+0x820>
ffffffffc02014ce:	958ff0ef          	jal	ffffffffc0200626 <__panic>

ffffffffc02014d2 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc02014d2:	1141                	addi	sp,sp,-16
ffffffffc02014d4:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02014d6:	14058f63          	beqz	a1,ffffffffc0201634 <default_free_pages+0x162>
    for (; p != base + n; p ++) {
ffffffffc02014da:	00259713          	slli	a4,a1,0x2
ffffffffc02014de:	972e                	add	a4,a4,a1
ffffffffc02014e0:	070e                	slli	a4,a4,0x3
ffffffffc02014e2:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc02014e6:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc02014e8:	cf09                	beqz	a4,ffffffffc0201502 <default_free_pages+0x30>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02014ea:	6798                	ld	a4,8(a5)
ffffffffc02014ec:	8b0d                	andi	a4,a4,3
ffffffffc02014ee:	12071363          	bnez	a4,ffffffffc0201614 <default_free_pages+0x142>
        p->flags = 0;
ffffffffc02014f2:	0007b423          	sd	zero,8(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02014f6:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02014fa:	02878793          	addi	a5,a5,40
ffffffffc02014fe:	fed796e3          	bne	a5,a3,ffffffffc02014ea <default_free_pages+0x18>
    SetPageProperty(base);
ffffffffc0201502:	00853883          	ld	a7,8(a0)
    nr_free += n;
ffffffffc0201506:	00005717          	auipc	a4,0x5
ffffffffc020150a:	b2272703          	lw	a4,-1246(a4) # ffffffffc0206028 <free_area+0x10>
ffffffffc020150e:	00005697          	auipc	a3,0x5
ffffffffc0201512:	b0a68693          	addi	a3,a3,-1270 # ffffffffc0206018 <free_area>
    base->property = n;
ffffffffc0201516:	2581                	sext.w	a1,a1
    return list->next == list;
ffffffffc0201518:	669c                	ld	a5,8(a3)
    SetPageProperty(base);
ffffffffc020151a:	0028e613          	ori	a2,a7,2
    base->property = n;
ffffffffc020151e:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201520:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc0201522:	9f2d                	addw	a4,a4,a1
ffffffffc0201524:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201526:	0ad78763          	beq	a5,a3,ffffffffc02015d4 <default_free_pages+0x102>
            struct Page* page = le2page(le, page_link);
ffffffffc020152a:	fe878713          	addi	a4,a5,-24
ffffffffc020152e:	4801                	li	a6,0
ffffffffc0201530:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0201534:	00e56a63          	bltu	a0,a4,ffffffffc0201548 <default_free_pages+0x76>
    return listelm->next;
ffffffffc0201538:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020153a:	06d70563          	beq	a4,a3,ffffffffc02015a4 <default_free_pages+0xd2>
    struct Page *p = base;
ffffffffc020153e:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201540:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201544:	fee57ae3          	bgeu	a0,a4,ffffffffc0201538 <default_free_pages+0x66>
ffffffffc0201548:	00080463          	beqz	a6,ffffffffc0201550 <default_free_pages+0x7e>
ffffffffc020154c:	0066b023          	sd	t1,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201550:	0007b803          	ld	a6,0(a5)
    prev->next = next->prev = elm;
ffffffffc0201554:	e390                	sd	a2,0(a5)
ffffffffc0201556:	00c83423          	sd	a2,8(a6)
    elm->prev = prev;
ffffffffc020155a:	01053c23          	sd	a6,24(a0)
    elm->next = next;
ffffffffc020155e:	f11c                	sd	a5,32(a0)
    if (le != &free_list) {
ffffffffc0201560:	02d80063          	beq	a6,a3,ffffffffc0201580 <default_free_pages+0xae>
        if (p + p->property == base) {
ffffffffc0201564:	ff882e03          	lw	t3,-8(a6)
        p = le2page(le, page_link);
ffffffffc0201568:	fe880313          	addi	t1,a6,-24
        if (p + p->property == base) {
ffffffffc020156c:	020e1613          	slli	a2,t3,0x20
ffffffffc0201570:	9201                	srli	a2,a2,0x20
ffffffffc0201572:	00261713          	slli	a4,a2,0x2
ffffffffc0201576:	9732                	add	a4,a4,a2
ffffffffc0201578:	070e                	slli	a4,a4,0x3
ffffffffc020157a:	971a                	add	a4,a4,t1
ffffffffc020157c:	02e50e63          	beq	a0,a4,ffffffffc02015b8 <default_free_pages+0xe6>
    if (le != &free_list) {
ffffffffc0201580:	00d78f63          	beq	a5,a3,ffffffffc020159e <default_free_pages+0xcc>
        if (base + base->property == p) {
ffffffffc0201584:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc0201586:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) {
ffffffffc020158a:	02059613          	slli	a2,a1,0x20
ffffffffc020158e:	9201                	srli	a2,a2,0x20
ffffffffc0201590:	00261713          	slli	a4,a2,0x2
ffffffffc0201594:	9732                	add	a4,a4,a2
ffffffffc0201596:	070e                	slli	a4,a4,0x3
ffffffffc0201598:	972a                	add	a4,a4,a0
ffffffffc020159a:	04e68a63          	beq	a3,a4,ffffffffc02015ee <default_free_pages+0x11c>
}
ffffffffc020159e:	60a2                	ld	ra,8(sp)
ffffffffc02015a0:	0141                	addi	sp,sp,16
ffffffffc02015a2:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02015a4:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02015a6:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02015a8:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02015aa:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02015ac:	8332                	mv	t1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc02015ae:	02d70c63          	beq	a4,a3,ffffffffc02015e6 <default_free_pages+0x114>
ffffffffc02015b2:	4805                	li	a6,1
    struct Page *p = base;
ffffffffc02015b4:	87ba                	mv	a5,a4
ffffffffc02015b6:	b769                	j	ffffffffc0201540 <default_free_pages+0x6e>
            p->property += base->property;
ffffffffc02015b8:	01c585bb          	addw	a1,a1,t3
ffffffffc02015bc:	feb82c23          	sw	a1,-8(a6)
            ClearPageProperty(base);
ffffffffc02015c0:	ffd8f893          	andi	a7,a7,-3
ffffffffc02015c4:	01153423          	sd	a7,8(a0)
    prev->next = next;
ffffffffc02015c8:	00f83423          	sd	a5,8(a6)
    next->prev = prev;
ffffffffc02015cc:	0107b023          	sd	a6,0(a5)
            base = p;
ffffffffc02015d0:	851a                	mv	a0,t1
ffffffffc02015d2:	b77d                	j	ffffffffc0201580 <default_free_pages+0xae>
}
ffffffffc02015d4:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02015d6:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc02015da:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02015dc:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc02015de:	e398                	sd	a4,0(a5)
ffffffffc02015e0:	e798                	sd	a4,8(a5)
}
ffffffffc02015e2:	0141                	addi	sp,sp,16
ffffffffc02015e4:	8082                	ret
    return listelm->prev;
ffffffffc02015e6:	883e                	mv	a6,a5
ffffffffc02015e8:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02015ea:	87b6                	mv	a5,a3
ffffffffc02015ec:	bf95                	j	ffffffffc0201560 <default_free_pages+0x8e>
            base->property += p->property;
ffffffffc02015ee:	ff87a683          	lw	a3,-8(a5)
            ClearPageProperty(p);
ffffffffc02015f2:	ff07b703          	ld	a4,-16(a5)
ffffffffc02015f6:	0007b803          	ld	a6,0(a5)
ffffffffc02015fa:	6790                	ld	a2,8(a5)
            base->property += p->property;
ffffffffc02015fc:	9ead                	addw	a3,a3,a1
ffffffffc02015fe:	c914                	sw	a3,16(a0)
            ClearPageProperty(p);
ffffffffc0201600:	9b75                	andi	a4,a4,-3
ffffffffc0201602:	fee7b823          	sd	a4,-16(a5)
}
ffffffffc0201606:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201608:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc020160c:	01063023          	sd	a6,0(a2)
ffffffffc0201610:	0141                	addi	sp,sp,16
ffffffffc0201612:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201614:	00001697          	auipc	a3,0x1
ffffffffc0201618:	40468693          	addi	a3,a3,1028 # ffffffffc0202a18 <etext+0xb58>
ffffffffc020161c:	00001617          	auipc	a2,0x1
ffffffffc0201620:	9e460613          	addi	a2,a2,-1564 # ffffffffc0202000 <etext+0x140>
ffffffffc0201624:	05000593          	li	a1,80
ffffffffc0201628:	00001517          	auipc	a0,0x1
ffffffffc020162c:	0b850513          	addi	a0,a0,184 # ffffffffc02026e0 <etext+0x820>
ffffffffc0201630:	ff7fe0ef          	jal	ffffffffc0200626 <__panic>
    assert(n > 0);
ffffffffc0201634:	00001697          	auipc	a3,0x1
ffffffffc0201638:	0a468693          	addi	a3,a3,164 # ffffffffc02026d8 <etext+0x818>
ffffffffc020163c:	00001617          	auipc	a2,0x1
ffffffffc0201640:	9c460613          	addi	a2,a2,-1596 # ffffffffc0202000 <etext+0x140>
ffffffffc0201644:	04d00593          	li	a1,77
ffffffffc0201648:	00001517          	auipc	a0,0x1
ffffffffc020164c:	09850513          	addi	a0,a0,152 # ffffffffc02026e0 <etext+0x820>
ffffffffc0201650:	fd7fe0ef          	jal	ffffffffc0200626 <__panic>

ffffffffc0201654 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0201654:	1141                	addi	sp,sp,-16
ffffffffc0201656:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201658:	c9e9                	beqz	a1,ffffffffc020172a <default_init_memmap+0xd6>
    for (; p != base + n; p ++) {
ffffffffc020165a:	00259713          	slli	a4,a1,0x2
ffffffffc020165e:	972e                	add	a4,a4,a1
ffffffffc0201660:	070e                	slli	a4,a4,0x3
ffffffffc0201662:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0201666:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc0201668:	cf11                	beqz	a4,ffffffffc0201684 <default_init_memmap+0x30>
        assert(PageReserved(p));
ffffffffc020166a:	6798                	ld	a4,8(a5)
ffffffffc020166c:	8b05                	andi	a4,a4,1
ffffffffc020166e:	cf59                	beqz	a4,ffffffffc020170c <default_init_memmap+0xb8>
        p->flags = p->property = 0;
ffffffffc0201670:	0007a823          	sw	zero,16(a5)
ffffffffc0201674:	0007b423          	sd	zero,8(a5)
ffffffffc0201678:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc020167c:	02878793          	addi	a5,a5,40
ffffffffc0201680:	fed795e3          	bne	a5,a3,ffffffffc020166a <default_init_memmap+0x16>
    SetPageProperty(base);
ffffffffc0201684:	6510                	ld	a2,8(a0)
    nr_free += n;
ffffffffc0201686:	00005717          	auipc	a4,0x5
ffffffffc020168a:	9a272703          	lw	a4,-1630(a4) # ffffffffc0206028 <free_area+0x10>
ffffffffc020168e:	00005697          	auipc	a3,0x5
ffffffffc0201692:	98a68693          	addi	a3,a3,-1654 # ffffffffc0206018 <free_area>
    base->property = n;
ffffffffc0201696:	2581                	sext.w	a1,a1
    return list->next == list;
ffffffffc0201698:	669c                	ld	a5,8(a3)
    SetPageProperty(base);
ffffffffc020169a:	00266613          	ori	a2,a2,2
    base->property = n;
ffffffffc020169e:	c90c                	sw	a1,16(a0)
    nr_free += n;
ffffffffc02016a0:	9f2d                	addw	a4,a4,a1
    SetPageProperty(base);
ffffffffc02016a2:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc02016a4:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02016a6:	04d78663          	beq	a5,a3,ffffffffc02016f2 <default_init_memmap+0x9e>
            struct Page* page = le2page(le, page_link);
ffffffffc02016aa:	fe878713          	addi	a4,a5,-24
ffffffffc02016ae:	4581                	li	a1,0
ffffffffc02016b0:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc02016b4:	00e56a63          	bltu	a0,a4,ffffffffc02016c8 <default_init_memmap+0x74>
    return listelm->next;
ffffffffc02016b8:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02016ba:	02d70263          	beq	a4,a3,ffffffffc02016de <default_init_memmap+0x8a>
    struct Page *p = base;
ffffffffc02016be:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02016c0:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02016c4:	fee57ae3          	bgeu	a0,a4,ffffffffc02016b8 <default_init_memmap+0x64>
ffffffffc02016c8:	c199                	beqz	a1,ffffffffc02016ce <default_init_memmap+0x7a>
ffffffffc02016ca:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02016ce:	6398                	ld	a4,0(a5)
}
ffffffffc02016d0:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02016d2:	e390                	sd	a2,0(a5)
ffffffffc02016d4:	e710                	sd	a2,8(a4)
    elm->prev = prev;
ffffffffc02016d6:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc02016d8:	f11c                	sd	a5,32(a0)
ffffffffc02016da:	0141                	addi	sp,sp,16
ffffffffc02016dc:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02016de:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02016e0:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02016e2:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02016e4:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02016e6:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc02016e8:	00d70e63          	beq	a4,a3,ffffffffc0201704 <default_init_memmap+0xb0>
ffffffffc02016ec:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc02016ee:	87ba                	mv	a5,a4
ffffffffc02016f0:	bfc1                	j	ffffffffc02016c0 <default_init_memmap+0x6c>
}
ffffffffc02016f2:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02016f4:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc02016f8:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02016fa:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc02016fc:	e398                	sd	a4,0(a5)
ffffffffc02016fe:	e798                	sd	a4,8(a5)
}
ffffffffc0201700:	0141                	addi	sp,sp,16
ffffffffc0201702:	8082                	ret
ffffffffc0201704:	60a2                	ld	ra,8(sp)
ffffffffc0201706:	e290                	sd	a2,0(a3)
ffffffffc0201708:	0141                	addi	sp,sp,16
ffffffffc020170a:	8082                	ret
        assert(PageReserved(p));
ffffffffc020170c:	00001697          	auipc	a3,0x1
ffffffffc0201710:	a5468693          	addi	a3,a3,-1452 # ffffffffc0202160 <etext+0x2a0>
ffffffffc0201714:	00001617          	auipc	a2,0x1
ffffffffc0201718:	8ec60613          	addi	a2,a2,-1812 # ffffffffc0202000 <etext+0x140>
ffffffffc020171c:	45d9                	li	a1,22
ffffffffc020171e:	00001517          	auipc	a0,0x1
ffffffffc0201722:	fc250513          	addi	a0,a0,-62 # ffffffffc02026e0 <etext+0x820>
ffffffffc0201726:	f01fe0ef          	jal	ffffffffc0200626 <__panic>
    assert(n > 0);
ffffffffc020172a:	00001697          	auipc	a3,0x1
ffffffffc020172e:	fae68693          	addi	a3,a3,-82 # ffffffffc02026d8 <etext+0x818>
ffffffffc0201732:	00001617          	auipc	a2,0x1
ffffffffc0201736:	8ce60613          	addi	a2,a2,-1842 # ffffffffc0202000 <etext+0x140>
ffffffffc020173a:	45cd                	li	a1,19
ffffffffc020173c:	00001517          	auipc	a0,0x1
ffffffffc0201740:	fa450513          	addi	a0,a0,-92 # ffffffffc02026e0 <etext+0x820>
ffffffffc0201744:	ee3fe0ef          	jal	ffffffffc0200626 <__panic>

ffffffffc0201748 <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc0201748:	00005797          	auipc	a5,0x5
ffffffffc020174c:	9007b783          	ld	a5,-1792(a5) # ffffffffc0206048 <pmm_manager>
ffffffffc0201750:	6f9c                	ld	a5,24(a5)
ffffffffc0201752:	8782                	jr	a5

ffffffffc0201754 <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc0201754:	00005797          	auipc	a5,0x5
ffffffffc0201758:	8f47b783          	ld	a5,-1804(a5) # ffffffffc0206048 <pmm_manager>
ffffffffc020175c:	739c                	ld	a5,32(a5)
ffffffffc020175e:	8782                	jr	a5

ffffffffc0201760 <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc0201760:	00005797          	auipc	a5,0x5
ffffffffc0201764:	8e87b783          	ld	a5,-1816(a5) # ffffffffc0206048 <pmm_manager>
ffffffffc0201768:	779c                	ld	a5,40(a5)
ffffffffc020176a:	8782                	jr	a5

ffffffffc020176c <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc020176c:	00001797          	auipc	a5,0x1
ffffffffc0201770:	59c78793          	addi	a5,a5,1436 # ffffffffc0202d08 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201774:	638c                	ld	a1,0(a5)
    }
    init_memmap(pa2page(freemem), (maxpa - freemem) / PGSIZE);
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0201776:	7179                	addi	sp,sp,-48
ffffffffc0201778:	f406                	sd	ra,40(sp)
ffffffffc020177a:	f022                	sd	s0,32(sp)
ffffffffc020177c:	ec26                	sd	s1,24(sp)
ffffffffc020177e:	e44e                	sd	s3,8(sp)
ffffffffc0201780:	e84a                	sd	s2,16(sp)
ffffffffc0201782:	e052                	sd	s4,0(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0201784:	00005417          	auipc	s0,0x5
ffffffffc0201788:	8c440413          	addi	s0,s0,-1852 # ffffffffc0206048 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020178c:	00001517          	auipc	a0,0x1
ffffffffc0201790:	2cc50513          	addi	a0,a0,716 # ffffffffc0202a58 <etext+0xb98>
    pmm_manager = &default_pmm_manager;
ffffffffc0201794:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201796:	9b5fe0ef          	jal	ffffffffc020014a <cprintf>
    pmm_manager->init();
ffffffffc020179a:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020179c:	00005497          	auipc	s1,0x5
ffffffffc02017a0:	8c448493          	addi	s1,s1,-1852 # ffffffffc0206060 <va_pa_offset>
    pmm_manager->init();
ffffffffc02017a4:	679c                	ld	a5,8(a5)
ffffffffc02017a6:	9782                	jalr	a5
    uint64_t mem_base = get_memory_base();
ffffffffc02017a8:	c7eff0ef          	jal	ffffffffc0200c26 <get_memory_base>
ffffffffc02017ac:	89aa                	mv	s3,a0
    uint64_t mem_size = get_memory_size();
ffffffffc02017ae:	c82ff0ef          	jal	ffffffffc0200c30 <get_memory_size>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02017b2:	57f5                	li	a5,-3
ffffffffc02017b4:	07fa                	slli	a5,a5,0x1e
ffffffffc02017b6:	e09c                	sd	a5,0(s1)
    if (mem_base == 0 || mem_size == 0 ||
ffffffffc02017b8:	1c098363          	beqz	s3,ffffffffc020197e <pmm_init+0x212>
ffffffffc02017bc:	8a2a                	mv	s4,a0
ffffffffc02017be:	1c050063          	beqz	a0,ffffffffc020197e <pmm_init+0x212>
ffffffffc02017c2:	00a98933          	add	s2,s3,a0
ffffffffc02017c6:	1b396c63          	bltu	s2,s3,ffffffffc020197e <pmm_init+0x212>
    if (mem_base < DRAM_BASE || mem_base > KERNEL_BEGIN_PADDR ||
ffffffffc02017ca:	800007b7          	lui	a5,0x80000
ffffffffc02017ce:	97ce                	add	a5,a5,s3
ffffffffc02017d0:	00200737          	lui	a4,0x200
ffffffffc02017d4:	18f76963          	bltu	a4,a5,ffffffffc0201966 <pmm_init+0x1fa>
ffffffffc02017d8:	40100793          	li	a5,1025
ffffffffc02017dc:	07d6                	slli	a5,a5,0x15
ffffffffc02017de:	1927f463          	bgeu	a5,s2,ffffffffc0201966 <pmm_init+0x1fa>
    cprintf("physical memory map:\n");
ffffffffc02017e2:	00001517          	auipc	a0,0x1
ffffffffc02017e6:	30650513          	addi	a0,a0,774 # ffffffffc0202ae8 <etext+0xc28>
ffffffffc02017ea:	961fe0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n",
ffffffffc02017ee:	864e                	mv	a2,s3
ffffffffc02017f0:	85d2                	mv	a1,s4
ffffffffc02017f2:	fff90693          	addi	a3,s2,-1
ffffffffc02017f6:	00001517          	auipc	a0,0x1
ffffffffc02017fa:	30a50513          	addi	a0,a0,778 # ffffffffc0202b00 <etext+0xc40>
ffffffffc02017fe:	94dfe0ef          	jal	ffffffffc020014a <cprintf>
    uintptr_t maxpa = ROUNDDOWN(
ffffffffc0201802:	47c5                	li	a5,17
ffffffffc0201804:	07ee                	slli	a5,a5,0x1b
ffffffffc0201806:	1527ee63          	bltu	a5,s2,ffffffffc0201962 <pmm_init+0x1f6>
ffffffffc020180a:	77fd                	lui	a5,0xfffff
ffffffffc020180c:	00f975b3          	and	a1,s2,a5
    pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);
ffffffffc0201810:	00006697          	auipc	a3,0x6
ffffffffc0201814:	86768693          	addi	a3,a3,-1945 # ffffffffc0207077 <end+0xfff>
ffffffffc0201818:	8efd                	and	a3,a3,a5
    npage = PPN(maxpa); // physical page-number upper bound, not the RAM page count
ffffffffc020181a:	00c5d893          	srli	a7,a1,0xc
    pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);
ffffffffc020181e:	00005797          	auipc	a5,0x5
ffffffffc0201822:	84d7b923          	sd	a3,-1966(a5) # ffffffffc0206070 <pages>
    npage = PPN(maxpa); // physical page-number upper bound, not the RAM page count
ffffffffc0201826:	00005797          	auipc	a5,0x5
ffffffffc020182a:	8517b123          	sd	a7,-1982(a5) # ffffffffc0206068 <npage>
    uintptr_t pages_pa = PADDR(pages);
ffffffffc020182e:	c02007b7          	lui	a5,0xc0200
    pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);
ffffffffc0201832:	8836                	mv	a6,a3
    uintptr_t pages_pa = PADDR(pages);
ffffffffc0201834:	16f6ed63          	bltu	a3,a5,ffffffffc02019ae <pmm_init+0x242>
ffffffffc0201838:	0004b303          	ld	t1,0(s1)
    if (pages_pa < KERNEL_BEGIN_PADDR || pages_pa >= maxpa ||
ffffffffc020183c:	40100793          	li	a5,1025
    size_t page_count = npage - nbase;
ffffffffc0201840:	fff80537          	lui	a0,0xfff80
    if (pages_pa < KERNEL_BEGIN_PADDR || pages_pa >= maxpa ||
ffffffffc0201844:	07d6                	slli	a5,a5,0x15
    uintptr_t pages_pa = PADDR(pages);
ffffffffc0201846:	40668733          	sub	a4,a3,t1
    size_t page_count = npage - nbase;
ffffffffc020184a:	9546                	add	a0,a0,a7
    if (pages_pa < KERNEL_BEGIN_PADDR || pages_pa >= maxpa ||
ffffffffc020184c:	14f76563          	bltu	a4,a5,ffffffffc0201996 <pmm_init+0x22a>
ffffffffc0201850:	14b77363          	bgeu	a4,a1,ffffffffc0201996 <pmm_init+0x22a>
        page_count > (maxpa - pages_pa) / sizeof(struct Page)) {
ffffffffc0201854:	ccccd737          	lui	a4,0xccccd
ffffffffc0201858:	ccd70713          	addi	a4,a4,-819 # ffffffffcccccccd <end+0xcac6c55>
ffffffffc020185c:	02071613          	slli	a2,a4,0x20
ffffffffc0201860:	40d307b3          	sub	a5,t1,a3
ffffffffc0201864:	9732                	add	a4,a4,a2
ffffffffc0201866:	97ae                	add	a5,a5,a1
ffffffffc0201868:	02e7b7b3          	mulhu	a5,a5,a4
ffffffffc020186c:	8395                	srli	a5,a5,0x5
    if (pages_pa < KERNEL_BEGIN_PADDR || pages_pa >= maxpa ||
ffffffffc020186e:	12a7e463          	bltu	a5,a0,ffffffffc0201996 <pmm_init+0x22a>
ffffffffc0201872:	00289713          	slli	a4,a7,0x2
ffffffffc0201876:	9746                	add	a4,a4,a7
ffffffffc0201878:	fec007b7          	lui	a5,0xfec00
ffffffffc020187c:	070e                	slli	a4,a4,0x3
ffffffffc020187e:	97b6                	add	a5,a5,a3
ffffffffc0201880:	973e                	add	a4,a4,a5
        SetPageReserved(p);
ffffffffc0201882:	4605                	li	a2,1
        list_init(&p->page_link);
ffffffffc0201884:	01868793          	addi	a5,a3,24
        p->property = 0;
ffffffffc0201888:	0006a823          	sw	zero,16(a3)
ffffffffc020188c:	0006a023          	sw	zero,0(a3)
        SetPageReserved(p);
ffffffffc0201890:	e690                	sd	a2,8(a3)
    elm->prev = elm->next = elm;
ffffffffc0201892:	f29c                	sd	a5,32(a3)
ffffffffc0201894:	ee9c                	sd	a5,24(a3)
    for (size_t i = 0; i < page_count; i++) {
ffffffffc0201896:	02868693          	addi	a3,a3,40
ffffffffc020189a:	fee695e3          	bne	a3,a4,ffffffffc0201884 <pmm_init+0x118>
    uintptr_t freemem = ROUNDUP(PADDR(pages + page_count), PGSIZE);
ffffffffc020189e:	00251693          	slli	a3,a0,0x2
ffffffffc02018a2:	96aa                	add	a3,a3,a0
ffffffffc02018a4:	068e                	slli	a3,a3,0x3
ffffffffc02018a6:	96c2                	add	a3,a3,a6
ffffffffc02018a8:	c02007b7          	lui	a5,0xc0200
ffffffffc02018ac:	16f6e263          	bltu	a3,a5,ffffffffc0201a10 <pmm_init+0x2a4>
ffffffffc02018b0:	6785                	lui	a5,0x1
ffffffffc02018b2:	17fd                	addi	a5,a5,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc02018b4:	406787b3          	sub	a5,a5,t1
ffffffffc02018b8:	97b6                	add	a5,a5,a3
ffffffffc02018ba:	777d                	lui	a4,0xfffff
ffffffffc02018bc:	8ff9                	and	a5,a5,a4
    if (freemem >= maxpa) {
ffffffffc02018be:	12b7fd63          	bgeu	a5,a1,ffffffffc02019f8 <pmm_init+0x28c>
    if (PPN(pa) >= npage) {
ffffffffc02018c2:	00c7d713          	srli	a4,a5,0xc
ffffffffc02018c6:	11177d63          	bgeu	a4,a7,ffffffffc02019e0 <pmm_init+0x274>
    pmm_manager->init_memmap(base, n);
ffffffffc02018ca:	6014                	ld	a3,0(s0)
    return &pages[PPN(pa) - nbase];
ffffffffc02018cc:	fff80637          	lui	a2,0xfff80
ffffffffc02018d0:	9732                	add	a4,a4,a2
ffffffffc02018d2:	00271513          	slli	a0,a4,0x2
ffffffffc02018d6:	953a                	add	a0,a0,a4
ffffffffc02018d8:	6a98                	ld	a4,16(a3)
    init_memmap(pa2page(freemem), (maxpa - freemem) / PGSIZE);
ffffffffc02018da:	8d9d                	sub	a1,a1,a5
ffffffffc02018dc:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02018de:	81b1                	srli	a1,a1,0xc
ffffffffc02018e0:	9542                	add	a0,a0,a6
ffffffffc02018e2:	9702                	jalr	a4
    // detect physical memory space, reserve already used memory,
    // then use pmm->init_memmap to create free page list
    page_init();
    extern void test_page_init(void);
    extern void test_page_init_extra(void);
    if (get_memory_base() + get_memory_size() <= PHYSICAL_MEMORY_END) {
ffffffffc02018e4:	b42ff0ef          	jal	ffffffffc0200c26 <get_memory_base>
ffffffffc02018e8:	892a                	mv	s2,a0
ffffffffc02018ea:	b46ff0ef          	jal	ffffffffc0200c30 <get_memory_size>
ffffffffc02018ee:	47c5                	li	a5,17
ffffffffc02018f0:	992a                	add	s2,s2,a0
ffffffffc02018f2:	07ee                	slli	a5,a5,0x1b
ffffffffc02018f4:	0727e063          	bltu	a5,s2,ffffffffc0201954 <pmm_init+0x1e8>
        test_page_init();
ffffffffc02018f8:	da3fe0ef          	jal	ffffffffc020069a <test_page_init>
    } else {
        cprintf("[Test 1] SKIP: original test assumes uncapped RAM; extra test checks cap\n");
    }
    test_page_init_extra();
ffffffffc02018fc:	8d1fe0ef          	jal	ffffffffc02001cc <test_page_init_extra>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201900:	601c                	ld	a5,0(s0)
ffffffffc0201902:	7b9c                	ld	a5,48(a5)
ffffffffc0201904:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201906:	00001517          	auipc	a0,0x1
ffffffffc020190a:	2ca50513          	addi	a0,a0,714 # ffffffffc0202bd0 <etext+0xd10>
ffffffffc020190e:	83dfe0ef          	jal	ffffffffc020014a <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0201912:	00003597          	auipc	a1,0x3
ffffffffc0201916:	6ee58593          	addi	a1,a1,1774 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc020191a:	00004797          	auipc	a5,0x4
ffffffffc020191e:	72b7bf23          	sd	a1,1854(a5) # ffffffffc0206058 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201922:	c02007b7          	lui	a5,0xc0200
ffffffffc0201926:	0af5e063          	bltu	a1,a5,ffffffffc02019c6 <pmm_init+0x25a>
ffffffffc020192a:	609c                	ld	a5,0(s1)
}
ffffffffc020192c:	7402                	ld	s0,32(sp)
ffffffffc020192e:	70a2                	ld	ra,40(sp)
ffffffffc0201930:	64e2                	ld	s1,24(sp)
ffffffffc0201932:	6942                	ld	s2,16(sp)
ffffffffc0201934:	69a2                	ld	s3,8(sp)
ffffffffc0201936:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0201938:	40f586b3          	sub	a3,a1,a5
ffffffffc020193c:	00004797          	auipc	a5,0x4
ffffffffc0201940:	70d7ba23          	sd	a3,1812(a5) # ffffffffc0206050 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201944:	00001517          	auipc	a0,0x1
ffffffffc0201948:	2ac50513          	addi	a0,a0,684 # ffffffffc0202bf0 <etext+0xd30>
ffffffffc020194c:	8636                	mv	a2,a3
}
ffffffffc020194e:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201950:	ffafe06f          	j	ffffffffc020014a <cprintf>
        cprintf("[Test 1] SKIP: original test assumes uncapped RAM; extra test checks cap\n");
ffffffffc0201954:	00001517          	auipc	a0,0x1
ffffffffc0201958:	22c50513          	addi	a0,a0,556 # ffffffffc0202b80 <etext+0xcc0>
ffffffffc020195c:	feefe0ef          	jal	ffffffffc020014a <cprintf>
ffffffffc0201960:	bf71                	j	ffffffffc02018fc <pmm_init+0x190>
    uintptr_t maxpa = ROUNDDOWN(
ffffffffc0201962:	893e                	mv	s2,a5
ffffffffc0201964:	b55d                	j	ffffffffc020180a <pmm_init+0x9e>
        panic("page_init: physical memory does not cover the kernel");
ffffffffc0201966:	00001617          	auipc	a2,0x1
ffffffffc020196a:	14a60613          	addi	a2,a2,330 # ffffffffc0202ab0 <etext+0xbf0>
ffffffffc020196e:	04e00593          	li	a1,78
ffffffffc0201972:	00001517          	auipc	a0,0x1
ffffffffc0201976:	12e50513          	addi	a0,a0,302 # ffffffffc0202aa0 <etext+0xbe0>
ffffffffc020197a:	cadfe0ef          	jal	ffffffffc0200626 <__panic>
        panic("page_init: invalid physical memory information");
ffffffffc020197e:	00001617          	auipc	a2,0x1
ffffffffc0201982:	0f260613          	addi	a2,a2,242 # ffffffffc0202a70 <etext+0xbb0>
ffffffffc0201986:	04900593          	li	a1,73
ffffffffc020198a:	00001517          	auipc	a0,0x1
ffffffffc020198e:	11650513          	addi	a0,a0,278 # ffffffffc0202aa0 <etext+0xbe0>
ffffffffc0201992:	c95fe0ef          	jal	ffffffffc0200626 <__panic>
        panic("page_init: no room for page descriptors");
ffffffffc0201996:	00001617          	auipc	a2,0x1
ffffffffc020199a:	19a60613          	addi	a2,a2,410 # ffffffffc0202b30 <etext+0xc70>
ffffffffc020199e:	05e00593          	li	a1,94
ffffffffc02019a2:	00001517          	auipc	a0,0x1
ffffffffc02019a6:	0fe50513          	addi	a0,a0,254 # ffffffffc0202aa0 <etext+0xbe0>
ffffffffc02019aa:	c7dfe0ef          	jal	ffffffffc0200626 <__panic>
    uintptr_t pages_pa = PADDR(pages);
ffffffffc02019ae:	00000617          	auipc	a2,0x0
ffffffffc02019b2:	5e260613          	addi	a2,a2,1506 # ffffffffc0201f90 <etext+0xd0>
ffffffffc02019b6:	05a00593          	li	a1,90
ffffffffc02019ba:	00001517          	auipc	a0,0x1
ffffffffc02019be:	0e650513          	addi	a0,a0,230 # ffffffffc0202aa0 <etext+0xbe0>
ffffffffc02019c2:	c65fe0ef          	jal	ffffffffc0200626 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02019c6:	86ae                	mv	a3,a1
ffffffffc02019c8:	00000617          	auipc	a2,0x0
ffffffffc02019cc:	5c860613          	addi	a2,a2,1480 # ffffffffc0201f90 <etext+0xd0>
ffffffffc02019d0:	08d00593          	li	a1,141
ffffffffc02019d4:	00001517          	auipc	a0,0x1
ffffffffc02019d8:	0cc50513          	addi	a0,a0,204 # ffffffffc0202aa0 <etext+0xbe0>
ffffffffc02019dc:	c4bfe0ef          	jal	ffffffffc0200626 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02019e0:	00000617          	auipc	a2,0x0
ffffffffc02019e4:	6b060613          	addi	a2,a2,1712 # ffffffffc0202090 <etext+0x1d0>
ffffffffc02019e8:	06a00593          	li	a1,106
ffffffffc02019ec:	00000517          	auipc	a0,0x0
ffffffffc02019f0:	6c450513          	addi	a0,a0,1732 # ffffffffc02020b0 <etext+0x1f0>
ffffffffc02019f4:	c33fe0ef          	jal	ffffffffc0200626 <__panic>
        panic("page_init: no complete free pages");
ffffffffc02019f8:	00001617          	auipc	a2,0x1
ffffffffc02019fc:	16060613          	addi	a2,a2,352 # ffffffffc0202b58 <etext+0xc98>
ffffffffc0201a00:	06e00593          	li	a1,110
ffffffffc0201a04:	00001517          	auipc	a0,0x1
ffffffffc0201a08:	09c50513          	addi	a0,a0,156 # ffffffffc0202aa0 <etext+0xbe0>
ffffffffc0201a0c:	c1bfe0ef          	jal	ffffffffc0200626 <__panic>
    uintptr_t freemem = ROUNDUP(PADDR(pages + page_count), PGSIZE);
ffffffffc0201a10:	00000617          	auipc	a2,0x0
ffffffffc0201a14:	58060613          	addi	a2,a2,1408 # ffffffffc0201f90 <etext+0xd0>
ffffffffc0201a18:	06c00593          	li	a1,108
ffffffffc0201a1c:	00001517          	auipc	a0,0x1
ffffffffc0201a20:	08450513          	addi	a0,a0,132 # ffffffffc0202aa0 <etext+0xbe0>
ffffffffc0201a24:	c03fe0ef          	jal	ffffffffc0200626 <__panic>

ffffffffc0201a28 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201a28:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a2c:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201a2e:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a32:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201a34:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a38:	f022                	sd	s0,32(sp)
ffffffffc0201a3a:	ec26                	sd	s1,24(sp)
ffffffffc0201a3c:	e84a                	sd	s2,16(sp)
ffffffffc0201a3e:	f406                	sd	ra,40(sp)
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201a40:	fff7041b          	addiw	s0,a4,-1 # ffffffffffffefff <end+0x3fdf8f87>
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a44:	84aa                	mv	s1,a0
ffffffffc0201a46:	892e                	mv	s2,a1
    unsigned mod = do_div(result, base);
ffffffffc0201a48:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201a4a:	05067063          	bgeu	a2,a6,ffffffffc0201a8a <printnum+0x62>
ffffffffc0201a4e:	e44e                	sd	s3,8(sp)
ffffffffc0201a50:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201a52:	4785                	li	a5,1
ffffffffc0201a54:	00e7d763          	bge	a5,a4,ffffffffc0201a62 <printnum+0x3a>
            putch(padc, putdat);
ffffffffc0201a58:	85ca                	mv	a1,s2
ffffffffc0201a5a:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc0201a5c:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201a5e:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201a60:	fc65                	bnez	s0,ffffffffc0201a58 <printnum+0x30>
ffffffffc0201a62:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a64:	1a02                	slli	s4,s4,0x20
ffffffffc0201a66:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201a6a:	00001797          	auipc	a5,0x1
ffffffffc0201a6e:	1c678793          	addi	a5,a5,454 # ffffffffc0202c30 <etext+0xd70>
ffffffffc0201a72:	97d2                	add	a5,a5,s4
}
ffffffffc0201a74:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a76:	0007c503          	lbu	a0,0(a5)
}
ffffffffc0201a7a:	70a2                	ld	ra,40(sp)
ffffffffc0201a7c:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a7e:	85ca                	mv	a1,s2
ffffffffc0201a80:	87a6                	mv	a5,s1
}
ffffffffc0201a82:	6942                	ld	s2,16(sp)
ffffffffc0201a84:	64e2                	ld	s1,24(sp)
ffffffffc0201a86:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a88:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201a8a:	03065633          	divu	a2,a2,a6
ffffffffc0201a8e:	8722                	mv	a4,s0
ffffffffc0201a90:	f99ff0ef          	jal	ffffffffc0201a28 <printnum>
ffffffffc0201a94:	bfc1                	j	ffffffffc0201a64 <printnum+0x3c>

ffffffffc0201a96 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201a96:	7119                	addi	sp,sp,-128
ffffffffc0201a98:	f4a6                	sd	s1,104(sp)
ffffffffc0201a9a:	f0ca                	sd	s2,96(sp)
ffffffffc0201a9c:	ecce                	sd	s3,88(sp)
ffffffffc0201a9e:	e8d2                	sd	s4,80(sp)
ffffffffc0201aa0:	e4d6                	sd	s5,72(sp)
ffffffffc0201aa2:	e0da                	sd	s6,64(sp)
ffffffffc0201aa4:	f862                	sd	s8,48(sp)
ffffffffc0201aa6:	fc86                	sd	ra,120(sp)
ffffffffc0201aa8:	f8a2                	sd	s0,112(sp)
ffffffffc0201aaa:	fc5e                	sd	s7,56(sp)
ffffffffc0201aac:	f466                	sd	s9,40(sp)
ffffffffc0201aae:	f06a                	sd	s10,32(sp)
ffffffffc0201ab0:	ec6e                	sd	s11,24(sp)
ffffffffc0201ab2:	892a                	mv	s2,a0
ffffffffc0201ab4:	84ae                	mv	s1,a1
ffffffffc0201ab6:	8c32                	mv	s8,a2
ffffffffc0201ab8:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201aba:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201abe:	05500b13          	li	s6,85
ffffffffc0201ac2:	00001a97          	auipc	s5,0x1
ffffffffc0201ac6:	27ea8a93          	addi	s5,s5,638 # ffffffffc0202d40 <default_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201aca:	000c4503          	lbu	a0,0(s8)
ffffffffc0201ace:	001c0413          	addi	s0,s8,1
ffffffffc0201ad2:	01350a63          	beq	a0,s3,ffffffffc0201ae6 <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0201ad6:	cd0d                	beqz	a0,ffffffffc0201b10 <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0201ad8:	85a6                	mv	a1,s1
ffffffffc0201ada:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201adc:	00044503          	lbu	a0,0(s0)
ffffffffc0201ae0:	0405                	addi	s0,s0,1
ffffffffc0201ae2:	ff351ae3          	bne	a0,s3,ffffffffc0201ad6 <vprintfmt+0x40>
        width = precision = -1;
ffffffffc0201ae6:	5cfd                	li	s9,-1
ffffffffc0201ae8:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc0201aea:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc0201aee:	4b81                	li	s7,0
ffffffffc0201af0:	4601                	li	a2,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201af2:	00044683          	lbu	a3,0(s0)
ffffffffc0201af6:	00140c13          	addi	s8,s0,1
ffffffffc0201afa:	fdd6859b          	addiw	a1,a3,-35
ffffffffc0201afe:	0ff5f593          	zext.b	a1,a1
ffffffffc0201b02:	02bb6663          	bltu	s6,a1,ffffffffc0201b2e <vprintfmt+0x98>
ffffffffc0201b06:	058a                	slli	a1,a1,0x2
ffffffffc0201b08:	95d6                	add	a1,a1,s5
ffffffffc0201b0a:	4198                	lw	a4,0(a1)
ffffffffc0201b0c:	9756                	add	a4,a4,s5
ffffffffc0201b0e:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201b10:	70e6                	ld	ra,120(sp)
ffffffffc0201b12:	7446                	ld	s0,112(sp)
ffffffffc0201b14:	74a6                	ld	s1,104(sp)
ffffffffc0201b16:	7906                	ld	s2,96(sp)
ffffffffc0201b18:	69e6                	ld	s3,88(sp)
ffffffffc0201b1a:	6a46                	ld	s4,80(sp)
ffffffffc0201b1c:	6aa6                	ld	s5,72(sp)
ffffffffc0201b1e:	6b06                	ld	s6,64(sp)
ffffffffc0201b20:	7be2                	ld	s7,56(sp)
ffffffffc0201b22:	7c42                	ld	s8,48(sp)
ffffffffc0201b24:	7ca2                	ld	s9,40(sp)
ffffffffc0201b26:	7d02                	ld	s10,32(sp)
ffffffffc0201b28:	6de2                	ld	s11,24(sp)
ffffffffc0201b2a:	6109                	addi	sp,sp,128
ffffffffc0201b2c:	8082                	ret
            putch('%', putdat);
ffffffffc0201b2e:	85a6                	mv	a1,s1
ffffffffc0201b30:	02500513          	li	a0,37
ffffffffc0201b34:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201b36:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201b3a:	02500713          	li	a4,37
ffffffffc0201b3e:	8c22                	mv	s8,s0
ffffffffc0201b40:	f8e785e3          	beq	a5,a4,ffffffffc0201aca <vprintfmt+0x34>
ffffffffc0201b44:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0201b48:	1c7d                	addi	s8,s8,-1
ffffffffc0201b4a:	fee79de3          	bne	a5,a4,ffffffffc0201b44 <vprintfmt+0xae>
ffffffffc0201b4e:	bfb5                	j	ffffffffc0201aca <vprintfmt+0x34>
                ch = *fmt;
ffffffffc0201b50:	00144783          	lbu	a5,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc0201b54:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc0201b56:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0201b5a:	fd07871b          	addiw	a4,a5,-48
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b5e:	8462                	mv	s0,s8
                ch = *fmt;
ffffffffc0201b60:	2781                	sext.w	a5,a5
                if (ch < '0' || ch > '9') {
ffffffffc0201b62:	02e56463          	bltu	a0,a4,ffffffffc0201b8a <vprintfmt+0xf4>
                precision = precision * 10 + ch - '0';
ffffffffc0201b66:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc0201b6a:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201b6e:	0197073b          	addw	a4,a4,s9
ffffffffc0201b72:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201b76:	9f3d                	addw	a4,a4,a5
                if (ch < '0' || ch > '9') {
ffffffffc0201b78:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201b7c:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201b7e:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0201b82:	0006879b          	sext.w	a5,a3
                if (ch < '0' || ch > '9') {
ffffffffc0201b86:	feb570e3          	bgeu	a0,a1,ffffffffc0201b66 <vprintfmt+0xd0>
            if (width < 0)
ffffffffc0201b8a:	f60d54e3          	bgez	s10,ffffffffc0201af2 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc0201b8e:	8d66                	mv	s10,s9
ffffffffc0201b90:	5cfd                	li	s9,-1
ffffffffc0201b92:	b785                	j	ffffffffc0201af2 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b94:	8db6                	mv	s11,a3
ffffffffc0201b96:	8462                	mv	s0,s8
ffffffffc0201b98:	bfa9                	j	ffffffffc0201af2 <vprintfmt+0x5c>
ffffffffc0201b9a:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0201b9c:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0201b9e:	bf91                	j	ffffffffc0201af2 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc0201ba0:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201ba2:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc0201ba6:	00c7c463          	blt	a5,a2,ffffffffc0201bae <vprintfmt+0x118>
    else if (lflag) {
ffffffffc0201baa:	18060763          	beqz	a2,ffffffffc0201d38 <vprintfmt+0x2a2>
        return va_arg(*ap, unsigned long);
ffffffffc0201bae:	000a3603          	ld	a2,0(s4)
ffffffffc0201bb2:	46c1                	li	a3,16
ffffffffc0201bb4:	8a3a                	mv	s4,a4
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201bb6:	000d879b          	sext.w	a5,s11
ffffffffc0201bba:	876a                	mv	a4,s10
ffffffffc0201bbc:	85a6                	mv	a1,s1
ffffffffc0201bbe:	854a                	mv	a0,s2
ffffffffc0201bc0:	e69ff0ef          	jal	ffffffffc0201a28 <printnum>
            break;
ffffffffc0201bc4:	b719                	j	ffffffffc0201aca <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0201bc6:	000a2503          	lw	a0,0(s4)
ffffffffc0201bca:	85a6                	mv	a1,s1
ffffffffc0201bcc:	0a21                	addi	s4,s4,8
ffffffffc0201bce:	9902                	jalr	s2
            break;
ffffffffc0201bd0:	bded                	j	ffffffffc0201aca <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0201bd2:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201bd4:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc0201bd8:	00c7c463          	blt	a5,a2,ffffffffc0201be0 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc0201bdc:	14060963          	beqz	a2,ffffffffc0201d2e <vprintfmt+0x298>
        return va_arg(*ap, unsigned long);
ffffffffc0201be0:	000a3603          	ld	a2,0(s4)
ffffffffc0201be4:	46a9                	li	a3,10
ffffffffc0201be6:	8a3a                	mv	s4,a4
ffffffffc0201be8:	b7f9                	j	ffffffffc0201bb6 <vprintfmt+0x120>
            putch('0', putdat);
ffffffffc0201bea:	85a6                	mv	a1,s1
ffffffffc0201bec:	03000513          	li	a0,48
ffffffffc0201bf0:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201bf2:	85a6                	mv	a1,s1
ffffffffc0201bf4:	07800513          	li	a0,120
ffffffffc0201bf8:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201bfa:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc0201bfe:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201c00:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201c02:	bf55                	j	ffffffffc0201bb6 <vprintfmt+0x120>
            putch(ch, putdat);
ffffffffc0201c04:	85a6                	mv	a1,s1
ffffffffc0201c06:	02500513          	li	a0,37
ffffffffc0201c0a:	9902                	jalr	s2
            break;
ffffffffc0201c0c:	bd7d                	j	ffffffffc0201aca <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc0201c0e:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c12:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0201c14:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc0201c16:	bf95                	j	ffffffffc0201b8a <vprintfmt+0xf4>
    if (lflag >= 2) {
ffffffffc0201c18:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201c1a:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc0201c1e:	00c7c463          	blt	a5,a2,ffffffffc0201c26 <vprintfmt+0x190>
    else if (lflag) {
ffffffffc0201c22:	10060163          	beqz	a2,ffffffffc0201d24 <vprintfmt+0x28e>
        return va_arg(*ap, unsigned long);
ffffffffc0201c26:	000a3603          	ld	a2,0(s4)
ffffffffc0201c2a:	46a1                	li	a3,8
ffffffffc0201c2c:	8a3a                	mv	s4,a4
ffffffffc0201c2e:	b761                	j	ffffffffc0201bb6 <vprintfmt+0x120>
            if (width < 0)
ffffffffc0201c30:	87ea                	mv	a5,s10
ffffffffc0201c32:	000d5363          	bgez	s10,ffffffffc0201c38 <vprintfmt+0x1a2>
ffffffffc0201c36:	4781                	li	a5,0
ffffffffc0201c38:	00078d1b          	sext.w	s10,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c3c:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0201c3e:	bd55                	j	ffffffffc0201af2 <vprintfmt+0x5c>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201c40:	000a3703          	ld	a4,0(s4)
ffffffffc0201c44:	12070b63          	beqz	a4,ffffffffc0201d7a <vprintfmt+0x2e4>
            if (width > 0 && padc != '-') {
ffffffffc0201c48:	0da05563          	blez	s10,ffffffffc0201d12 <vprintfmt+0x27c>
ffffffffc0201c4c:	02d00793          	li	a5,45
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c50:	00170413          	addi	s0,a4,1
            if (width > 0 && padc != '-') {
ffffffffc0201c54:	14fd9a63          	bne	s11,a5,ffffffffc0201da8 <vprintfmt+0x312>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c58:	00074783          	lbu	a5,0(a4)
ffffffffc0201c5c:	0007851b          	sext.w	a0,a5
ffffffffc0201c60:	c785                	beqz	a5,ffffffffc0201c88 <vprintfmt+0x1f2>
ffffffffc0201c62:	5dfd                	li	s11,-1
ffffffffc0201c64:	000cc563          	bltz	s9,ffffffffc0201c6e <vprintfmt+0x1d8>
ffffffffc0201c68:	3cfd                	addiw	s9,s9,-1
ffffffffc0201c6a:	01bc8d63          	beq	s9,s11,ffffffffc0201c84 <vprintfmt+0x1ee>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201c6e:	0c0b9a63          	bnez	s7,ffffffffc0201d42 <vprintfmt+0x2ac>
                    putch(ch, putdat);
ffffffffc0201c72:	85a6                	mv	a1,s1
ffffffffc0201c74:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c76:	00044783          	lbu	a5,0(s0)
ffffffffc0201c7a:	0405                	addi	s0,s0,1
ffffffffc0201c7c:	3d7d                	addiw	s10,s10,-1
ffffffffc0201c7e:	0007851b          	sext.w	a0,a5
ffffffffc0201c82:	f3ed                	bnez	a5,ffffffffc0201c64 <vprintfmt+0x1ce>
            for (; width > 0; width --) {
ffffffffc0201c84:	01a05963          	blez	s10,ffffffffc0201c96 <vprintfmt+0x200>
                putch(' ', putdat);
ffffffffc0201c88:	85a6                	mv	a1,s1
ffffffffc0201c8a:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc0201c8e:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc0201c90:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201c92:	fe0d1be3          	bnez	s10,ffffffffc0201c88 <vprintfmt+0x1f2>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201c96:	0a21                	addi	s4,s4,8
ffffffffc0201c98:	bd0d                	j	ffffffffc0201aca <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0201c9a:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201c9c:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc0201ca0:	00c7c363          	blt	a5,a2,ffffffffc0201ca6 <vprintfmt+0x210>
    else if (lflag) {
ffffffffc0201ca4:	c625                	beqz	a2,ffffffffc0201d0c <vprintfmt+0x276>
        return va_arg(*ap, long);
ffffffffc0201ca6:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201caa:	0a044f63          	bltz	s0,ffffffffc0201d68 <vprintfmt+0x2d2>
            num = getint(&ap, lflag);
ffffffffc0201cae:	8622                	mv	a2,s0
ffffffffc0201cb0:	8a5e                	mv	s4,s7
ffffffffc0201cb2:	46a9                	li	a3,10
ffffffffc0201cb4:	b709                	j	ffffffffc0201bb6 <vprintfmt+0x120>
            if (err < 0) {
ffffffffc0201cb6:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201cba:	4619                	li	a2,6
            if (err < 0) {
ffffffffc0201cbc:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc0201cc0:	8fb9                	xor	a5,a5,a4
ffffffffc0201cc2:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201cc6:	02d64663          	blt	a2,a3,ffffffffc0201cf2 <vprintfmt+0x25c>
ffffffffc0201cca:	00001797          	auipc	a5,0x1
ffffffffc0201cce:	1ce78793          	addi	a5,a5,462 # ffffffffc0202e98 <error_string>
ffffffffc0201cd2:	00369713          	slli	a4,a3,0x3
ffffffffc0201cd6:	97ba                	add	a5,a5,a4
ffffffffc0201cd8:	639c                	ld	a5,0(a5)
ffffffffc0201cda:	cf81                	beqz	a5,ffffffffc0201cf2 <vprintfmt+0x25c>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201cdc:	86be                	mv	a3,a5
ffffffffc0201cde:	00001617          	auipc	a2,0x1
ffffffffc0201ce2:	f8260613          	addi	a2,a2,-126 # ffffffffc0202c60 <etext+0xda0>
ffffffffc0201ce6:	85a6                	mv	a1,s1
ffffffffc0201ce8:	854a                	mv	a0,s2
ffffffffc0201cea:	0f4000ef          	jal	ffffffffc0201dde <printfmt>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201cee:	0a21                	addi	s4,s4,8
ffffffffc0201cf0:	bbe9                	j	ffffffffc0201aca <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201cf2:	00001617          	auipc	a2,0x1
ffffffffc0201cf6:	f5e60613          	addi	a2,a2,-162 # ffffffffc0202c50 <etext+0xd90>
ffffffffc0201cfa:	85a6                	mv	a1,s1
ffffffffc0201cfc:	854a                	mv	a0,s2
ffffffffc0201cfe:	0e0000ef          	jal	ffffffffc0201dde <printfmt>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201d02:	0a21                	addi	s4,s4,8
ffffffffc0201d04:	b3d9                	j	ffffffffc0201aca <vprintfmt+0x34>
            lflag ++;
ffffffffc0201d06:	2605                	addiw	a2,a2,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201d08:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0201d0a:	b3e5                	j	ffffffffc0201af2 <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc0201d0c:	000a2403          	lw	s0,0(s4)
ffffffffc0201d10:	bf69                	j	ffffffffc0201caa <vprintfmt+0x214>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d12:	00074783          	lbu	a5,0(a4)
ffffffffc0201d16:	0007851b          	sext.w	a0,a5
ffffffffc0201d1a:	dfb5                	beqz	a5,ffffffffc0201c96 <vprintfmt+0x200>
ffffffffc0201d1c:	00170413          	addi	s0,a4,1
ffffffffc0201d20:	5dfd                	li	s11,-1
ffffffffc0201d22:	b789                	j	ffffffffc0201c64 <vprintfmt+0x1ce>
        return va_arg(*ap, unsigned int);
ffffffffc0201d24:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d28:	46a1                	li	a3,8
ffffffffc0201d2a:	8a3a                	mv	s4,a4
ffffffffc0201d2c:	b569                	j	ffffffffc0201bb6 <vprintfmt+0x120>
ffffffffc0201d2e:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d32:	46a9                	li	a3,10
ffffffffc0201d34:	8a3a                	mv	s4,a4
ffffffffc0201d36:	b541                	j	ffffffffc0201bb6 <vprintfmt+0x120>
ffffffffc0201d38:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d3c:	46c1                	li	a3,16
ffffffffc0201d3e:	8a3a                	mv	s4,a4
ffffffffc0201d40:	bd9d                	j	ffffffffc0201bb6 <vprintfmt+0x120>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201d42:	3781                	addiw	a5,a5,-32
ffffffffc0201d44:	05e00713          	li	a4,94
ffffffffc0201d48:	f2f775e3          	bgeu	a4,a5,ffffffffc0201c72 <vprintfmt+0x1dc>
                    putch('?', putdat);
ffffffffc0201d4c:	03f00513          	li	a0,63
ffffffffc0201d50:	85a6                	mv	a1,s1
ffffffffc0201d52:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d54:	00044783          	lbu	a5,0(s0)
ffffffffc0201d58:	0405                	addi	s0,s0,1
ffffffffc0201d5a:	3d7d                	addiw	s10,s10,-1
ffffffffc0201d5c:	0007851b          	sext.w	a0,a5
ffffffffc0201d60:	d395                	beqz	a5,ffffffffc0201c84 <vprintfmt+0x1ee>
ffffffffc0201d62:	f00cd3e3          	bgez	s9,ffffffffc0201c68 <vprintfmt+0x1d2>
ffffffffc0201d66:	bff1                	j	ffffffffc0201d42 <vprintfmt+0x2ac>
                putch('-', putdat);
ffffffffc0201d68:	85a6                	mv	a1,s1
ffffffffc0201d6a:	02d00513          	li	a0,45
ffffffffc0201d6e:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201d70:	40800633          	neg	a2,s0
ffffffffc0201d74:	8a5e                	mv	s4,s7
ffffffffc0201d76:	46a9                	li	a3,10
ffffffffc0201d78:	bd3d                	j	ffffffffc0201bb6 <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
ffffffffc0201d7a:	01a05663          	blez	s10,ffffffffc0201d86 <vprintfmt+0x2f0>
ffffffffc0201d7e:	02d00793          	li	a5,45
ffffffffc0201d82:	00fd9b63          	bne	s11,a5,ffffffffc0201d98 <vprintfmt+0x302>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d86:	02800793          	li	a5,40
ffffffffc0201d8a:	853e                	mv	a0,a5
ffffffffc0201d8c:	00001417          	auipc	s0,0x1
ffffffffc0201d90:	ebd40413          	addi	s0,s0,-323 # ffffffffc0202c49 <etext+0xd89>
ffffffffc0201d94:	5dfd                	li	s11,-1
ffffffffc0201d96:	b5f9                	j	ffffffffc0201c64 <vprintfmt+0x1ce>
ffffffffc0201d98:	00001417          	auipc	s0,0x1
ffffffffc0201d9c:	eb140413          	addi	s0,s0,-335 # ffffffffc0202c49 <etext+0xd89>
                p = "(null)";
ffffffffc0201da0:	00001717          	auipc	a4,0x1
ffffffffc0201da4:	ea870713          	addi	a4,a4,-344 # ffffffffc0202c48 <etext+0xd88>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201da8:	853a                	mv	a0,a4
ffffffffc0201daa:	85e6                	mv	a1,s9
ffffffffc0201dac:	e43a                	sd	a4,8(sp)
ffffffffc0201dae:	084000ef          	jal	ffffffffc0201e32 <strnlen>
ffffffffc0201db2:	40ad0d3b          	subw	s10,s10,a0
ffffffffc0201db6:	6722                	ld	a4,8(sp)
ffffffffc0201db8:	01a05b63          	blez	s10,ffffffffc0201dce <vprintfmt+0x338>
                    putch(padc, putdat);
ffffffffc0201dbc:	2d81                	sext.w	s11,s11
ffffffffc0201dbe:	85a6                	mv	a1,s1
ffffffffc0201dc0:	856e                	mv	a0,s11
ffffffffc0201dc2:	e43a                	sd	a4,8(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201dc4:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc0201dc6:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201dc8:	6722                	ld	a4,8(sp)
ffffffffc0201dca:	fe0d1ae3          	bnez	s10,ffffffffc0201dbe <vprintfmt+0x328>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201dce:	00074783          	lbu	a5,0(a4)
ffffffffc0201dd2:	0007851b          	sext.w	a0,a5
ffffffffc0201dd6:	ec0780e3          	beqz	a5,ffffffffc0201c96 <vprintfmt+0x200>
ffffffffc0201dda:	5dfd                	li	s11,-1
ffffffffc0201ddc:	b561                	j	ffffffffc0201c64 <vprintfmt+0x1ce>

ffffffffc0201dde <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201dde:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201de0:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201de4:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201de6:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201de8:	ec06                	sd	ra,24(sp)
ffffffffc0201dea:	f83a                	sd	a4,48(sp)
ffffffffc0201dec:	fc3e                	sd	a5,56(sp)
ffffffffc0201dee:	e0c2                	sd	a6,64(sp)
ffffffffc0201df0:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201df2:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201df4:	ca3ff0ef          	jal	ffffffffc0201a96 <vprintfmt>
}
ffffffffc0201df8:	60e2                	ld	ra,24(sp)
ffffffffc0201dfa:	6161                	addi	sp,sp,80
ffffffffc0201dfc:	8082                	ret

ffffffffc0201dfe <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201dfe:	00004717          	auipc	a4,0x4
ffffffffc0201e02:	21273703          	ld	a4,530(a4) # ffffffffc0206010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201e06:	4781                	li	a5,0
ffffffffc0201e08:	88ba                	mv	a7,a4
ffffffffc0201e0a:	852a                	mv	a0,a0
ffffffffc0201e0c:	85be                	mv	a1,a5
ffffffffc0201e0e:	863e                	mv	a2,a5
ffffffffc0201e10:	00000073          	ecall
ffffffffc0201e14:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201e16:	8082                	ret

ffffffffc0201e18 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201e18:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201e1c:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201e1e:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201e20:	cb81                	beqz	a5,ffffffffc0201e30 <strlen+0x18>
        cnt ++;
ffffffffc0201e22:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201e24:	00a707b3          	add	a5,a4,a0
ffffffffc0201e28:	0007c783          	lbu	a5,0(a5)
ffffffffc0201e2c:	fbfd                	bnez	a5,ffffffffc0201e22 <strlen+0xa>
ffffffffc0201e2e:	8082                	ret
    }
    return cnt;
}
ffffffffc0201e30:	8082                	ret

ffffffffc0201e32 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201e32:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201e34:	e589                	bnez	a1,ffffffffc0201e3e <strnlen+0xc>
ffffffffc0201e36:	a811                	j	ffffffffc0201e4a <strnlen+0x18>
        cnt ++;
ffffffffc0201e38:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201e3a:	00f58863          	beq	a1,a5,ffffffffc0201e4a <strnlen+0x18>
ffffffffc0201e3e:	00f50733          	add	a4,a0,a5
ffffffffc0201e42:	00074703          	lbu	a4,0(a4)
ffffffffc0201e46:	fb6d                	bnez	a4,ffffffffc0201e38 <strnlen+0x6>
ffffffffc0201e48:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201e4a:	852e                	mv	a0,a1
ffffffffc0201e4c:	8082                	ret

ffffffffc0201e4e <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201e4e:	00054783          	lbu	a5,0(a0)
ffffffffc0201e52:	e791                	bnez	a5,ffffffffc0201e5e <strcmp+0x10>
ffffffffc0201e54:	a02d                	j	ffffffffc0201e7e <strcmp+0x30>
ffffffffc0201e56:	00054783          	lbu	a5,0(a0)
ffffffffc0201e5a:	cf89                	beqz	a5,ffffffffc0201e74 <strcmp+0x26>
ffffffffc0201e5c:	85b6                	mv	a1,a3
ffffffffc0201e5e:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc0201e62:	0505                	addi	a0,a0,1
ffffffffc0201e64:	00158693          	addi	a3,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201e68:	fef707e3          	beq	a4,a5,ffffffffc0201e56 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201e6c:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201e70:	9d19                	subw	a0,a0,a4
ffffffffc0201e72:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201e74:	0015c703          	lbu	a4,1(a1)
ffffffffc0201e78:	4501                	li	a0,0
}
ffffffffc0201e7a:	9d19                	subw	a0,a0,a4
ffffffffc0201e7c:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201e7e:	0005c703          	lbu	a4,0(a1)
ffffffffc0201e82:	4501                	li	a0,0
ffffffffc0201e84:	b7f5                	j	ffffffffc0201e70 <strcmp+0x22>

ffffffffc0201e86 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201e86:	ce01                	beqz	a2,ffffffffc0201e9e <strncmp+0x18>
ffffffffc0201e88:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201e8c:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201e8e:	cb91                	beqz	a5,ffffffffc0201ea2 <strncmp+0x1c>
ffffffffc0201e90:	0005c703          	lbu	a4,0(a1)
ffffffffc0201e94:	00f71763          	bne	a4,a5,ffffffffc0201ea2 <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc0201e98:	0505                	addi	a0,a0,1
ffffffffc0201e9a:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201e9c:	f675                	bnez	a2,ffffffffc0201e88 <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201e9e:	4501                	li	a0,0
ffffffffc0201ea0:	8082                	ret
ffffffffc0201ea2:	00054503          	lbu	a0,0(a0)
ffffffffc0201ea6:	0005c783          	lbu	a5,0(a1)
ffffffffc0201eaa:	9d1d                	subw	a0,a0,a5
}
ffffffffc0201eac:	8082                	ret

ffffffffc0201eae <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201eae:	ca01                	beqz	a2,ffffffffc0201ebe <memset+0x10>
ffffffffc0201eb0:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201eb2:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201eb4:	0785                	addi	a5,a5,1
ffffffffc0201eb6:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201eba:	fef61de3          	bne	a2,a5,ffffffffc0201eb4 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201ebe:	8082                	ret
