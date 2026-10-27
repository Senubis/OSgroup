
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00007297          	auipc	t0,0x7
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0207000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00007297          	auipc	t0,0x7
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0207008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02062b7          	lui	t0,0xc0206
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
ffffffffc020003c:	c0206137          	lui	sp,0xc0206

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
ffffffffc020004a:	1141                	addi	sp,sp,-16 # ffffffffc0205ff0 <bootstack+0x1ff0>
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00002517          	auipc	a0,0x2
ffffffffc0200050:	ebc50513          	addi	a0,a0,-324 # ffffffffc0201f08 <etext+0x6>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f4000ef          	jal	ffffffffc020014a <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07c58593          	addi	a1,a1,124 # ffffffffc02000d6 <kern_init>
ffffffffc0200062:	00002517          	auipc	a0,0x2
ffffffffc0200066:	ec650513          	addi	a0,a0,-314 # ffffffffc0201f28 <etext+0x26>
ffffffffc020006a:	0e0000ef          	jal	ffffffffc020014a <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00002597          	auipc	a1,0x2
ffffffffc0200072:	e9458593          	addi	a1,a1,-364 # ffffffffc0201f02 <etext>
ffffffffc0200076:	00002517          	auipc	a0,0x2
ffffffffc020007a:	ed250513          	addi	a0,a0,-302 # ffffffffc0201f48 <etext+0x46>
ffffffffc020007e:	0cc000ef          	jal	ffffffffc020014a <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00007597          	auipc	a1,0x7
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0207018 <free_area>
ffffffffc020008a:	00002517          	auipc	a0,0x2
ffffffffc020008e:	ede50513          	addi	a0,a0,-290 # ffffffffc0201f68 <etext+0x66>
ffffffffc0200092:	0b8000ef          	jal	ffffffffc020014a <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00007597          	auipc	a1,0x7
ffffffffc020009a:	fe258593          	addi	a1,a1,-30 # ffffffffc0207078 <end>
ffffffffc020009e:	00002517          	auipc	a0,0x2
ffffffffc02000a2:	eea50513          	addi	a0,a0,-278 # ffffffffc0201f88 <etext+0x86>
ffffffffc02000a6:	0a4000ef          	jal	ffffffffc020014a <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00000717          	auipc	a4,0x0
ffffffffc02000ae:	02c70713          	addi	a4,a4,44 # ffffffffc02000d6 <kern_init>
ffffffffc02000b2:	00007797          	auipc	a5,0x7
ffffffffc02000b6:	3c578793          	addi	a5,a5,965 # ffffffffc0207477 <end+0x3ff>
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
ffffffffc02000ce:	ede50513          	addi	a0,a0,-290 # ffffffffc0201fa8 <etext+0xa6>
}
ffffffffc02000d2:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d4:	a89d                	j	ffffffffc020014a <cprintf>

ffffffffc02000d6 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d6:	00007517          	auipc	a0,0x7
ffffffffc02000da:	f4250513          	addi	a0,a0,-190 # ffffffffc0207018 <free_area>
ffffffffc02000de:	00007617          	auipc	a2,0x7
ffffffffc02000e2:	f9a60613          	addi	a2,a2,-102 # ffffffffc0207078 <end>
int kern_init(void) {
ffffffffc02000e6:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000e8:	8e09                	sub	a2,a2,a0
ffffffffc02000ea:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ec:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000ee:	603010ef          	jal	ffffffffc0201ef0 <memset>
    dtb_init();
ffffffffc02000f2:	13c000ef          	jal	ffffffffc020022e <dtb_init>
    cons_init();  // init the console
ffffffffc02000f6:	12e000ef          	jal	ffffffffc0200224 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fa:	00003517          	auipc	a0,0x3
ffffffffc02000fe:	d4e50513          	addi	a0,a0,-690 # ffffffffc0202e48 <etext+0xf46>
ffffffffc0200102:	07c000ef          	jal	ffffffffc020017e <cputs>

    print_kerninfo();
ffffffffc0200106:	f45ff0ef          	jal	ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010a:	713000ef          	jal	ffffffffc020101c <pmm_init>

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
ffffffffc0200118:	10e000ef          	jal	ffffffffc0200226 <cons_putc>
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
ffffffffc020013e:	19b010ef          	jal	ffffffffc0201ad8 <vprintfmt>
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
ffffffffc0200172:	167010ef          	jal	ffffffffc0201ad8 <vprintfmt>
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
ffffffffc0200194:	092000ef          	jal	ffffffffc0200226 <cons_putc>
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
ffffffffc02001ac:	07a000ef          	jal	ffffffffc0200226 <cons_putc>
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
ffffffffc02001bc:	06a000ef          	jal	ffffffffc0200226 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc02001c0:	4405                	li	s0,1
}
ffffffffc02001c2:	60e2                	ld	ra,24(sp)
ffffffffc02001c4:	8522                	mv	a0,s0
ffffffffc02001c6:	6442                	ld	s0,16(sp)
ffffffffc02001c8:	6105                	addi	sp,sp,32
ffffffffc02001ca:	8082                	ret

ffffffffc02001cc <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001cc:	00007317          	auipc	t1,0x7
ffffffffc02001d0:	e6432303          	lw	t1,-412(t1) # ffffffffc0207030 <is_panic>
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001d4:	715d                	addi	sp,sp,-80
ffffffffc02001d6:	ec06                	sd	ra,24(sp)
ffffffffc02001d8:	f436                	sd	a3,40(sp)
ffffffffc02001da:	f83a                	sd	a4,48(sp)
ffffffffc02001dc:	fc3e                	sd	a5,56(sp)
ffffffffc02001de:	e0c2                	sd	a6,64(sp)
ffffffffc02001e0:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001e2:	00030363          	beqz	t1,ffffffffc02001e8 <__panic+0x1c>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001e6:	a001                	j	ffffffffc02001e6 <__panic+0x1a>
    is_panic = 1;
ffffffffc02001e8:	e822                	sd	s0,16(sp)
ffffffffc02001ea:	00007797          	auipc	a5,0x7
ffffffffc02001ee:	e4678793          	addi	a5,a5,-442 # ffffffffc0207030 <is_panic>
ffffffffc02001f2:	4685                	li	a3,1
    va_start(ap, fmt);
ffffffffc02001f4:	1038                	addi	a4,sp,40
ffffffffc02001f6:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001f8:	862e                	mv	a2,a1
ffffffffc02001fa:	85aa                	mv	a1,a0
ffffffffc02001fc:	00002517          	auipc	a0,0x2
ffffffffc0200200:	ddc50513          	addi	a0,a0,-548 # ffffffffc0201fd8 <etext+0xd6>
    is_panic = 1;
ffffffffc0200204:	c394                	sw	a3,0(a5)
    va_start(ap, fmt);
ffffffffc0200206:	e43a                	sd	a4,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200208:	f43ff0ef          	jal	ffffffffc020014a <cprintf>
    vcprintf(fmt, ap);
ffffffffc020020c:	65a2                	ld	a1,8(sp)
ffffffffc020020e:	8522                	mv	a0,s0
ffffffffc0200210:	f1bff0ef          	jal	ffffffffc020012a <vcprintf>
    cprintf("\n");
ffffffffc0200214:	00002517          	auipc	a0,0x2
ffffffffc0200218:	de450513          	addi	a0,a0,-540 # ffffffffc0201ff8 <etext+0xf6>
ffffffffc020021c:	f2fff0ef          	jal	ffffffffc020014a <cprintf>
ffffffffc0200220:	6442                	ld	s0,16(sp)
ffffffffc0200222:	b7d1                	j	ffffffffc02001e6 <__panic+0x1a>

ffffffffc0200224 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200224:	8082                	ret

ffffffffc0200226 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200226:	0ff57513          	zext.b	a0,a0
ffffffffc020022a:	4170106f          	j	ffffffffc0201e40 <sbi_console_putchar>

ffffffffc020022e <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc020022e:	711d                	addi	sp,sp,-96
    cprintf("DTB Init\n");
ffffffffc0200230:	00002517          	auipc	a0,0x2
ffffffffc0200234:	dd050513          	addi	a0,a0,-560 # ffffffffc0202000 <etext+0xfe>
void dtb_init(void) {
ffffffffc0200238:	ec86                	sd	ra,88(sp)
ffffffffc020023a:	e8a2                	sd	s0,80(sp)
    cprintf("DTB Init\n");
ffffffffc020023c:	f0fff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200240:	00007597          	auipc	a1,0x7
ffffffffc0200244:	dc05b583          	ld	a1,-576(a1) # ffffffffc0207000 <boot_hartid>
ffffffffc0200248:	00002517          	auipc	a0,0x2
ffffffffc020024c:	dc850513          	addi	a0,a0,-568 # ffffffffc0202010 <etext+0x10e>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200250:	00007417          	auipc	s0,0x7
ffffffffc0200254:	db840413          	addi	s0,s0,-584 # ffffffffc0207008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200258:	ef3ff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020025c:	600c                	ld	a1,0(s0)
ffffffffc020025e:	00002517          	auipc	a0,0x2
ffffffffc0200262:	dc250513          	addi	a0,a0,-574 # ffffffffc0202020 <etext+0x11e>
ffffffffc0200266:	ee5ff0ef          	jal	ffffffffc020014a <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc020026a:	601c                	ld	a5,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020026c:	00002517          	auipc	a0,0x2
ffffffffc0200270:	dcc50513          	addi	a0,a0,-564 # ffffffffc0202038 <etext+0x136>
    if (boot_dtb == 0) {
ffffffffc0200274:	12078463          	beqz	a5,ffffffffc020039c <dtb_init+0x16e>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200278:	5775                	li	a4,-3
ffffffffc020027a:	077a                	slli	a4,a4,0x1e
ffffffffc020027c:	97ba                	add	a5,a5,a4
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc020027e:	4398                	lw	a4,0(a5)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200280:	f456                	sd	s5,40(sp)
ffffffffc0200282:	00ff0ab7          	lui	s5,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200286:	0107569b          	srliw	a3,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020028a:	0087559b          	srliw	a1,a4,0x8
ffffffffc020028e:	0187151b          	slliw	a0,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200292:	0086969b          	slliw	a3,a3,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200296:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020029a:	0187571b          	srliw	a4,a4,0x18
ffffffffc020029e:	8f49                	or	a4,a4,a0
ffffffffc02002a0:	16c2                	slli	a3,a3,0x30
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a2:	0155f5b3          	and	a1,a1,s5
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a6:	8dd9                	or	a1,a1,a4
    if (magic != 0xd00dfeed) {
ffffffffc02002a8:	d00e0637          	lui	a2,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ac:	92c1                	srli	a3,a3,0x30
ffffffffc02002ae:	8dd5                	or	a1,a1,a3
    if (magic != 0xd00dfeed) {
ffffffffc02002b0:	eed60713          	addi	a4,a2,-275 # ffffffffd00dfeed <end+0xfed8e75>
ffffffffc02002b4:	0ee59863          	bne	a1,a4,ffffffffc02003a4 <dtb_init+0x176>
ffffffffc02002b8:	4794                	lw	a3,8(a5)
ffffffffc02002ba:	47d8                	lw	a4,12(a5)
ffffffffc02002bc:	e4a6                	sd	s1,72(sp)
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002be:	0106d59b          	srliw	a1,a3,0x10
ffffffffc02002c2:	0107561b          	srliw	a2,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002c6:	0086d41b          	srliw	s0,a3,0x8
ffffffffc02002ca:	0087549b          	srliw	s1,a4,0x8
ffffffffc02002ce:	0186981b          	slliw	a6,a3,0x18
ffffffffc02002d2:	0187151b          	slliw	a0,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d6:	0085959b          	slliw	a1,a1,0x8
ffffffffc02002da:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002de:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e2:	0186d69b          	srliw	a3,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e6:	0104949b          	slliw	s1,s1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ea:	0187571b          	srliw	a4,a4,0x18
ffffffffc02002ee:	15c2                	slli	a1,a1,0x30
ffffffffc02002f0:	1642                	slli	a2,a2,0x30
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f2:	01547433          	and	s0,s0,s5
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f6:	00d866b3          	or	a3,a6,a3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002fa:	0154f4b3          	and	s1,s1,s5
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002fe:	8f49                	or	a4,a4,a0
ffffffffc0200300:	91c1                	srli	a1,a1,0x30
ffffffffc0200302:	9241                	srli	a2,a2,0x30
ffffffffc0200304:	8c55                	or	s0,s0,a3
ffffffffc0200306:	8cd9                	or	s1,s1,a4
ffffffffc0200308:	8c4d                	or	s0,s0,a1
ffffffffc020030a:	8cd1                	or	s1,s1,a2
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020030c:	1402                	slli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020030e:	1482                	slli	s1,s1,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200310:	9001                	srli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200312:	9081                	srli	s1,s1,0x20
ffffffffc0200314:	e0ca                	sd	s2,64(sp)
ffffffffc0200316:	fc4e                	sd	s3,56(sp)
ffffffffc0200318:	f05a                	sd	s6,32(sp)
ffffffffc020031a:	ec5e                	sd	s7,24(sp)
ffffffffc020031c:	e862                	sd	s8,16(sp)
ffffffffc020031e:	f852                	sd	s4,48(sp)
ffffffffc0200320:	e466                	sd	s9,8(sp)
    int in_memory_node = 0;
ffffffffc0200322:	4b81                	li	s7,0
        switch (token) {
ffffffffc0200324:	4b0d                	li	s6,3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200326:	943e                	add	s0,s0,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200328:	94be                	add	s1,s1,a5
        switch (token) {
ffffffffc020032a:	4991                	li	s3,4
ffffffffc020032c:	4c05                	li	s8,1
ffffffffc020032e:	4909                	li	s2,2
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200330:	4018                	lw	a4,0(s0)
ffffffffc0200332:	00440a13          	addi	s4,s0,4
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200336:	0107569b          	srliw	a3,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020033a:	0087579b          	srliw	a5,a4,0x8
ffffffffc020033e:	0187161b          	slliw	a2,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200342:	0086969b          	slliw	a3,a3,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200346:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020034a:	0187571b          	srliw	a4,a4,0x18
ffffffffc020034e:	16c2                	slli	a3,a3,0x30
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200350:	0157f7b3          	and	a5,a5,s5
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200354:	8f51                	or	a4,a4,a2
ffffffffc0200356:	92c1                	srli	a3,a3,0x30
ffffffffc0200358:	8fd9                	or	a5,a5,a4
ffffffffc020035a:	8fd5                	or	a5,a5,a3
        switch (token) {
ffffffffc020035c:	09678763          	beq	a5,s6,ffffffffc02003ea <dtb_init+0x1bc>
ffffffffc0200360:	00fb6963          	bltu	s6,a5,ffffffffc0200372 <dtb_init+0x144>
ffffffffc0200364:	05878963          	beq	a5,s8,ffffffffc02003b6 <dtb_init+0x188>
ffffffffc0200368:	01279763          	bne	a5,s2,ffffffffc0200376 <dtb_init+0x148>
ffffffffc020036c:	4b81                	li	s7,0
ffffffffc020036e:	8452                	mv	s0,s4
ffffffffc0200370:	b7c1                	j	ffffffffc0200330 <dtb_init+0x102>
ffffffffc0200372:	ff378ee3          	beq	a5,s3,ffffffffc020036e <dtb_init+0x140>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200376:	00002517          	auipc	a0,0x2
ffffffffc020037a:	d8a50513          	addi	a0,a0,-630 # ffffffffc0202100 <etext+0x1fe>
ffffffffc020037e:	dcdff0ef          	jal	ffffffffc020014a <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200382:	64a6                	ld	s1,72(sp)
ffffffffc0200384:	6906                	ld	s2,64(sp)
ffffffffc0200386:	79e2                	ld	s3,56(sp)
ffffffffc0200388:	7a42                	ld	s4,48(sp)
ffffffffc020038a:	7aa2                	ld	s5,40(sp)
ffffffffc020038c:	7b02                	ld	s6,32(sp)
ffffffffc020038e:	6be2                	ld	s7,24(sp)
ffffffffc0200390:	6c42                	ld	s8,16(sp)
ffffffffc0200392:	6ca2                	ld	s9,8(sp)
ffffffffc0200394:	00002517          	auipc	a0,0x2
ffffffffc0200398:	da450513          	addi	a0,a0,-604 # ffffffffc0202138 <etext+0x236>
}
ffffffffc020039c:	6446                	ld	s0,80(sp)
ffffffffc020039e:	60e6                	ld	ra,88(sp)
ffffffffc02003a0:	6125                	addi	sp,sp,96
    cprintf("DTB init completed\n");
ffffffffc02003a2:	b365                	j	ffffffffc020014a <cprintf>
}
ffffffffc02003a4:	6446                	ld	s0,80(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003a6:	7aa2                	ld	s5,40(sp)
}
ffffffffc02003a8:	60e6                	ld	ra,88(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003aa:	00002517          	auipc	a0,0x2
ffffffffc02003ae:	cae50513          	addi	a0,a0,-850 # ffffffffc0202058 <etext+0x156>
}
ffffffffc02003b2:	6125                	addi	sp,sp,96
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003b4:	bb59                	j	ffffffffc020014a <cprintf>
                int name_len = strlen(name);
ffffffffc02003b6:	8552                	mv	a0,s4
ffffffffc02003b8:	2a3010ef          	jal	ffffffffc0201e5a <strlen>
ffffffffc02003bc:	8caa                	mv	s9,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003be:	4619                	li	a2,6
ffffffffc02003c0:	8552                	mv	a0,s4
ffffffffc02003c2:	00002597          	auipc	a1,0x2
ffffffffc02003c6:	cbe58593          	addi	a1,a1,-834 # ffffffffc0202080 <etext+0x17e>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02003ca:	00840a13          	addi	s4,s0,8
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003ce:	2fb010ef          	jal	ffffffffc0201ec8 <strncmp>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02003d2:	2c81                	sext.w	s9,s9
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003d4:	00153513          	seqz	a0,a0
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02003d8:	9a66                	add	s4,s4,s9
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003da:	00abe533          	or	a0,s7,a0
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02003de:	ffca7a13          	andi	s4,s4,-4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003e2:	00050b9b          	sext.w	s7,a0
        switch (token) {
ffffffffc02003e6:	8452                	mv	s0,s4
ffffffffc02003e8:	b7a1                	j	ffffffffc0200330 <dtb_init+0x102>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02003ea:	405c                	lw	a5,4(s0)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02003ec:	00c40a13          	addi	s4,s0,12
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02003f0:	0107d71b          	srliw	a4,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02003f4:	0087d69b          	srliw	a3,a5,0x8
ffffffffc02003f8:	01879c9b          	slliw	s9,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02003fc:	0087171b          	slliw	a4,a4,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200400:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200404:	0187d79b          	srliw	a5,a5,0x18
ffffffffc0200408:	1742                	slli	a4,a4,0x30
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020040a:	0156f6b3          	and	a3,a3,s5
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020040e:	00fcecb3          	or	s9,s9,a5
ffffffffc0200412:	9341                	srli	a4,a4,0x30
ffffffffc0200414:	00dcecb3          	or	s9,s9,a3
ffffffffc0200418:	00ececb3          	or	s9,s9,a4
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020041c:	000b9b63          	bnez	s7,ffffffffc0200432 <dtb_init+0x204>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200420:	1c82                	slli	s9,s9,0x20
ffffffffc0200422:	020cdc93          	srli	s9,s9,0x20
ffffffffc0200426:	0a0d                	addi	s4,s4,3
ffffffffc0200428:	9a66                	add	s4,s4,s9
ffffffffc020042a:	ffca7a13          	andi	s4,s4,-4
        switch (token) {
ffffffffc020042e:	8452                	mv	s0,s4
ffffffffc0200430:	b701                	j	ffffffffc0200330 <dtb_init+0x102>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200432:	441c                	lw	a5,8(s0)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200434:	00002597          	auipc	a1,0x2
ffffffffc0200438:	c5458593          	addi	a1,a1,-940 # ffffffffc0202088 <etext+0x186>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020043c:	0087d69b          	srliw	a3,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200440:	0107d71b          	srliw	a4,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200444:	0187951b          	slliw	a0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200448:	0087171b          	slliw	a4,a4,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020044c:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200450:	0187d79b          	srliw	a5,a5,0x18
ffffffffc0200454:	1742                	slli	a4,a4,0x30
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200456:	0156f6b3          	and	a3,a3,s5
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020045a:	8d5d                	or	a0,a0,a5
ffffffffc020045c:	9341                	srli	a4,a4,0x30
ffffffffc020045e:	8d55                	or	a0,a0,a3
ffffffffc0200460:	8d59                	or	a0,a0,a4
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200462:	1502                	slli	a0,a0,0x20
ffffffffc0200464:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200466:	9526                	add	a0,a0,s1
ffffffffc0200468:	229010ef          	jal	ffffffffc0201e90 <strcmp>
ffffffffc020046c:	f955                	bnez	a0,ffffffffc0200420 <dtb_init+0x1f2>
ffffffffc020046e:	47bd                	li	a5,15
ffffffffc0200470:	fb97f8e3          	bgeu	a5,s9,ffffffffc0200420 <dtb_init+0x1f2>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200474:	00c43703          	ld	a4,12(s0)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200478:	01443783          	ld	a5,20(s0)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020047c:	00002517          	auipc	a0,0x2
ffffffffc0200480:	c1450513          	addi	a0,a0,-1004 # ffffffffc0202090 <etext+0x18e>
           fdt32_to_cpu(x >> 32);
ffffffffc0200484:	42075813          	srai	a6,a4,0x20
ffffffffc0200488:	4207d593          	srai	a1,a5,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020048c:	01085e9b          	srliw	t4,a6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200490:	02875613          	srli	a2,a4,0x28
ffffffffc0200494:	0287d693          	srli	a3,a5,0x28
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200498:	00070e1b          	sext.w	t3,a4
ffffffffc020049c:	0007889b          	sext.w	a7,a5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004a0:	01859f9b          	slliw	t6,a1,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004a4:	0105d31b          	srliw	t1,a1,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004a8:	0188139b          	slliw	t2,a6,0x18
ffffffffc02004ac:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004b0:	0188581b          	srliw	a6,a6,0x18
ffffffffc02004b4:	0185df1b          	srliw	t5,a1,0x18
ffffffffc02004b8:	008e9e9b          	slliw	t4,t4,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004bc:	0106161b          	slliw	a2,a2,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c0:	010e529b          	srliw	t0,t3,0x10
ffffffffc02004c4:	0103e3b3          	or	t2,t2,a6
ffffffffc02004c8:	01efef33          	or	t5,t6,t5
ffffffffc02004cc:	0108d59b          	srliw	a1,a7,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004d0:	01567633          	and	a2,a2,s5
ffffffffc02004d4:	0087549b          	srliw	s1,a4,0x8
ffffffffc02004d8:	0087d41b          	srliw	s0,a5,0x8
ffffffffc02004dc:	0156f733          	and	a4,a3,s5
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e0:	0083131b          	slliw	t1,t1,0x8
ffffffffc02004e4:	1ec2                	slli	t4,t4,0x30
ffffffffc02004e6:	007666b3          	or	a3,a2,t2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ea:	018e1f9b          	slliw	t6,t3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ee:	030ede93          	srli	t4,t4,0x30
ffffffffc02004f2:	0082981b          	slliw	a6,t0,0x8
ffffffffc02004f6:	018e5e1b          	srliw	t3,t3,0x18
ffffffffc02004fa:	01e767b3          	or	a5,a4,t5
ffffffffc02004fe:	0085959b          	slliw	a1,a1,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200502:	01889f1b          	slliw	t5,a7,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200506:	1342                	slli	t1,t1,0x30
ffffffffc0200508:	0188d89b          	srliw	a7,a7,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020050c:	0104949b          	slliw	s1,s1,0x10
ffffffffc0200510:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200514:	01d6e733          	or	a4,a3,t4
ffffffffc0200518:	03035313          	srli	t1,t1,0x30
ffffffffc020051c:	011f66b3          	or	a3,t5,a7
ffffffffc0200520:	03059613          	slli	a2,a1,0x30
ffffffffc0200524:	1842                	slli	a6,a6,0x30
ffffffffc0200526:	01cfe5b3          	or	a1,t6,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	0154f4b3          	and	s1,s1,s5
ffffffffc020052e:	01547433          	and	s0,s0,s5
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200532:	03085813          	srli	a6,a6,0x30
ffffffffc0200536:	0067e7b3          	or	a5,a5,t1
ffffffffc020053a:	8c55                	or	s0,s0,a3
ffffffffc020053c:	9241                	srli	a2,a2,0x30
ffffffffc020053e:	8ccd                	or	s1,s1,a1
ffffffffc0200540:	0104e4b3          	or	s1,s1,a6
ffffffffc0200544:	8c51                	or	s0,s0,a2
           fdt32_to_cpu(x >> 32);
ffffffffc0200546:	1702                	slli	a4,a4,0x20
ffffffffc0200548:	1782                	slli	a5,a5,0x20
ffffffffc020054a:	9381                	srli	a5,a5,0x20
ffffffffc020054c:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020054e:	1482                	slli	s1,s1,0x20
ffffffffc0200550:	1402                	slli	s0,s0,0x20
ffffffffc0200552:	8c5d                	or	s0,s0,a5
ffffffffc0200554:	8cd9                	or	s1,s1,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200556:	bf5ff0ef          	jal	ffffffffc020014a <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc020055a:	85a6                	mv	a1,s1
ffffffffc020055c:	00002517          	auipc	a0,0x2
ffffffffc0200560:	b5450513          	addi	a0,a0,-1196 # ffffffffc02020b0 <etext+0x1ae>
ffffffffc0200564:	be7ff0ef          	jal	ffffffffc020014a <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200568:	01445613          	srli	a2,s0,0x14
ffffffffc020056c:	85a2                	mv	a1,s0
ffffffffc020056e:	00002517          	auipc	a0,0x2
ffffffffc0200572:	b5a50513          	addi	a0,a0,-1190 # ffffffffc02020c8 <etext+0x1c6>
ffffffffc0200576:	bd5ff0ef          	jal	ffffffffc020014a <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020057a:	009405b3          	add	a1,s0,s1
ffffffffc020057e:	15fd                	addi	a1,a1,-1
ffffffffc0200580:	00002517          	auipc	a0,0x2
ffffffffc0200584:	b6850513          	addi	a0,a0,-1176 # ffffffffc02020e8 <etext+0x1e6>
ffffffffc0200588:	bc3ff0ef          	jal	ffffffffc020014a <cprintf>
        memory_base = mem_base;
ffffffffc020058c:	00007797          	auipc	a5,0x7
ffffffffc0200590:	aa97ba23          	sd	s1,-1356(a5) # ffffffffc0207040 <memory_base>
        memory_size = mem_size;
ffffffffc0200594:	00007797          	auipc	a5,0x7
ffffffffc0200598:	aa87b223          	sd	s0,-1372(a5) # ffffffffc0207038 <memory_size>
ffffffffc020059c:	b3dd                	j	ffffffffc0200382 <dtb_init+0x154>

ffffffffc020059e <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020059e:	00007517          	auipc	a0,0x7
ffffffffc02005a2:	aa253503          	ld	a0,-1374(a0) # ffffffffc0207040 <memory_base>
ffffffffc02005a6:	8082                	ret

ffffffffc02005a8 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005a8:	00007517          	auipc	a0,0x7
ffffffffc02005ac:	a9053503          	ld	a0,-1392(a0) # ffffffffc0207038 <memory_size>
ffffffffc02005b0:	8082                	ret

ffffffffc02005b2 <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02005b2:	00007797          	auipc	a5,0x7
ffffffffc02005b6:	a6678793          	addi	a5,a5,-1434 # ffffffffc0207018 <free_area>
ffffffffc02005ba:	e79c                	sd	a5,8(a5)
ffffffffc02005bc:	e39c                	sd	a5,0(a5)
static void best_fit_check(void);

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc02005be:	0007a823          	sw	zero,16(a5)
}
ffffffffc02005c2:	8082                	ret

ffffffffc02005c4 <best_fit_insert>:
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc02005c4:	00007697          	auipc	a3,0x7
ffffffffc02005c8:	a5468693          	addi	a3,a3,-1452 # ffffffffc0207018 <free_area>
ffffffffc02005cc:	669c                	ld	a5,8(a3)
// Insert by physical address, then merge with the two address-neighbours.
// All pages in the new block have already had their flags/refcounts reset.
static void
best_fit_insert(struct Page *base, size_t n) {
    list_entry_t *le = list_next(&free_list);
    while (le != &free_list && le2page(le, page_link) < base) {
ffffffffc02005ce:	00d79663          	bne	a5,a3,ffffffffc02005da <best_fit_insert+0x16>
ffffffffc02005d2:	a801                	j	ffffffffc02005e2 <best_fit_insert+0x1e>
ffffffffc02005d4:	679c                	ld	a5,8(a5)
ffffffffc02005d6:	00d78663          	beq	a5,a3,ffffffffc02005e2 <best_fit_insert+0x1e>
ffffffffc02005da:	fe878713          	addi	a4,a5,-24
ffffffffc02005de:	fea76be3          	bltu	a4,a0,ffffffffc02005d4 <best_fit_insert+0x10>
        le = list_next(le);
    }
    base->property = n;
    SetPageProperty(base);
ffffffffc02005e2:	00853883          	ld	a7,8(a0)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02005e6:	6398                	ld	a4,0(a5)
    list_add_before(le, &base->page_link);
    nr_free += n;
ffffffffc02005e8:	00007617          	auipc	a2,0x7
ffffffffc02005ec:	a4062603          	lw	a2,-1472(a2) # ffffffffc0207028 <free_area+0x10>
    base->property = n;
ffffffffc02005f0:	2581                	sext.w	a1,a1
    SetPageProperty(base);
ffffffffc02005f2:	0028e813          	ori	a6,a7,2
ffffffffc02005f6:	01053423          	sd	a6,8(a0)
    base->property = n;
ffffffffc02005fa:	c90c                	sw	a1,16(a0)
    list_add_before(le, &base->page_link);
ffffffffc02005fc:	01850813          	addi	a6,a0,24
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0200600:	0107b023          	sd	a6,0(a5)
ffffffffc0200604:	01073423          	sd	a6,8(a4)
    nr_free += n;
ffffffffc0200608:	9e2d                	addw	a2,a2,a1
    elm->next = next;
    elm->prev = prev;
ffffffffc020060a:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc020060c:	f11c                	sd	a5,32(a0)
ffffffffc020060e:	ca90                	sw	a2,16(a3)

    le = list_prev(&base->page_link);
    if (le != &free_list) {
ffffffffc0200610:	02d70163          	beq	a4,a3,ffffffffc0200632 <best_fit_insert+0x6e>
        struct Page *prev = le2page(le, page_link);
        if (prev + prev->property == base) {
ffffffffc0200614:	ff872e83          	lw	t4,-8(a4)
        struct Page *prev = le2page(le, page_link);
ffffffffc0200618:	fe870e13          	addi	t3,a4,-24
        if (prev + prev->property == base) {
ffffffffc020061c:	020e9313          	slli	t1,t4,0x20
ffffffffc0200620:	02035313          	srli	t1,t1,0x20
ffffffffc0200624:	00231613          	slli	a2,t1,0x2
ffffffffc0200628:	961a                	add	a2,a2,t1
ffffffffc020062a:	060e                	slli	a2,a2,0x3
ffffffffc020062c:	9672                	add	a2,a2,t3
ffffffffc020062e:	04c50763          	beq	a0,a2,ffffffffc020067c <best_fit_insert+0xb8>
            list_del_init(&base->page_link);
            base = prev;
        }
    }
    le = list_next(&base->page_link);
    if (le != &free_list) {
ffffffffc0200632:	00d78f63          	beq	a5,a3,ffffffffc0200650 <best_fit_insert+0x8c>
        struct Page *next = le2page(le, page_link);
        if (base + base->property == next) {
ffffffffc0200636:	490c                	lw	a1,16(a0)
        struct Page *next = le2page(le, page_link);
ffffffffc0200638:	fe878693          	addi	a3,a5,-24
        if (base + base->property == next) {
ffffffffc020063c:	02059613          	slli	a2,a1,0x20
ffffffffc0200640:	9201                	srli	a2,a2,0x20
ffffffffc0200642:	00261713          	slli	a4,a2,0x2
ffffffffc0200646:	9732                	add	a4,a4,a2
ffffffffc0200648:	070e                	slli	a4,a4,0x3
ffffffffc020064a:	972a                	add	a4,a4,a0
ffffffffc020064c:	00d70363          	beq	a4,a3,ffffffffc0200652 <best_fit_insert+0x8e>
            ClearPageProperty(next);
            next->property = 0;
            list_del_init(&next->page_link);
        }
    }
}
ffffffffc0200650:	8082                	ret
            base->property += next->property;
ffffffffc0200652:	ff87a683          	lw	a3,-8(a5)
            ClearPageProperty(next);
ffffffffc0200656:	ff07b703          	ld	a4,-16(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc020065a:	0007b803          	ld	a6,0(a5)
ffffffffc020065e:	6790                	ld	a2,8(a5)
            base->property += next->property;
ffffffffc0200660:	9ead                	addw	a3,a3,a1
ffffffffc0200662:	c914                	sw	a3,16(a0)
            ClearPageProperty(next);
ffffffffc0200664:	9b75                	andi	a4,a4,-3
            next->property = 0;
ffffffffc0200666:	fe07ac23          	sw	zero,-8(a5)
            ClearPageProperty(next);
ffffffffc020066a:	fee7b823          	sd	a4,-16(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020066e:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc0200672:	01063023          	sd	a6,0(a2)
    elm->prev = elm->next = elm;
ffffffffc0200676:	e79c                	sd	a5,8(a5)
ffffffffc0200678:	e39c                	sd	a5,0(a5)
}
ffffffffc020067a:	8082                	ret
            prev->property += base->property;
ffffffffc020067c:	01d585bb          	addw	a1,a1,t4
ffffffffc0200680:	feb72c23          	sw	a1,-8(a4)
            ClearPageProperty(base);
ffffffffc0200684:	ffd8f893          	andi	a7,a7,-3
ffffffffc0200688:	01153423          	sd	a7,8(a0)
            base->property = 0;
ffffffffc020068c:	00052823          	sw	zero,16(a0)
    prev->next = next;
ffffffffc0200690:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0200692:	e398                	sd	a4,0(a5)
    elm->prev = elm->next = elm;
ffffffffc0200694:	03053023          	sd	a6,32(a0)
    return listelm->next;
ffffffffc0200698:	671c                	ld	a5,8(a4)
    elm->prev = elm->next = elm;
ffffffffc020069a:	01053c23          	sd	a6,24(a0)
            base = prev;
ffffffffc020069e:	8572                	mv	a0,t3
ffffffffc02006a0:	bf49                	j	ffffffffc0200632 <best_fit_insert+0x6e>

ffffffffc02006a2 <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc02006a2:	00007517          	auipc	a0,0x7
ffffffffc02006a6:	98656503          	lwu	a0,-1658(a0) # ffffffffc0207028 <free_area+0x10>
ffffffffc02006aa:	8082                	ret

ffffffffc02006ac <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc02006ac:	c965                	beqz	a0,ffffffffc020079c <best_fit_alloc_pages+0xf0>
    if (n > nr_free) {
ffffffffc02006ae:	00007897          	auipc	a7,0x7
ffffffffc02006b2:	97a8a883          	lw	a7,-1670(a7) # ffffffffc0207028 <free_area+0x10>
ffffffffc02006b6:	862a                	mv	a2,a0
ffffffffc02006b8:	00007597          	auipc	a1,0x7
ffffffffc02006bc:	96058593          	addi	a1,a1,-1696 # ffffffffc0207018 <free_area>
ffffffffc02006c0:	02089793          	slli	a5,a7,0x20
ffffffffc02006c4:	9381                	srli	a5,a5,0x20
ffffffffc02006c6:	0ca7e963          	bltu	a5,a0,ffffffffc0200798 <best_fit_alloc_pages+0xec>
    return listelm->next;
ffffffffc02006ca:	659c                	ld	a5,8(a1)
    struct Page *best = NULL;
ffffffffc02006cc:	4501                	li	a0,0
    while ((le = list_next(le)) != &free_list) {
ffffffffc02006ce:	0cb78463          	beq	a5,a1,ffffffffc0200796 <best_fit_alloc_pages+0xea>
        if (p->property >= n &&
ffffffffc02006d2:	ff87a703          	lw	a4,-8(a5)
ffffffffc02006d6:	02071693          	slli	a3,a4,0x20
ffffffffc02006da:	9281                	srli	a3,a3,0x20
ffffffffc02006dc:	04c6e963          	bltu	a3,a2,ffffffffc020072e <best_fit_alloc_pages+0x82>
ffffffffc02006e0:	e90d                	bnez	a0,ffffffffc0200712 <best_fit_alloc_pages+0x66>
        struct Page *p = le2page(le, page_link);
ffffffffc02006e2:	fe878513          	addi	a0,a5,-24
            if (p->property == n) {
ffffffffc02006e6:	04d60863          	beq	a2,a3,ffffffffc0200736 <best_fit_alloc_pages+0x8a>
ffffffffc02006ea:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02006ec:	04b78563          	beq	a5,a1,ffffffffc0200736 <best_fit_alloc_pages+0x8a>
        if (p->property >= n &&
ffffffffc02006f0:	ff87a703          	lw	a4,-8(a5)
ffffffffc02006f4:	02071693          	slli	a3,a4,0x20
ffffffffc02006f8:	9281                	srli	a3,a3,0x20
ffffffffc02006fa:	00c6fc63          	bgeu	a3,a2,ffffffffc0200712 <best_fit_alloc_pages+0x66>
ffffffffc02006fe:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200700:	02b78a63          	beq	a5,a1,ffffffffc0200734 <best_fit_alloc_pages+0x88>
        if (p->property >= n &&
ffffffffc0200704:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200708:	02071693          	slli	a3,a4,0x20
ffffffffc020070c:	9281                	srli	a3,a3,0x20
ffffffffc020070e:	02c6e063          	bltu	a3,a2,ffffffffc020072e <best_fit_alloc_pages+0x82>
            (best == NULL || p->property < best->property)) {
ffffffffc0200712:	01052803          	lw	a6,16(a0)
ffffffffc0200716:	fd0766e3          	bltu	a4,a6,ffffffffc02006e2 <best_fit_alloc_pages+0x36>
ffffffffc020071a:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc020071c:	00b78d63          	beq	a5,a1,ffffffffc0200736 <best_fit_alloc_pages+0x8a>
        if (p->property >= n &&
ffffffffc0200720:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200724:	02071693          	slli	a3,a4,0x20
ffffffffc0200728:	9281                	srli	a3,a3,0x20
ffffffffc020072a:	fec6f6e3          	bgeu	a3,a2,ffffffffc0200716 <best_fit_alloc_pages+0x6a>
ffffffffc020072e:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200730:	fab791e3          	bne	a5,a1,ffffffffc02006d2 <best_fit_alloc_pages+0x26>
    if (best == NULL) {
ffffffffc0200734:	c12d                	beqz	a0,ffffffffc0200796 <best_fit_alloc_pages+0xea>
    return listelm->prev;
ffffffffc0200736:	6d18                	ld	a4,24(a0)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200738:	02053803          	ld	a6,32(a0)
    size_t remaining = best->property - n;
ffffffffc020073c:	01056683          	lwu	a3,16(a0)
    list_del_init(&best->page_link);
ffffffffc0200740:	01850793          	addi	a5,a0,24
    prev->next = next;
ffffffffc0200744:	01073423          	sd	a6,8(a4)
    next->prev = prev;
ffffffffc0200748:	00e83023          	sd	a4,0(a6)
    elm->prev = elm->next = elm;
ffffffffc020074c:	f11c                	sd	a5,32(a0)
ffffffffc020074e:	ed1c                	sd	a5,24(a0)
    size_t remaining = best->property - n;
ffffffffc0200750:	40c68333          	sub	t1,a3,a2
    if (remaining != 0) {
ffffffffc0200754:	02c68763          	beq	a3,a2,ffffffffc0200782 <best_fit_alloc_pages+0xd6>
        struct Page *rest = best + n;
ffffffffc0200758:	00261793          	slli	a5,a2,0x2
ffffffffc020075c:	97b2                	add	a5,a5,a2
ffffffffc020075e:	078e                	slli	a5,a5,0x3
ffffffffc0200760:	97aa                	add	a5,a5,a0
        SetPageProperty(rest);
ffffffffc0200762:	6794                	ld	a3,8(a5)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200764:	00873803          	ld	a6,8(a4)
        rest->property = remaining;
ffffffffc0200768:	0067a823          	sw	t1,16(a5)
        SetPageProperty(rest);
ffffffffc020076c:	0026e693          	ori	a3,a3,2
ffffffffc0200770:	e794                	sd	a3,8(a5)
        list_add(prev, &rest->page_link);
ffffffffc0200772:	01878693          	addi	a3,a5,24
    prev->next = next->prev = elm;
ffffffffc0200776:	00d83023          	sd	a3,0(a6)
ffffffffc020077a:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc020077c:	0307b023          	sd	a6,32(a5)
    elm->prev = prev;
ffffffffc0200780:	ef98                	sd	a4,24(a5)
    ClearPageProperty(best);
ffffffffc0200782:	651c                	ld	a5,8(a0)
    best->property = 0;
ffffffffc0200784:	00052823          	sw	zero,16(a0)
    nr_free -= n;
ffffffffc0200788:	40c888bb          	subw	a7,a7,a2
    ClearPageProperty(best);
ffffffffc020078c:	9bf5                	andi	a5,a5,-3
ffffffffc020078e:	e51c                	sd	a5,8(a0)
    nr_free -= n;
ffffffffc0200790:	0115a823          	sw	a7,16(a1)
    return best;
ffffffffc0200794:	8082                	ret
}
ffffffffc0200796:	8082                	ret
        return NULL;
ffffffffc0200798:	4501                	li	a0,0
ffffffffc020079a:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc020079c:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020079e:	00002697          	auipc	a3,0x2
ffffffffc02007a2:	9b268693          	addi	a3,a3,-1614 # ffffffffc0202150 <etext+0x24e>
ffffffffc02007a6:	00002617          	auipc	a2,0x2
ffffffffc02007aa:	9b260613          	addi	a2,a2,-1614 # ffffffffc0202158 <etext+0x256>
ffffffffc02007ae:	04500593          	li	a1,69
ffffffffc02007b2:	00002517          	auipc	a0,0x2
ffffffffc02007b6:	9be50513          	addi	a0,a0,-1602 # ffffffffc0202170 <etext+0x26e>
best_fit_alloc_pages(size_t n) {
ffffffffc02007ba:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02007bc:	a11ff0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc02007c0 <best_fit_check>:
    free_page(p1);
    free_page(p2);
}

static void
best_fit_check(void) {
ffffffffc02007c0:	715d                	addi	sp,sp,-80
ffffffffc02007c2:	f84a                	sd	s2,48(sp)
    return listelm->next;
ffffffffc02007c4:	00007917          	auipc	s2,0x7
ffffffffc02007c8:	85490913          	addi	s2,s2,-1964 # ffffffffc0207018 <free_area>
ffffffffc02007cc:	00893783          	ld	a5,8(s2)
ffffffffc02007d0:	e486                	sd	ra,72(sp)
ffffffffc02007d2:	e0a2                	sd	s0,64(sp)
ffffffffc02007d4:	fc26                	sd	s1,56(sp)
ffffffffc02007d6:	f44e                	sd	s3,40(sp)
ffffffffc02007d8:	f052                	sd	s4,32(sp)
ffffffffc02007da:	ec56                	sd	s5,24(sp)
ffffffffc02007dc:	e85a                	sd	s6,16(sp)
ffffffffc02007de:	e45e                	sd	s7,8(sp)
ffffffffc02007e0:	e062                	sd	s8,0(sp)
    int score = 0, sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02007e2:	2f278f63          	beq	a5,s2,ffffffffc0200ae0 <best_fit_check+0x320>
    int count = 0, total = 0;
ffffffffc02007e6:	4401                	li	s0,0
ffffffffc02007e8:	4481                	li	s1,0
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc02007ea:	ff07b703          	ld	a4,-16(a5)
ffffffffc02007ee:	8b09                	andi	a4,a4,2
ffffffffc02007f0:	2e070c63          	beqz	a4,ffffffffc0200ae8 <best_fit_check+0x328>
        count++, total += p->property;
ffffffffc02007f4:	ff87a703          	lw	a4,-8(a5)
ffffffffc02007f8:	679c                	ld	a5,8(a5)
ffffffffc02007fa:	2485                	addiw	s1,s1,1
ffffffffc02007fc:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02007fe:	ff2796e3          	bne	a5,s2,ffffffffc02007ea <best_fit_check+0x2a>
    }
    assert(total == nr_free_pages());
ffffffffc0200802:	89a2                	mv	s3,s0
ffffffffc0200804:	00d000ef          	jal	ffffffffc0201010 <nr_free_pages>
ffffffffc0200808:	3d351063          	bne	a0,s3,ffffffffc0200bc8 <best_fit_check+0x408>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020080c:	4505                	li	a0,1
ffffffffc020080e:	7ea000ef          	jal	ffffffffc0200ff8 <alloc_pages>
ffffffffc0200812:	8a2a                	mv	s4,a0
ffffffffc0200814:	3e050a63          	beqz	a0,ffffffffc0200c08 <best_fit_check+0x448>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200818:	4505                	li	a0,1
ffffffffc020081a:	7de000ef          	jal	ffffffffc0200ff8 <alloc_pages>
ffffffffc020081e:	89aa                	mv	s3,a0
ffffffffc0200820:	3c050463          	beqz	a0,ffffffffc0200be8 <best_fit_check+0x428>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200824:	4505                	li	a0,1
ffffffffc0200826:	7d2000ef          	jal	ffffffffc0200ff8 <alloc_pages>
ffffffffc020082a:	8aaa                	mv	s5,a0
ffffffffc020082c:	34050e63          	beqz	a0,ffffffffc0200b88 <best_fit_check+0x3c8>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200830:	2d3a0c63          	beq	s4,s3,ffffffffc0200b08 <best_fit_check+0x348>
ffffffffc0200834:	2caa0a63          	beq	s4,a0,ffffffffc0200b08 <best_fit_check+0x348>
ffffffffc0200838:	2ca98863          	beq	s3,a0,ffffffffc0200b08 <best_fit_check+0x348>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020083c:	000a2783          	lw	a5,0(s4)
ffffffffc0200840:	2e079463          	bnez	a5,ffffffffc0200b28 <best_fit_check+0x368>
ffffffffc0200844:	0009a783          	lw	a5,0(s3)
ffffffffc0200848:	2e079063          	bnez	a5,ffffffffc0200b28 <best_fit_check+0x368>
ffffffffc020084c:	411c                	lw	a5,0(a0)
ffffffffc020084e:	2c079d63          	bnez	a5,ffffffffc0200b28 <best_fit_check+0x368>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200852:	00007797          	auipc	a5,0x7
ffffffffc0200856:	81e7b783          	ld	a5,-2018(a5) # ffffffffc0207070 <pages>
ffffffffc020085a:	ccccd6b7          	lui	a3,0xccccd
ffffffffc020085e:	ccd68693          	addi	a3,a3,-819 # ffffffffcccccccd <end+0xcac5c55>
ffffffffc0200862:	02069613          	slli	a2,a3,0x20
ffffffffc0200866:	40fa0733          	sub	a4,s4,a5
ffffffffc020086a:	9636                	add	a2,a2,a3
ffffffffc020086c:	870d                	srai	a4,a4,0x3
ffffffffc020086e:	02c70733          	mul	a4,a4,a2
ffffffffc0200872:	00002597          	auipc	a1,0x2
ffffffffc0200876:	7be5b583          	ld	a1,1982(a1) # ffffffffc0203030 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020087a:	00006697          	auipc	a3,0x6
ffffffffc020087e:	7ee6b683          	ld	a3,2030(a3) # ffffffffc0207068 <npage>
ffffffffc0200882:	06b2                	slli	a3,a3,0xc
ffffffffc0200884:	972e                	add	a4,a4,a1

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200886:	0732                	slli	a4,a4,0xc
ffffffffc0200888:	2cd77063          	bgeu	a4,a3,ffffffffc0200b48 <best_fit_check+0x388>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020088c:	40f98733          	sub	a4,s3,a5
ffffffffc0200890:	870d                	srai	a4,a4,0x3
ffffffffc0200892:	02c70733          	mul	a4,a4,a2
ffffffffc0200896:	972e                	add	a4,a4,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200898:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020089a:	46d77763          	bgeu	a4,a3,ffffffffc0200d08 <best_fit_check+0x548>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020089e:	40f507b3          	sub	a5,a0,a5
ffffffffc02008a2:	878d                	srai	a5,a5,0x3
ffffffffc02008a4:	02c787b3          	mul	a5,a5,a2
ffffffffc02008a8:	97ae                	add	a5,a5,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc02008aa:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02008ac:	42d7fe63          	bgeu	a5,a3,ffffffffc0200ce8 <best_fit_check+0x528>
    assert(alloc_page() == NULL);
ffffffffc02008b0:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02008b2:	00093c03          	ld	s8,0(s2)
ffffffffc02008b6:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc02008ba:	00006b17          	auipc	s6,0x6
ffffffffc02008be:	76eb2b03          	lw	s6,1902(s6) # ffffffffc0207028 <free_area+0x10>
    elm->prev = elm->next = elm;
ffffffffc02008c2:	01293023          	sd	s2,0(s2)
ffffffffc02008c6:	01293423          	sd	s2,8(s2)
    nr_free = 0;
ffffffffc02008ca:	00006797          	auipc	a5,0x6
ffffffffc02008ce:	7407af23          	sw	zero,1886(a5) # ffffffffc0207028 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02008d2:	726000ef          	jal	ffffffffc0200ff8 <alloc_pages>
ffffffffc02008d6:	3e051963          	bnez	a0,ffffffffc0200cc8 <best_fit_check+0x508>
    free_page(p0);
ffffffffc02008da:	8552                	mv	a0,s4
ffffffffc02008dc:	4585                	li	a1,1
ffffffffc02008de:	726000ef          	jal	ffffffffc0201004 <free_pages>
    free_page(p1);
ffffffffc02008e2:	854e                	mv	a0,s3
ffffffffc02008e4:	4585                	li	a1,1
ffffffffc02008e6:	71e000ef          	jal	ffffffffc0201004 <free_pages>
    free_page(p2);
ffffffffc02008ea:	8556                	mv	a0,s5
ffffffffc02008ec:	4585                	li	a1,1
ffffffffc02008ee:	716000ef          	jal	ffffffffc0201004 <free_pages>
    assert(nr_free == 3);
ffffffffc02008f2:	00006717          	auipc	a4,0x6
ffffffffc02008f6:	73672703          	lw	a4,1846(a4) # ffffffffc0207028 <free_area+0x10>
ffffffffc02008fa:	478d                	li	a5,3
ffffffffc02008fc:	3af71663          	bne	a4,a5,ffffffffc0200ca8 <best_fit_check+0x4e8>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200900:	4505                	li	a0,1
ffffffffc0200902:	6f6000ef          	jal	ffffffffc0200ff8 <alloc_pages>
ffffffffc0200906:	89aa                	mv	s3,a0
ffffffffc0200908:	38050063          	beqz	a0,ffffffffc0200c88 <best_fit_check+0x4c8>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020090c:	4505                	li	a0,1
ffffffffc020090e:	6ea000ef          	jal	ffffffffc0200ff8 <alloc_pages>
ffffffffc0200912:	8aaa                	mv	s5,a0
ffffffffc0200914:	34050a63          	beqz	a0,ffffffffc0200c68 <best_fit_check+0x4a8>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200918:	4505                	li	a0,1
ffffffffc020091a:	6de000ef          	jal	ffffffffc0200ff8 <alloc_pages>
ffffffffc020091e:	8a2a                	mv	s4,a0
ffffffffc0200920:	32050463          	beqz	a0,ffffffffc0200c48 <best_fit_check+0x488>
    assert(alloc_page() == NULL);
ffffffffc0200924:	4505                	li	a0,1
ffffffffc0200926:	6d2000ef          	jal	ffffffffc0200ff8 <alloc_pages>
ffffffffc020092a:	2e051f63          	bnez	a0,ffffffffc0200c28 <best_fit_check+0x468>
    free_page(p0);
ffffffffc020092e:	4585                	li	a1,1
ffffffffc0200930:	854e                	mv	a0,s3
ffffffffc0200932:	6d2000ef          	jal	ffffffffc0201004 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200936:	00893783          	ld	a5,8(s2)
ffffffffc020093a:	23278763          	beq	a5,s2,ffffffffc0200b68 <best_fit_check+0x3a8>
    assert((p = alloc_page()) == p0);
ffffffffc020093e:	4505                	li	a0,1
ffffffffc0200940:	6b8000ef          	jal	ffffffffc0200ff8 <alloc_pages>
ffffffffc0200944:	5aa99263          	bne	s3,a0,ffffffffc0200ee8 <best_fit_check+0x728>
    assert(alloc_page() == NULL);
ffffffffc0200948:	4505                	li	a0,1
ffffffffc020094a:	6ae000ef          	jal	ffffffffc0200ff8 <alloc_pages>
ffffffffc020094e:	56051d63          	bnez	a0,ffffffffc0200ec8 <best_fit_check+0x708>
    assert(nr_free == 0);
ffffffffc0200952:	00006797          	auipc	a5,0x6
ffffffffc0200956:	6d67a783          	lw	a5,1750(a5) # ffffffffc0207028 <free_area+0x10>
ffffffffc020095a:	54079763          	bnez	a5,ffffffffc0200ea8 <best_fit_check+0x6e8>
    free_page(p);
ffffffffc020095e:	854e                	mv	a0,s3
ffffffffc0200960:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200962:	01893023          	sd	s8,0(s2)
ffffffffc0200966:	01793423          	sd	s7,8(s2)
    nr_free = nr_free_store;
ffffffffc020096a:	01692823          	sw	s6,16(s2)
    free_page(p);
ffffffffc020096e:	696000ef          	jal	ffffffffc0201004 <free_pages>
    free_page(p1);
ffffffffc0200972:	8556                	mv	a0,s5
ffffffffc0200974:	4585                	li	a1,1
ffffffffc0200976:	68e000ef          	jal	ffffffffc0201004 <free_pages>
    free_page(p2);
ffffffffc020097a:	8552                	mv	a0,s4
ffffffffc020097c:	4585                	li	a1,1
ffffffffc020097e:	686000ef          	jal	ffffffffc0201004 <free_pages>

    basic_check();

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
ffffffffc0200982:	4619                	li	a2,6
ffffffffc0200984:	4585                	li	a1,1
ffffffffc0200986:	00002517          	auipc	a0,0x2
ffffffffc020098a:	9b250513          	addi	a0,a0,-1614 # ffffffffc0202338 <etext+0x436>
ffffffffc020098e:	fbcff0ef          	jal	ffffffffc020014a <cprintf>
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200992:	4515                	li	a0,5
ffffffffc0200994:	664000ef          	jal	ffffffffc0200ff8 <alloc_pages>
ffffffffc0200998:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc020099a:	4e050763          	beqz	a0,ffffffffc0200e88 <best_fit_check+0x6c8>
    assert(!PageProperty(p0));
ffffffffc020099e:	651c                	ld	a5,8(a0)
ffffffffc02009a0:	8b89                	andi	a5,a5,2
ffffffffc02009a2:	4c079363          	bnez	a5,ffffffffc0200e68 <best_fit_check+0x6a8>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
ffffffffc02009a6:	4619                	li	a2,6
ffffffffc02009a8:	4589                	li	a1,2
ffffffffc02009aa:	00002517          	auipc	a0,0x2
ffffffffc02009ae:	98e50513          	addi	a0,a0,-1650 # ffffffffc0202338 <etext+0x436>
ffffffffc02009b2:	f98ff0ef          	jal	ffffffffc020014a <cprintf>
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc02009b6:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02009b8:	00093b03          	ld	s6,0(s2)
ffffffffc02009bc:	00893a83          	ld	s5,8(s2)
ffffffffc02009c0:	01293023          	sd	s2,0(s2)
ffffffffc02009c4:	01293423          	sd	s2,8(s2)
    assert(alloc_page() == NULL);
ffffffffc02009c8:	630000ef          	jal	ffffffffc0200ff8 <alloc_pages>
ffffffffc02009cc:	46051e63          	bnez	a0,ffffffffc0200e48 <best_fit_check+0x688>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
ffffffffc02009d0:	4619                	li	a2,6
ffffffffc02009d2:	458d                	li	a1,3
ffffffffc02009d4:	00002517          	auipc	a0,0x2
ffffffffc02009d8:	96450513          	addi	a0,a0,-1692 # ffffffffc0202338 <etext+0x436>
ffffffffc02009dc:	f6eff0ef          	jal	ffffffffc020014a <cprintf>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc02009e0:	02898513          	addi	a0,s3,40
ffffffffc02009e4:	4589                	li	a1,2
    unsigned int nr_free_store = nr_free;
ffffffffc02009e6:	00006b97          	auipc	s7,0x6
ffffffffc02009ea:	642bab83          	lw	s7,1602(s7) # ffffffffc0207028 <free_area+0x10>
    free_pages(p0 + 4, 1);
ffffffffc02009ee:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc02009f2:	00006797          	auipc	a5,0x6
ffffffffc02009f6:	6207ab23          	sw	zero,1590(a5) # ffffffffc0207028 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc02009fa:	60a000ef          	jal	ffffffffc0201004 <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc02009fe:	8562                	mv	a0,s8
ffffffffc0200a00:	4585                	li	a1,1
ffffffffc0200a02:	602000ef          	jal	ffffffffc0201004 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200a06:	4511                	li	a0,4
ffffffffc0200a08:	5f0000ef          	jal	ffffffffc0200ff8 <alloc_pages>
ffffffffc0200a0c:	40051e63          	bnez	a0,ffffffffc0200e28 <best_fit_check+0x668>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200a10:	0309b783          	ld	a5,48(s3)
ffffffffc0200a14:	8b89                	andi	a5,a5,2
ffffffffc0200a16:	3e078963          	beqz	a5,ffffffffc0200e08 <best_fit_check+0x648>
ffffffffc0200a1a:	0389a703          	lw	a4,56(s3)
ffffffffc0200a1e:	4789                	li	a5,2
ffffffffc0200a20:	3ef71463          	bne	a4,a5,ffffffffc0200e08 <best_fit_check+0x648>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200a24:	4505                	li	a0,1
ffffffffc0200a26:	5d2000ef          	jal	ffffffffc0200ff8 <alloc_pages>
ffffffffc0200a2a:	8a2a                	mv	s4,a0
ffffffffc0200a2c:	3a050e63          	beqz	a0,ffffffffc0200de8 <best_fit_check+0x628>
    assert(alloc_pages(2) != NULL);
ffffffffc0200a30:	4509                	li	a0,2
ffffffffc0200a32:	5c6000ef          	jal	ffffffffc0200ff8 <alloc_pages>
ffffffffc0200a36:	38050963          	beqz	a0,ffffffffc0200dc8 <best_fit_check+0x608>
    assert(p0 + 4 == p1);
ffffffffc0200a3a:	374c1763          	bne	s8,s4,ffffffffc0200da8 <best_fit_check+0x5e8>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
ffffffffc0200a3e:	4619                	li	a2,6
ffffffffc0200a40:	4591                	li	a1,4
ffffffffc0200a42:	00002517          	auipc	a0,0x2
ffffffffc0200a46:	8f650513          	addi	a0,a0,-1802 # ffffffffc0202338 <etext+0x436>
ffffffffc0200a4a:	f00ff0ef          	jal	ffffffffc020014a <cprintf>
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc0200a4e:	854e                	mv	a0,s3
ffffffffc0200a50:	4595                	li	a1,5
ffffffffc0200a52:	5b2000ef          	jal	ffffffffc0201004 <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200a56:	4515                	li	a0,5
ffffffffc0200a58:	5a0000ef          	jal	ffffffffc0200ff8 <alloc_pages>
ffffffffc0200a5c:	89aa                	mv	s3,a0
ffffffffc0200a5e:	32050563          	beqz	a0,ffffffffc0200d88 <best_fit_check+0x5c8>
    assert(alloc_page() == NULL);
ffffffffc0200a62:	4505                	li	a0,1
ffffffffc0200a64:	594000ef          	jal	ffffffffc0200ff8 <alloc_pages>
ffffffffc0200a68:	30051063          	bnez	a0,ffffffffc0200d68 <best_fit_check+0x5a8>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
ffffffffc0200a6c:	4619                	li	a2,6
ffffffffc0200a6e:	4595                	li	a1,5
ffffffffc0200a70:	00002517          	auipc	a0,0x2
ffffffffc0200a74:	8c850513          	addi	a0,a0,-1848 # ffffffffc0202338 <etext+0x436>
ffffffffc0200a78:	ed2ff0ef          	jal	ffffffffc020014a <cprintf>
    #endif
    assert(nr_free == 0);
ffffffffc0200a7c:	00006797          	auipc	a5,0x6
ffffffffc0200a80:	5ac7a783          	lw	a5,1452(a5) # ffffffffc0207028 <free_area+0x10>
ffffffffc0200a84:	2c079263          	bnez	a5,ffffffffc0200d48 <best_fit_check+0x588>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200a88:	854e                	mv	a0,s3
ffffffffc0200a8a:	4595                	li	a1,5
    nr_free = nr_free_store;
ffffffffc0200a8c:	01792823          	sw	s7,16(s2)
    free_list = free_list_store;
ffffffffc0200a90:	01693023          	sd	s6,0(s2)
ffffffffc0200a94:	01593423          	sd	s5,8(s2)
    free_pages(p0, 5);
ffffffffc0200a98:	56c000ef          	jal	ffffffffc0201004 <free_pages>
    return listelm->next;
ffffffffc0200a9c:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200aa0:	01278963          	beq	a5,s2,ffffffffc0200ab2 <best_fit_check+0x2f2>
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc0200aa4:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200aa8:	679c                	ld	a5,8(a5)
ffffffffc0200aaa:	34fd                	addiw	s1,s1,-1
ffffffffc0200aac:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200aae:	ff279be3          	bne	a5,s2,ffffffffc0200aa4 <best_fit_check+0x2e4>
    }
    assert(count == 0);
ffffffffc0200ab2:	26049b63          	bnez	s1,ffffffffc0200d28 <best_fit_check+0x568>
    assert(total == 0);
ffffffffc0200ab6:	0e041963          	bnez	s0,ffffffffc0200ba8 <best_fit_check+0x3e8>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
}
ffffffffc0200aba:	6406                	ld	s0,64(sp)
ffffffffc0200abc:	60a6                	ld	ra,72(sp)
ffffffffc0200abe:	74e2                	ld	s1,56(sp)
ffffffffc0200ac0:	7942                	ld	s2,48(sp)
ffffffffc0200ac2:	79a2                	ld	s3,40(sp)
ffffffffc0200ac4:	7a02                	ld	s4,32(sp)
ffffffffc0200ac6:	6ae2                	ld	s5,24(sp)
ffffffffc0200ac8:	6b42                	ld	s6,16(sp)
ffffffffc0200aca:	6ba2                	ld	s7,8(sp)
ffffffffc0200acc:	6c02                	ld	s8,0(sp)
    cprintf("grading: %d / %d points\n", score, sumscore);
ffffffffc0200ace:	4619                	li	a2,6
ffffffffc0200ad0:	85b2                	mv	a1,a2
ffffffffc0200ad2:	00002517          	auipc	a0,0x2
ffffffffc0200ad6:	86650513          	addi	a0,a0,-1946 # ffffffffc0202338 <etext+0x436>
}
ffffffffc0200ada:	6161                	addi	sp,sp,80
    cprintf("grading: %d / %d points\n", score, sumscore);
ffffffffc0200adc:	e6eff06f          	j	ffffffffc020014a <cprintf>
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200ae0:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200ae2:	4401                	li	s0,0
ffffffffc0200ae4:	4481                	li	s1,0
ffffffffc0200ae6:	bb39                	j	ffffffffc0200804 <best_fit_check+0x44>
        assert(PageProperty(p));
ffffffffc0200ae8:	00001697          	auipc	a3,0x1
ffffffffc0200aec:	6a068693          	addi	a3,a3,1696 # ffffffffc0202188 <etext+0x286>
ffffffffc0200af0:	00001617          	auipc	a2,0x1
ffffffffc0200af4:	66860613          	addi	a2,a2,1640 # ffffffffc0202158 <etext+0x256>
ffffffffc0200af8:	0bd00593          	li	a1,189
ffffffffc0200afc:	00001517          	auipc	a0,0x1
ffffffffc0200b00:	67450513          	addi	a0,a0,1652 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200b04:	ec8ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200b08:	00001697          	auipc	a3,0x1
ffffffffc0200b0c:	71068693          	addi	a3,a3,1808 # ffffffffc0202218 <etext+0x316>
ffffffffc0200b10:	00001617          	auipc	a2,0x1
ffffffffc0200b14:	64860613          	addi	a2,a2,1608 # ffffffffc0202158 <etext+0x256>
ffffffffc0200b18:	08b00593          	li	a1,139
ffffffffc0200b1c:	00001517          	auipc	a0,0x1
ffffffffc0200b20:	65450513          	addi	a0,a0,1620 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200b24:	ea8ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200b28:	00001697          	auipc	a3,0x1
ffffffffc0200b2c:	71868693          	addi	a3,a3,1816 # ffffffffc0202240 <etext+0x33e>
ffffffffc0200b30:	00001617          	auipc	a2,0x1
ffffffffc0200b34:	62860613          	addi	a2,a2,1576 # ffffffffc0202158 <etext+0x256>
ffffffffc0200b38:	08c00593          	li	a1,140
ffffffffc0200b3c:	00001517          	auipc	a0,0x1
ffffffffc0200b40:	63450513          	addi	a0,a0,1588 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200b44:	e88ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200b48:	00001697          	auipc	a3,0x1
ffffffffc0200b4c:	73868693          	addi	a3,a3,1848 # ffffffffc0202280 <etext+0x37e>
ffffffffc0200b50:	00001617          	auipc	a2,0x1
ffffffffc0200b54:	60860613          	addi	a2,a2,1544 # ffffffffc0202158 <etext+0x256>
ffffffffc0200b58:	08e00593          	li	a1,142
ffffffffc0200b5c:	00001517          	auipc	a0,0x1
ffffffffc0200b60:	61450513          	addi	a0,a0,1556 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200b64:	e68ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200b68:	00001697          	auipc	a3,0x1
ffffffffc0200b6c:	78868693          	addi	a3,a3,1928 # ffffffffc02022f0 <etext+0x3ee>
ffffffffc0200b70:	00001617          	auipc	a2,0x1
ffffffffc0200b74:	5e860613          	addi	a2,a2,1512 # ffffffffc0202158 <etext+0x256>
ffffffffc0200b78:	0a700593          	li	a1,167
ffffffffc0200b7c:	00001517          	auipc	a0,0x1
ffffffffc0200b80:	5f450513          	addi	a0,a0,1524 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200b84:	e48ff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200b88:	00001697          	auipc	a3,0x1
ffffffffc0200b8c:	67068693          	addi	a3,a3,1648 # ffffffffc02021f8 <etext+0x2f6>
ffffffffc0200b90:	00001617          	auipc	a2,0x1
ffffffffc0200b94:	5c860613          	addi	a2,a2,1480 # ffffffffc0202158 <etext+0x256>
ffffffffc0200b98:	08900593          	li	a1,137
ffffffffc0200b9c:	00001517          	auipc	a0,0x1
ffffffffc0200ba0:	5d450513          	addi	a0,a0,1492 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200ba4:	e28ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(total == 0);
ffffffffc0200ba8:	00002697          	auipc	a3,0x2
ffffffffc0200bac:	89868693          	addi	a3,a3,-1896 # ffffffffc0202440 <etext+0x53e>
ffffffffc0200bb0:	00001617          	auipc	a2,0x1
ffffffffc0200bb4:	5a860613          	addi	a2,a2,1448 # ffffffffc0202158 <etext+0x256>
ffffffffc0200bb8:	0ff00593          	li	a1,255
ffffffffc0200bbc:	00001517          	auipc	a0,0x1
ffffffffc0200bc0:	5b450513          	addi	a0,a0,1460 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200bc4:	e08ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(total == nr_free_pages());
ffffffffc0200bc8:	00001697          	auipc	a3,0x1
ffffffffc0200bcc:	5d068693          	addi	a3,a3,1488 # ffffffffc0202198 <etext+0x296>
ffffffffc0200bd0:	00001617          	auipc	a2,0x1
ffffffffc0200bd4:	58860613          	addi	a2,a2,1416 # ffffffffc0202158 <etext+0x256>
ffffffffc0200bd8:	0c000593          	li	a1,192
ffffffffc0200bdc:	00001517          	auipc	a0,0x1
ffffffffc0200be0:	59450513          	addi	a0,a0,1428 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200be4:	de8ff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200be8:	00001697          	auipc	a3,0x1
ffffffffc0200bec:	5f068693          	addi	a3,a3,1520 # ffffffffc02021d8 <etext+0x2d6>
ffffffffc0200bf0:	00001617          	auipc	a2,0x1
ffffffffc0200bf4:	56860613          	addi	a2,a2,1384 # ffffffffc0202158 <etext+0x256>
ffffffffc0200bf8:	08800593          	li	a1,136
ffffffffc0200bfc:	00001517          	auipc	a0,0x1
ffffffffc0200c00:	57450513          	addi	a0,a0,1396 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200c04:	dc8ff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200c08:	00001697          	auipc	a3,0x1
ffffffffc0200c0c:	5b068693          	addi	a3,a3,1456 # ffffffffc02021b8 <etext+0x2b6>
ffffffffc0200c10:	00001617          	auipc	a2,0x1
ffffffffc0200c14:	54860613          	addi	a2,a2,1352 # ffffffffc0202158 <etext+0x256>
ffffffffc0200c18:	08700593          	li	a1,135
ffffffffc0200c1c:	00001517          	auipc	a0,0x1
ffffffffc0200c20:	55450513          	addi	a0,a0,1364 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200c24:	da8ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200c28:	00002697          	auipc	a3,0x2
ffffffffc0200c2c:	c1068693          	addi	a3,a3,-1008 # ffffffffc0202838 <etext+0x936>
ffffffffc0200c30:	00001617          	auipc	a2,0x1
ffffffffc0200c34:	52860613          	addi	a2,a2,1320 # ffffffffc0202158 <etext+0x256>
ffffffffc0200c38:	0a400593          	li	a1,164
ffffffffc0200c3c:	00001517          	auipc	a0,0x1
ffffffffc0200c40:	53450513          	addi	a0,a0,1332 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200c44:	d88ff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200c48:	00001697          	auipc	a3,0x1
ffffffffc0200c4c:	5b068693          	addi	a3,a3,1456 # ffffffffc02021f8 <etext+0x2f6>
ffffffffc0200c50:	00001617          	auipc	a2,0x1
ffffffffc0200c54:	50860613          	addi	a2,a2,1288 # ffffffffc0202158 <etext+0x256>
ffffffffc0200c58:	0a200593          	li	a1,162
ffffffffc0200c5c:	00001517          	auipc	a0,0x1
ffffffffc0200c60:	51450513          	addi	a0,a0,1300 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200c64:	d68ff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200c68:	00001697          	auipc	a3,0x1
ffffffffc0200c6c:	57068693          	addi	a3,a3,1392 # ffffffffc02021d8 <etext+0x2d6>
ffffffffc0200c70:	00001617          	auipc	a2,0x1
ffffffffc0200c74:	4e860613          	addi	a2,a2,1256 # ffffffffc0202158 <etext+0x256>
ffffffffc0200c78:	0a100593          	li	a1,161
ffffffffc0200c7c:	00001517          	auipc	a0,0x1
ffffffffc0200c80:	4f450513          	addi	a0,a0,1268 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200c84:	d48ff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200c88:	00001697          	auipc	a3,0x1
ffffffffc0200c8c:	53068693          	addi	a3,a3,1328 # ffffffffc02021b8 <etext+0x2b6>
ffffffffc0200c90:	00001617          	auipc	a2,0x1
ffffffffc0200c94:	4c860613          	addi	a2,a2,1224 # ffffffffc0202158 <etext+0x256>
ffffffffc0200c98:	0a000593          	li	a1,160
ffffffffc0200c9c:	00001517          	auipc	a0,0x1
ffffffffc0200ca0:	4d450513          	addi	a0,a0,1236 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200ca4:	d28ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(nr_free == 3);
ffffffffc0200ca8:	00001697          	auipc	a3,0x1
ffffffffc0200cac:	63868693          	addi	a3,a3,1592 # ffffffffc02022e0 <etext+0x3de>
ffffffffc0200cb0:	00001617          	auipc	a2,0x1
ffffffffc0200cb4:	4a860613          	addi	a2,a2,1192 # ffffffffc0202158 <etext+0x256>
ffffffffc0200cb8:	09e00593          	li	a1,158
ffffffffc0200cbc:	00001517          	auipc	a0,0x1
ffffffffc0200cc0:	4b450513          	addi	a0,a0,1204 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200cc4:	d08ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200cc8:	00002697          	auipc	a3,0x2
ffffffffc0200ccc:	b7068693          	addi	a3,a3,-1168 # ffffffffc0202838 <etext+0x936>
ffffffffc0200cd0:	00001617          	auipc	a2,0x1
ffffffffc0200cd4:	48860613          	addi	a2,a2,1160 # ffffffffc0202158 <etext+0x256>
ffffffffc0200cd8:	09900593          	li	a1,153
ffffffffc0200cdc:	00001517          	auipc	a0,0x1
ffffffffc0200ce0:	49450513          	addi	a0,a0,1172 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200ce4:	ce8ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200ce8:	00001697          	auipc	a3,0x1
ffffffffc0200cec:	5d868693          	addi	a3,a3,1496 # ffffffffc02022c0 <etext+0x3be>
ffffffffc0200cf0:	00001617          	auipc	a2,0x1
ffffffffc0200cf4:	46860613          	addi	a2,a2,1128 # ffffffffc0202158 <etext+0x256>
ffffffffc0200cf8:	09000593          	li	a1,144
ffffffffc0200cfc:	00001517          	auipc	a0,0x1
ffffffffc0200d00:	47450513          	addi	a0,a0,1140 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200d04:	cc8ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200d08:	00001697          	auipc	a3,0x1
ffffffffc0200d0c:	59868693          	addi	a3,a3,1432 # ffffffffc02022a0 <etext+0x39e>
ffffffffc0200d10:	00001617          	auipc	a2,0x1
ffffffffc0200d14:	44860613          	addi	a2,a2,1096 # ffffffffc0202158 <etext+0x256>
ffffffffc0200d18:	08f00593          	li	a1,143
ffffffffc0200d1c:	00001517          	auipc	a0,0x1
ffffffffc0200d20:	45450513          	addi	a0,a0,1108 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200d24:	ca8ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(count == 0);
ffffffffc0200d28:	00001697          	auipc	a3,0x1
ffffffffc0200d2c:	70868693          	addi	a3,a3,1800 # ffffffffc0202430 <etext+0x52e>
ffffffffc0200d30:	00001617          	auipc	a2,0x1
ffffffffc0200d34:	42860613          	addi	a2,a2,1064 # ffffffffc0202158 <etext+0x256>
ffffffffc0200d38:	0fe00593          	li	a1,254
ffffffffc0200d3c:	00001517          	auipc	a0,0x1
ffffffffc0200d40:	43450513          	addi	a0,a0,1076 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200d44:	c88ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(nr_free == 0);
ffffffffc0200d48:	00001697          	auipc	a3,0x1
ffffffffc0200d4c:	5e068693          	addi	a3,a3,1504 # ffffffffc0202328 <etext+0x426>
ffffffffc0200d50:	00001617          	auipc	a2,0x1
ffffffffc0200d54:	40860613          	addi	a2,a2,1032 # ffffffffc0202158 <etext+0x256>
ffffffffc0200d58:	0f300593          	li	a1,243
ffffffffc0200d5c:	00001517          	auipc	a0,0x1
ffffffffc0200d60:	41450513          	addi	a0,a0,1044 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200d64:	c68ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200d68:	00002697          	auipc	a3,0x2
ffffffffc0200d6c:	ad068693          	addi	a3,a3,-1328 # ffffffffc0202838 <etext+0x936>
ffffffffc0200d70:	00001617          	auipc	a2,0x1
ffffffffc0200d74:	3e860613          	addi	a2,a2,1000 # ffffffffc0202158 <etext+0x256>
ffffffffc0200d78:	0ed00593          	li	a1,237
ffffffffc0200d7c:	00001517          	auipc	a0,0x1
ffffffffc0200d80:	3f450513          	addi	a0,a0,1012 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200d84:	c48ff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200d88:	00001697          	auipc	a3,0x1
ffffffffc0200d8c:	68868693          	addi	a3,a3,1672 # ffffffffc0202410 <etext+0x50e>
ffffffffc0200d90:	00001617          	auipc	a2,0x1
ffffffffc0200d94:	3c860613          	addi	a2,a2,968 # ffffffffc0202158 <etext+0x256>
ffffffffc0200d98:	0ec00593          	li	a1,236
ffffffffc0200d9c:	00001517          	auipc	a0,0x1
ffffffffc0200da0:	3d450513          	addi	a0,a0,980 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200da4:	c28ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(p0 + 4 == p1);
ffffffffc0200da8:	00001697          	auipc	a3,0x1
ffffffffc0200dac:	65868693          	addi	a3,a3,1624 # ffffffffc0202400 <etext+0x4fe>
ffffffffc0200db0:	00001617          	auipc	a2,0x1
ffffffffc0200db4:	3a860613          	addi	a2,a2,936 # ffffffffc0202158 <etext+0x256>
ffffffffc0200db8:	0e400593          	li	a1,228
ffffffffc0200dbc:	00001517          	auipc	a0,0x1
ffffffffc0200dc0:	3b450513          	addi	a0,a0,948 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200dc4:	c08ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_pages(2) != NULL);
ffffffffc0200dc8:	00001697          	auipc	a3,0x1
ffffffffc0200dcc:	62068693          	addi	a3,a3,1568 # ffffffffc02023e8 <etext+0x4e6>
ffffffffc0200dd0:	00001617          	auipc	a2,0x1
ffffffffc0200dd4:	38860613          	addi	a2,a2,904 # ffffffffc0202158 <etext+0x256>
ffffffffc0200dd8:	0e300593          	li	a1,227
ffffffffc0200ddc:	00001517          	auipc	a0,0x1
ffffffffc0200de0:	39450513          	addi	a0,a0,916 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200de4:	be8ff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200de8:	00001697          	auipc	a3,0x1
ffffffffc0200dec:	5e068693          	addi	a3,a3,1504 # ffffffffc02023c8 <etext+0x4c6>
ffffffffc0200df0:	00001617          	auipc	a2,0x1
ffffffffc0200df4:	36860613          	addi	a2,a2,872 # ffffffffc0202158 <etext+0x256>
ffffffffc0200df8:	0e200593          	li	a1,226
ffffffffc0200dfc:	00001517          	auipc	a0,0x1
ffffffffc0200e00:	37450513          	addi	a0,a0,884 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200e04:	bc8ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200e08:	00001697          	auipc	a3,0x1
ffffffffc0200e0c:	59068693          	addi	a3,a3,1424 # ffffffffc0202398 <etext+0x496>
ffffffffc0200e10:	00001617          	auipc	a2,0x1
ffffffffc0200e14:	34860613          	addi	a2,a2,840 # ffffffffc0202158 <etext+0x256>
ffffffffc0200e18:	0e000593          	li	a1,224
ffffffffc0200e1c:	00001517          	auipc	a0,0x1
ffffffffc0200e20:	35450513          	addi	a0,a0,852 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200e24:	ba8ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0200e28:	00001697          	auipc	a3,0x1
ffffffffc0200e2c:	55868693          	addi	a3,a3,1368 # ffffffffc0202380 <etext+0x47e>
ffffffffc0200e30:	00001617          	auipc	a2,0x1
ffffffffc0200e34:	32860613          	addi	a2,a2,808 # ffffffffc0202158 <etext+0x256>
ffffffffc0200e38:	0df00593          	li	a1,223
ffffffffc0200e3c:	00001517          	auipc	a0,0x1
ffffffffc0200e40:	33450513          	addi	a0,a0,820 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200e44:	b88ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200e48:	00002697          	auipc	a3,0x2
ffffffffc0200e4c:	9f068693          	addi	a3,a3,-1552 # ffffffffc0202838 <etext+0x936>
ffffffffc0200e50:	00001617          	auipc	a2,0x1
ffffffffc0200e54:	30860613          	addi	a2,a2,776 # ffffffffc0202158 <etext+0x256>
ffffffffc0200e58:	0d300593          	li	a1,211
ffffffffc0200e5c:	00001517          	auipc	a0,0x1
ffffffffc0200e60:	31450513          	addi	a0,a0,788 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200e64:	b68ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(!PageProperty(p0));
ffffffffc0200e68:	00001697          	auipc	a3,0x1
ffffffffc0200e6c:	50068693          	addi	a3,a3,1280 # ffffffffc0202368 <etext+0x466>
ffffffffc0200e70:	00001617          	auipc	a2,0x1
ffffffffc0200e74:	2e860613          	addi	a2,a2,744 # ffffffffc0202158 <etext+0x256>
ffffffffc0200e78:	0ca00593          	li	a1,202
ffffffffc0200e7c:	00001517          	auipc	a0,0x1
ffffffffc0200e80:	2f450513          	addi	a0,a0,756 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200e84:	b48ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(p0 != NULL);
ffffffffc0200e88:	00001697          	auipc	a3,0x1
ffffffffc0200e8c:	4d068693          	addi	a3,a3,1232 # ffffffffc0202358 <etext+0x456>
ffffffffc0200e90:	00001617          	auipc	a2,0x1
ffffffffc0200e94:	2c860613          	addi	a2,a2,712 # ffffffffc0202158 <etext+0x256>
ffffffffc0200e98:	0c900593          	li	a1,201
ffffffffc0200e9c:	00001517          	auipc	a0,0x1
ffffffffc0200ea0:	2d450513          	addi	a0,a0,724 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200ea4:	b28ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(nr_free == 0);
ffffffffc0200ea8:	00001697          	auipc	a3,0x1
ffffffffc0200eac:	48068693          	addi	a3,a3,1152 # ffffffffc0202328 <etext+0x426>
ffffffffc0200eb0:	00001617          	auipc	a2,0x1
ffffffffc0200eb4:	2a860613          	addi	a2,a2,680 # ffffffffc0202158 <etext+0x256>
ffffffffc0200eb8:	0ad00593          	li	a1,173
ffffffffc0200ebc:	00001517          	auipc	a0,0x1
ffffffffc0200ec0:	2b450513          	addi	a0,a0,692 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200ec4:	b08ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200ec8:	00002697          	auipc	a3,0x2
ffffffffc0200ecc:	97068693          	addi	a3,a3,-1680 # ffffffffc0202838 <etext+0x936>
ffffffffc0200ed0:	00001617          	auipc	a2,0x1
ffffffffc0200ed4:	28860613          	addi	a2,a2,648 # ffffffffc0202158 <etext+0x256>
ffffffffc0200ed8:	0ab00593          	li	a1,171
ffffffffc0200edc:	00001517          	auipc	a0,0x1
ffffffffc0200ee0:	29450513          	addi	a0,a0,660 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200ee4:	ae8ff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200ee8:	00001697          	auipc	a3,0x1
ffffffffc0200eec:	42068693          	addi	a3,a3,1056 # ffffffffc0202308 <etext+0x406>
ffffffffc0200ef0:	00001617          	auipc	a2,0x1
ffffffffc0200ef4:	26860613          	addi	a2,a2,616 # ffffffffc0202158 <etext+0x256>
ffffffffc0200ef8:	0aa00593          	li	a1,170
ffffffffc0200efc:	00001517          	auipc	a0,0x1
ffffffffc0200f00:	27450513          	addi	a0,a0,628 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200f04:	ac8ff0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc0200f08 <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0200f08:	1141                	addi	sp,sp,-16
ffffffffc0200f0a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200f0c:	c9b1                	beqz	a1,ffffffffc0200f60 <best_fit_free_pages+0x58>
    for (struct Page *p = base; p != base + n; p++) {
ffffffffc0200f0e:	00259713          	slli	a4,a1,0x2
ffffffffc0200f12:	972e                	add	a4,a4,a1
ffffffffc0200f14:	070e                	slli	a4,a4,0x3
ffffffffc0200f16:	00e506b3          	add	a3,a0,a4
ffffffffc0200f1a:	87aa                	mv	a5,a0
ffffffffc0200f1c:	cf11                	beqz	a4,ffffffffc0200f38 <best_fit_free_pages+0x30>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200f1e:	6798                	ld	a4,8(a5)
ffffffffc0200f20:	8b0d                	andi	a4,a4,3
ffffffffc0200f22:	ef19                	bnez	a4,ffffffffc0200f40 <best_fit_free_pages+0x38>
        p->flags = p->property = 0;
ffffffffc0200f24:	0007a823          	sw	zero,16(a5)
ffffffffc0200f28:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200f2c:	0007a023          	sw	zero,0(a5)
    for (struct Page *p = base; p != base + n; p++) {
ffffffffc0200f30:	02878793          	addi	a5,a5,40
ffffffffc0200f34:	fed795e3          	bne	a5,a3,ffffffffc0200f1e <best_fit_free_pages+0x16>
}
ffffffffc0200f38:	60a2                	ld	ra,8(sp)
ffffffffc0200f3a:	0141                	addi	sp,sp,16
    best_fit_insert(base, n);
ffffffffc0200f3c:	e88ff06f          	j	ffffffffc02005c4 <best_fit_insert>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200f40:	00001697          	auipc	a3,0x1
ffffffffc0200f44:	51068693          	addi	a3,a3,1296 # ffffffffc0202450 <etext+0x54e>
ffffffffc0200f48:	00001617          	auipc	a2,0x1
ffffffffc0200f4c:	21060613          	addi	a2,a2,528 # ffffffffc0202158 <etext+0x256>
ffffffffc0200f50:	06c00593          	li	a1,108
ffffffffc0200f54:	00001517          	auipc	a0,0x1
ffffffffc0200f58:	21c50513          	addi	a0,a0,540 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200f5c:	a70ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(n > 0);
ffffffffc0200f60:	00001697          	auipc	a3,0x1
ffffffffc0200f64:	1f068693          	addi	a3,a3,496 # ffffffffc0202150 <etext+0x24e>
ffffffffc0200f68:	00001617          	auipc	a2,0x1
ffffffffc0200f6c:	1f060613          	addi	a2,a2,496 # ffffffffc0202158 <etext+0x256>
ffffffffc0200f70:	06a00593          	li	a1,106
ffffffffc0200f74:	00001517          	auipc	a0,0x1
ffffffffc0200f78:	1fc50513          	addi	a0,a0,508 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200f7c:	a50ff0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc0200f80 <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc0200f80:	1141                	addi	sp,sp,-16
ffffffffc0200f82:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200f84:	c9b1                	beqz	a1,ffffffffc0200fd8 <best_fit_init_memmap+0x58>
    for (struct Page *p = base; p != base + n; p++) {
ffffffffc0200f86:	00259713          	slli	a4,a1,0x2
ffffffffc0200f8a:	972e                	add	a4,a4,a1
ffffffffc0200f8c:	070e                	slli	a4,a4,0x3
ffffffffc0200f8e:	00e506b3          	add	a3,a0,a4
ffffffffc0200f92:	87aa                	mv	a5,a0
ffffffffc0200f94:	cf11                	beqz	a4,ffffffffc0200fb0 <best_fit_init_memmap+0x30>
        assert(PageReserved(p));
ffffffffc0200f96:	6798                	ld	a4,8(a5)
ffffffffc0200f98:	8b05                	andi	a4,a4,1
ffffffffc0200f9a:	cf19                	beqz	a4,ffffffffc0200fb8 <best_fit_init_memmap+0x38>
        p->flags = p->property = 0;
ffffffffc0200f9c:	0007a823          	sw	zero,16(a5)
ffffffffc0200fa0:	0007b423          	sd	zero,8(a5)
ffffffffc0200fa4:	0007a023          	sw	zero,0(a5)
    for (struct Page *p = base; p != base + n; p++) {
ffffffffc0200fa8:	02878793          	addi	a5,a5,40
ffffffffc0200fac:	fed795e3          	bne	a5,a3,ffffffffc0200f96 <best_fit_init_memmap+0x16>
}
ffffffffc0200fb0:	60a2                	ld	ra,8(sp)
ffffffffc0200fb2:	0141                	addi	sp,sp,16
    best_fit_insert(base, n);
ffffffffc0200fb4:	e10ff06f          	j	ffffffffc02005c4 <best_fit_insert>
        assert(PageReserved(p));
ffffffffc0200fb8:	00001697          	auipc	a3,0x1
ffffffffc0200fbc:	4c068693          	addi	a3,a3,1216 # ffffffffc0202478 <etext+0x576>
ffffffffc0200fc0:	00001617          	auipc	a2,0x1
ffffffffc0200fc4:	19860613          	addi	a2,a2,408 # ffffffffc0202158 <etext+0x256>
ffffffffc0200fc8:	03c00593          	li	a1,60
ffffffffc0200fcc:	00001517          	auipc	a0,0x1
ffffffffc0200fd0:	1a450513          	addi	a0,a0,420 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200fd4:	9f8ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(n > 0);
ffffffffc0200fd8:	00001697          	auipc	a3,0x1
ffffffffc0200fdc:	17868693          	addi	a3,a3,376 # ffffffffc0202150 <etext+0x24e>
ffffffffc0200fe0:	00001617          	auipc	a2,0x1
ffffffffc0200fe4:	17860613          	addi	a2,a2,376 # ffffffffc0202158 <etext+0x256>
ffffffffc0200fe8:	03a00593          	li	a1,58
ffffffffc0200fec:	00001517          	auipc	a0,0x1
ffffffffc0200ff0:	18450513          	addi	a0,a0,388 # ffffffffc0202170 <etext+0x26e>
ffffffffc0200ff4:	9d8ff0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc0200ff8 <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc0200ff8:	00006797          	auipc	a5,0x6
ffffffffc0200ffc:	0507b783          	ld	a5,80(a5) # ffffffffc0207048 <pmm_manager>
ffffffffc0201000:	6f9c                	ld	a5,24(a5)
ffffffffc0201002:	8782                	jr	a5

ffffffffc0201004 <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc0201004:	00006797          	auipc	a5,0x6
ffffffffc0201008:	0447b783          	ld	a5,68(a5) # ffffffffc0207048 <pmm_manager>
ffffffffc020100c:	739c                	ld	a5,32(a5)
ffffffffc020100e:	8782                	jr	a5

ffffffffc0201010 <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc0201010:	00006797          	auipc	a5,0x6
ffffffffc0201014:	0387b783          	ld	a5,56(a5) # ffffffffc0207048 <pmm_manager>
ffffffffc0201018:	779c                	ld	a5,40(a5)
ffffffffc020101a:	8782                	jr	a5

ffffffffc020101c <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc020101c:	00002797          	auipc	a5,0x2
ffffffffc0201020:	e4c78793          	addi	a5,a5,-436 # ffffffffc0202e68 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201024:	638c                	ld	a1,0(a5)
    }
    init_memmap(pa2page(freemem), (maxpa - freemem) / PGSIZE);
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0201026:	7179                	addi	sp,sp,-48
ffffffffc0201028:	f406                	sd	ra,40(sp)
ffffffffc020102a:	f022                	sd	s0,32(sp)
ffffffffc020102c:	ec26                	sd	s1,24(sp)
ffffffffc020102e:	e44e                	sd	s3,8(sp)
ffffffffc0201030:	e84a                	sd	s2,16(sp)
ffffffffc0201032:	e052                	sd	s4,0(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201034:	00006417          	auipc	s0,0x6
ffffffffc0201038:	01440413          	addi	s0,s0,20 # ffffffffc0207048 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020103c:	00001517          	auipc	a0,0x1
ffffffffc0201040:	44c50513          	addi	a0,a0,1100 # ffffffffc0202488 <etext+0x586>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201044:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201046:	904ff0ef          	jal	ffffffffc020014a <cprintf>
    pmm_manager->init();
ffffffffc020104a:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020104c:	00006497          	auipc	s1,0x6
ffffffffc0201050:	01448493          	addi	s1,s1,20 # ffffffffc0207060 <va_pa_offset>
    pmm_manager->init();
ffffffffc0201054:	679c                	ld	a5,8(a5)
ffffffffc0201056:	9782                	jalr	a5
    uint64_t mem_base = get_memory_base();
ffffffffc0201058:	d46ff0ef          	jal	ffffffffc020059e <get_memory_base>
ffffffffc020105c:	89aa                	mv	s3,a0
    uint64_t mem_size = get_memory_size();
ffffffffc020105e:	d4aff0ef          	jal	ffffffffc02005a8 <get_memory_size>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201062:	57f5                	li	a5,-3
ffffffffc0201064:	07fa                	slli	a5,a5,0x1e
ffffffffc0201066:	e09c                	sd	a5,0(s1)
    if (mem_base == 0 || mem_size == 0 ||
ffffffffc0201068:	1a098163          	beqz	s3,ffffffffc020120a <pmm_init+0x1ee>
ffffffffc020106c:	8a2a                	mv	s4,a0
ffffffffc020106e:	18050e63          	beqz	a0,ffffffffc020120a <pmm_init+0x1ee>
ffffffffc0201072:	00a98933          	add	s2,s3,a0
ffffffffc0201076:	19396a63          	bltu	s2,s3,ffffffffc020120a <pmm_init+0x1ee>
    if (mem_base < DRAM_BASE || mem_base > KERNEL_BEGIN_PADDR ||
ffffffffc020107a:	800007b7          	lui	a5,0x80000
ffffffffc020107e:	97ce                	add	a5,a5,s3
ffffffffc0201080:	00200737          	lui	a4,0x200
ffffffffc0201084:	16f76763          	bltu	a4,a5,ffffffffc02011f2 <pmm_init+0x1d6>
ffffffffc0201088:	40100793          	li	a5,1025
ffffffffc020108c:	07d6                	slli	a5,a5,0x15
ffffffffc020108e:	1727f263          	bgeu	a5,s2,ffffffffc02011f2 <pmm_init+0x1d6>
    cprintf("physical memory map:\n");
ffffffffc0201092:	00001517          	auipc	a0,0x1
ffffffffc0201096:	48650513          	addi	a0,a0,1158 # ffffffffc0202518 <etext+0x616>
ffffffffc020109a:	8b0ff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n",
ffffffffc020109e:	864e                	mv	a2,s3
ffffffffc02010a0:	85d2                	mv	a1,s4
ffffffffc02010a2:	fff90693          	addi	a3,s2,-1
ffffffffc02010a6:	00001517          	auipc	a0,0x1
ffffffffc02010aa:	48a50513          	addi	a0,a0,1162 # ffffffffc0202530 <etext+0x62e>
ffffffffc02010ae:	89cff0ef          	jal	ffffffffc020014a <cprintf>
    uintptr_t maxpa = ROUNDDOWN(
ffffffffc02010b2:	47c5                	li	a5,17
ffffffffc02010b4:	07ee                	slli	a5,a5,0x1b
ffffffffc02010b6:	1327ec63          	bltu	a5,s2,ffffffffc02011ee <pmm_init+0x1d2>
ffffffffc02010ba:	77fd                	lui	a5,0xfffff
ffffffffc02010bc:	00f975b3          	and	a1,s2,a5
    pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);
ffffffffc02010c0:	00007697          	auipc	a3,0x7
ffffffffc02010c4:	fb768693          	addi	a3,a3,-73 # ffffffffc0208077 <end+0xfff>
ffffffffc02010c8:	8efd                	and	a3,a3,a5
    npage = PPN(maxpa); // physical page-number upper bound, not the RAM page count
ffffffffc02010ca:	00c5d893          	srli	a7,a1,0xc
    pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);
ffffffffc02010ce:	00006797          	auipc	a5,0x6
ffffffffc02010d2:	fad7b123          	sd	a3,-94(a5) # ffffffffc0207070 <pages>
    npage = PPN(maxpa); // physical page-number upper bound, not the RAM page count
ffffffffc02010d6:	00006797          	auipc	a5,0x6
ffffffffc02010da:	f917b923          	sd	a7,-110(a5) # ffffffffc0207068 <npage>
    uintptr_t pages_pa = PADDR(pages);
ffffffffc02010de:	c02007b7          	lui	a5,0xc0200
    pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);
ffffffffc02010e2:	8836                	mv	a6,a3
    uintptr_t pages_pa = PADDR(pages);
ffffffffc02010e4:	14f6eb63          	bltu	a3,a5,ffffffffc020123a <pmm_init+0x21e>
ffffffffc02010e8:	0004b303          	ld	t1,0(s1)
    if (pages_pa < KERNEL_BEGIN_PADDR || pages_pa >= maxpa ||
ffffffffc02010ec:	40100793          	li	a5,1025
    size_t page_count = npage - nbase;
ffffffffc02010f0:	fff80537          	lui	a0,0xfff80
    if (pages_pa < KERNEL_BEGIN_PADDR || pages_pa >= maxpa ||
ffffffffc02010f4:	07d6                	slli	a5,a5,0x15
    uintptr_t pages_pa = PADDR(pages);
ffffffffc02010f6:	40668733          	sub	a4,a3,t1
    size_t page_count = npage - nbase;
ffffffffc02010fa:	9546                	add	a0,a0,a7
    if (pages_pa < KERNEL_BEGIN_PADDR || pages_pa >= maxpa ||
ffffffffc02010fc:	12f76363          	bltu	a4,a5,ffffffffc0201222 <pmm_init+0x206>
ffffffffc0201100:	12b77163          	bgeu	a4,a1,ffffffffc0201222 <pmm_init+0x206>
        page_count > (maxpa - pages_pa) / sizeof(struct Page)) {
ffffffffc0201104:	ccccd737          	lui	a4,0xccccd
ffffffffc0201108:	ccd70713          	addi	a4,a4,-819 # ffffffffcccccccd <end+0xcac5c55>
ffffffffc020110c:	02071613          	slli	a2,a4,0x20
ffffffffc0201110:	40d307b3          	sub	a5,t1,a3
ffffffffc0201114:	9732                	add	a4,a4,a2
ffffffffc0201116:	97ae                	add	a5,a5,a1
ffffffffc0201118:	02e7b7b3          	mulhu	a5,a5,a4
ffffffffc020111c:	8395                	srli	a5,a5,0x5
    if (pages_pa < KERNEL_BEGIN_PADDR || pages_pa >= maxpa ||
ffffffffc020111e:	10a7e263          	bltu	a5,a0,ffffffffc0201222 <pmm_init+0x206>
ffffffffc0201122:	00289713          	slli	a4,a7,0x2
ffffffffc0201126:	9746                	add	a4,a4,a7
ffffffffc0201128:	fec007b7          	lui	a5,0xfec00
ffffffffc020112c:	070e                	slli	a4,a4,0x3
ffffffffc020112e:	97b6                	add	a5,a5,a3
ffffffffc0201130:	973e                	add	a4,a4,a5
        SetPageReserved(p);
ffffffffc0201132:	4605                	li	a2,1
        list_init(&p->page_link);
ffffffffc0201134:	01868793          	addi	a5,a3,24
        p->property = 0;
ffffffffc0201138:	0006a823          	sw	zero,16(a3)
ffffffffc020113c:	0006a023          	sw	zero,0(a3)
        SetPageReserved(p);
ffffffffc0201140:	e690                	sd	a2,8(a3)
    elm->prev = elm->next = elm;
ffffffffc0201142:	f29c                	sd	a5,32(a3)
ffffffffc0201144:	ee9c                	sd	a5,24(a3)
    for (size_t i = 0; i < page_count; i++) {
ffffffffc0201146:	02868693          	addi	a3,a3,40
ffffffffc020114a:	fee695e3          	bne	a3,a4,ffffffffc0201134 <pmm_init+0x118>
    uintptr_t freemem = ROUNDUP(PADDR(pages + page_count), PGSIZE);
ffffffffc020114e:	00251693          	slli	a3,a0,0x2
ffffffffc0201152:	96aa                	add	a3,a3,a0
ffffffffc0201154:	068e                	slli	a3,a3,0x3
ffffffffc0201156:	96c2                	add	a3,a3,a6
ffffffffc0201158:	c0200937          	lui	s2,0xc0200
ffffffffc020115c:	1526e063          	bltu	a3,s2,ffffffffc020129c <pmm_init+0x280>
ffffffffc0201160:	6785                	lui	a5,0x1
ffffffffc0201162:	17fd                	addi	a5,a5,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc0201164:	406787b3          	sub	a5,a5,t1
ffffffffc0201168:	97b6                	add	a5,a5,a3
ffffffffc020116a:	777d                	lui	a4,0xfffff
ffffffffc020116c:	8ff9                	and	a5,a5,a4
    if (freemem >= maxpa) {
ffffffffc020116e:	10b7fb63          	bgeu	a5,a1,ffffffffc0201284 <pmm_init+0x268>
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201172:	00c7d713          	srli	a4,a5,0xc
ffffffffc0201176:	0f177b63          	bgeu	a4,a7,ffffffffc020126c <pmm_init+0x250>
    pmm_manager->init_memmap(base, n);
ffffffffc020117a:	6014                	ld	a3,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc020117c:	fff80637          	lui	a2,0xfff80
ffffffffc0201180:	9732                	add	a4,a4,a2
ffffffffc0201182:	00271513          	slli	a0,a4,0x2
ffffffffc0201186:	953a                	add	a0,a0,a4
ffffffffc0201188:	6a98                	ld	a4,16(a3)
    init_memmap(pa2page(freemem), (maxpa - freemem) / PGSIZE);
ffffffffc020118a:	8d9d                	sub	a1,a1,a5
ffffffffc020118c:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc020118e:	81b1                	srli	a1,a1,0xc
ffffffffc0201190:	9542                	add	a0,a0,a6
ffffffffc0201192:	9702                	jalr	a4
    extern void test_best_fit_extra(void);
    test_best_fit_extra();
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201194:	601c                	ld	a5,0(s0)
ffffffffc0201196:	7b9c                	ld	a5,48(a5)
ffffffffc0201198:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc020119a:	00001517          	auipc	a0,0x1
ffffffffc020119e:	46e50513          	addi	a0,a0,1134 # ffffffffc0202608 <etext+0x706>
ffffffffc02011a2:	fa9fe0ef          	jal	ffffffffc020014a <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02011a6:	00005597          	auipc	a1,0x5
ffffffffc02011aa:	e5a58593          	addi	a1,a1,-422 # ffffffffc0206000 <boot_page_table_sv39>
ffffffffc02011ae:	00006797          	auipc	a5,0x6
ffffffffc02011b2:	eab7b523          	sd	a1,-342(a5) # ffffffffc0207058 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc02011b6:	0925ee63          	bltu	a1,s2,ffffffffc0201252 <pmm_init+0x236>
ffffffffc02011ba:	609c                	ld	a5,0(s1)
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02011bc:	00001517          	auipc	a0,0x1
ffffffffc02011c0:	46c50513          	addi	a0,a0,1132 # ffffffffc0202628 <etext+0x726>
    satp_physical = PADDR(satp_virtual);
ffffffffc02011c4:	40f586b3          	sub	a3,a1,a5
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02011c8:	8636                	mv	a2,a3
    satp_physical = PADDR(satp_virtual);
ffffffffc02011ca:	00006797          	auipc	a5,0x6
ffffffffc02011ce:	e8d7b323          	sd	a3,-378(a5) # ffffffffc0207050 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02011d2:	f79fe0ef          	jal	ffffffffc020014a <cprintf>
    test_page_init();
ffffffffc02011d6:	64e000ef          	jal	ffffffffc0201824 <test_page_init>
    test_best_fit();
ffffffffc02011da:	063000ef          	jal	ffffffffc0201a3c <test_best_fit>
}
ffffffffc02011de:	7402                	ld	s0,32(sp)
ffffffffc02011e0:	70a2                	ld	ra,40(sp)
ffffffffc02011e2:	64e2                	ld	s1,24(sp)
ffffffffc02011e4:	6942                	ld	s2,16(sp)
ffffffffc02011e6:	69a2                	ld	s3,8(sp)
ffffffffc02011e8:	6a02                	ld	s4,0(sp)
ffffffffc02011ea:	6145                	addi	sp,sp,48
    test_best_fit_extra();
ffffffffc02011ec:	a0e1                	j	ffffffffc02012b4 <test_best_fit_extra>
    uintptr_t maxpa = ROUNDDOWN(
ffffffffc02011ee:	893e                	mv	s2,a5
ffffffffc02011f0:	b5e9                	j	ffffffffc02010ba <pmm_init+0x9e>
        panic("page_init: physical memory does not cover the kernel");
ffffffffc02011f2:	00001617          	auipc	a2,0x1
ffffffffc02011f6:	2ee60613          	addi	a2,a2,750 # ffffffffc02024e0 <etext+0x5de>
ffffffffc02011fa:	04f00593          	li	a1,79
ffffffffc02011fe:	00001517          	auipc	a0,0x1
ffffffffc0201202:	2d250513          	addi	a0,a0,722 # ffffffffc02024d0 <etext+0x5ce>
ffffffffc0201206:	fc7fe0ef          	jal	ffffffffc02001cc <__panic>
        panic("page_init: invalid physical memory information");
ffffffffc020120a:	00001617          	auipc	a2,0x1
ffffffffc020120e:	29660613          	addi	a2,a2,662 # ffffffffc02024a0 <etext+0x59e>
ffffffffc0201212:	04a00593          	li	a1,74
ffffffffc0201216:	00001517          	auipc	a0,0x1
ffffffffc020121a:	2ba50513          	addi	a0,a0,698 # ffffffffc02024d0 <etext+0x5ce>
ffffffffc020121e:	faffe0ef          	jal	ffffffffc02001cc <__panic>
        panic("page_init: no room for page descriptors");
ffffffffc0201222:	00001617          	auipc	a2,0x1
ffffffffc0201226:	36660613          	addi	a2,a2,870 # ffffffffc0202588 <etext+0x686>
ffffffffc020122a:	05f00593          	li	a1,95
ffffffffc020122e:	00001517          	auipc	a0,0x1
ffffffffc0201232:	2a250513          	addi	a0,a0,674 # ffffffffc02024d0 <etext+0x5ce>
ffffffffc0201236:	f97fe0ef          	jal	ffffffffc02001cc <__panic>
    uintptr_t pages_pa = PADDR(pages);
ffffffffc020123a:	00001617          	auipc	a2,0x1
ffffffffc020123e:	32660613          	addi	a2,a2,806 # ffffffffc0202560 <etext+0x65e>
ffffffffc0201242:	05b00593          	li	a1,91
ffffffffc0201246:	00001517          	auipc	a0,0x1
ffffffffc020124a:	28a50513          	addi	a0,a0,650 # ffffffffc02024d0 <etext+0x5ce>
ffffffffc020124e:	f7ffe0ef          	jal	ffffffffc02001cc <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201252:	86ae                	mv	a3,a1
ffffffffc0201254:	00001617          	auipc	a2,0x1
ffffffffc0201258:	30c60613          	addi	a2,a2,780 # ffffffffc0202560 <etext+0x65e>
ffffffffc020125c:	08600593          	li	a1,134
ffffffffc0201260:	00001517          	auipc	a0,0x1
ffffffffc0201264:	27050513          	addi	a0,a0,624 # ffffffffc02024d0 <etext+0x5ce>
ffffffffc0201268:	f65fe0ef          	jal	ffffffffc02001cc <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020126c:	00001617          	auipc	a2,0x1
ffffffffc0201270:	36c60613          	addi	a2,a2,876 # ffffffffc02025d8 <etext+0x6d6>
ffffffffc0201274:	06a00593          	li	a1,106
ffffffffc0201278:	00001517          	auipc	a0,0x1
ffffffffc020127c:	38050513          	addi	a0,a0,896 # ffffffffc02025f8 <etext+0x6f6>
ffffffffc0201280:	f4dfe0ef          	jal	ffffffffc02001cc <__panic>
        panic("page_init: no complete free pages");
ffffffffc0201284:	00001617          	auipc	a2,0x1
ffffffffc0201288:	32c60613          	addi	a2,a2,812 # ffffffffc02025b0 <etext+0x6ae>
ffffffffc020128c:	06f00593          	li	a1,111
ffffffffc0201290:	00001517          	auipc	a0,0x1
ffffffffc0201294:	24050513          	addi	a0,a0,576 # ffffffffc02024d0 <etext+0x5ce>
ffffffffc0201298:	f35fe0ef          	jal	ffffffffc02001cc <__panic>
    uintptr_t freemem = ROUNDUP(PADDR(pages + page_count), PGSIZE);
ffffffffc020129c:	00001617          	auipc	a2,0x1
ffffffffc02012a0:	2c460613          	addi	a2,a2,708 # ffffffffc0202560 <etext+0x65e>
ffffffffc02012a4:	06d00593          	li	a1,109
ffffffffc02012a8:	00001517          	auipc	a0,0x1
ffffffffc02012ac:	22850513          	addi	a0,a0,552 # ffffffffc02024d0 <etext+0x5ce>
ffffffffc02012b0:	f1dfe0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc02012b4 <test_best_fit_extra>:
#include <pmm.h>
#include <best_fit_pmm.h>
#include <stdio.h>

void test_best_fit_extra(void) {
ffffffffc02012b4:	7139                	addi	sp,sp,-64
ffffffffc02012b6:	ec4e                	sd	s3,24(sp)
    assert(pmm_manager == &best_fit_pmm_manager);
ffffffffc02012b8:	00006997          	auipc	s3,0x6
ffffffffc02012bc:	d9098993          	addi	s3,s3,-624 # ffffffffc0207048 <pmm_manager>
ffffffffc02012c0:	0009b703          	ld	a4,0(s3)
void test_best_fit_extra(void) {
ffffffffc02012c4:	fc06                	sd	ra,56(sp)
ffffffffc02012c6:	f822                	sd	s0,48(sp)
ffffffffc02012c8:	f426                	sd	s1,40(sp)
ffffffffc02012ca:	f04a                	sd	s2,32(sp)
ffffffffc02012cc:	e852                	sd	s4,16(sp)
ffffffffc02012ce:	e456                	sd	s5,8(sp)
ffffffffc02012d0:	e05a                	sd	s6,0(sp)
    assert(pmm_manager == &best_fit_pmm_manager);
ffffffffc02012d2:	00002797          	auipc	a5,0x2
ffffffffc02012d6:	b9678793          	addi	a5,a5,-1130 # ffffffffc0202e68 <best_fit_pmm_manager>
ffffffffc02012da:	36f71f63          	bne	a4,a5,ffffffffc0201658 <test_best_fit_extra+0x3a4>
    size_t total = nr_free_pages();
ffffffffc02012de:	d33ff0ef          	jal	ffffffffc0201010 <nr_free_pages>
    assert(total > 32);
ffffffffc02012e2:	02000793          	li	a5,32
    size_t total = nr_free_pages();
ffffffffc02012e6:	84aa                	mv	s1,a0
    assert(total > 32);
ffffffffc02012e8:	32a7f963          	bgeu	a5,a0,ffffffffc020161a <test_best_fit_extra+0x366>
    struct Page *arena = alloc_pages(total);
ffffffffc02012ec:	d0dff0ef          	jal	ffffffffc0200ff8 <alloc_pages>
ffffffffc02012f0:	842a                	mv	s0,a0
    assert(arena != NULL && nr_free_pages() == 0);
ffffffffc02012f2:	1e050963          	beqz	a0,ffffffffc02014e4 <test_best_fit_extra+0x230>
ffffffffc02012f6:	d1bff0ef          	jal	ffffffffc0201010 <nr_free_pages>
ffffffffc02012fa:	1e051563          	bnez	a0,ffffffffc02014e4 <test_best_fit_extra+0x230>

    // Four separated holes; insert them in a non-address order.
    free_pages(arena + 15, 5);
ffffffffc02012fe:	25840a13          	addi	s4,s0,600
ffffffffc0201302:	8552                	mv	a0,s4
ffffffffc0201304:	4595                	li	a1,5
ffffffffc0201306:	cffff0ef          	jal	ffffffffc0201004 <free_pages>
    free_pages(arena, 8);
ffffffffc020130a:	8522                	mv	a0,s0
ffffffffc020130c:	45a1                	li	a1,8
ffffffffc020130e:	cf7ff0ef          	jal	ffffffffc0201004 <free_pages>
    free_pages(arena + 22, 3);
ffffffffc0201312:	37040a93          	addi	s5,s0,880
ffffffffc0201316:	8556                	mv	a0,s5
ffffffffc0201318:	458d                	li	a1,3
ffffffffc020131a:	cebff0ef          	jal	ffffffffc0201004 <free_pages>
    free_pages(arena + 10, 3);
ffffffffc020131e:	19040b13          	addi	s6,s0,400
ffffffffc0201322:	855a                	mv	a0,s6
ffffffffc0201324:	458d                	li	a1,3
ffffffffc0201326:	cdfff0ef          	jal	ffffffffc0201004 <free_pages>
    assert(nr_free_pages() == 19);
ffffffffc020132a:	ce7ff0ef          	jal	ffffffffc0201010 <nr_free_pages>
ffffffffc020132e:	47cd                	li	a5,19
ffffffffc0201330:	892a                	mv	s2,a0
ffffffffc0201332:	3af51f63          	bne	a0,a5,ffffffffc02016f0 <test_best_fit_extra+0x43c>
    // Smallest fitting size wins; equal sizes choose the lower address.
    assert(alloc_pages(2) == arena + 10);
ffffffffc0201336:	4509                	li	a0,2
ffffffffc0201338:	cc1ff0ef          	jal	ffffffffc0200ff8 <alloc_pages>
ffffffffc020133c:	38ab1b63          	bne	s6,a0,ffffffffc02016d2 <test_best_fit_extra+0x41e>
    assert(alloc_page() == arena + 12);
ffffffffc0201340:	4505                	li	a0,1
ffffffffc0201342:	cb7ff0ef          	jal	ffffffffc0200ff8 <alloc_pages>
ffffffffc0201346:	1e040793          	addi	a5,s0,480
ffffffffc020134a:	36a79563          	bne	a5,a0,ffffffffc02016b4 <test_best_fit_extra+0x400>
    assert(alloc_pages(3) == arena + 22);
ffffffffc020134e:	450d                	li	a0,3
ffffffffc0201350:	ca9ff0ef          	jal	ffffffffc0200ff8 <alloc_pages>
ffffffffc0201354:	34aa9163          	bne	s5,a0,ffffffffc0201696 <test_best_fit_extra+0x3e2>
    assert(alloc_pages(4) == arena + 15);
ffffffffc0201358:	4511                	li	a0,4
ffffffffc020135a:	c9fff0ef          	jal	ffffffffc0200ff8 <alloc_pages>
ffffffffc020135e:	26aa1063          	bne	s4,a0,ffffffffc02015be <test_best_fit_extra+0x30a>
    assert(alloc_pages(6) == arena);
ffffffffc0201362:	4519                	li	a0,6
ffffffffc0201364:	c95ff0ef          	jal	ffffffffc0200ff8 <alloc_pages>
ffffffffc0201368:	26a41a63          	bne	s0,a0,ffffffffc02015dc <test_best_fit_extra+0x328>
    assert(nr_free_pages() == 3);
ffffffffc020136c:	ca5ff0ef          	jal	ffffffffc0201010 <nr_free_pages>
ffffffffc0201370:	478d                	li	a5,3
ffffffffc0201372:	892a                	mv	s2,a0
ffffffffc0201374:	46f51b63          	bne	a0,a5,ffffffffc02017ea <test_best_fit_extra+0x536>
    // The remaining holes have sizes 2 and 1, so a 3-page request must fail.
    assert(alloc_pages(3) == NULL && nr_free_pages() == 3);
ffffffffc0201378:	c81ff0ef          	jal	ffffffffc0200ff8 <alloc_pages>
ffffffffc020137c:	22051263          	bnez	a0,ffffffffc02015a0 <test_best_fit_extra+0x2ec>
ffffffffc0201380:	c91ff0ef          	jal	ffffffffc0201010 <nr_free_pages>
ffffffffc0201384:	21251e63          	bne	a0,s2,ffffffffc02015a0 <test_best_fit_extra+0x2ec>
    assert(alloc_page() == arena + 19);
ffffffffc0201388:	4505                	li	a0,1
ffffffffc020138a:	c6fff0ef          	jal	ffffffffc0200ff8 <alloc_pages>
ffffffffc020138e:	2f840793          	addi	a5,s0,760
ffffffffc0201392:	3ca79d63          	bne	a5,a0,ffffffffc020176c <test_best_fit_extra+0x4b8>
    assert(alloc_pages(2) == arena + 6);
ffffffffc0201396:	4509                	li	a0,2
ffffffffc0201398:	c61ff0ef          	jal	ffffffffc0200ff8 <alloc_pages>
ffffffffc020139c:	0f040793          	addi	a5,s0,240
ffffffffc02013a0:	892a                	mv	s2,a0
ffffffffc02013a2:	3af51663          	bne	a0,a5,ffffffffc020174e <test_best_fit_extra+0x49a>
    assert(nr_free_pages() == 0 && alloc_page() == NULL);
ffffffffc02013a6:	c6bff0ef          	jal	ffffffffc0201010 <nr_free_pages>
ffffffffc02013aa:	1c051c63          	bnez	a0,ffffffffc0201582 <test_best_fit_extra+0x2ce>
ffffffffc02013ae:	4505                	li	a0,1
ffffffffc02013b0:	c49ff0ef          	jal	ffffffffc0200ff8 <alloc_pages>
ffffffffc02013b4:	1c051763          	bnez	a0,ffffffffc0201582 <test_best_fit_extra+0x2ce>
    cprintf("[Extra] Best-Fit selection/split/fragmentation: PASS\n");
ffffffffc02013b8:	00001517          	auipc	a0,0x1
ffffffffc02013bc:	49850513          	addi	a0,a0,1176 # ffffffffc0202850 <etext+0x94e>
ffffffffc02013c0:	d8bfe0ef          	jal	ffffffffc020014a <cprintf>

    // A newly freed middle block must join both neighbouring blocks.
    free_pages(arena + 2, 2);
ffffffffc02013c4:	05040a13          	addi	s4,s0,80
ffffffffc02013c8:	8552                	mv	a0,s4
ffffffffc02013ca:	4589                	li	a1,2
ffffffffc02013cc:	c39ff0ef          	jal	ffffffffc0201004 <free_pages>
    free_pages(arena + 6, 2);
ffffffffc02013d0:	854a                	mv	a0,s2
ffffffffc02013d2:	4589                	li	a1,2
ffffffffc02013d4:	c31ff0ef          	jal	ffffffffc0201004 <free_pages>
    free_pages(arena + 4, 2);
ffffffffc02013d8:	0a040913          	addi	s2,s0,160
ffffffffc02013dc:	854a                	mv	a0,s2
ffffffffc02013de:	4589                	li	a1,2
ffffffffc02013e0:	c25ff0ef          	jal	ffffffffc0201004 <free_pages>
    assert(nr_free_pages() == 6);
ffffffffc02013e4:	c2dff0ef          	jal	ffffffffc0201010 <nr_free_pages>
ffffffffc02013e8:	4799                	li	a5,6
ffffffffc02013ea:	34f51263          	bne	a0,a5,ffffffffc020172e <test_best_fit_extra+0x47a>
    assert(PageProperty(arena + 2) && arena[2].property == 6);
ffffffffc02013ee:	6c3c                	ld	a5,88(s0)
ffffffffc02013f0:	8b89                	andi	a5,a5,2
ffffffffc02013f2:	16078863          	beqz	a5,ffffffffc0201562 <test_best_fit_extra+0x2ae>
ffffffffc02013f6:	503c                	lw	a5,96(s0)
ffffffffc02013f8:	16a79563          	bne	a5,a0,ffffffffc0201562 <test_best_fit_extra+0x2ae>
    assert(!PageProperty(arena + 4) && !PageProperty(arena + 6));
ffffffffc02013fc:	745c                	ld	a5,168(s0)
ffffffffc02013fe:	8b89                	andi	a5,a5,2
ffffffffc0201400:	14079163          	bnez	a5,ffffffffc0201542 <test_best_fit_extra+0x28e>
ffffffffc0201404:	7c7c                	ld	a5,248(s0)
ffffffffc0201406:	8b89                	andi	a5,a5,2
ffffffffc0201408:	12079d63          	bnez	a5,ffffffffc0201542 <test_best_fit_extra+0x28e>
    assert(alloc_pages(6) == arena + 2);
ffffffffc020140c:	4519                	li	a0,6
ffffffffc020140e:	bebff0ef          	jal	ffffffffc0200ff8 <alloc_pages>
ffffffffc0201412:	1eaa1463          	bne	s4,a0,ffffffffc02015fa <test_best_fit_extra+0x346>
    assert(nr_free_pages() == 0);
ffffffffc0201416:	bfbff0ef          	jal	ffffffffc0201010 <nr_free_pages>
ffffffffc020141a:	3a051863          	bnez	a0,ffffffffc02017ca <test_best_fit_extra+0x516>
    cprintf("[Extra] Best-Fit two-sided coalescing: PASS\n");
ffffffffc020141e:	00001517          	auipc	a0,0x1
ffffffffc0201422:	52a50513          	addi	a0,a0,1322 # ffffffffc0202948 <etext+0xa46>
ffffffffc0201426:	d25fe0ef          	jal	ffffffffc020014a <cprintf>

    // Register several new, reserved regions out of order, then bridge the gap.
    // Only descriptors are touched; the underlying physical pages are not used.
    for (size_t i = 0; i < 12; i++) {
ffffffffc020142a:	00840793          	addi	a5,s0,8
ffffffffc020142e:	1e840693          	addi	a3,s0,488
        SetPageReserved(arena + i);
ffffffffc0201432:	6398                	ld	a4,0(a5)
    for (size_t i = 0; i < 12; i++) {
ffffffffc0201434:	02878793          	addi	a5,a5,40
        SetPageReserved(arena + i);
ffffffffc0201438:	00176713          	ori	a4,a4,1
ffffffffc020143c:	fce7bc23          	sd	a4,-40(a5)
    for (size_t i = 0; i < 12; i++) {
ffffffffc0201440:	fed799e3          	bne	a5,a3,ffffffffc0201432 <test_best_fit_extra+0x17e>
    }
    pmm_manager->init_memmap(arena + 8, 4);
ffffffffc0201444:	0009b783          	ld	a5,0(s3)
ffffffffc0201448:	4591                	li	a1,4
ffffffffc020144a:	14040513          	addi	a0,s0,320
ffffffffc020144e:	6b9c                	ld	a5,16(a5)
ffffffffc0201450:	9782                	jalr	a5
    pmm_manager->init_memmap(arena, 4);
ffffffffc0201452:	0009b783          	ld	a5,0(s3)
ffffffffc0201456:	8522                	mv	a0,s0
ffffffffc0201458:	4591                	li	a1,4
ffffffffc020145a:	6b9c                	ld	a5,16(a5)
ffffffffc020145c:	9782                	jalr	a5
    pmm_manager->init_memmap(arena + 4, 4);
ffffffffc020145e:	0009b783          	ld	a5,0(s3)
ffffffffc0201462:	854a                	mv	a0,s2
ffffffffc0201464:	4591                	li	a1,4
ffffffffc0201466:	6b9c                	ld	a5,16(a5)
ffffffffc0201468:	9782                	jalr	a5
    assert(nr_free_pages() == 12);
ffffffffc020146a:	ba7ff0ef          	jal	ffffffffc0201010 <nr_free_pages>
ffffffffc020146e:	4731                	li	a4,12
ffffffffc0201470:	28e51f63          	bne	a0,a4,ffffffffc020170e <test_best_fit_extra+0x45a>
    assert(PageProperty(arena) && arena->property == 12);
ffffffffc0201474:	6418                	ld	a4,8(s0)
ffffffffc0201476:	8b09                	andi	a4,a4,2
ffffffffc0201478:	c74d                	beqz	a4,ffffffffc0201522 <test_best_fit_extra+0x26e>
ffffffffc020147a:	4818                	lw	a4,16(s0)
ffffffffc020147c:	0aa71363          	bne	a4,a0,ffffffffc0201522 <test_best_fit_extra+0x26e>
    assert(alloc_pages(12) == arena);
ffffffffc0201480:	b79ff0ef          	jal	ffffffffc0200ff8 <alloc_pages>
ffffffffc0201484:	32a41363          	bne	s0,a0,ffffffffc02017aa <test_best_fit_extra+0x4f6>
    assert(nr_free_pages() == 0);
ffffffffc0201488:	b89ff0ef          	jal	ffffffffc0201010 <nr_free_pages>
ffffffffc020148c:	2e051f63          	bnez	a0,ffffffffc020178a <test_best_fit_extra+0x4d6>
    cprintf("[Extra] Best-Fit multi-region registration: PASS\n");
ffffffffc0201490:	00001517          	auipc	a0,0x1
ffffffffc0201494:	55050513          	addi	a0,a0,1360 # ffffffffc02029e0 <etext+0xade>
ffffffffc0201498:	cb3fe0ef          	jal	ffffffffc020014a <cprintf>

    free_pages(arena, total);
ffffffffc020149c:	85a6                	mv	a1,s1
ffffffffc020149e:	8522                	mv	a0,s0
ffffffffc02014a0:	b65ff0ef          	jal	ffffffffc0201004 <free_pages>
    assert(nr_free_pages() == total);
ffffffffc02014a4:	b6dff0ef          	jal	ffffffffc0201010 <nr_free_pages>
ffffffffc02014a8:	18951863          	bne	a0,s1,ffffffffc0201638 <test_best_fit_extra+0x384>
    assert(PageProperty(arena) && arena->property == total);
ffffffffc02014ac:	641c                	ld	a5,8(s0)
ffffffffc02014ae:	8b89                	andi	a5,a5,2
ffffffffc02014b0:	cba9                	beqz	a5,ffffffffc0201502 <test_best_fit_extra+0x24e>
ffffffffc02014b2:	01046783          	lwu	a5,16(s0)
ffffffffc02014b6:	04979663          	bne	a5,s1,ffffffffc0201502 <test_best_fit_extra+0x24e>
    assert(alloc_pages(total + 1) == NULL);
ffffffffc02014ba:	00148513          	addi	a0,s1,1
ffffffffc02014be:	b3bff0ef          	jal	ffffffffc0200ff8 <alloc_pages>
ffffffffc02014c2:	1a051a63          	bnez	a0,ffffffffc0201676 <test_best_fit_extra+0x3c2>
    cprintf("[Extra] Best-Fit accounting/restoration: PASS\n");
}
ffffffffc02014c6:	7442                	ld	s0,48(sp)
ffffffffc02014c8:	70e2                	ld	ra,56(sp)
ffffffffc02014ca:	74a2                	ld	s1,40(sp)
ffffffffc02014cc:	7902                	ld	s2,32(sp)
ffffffffc02014ce:	69e2                	ld	s3,24(sp)
ffffffffc02014d0:	6a42                	ld	s4,16(sp)
ffffffffc02014d2:	6aa2                	ld	s5,8(sp)
ffffffffc02014d4:	6b02                	ld	s6,0(sp)
    cprintf("[Extra] Best-Fit accounting/restoration: PASS\n");
ffffffffc02014d6:	00001517          	auipc	a0,0x1
ffffffffc02014da:	5b250513          	addi	a0,a0,1458 # ffffffffc0202a88 <etext+0xb86>
}
ffffffffc02014de:	6121                	addi	sp,sp,64
    cprintf("[Extra] Best-Fit accounting/restoration: PASS\n");
ffffffffc02014e0:	c6bfe06f          	j	ffffffffc020014a <cprintf>
    assert(arena != NULL && nr_free_pages() == 0);
ffffffffc02014e4:	00001697          	auipc	a3,0x1
ffffffffc02014e8:	1dc68693          	addi	a3,a3,476 # ffffffffc02026c0 <etext+0x7be>
ffffffffc02014ec:	00001617          	auipc	a2,0x1
ffffffffc02014f0:	c6c60613          	addi	a2,a2,-916 # ffffffffc0202158 <etext+0x256>
ffffffffc02014f4:	45a9                	li	a1,10
ffffffffc02014f6:	00001517          	auipc	a0,0x1
ffffffffc02014fa:	19a50513          	addi	a0,a0,410 # ffffffffc0202690 <etext+0x78e>
ffffffffc02014fe:	ccffe0ef          	jal	ffffffffc02001cc <__panic>
    assert(PageProperty(arena) && arena->property == total);
ffffffffc0201502:	00001697          	auipc	a3,0x1
ffffffffc0201506:	53668693          	addi	a3,a3,1334 # ffffffffc0202a38 <etext+0xb36>
ffffffffc020150a:	00001617          	auipc	a2,0x1
ffffffffc020150e:	c4e60613          	addi	a2,a2,-946 # ffffffffc0202158 <etext+0x256>
ffffffffc0201512:	03b00593          	li	a1,59
ffffffffc0201516:	00001517          	auipc	a0,0x1
ffffffffc020151a:	17a50513          	addi	a0,a0,378 # ffffffffc0202690 <etext+0x78e>
ffffffffc020151e:	caffe0ef          	jal	ffffffffc02001cc <__panic>
    assert(PageProperty(arena) && arena->property == 12);
ffffffffc0201522:	00001697          	auipc	a3,0x1
ffffffffc0201526:	46e68693          	addi	a3,a3,1134 # ffffffffc0202990 <etext+0xa8e>
ffffffffc020152a:	00001617          	auipc	a2,0x1
ffffffffc020152e:	c2e60613          	addi	a2,a2,-978 # ffffffffc0202158 <etext+0x256>
ffffffffc0201532:	03400593          	li	a1,52
ffffffffc0201536:	00001517          	auipc	a0,0x1
ffffffffc020153a:	15a50513          	addi	a0,a0,346 # ffffffffc0202690 <etext+0x78e>
ffffffffc020153e:	c8ffe0ef          	jal	ffffffffc02001cc <__panic>
    assert(!PageProperty(arena + 4) && !PageProperty(arena + 6));
ffffffffc0201542:	00001697          	auipc	a3,0x1
ffffffffc0201546:	39668693          	addi	a3,a3,918 # ffffffffc02028d8 <etext+0x9d6>
ffffffffc020154a:	00001617          	auipc	a2,0x1
ffffffffc020154e:	c0e60613          	addi	a2,a2,-1010 # ffffffffc0202158 <etext+0x256>
ffffffffc0201552:	02600593          	li	a1,38
ffffffffc0201556:	00001517          	auipc	a0,0x1
ffffffffc020155a:	13a50513          	addi	a0,a0,314 # ffffffffc0202690 <etext+0x78e>
ffffffffc020155e:	c6ffe0ef          	jal	ffffffffc02001cc <__panic>
    assert(PageProperty(arena + 2) && arena[2].property == 6);
ffffffffc0201562:	00001697          	auipc	a3,0x1
ffffffffc0201566:	33e68693          	addi	a3,a3,830 # ffffffffc02028a0 <etext+0x99e>
ffffffffc020156a:	00001617          	auipc	a2,0x1
ffffffffc020156e:	bee60613          	addi	a2,a2,-1042 # ffffffffc0202158 <etext+0x256>
ffffffffc0201572:	02500593          	li	a1,37
ffffffffc0201576:	00001517          	auipc	a0,0x1
ffffffffc020157a:	11a50513          	addi	a0,a0,282 # ffffffffc0202690 <etext+0x78e>
ffffffffc020157e:	c4ffe0ef          	jal	ffffffffc02001cc <__panic>
    assert(nr_free_pages() == 0 && alloc_page() == NULL);
ffffffffc0201582:	00001697          	auipc	a3,0x1
ffffffffc0201586:	29e68693          	addi	a3,a3,670 # ffffffffc0202820 <etext+0x91e>
ffffffffc020158a:	00001617          	auipc	a2,0x1
ffffffffc020158e:	bce60613          	addi	a2,a2,-1074 # ffffffffc0202158 <etext+0x256>
ffffffffc0201592:	45f5                	li	a1,29
ffffffffc0201594:	00001517          	auipc	a0,0x1
ffffffffc0201598:	0fc50513          	addi	a0,a0,252 # ffffffffc0202690 <etext+0x78e>
ffffffffc020159c:	c31fe0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_pages(3) == NULL && nr_free_pages() == 3);
ffffffffc02015a0:	00001697          	auipc	a3,0x1
ffffffffc02015a4:	21068693          	addi	a3,a3,528 # ffffffffc02027b0 <etext+0x8ae>
ffffffffc02015a8:	00001617          	auipc	a2,0x1
ffffffffc02015ac:	bb060613          	addi	a2,a2,-1104 # ffffffffc0202158 <etext+0x256>
ffffffffc02015b0:	45e9                	li	a1,26
ffffffffc02015b2:	00001517          	auipc	a0,0x1
ffffffffc02015b6:	0de50513          	addi	a0,a0,222 # ffffffffc0202690 <etext+0x78e>
ffffffffc02015ba:	c13fe0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_pages(4) == arena + 15);
ffffffffc02015be:	00001697          	auipc	a3,0x1
ffffffffc02015c2:	1a268693          	addi	a3,a3,418 # ffffffffc0202760 <etext+0x85e>
ffffffffc02015c6:	00001617          	auipc	a2,0x1
ffffffffc02015ca:	b9260613          	addi	a2,a2,-1134 # ffffffffc0202158 <etext+0x256>
ffffffffc02015ce:	45d9                	li	a1,22
ffffffffc02015d0:	00001517          	auipc	a0,0x1
ffffffffc02015d4:	0c050513          	addi	a0,a0,192 # ffffffffc0202690 <etext+0x78e>
ffffffffc02015d8:	bf5fe0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_pages(6) == arena);
ffffffffc02015dc:	00001697          	auipc	a3,0x1
ffffffffc02015e0:	1a468693          	addi	a3,a3,420 # ffffffffc0202780 <etext+0x87e>
ffffffffc02015e4:	00001617          	auipc	a2,0x1
ffffffffc02015e8:	b7460613          	addi	a2,a2,-1164 # ffffffffc0202158 <etext+0x256>
ffffffffc02015ec:	45dd                	li	a1,23
ffffffffc02015ee:	00001517          	auipc	a0,0x1
ffffffffc02015f2:	0a250513          	addi	a0,a0,162 # ffffffffc0202690 <etext+0x78e>
ffffffffc02015f6:	bd7fe0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_pages(6) == arena + 2);
ffffffffc02015fa:	00001697          	auipc	a3,0x1
ffffffffc02015fe:	31668693          	addi	a3,a3,790 # ffffffffc0202910 <etext+0xa0e>
ffffffffc0201602:	00001617          	auipc	a2,0x1
ffffffffc0201606:	b5660613          	addi	a2,a2,-1194 # ffffffffc0202158 <etext+0x256>
ffffffffc020160a:	02700593          	li	a1,39
ffffffffc020160e:	00001517          	auipc	a0,0x1
ffffffffc0201612:	08250513          	addi	a0,a0,130 # ffffffffc0202690 <etext+0x78e>
ffffffffc0201616:	bb7fe0ef          	jal	ffffffffc02001cc <__panic>
    assert(total > 32);
ffffffffc020161a:	00001697          	auipc	a3,0x1
ffffffffc020161e:	09668693          	addi	a3,a3,150 # ffffffffc02026b0 <etext+0x7ae>
ffffffffc0201622:	00001617          	auipc	a2,0x1
ffffffffc0201626:	b3660613          	addi	a2,a2,-1226 # ffffffffc0202158 <etext+0x256>
ffffffffc020162a:	45a1                	li	a1,8
ffffffffc020162c:	00001517          	auipc	a0,0x1
ffffffffc0201630:	06450513          	addi	a0,a0,100 # ffffffffc0202690 <etext+0x78e>
ffffffffc0201634:	b99fe0ef          	jal	ffffffffc02001cc <__panic>
    assert(nr_free_pages() == total);
ffffffffc0201638:	00001697          	auipc	a3,0x1
ffffffffc020163c:	3e068693          	addi	a3,a3,992 # ffffffffc0202a18 <etext+0xb16>
ffffffffc0201640:	00001617          	auipc	a2,0x1
ffffffffc0201644:	b1860613          	addi	a2,a2,-1256 # ffffffffc0202158 <etext+0x256>
ffffffffc0201648:	03a00593          	li	a1,58
ffffffffc020164c:	00001517          	auipc	a0,0x1
ffffffffc0201650:	04450513          	addi	a0,a0,68 # ffffffffc0202690 <etext+0x78e>
ffffffffc0201654:	b79fe0ef          	jal	ffffffffc02001cc <__panic>
    assert(pmm_manager == &best_fit_pmm_manager);
ffffffffc0201658:	00001697          	auipc	a3,0x1
ffffffffc020165c:	01068693          	addi	a3,a3,16 # ffffffffc0202668 <etext+0x766>
ffffffffc0201660:	00001617          	auipc	a2,0x1
ffffffffc0201664:	af860613          	addi	a2,a2,-1288 # ffffffffc0202158 <etext+0x256>
ffffffffc0201668:	4599                	li	a1,6
ffffffffc020166a:	00001517          	auipc	a0,0x1
ffffffffc020166e:	02650513          	addi	a0,a0,38 # ffffffffc0202690 <etext+0x78e>
ffffffffc0201672:	b5bfe0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_pages(total + 1) == NULL);
ffffffffc0201676:	00001697          	auipc	a3,0x1
ffffffffc020167a:	3f268693          	addi	a3,a3,1010 # ffffffffc0202a68 <etext+0xb66>
ffffffffc020167e:	00001617          	auipc	a2,0x1
ffffffffc0201682:	ada60613          	addi	a2,a2,-1318 # ffffffffc0202158 <etext+0x256>
ffffffffc0201686:	03c00593          	li	a1,60
ffffffffc020168a:	00001517          	auipc	a0,0x1
ffffffffc020168e:	00650513          	addi	a0,a0,6 # ffffffffc0202690 <etext+0x78e>
ffffffffc0201692:	b3bfe0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_pages(3) == arena + 22);
ffffffffc0201696:	00001697          	auipc	a3,0x1
ffffffffc020169a:	0aa68693          	addi	a3,a3,170 # ffffffffc0202740 <etext+0x83e>
ffffffffc020169e:	00001617          	auipc	a2,0x1
ffffffffc02016a2:	aba60613          	addi	a2,a2,-1350 # ffffffffc0202158 <etext+0x256>
ffffffffc02016a6:	45d5                	li	a1,21
ffffffffc02016a8:	00001517          	auipc	a0,0x1
ffffffffc02016ac:	fe850513          	addi	a0,a0,-24 # ffffffffc0202690 <etext+0x78e>
ffffffffc02016b0:	b1dfe0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_page() == arena + 12);
ffffffffc02016b4:	00001697          	auipc	a3,0x1
ffffffffc02016b8:	06c68693          	addi	a3,a3,108 # ffffffffc0202720 <etext+0x81e>
ffffffffc02016bc:	00001617          	auipc	a2,0x1
ffffffffc02016c0:	a9c60613          	addi	a2,a2,-1380 # ffffffffc0202158 <etext+0x256>
ffffffffc02016c4:	45d1                	li	a1,20
ffffffffc02016c6:	00001517          	auipc	a0,0x1
ffffffffc02016ca:	fca50513          	addi	a0,a0,-54 # ffffffffc0202690 <etext+0x78e>
ffffffffc02016ce:	afffe0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_pages(2) == arena + 10);
ffffffffc02016d2:	85ca                	mv	a1,s2
ffffffffc02016d4:	00001697          	auipc	a3,0x1
ffffffffc02016d8:	02c68693          	addi	a3,a3,44 # ffffffffc0202700 <etext+0x7fe>
ffffffffc02016dc:	00001617          	auipc	a2,0x1
ffffffffc02016e0:	a7c60613          	addi	a2,a2,-1412 # ffffffffc0202158 <etext+0x256>
ffffffffc02016e4:	00001517          	auipc	a0,0x1
ffffffffc02016e8:	fac50513          	addi	a0,a0,-84 # ffffffffc0202690 <etext+0x78e>
ffffffffc02016ec:	ae1fe0ef          	jal	ffffffffc02001cc <__panic>
    assert(nr_free_pages() == 19);
ffffffffc02016f0:	00001697          	auipc	a3,0x1
ffffffffc02016f4:	ff868693          	addi	a3,a3,-8 # ffffffffc02026e8 <etext+0x7e6>
ffffffffc02016f8:	00001617          	auipc	a2,0x1
ffffffffc02016fc:	a6060613          	addi	a2,a2,-1440 # ffffffffc0202158 <etext+0x256>
ffffffffc0201700:	45c5                	li	a1,17
ffffffffc0201702:	00001517          	auipc	a0,0x1
ffffffffc0201706:	f8e50513          	addi	a0,a0,-114 # ffffffffc0202690 <etext+0x78e>
ffffffffc020170a:	ac3fe0ef          	jal	ffffffffc02001cc <__panic>
    assert(nr_free_pages() == 12);
ffffffffc020170e:	00001697          	auipc	a3,0x1
ffffffffc0201712:	26a68693          	addi	a3,a3,618 # ffffffffc0202978 <etext+0xa76>
ffffffffc0201716:	00001617          	auipc	a2,0x1
ffffffffc020171a:	a4260613          	addi	a2,a2,-1470 # ffffffffc0202158 <etext+0x256>
ffffffffc020171e:	03300593          	li	a1,51
ffffffffc0201722:	00001517          	auipc	a0,0x1
ffffffffc0201726:	f6e50513          	addi	a0,a0,-146 # ffffffffc0202690 <etext+0x78e>
ffffffffc020172a:	aa3fe0ef          	jal	ffffffffc02001cc <__panic>
    assert(nr_free_pages() == 6);
ffffffffc020172e:	00001697          	auipc	a3,0x1
ffffffffc0201732:	15a68693          	addi	a3,a3,346 # ffffffffc0202888 <etext+0x986>
ffffffffc0201736:	00001617          	auipc	a2,0x1
ffffffffc020173a:	a2260613          	addi	a2,a2,-1502 # ffffffffc0202158 <etext+0x256>
ffffffffc020173e:	02400593          	li	a1,36
ffffffffc0201742:	00001517          	auipc	a0,0x1
ffffffffc0201746:	f4e50513          	addi	a0,a0,-178 # ffffffffc0202690 <etext+0x78e>
ffffffffc020174a:	a83fe0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_pages(2) == arena + 6);
ffffffffc020174e:	00001697          	auipc	a3,0x1
ffffffffc0201752:	0b268693          	addi	a3,a3,178 # ffffffffc0202800 <etext+0x8fe>
ffffffffc0201756:	00001617          	auipc	a2,0x1
ffffffffc020175a:	a0260613          	addi	a2,a2,-1534 # ffffffffc0202158 <etext+0x256>
ffffffffc020175e:	45f1                	li	a1,28
ffffffffc0201760:	00001517          	auipc	a0,0x1
ffffffffc0201764:	f3050513          	addi	a0,a0,-208 # ffffffffc0202690 <etext+0x78e>
ffffffffc0201768:	a65fe0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_page() == arena + 19);
ffffffffc020176c:	00001697          	auipc	a3,0x1
ffffffffc0201770:	07468693          	addi	a3,a3,116 # ffffffffc02027e0 <etext+0x8de>
ffffffffc0201774:	00001617          	auipc	a2,0x1
ffffffffc0201778:	9e460613          	addi	a2,a2,-1564 # ffffffffc0202158 <etext+0x256>
ffffffffc020177c:	45ed                	li	a1,27
ffffffffc020177e:	00001517          	auipc	a0,0x1
ffffffffc0201782:	f1250513          	addi	a0,a0,-238 # ffffffffc0202690 <etext+0x78e>
ffffffffc0201786:	a47fe0ef          	jal	ffffffffc02001cc <__panic>
    assert(nr_free_pages() == 0);
ffffffffc020178a:	00001697          	auipc	a3,0x1
ffffffffc020178e:	1a668693          	addi	a3,a3,422 # ffffffffc0202930 <etext+0xa2e>
ffffffffc0201792:	00001617          	auipc	a2,0x1
ffffffffc0201796:	9c660613          	addi	a2,a2,-1594 # ffffffffc0202158 <etext+0x256>
ffffffffc020179a:	03600593          	li	a1,54
ffffffffc020179e:	00001517          	auipc	a0,0x1
ffffffffc02017a2:	ef250513          	addi	a0,a0,-270 # ffffffffc0202690 <etext+0x78e>
ffffffffc02017a6:	a27fe0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_pages(12) == arena);
ffffffffc02017aa:	00001697          	auipc	a3,0x1
ffffffffc02017ae:	21668693          	addi	a3,a3,534 # ffffffffc02029c0 <etext+0xabe>
ffffffffc02017b2:	00001617          	auipc	a2,0x1
ffffffffc02017b6:	9a660613          	addi	a2,a2,-1626 # ffffffffc0202158 <etext+0x256>
ffffffffc02017ba:	03500593          	li	a1,53
ffffffffc02017be:	00001517          	auipc	a0,0x1
ffffffffc02017c2:	ed250513          	addi	a0,a0,-302 # ffffffffc0202690 <etext+0x78e>
ffffffffc02017c6:	a07fe0ef          	jal	ffffffffc02001cc <__panic>
    assert(nr_free_pages() == 0);
ffffffffc02017ca:	00001697          	auipc	a3,0x1
ffffffffc02017ce:	16668693          	addi	a3,a3,358 # ffffffffc0202930 <etext+0xa2e>
ffffffffc02017d2:	00001617          	auipc	a2,0x1
ffffffffc02017d6:	98660613          	addi	a2,a2,-1658 # ffffffffc0202158 <etext+0x256>
ffffffffc02017da:	02800593          	li	a1,40
ffffffffc02017de:	00001517          	auipc	a0,0x1
ffffffffc02017e2:	eb250513          	addi	a0,a0,-334 # ffffffffc0202690 <etext+0x78e>
ffffffffc02017e6:	9e7fe0ef          	jal	ffffffffc02001cc <__panic>
    assert(nr_free_pages() == 3);
ffffffffc02017ea:	00001697          	auipc	a3,0x1
ffffffffc02017ee:	fae68693          	addi	a3,a3,-82 # ffffffffc0202798 <etext+0x896>
ffffffffc02017f2:	00001617          	auipc	a2,0x1
ffffffffc02017f6:	96660613          	addi	a2,a2,-1690 # ffffffffc0202158 <etext+0x256>
ffffffffc02017fa:	45e1                	li	a1,24
ffffffffc02017fc:	00001517          	auipc	a0,0x1
ffffffffc0201800:	e9450513          	addi	a0,a0,-364 # ffffffffc0202690 <etext+0x78e>
ffffffffc0201804:	9c9fe0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc0201808 <pa2page.part.0>:
static inline struct Page *pa2page(uintptr_t pa) {
ffffffffc0201808:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc020180a:	00001617          	auipc	a2,0x1
ffffffffc020180e:	dce60613          	addi	a2,a2,-562 # ffffffffc02025d8 <etext+0x6d6>
ffffffffc0201812:	06a00593          	li	a1,106
ffffffffc0201816:	00001517          	auipc	a0,0x1
ffffffffc020181a:	de250513          	addi	a0,a0,-542 # ffffffffc02025f8 <etext+0x6f6>
static inline struct Page *pa2page(uintptr_t pa) {
ffffffffc020181e:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201820:	9adfe0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc0201824 <test_page_init>:
#include <dtb.h>
#include <test_lab2.h>

void
test_page_init(void)
{
ffffffffc0201824:	7179                	addi	sp,sp,-48
ffffffffc0201826:	f406                	sd	ra,40(sp)
ffffffffc0201828:	f022                	sd	s0,32(sp)
ffffffffc020182a:	ec26                	sd	s1,24(sp)
    extern char end[];
    uint64_t mem_base = get_memory_base();
ffffffffc020182c:	d73fe0ef          	jal	ffffffffc020059e <get_memory_base>
ffffffffc0201830:	842a                	mv	s0,a0
    uint64_t mem_size = get_memory_size();
    uintptr_t end_pa;

    /* 1. va_pa_offset must be set to the virtual/physical mapping offset */
    if (va_pa_offset != PHYSICAL_MEMORY_OFFSET) {
ffffffffc0201832:	00006497          	auipc	s1,0x6
ffffffffc0201836:	82e48493          	addi	s1,s1,-2002 # ffffffffc0207060 <va_pa_offset>
    uint64_t mem_size = get_memory_size();
ffffffffc020183a:	d6ffe0ef          	jal	ffffffffc02005a8 <get_memory_size>
    if (va_pa_offset != PHYSICAL_MEMORY_OFFSET) {
ffffffffc020183e:	6098                	ld	a4,0(s1)
ffffffffc0201840:	57f5                	li	a5,-3
ffffffffc0201842:	07fa                	slli	a5,a5,0x1e
ffffffffc0201844:	14f71363          	bne	a4,a5,ffffffffc020198a <test_page_init+0x166>
        cprintf("[Test 1] Page Init: FAIL (va_pa_offset)\n");
        return;
    }

    /* 2. the device tree must report a valid physical memory range */
    if (mem_base == 0 || mem_size == 0) {
ffffffffc0201848:	12040763          	beqz	s0,ffffffffc0201976 <test_page_init+0x152>
ffffffffc020184c:	12050563          	beqz	a0,ffffffffc0201976 <test_page_init+0x152>
ffffffffc0201850:	e84a                	sd	s2,16(sp)
    /* 3. npage must equal the page number of the reported memory end,
     *    and the upper bound must exceed the DRAM start page number */
    {
        uint64_t mem_end = mem_base + mem_size;
        size_t expect_npage = PPN(mem_end);
        if (npage != expect_npage || npage <= nbase) {
ffffffffc0201852:	00006917          	auipc	s2,0x6
ffffffffc0201856:	81690913          	addi	s2,s2,-2026 # ffffffffc0207068 <npage>
ffffffffc020185a:	00093583          	ld	a1,0(s2)
        uint64_t mem_end = mem_base + mem_size;
ffffffffc020185e:	9522                	add	a0,a0,s0
        size_t expect_npage = PPN(mem_end);
ffffffffc0201860:	00c55613          	srli	a2,a0,0xc
        if (npage != expect_npage || npage <= nbase) {
ffffffffc0201864:	12c59d63          	bne	a1,a2,ffffffffc020199e <test_page_init+0x17a>
ffffffffc0201868:	00001417          	auipc	s0,0x1
ffffffffc020186c:	7c843403          	ld	s0,1992(s0) # ffffffffc0203030 <nbase>
ffffffffc0201870:	12b47763          	bgeu	s0,a1,ffffffffc020199e <test_page_init+0x17a>
ffffffffc0201874:	e052                	sd	s4,0(sp)
            return;
        }
    }

    /* 4. pages must be non-null, page-aligned, and located after the kernel `end` */
    if (pages == NULL) {
ffffffffc0201876:	00005a17          	auipc	s4,0x5
ffffffffc020187a:	7faa0a13          	addi	s4,s4,2042 # ffffffffc0207070 <pages>
ffffffffc020187e:	000a3783          	ld	a5,0(s4)
ffffffffc0201882:	14078e63          	beqz	a5,ffffffffc02019de <test_page_init+0x1ba>
        cprintf("[Test 1] Page Init: FAIL (pages NULL)\n");
        return;
    }
    if (((uintptr_t)pages % PGSIZE) != 0) {
ffffffffc0201886:	03479713          	slli	a4,a5,0x34
ffffffffc020188a:	14071363          	bnez	a4,ffffffffc02019d0 <test_page_init+0x1ac>
        cprintf("[Test 1] Page Init: FAIL (pages not page-aligned)\n");
        return;
    }
    if ((uintptr_t)pages < (uintptr_t)ROUNDUP((uintptr_t)end, PGSIZE)) {
ffffffffc020188e:	00006717          	auipc	a4,0x6
ffffffffc0201892:	7e970713          	addi	a4,a4,2025 # ffffffffc0208077 <end+0xfff>
ffffffffc0201896:	76fd                	lui	a3,0xfffff
ffffffffc0201898:	e44e                	sd	s3,8(sp)
ffffffffc020189a:	8f75                	and	a4,a4,a3
ffffffffc020189c:	00005997          	auipc	s3,0x5
ffffffffc02018a0:	7dc98993          	addi	s3,s3,2012 # ffffffffc0207078 <end>
        cprintf("[Test 1] Page Init: FAIL (pages before kernel end)\n");
ffffffffc02018a4:	00001517          	auipc	a0,0x1
ffffffffc02018a8:	30450513          	addi	a0,a0,772 # ffffffffc0202ba8 <etext+0xca6>
    if ((uintptr_t)pages < (uintptr_t)ROUNDUP((uintptr_t)end, PGSIZE)) {
ffffffffc02018ac:	0ae7ec63          	bltu	a5,a4,ffffffffc0201964 <test_page_init+0x140>
        return;
    }

    /* 5. the free area must have been built: some free pages, not more than total */
    {
        size_t free_now = nr_free_pages();
ffffffffc02018b0:	f60ff0ef          	jal	ffffffffc0201010 <nr_free_pages>
        if (free_now == 0 || free_now > (npage - nbase)) {
ffffffffc02018b4:	10050063          	beqz	a0,ffffffffc02019b4 <test_page_init+0x190>
ffffffffc02018b8:	00093703          	ld	a4,0(s2)
ffffffffc02018bc:	408707b3          	sub	a5,a4,s0
ffffffffc02018c0:	0ea7ea63          	bltu	a5,a0,ffffffffc02019b4 <test_page_init+0x190>
            return;
        }
    }

    /* 6. the kernel-image tail page must not be handed to the allocator */
    end_pa = PADDR((uintptr_t)end);
ffffffffc02018c4:	c0200537          	lui	a0,0xc0200
ffffffffc02018c8:	14a9ea63          	bltu	s3,a0,ffffffffc0201a1c <test_page_init+0x1f8>
ffffffffc02018cc:	609c                	ld	a5,0(s1)
ffffffffc02018ce:	40f989b3          	sub	s3,s3,a5
    if (PPN(end_pa) >= npage) {
ffffffffc02018d2:	00c9d993          	srli	s3,s3,0xc
ffffffffc02018d6:	10e9fb63          	bgeu	s3,a4,ffffffffc02019ec <test_page_init+0x1c8>
    return &pages[PPN(pa) - nbase];
ffffffffc02018da:	408989b3          	sub	s3,s3,s0
ffffffffc02018de:	000a3683          	ld	a3,0(s4)
ffffffffc02018e2:	00299613          	slli	a2,s3,0x2
ffffffffc02018e6:	964e                	add	a2,a2,s3
ffffffffc02018e8:	060e                	slli	a2,a2,0x3
        cprintf("[Test 1] Page Init: FAIL (end pa out of range)\n");
        return;
    }
    if (!PageReserved(pa2page(end_pa))) {
ffffffffc02018ea:	00c685b3          	add	a1,a3,a2
ffffffffc02018ee:	658c                	ld	a1,8(a1)
ffffffffc02018f0:	8985                	andi	a1,a1,1
ffffffffc02018f2:	10058263          	beqz	a1,ffffffffc02019f6 <test_page_init+0x1d2>
        return;
    }

    /* 7. the pages occupied by the page-descriptor array must stay reserved too */
    {
        uintptr_t pages_pa = PADDR((uintptr_t)pages);
ffffffffc02018f6:	10a6e563          	bltu	a3,a0,ffffffffc0201a00 <test_page_init+0x1dc>
ffffffffc02018fa:	40f687b3          	sub	a5,a3,a5
        if (PPN(pages_pa) >= npage) {
ffffffffc02018fe:	83b1                	srli	a5,a5,0xc
            cprintf("[Test 1] Page Init: FAIL (pages pa out of range)\n");
ffffffffc0201900:	00001517          	auipc	a0,0x1
ffffffffc0201904:	38850513          	addi	a0,a0,904 # ffffffffc0202c88 <etext+0xd86>
        if (PPN(pages_pa) >= npage) {
ffffffffc0201908:	04e7fe63          	bgeu	a5,a4,ffffffffc0201964 <test_page_init+0x140>
ffffffffc020190c:	8f81                	sub	a5,a5,s0
            return;
        }
        if (!PageReserved(pa2page(pages_pa))) {
ffffffffc020190e:	00279593          	slli	a1,a5,0x2
ffffffffc0201912:	97ae                	add	a5,a5,a1
ffffffffc0201914:	078e                	slli	a5,a5,0x3
ffffffffc0201916:	96be                	add	a3,a3,a5
ffffffffc0201918:	669c                	ld	a5,8(a3)
            cprintf("[Test 1] Page Init: FAIL (pages array not reserved)\n");
ffffffffc020191a:	00001517          	auipc	a0,0x1
ffffffffc020191e:	3a650513          	addi	a0,a0,934 # ffffffffc0202cc0 <etext+0xdbe>
        if (!PageReserved(pa2page(pages_pa))) {
ffffffffc0201922:	8b85                	andi	a5,a5,1
ffffffffc0201924:	c3a1                	beqz	a5,ffffffffc0201964 <test_page_init+0x140>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201926:	ccccd7b7          	lui	a5,0xccccd
ffffffffc020192a:	ccd78793          	addi	a5,a5,-819 # ffffffffcccccccd <end+0xcac5c55>
ffffffffc020192e:	02079693          	slli	a3,a5,0x20
ffffffffc0201932:	96be                	add	a3,a3,a5
ffffffffc0201934:	40365793          	srai	a5,a2,0x3
ffffffffc0201938:	02d787b3          	mul	a5,a5,a3
ffffffffc020193c:	97a2                	add	a5,a5,s0
    if (PPN(pa) >= npage) {
ffffffffc020193e:	07b2                	slli	a5,a5,0xc
ffffffffc0201940:	83b1                	srli	a5,a5,0xc
ffffffffc0201942:	0ce7fb63          	bgeu	a5,a4,ffffffffc0201a18 <test_page_init+0x1f4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201946:	8f81                	sub	a5,a5,s0
ffffffffc0201948:	00279713          	slli	a4,a5,0x2
ffffffffc020194c:	97ba                	add	a5,a5,a4
ffffffffc020194e:	078e                	slli	a5,a5,0x3

    /* 8. page2pa / pa2page round-trip must be correct */
    {
        struct Page *q = pa2page(end_pa);
        if (pa2page(page2pa(q)) != q) {
            cprintf("[Test 1] Page Init: FAIL (roundtrip)\n");
ffffffffc0201950:	00001517          	auipc	a0,0x1
ffffffffc0201954:	3a850513          	addi	a0,a0,936 # ffffffffc0202cf8 <etext+0xdf6>
        if (pa2page(page2pa(q)) != q) {
ffffffffc0201958:	00f61663          	bne	a2,a5,ffffffffc0201964 <test_page_init+0x140>
            return;
        }
    }

    cprintf("[Test 1] Page Init: PASS\n");
ffffffffc020195c:	00001517          	auipc	a0,0x1
ffffffffc0201960:	3c450513          	addi	a0,a0,964 # ffffffffc0202d20 <etext+0xe1e>
ffffffffc0201964:	6942                	ld	s2,16(sp)
ffffffffc0201966:	69a2                	ld	s3,8(sp)
ffffffffc0201968:	6a02                	ld	s4,0(sp)
}
ffffffffc020196a:	7402                	ld	s0,32(sp)
ffffffffc020196c:	70a2                	ld	ra,40(sp)
ffffffffc020196e:	64e2                	ld	s1,24(sp)
ffffffffc0201970:	6145                	addi	sp,sp,48
    cprintf("[Test 1] Page Init: PASS\n");
ffffffffc0201972:	fd8fe06f          	j	ffffffffc020014a <cprintf>
}
ffffffffc0201976:	7402                	ld	s0,32(sp)
ffffffffc0201978:	70a2                	ld	ra,40(sp)
ffffffffc020197a:	64e2                	ld	s1,24(sp)
        cprintf("[Test 1] Page Init: FAIL (dtb mem 0)\n");
ffffffffc020197c:	00001517          	auipc	a0,0x1
ffffffffc0201980:	16c50513          	addi	a0,a0,364 # ffffffffc0202ae8 <etext+0xbe6>
}
ffffffffc0201984:	6145                	addi	sp,sp,48
    cprintf("[Test 1] Page Init: PASS\n");
ffffffffc0201986:	fc4fe06f          	j	ffffffffc020014a <cprintf>
}
ffffffffc020198a:	7402                	ld	s0,32(sp)
ffffffffc020198c:	70a2                	ld	ra,40(sp)
ffffffffc020198e:	64e2                	ld	s1,24(sp)
        cprintf("[Test 1] Page Init: FAIL (va_pa_offset)\n");
ffffffffc0201990:	00001517          	auipc	a0,0x1
ffffffffc0201994:	12850513          	addi	a0,a0,296 # ffffffffc0202ab8 <etext+0xbb6>
}
ffffffffc0201998:	6145                	addi	sp,sp,48
    cprintf("[Test 1] Page Init: PASS\n");
ffffffffc020199a:	fb0fe06f          	j	ffffffffc020014a <cprintf>
}
ffffffffc020199e:	7402                	ld	s0,32(sp)
            cprintf("[Test 1] Page Init: FAIL (npage=%lu expect=%lu)\n",
ffffffffc02019a0:	6942                	ld	s2,16(sp)
}
ffffffffc02019a2:	70a2                	ld	ra,40(sp)
ffffffffc02019a4:	64e2                	ld	s1,24(sp)
            cprintf("[Test 1] Page Init: FAIL (npage=%lu expect=%lu)\n",
ffffffffc02019a6:	00001517          	auipc	a0,0x1
ffffffffc02019aa:	16a50513          	addi	a0,a0,362 # ffffffffc0202b10 <etext+0xc0e>
}
ffffffffc02019ae:	6145                	addi	sp,sp,48
            cprintf("[Test 1] Page Init: FAIL (npage=%lu expect=%lu)\n",
ffffffffc02019b0:	f9afe06f          	j	ffffffffc020014a <cprintf>
}
ffffffffc02019b4:	7402                	ld	s0,32(sp)
            cprintf("[Test 1] Page Init: FAIL (nr_free=%lu)\n",
ffffffffc02019b6:	6942                	ld	s2,16(sp)
ffffffffc02019b8:	69a2                	ld	s3,8(sp)
ffffffffc02019ba:	6a02                	ld	s4,0(sp)
}
ffffffffc02019bc:	70a2                	ld	ra,40(sp)
ffffffffc02019be:	64e2                	ld	s1,24(sp)
            cprintf("[Test 1] Page Init: FAIL (nr_free=%lu)\n",
ffffffffc02019c0:	85aa                	mv	a1,a0
ffffffffc02019c2:	00001517          	auipc	a0,0x1
ffffffffc02019c6:	21e50513          	addi	a0,a0,542 # ffffffffc0202be0 <etext+0xcde>
}
ffffffffc02019ca:	6145                	addi	sp,sp,48
            cprintf("[Test 1] Page Init: FAIL (nr_free=%lu)\n",
ffffffffc02019cc:	f7efe06f          	j	ffffffffc020014a <cprintf>
        cprintf("[Test 1] Page Init: FAIL (pages not page-aligned)\n");
ffffffffc02019d0:	6942                	ld	s2,16(sp)
    cprintf("[Test 1] Page Init: PASS\n");
ffffffffc02019d2:	6a02                	ld	s4,0(sp)
        cprintf("[Test 1] Page Init: FAIL (pages not page-aligned)\n");
ffffffffc02019d4:	00001517          	auipc	a0,0x1
ffffffffc02019d8:	19c50513          	addi	a0,a0,412 # ffffffffc0202b70 <etext+0xc6e>
ffffffffc02019dc:	b779                	j	ffffffffc020196a <test_page_init+0x146>
        cprintf("[Test 1] Page Init: FAIL (pages NULL)\n");
ffffffffc02019de:	6942                	ld	s2,16(sp)
    cprintf("[Test 1] Page Init: PASS\n");
ffffffffc02019e0:	6a02                	ld	s4,0(sp)
        cprintf("[Test 1] Page Init: FAIL (pages NULL)\n");
ffffffffc02019e2:	00001517          	auipc	a0,0x1
ffffffffc02019e6:	16650513          	addi	a0,a0,358 # ffffffffc0202b48 <etext+0xc46>
ffffffffc02019ea:	b741                	j	ffffffffc020196a <test_page_init+0x146>
        cprintf("[Test 1] Page Init: FAIL (end pa out of range)\n");
ffffffffc02019ec:	00001517          	auipc	a0,0x1
ffffffffc02019f0:	23450513          	addi	a0,a0,564 # ffffffffc0202c20 <etext+0xd1e>
ffffffffc02019f4:	bf85                	j	ffffffffc0201964 <test_page_init+0x140>
        cprintf("[Test 1] Page Init: FAIL (kernel tail not reserved)\n");
ffffffffc02019f6:	00001517          	auipc	a0,0x1
ffffffffc02019fa:	25a50513          	addi	a0,a0,602 # ffffffffc0202c50 <etext+0xd4e>
ffffffffc02019fe:	b79d                	j	ffffffffc0201964 <test_page_init+0x140>
        uintptr_t pages_pa = PADDR((uintptr_t)pages);
ffffffffc0201a00:	00001617          	auipc	a2,0x1
ffffffffc0201a04:	b6060613          	addi	a2,a2,-1184 # ffffffffc0202560 <etext+0x65e>
ffffffffc0201a08:	05000593          	li	a1,80
ffffffffc0201a0c:	00001517          	auipc	a0,0x1
ffffffffc0201a10:	1fc50513          	addi	a0,a0,508 # ffffffffc0202c08 <etext+0xd06>
ffffffffc0201a14:	fb8fe0ef          	jal	ffffffffc02001cc <__panic>
ffffffffc0201a18:	df1ff0ef          	jal	ffffffffc0201808 <pa2page.part.0>
    end_pa = PADDR((uintptr_t)end);
ffffffffc0201a1c:	00005697          	auipc	a3,0x5
ffffffffc0201a20:	65c68693          	addi	a3,a3,1628 # ffffffffc0207078 <end>
ffffffffc0201a24:	00001617          	auipc	a2,0x1
ffffffffc0201a28:	b3c60613          	addi	a2,a2,-1220 # ffffffffc0202560 <etext+0x65e>
ffffffffc0201a2c:	04400593          	li	a1,68
ffffffffc0201a30:	00001517          	auipc	a0,0x1
ffffffffc0201a34:	1d850513          	addi	a0,a0,472 # ffffffffc0202c08 <etext+0xd06>
ffffffffc0201a38:	f94fe0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc0201a3c <test_best_fit>:

void
test_best_fit(void)
{
    if (pmm_manager != &best_fit_pmm_manager) {
ffffffffc0201a3c:	00005797          	auipc	a5,0x5
ffffffffc0201a40:	60c7b783          	ld	a5,1548(a5) # ffffffffc0207048 <pmm_manager>
ffffffffc0201a44:	00001717          	auipc	a4,0x1
ffffffffc0201a48:	42470713          	addi	a4,a4,1060 # ffffffffc0202e68 <best_fit_pmm_manager>
ffffffffc0201a4c:	00e78963          	beq	a5,a4,ffffffffc0201a5e <test_best_fit+0x22>
        cprintf("[Test 2] Best-Fit: FAIL (pmm_manager=%s)\n", pmm_manager->name);
ffffffffc0201a50:	638c                	ld	a1,0(a5)
ffffffffc0201a52:	00001517          	auipc	a0,0x1
ffffffffc0201a56:	2ee50513          	addi	a0,a0,750 # ffffffffc0202d40 <etext+0xe3e>
ffffffffc0201a5a:	ef0fe06f          	j	ffffffffc020014a <cprintf>
        return;
    }
    cprintf("[Test 2] Best-Fit: PASS\n");
ffffffffc0201a5e:	00001517          	auipc	a0,0x1
ffffffffc0201a62:	31250513          	addi	a0,a0,786 # ffffffffc0202d70 <etext+0xe6e>
ffffffffc0201a66:	ee4fe06f          	j	ffffffffc020014a <cprintf>

ffffffffc0201a6a <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201a6a:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a6e:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201a70:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a74:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201a76:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a7a:	f022                	sd	s0,32(sp)
ffffffffc0201a7c:	ec26                	sd	s1,24(sp)
ffffffffc0201a7e:	e84a                	sd	s2,16(sp)
ffffffffc0201a80:	f406                	sd	ra,40(sp)
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201a82:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a86:	84aa                	mv	s1,a0
ffffffffc0201a88:	892e                	mv	s2,a1
    unsigned mod = do_div(result, base);
ffffffffc0201a8a:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201a8c:	05067063          	bgeu	a2,a6,ffffffffc0201acc <printnum+0x62>
ffffffffc0201a90:	e44e                	sd	s3,8(sp)
ffffffffc0201a92:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201a94:	4785                	li	a5,1
ffffffffc0201a96:	00e7d763          	bge	a5,a4,ffffffffc0201aa4 <printnum+0x3a>
            putch(padc, putdat);
ffffffffc0201a9a:	85ca                	mv	a1,s2
ffffffffc0201a9c:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc0201a9e:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201aa0:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201aa2:	fc65                	bnez	s0,ffffffffc0201a9a <printnum+0x30>
ffffffffc0201aa4:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201aa6:	1a02                	slli	s4,s4,0x20
ffffffffc0201aa8:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201aac:	00001797          	auipc	a5,0x1
ffffffffc0201ab0:	2e478793          	addi	a5,a5,740 # ffffffffc0202d90 <etext+0xe8e>
ffffffffc0201ab4:	97d2                	add	a5,a5,s4
}
ffffffffc0201ab6:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201ab8:	0007c503          	lbu	a0,0(a5)
}
ffffffffc0201abc:	70a2                	ld	ra,40(sp)
ffffffffc0201abe:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201ac0:	85ca                	mv	a1,s2
ffffffffc0201ac2:	87a6                	mv	a5,s1
}
ffffffffc0201ac4:	6942                	ld	s2,16(sp)
ffffffffc0201ac6:	64e2                	ld	s1,24(sp)
ffffffffc0201ac8:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201aca:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201acc:	03065633          	divu	a2,a2,a6
ffffffffc0201ad0:	8722                	mv	a4,s0
ffffffffc0201ad2:	f99ff0ef          	jal	ffffffffc0201a6a <printnum>
ffffffffc0201ad6:	bfc1                	j	ffffffffc0201aa6 <printnum+0x3c>

ffffffffc0201ad8 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201ad8:	7119                	addi	sp,sp,-128
ffffffffc0201ada:	f4a6                	sd	s1,104(sp)
ffffffffc0201adc:	f0ca                	sd	s2,96(sp)
ffffffffc0201ade:	ecce                	sd	s3,88(sp)
ffffffffc0201ae0:	e8d2                	sd	s4,80(sp)
ffffffffc0201ae2:	e4d6                	sd	s5,72(sp)
ffffffffc0201ae4:	e0da                	sd	s6,64(sp)
ffffffffc0201ae6:	f862                	sd	s8,48(sp)
ffffffffc0201ae8:	fc86                	sd	ra,120(sp)
ffffffffc0201aea:	f8a2                	sd	s0,112(sp)
ffffffffc0201aec:	fc5e                	sd	s7,56(sp)
ffffffffc0201aee:	f466                	sd	s9,40(sp)
ffffffffc0201af0:	f06a                	sd	s10,32(sp)
ffffffffc0201af2:	ec6e                	sd	s11,24(sp)
ffffffffc0201af4:	892a                	mv	s2,a0
ffffffffc0201af6:	84ae                	mv	s1,a1
ffffffffc0201af8:	8c32                	mv	s8,a2
ffffffffc0201afa:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201afc:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b00:	05500b13          	li	s6,85
ffffffffc0201b04:	00001a97          	auipc	s5,0x1
ffffffffc0201b08:	39ca8a93          	addi	s5,s5,924 # ffffffffc0202ea0 <best_fit_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201b0c:	000c4503          	lbu	a0,0(s8)
ffffffffc0201b10:	001c0413          	addi	s0,s8,1
ffffffffc0201b14:	01350a63          	beq	a0,s3,ffffffffc0201b28 <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0201b18:	cd0d                	beqz	a0,ffffffffc0201b52 <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0201b1a:	85a6                	mv	a1,s1
ffffffffc0201b1c:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201b1e:	00044503          	lbu	a0,0(s0)
ffffffffc0201b22:	0405                	addi	s0,s0,1
ffffffffc0201b24:	ff351ae3          	bne	a0,s3,ffffffffc0201b18 <vprintfmt+0x40>
        width = precision = -1;
ffffffffc0201b28:	5cfd                	li	s9,-1
ffffffffc0201b2a:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc0201b2c:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc0201b30:	4b81                	li	s7,0
ffffffffc0201b32:	4601                	li	a2,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b34:	00044683          	lbu	a3,0(s0)
ffffffffc0201b38:	00140c13          	addi	s8,s0,1
ffffffffc0201b3c:	fdd6859b          	addiw	a1,a3,-35
ffffffffc0201b40:	0ff5f593          	zext.b	a1,a1
ffffffffc0201b44:	02bb6663          	bltu	s6,a1,ffffffffc0201b70 <vprintfmt+0x98>
ffffffffc0201b48:	058a                	slli	a1,a1,0x2
ffffffffc0201b4a:	95d6                	add	a1,a1,s5
ffffffffc0201b4c:	4198                	lw	a4,0(a1)
ffffffffc0201b4e:	9756                	add	a4,a4,s5
ffffffffc0201b50:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201b52:	70e6                	ld	ra,120(sp)
ffffffffc0201b54:	7446                	ld	s0,112(sp)
ffffffffc0201b56:	74a6                	ld	s1,104(sp)
ffffffffc0201b58:	7906                	ld	s2,96(sp)
ffffffffc0201b5a:	69e6                	ld	s3,88(sp)
ffffffffc0201b5c:	6a46                	ld	s4,80(sp)
ffffffffc0201b5e:	6aa6                	ld	s5,72(sp)
ffffffffc0201b60:	6b06                	ld	s6,64(sp)
ffffffffc0201b62:	7be2                	ld	s7,56(sp)
ffffffffc0201b64:	7c42                	ld	s8,48(sp)
ffffffffc0201b66:	7ca2                	ld	s9,40(sp)
ffffffffc0201b68:	7d02                	ld	s10,32(sp)
ffffffffc0201b6a:	6de2                	ld	s11,24(sp)
ffffffffc0201b6c:	6109                	addi	sp,sp,128
ffffffffc0201b6e:	8082                	ret
            putch('%', putdat);
ffffffffc0201b70:	85a6                	mv	a1,s1
ffffffffc0201b72:	02500513          	li	a0,37
ffffffffc0201b76:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201b78:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201b7c:	02500713          	li	a4,37
ffffffffc0201b80:	8c22                	mv	s8,s0
ffffffffc0201b82:	f8e785e3          	beq	a5,a4,ffffffffc0201b0c <vprintfmt+0x34>
ffffffffc0201b86:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0201b8a:	1c7d                	addi	s8,s8,-1
ffffffffc0201b8c:	fee79de3          	bne	a5,a4,ffffffffc0201b86 <vprintfmt+0xae>
ffffffffc0201b90:	bfb5                	j	ffffffffc0201b0c <vprintfmt+0x34>
                ch = *fmt;
ffffffffc0201b92:	00144783          	lbu	a5,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc0201b96:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc0201b98:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0201b9c:	fd07871b          	addiw	a4,a5,-48
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ba0:	8462                	mv	s0,s8
                ch = *fmt;
ffffffffc0201ba2:	2781                	sext.w	a5,a5
                if (ch < '0' || ch > '9') {
ffffffffc0201ba4:	02e56463          	bltu	a0,a4,ffffffffc0201bcc <vprintfmt+0xf4>
                precision = precision * 10 + ch - '0';
ffffffffc0201ba8:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc0201bac:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201bb0:	0197073b          	addw	a4,a4,s9
ffffffffc0201bb4:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201bb8:	9f3d                	addw	a4,a4,a5
                if (ch < '0' || ch > '9') {
ffffffffc0201bba:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201bbe:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201bc0:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0201bc4:	0006879b          	sext.w	a5,a3
                if (ch < '0' || ch > '9') {
ffffffffc0201bc8:	feb570e3          	bgeu	a0,a1,ffffffffc0201ba8 <vprintfmt+0xd0>
            if (width < 0)
ffffffffc0201bcc:	f60d54e3          	bgez	s10,ffffffffc0201b34 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc0201bd0:	8d66                	mv	s10,s9
ffffffffc0201bd2:	5cfd                	li	s9,-1
ffffffffc0201bd4:	b785                	j	ffffffffc0201b34 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bd6:	8db6                	mv	s11,a3
ffffffffc0201bd8:	8462                	mv	s0,s8
ffffffffc0201bda:	bfa9                	j	ffffffffc0201b34 <vprintfmt+0x5c>
ffffffffc0201bdc:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0201bde:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0201be0:	bf91                	j	ffffffffc0201b34 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc0201be2:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201be4:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc0201be8:	00c7c463          	blt	a5,a2,ffffffffc0201bf0 <vprintfmt+0x118>
    else if (lflag) {
ffffffffc0201bec:	18060763          	beqz	a2,ffffffffc0201d7a <vprintfmt+0x2a2>
        return va_arg(*ap, unsigned long);
ffffffffc0201bf0:	000a3603          	ld	a2,0(s4)
ffffffffc0201bf4:	46c1                	li	a3,16
ffffffffc0201bf6:	8a3a                	mv	s4,a4
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201bf8:	000d879b          	sext.w	a5,s11
ffffffffc0201bfc:	876a                	mv	a4,s10
ffffffffc0201bfe:	85a6                	mv	a1,s1
ffffffffc0201c00:	854a                	mv	a0,s2
ffffffffc0201c02:	e69ff0ef          	jal	ffffffffc0201a6a <printnum>
            break;
ffffffffc0201c06:	b719                	j	ffffffffc0201b0c <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0201c08:	000a2503          	lw	a0,0(s4)
ffffffffc0201c0c:	85a6                	mv	a1,s1
ffffffffc0201c0e:	0a21                	addi	s4,s4,8
ffffffffc0201c10:	9902                	jalr	s2
            break;
ffffffffc0201c12:	bded                	j	ffffffffc0201b0c <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0201c14:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201c16:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc0201c1a:	00c7c463          	blt	a5,a2,ffffffffc0201c22 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc0201c1e:	14060963          	beqz	a2,ffffffffc0201d70 <vprintfmt+0x298>
        return va_arg(*ap, unsigned long);
ffffffffc0201c22:	000a3603          	ld	a2,0(s4)
ffffffffc0201c26:	46a9                	li	a3,10
ffffffffc0201c28:	8a3a                	mv	s4,a4
ffffffffc0201c2a:	b7f9                	j	ffffffffc0201bf8 <vprintfmt+0x120>
            putch('0', putdat);
ffffffffc0201c2c:	85a6                	mv	a1,s1
ffffffffc0201c2e:	03000513          	li	a0,48
ffffffffc0201c32:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201c34:	85a6                	mv	a1,s1
ffffffffc0201c36:	07800513          	li	a0,120
ffffffffc0201c3a:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201c3c:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc0201c40:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201c42:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201c44:	bf55                	j	ffffffffc0201bf8 <vprintfmt+0x120>
            putch(ch, putdat);
ffffffffc0201c46:	85a6                	mv	a1,s1
ffffffffc0201c48:	02500513          	li	a0,37
ffffffffc0201c4c:	9902                	jalr	s2
            break;
ffffffffc0201c4e:	bd7d                	j	ffffffffc0201b0c <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc0201c50:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c54:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0201c56:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc0201c58:	bf95                	j	ffffffffc0201bcc <vprintfmt+0xf4>
    if (lflag >= 2) {
ffffffffc0201c5a:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201c5c:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc0201c60:	00c7c463          	blt	a5,a2,ffffffffc0201c68 <vprintfmt+0x190>
    else if (lflag) {
ffffffffc0201c64:	10060163          	beqz	a2,ffffffffc0201d66 <vprintfmt+0x28e>
        return va_arg(*ap, unsigned long);
ffffffffc0201c68:	000a3603          	ld	a2,0(s4)
ffffffffc0201c6c:	46a1                	li	a3,8
ffffffffc0201c6e:	8a3a                	mv	s4,a4
ffffffffc0201c70:	b761                	j	ffffffffc0201bf8 <vprintfmt+0x120>
            if (width < 0)
ffffffffc0201c72:	87ea                	mv	a5,s10
ffffffffc0201c74:	000d5363          	bgez	s10,ffffffffc0201c7a <vprintfmt+0x1a2>
ffffffffc0201c78:	4781                	li	a5,0
ffffffffc0201c7a:	00078d1b          	sext.w	s10,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c7e:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0201c80:	bd55                	j	ffffffffc0201b34 <vprintfmt+0x5c>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201c82:	000a3703          	ld	a4,0(s4)
ffffffffc0201c86:	12070b63          	beqz	a4,ffffffffc0201dbc <vprintfmt+0x2e4>
            if (width > 0 && padc != '-') {
ffffffffc0201c8a:	0da05563          	blez	s10,ffffffffc0201d54 <vprintfmt+0x27c>
ffffffffc0201c8e:	02d00793          	li	a5,45
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c92:	00170413          	addi	s0,a4,1
            if (width > 0 && padc != '-') {
ffffffffc0201c96:	14fd9a63          	bne	s11,a5,ffffffffc0201dea <vprintfmt+0x312>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c9a:	00074783          	lbu	a5,0(a4)
ffffffffc0201c9e:	0007851b          	sext.w	a0,a5
ffffffffc0201ca2:	c785                	beqz	a5,ffffffffc0201cca <vprintfmt+0x1f2>
ffffffffc0201ca4:	5dfd                	li	s11,-1
ffffffffc0201ca6:	000cc563          	bltz	s9,ffffffffc0201cb0 <vprintfmt+0x1d8>
ffffffffc0201caa:	3cfd                	addiw	s9,s9,-1
ffffffffc0201cac:	01bc8d63          	beq	s9,s11,ffffffffc0201cc6 <vprintfmt+0x1ee>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201cb0:	0c0b9a63          	bnez	s7,ffffffffc0201d84 <vprintfmt+0x2ac>
                    putch(ch, putdat);
ffffffffc0201cb4:	85a6                	mv	a1,s1
ffffffffc0201cb6:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201cb8:	00044783          	lbu	a5,0(s0)
ffffffffc0201cbc:	0405                	addi	s0,s0,1
ffffffffc0201cbe:	3d7d                	addiw	s10,s10,-1
ffffffffc0201cc0:	0007851b          	sext.w	a0,a5
ffffffffc0201cc4:	f3ed                	bnez	a5,ffffffffc0201ca6 <vprintfmt+0x1ce>
            for (; width > 0; width --) {
ffffffffc0201cc6:	01a05963          	blez	s10,ffffffffc0201cd8 <vprintfmt+0x200>
                putch(' ', putdat);
ffffffffc0201cca:	85a6                	mv	a1,s1
ffffffffc0201ccc:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc0201cd0:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc0201cd2:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201cd4:	fe0d1be3          	bnez	s10,ffffffffc0201cca <vprintfmt+0x1f2>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201cd8:	0a21                	addi	s4,s4,8
ffffffffc0201cda:	bd0d                	j	ffffffffc0201b0c <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0201cdc:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201cde:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc0201ce2:	00c7c363          	blt	a5,a2,ffffffffc0201ce8 <vprintfmt+0x210>
    else if (lflag) {
ffffffffc0201ce6:	c625                	beqz	a2,ffffffffc0201d4e <vprintfmt+0x276>
        return va_arg(*ap, long);
ffffffffc0201ce8:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201cec:	0a044f63          	bltz	s0,ffffffffc0201daa <vprintfmt+0x2d2>
            num = getint(&ap, lflag);
ffffffffc0201cf0:	8622                	mv	a2,s0
ffffffffc0201cf2:	8a5e                	mv	s4,s7
ffffffffc0201cf4:	46a9                	li	a3,10
ffffffffc0201cf6:	b709                	j	ffffffffc0201bf8 <vprintfmt+0x120>
            if (err < 0) {
ffffffffc0201cf8:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201cfc:	4619                	li	a2,6
            if (err < 0) {
ffffffffc0201cfe:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc0201d02:	8fb9                	xor	a5,a5,a4
ffffffffc0201d04:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201d08:	02d64663          	blt	a2,a3,ffffffffc0201d34 <vprintfmt+0x25c>
ffffffffc0201d0c:	00001797          	auipc	a5,0x1
ffffffffc0201d10:	2ec78793          	addi	a5,a5,748 # ffffffffc0202ff8 <error_string>
ffffffffc0201d14:	00369713          	slli	a4,a3,0x3
ffffffffc0201d18:	97ba                	add	a5,a5,a4
ffffffffc0201d1a:	639c                	ld	a5,0(a5)
ffffffffc0201d1c:	cf81                	beqz	a5,ffffffffc0201d34 <vprintfmt+0x25c>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201d1e:	86be                	mv	a3,a5
ffffffffc0201d20:	00001617          	auipc	a2,0x1
ffffffffc0201d24:	0a060613          	addi	a2,a2,160 # ffffffffc0202dc0 <etext+0xebe>
ffffffffc0201d28:	85a6                	mv	a1,s1
ffffffffc0201d2a:	854a                	mv	a0,s2
ffffffffc0201d2c:	0f4000ef          	jal	ffffffffc0201e20 <printfmt>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201d30:	0a21                	addi	s4,s4,8
ffffffffc0201d32:	bbe9                	j	ffffffffc0201b0c <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201d34:	00001617          	auipc	a2,0x1
ffffffffc0201d38:	07c60613          	addi	a2,a2,124 # ffffffffc0202db0 <etext+0xeae>
ffffffffc0201d3c:	85a6                	mv	a1,s1
ffffffffc0201d3e:	854a                	mv	a0,s2
ffffffffc0201d40:	0e0000ef          	jal	ffffffffc0201e20 <printfmt>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201d44:	0a21                	addi	s4,s4,8
ffffffffc0201d46:	b3d9                	j	ffffffffc0201b0c <vprintfmt+0x34>
            lflag ++;
ffffffffc0201d48:	2605                	addiw	a2,a2,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201d4a:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0201d4c:	b3e5                	j	ffffffffc0201b34 <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc0201d4e:	000a2403          	lw	s0,0(s4)
ffffffffc0201d52:	bf69                	j	ffffffffc0201cec <vprintfmt+0x214>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d54:	00074783          	lbu	a5,0(a4)
ffffffffc0201d58:	0007851b          	sext.w	a0,a5
ffffffffc0201d5c:	dfb5                	beqz	a5,ffffffffc0201cd8 <vprintfmt+0x200>
ffffffffc0201d5e:	00170413          	addi	s0,a4,1
ffffffffc0201d62:	5dfd                	li	s11,-1
ffffffffc0201d64:	b789                	j	ffffffffc0201ca6 <vprintfmt+0x1ce>
        return va_arg(*ap, unsigned int);
ffffffffc0201d66:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d6a:	46a1                	li	a3,8
ffffffffc0201d6c:	8a3a                	mv	s4,a4
ffffffffc0201d6e:	b569                	j	ffffffffc0201bf8 <vprintfmt+0x120>
ffffffffc0201d70:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d74:	46a9                	li	a3,10
ffffffffc0201d76:	8a3a                	mv	s4,a4
ffffffffc0201d78:	b541                	j	ffffffffc0201bf8 <vprintfmt+0x120>
ffffffffc0201d7a:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d7e:	46c1                	li	a3,16
ffffffffc0201d80:	8a3a                	mv	s4,a4
ffffffffc0201d82:	bd9d                	j	ffffffffc0201bf8 <vprintfmt+0x120>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201d84:	3781                	addiw	a5,a5,-32
ffffffffc0201d86:	05e00713          	li	a4,94
ffffffffc0201d8a:	f2f775e3          	bgeu	a4,a5,ffffffffc0201cb4 <vprintfmt+0x1dc>
                    putch('?', putdat);
ffffffffc0201d8e:	03f00513          	li	a0,63
ffffffffc0201d92:	85a6                	mv	a1,s1
ffffffffc0201d94:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d96:	00044783          	lbu	a5,0(s0)
ffffffffc0201d9a:	0405                	addi	s0,s0,1
ffffffffc0201d9c:	3d7d                	addiw	s10,s10,-1
ffffffffc0201d9e:	0007851b          	sext.w	a0,a5
ffffffffc0201da2:	d395                	beqz	a5,ffffffffc0201cc6 <vprintfmt+0x1ee>
ffffffffc0201da4:	f00cd3e3          	bgez	s9,ffffffffc0201caa <vprintfmt+0x1d2>
ffffffffc0201da8:	bff1                	j	ffffffffc0201d84 <vprintfmt+0x2ac>
                putch('-', putdat);
ffffffffc0201daa:	85a6                	mv	a1,s1
ffffffffc0201dac:	02d00513          	li	a0,45
ffffffffc0201db0:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201db2:	40800633          	neg	a2,s0
ffffffffc0201db6:	8a5e                	mv	s4,s7
ffffffffc0201db8:	46a9                	li	a3,10
ffffffffc0201dba:	bd3d                	j	ffffffffc0201bf8 <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
ffffffffc0201dbc:	01a05663          	blez	s10,ffffffffc0201dc8 <vprintfmt+0x2f0>
ffffffffc0201dc0:	02d00793          	li	a5,45
ffffffffc0201dc4:	00fd9b63          	bne	s11,a5,ffffffffc0201dda <vprintfmt+0x302>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201dc8:	02800793          	li	a5,40
ffffffffc0201dcc:	853e                	mv	a0,a5
ffffffffc0201dce:	00001417          	auipc	s0,0x1
ffffffffc0201dd2:	fdb40413          	addi	s0,s0,-37 # ffffffffc0202da9 <etext+0xea7>
ffffffffc0201dd6:	5dfd                	li	s11,-1
ffffffffc0201dd8:	b5f9                	j	ffffffffc0201ca6 <vprintfmt+0x1ce>
ffffffffc0201dda:	00001417          	auipc	s0,0x1
ffffffffc0201dde:	fcf40413          	addi	s0,s0,-49 # ffffffffc0202da9 <etext+0xea7>
                p = "(null)";
ffffffffc0201de2:	00001717          	auipc	a4,0x1
ffffffffc0201de6:	fc670713          	addi	a4,a4,-58 # ffffffffc0202da8 <etext+0xea6>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201dea:	853a                	mv	a0,a4
ffffffffc0201dec:	85e6                	mv	a1,s9
ffffffffc0201dee:	e43a                	sd	a4,8(sp)
ffffffffc0201df0:	084000ef          	jal	ffffffffc0201e74 <strnlen>
ffffffffc0201df4:	40ad0d3b          	subw	s10,s10,a0
ffffffffc0201df8:	6722                	ld	a4,8(sp)
ffffffffc0201dfa:	01a05b63          	blez	s10,ffffffffc0201e10 <vprintfmt+0x338>
                    putch(padc, putdat);
ffffffffc0201dfe:	2d81                	sext.w	s11,s11
ffffffffc0201e00:	85a6                	mv	a1,s1
ffffffffc0201e02:	856e                	mv	a0,s11
ffffffffc0201e04:	e43a                	sd	a4,8(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201e06:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc0201e08:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201e0a:	6722                	ld	a4,8(sp)
ffffffffc0201e0c:	fe0d1ae3          	bnez	s10,ffffffffc0201e00 <vprintfmt+0x328>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201e10:	00074783          	lbu	a5,0(a4)
ffffffffc0201e14:	0007851b          	sext.w	a0,a5
ffffffffc0201e18:	ec0780e3          	beqz	a5,ffffffffc0201cd8 <vprintfmt+0x200>
ffffffffc0201e1c:	5dfd                	li	s11,-1
ffffffffc0201e1e:	b561                	j	ffffffffc0201ca6 <vprintfmt+0x1ce>

ffffffffc0201e20 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201e20:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201e22:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201e26:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201e28:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201e2a:	ec06                	sd	ra,24(sp)
ffffffffc0201e2c:	f83a                	sd	a4,48(sp)
ffffffffc0201e2e:	fc3e                	sd	a5,56(sp)
ffffffffc0201e30:	e0c2                	sd	a6,64(sp)
ffffffffc0201e32:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201e34:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201e36:	ca3ff0ef          	jal	ffffffffc0201ad8 <vprintfmt>
}
ffffffffc0201e3a:	60e2                	ld	ra,24(sp)
ffffffffc0201e3c:	6161                	addi	sp,sp,80
ffffffffc0201e3e:	8082                	ret

ffffffffc0201e40 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201e40:	00005717          	auipc	a4,0x5
ffffffffc0201e44:	1d073703          	ld	a4,464(a4) # ffffffffc0207010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201e48:	4781                	li	a5,0
ffffffffc0201e4a:	88ba                	mv	a7,a4
ffffffffc0201e4c:	852a                	mv	a0,a0
ffffffffc0201e4e:	85be                	mv	a1,a5
ffffffffc0201e50:	863e                	mv	a2,a5
ffffffffc0201e52:	00000073          	ecall
ffffffffc0201e56:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201e58:	8082                	ret

ffffffffc0201e5a <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201e5a:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201e5e:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201e60:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201e62:	cb81                	beqz	a5,ffffffffc0201e72 <strlen+0x18>
        cnt ++;
ffffffffc0201e64:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201e66:	00a707b3          	add	a5,a4,a0
ffffffffc0201e6a:	0007c783          	lbu	a5,0(a5)
ffffffffc0201e6e:	fbfd                	bnez	a5,ffffffffc0201e64 <strlen+0xa>
ffffffffc0201e70:	8082                	ret
    }
    return cnt;
}
ffffffffc0201e72:	8082                	ret

ffffffffc0201e74 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201e74:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201e76:	e589                	bnez	a1,ffffffffc0201e80 <strnlen+0xc>
ffffffffc0201e78:	a811                	j	ffffffffc0201e8c <strnlen+0x18>
        cnt ++;
ffffffffc0201e7a:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201e7c:	00f58863          	beq	a1,a5,ffffffffc0201e8c <strnlen+0x18>
ffffffffc0201e80:	00f50733          	add	a4,a0,a5
ffffffffc0201e84:	00074703          	lbu	a4,0(a4)
ffffffffc0201e88:	fb6d                	bnez	a4,ffffffffc0201e7a <strnlen+0x6>
ffffffffc0201e8a:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201e8c:	852e                	mv	a0,a1
ffffffffc0201e8e:	8082                	ret

ffffffffc0201e90 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201e90:	00054783          	lbu	a5,0(a0)
ffffffffc0201e94:	e791                	bnez	a5,ffffffffc0201ea0 <strcmp+0x10>
ffffffffc0201e96:	a02d                	j	ffffffffc0201ec0 <strcmp+0x30>
ffffffffc0201e98:	00054783          	lbu	a5,0(a0)
ffffffffc0201e9c:	cf89                	beqz	a5,ffffffffc0201eb6 <strcmp+0x26>
ffffffffc0201e9e:	85b6                	mv	a1,a3
ffffffffc0201ea0:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc0201ea4:	0505                	addi	a0,a0,1
ffffffffc0201ea6:	00158693          	addi	a3,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201eaa:	fef707e3          	beq	a4,a5,ffffffffc0201e98 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201eae:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201eb2:	9d19                	subw	a0,a0,a4
ffffffffc0201eb4:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201eb6:	0015c703          	lbu	a4,1(a1)
ffffffffc0201eba:	4501                	li	a0,0
}
ffffffffc0201ebc:	9d19                	subw	a0,a0,a4
ffffffffc0201ebe:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201ec0:	0005c703          	lbu	a4,0(a1)
ffffffffc0201ec4:	4501                	li	a0,0
ffffffffc0201ec6:	b7f5                	j	ffffffffc0201eb2 <strcmp+0x22>

ffffffffc0201ec8 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201ec8:	ce01                	beqz	a2,ffffffffc0201ee0 <strncmp+0x18>
ffffffffc0201eca:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201ece:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201ed0:	cb91                	beqz	a5,ffffffffc0201ee4 <strncmp+0x1c>
ffffffffc0201ed2:	0005c703          	lbu	a4,0(a1)
ffffffffc0201ed6:	00f71763          	bne	a4,a5,ffffffffc0201ee4 <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc0201eda:	0505                	addi	a0,a0,1
ffffffffc0201edc:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201ede:	f675                	bnez	a2,ffffffffc0201eca <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201ee0:	4501                	li	a0,0
ffffffffc0201ee2:	8082                	ret
ffffffffc0201ee4:	00054503          	lbu	a0,0(a0)
ffffffffc0201ee8:	0005c783          	lbu	a5,0(a1)
ffffffffc0201eec:	9d1d                	subw	a0,a0,a5
}
ffffffffc0201eee:	8082                	ret

ffffffffc0201ef0 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201ef0:	ca01                	beqz	a2,ffffffffc0201f00 <memset+0x10>
ffffffffc0201ef2:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201ef4:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201ef6:	0785                	addi	a5,a5,1
ffffffffc0201ef8:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201efc:	fef61de3          	bne	a2,a5,ffffffffc0201ef6 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201f00:	8082                	ret
