# 第 1 章：编写 Bootloader 引导程序

## 1.1 计算机启动过程详解

```
上电/复位
   │
   ▼
CPU 从固定地址 0xFFFFFFF0 开始执行
   │
   ▼
BIOS 执行 POST（加电自检）
   │
   ▼
BIOS 检查引导设备（硬盘/软盘/USB）
   │
   ▼
BIOS 读取引导设备第一个扇区（512字节）到内存 0x7C00
   │
   ▼
BIOS 检查最后两字节是否为 0x55 0xAA
   │
   ├── 不是 → 尝试下一个引导设备
   │
   └── 是 → 跳转到 0x7C00 开始执行（这就是我们的代码！）
```

**关键约束**：
- MBR（主引导记录）只有 **512 字节**
- 其中最后 2 字节必须是 `0x55 0xAA`（引导标志）
- 可用代码空间只有 **510 字节**

**策略**：用 510 字节的一级引导器（Boot Sector）加载一个更大的二级引导器（Loader），然后由 Loader 加载内核。

---

## 1.2 一级引导器（Boot Sector）

一级引导器的唯一任务：**从磁盘读取 Loader 并跳转过去**。

**文件：`boot/boot.asm`**

```nasm
;=============================================================
; boot.asm - MBR 一级引导器
; 加载地址：0x7C00（BIOS 自动加载）
; 功能：从磁盘读取 Loader，跳转执行
;=============================================================

[BITS 16]           ; 实模式：16 位代码
[ORG 0x7C00]        ; 代码基地址

; Loader 的加载位置和磁盘位置
LOADER_BASE_ADDR    equ 0x9000   ; Loader 加载到内存 0x9000
LOADER_START_SECTOR equ 2        ; Loader 从磁盘第 2 扇区开始
LOADER_SECTOR_COUNT equ 4        ; 读取 4 个扇区（2KB）

;-------------------------------------------------------------
; 入口点
;-------------------------------------------------------------
_start:
    ; 关中断，防止 BIOS 打扰
    cli

    ; 初始化段寄存器（实模式下 段地址 * 16 + 偏移 = 物理地址）
    xor ax, ax          ; ax = 0
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; 初始化栈
    mov ss, ax
    mov sp, 0x7C00      ; 栈从 0x7C00 向低地址增长

    ; 开中断
    sti

    ; 打印启动信息
    mov si, boot_msg
    call print_string

    ; 从磁盘读取 Loader
    call load_loader

    ; 跳转到 Loader
    jmp LOADER_BASE_ADDR

;-------------------------------------------------------------
; 函数：print_string
; 参数：SI = 字符串地址（以 0 结尾）
;-------------------------------------------------------------
print_string:
    pusha               ; 保存所有通用寄存器
.loop:
    lodsb               ; AL = [SI]，SI++
    or al, al
    jz .done            ; 遇到 0 则结束
    mov ah, 0x0E        ; BIOS 电传打字模式
    mov bx, 0x0007      ; 页面 0，白色前景
    int 0x10
    jmp .loop
.done:
    popa
    ret

;-------------------------------------------------------------
; 函数：load_loader
; 使用 BIOS INT 0x13 从磁盘读取扇区
;-------------------------------------------------------------
load_loader:
    mov ax, LOADER_BASE_ADDR >> 4   ; 计算段地址
    mov es, ax
    xor bx, bx                      ; 偏移地址 = 0

    mov ah, 0x02        ; BIOS 读取扇区功能
    mov al, LOADER_SECTOR_COUNT  ; 读取扇区数
    mov ch, 0           ; 磁道号（柱面号）= 0
    mov cl, LOADER_START_SECTOR  ; 起始扇区号
    mov dh, 0           ; 磁头号 = 0
    mov dl, 0x00        ; 驱动器号（0 = 软盘 A:）
    int 0x13

    jc disk_error       ; 如果进位标志被设置，说明出错

    ; 恢复 ES
    xor ax, ax
    mov es, ax
    ret

;-------------------------------------------------------------
; 磁盘读取错误处理
;-------------------------------------------------------------
disk_error:
    mov si, error_msg
    call print_string
.halt:
    hlt
    jmp .halt           ; 死循环

;-------------------------------------------------------------
; 数据区
;-------------------------------------------------------------
boot_msg  db '[Boot] MBR loaded, reading loader...', 0x0D, 0x0A, 0
error_msg db '[Boot] ERROR: Disk read failed!', 0x0D, 0x0A, 0

;-------------------------------------------------------------
; MBR 填充与引导签名
;-------------------------------------------------------------
times 510 - ($ - $$) db 0   ; 填充到 510 字节
dw 0xAA55                    ; 引导签名（注意字节序）
```

---

## 1.3 二级引导器（Loader）

Loader 比 MBR 宽松得多（我们给它 4 个扇区 = 2KB），可以做更复杂的事情：

**文件：`boot/loader.asm`**

```nasm
;=============================================================
; loader.asm - 二级引导器
; 加载地址：0x9000
; 功能：
;   1. 检测内存大小
;   2. 开启 A20 地址线
;   3. 切换到保护模式
;   4. 加载内核到高地址
;   5. 跳转到内核
;=============================================================

[BITS 16]
[ORG 0x9000]

KERNEL_BASE_ADDR    equ 0x100000   ; 内核加载到 1MB 地址处
KERNEL_START_SECTOR equ 6          ; 内核从第 6 扇区开始
KERNEL_SECTOR_COUNT equ 200        ; 读取 200 个扇区（100KB）

;-------------------------------------------------------------
; 入口点
;-------------------------------------------------------------
loader_start:
    ; 打印进入 Loader 的信息
    mov si, loader_msg
    call print_string_16

    ;--- 步骤 1：检测内存 ---
    call detect_memory

    ;--- 步骤 2：开启 A20 地址线 ---
    call enable_a20

    ;--- 步骤 3：加载内核文件 ---
    call load_kernel

    ;--- 步骤 4：切换到保护模式（见第2章） ---
    ; ... 第2章实现

    jmp $               ; 临时死循环

;-------------------------------------------------------------
; 函数：detect_memory
; 使用 BIOS E820 功能检测物理内存布局
; 将结果存储到 mem_map 数组
;-------------------------------------------------------------
detect_memory:
    pushad
    mov si, mem_detect_msg
    call print_string_16

    xor ebx, ebx            ; EBX = 0（第一次调用）
    mov di, mem_map         ; ES:DI 指向存储区
    xor bp, bp              ; BP 计数器清零

.e820_loop:
    mov eax, 0xE820         ; BIOS E820 功能号
    mov edx, 0x534D4150     ; 魔数 "SMAP"
    mov ecx, 24             ; 每条记录 24 字节
    int 0x15

    jc .e820_done           ; 进位标志 = 出错或结束
    cmp eax, 0x534D4150     ; 返回值应等于 "SMAP"
    jne .e820_done

    inc bp                  ; 记录数 +1
    add di, 24              ; 移动到下一条记录

    test ebx, ebx           ; EBX = 0 表示没有更多记录
    jz .e820_done
    jmp .e820_loop

.e820_done:
    mov [mem_map_count], bp  ; 保存记录数
    popad
    ret

;-------------------------------------------------------------
; 函数：enable_a20
; 开启 A20 地址线，允许访问 1MB 以上内存
;-------------------------------------------------------------
enable_a20:
    ; 方法一：通过 BIOS
    mov ax, 0x2401
    int 0x15
    jnc .done

    ; 方法二：通过键盘控制器（8042）
    call .wait_input
    mov al, 0xAD            ; 禁用键盘
    out 0x64, al

    call .wait_input
    mov al, 0xD0            ; 读取输出端口
    out 0x64, al

    call .wait_output
    in al, 0x60             ; 读取数据
    push ax

    call .wait_input
    mov al, 0xD1            ; 写输出端口
    out 0x64, al

    call .wait_input
    pop ax
    or al, 0x02             ; 设置 A20 位
    out 0x60, al

    call .wait_input
    mov al, 0xAE            ; 启用键盘
    out 0x64, al

    call .wait_input
.done:
    ret

.wait_input:
    in al, 0x64
    test al, 0x02
    jnz .wait_input
    ret

.wait_output:
    in al, 0x64
    test al, 0x01
    jz .wait_output
    ret

;-------------------------------------------------------------
; 函数：load_kernel
; 从磁盘加载内核到 1MB 地址（需要保护模式才能访问高地址）
; 这里先加载到临时低地址，后续在保护模式下复制
;-------------------------------------------------------------
load_kernel:
    mov si, kernel_load_msg
    call print_string_16
    ; 具体实现见第 3 章
    ret

;-------------------------------------------------------------
; 16 位模式下的字符串打印函数
;-------------------------------------------------------------
print_string_16:
    pusha
.loop:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    mov bx, 0x0007
    int 0x10
    jmp .loop
.done:
    popa
    ret

;-------------------------------------------------------------
; 数据区
;-------------------------------------------------------------
loader_msg      db '[Loader] Stage 2 bootloader running', 0x0D, 0x0A, 0
mem_detect_msg  db '[Loader] Detecting memory...', 0x0D, 0x0A, 0
kernel_load_msg db '[Loader] Loading kernel...', 0x0D, 0x0A, 0

mem_map_count   dw 0
mem_map         times (20 * 24) db 0   ; 最多 20 条内存记录

; 填充到扇区边界（4 扇区 = 2048 字节）
times 2048 - ($ - $$) db 0
```

---

## 1.4 磁盘映像布局设计

```
磁盘映像（floppy.img）布局：
┌─────────────────────────────────────┐
│ 扇区 0（0x0000）                     │ ← MBR boot.asm 编译结果（512 字节）
├─────────────────────────────────────┤
│ 扇区 1（0x0200）                     │ ← 保留
├─────────────────────────────────────┤
│ 扇区 2-5（0x0400 - 0x0BFF）          │ ← Loader loader.asm 编译结果（4 扇区）
├─────────────────────────────────────┤
│ 扇区 6-205（0x0C00 - 0x19BFF）       │ ← 内核 kernel.bin（200 扇区）
├─────────────────────────────────────┤
│ 剩余扇区                             │ ← 文件系统数据
└─────────────────────────────────────┘
```

---

## 1.5 Makefile 构建脚本

**文件：`Makefile`**

```makefile
# ============================================================
# MiniOS Makefile
# ============================================================

NASM   = nasm
GCC    = gcc
LD     = ld
QEMU   = qemu-system-i386

# 编译选项
NASM_FLAGS = -f bin
GCC_FLAGS  = -m32 -ffreestanding -fno-stack-protector \
             -fno-builtin -nostdlib -nostdinc \
             -Wall -Wextra

IMG = disk.img
IMG_SIZE_MB = 4

.PHONY: all run debug clean

all: $(IMG)

# 创建磁盘映像
$(IMG): boot/boot.bin boot/loader.bin
	# 创建空白磁盘映像（4MB）
	dd if=/dev/zero of=$(IMG) bs=1M count=$(IMG_SIZE_MB)
	# 写入 MBR
	dd if=boot/boot.bin of=$(IMG) conv=notrunc bs=512 seek=0
	# 写入 Loader（从第 2 扇区开始）
	dd if=boot/loader.bin of=$(IMG) conv=notrunc bs=512 seek=2

# 编译 MBR
boot/boot.bin: boot/boot.asm
	$(NASM) $(NASM_FLAGS) $< -o $@

# 编译 Loader
boot/loader.bin: boot/loader.asm
	$(NASM) $(NASM_FLAGS) $< -o $@

# 启动 QEMU
run: $(IMG)
	$(QEMU) -drive file=$(IMG),format=raw,index=0,media=disk \
	        -m 32M \
	        -display gtk

# 调试模式（配合 GDB）
debug: $(IMG)
	$(QEMU) -drive file=$(IMG),format=raw,index=0,media=disk \
	        -m 32M \
	        -S -gdb tcp::1234 &
	gdb -ex "target remote localhost:1234" \
	    -ex "set architecture i8086" \
	    -ex "break *0x7C00" \
	    -ex "continue"

clean:
	rm -f boot/*.bin $(IMG)
```

---

## 1.6 运行与调试

### 正常运行

```bash
# 构建项目
make all

# 启动 QEMU
make run
```

**预期输出**：
```
[Boot] MBR loaded, reading loader...
[Loader] Stage 2 bootloader running
[Loader] Detecting memory...
[Loader] Loading kernel...
```

### GDB 调试技巧

```bash
# 终端 1：启动 QEMU 等待调试器
make debug

# 终端 2：连接 GDB
gdb
(gdb) target remote localhost:1234
(gdb) set architecture i8086   # 实模式 16 位
(gdb) break *0x7C00            # 在 MBR 入口处设置断点
(gdb) continue                 # 运行到断点
(gdb) x/10i $pc                # 查看当前位置的 10 条指令
(gdb) info registers           # 查看寄存器状态
(gdb) x/16xb 0x7C00            # 查看 0x7C00 处的内存（十六进制）
(gdb) stepi                    # 单步执行一条指令
```

---

## 1.7 BIOS 读取磁盘的两种方式

### CHS 寻址（本章使用）
```
Cylinder-Head-Sector 寻址（旧式）
  柱面（Cylinder）：0 ~ 1023
  磁头（Head）    ：0 ~ 255
  扇区（Sector）  ：1 ~ 63

CHS → LBA 转换公式：
LBA = (Cylinder * 磁头数 + Head) * 扇区数/磁道 + (Sector - 1)

软盘参数：
  80 个柱面，2 个磁头，18 个扇区/磁道
  总扇区数 = 80 × 2 × 18 = 2880 扇区
```

### LBA 寻址（现代方式）
```nasm
; 使用 INT 0x13 扩展功能（LBA 寻址）
; 需要 BIOS 支持 INT 0x13 AH=0x42

; 磁盘地址数据包（DAP）
dap:
    db 0x10         ; 包大小（16 字节）
    db 0            ; 保留
    dw 1            ; 读取扇区数
    dw 0x0000       ; 目标偏移
    dw 0x1000       ; 目标段地址
    dq 2            ; 起始 LBA（64位）

mov ah, 0x42        ; 扩展读取
mov dl, 0x80        ; 硬盘 0
mov si, dap         ; DS:SI 指向 DAP
int 0x13
```

---

## 1.8 章节小结

本章我们实现了：
- [x] 理解 BIOS 启动流程
- [x] 编写 512 字节的 MBR 引导扇区
- [x] 编写二级引导器（Loader）
- [x] 内存检测（E820）
- [x] A20 地址线开启
- [x] 完整的 Makefile 构建系统
- [x] QEMU + GDB 调试方法

## 🏠 课后作业

1. 修改 boot.asm，在打印信息前先清屏（BIOS INT 0x10 AH=0x00，AL=0x03）
2. 为 disk_error 函数添加重试机制（最多重试 3 次）
3. 研究 BIOS E820 返回的内存类型：Type=1（可用），Type=2（保留），Type=3（ACPI）...

---

**上一章** ← [第 0 章：前置知识](./00_Prerequisites.md)

**下一章** → [第 2 章：进入保护模式](./02_ProtectedMode.md)
