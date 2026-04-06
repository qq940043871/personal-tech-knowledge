# 第 5 章：中断与异常处理

## 5.1 中断系统概述

```
中断类型：
┌─────────────────────────────────────────────────────┐
│ 硬件中断（IRQ）                                      │
│   来自外设（键盘、定时器、磁盘等）                    │
│   通过 PIC（可编程中断控制器）路由到 CPU              │
├─────────────────────────────────────────────────────┤
│ 软件中断（INT n）                                    │
│   由程序主动调用（INT 0x80 = Linux 系统调用）         │
├─────────────────────────────────────────────────────┤
│ CPU 异常（Exception）                               │
│   由 CPU 检测到的错误（除零、缺页、段错误等）          │
└─────────────────────────────────────────────────────┘

重要中断向量号：
  0x00 - 除法错误 (#DE)
  0x06 - 无效操作码 (#UD)
  0x08 - 双重错误 (#DF)
  0x0D - 通用保护错误 (#GP)  ← 非法内存访问
  0x0E - 缺页错误 (#PF)     ← 分页相关
  0x20 - PIC 定时器 (IRQ0)
  0x21 - PS/2 键盘 (IRQ1)
  0x80 - 系统调用（自定义）
```

---

## 5.2 中断描述符表（IDT）

IDT 是一个包含 256 个条目的表，每个条目描述了对应中断号的处理函数地址。

### IDT 条目结构

```
IDT 门描述符（8 字节）：
63          48 47 46-45 44 43-40 39-32 31         16 15        0
┌─────────────┬─┬────┬──┬──────┬──────┬─────────────┬──────────┐
│ 偏移 31-16  │P│DPL │0 │ 类型 │ 保留 │  段选择子    │偏移 15-0 │
└─────────────┴─┴────┴──┴──────┴──────┴─────────────┴──────────┘

P   = 存在位（1 = 有效）
DPL = 描述符特权级（0 = 内核，3 = 用户可调用）
类型（中断门）= 0b1110（0xE）
```

### 实现 IDT

**文件：`kernel/interrupt/idt.h`**

```c
#ifndef _IDT_H
#define _IDT_H

#include <stdint.h>

#define IDT_ENTRIES 256

/* 中断时 CPU 自动压栈的寄存器状态 */
typedef struct {
    /* 通用寄存器（由 isr_stub 压栈） */
    uint32_t edi, esi, ebp, esp_dummy;
    uint32_t ebx, edx, ecx, eax;
    /* 中断号和错误码（由我们手动压栈） */
    uint32_t int_no, error_code;
    /* CPU 自动压栈 */
    uint32_t eip, cs, eflags;
    /* 特权级变化时 CPU 额外压栈 */
    uint32_t user_esp, user_ss;
} InterruptFrame;

/* IDT 条目结构 */
typedef struct {
    uint16_t offset_low;    /* 处理函数地址低 16 位 */
    uint16_t selector;      /* 代码段选择子 */
    uint8_t  zero;          /* 保留，必须为 0 */
    uint8_t  type_attr;     /* 类型和属性 */
    uint16_t offset_high;   /* 处理函数地址高 16 位 */
} __attribute__((packed)) IDTEntry;

/* IDTR 寄存器结构 */
typedef struct {
    uint16_t limit;         /* IDT 大小 - 1 */
    uint32_t base;          /* IDT 物理基地址 */
} __attribute__((packed)) IDTR;

/* 初始化 IDT */
void idt_init(void);

/* 设置一个 IDT 条目 */
void idt_set_gate(uint8_t num, uint32_t handler, uint16_t selector, uint8_t flags);

/* 注册中断处理函数 */
typedef void (*interrupt_handler_t)(InterruptFrame *frame);
void register_interrupt_handler(uint8_t num, interrupt_handler_t handler);

#endif
```

**文件：`kernel/interrupt/idt.c`**

```c
#include "idt.h"
#include "../main.h"

static IDTEntry  idt_entries[IDT_ENTRIES];
static IDTR      idtr;
static interrupt_handler_t interrupt_handlers[IDT_ENTRIES];

/* 外部声明（在 isr.asm 中定义） */
extern void isr0(void);  extern void isr1(void);  /* ... */
extern void irq0(void);  extern void irq1(void);  /* ... */

/*------------------------------------------------------------
 * 设置 IDT 条目
 *------------------------------------------------------------*/
void idt_set_gate(uint8_t num, uint32_t handler,
                  uint16_t selector, uint8_t flags)
{
    idt_entries[num].offset_low  = handler & 0xFFFF;
    idt_entries[num].offset_high = (handler >> 16) & 0xFFFF;
    idt_entries[num].selector    = selector;
    idt_entries[num].zero        = 0;
    idt_entries[num].type_attr   = flags;
}

/*------------------------------------------------------------
 * 注册中断处理函数
 *------------------------------------------------------------*/
void register_interrupt_handler(uint8_t num, interrupt_handler_t handler)
{
    interrupt_handlers[num] = handler;
}

/*------------------------------------------------------------
 * 初始化 IDT
 *------------------------------------------------------------*/
void idt_init(void)
{
    /* 清零所有处理函数 */
    for (int i = 0; i < IDT_ENTRIES; i++) {
        interrupt_handlers[i] = NULL;
    }

    /* 设置 CPU 异常处理（0x00 ~ 0x1F） */
    /* 0xEE = 中断门，DPL=0（内核），Present=1 */
    idt_set_gate(0,  (uint32_t)isr0,  0x0008, 0x8E); /* 除法错误 */
    idt_set_gate(1,  (uint32_t)isr1,  0x0008, 0x8E); /* 调试 */
    /* ... 其他异常 ... */
    idt_set_gate(13, (uint32_t)isr13, 0x0008, 0x8E); /* #GP */
    idt_set_gate(14, (uint32_t)isr14, 0x0008, 0x8E); /* #PF */

    /* 设置 PIC 硬件中断（0x20 ~ 0x2F） */
    idt_set_gate(32, (uint32_t)irq0,  0x0008, 0x8E); /* 定时器 */
    idt_set_gate(33, (uint32_t)irq1,  0x0008, 0x8E); /* 键盘 */

    /* 系统调用（用户可调用，DPL=3） */
    idt_set_gate(0x80, (uint32_t)isr128, 0x0008, 0xEE);

    /* 加载 IDT */
    idtr.limit = sizeof(IDTEntry) * IDT_ENTRIES - 1;
    idtr.base  = (uint32_t)&idt_entries;

    __asm__ volatile("lidt (%0)" : : "r"(&idtr));

    kprintf("[IDT] Initialized with %d entries\n", IDT_ENTRIES);
}

/*------------------------------------------------------------
 * 统一中断分发函数（被 isr.asm 调用）
 *------------------------------------------------------------*/
void interrupt_dispatch(InterruptFrame *frame)
{
    uint8_t num = (uint8_t)frame->int_no;

    if (interrupt_handlers[num]) {
        interrupt_handlers[num](frame);
    } else {
        /* 未处理的异常：打印信息并崩溃 */
        if (num < 32) {
            kprintf("\n[EXCEPTION] #%d at EIP=0x", num);
            kprint_hex(frame->eip);
            kprintf(", err=0x");
            kprint_hex(frame->error_code);
            kprintf("\n");
            kernel_panic("Unhandled CPU exception");
        }
    }
}
```

---

## 5.3 中断服务例程汇编存根

**文件：`kernel/interrupt/isr.asm`**

```nasm
;=============================================================
; isr.asm - 中断服务例程汇编存根
; 
; 每个中断号都需要一个唯一的入口，
; 因为 CPU 对有些异常会压入错误码，有些不会。
; 我们统一处理：没有错误码的压入 0。
;=============================================================

[BITS 32]

[EXTERN interrupt_dispatch]     ; C 语言分发函数

; 宏：不带错误码的 ISR 存根
%macro ISR_NOERR 1
    [GLOBAL isr%1]
    isr%1:
        cli
        push dword 0        ; 压入假错误码（保持栈帧一致）
        push dword %1       ; 压入中断号
        jmp isr_common
%endmacro

; 宏：带错误码的 ISR 存根
%macro ISR_ERR 1
    [GLOBAL isr%1]
    isr%1:
        cli
        ; CPU 已压入错误码，不需要再压
        push dword %1       ; 压入中断号
        jmp isr_common
%endmacro

; 宏：IRQ（硬件中断）存根
%macro IRQ 2
    [GLOBAL irq%1]
    irq%1:
        cli
        push dword 0        ; 假错误码
        push dword %2       ; 中断号（%2 = IRQ号 + 32）
        jmp isr_common
%endmacro

; CPU 异常（0 ~ 31）
ISR_NOERR 0     ; #DE 除法错误
ISR_NOERR 1     ; #DB 调试
ISR_NOERR 2     ; NMI 不可屏蔽中断
ISR_NOERR 3     ; #BP 断点
ISR_NOERR 4     ; #OF 溢出
ISR_NOERR 5     ; #BR 越界
ISR_NOERR 6     ; #UD 无效操作码
ISR_NOERR 7     ; #NM 设备不可用
ISR_ERR   8     ; #DF 双重错误（有错误码）
ISR_NOERR 9     ; 协处理器段溢出（过时）
ISR_ERR   10    ; #TS 无效 TSS
ISR_ERR   11    ; #NP 段不存在
ISR_ERR   12    ; #SS 栈段错误
ISR_ERR   13    ; #GP 通用保护错误
ISR_ERR   14    ; #PF 缺页错误
ISR_NOERR 15    ; 保留
ISR_NOERR 16    ; #MF x87 浮点错误
ISR_ERR   17    ; #AC 对齐检查
ISR_NOERR 18    ; #MC 机器检查
ISR_NOERR 19    ; #XF SIMD 浮点错误

; 用户系统调用
ISR_NOERR 128   ; INT 0x80

; 硬件中断（IRQ0 ~ IRQ15 映射到 0x20 ~ 0x2F）
IRQ 0, 32       ; PIT 定时器
IRQ 1, 33       ; PS/2 键盘
IRQ 2, 34       ; 串联 PIC
IRQ 3, 35       ; COM2
IRQ 4, 36       ; COM1
IRQ 5, 37       ; LPT2
IRQ 6, 38       ; 软盘
IRQ 7, 39       ; LPT1
IRQ 8, 40       ; 实时时钟
IRQ 12, 44      ; PS/2 鼠标
IRQ 14, 46      ; ATA 主通道
IRQ 15, 47      ; ATA 从通道

;-------------------------------------------------------------
; 公共中断处理代码
;-------------------------------------------------------------
isr_common:
    ; 保存所有通用寄存器（pushad 保存 EAX,ECX,EDX,EBX,ESP,EBP,ESI,EDI）
    pushad

    ; 保存数据段
    mov ax, ds
    push eax

    ; 切换到内核数据段
    mov ax, 0x10    ; 内核数据段选择子
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; 调用 C 语言分发函数
    ; 参数：InterruptFrame *frame = ESP（当前栈顶就是 InterruptFrame）
    push esp
    call interrupt_dispatch
    add esp, 4      ; 清理参数

    ; 恢复数据段
    pop eax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; 恢复通用寄存器
    popad

    ; 清理 int_no 和 error_code（我们压栈的两个 dword）
    add esp, 8

    ; 返回（恢复 EIP, CS, EFLAGS）
    iret
```

---

## 5.4 可编程中断控制器（PIC）初始化

x86 系统使用 8259A PIC 管理硬件中断。默认情况下，IRQ0~IRQ7 映射到 INT 0x08~0x0F，与 CPU 异常冲突，需要重新映射：

**文件：`kernel/interrupt/pic.c`**

```c
#include "pic.h"

/* 8259A PIC I/O 端口 */
#define PIC1_CMD    0x20    /* 主 PIC 命令端口 */
#define PIC1_DATA   0x21    /* 主 PIC 数据端口 */
#define PIC2_CMD    0xA0    /* 从 PIC 命令端口 */
#define PIC2_DATA   0xA1    /* 从 PIC 数据端口 */

#define PIC_EOI     0x20    /* End Of Interrupt（中断结束信号） */

/* 延迟：通过写一个无害的端口来产生小延迟 */
static inline void io_wait(void)
{
    __asm__ volatile("outb %%al, $0x80" : : "a"(0));
}

static inline void outb(uint16_t port, uint8_t val)
{
    __asm__ volatile("outb %%al, %%dx" : : "d"(port), "a"(val));
}

static inline uint8_t inb(uint16_t port)
{
    uint8_t val;
    __asm__ volatile("inb %%dx, %%al" : "=a"(val) : "d"(port));
    return val;
}

/*------------------------------------------------------------
 * 重新映射 PIC
 * IRQ0~7  → INT 0x20~0x27（主 PIC）
 * IRQ8~15 → INT 0x28~0x2F（从 PIC）
 *------------------------------------------------------------*/
void pic_init(void)
{
    /* 保存当前 IMR（中断屏蔽寄存器） */
    uint8_t mask1 = inb(PIC1_DATA);
    uint8_t mask2 = inb(PIC2_DATA);

    /* 初始化序列（ICW = Initialization Command Word） */

    /* ICW1：开始初始化，级联模式，需要 ICW4 */
    outb(PIC1_CMD, 0x11); io_wait();
    outb(PIC2_CMD, 0x11); io_wait();

    /* ICW2：设置中断向量偏移 */
    outb(PIC1_DATA, 0x20); io_wait();  /* 主 PIC IRQ0 → INT 32 (0x20) */
    outb(PIC2_DATA, 0x28); io_wait();  /* 从 PIC IRQ8 → INT 40 (0x28) */

    /* ICW3：设置级联 */
    outb(PIC1_DATA, 0x04); io_wait();  /* 主 PIC 的 IR2 连接从 PIC */
    outb(PIC2_DATA, 0x02); io_wait();  /* 从 PIC 连接到主 PIC 的 IR2 */

    /* ICW4：8086 模式 */
    outb(PIC1_DATA, 0x01); io_wait();
    outb(PIC2_DATA, 0x01); io_wait();

    /* 恢复 IMR（屏蔽寄存器） */
    outb(PIC1_DATA, mask1);
    outb(PIC2_DATA, mask2);

    kprintf("[PIC] Remapped. IRQ0-7 = INT 0x20-0x27\n");
}

/*------------------------------------------------------------
 * 发送 EOI（中断结束信号）
 * 每次处理完硬件中断后必须调用！
 *------------------------------------------------------------*/
void pic_send_eoi(uint8_t irq)
{
    if (irq >= 8) {
        outb(PIC2_CMD, PIC_EOI);    /* 如果是从 PIC 的中断，先通知从 PIC */
    }
    outb(PIC1_CMD, PIC_EOI);        /* 通知主 PIC */
}

/* 开启/关闭特定 IRQ */
void pic_enable_irq(uint8_t irq)
{
    uint16_t port = (irq < 8) ? PIC1_DATA : PIC2_DATA;
    uint8_t  bit  = (irq < 8) ? irq : (irq - 8);
    outb(port, inb(port) & ~(1 << bit));
}

void pic_disable_irq(uint8_t irq)
{
    uint16_t port = (irq < 8) ? PIC1_DATA : PIC2_DATA;
    uint8_t  bit  = (irq < 8) ? irq : (irq - 8);
    outb(port, inb(port) | (1 << bit));
}
```

---

## 5.5 PIT 定时器（时间片调度基础）

**文件：`kernel/interrupt/timer.c`**

```c
#include "timer.h"
#include "pic.h"
#include "idt.h"

static volatile uint64_t timer_ticks = 0;
static uint32_t          timer_frequency = 0;

/* 定时器 IRQ0 中断处理函数 */
static void timer_handler(InterruptFrame *frame)
{
    (void)frame;
    timer_ticks++;

    /* 每 100 个 tick 打印一次（调试用） */
    /* if (timer_ticks % 100 == 0) {
        kprintf("[Timer] Tick: %d\n", (int)timer_ticks);
    } */

    /* TODO 第6章：通知调度器切换任务 */
    /* scheduler_tick(); */

    pic_send_eoi(0);    /* 必须！告诉 PIC 中断已处理 */
}

/*------------------------------------------------------------
 * 初始化 PIT（可编程间隔定时器）
 * PIT 基准频率 = 1193182 Hz
 * 目标频率 = 100 Hz（每 10ms 触发一次）
 *------------------------------------------------------------*/
void timer_init(uint32_t frequency)
{
    timer_frequency = frequency;

    /* 计算分频值 */
    uint32_t divisor = 1193182 / frequency;

    /* PIT 控制字：通道0，低/高字节模式，方波模式 */
    outb(0x43, 0x36);

    /* 写入分频值（低字节在前） */
    outb(0x40, (uint8_t)(divisor & 0xFF));
    outb(0x40, (uint8_t)((divisor >> 8) & 0xFF));

    /* 注册定时器中断处理函数 */
    register_interrupt_handler(32, timer_handler);
    pic_enable_irq(0);

    kprintf("[Timer] PIT initialized at %d Hz\n", frequency);
}

uint64_t timer_get_ticks(void)
{
    return timer_ticks;
}

/* 忙等待指定毫秒数 */
void sleep_ms(uint32_t ms)
{
    uint64_t target = timer_ticks + (uint64_t)ms * timer_frequency / 1000;
    while (timer_ticks < target) {
        __asm__ volatile("hlt");
    }
}
```

---

## 5.6 在内核中集成中断系统

更新 `kernel/main.c`：

```c
void kernel_main(void)
{
    vga_clear();
    kprintf("=== MiniOS - Interrupt System ===\n\n");

    /* 内存初始化（第4章） */
    /* ... */

    /* 中断系统初始化 */
    idt_init();
    pic_init();
    timer_init(100);    /* 100 Hz，每 10ms 一次定时器中断 */

    /* 开启中断 */
    __asm__ volatile("sti");
    kprintf("[Kernel] Interrupts enabled.\n");

    /* 注册缺页处理 */
    register_interrupt_handler(14, page_fault_handler);

    kprintf("[Kernel] System ready! Waiting for interrupts...\n");

    /* 内核主循环 */
    while (1) {
        __asm__ volatile("hlt");    /* 等待中断 */
    }
}

/* 缺页处理函数 */
static void page_fault_handler(InterruptFrame *frame)
{
    uint32_t fault_addr;
    __asm__ volatile("mov %%cr2, %0" : "=r"(fault_addr));

    kprintf("\n[#PF] Page Fault at virtual address 0x");
    kprint_hex(fault_addr);
    kprintf("\n  EIP=0x");
    kprint_hex(frame->eip);
    kprintf(", error=0x");
    kprint_hex(frame->error_code);
    kprintf("\n");

    if (frame->error_code & 0x4) {
        kernel_panic("#PF: User mode access violation");
    } else {
        kernel_panic("#PF: Kernel mode page fault");
    }
}
```

---

## 5.7 章节小结

本章实现了：
- [x] IDT（中断描述符表）初始化
- [x] CPU 异常处理（含通用保护错误、缺页错误）
- [x] PIC 重新映射（避免与 CPU 异常冲突）
- [x] PIT 定时器初始化（100 Hz）
- [x] 完整的中断处理流程（汇编存根 + C 分发器）

## 🏠 课后作业

1. 为所有 32 个 CPU 异常编写默认处理函数，打印异常名称
2. 实现 `enable_interrupts()` 和 `disable_interrupts()` 函数，并使用自旋锁保护临界区
3. 实现高精度定时器：用 `rdtsc` 指令（读取 CPU 周期计数器）实现微秒级精度

---

**上一章** ← [第 4 章：内存管理](./04_Memory.md)

**下一章** → [第 6 章：进程管理与任务调度](./06_Process.md)
