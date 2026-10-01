# 第 2 章：进入保护模式

## 2.1 为什么需要保护模式？

| 特性 | 实模式 | 保护模式 |
|------|--------|----------|
| 最大寻址空间 | 1MB | 4GB |
| 内存保护 | 无 | 有（段权限 + 分页） |
| 多任务支持 | 无 | 有（任务状态段 TSS） |
| 特权级别 | 无 | Ring 0 ~ Ring 3 |
| 32 位操作 | 无 | 有 |

保护模式是现代操作系统的基础，只有进入保护模式，才能使用 4GB 内存、实现内存保护和多任务。

---

## 2.2 全局描述符表（GDT）

**GDT 是什么？**

在保护模式下，内存段不再用「段寄存器 × 16」来寻址，而是通过段寄存器中存放的**段选择子**来查询 GDT，从而获取段的基地址、大小和权限。

### GDT 表结构

```
GDT（全局描述符表）：
┌──────────────┐ 索引 0
│   空描述符   │  ← 第 0 项必须为全 0（规定）
├──────────────┤ 索引 1
│  代码段描述符 │  ← 内核代码段（Ring 0）
├──────────────┤ 索引 2
│  数据段描述符 │  ← 内核数据段（Ring 0）
├──────────────┤ 索引 3
│  ...         │
└──────────────┘
```

### 段描述符结构（8 字节）

```
63          56 55    52 51   48 47      40 39        16 15       0
┌─────────────┬────────┬───────┬──────────┬────────────┬──────────┐
│  基址 31-24 │  标志  │ 段限  │  访问字节 │  基址 23-0 │  段限制  │
│   (8 bits)  │(4 bits)│(4bits)│ (8 bits)  │  (24 bits) │ (16 bits)│
└─────────────┴────────┴───────┴──────────┴────────────┴──────────┘

访问字节（Access Byte）：
  Bit 7: 存在位（Present）= 1 表示有效
  Bit 6-5: 特权级（DPL）0=内核 3=用户
  Bit 4: 描述符类型 1=代码/数据 0=系统
  Bit 3: 可执行（1=代码段，0=数据段）
  Bit 2: 方向/一致性
  Bit 1: 可读/可写
  Bit 0: 访问位（CPU 自动设置）

标志（Flags）：
  Bit 3: 粒度（G）0=字节 1=4KB页
  Bit 2: 操作数大小（DB）0=16位 1=32位
  Bit 1: 64位代码段（L）
  Bit 0: 保留
```

### 段选择子（Segment Selector）

段寄存器（CS/DS/ES等）在保护模式下存放的是**段选择子**：

```
15              3  2   1  0
┌────────────────┬──┬─────┐
│    描述符索引   │TI│ RPL │
│   (13 bits)    │1b│ 2b  │
└────────────────┴──┴─────┘

TI = 0: 查询 GDT
TI = 1: 查询 LDT
RPL: 请求特权级（0~3）

示例：
  0x0008 = 0000 0000 0000 1000b → 索引1，GDT，Ring0（内核代码段）
  0x0010 = 0000 0000 0001 0000b → 索引2，GDT，Ring0（内核数据段）
  0x001B = 0000 0000 0001 1011b → 索引3，GDT，Ring3（用户代码段）
```

---

## 2.3 实现 GDT

将 GDT 初始化代码添加到 `loader.asm` 中：

```nasm
;-------------------------------------------------------------
; GDT 定义（放在 loader.asm 的数据段）
;-------------------------------------------------------------

; GDT 描述符宏（方便定义）
; 参数：基址, 段限, 访问字节, 标志
%macro SEG_DESC 4
    dw (%2 & 0xFFFF)              ; 段限 0-15
    dw (%1 & 0xFFFF)              ; 基址 0-15
    db ((%1 >> 16) & 0xFF)        ; 基址 16-23
    db %3                          ; 访问字节
    db (((%2 >> 16) & 0x0F) | ((%4 << 4) & 0xF0))  ; 段限 16-19 + 标志
    db ((%1 >> 24) & 0xFF)        ; 基址 24-31
%endmacro

; 访问字节常量
CODE_SEG_ACCESS  equ 0b10011010  ; 存在=1,DPL=00,类型=1,可执行=1,一致=0,可读=1,访问=0
DATA_SEG_ACCESS  equ 0b10010010  ; 存在=1,DPL=00,类型=1,可执行=0,方向=0,可写=1,访问=0

; 段标志常量
SEG_FLAGS_32     equ 0b1100      ; G=1(4KB粒度),DB=1(32位),L=0,保留=0

; 对齐 GDT 到 4 字节边界
align 4
GDT_start:
    ; 第 0 项：空描述符（必须）
    SEG_DESC 0x0, 0x0, 0x0, 0x0

    ; 第 1 项：内核代码段（Ring 0）
    ; 基址=0，长度=4GB（0xFFFFF × 4KB），32位，可执行，可读
    SEG_DESC 0x0, 0xFFFFF, CODE_SEG_ACCESS, SEG_FLAGS_32

    ; 第 2 项：内核数据段（Ring 0）
    ; 基址=0，长度=4GB，32位，可写
    SEG_DESC 0x0, 0xFFFFF, DATA_SEG_ACCESS, SEG_FLAGS_32

GDT_end:

; GDTR 寄存器结构（lgdt 指令需要这个）
GDT_descriptor:
    dw GDT_end - GDT_start - 1   ; GDT 大小（字节数 - 1）
    dd GDT_start                  ; GDT 物理基地址（32位）

; 段选择子常量（方便后续使用）
KERNEL_CODE_SEG equ GDT_start + 8 - GDT_start   ; = 0x0008
KERNEL_DATA_SEG equ GDT_start + 16 - GDT_start  ; = 0x0010
```

---

## 2.4 切换到保护模式的步骤

切换到保护模式需要严格按照以下步骤执行：

```nasm
;-------------------------------------------------------------
; 函数：switch_to_protected_mode
; 切换 CPU 到 32 位保护模式
;-------------------------------------------------------------
switch_to_protected_mode:
    ; 步骤 1：关中断（切换期间不允许中断）
    cli

    ; 步骤 2：加载 GDT（告诉 CPU GDT 在哪里）
    lgdt [GDT_descriptor]

    ; 步骤 3：设置 CR0 寄存器的 PE 位（Protected Enable）
    mov eax, cr0
    or eax, 0x1         ; 设置第 0 位（PE 位）
    mov cr0, eax

    ; 步骤 4：通过远跳转（Far Jump）刷新流水线
    ; 这一步非常关键！必须用 far jmp 强制 CPU 重新加载 CS 寄存器
    ; 0x0008 是内核代码段选择子
    jmp 0x0008:protected_mode_entry

;-------------------------------------------------------------
; 保护模式入口（从这里开始是 32 位代码）
;-------------------------------------------------------------
[BITS 32]
protected_mode_entry:
    ; 步骤 5：更新所有数据段寄存器
    mov ax, 0x0010      ; 内核数据段选择子
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; 步骤 6：设置新的栈顶
    mov esp, 0x9F000    ; 在 Loader 下方的安全区域

    ; 打印进入保护模式的确认信息
    call print_string_32

    ; 跳转到内核
    jmp KERNEL_BASE_ADDR

;-------------------------------------------------------------
; 32 位保护模式下的字符串打印
; 直接写 VGA 显存（0xB8000）
;-------------------------------------------------------------
print_string_32:
    ; 在保护模式下不能用 BIOS 中断
    ; 直接操作 VGA 文字模式显存
    mov edi, 0xB8000    ; VGA 显存基地址
    mov esi, pm_msg     ; 消息字符串
    mov ah, 0x0F        ; 属性：黑底白字

.loop:
    lodsb
    or al, al
    jz .done
    mov [edi], ax       ; 写入字符和属性
    add edi, 2          ; 每个字符占 2 字节（字符 + 属性）
    jmp .loop
.done:
    ret

pm_msg db 'Entered Protected Mode!', 0
```

---

## 2.5 完整的 loader.asm（集成保护模式切换）

将以上内容整合到完整的 loader.asm：

```nasm
[BITS 16]
[ORG 0x9000]

KERNEL_BASE_ADDR equ 0x100000   ; 1MB 处

loader_start:
    mov si, loader_msg
    call print_string_16
    
    call detect_memory       ; 内存检测（第1章）
    call enable_a20          ; 开启 A20（第1章）
    call switch_to_protected_mode  ; 切换保护模式

; （以下代码在16位模式下）
; ... 参见第1章的实现

;=============================================
; GDT 定义（如 2.3 节所示）
;=============================================
; ... GDT_start, GDT_end, GDT_descriptor

;=============================================
; switch_to_protected_mode（如 2.4 节所示）
;=============================================

;=============================================
; 32位代码（保护模式入口）
;=============================================
[BITS 32]
protected_mode_entry:
    mov ax, 0x0010
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x9F000

    ; 清除 VGA 屏幕
    call clear_screen_32

    ; 打印进入保护模式的信息
    mov esi, pm_msg
    mov edi, 0xB8000
    call print_string_vga

    ; 跳转到内核入口
    jmp KERNEL_BASE_ADDR

;-------------------------------------------------------------
; 清除 VGA 屏幕（80×25 文字模式）
;-------------------------------------------------------------
clear_screen_32:
    mov edi, 0xB8000
    mov ecx, 80 * 25    ; 总字符数
    mov ax, 0x0720      ; 空格 + 白色属性
    rep stosw           ; 重复写入（每次写 2 字节）
    ret

;-------------------------------------------------------------
; VGA 字符串打印
; 参数：ESI = 字符串，EDI = 显存地址
;-------------------------------------------------------------
print_string_vga:
    mov ah, 0x0F        ; 白色前景，黑色背景
.loop:
    lodsb
    or al, al
    jz .done
    stosw               ; 写入 AX（AL=字符，AH=属性）到 ES:EDI
    jmp .loop
.done:
    ret

pm_msg db '[32-bit] Protected mode activated!', 0

times 2048 - ($ - $$) db 0     ; 填充到 4 扇区
```

---

## 2.6 验证保护模式

构建并运行：

```bash
make all && make run
```

**预期 QEMU 输出**：
```
[Boot] MBR loaded, reading loader...
[Loader] Stage 2 bootloader running
[Loader] Detecting memory...
[32-bit] Protected mode activated!
```

### GDB 调试保护模式切换

```bash
# 启动调试
make debug

# GDB 命令
(gdb) set architecture i8086       # 先设置 16 位架构
(gdb) break *0x9000                # 在 Loader 入口断点
(gdb) continue
(gdb) stepi                        # 单步执行
# 当执行到 jmp 0x0008:protected_mode_entry 之后
(gdb) set architecture i386        # 切换到 32 位架构
(gdb) x/8i $eip                    # 查看 32 位指令
```

---

## 2.7 特权级（Ring）机制

```
Ring 0（内核态）：最高权限
  - 可访问所有硬件
  - 可执行特权指令（如 lgdt, lidt, cli, sti）
  - 直接操作内存

Ring 3（用户态）：最低权限
  - 不能直接访问硬件
  - 不能执行特权指令
  - 通过系统调用进入 Ring 0

Ring 1, 2：通常不使用（Linux/Windows 都只用 0 和 3）

特权级转换：
  Ring 3 → Ring 0：通过中断（INT）或系统调用（SYSCALL/SYSENTER）
  Ring 0 → Ring 3：通过 IRET 指令
```

---

## 2.8 章节小结

本章实现了：
- [x] 理解 GDT 与段描述符结构
- [x] 编写 GDT 初始化代码
- [x] 实现实模式到保护模式的切换
- [x] 在保护模式下直接操作 VGA 显存输出文字
- [x] 理解特权级机制

## 🏠 课后作业

1. 为 GDT 添加用户态代码段和数据段（Ring 3）描述符
2. 实现 VGA 彩色文字输出（修改 AH 字节的高 4 位为背景色，低 4 位为前景色）
3. 尝试在保护模式下执行一条特权指令，观察 CPU 会产生什么异常（General Protection Fault #GP）

---

**上一章** ← [第 1 章：Bootloader](./01_Bootloader.md)

**下一章** → [第 3 章：内核入口与 C 语言环境](./03_Kernel_Entry.md)
