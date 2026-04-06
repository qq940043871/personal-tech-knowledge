# 第 0 章：前置知识与工具准备

## 0.1 你需要掌握的基础知识

在开始之前，请确认你已经具备以下基础：

### 必备知识
| 知识点 | 要求程度 | 说明 |
|--------|----------|------|
| C 语言 | 熟练 | 指针、结构体、位运算必须掌握 |
| 二进制/十六进制 | 熟练 | 所有地址操作都用十六进制 |
| 汇编基础 | 了解 | 不需要精通，看得懂基本指令即可 |
| 计算机组成原理 | 了解 | CPU 寄存器、内存寻址、I/O 端口 |
| Linux 命令行 | 基础 | make、gcc、dd 等工具的使用 |

### 推荐预学
- 《深入理解计算机系统》（CSAPP）第 1-3 章
- Intel IA-32 架构手册（有参考价值，不需要全读）

---

## 0.2 开发环境搭建

### 方式一：Ubuntu/Debian（推荐）

```bash
# 更新包管理器
sudo apt update

# 安装汇编器
sudo apt install nasm -y

# 安装 GCC 工具链
sudo apt install gcc gcc-multilib binutils -y

# 安装 QEMU 虚拟机
sudo apt install qemu-system-x86 -y

# 安装调试工具
sudo apt install gdb -y

# 安装 make
sudo apt install make -y

# 验证安装
nasm --version    # NASM version 2.15.x
gcc --version     # gcc (Ubuntu 11.x) ...
qemu-system-i386 --version  # QEMU emulator version 6.x
```

### 方式二：Windows（使用 WSL2）

```powershell
# 在 Windows PowerShell 中安装 WSL2
wsl --install -d Ubuntu-22.04

# 进入 WSL2 后执行方式一的命令
```

### 方式三：macOS

```bash
# 使用 Homebrew
brew install nasm
brew install qemu
brew install x86_64-elf-gcc  # 交叉编译器
```

---

## 0.3 关键概念速览

### CPU 实模式 vs 保护模式

| 特性 | 实模式（Real Mode） | 保护模式（Protected Mode） |
|------|---------------------|---------------------------|
| 地址宽度 | 20 位（最大 1MB） | 32 位（最大 4GB） |
| 内存保护 | 无 | 有（段权限、分页） |
| 多任务 | 不支持 | 支持 |
| 启动后状态 | CPU 默认启动状态 | 需要手动切换 |

> **关键流程**：计算机上电 → BIOS → 实模式 → 我们的 Bootloader → 切换到保护模式 → 内核

### 内存地址空间（x86 启动初始布局）

```
物理内存地址分布（低 1MB）：
┌──────────────────────────────┐ 0x00100000 (1MB)
│       上位内存区（HMA）        │
├──────────────────────────────┤ 0x000F0000
│       BIOS ROM 映射区         │
├──────────────────────────────┤ 0x000C0000
│     显卡 BIOS/显存映射区       │
├──────────────────────────────┤ 0x000A0000
│       可用 RAM（约 640KB）     │ ← 我们的代码和数据放这里
├──────────────────────────────┤ 0x00007E00
│    MBR 引导扇区（512 字节）    │ ← BIOS 把磁盘第一个扇区加载到这里
├──────────────────────────────┤ 0x00007C00
│       BIOS 数据区              │
├──────────────────────────────┤ 0x00000500
│       BIOS 中断向量表          │
└──────────────────────────────┘ 0x00000000
```

### 重要寄存器

```
通用寄存器：
  EAX, EBX, ECX, EDX  - 数据运算
  ESI, EDI             - 字符串/数据操作
  ESP                  - 栈指针（Stack Pointer）
  EBP                  - 基址指针（Base Pointer）

段寄存器（16 位）：
  CS  - 代码段（Code Segment）
  DS  - 数据段（Data Segment）
  SS  - 栈段（Stack Segment）
  ES/FS/GS - 附加段

特殊寄存器：
  EIP  - 指令指针（程序计数器）
  EFLAGS - 标志寄存器（进位、零标志等）
  CR0  - 控制寄存器 0（PE 位控制保护模式）
  CR3  - 页目录基地址（分页时使用）
```

---

## 0.4 BIOS 中断服务（实模式下使用）

BIOS 提供了一系列软中断（INT 指令）供我们在实模式下调用：

```nasm
; 常用 BIOS 中断
INT 0x10  - 视频服务（打印字符、设置显示模式）
INT 0x13  - 磁盘服务（读取扇区）
INT 0x15  - 系统服务（获取内存大小）
INT 0x16  - 键盘服务（读取按键）

; 示例：用 BIOS 打印一个字符 'A'
mov ah, 0x0E    ; 功能号：电传打字模式输出
mov al, 'A'     ; 要输出的字符
int 0x10        ; 调用 BIOS 视频中断
```

---

## 0.5 NASM 汇编基础语法速查

```nasm
; 注释用分号

; 数据定义
db 0x55, 0xAA       ; 定义字节
dw 0x1234           ; 定义字（2 字节）
dd 0x12345678       ; 定义双字（4 字节）
times 510 db 0      ; 重复 510 次定义 0 字节

; 伪指令
[BITS 16]           ; 告诉 NASM 生成 16 位代码
[ORG 0x7C00]        ; 告诉 NASM 代码加载地址为 0x7C00
section .text       ; 代码段
section .data       ; 数据段

; 常用指令
mov eax, 0x10       ; 将 0x10 赋值给 eax
add eax, ebx        ; eax = eax + ebx
sub eax, 1          ; eax = eax - 1
push eax            ; 压栈
pop eax             ; 出栈
call func           ; 调用函数
ret                 ; 函数返回
jmp label           ; 无条件跳转
je label            ; 相等时跳转（Zero Flag = 1）
jne label           ; 不相等时跳转
cmp eax, ebx        ; 比较（设置标志位，不改变操作数）
and eax, 0xFF       ; 按位与
or  eax, 0x01       ; 按位或
xor eax, eax        ; 清零（eax = eax XOR eax = 0）
shl eax, 2          ; 左移 2 位（× 4）
shr eax, 2          ; 右移 2 位（÷ 4）
```

---

## 0.6 第一个汇编程序：Hello BIOS

用于验证开发环境是否正常：

**文件：`test/hello_bios.asm`**

```nasm
[BITS 16]
[ORG 0x7C00]

start:
    ; 初始化段寄存器
    xor ax, ax
    mov ds, ax
    mov es, ax

    ; 设置栈
    mov ss, ax
    mov sp, 0x7C00

    ; 打印 "Hello OS!" 字符串
    mov si, msg
print_loop:
    lodsb               ; 从 [SI] 加载一个字节到 AL，SI 自动 +1
    or al, al           ; 检查是否为 0（字符串结尾）
    jz done
    mov ah, 0x0E        ; BIOS 输出字符功能
    int 0x10
    jmp print_loop
done:
    hlt                 ; 停机

msg db 'Hello OS!', 0x0D, 0x0A, 0   ; 字符串，含回车换行，以 0 结尾

; 填充到 510 字节，并加上 MBR 引导签名
times 510 - ($ - $$) db 0
dw 0xAA55               ; 引导扇区标志（小端序：0x55, 0xAA）
```

**构建并运行：**

```bash
# 编译汇编文件，生成原始二进制
nasm -f bin hello_bios.asm -o hello_bios.bin

# 创建虚拟软盘映像（1.44MB）
dd if=/dev/zero of=floppy.img bs=512 count=2880

# 将引导扇区写入虚拟软盘的第一个扇区
dd if=hello_bios.bin of=floppy.img conv=notrunc

# 用 QEMU 启动
qemu-system-i386 -fda floppy.img
```

✅ 如果看到 QEMU 窗口显示 `Hello OS!`，说明开发环境配置成功！

---

## 0.7 Makefile 基础

本教程大量使用 Makefile 自动化构建：

```makefile
# Makefile 基础结构
目标: 依赖1 依赖2
	命令（注意：必须用 Tab 缩进，不能用空格）

# 示例
hello.bin: hello.asm
	nasm -f bin hello.asm -o hello.bin

run: hello.bin
	qemu-system-i386 -fda hello.bin

clean:
	rm -f *.bin *.img

.PHONY: run clean  # 声明伪目标（不对应实际文件）
```

---

## 0.8 章节小结

本章我们完成了：
- [x] 了解开发操作系统所需的前置知识
- [x] 搭建完整的开发环境（NASM + GCC + QEMU）
- [x] 理解 x86 内存布局和 CPU 模式
- [x] 编写并运行了第一个 BIOS 程序

## 🏠 课后作业

1. 修改 `hello_bios.asm`，打印出你自己的名字
2. 查阅 BIOS INT 0x10 的其他功能，尝试用不同颜色打印字符
3. 用 `xxd hello_bios.bin | head` 查看二进制文件的最后两字节，确认 `0x55 0xAA`

---

**下一章** → [第 1 章：编写 Bootloader 引导程序](./01_Bootloader.md)
