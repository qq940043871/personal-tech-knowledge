# 第 3 章：内核入口与 C 语言环境

## 3.1 从汇编跳转到 C

在保护模式建立后，我们需要创建一个可以运行 C 代码的环境。这需要：

1. **设置好栈**（C 函数调用依赖栈）
2. **清零 BSS 段**（未初始化的全局变量必须为 0）
3. **调用内核主函数 `kernel_main()`**

### 调用约定（x86 cdecl）

```
函数调用时：
1. 调用者将参数从右到左依次压栈
2. 调用 call 指令（自动压入返回地址）
3. 被调用者保存 EBP，设置新 EBP
4. 函数执行完毕，恢复 EBP，执行 ret

栈帧结构：
高地址
┌──────────┐
│  参数 N  │
├──────────┤
│  参数 1  │
├──────────┤
│ 返回地址  │ ← call 指令压入
├──────────┤
│  旧 EBP  │ ← push ebp 保存
├──────────┤  ← EBP 指向这里（新帧基址）
│  局部变量 │
├──────────┤  ← ESP 指向这里（栈顶）
低地址
```

---

## 3.2 内核汇编入口

**文件：`kernel/kernel_entry.asm`**

```nasm
;=============================================================
; kernel_entry.asm - 内核汇编入口
; 
; 由 Loader 跳转到这里（地址 0x100000）
; 功能：初始化 C 运行环境，然后调用 kernel_main()
;=============================================================

[BITS 32]
[EXTERN kernel_main]    ; 声明外部 C 函数
[EXTERN __bss_start]    ; BSS 段起始（由链接脚本提供）
[EXTERN __bss_end]      ; BSS 段结束

[GLOBAL _start]         ; 导出入口符号

section .text

_start:
    ; 确保段寄存器正确（Loader 已设置好，但保险起见再设一次）
    mov ax, 0x10        ; 内核数据段选择子
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; 设置内核栈（放在安全区域）
    mov esp, KERNEL_STACK_TOP

    ; 清零 BSS 段（未初始化全局变量必须为 0）
    call zero_bss

    ; 调用 C 语言内核主函数
    call kernel_main

    ; 如果 kernel_main 意外返回，挂起 CPU
.hang:
    hlt
    jmp .hang

;-------------------------------------------------------------
; 清零 BSS 段
;-------------------------------------------------------------
zero_bss:
    mov edi, __bss_start
    mov ecx, __bss_end
    sub ecx, edi        ; 计算 BSS 大小（字节数）
    xor al, al          ; 填充值 = 0
    rep stosb           ; 重复 STORE Byte
    ret

;-------------------------------------------------------------
; 常量定义
;-------------------------------------------------------------
KERNEL_STACK_TOP equ 0x200000   ; 内核栈顶（2MB 处，向下增长）
```

---

## 3.3 内核链接脚本

链接脚本告诉链接器如何将各个 .o 文件组合成最终的 kernel.bin：

**文件：`kernel/kernel.ld`**

```ld
/* kernel.ld - 内核链接脚本 */

/* 入口点 */
ENTRY(_start)

SECTIONS
{
    /* 内核加载到 1MB 地址处 */
    . = 0x100000;

    /* 代码段 */
    .text :
    {
        *(.text)        /* 所有目标文件的 .text 节 */
    }

    /* 只读数据段 */
    .rodata :
    {
        *(.rodata)
        *(.rodata*)
    }

    /* 数据段（已初始化的全局变量） */
    .data :
    {
        *(.data)
    }

    /* BSS 段（未初始化的全局变量） */
    .bss :
    {
        __bss_start = .;    /* 导出 BSS 起始地址 */
        *(.bss)
        *(COMMON)           /* 未初始化的公共变量 */
        __bss_end = .;      /* 导出 BSS 结束地址 */
    }
}
```

---

## 3.4 第一个内核主函数

**文件：`kernel/main.c`**

```c
/*============================================================
 * main.c - 内核主函数
 * 
 * 这是内核的 C 语言入口点
 *============================================================*/

/* VGA 文字模式相关常量 */
#define VGA_ADDRESS    0xB8000      /* VGA 显存基地址 */
#define VGA_WIDTH      80           /* 文字列数 */
#define VGA_HEIGHT     25           /* 文字行数 */
#define VGA_WHITE_ON_BLACK  0x0F    /* 白字黑底属性 */

/* 全局变量：当前光标位置 */
static int cursor_x = 0;
static int cursor_y = 0;

/*------------------------------------------------------------
 * VGA 基础操作
 *------------------------------------------------------------*/

/* 在指定位置写入一个字符 */
static void vga_put_char_at(char c, uint8_t color, int x, int y)
{
    /* VGA 显存每个字符占 2 字节：[字符][属性] */
    volatile uint16_t *vga = (uint16_t *)VGA_ADDRESS;
    vga[y * VGA_WIDTH + x] = (uint16_t)c | ((uint16_t)color << 8);
}

/* 滚动屏幕（当内容超出 25 行时） */
static void vga_scroll(void)
{
    volatile uint16_t *vga = (uint16_t *)VGA_ADDRESS;
    
    /* 将第 1~24 行复制到第 0~23 行 */
    for (int i = 0; i < (VGA_HEIGHT - 1) * VGA_WIDTH; i++) {
        vga[i] = vga[i + VGA_WIDTH];
    }
    
    /* 清空最后一行 */
    for (int i = (VGA_HEIGHT - 1) * VGA_WIDTH; i < VGA_HEIGHT * VGA_WIDTH; i++) {
        vga[i] = ' ' | (VGA_WHITE_ON_BLACK << 8);
    }
}

/* 清屏 */
void vga_clear(void)
{
    volatile uint16_t *vga = (uint16_t *)VGA_ADDRESS;
    for (int i = 0; i < VGA_WIDTH * VGA_HEIGHT; i++) {
        vga[i] = ' ' | (VGA_WHITE_ON_BLACK << 8);
    }
    cursor_x = 0;
    cursor_y = 0;
}

/* 打印单个字符 */
void vga_putchar(char c)
{
    if (c == '\n') {
        /* 换行 */
        cursor_x = 0;
        cursor_y++;
    } else if (c == '\r') {
        cursor_x = 0;
    } else if (c == '\b') {
        /* 退格 */
        if (cursor_x > 0) cursor_x--;
    } else if (c == '\t') {
        /* Tab：移到下一个 8 对齐位置 */
        cursor_x = (cursor_x + 8) & ~7;
    } else {
        vga_put_char_at(c, VGA_WHITE_ON_BLACK, cursor_x, cursor_y);
        cursor_x++;
    }
    
    /* 处理行溢出 */
    if (cursor_x >= VGA_WIDTH) {
        cursor_x = 0;
        cursor_y++;
    }
    
    /* 处理页溢出：滚动屏幕 */
    if (cursor_y >= VGA_HEIGHT) {
        vga_scroll();
        cursor_y = VGA_HEIGHT - 1;
    }
}

/* 打印字符串 */
void kprintf(const char *str)
{
    while (*str) {
        vga_putchar(*str++);
    }
}

/* 打印十进制整数 */
void kprint_int(int n)
{
    if (n < 0) {
        vga_putchar('-');
        n = -n;
    }
    if (n >= 10) {
        kprint_int(n / 10);
    }
    vga_putchar('0' + n % 10);
}

/* 打印十六进制 */
void kprint_hex(uint32_t n)
{
    const char hex_chars[] = "0123456789ABCDEF";
    kprintf("0x");
    for (int i = 28; i >= 0; i -= 4) {
        vga_putchar(hex_chars[(n >> i) & 0xF]);
    }
}

/*------------------------------------------------------------
 * 内核主函数
 *------------------------------------------------------------*/
void kernel_main(void)
{
    /* 清屏 */
    vga_clear();

    /* 打印欢迎信息 */
    kprintf("===========================================\n");
    kprintf("  MiniOS Kernel - Starting up...\n");
    kprintf("===========================================\n\n");
    
    kprintf("[Kernel] Protected mode: 32-bit\n");
    kprintf("[Kernel] Kernel loaded at: ");
    kprint_hex(0x100000);
    kprintf("\n");
    
    kprintf("[Kernel] VGA text mode: 80x25\n");
    kprintf("[Kernel] Kernel is alive!\n\n");

    /* 第4章：初始化内存管理 */
    /* memory_init(); */
    
    /* 第5章：初始化中断 */
    /* interrupt_init(); */
    
    /* 第6章：初始化进程调度 */
    /* scheduler_init(); */
    
    /* 第8章：初始化驱动 */
    /* keyboard_init(); */
    
    /* 第9章：启动 Shell */
    /* shell_run(); */

    kprintf("[Kernel] All systems initialized.\n");
    kprintf("[Kernel] Halting CPU (Shell not yet implemented).\n");

    /* 内核主循环（后续会替换为调度器） */
    while (1) {
        __asm__ volatile("hlt");
    }
}
```

---

## 3.5 自制简单的 stdint.h

因为内核不能使用标准库，需要自己定义基础类型：

**文件：`kernel/include/stdint.h`**

```c
#ifndef _STDINT_H
#define _STDINT_H

/* 固定宽度整数类型 */
typedef unsigned char       uint8_t;
typedef unsigned short      uint16_t;
typedef unsigned int        uint32_t;
typedef unsigned long long  uint64_t;

typedef signed char         int8_t;
typedef signed short        int16_t;
typedef signed int          int32_t;
typedef signed long long    int64_t;

/* 地址大小整数 */
typedef uint32_t    uintptr_t;
typedef int32_t     intptr_t;
typedef uint32_t    size_t;
typedef int32_t     ssize_t;

/* NULL 定义 */
#ifndef NULL
#define NULL ((void *)0)
#endif

/* 布尔类型 */
typedef uint8_t bool;
#define true  1
#define false 0

#endif /* _STDINT_H */
```

---

## 3.6 完整的 Makefile（含内核编译）

```makefile
# ============================================================
# MiniOS Makefile（含内核）
# ============================================================

NASM    = nasm
CC      = gcc
LD      = ld

# GCC 选项（裸机编译）
CFLAGS  = -m32 \
          -ffreestanding \       # 不假设有标准库
          -fno-stack-protector \ # 关闭栈保护（没有 __stack_chk_fail）
          -fno-builtin \         # 不使用内建函数
          -nostdlib \            # 不链接标准库
          -nostdinc \            # 不搜索标准头文件目录
          -I kernel/include \    # 自定义头文件目录
          -Wall -Wextra \
          -std=c11

LDFLAGS = -m elf_i386 \
          -T kernel/kernel.ld \  # 使用自定义链接脚本
          --oformat binary       # 输出原始二进制（不是 ELF）

IMG = disk.img

.PHONY: all run clean

all: $(IMG)

$(IMG): boot/boot.bin boot/loader.bin kernel/kernel.bin
	dd if=/dev/zero of=$(IMG) bs=1M count=8
	dd if=boot/boot.bin    of=$(IMG) conv=notrunc bs=512 seek=0
	dd if=boot/loader.bin  of=$(IMG) conv=notrunc bs=512 seek=2
	dd if=kernel/kernel.bin of=$(IMG) conv=notrunc bs=512 seek=6

boot/boot.bin: boot/boot.asm
	$(NASM) -f bin $< -o $@

boot/loader.bin: boot/loader.asm
	$(NASM) -f bin $< -o $@

# 内核编译：先编译各 .c/.asm 文件，再链接
KERNEL_OBJS = kernel/kernel_entry.o \
              kernel/main.o

kernel/kernel.bin: $(KERNEL_OBJS)
	$(LD) $(LDFLAGS) -o $@ $^

kernel/kernel_entry.o: kernel/kernel_entry.asm
	$(NASM) -f elf32 $< -o $@

kernel/main.o: kernel/main.c
	$(CC) $(CFLAGS) -c $< -o $@

run: $(IMG)
	qemu-system-i386 -drive file=$(IMG),format=raw \
	                 -m 32M -display gtk

clean:
	rm -f boot/*.bin kernel/*.o kernel/*.bin $(IMG)
```

---

## 3.7 内核调试技巧

### 使用 GDB 调试 C 代码

```bash
# 编译时加 -g 调试信息（链接时不用 --oformat binary，先生成 ELF）
gcc -m32 -g -ffreestanding ... -o kernel.elf kernel_entry.o main.o

# GDB 调试
gdb kernel.elf
(gdb) target remote localhost:1234  # 连接 QEMU
(gdb) break kernel_main             # 在 C 函数处设断点
(gdb) continue
(gdb) next                          # 单步执行 C 代码
(gdb) print cursor_x                # 查看变量值
(gdb) backtrace                     # 查看调用栈
```

### 内核 panic 函数

```c
/* 添加到 main.c：内核崩溃处理 */
void kernel_panic(const char *message)
{
    /* 用红色打印错误信息 */
    volatile uint16_t *vga = (uint16_t *)VGA_ADDRESS;
    vga_clear();
    
    /* 先打印 PANIC 标题（红色） */
    const char *title = "KERNEL PANIC: ";
    int pos = 0;
    while (*title) {
        vga[pos++] = (uint16_t)(*title++) | (0x4F << 8); /* 红底白字 */
    }
    
    /* 打印错误消息 */
    while (*message) {
        vga[pos++] = (uint16_t)(*message++) | (0x4F << 8);
    }
    
    /* 停机 */
    while (1) {
        __asm__ volatile("hlt");
    }
}
```

---

## 3.8 章节小结

本章实现了：
- [x] 内核汇编入口（kernel_entry.asm）
- [x] BSS 段清零
- [x] 链接脚本（控制内存布局）
- [x] 内核 C 主函数
- [x] VGA 文字输出函数
- [x] 基础类型定义（stdint.h）
- [x] 完整的 Makefile 构建系统

## 🏠 课后作业

1. 为 `kprintf` 添加格式化支持（`%d`, `%x`, `%s`）
2. 实现 `kmemset()` 和 `kmemcpy()` 函数
3. 在内核中打印出 E820 内存检测的结果（需要从 Loader 传递数据给内核）

---

**上一章** ← [第 2 章：保护模式](./02_ProtectedMode.md)

**下一章** → [第 4 章：内存管理](./04_Memory.md)
