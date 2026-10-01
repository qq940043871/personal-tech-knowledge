# 第 8 章：设备驱动程序

## 8.1 驱动程序架构

```
用户程序
    │ read/write 设备文件
    ▼
VFS 层（/dev/keyboard, /dev/hda）
    │ 调用设备节点的 read/write 函数
    ▼
驱动程序层
    ├── 键盘驱动（PS/2）
    ├── ATA 磁盘驱动
    └── VGA 显示驱动
    │
    ▼
硬件（I/O 端口操作）
```

---

## 8.2 VGA 文字模式驱动（完整版）

VGA 文字模式：80×25 字符，每字符 2 字节（字符 + 属性）

**文件：`kernel/drivers/vga.h`**

```c
#ifndef _VGA_H
#define _VGA_H

#include <stdint.h>

/* 颜色定义 */
#define VGA_BLACK           0
#define VGA_BLUE            1
#define VGA_GREEN           2
#define VGA_CYAN            3
#define VGA_RED             4
#define VGA_MAGENTA         5
#define VGA_BROWN           6
#define VGA_LIGHT_GREY      7
#define VGA_DARK_GREY       8
#define VGA_LIGHT_BLUE      9
#define VGA_LIGHT_GREEN     10
#define VGA_LIGHT_CYAN      11
#define VGA_LIGHT_RED       12
#define VGA_LIGHT_MAGENTA   13
#define VGA_LIGHT_BROWN     14  /* Yellow */
#define VGA_WHITE           15

#define VGA_COLOR(fg, bg)   ((bg << 4) | fg)

void vga_init(void);
void vga_clear(void);
void vga_putchar(char c);
void vga_putchar_color(char c, uint8_t color);
void vga_puts(const char *str);
void vga_set_color(uint8_t color);
void vga_move_cursor(int x, int y);
void vga_get_cursor(int *x, int *y);

#endif
```

**文件：`kernel/drivers/vga.c`**

```c
#include "vga.h"
#include <stdint.h>

#define VGA_ADDR    0xB8000
#define VGA_W       80
#define VGA_H       25

/* 硬件光标 I/O 端口 */
#define VGA_CTRL_REG    0x3D4
#define VGA_DATA_REG    0x3D5
#define VGA_CURSOR_HI   0x0E
#define VGA_CURSOR_LO   0x0F

static volatile uint16_t *vga_buf = (uint16_t *)VGA_ADDR;
static int  cursor_x    = 0;
static int  cursor_y    = 0;
static uint8_t cur_color = VGA_COLOR(VGA_LIGHT_GREY, VGA_BLACK);

/* I/O 端口操作 */
static inline void outb(uint16_t port, uint8_t val) {
    __asm__ volatile("outb %%al, %%dx" : : "d"(port), "a"(val));
}
static inline uint8_t inb(uint16_t port) {
    uint8_t v;
    __asm__ volatile("inb %%dx, %%al" : "=a"(v) : "d"(port));
    return v;
}

/* 更新硬件光标位置 */
static void update_hw_cursor(void)
{
    uint16_t pos = cursor_y * VGA_W + cursor_x;
    outb(VGA_CTRL_REG, VGA_CURSOR_HI);
    outb(VGA_DATA_REG, (pos >> 8) & 0xFF);
    outb(VGA_CTRL_REG, VGA_CURSOR_LO);
    outb(VGA_DATA_REG, pos & 0xFF);
}

/* 滚动屏幕 */
static void scroll(void)
{
    /* 上移一行 */
    for (int i = 0; i < (VGA_H - 1) * VGA_W; i++) {
        vga_buf[i] = vga_buf[i + VGA_W];
    }
    /* 清空最后一行 */
    uint16_t blank = ' ' | ((uint16_t)cur_color << 8);
    for (int i = (VGA_H - 1) * VGA_W; i < VGA_H * VGA_W; i++) {
        vga_buf[i] = blank;
    }
}

void vga_clear(void)
{
    uint16_t blank = ' ' | ((uint16_t)cur_color << 8);
    for (int i = 0; i < VGA_W * VGA_H; i++) vga_buf[i] = blank;
    cursor_x = cursor_y = 0;
    update_hw_cursor();
}

void vga_set_color(uint8_t color) { cur_color = color; }

void vga_putchar_color(char c, uint8_t color)
{
    uint8_t saved = cur_color;
    cur_color = color;
    vga_putchar(c);
    cur_color = saved;
}

void vga_putchar(char c)
{
    if (c == '\n') {
        cursor_x = 0; cursor_y++;
    } else if (c == '\r') {
        cursor_x = 0;
    } else if (c == '\b') {
        if (cursor_x > 0) {
            cursor_x--;
            vga_buf[cursor_y * VGA_W + cursor_x] = ' ' | ((uint16_t)cur_color << 8);
        }
    } else if (c == '\t') {
        cursor_x = (cursor_x + 8) & ~7;
    } else {
        vga_buf[cursor_y * VGA_W + cursor_x] = (uint8_t)c | ((uint16_t)cur_color << 8);
        cursor_x++;
    }

    if (cursor_x >= VGA_W) { cursor_x = 0; cursor_y++; }
    if (cursor_y >= VGA_H) { scroll(); cursor_y = VGA_H - 1; }

    update_hw_cursor();
}

void vga_puts(const char *s)
{
    while (*s) vga_putchar(*s++);
}

void vga_move_cursor(int x, int y)
{
    cursor_x = x; cursor_y = y;
    update_hw_cursor();
}
```

---

## 8.3 PS/2 键盘驱动

**文件：`kernel/drivers/keyboard.c`**

```c
#include "keyboard.h"
#include "../interrupt/idt.h"
#include "../interrupt/pic.h"

/* PS/2 键盘 I/O 端口 */
#define KEYBOARD_DATA   0x60    /* 数据端口（读取扫描码） */
#define KEYBOARD_STATUS 0x64    /* 状态端口 */

/* 扫描码集合 1（QWERTY 布局）*/
static const char scancode_to_ascii[] = {
    0,   27,  '1', '2', '3', '4', '5', '6', '7', '8', /* 0x00-0x09 */
    '9', '0', '-', '=', '\b','\t','q', 'w', 'e', 'r', /* 0x0A-0x13 */
    't', 'y', 'u', 'i', 'o', 'p', '[', ']', '\n',0,   /* 0x14-0x1D */
    'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', /* 0x1E-0x27 */
    '\'','`', 0,   '\\','z', 'x', 'c', 'v', 'b', 'n', /* 0x28-0x31 */
    'm', ',', '.', '/', 0,   '*', 0,   ' ', 0,         /* 0x32-0x3A */
};

static const char scancode_to_ascii_shift[] = {
    0,   27,  '!', '@', '#', '$', '%', '^', '&', '*',
    '(', ')', '_', '+', '\b','\t','Q', 'W', 'E', 'R',
    'T', 'Y', 'U', 'I', 'O', 'P', '{', '}', '\n',0,
    'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':',
    '"', '~', 0,   '|', 'Z', 'X', 'C', 'V', 'B', 'N',
    'M', '<', '>', '?', 0,   '*', 0,   ' ', 0,
};

/* 循环缓冲区（键盘输入队列） */
#define KB_BUFFER_SIZE  256
static char     kb_buffer[KB_BUFFER_SIZE];
static uint32_t kb_head = 0;
static uint32_t kb_tail = 0;

/* 修饰键状态 */
static int shift_pressed  = 0;
static int ctrl_pressed   = 0;
static int alt_pressed    = 0;
static int caps_lock      = 0;

static inline uint8_t inb(uint16_t port) {
    uint8_t v;
    __asm__ volatile("inb %%dx, %%al" : "=a"(v) : "d"(port));
    return v;
}

/* 向键盘缓冲区写入一个字符 */
static void kb_buffer_put(char c)
{
    uint32_t next = (kb_head + 1) % KB_BUFFER_SIZE;
    if (next != kb_tail) {      /* 缓冲区未满 */
        kb_buffer[kb_head] = c;
        kb_head = next;
    }
}

/* 从键盘缓冲区读取一个字符（阻塞） */
char keyboard_getchar(void)
{
    while (kb_head == kb_tail) {
        __asm__ volatile("hlt");    /* 等待中断 */
    }
    char c = kb_buffer[kb_tail];
    kb_tail = (kb_tail + 1) % KB_BUFFER_SIZE;
    return c;
}

/* 非阻塞读取（-1 表示没有字符） */
int keyboard_try_getchar(void)
{
    if (kb_head == kb_tail) return -1;
    char c = kb_buffer[kb_tail];
    kb_tail = (kb_tail + 1) % KB_BUFFER_SIZE;
    return (unsigned char)c;
}

/* 键盘中断处理函数（IRQ1 = INT 33） */
static void keyboard_handler(InterruptFrame *frame)
{
    (void)frame;
    uint8_t scancode = inb(KEYBOARD_DATA);

    /* 按键释放（扫描码 >= 0x80） */
    if (scancode & 0x80) {
        uint8_t key = scancode & 0x7F;
        if (key == 0x2A || key == 0x36) shift_pressed = 0; /* Shift 松开 */
        if (key == 0x1D) ctrl_pressed  = 0; /* Ctrl 松开 */
        if (key == 0x38) alt_pressed   = 0; /* Alt 松开 */
    } else {
        /* 按键按下 */
        if (scancode == 0x2A || scancode == 0x36) { shift_pressed = 1; }
        else if (scancode == 0x1D) { ctrl_pressed  = 1; }
        else if (scancode == 0x38) { alt_pressed   = 1; }
        else if (scancode == 0x3A) { caps_lock ^= 1; }  /* Caps Lock 切换 */
        else if (scancode < sizeof(scancode_to_ascii)) {
            char c;
            int  use_shift = shift_pressed ^ caps_lock;

            if (use_shift && scancode_to_ascii_shift[scancode]) {
                c = scancode_to_ascii_shift[scancode];
            } else {
                c = scancode_to_ascii[scancode];
            }

            if (c) {
                kb_buffer_put(c);
            }
        }
    }

    pic_send_eoi(1);    /* 发送 EOI，告诉 PIC IRQ1 已处理 */
}

void keyboard_init(void)
{
    register_interrupt_handler(33, keyboard_handler);
    pic_enable_irq(1);
    kprintf("[Keyboard] PS/2 keyboard driver initialized\n");
}
```

---

## 8.4 ATA 磁盘驱动（PIO 模式）

**文件：`kernel/drivers/disk.c`**

```c
#include "disk.h"
#include "../main.h"
#include <string.h>

/* ATA 主通道 I/O 端口 */
#define ATA_PRIMARY_DATA        0x1F0
#define ATA_PRIMARY_ERROR       0x1F1
#define ATA_PRIMARY_SECCOUNT    0x1F2
#define ATA_PRIMARY_LBA_LO      0x1F3
#define ATA_PRIMARY_LBA_MID     0x1F4
#define ATA_PRIMARY_LBA_HI      0x1F5
#define ATA_PRIMARY_DRIVE       0x1F6
#define ATA_PRIMARY_STATUS      0x1F7   /* 读 = 状态，写 = 命令 */
#define ATA_PRIMARY_CMD         0x1F7

/* ATA 状态位 */
#define ATA_SR_BSY  0x80    /* 忙 */
#define ATA_SR_RDY  0x40    /* 就绪 */
#define ATA_SR_DRQ  0x08    /* 数据请求 */
#define ATA_SR_ERR  0x01    /* 错误 */

/* ATA 命令 */
#define ATA_CMD_READ_PIO    0x20
#define ATA_CMD_WRITE_PIO   0x30
#define ATA_CMD_IDENTIFY    0xEC

static inline void outb(uint16_t p, uint8_t v) {
    __asm__ volatile("outb %%al, %%dx" : : "d"(p), "a"(v));
}
static inline uint8_t inb(uint16_t p) {
    uint8_t v;
    __asm__ volatile("inb %%dx, %%al" : "=a"(v) : "d"(p));
    return v;
}
static inline uint16_t inw(uint16_t p) {
    uint16_t v;
    __asm__ volatile("inw %%dx, %%ax" : "=a"(v) : "d"(p));
    return v;
}
static inline void outw(uint16_t p, uint16_t v) {
    __asm__ volatile("outw %%ax, %%dx" : : "d"(p), "a"(v));
}

/* 等待硬盘不忙 */
static void ata_wait_ready(void)
{
    int timeout = 100000;
    while ((inb(ATA_PRIMARY_STATUS) & ATA_SR_BSY) && timeout-- > 0);
}

/* 等待数据就绪 */
static int ata_wait_drq(void)
{
    int timeout = 100000;
    while (timeout-- > 0) {
        uint8_t status = inb(ATA_PRIMARY_STATUS);
        if (status & ATA_SR_ERR) return -1;
        if (status & ATA_SR_DRQ) return 0;
    }
    return -1;
}

/*------------------------------------------------------------
 * 读取若干扇区（LBA 28 位寻址，PIO 模式）
 *------------------------------------------------------------*/
int disk_read_sectors(uint32_t lba, uint8_t count, uint8_t *buf)
{
    ata_wait_ready();

    /* 选择硬盘（主盘）并设置 LBA 高 4 位 */
    outb(ATA_PRIMARY_DRIVE,   0xE0 | ((lba >> 24) & 0x0F));
    outb(ATA_PRIMARY_ERROR,   0x00);            /* 特性/错误（写 0） */
    outb(ATA_PRIMARY_SECCOUNT,count);           /* 扇区数 */
    outb(ATA_PRIMARY_LBA_LO,  (lba) & 0xFF);
    outb(ATA_PRIMARY_LBA_MID, (lba >> 8) & 0xFF);
    outb(ATA_PRIMARY_LBA_HI,  (lba >> 16) & 0xFF);
    outb(ATA_PRIMARY_CMD,     ATA_CMD_READ_PIO);/* 发送读取命令 */

    /* 逐扇区读取 */
    for (int s = 0; s < count; s++) {
        if (ata_wait_drq() < 0) {
            kprintf("[Disk] Error reading sector %d\n", lba + s);
            return -1;
        }
        /* 每扇区 256 个 16 位字 */
        for (int i = 0; i < 256; i++) {
            uint16_t word = inw(ATA_PRIMARY_DATA);
            buf[(s * 512) + (i * 2)]     = word & 0xFF;
            buf[(s * 512) + (i * 2) + 1] = (word >> 8) & 0xFF;
        }
    }
    return 0;
}

/*------------------------------------------------------------
 * 写入若干扇区
 *------------------------------------------------------------*/
int disk_write_sectors(uint32_t lba, uint8_t count, const uint8_t *buf)
{
    ata_wait_ready();

    outb(ATA_PRIMARY_DRIVE,    0xE0 | ((lba >> 24) & 0x0F));
    outb(ATA_PRIMARY_ERROR,    0x00);
    outb(ATA_PRIMARY_SECCOUNT, count);
    outb(ATA_PRIMARY_LBA_LO,   (lba) & 0xFF);
    outb(ATA_PRIMARY_LBA_MID,  (lba >> 8) & 0xFF);
    outb(ATA_PRIMARY_LBA_HI,   (lba >> 16) & 0xFF);
    outb(ATA_PRIMARY_CMD,      ATA_CMD_WRITE_PIO);

    for (int s = 0; s < count; s++) {
        if (ata_wait_drq() < 0) return -1;
        for (int i = 0; i < 256; i++) {
            uint16_t word = buf[(s * 512) + (i * 2)] |
                           ((uint16_t)buf[(s * 512) + (i * 2) + 1] << 8);
            outw(ATA_PRIMARY_DATA, word);
        }
    }
    /* 刷新缓存 */
    outb(ATA_PRIMARY_CMD, 0xE7);
    ata_wait_ready();
    return 0;
}

void disk_init(void)
{
    /* 发送 IDENTIFY 命令检测硬盘 */
    outb(ATA_PRIMARY_DRIVE, 0xA0);
    outb(ATA_PRIMARY_CMD,   ATA_CMD_IDENTIFY);

    if (inb(ATA_PRIMARY_STATUS) == 0) {
        kprintf("[Disk] No ATA drive detected!\n");
        return;
    }

    if (ata_wait_drq() < 0) {
        kprintf("[Disk] IDENTIFY failed!\n");
        return;
    }

    uint16_t identify[256];
    for (int i = 0; i < 256; i++) {
        identify[i] = inw(ATA_PRIMARY_DATA);
    }

    /* 读取型号字符串（字节交换） */
    char model[41] = {0};
    for (int i = 0; i < 20; i++) {
        model[i * 2]     = (identify[27 + i] >> 8) & 0xFF;
        model[i * 2 + 1] = identify[27 + i] & 0xFF;
    }

    kprintf("[Disk] ATA drive: %s\n", model);
    kprintf("[Disk] PIO mode driver ready\n");
}
```

---

## 8.5 章节小结

本章实现了：
- [x] VGA 文字模式完整驱动（含硬件光标、滚屏、颜色）
- [x] PS/2 键盘驱动（扫描码解析、缓冲队列、修饰键）
- [x] ATA 磁盘驱动（LBA 寻址、PIO 读写）

## 🏠 课后作业

1. 为 VGA 驱动添加 `printf` 风格的 `kprintf`（支持 `%d` `%x` `%s` `%c`）
2. 为键盘驱动添加行缓冲模式（按下回车才将一行输入提交给程序）
3. 将 ATA 驱动升级为 DMA 模式（通过 PCI 总线配置 BMIDE 控制器）

---

**上一章** ← [第 7 章：文件系统](./07_FileSystem.md)

**下一章** → [第 9 章：Shell](./09_Shell.md)
