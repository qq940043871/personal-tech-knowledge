# 快速参考指南

## 🔧 常用命令

### 编译命令

```bash
# 编译汇编文件
nasm -f bin boot.asm -o boot.img
nasm -f elf32 kernel.asm -o kernel.o

# 编译C文件
gcc -m32 -c kernel.c -o kernel.o
gcc -m32 -nostdlib -c kernel.c -o kernel.o

# 链接
ld -m elf_i386 -o kernel.elf boot.o kernel.o

# 转换为二进制
objcopy -O binary kernel.elf kernel.bin
```

### 运行和调试

```bash
# 运行
qemu-system-i386 -fda boot.img
qemu-system-i386 -hda disk.img

# 调试
qemu-system-i386 -fda boot.img -s -S
gdb
(gdb) target remote localhost:1234
(gdb) file kernel.elf
(gdb) break main
(gdb) continue
```

### 查看文件

```bash
# 查看二进制文件
hexdump -C boot.img | head -20

# 反汇编
objdump -d kernel.elf

# 查看符号表
nm kernel.elf

# 查看节信息
readelf -S kernel.elf
```

---

## 📚 x86汇编速查表

### 数据传输指令

| 指令 | 说明 | 例子 |
|------|------|------|
| `mov` | 传输数据 | `mov eax, ebx` |
| `movzx` | 零扩展传输 | `movzx eax, al` |
| `movsx` | 符号扩展传输 | `movsx eax, al` |
| `xchg` | 交换数据 | `xchg eax, ebx` |
| `lea` | 加载有效地址 | `lea eax, [ebx+4]` |

### 算术指令

| 指令 | 说明 | 例子 |
|------|------|------|
| `add` | 加法 | `add eax, ebx` |
| `sub` | 减法 | `sub eax, 1` |
| `imul` | 有符号乘法 | `imul eax, 2` |
| `idiv` | 有符号除法 | `idiv ecx` |
| `inc` | 加1 | `inc eax` |
| `dec` | 减1 | `dec eax` |
| `neg` | 取反 | `neg eax` |

### 逻辑指令

| 指令 | 说明 | 例子 |
|------|------|------|
| `and` | 按位与 | `and eax, 0xFF` |
| `or` | 按位或 | `or eax, 0x80` |
| `xor` | 按位异或 | `xor eax, eax` |
| `not` | 按位非 | `not eax` |
| `shl` | 左移 | `shl eax, 2` |
| `shr` | 右移 | `shr eax, 2` |
| `sar` | 算术右移 | `sar eax, 2` |

### 比较和跳转

| 指令 | 说明 | 例子 |
|------|------|------|
| `cmp` | 比较 | `cmp eax, ebx` |
| `test` | 测试 | `test eax, eax` |
| `jmp` | 无条件跳转 | `jmp label` |
| `je` | 相等时跳转 | `je label` |
| `jne` | 不相等时跳转 | `jne label` |
| `jl` | 小于时跳转 | `jl label` |
| `jle` | 小于等于时跳转 | `jle label` |
| `jg` | 大于时跳转 | `jg label` |
| `jge` | 大于等于时跳转 | `jge label` |

### 栈操作

| 指令 | 说明 | 例子 |
|------|------|------|
| `push` | 压栈 | `push eax` |
| `pop` | 出栈 | `pop eax` |
| `call` | 调用函数 | `call function` |
| `ret` | 返回 | `ret` |

### 特殊指令

| 指令 | 说明 | 例子 |
|------|------|------|
| `cli` | 禁用中断 | `cli` |
| `sti` | 启用中断 | `sti` |
| `hlt` | 停止 | `hlt` |
| `nop` | 无操作 | `nop` |
| `lgdt` | 加载GDT | `lgdt [gdt_ptr]` |
| `lidt` | 加载IDT | `lidt [idt_ptr]` |
| `in` | 读端口 | `in al, 0x60` |
| `out` | 写端口 | `out 0x60, al` |

---

## 🔌 I/O端口速查表

| 端口范围 | 设备 | 说明 |
|---------|------|------|
| 0x0000-0x000F | DMA控制器 | 直接内存访问 |
| 0x0020-0x003F | 可编程中断控制器 | 中断管理 |
| 0x0040-0x005F | 定时器/计数器 | 系统时钟 |
| 0x0060-0x006F | 键盘控制器 | 键盘输入 |
| 0x0070-0x007F | 实时时钟 | 系统时间 |
| 0x0080-0x008F | DMA页寄存器 | 内存分页 |
| 0x00A0-0x00AF | 从PIC | 级联中断 |
| 0x0170-0x0177 | IDE次通道 | 磁盘控制 |
| 0x01F0-0x01F7 | IDE主通道 | 磁盘控制 |
| 0x03F8-0x03FF | 串口1 | 串行通信 |
| 0x02F8-0x02FF | 串口2 | 串行通信 |

---

## 🎯 中断向量表

| 中断号 | 异常/中断名称 | 说明 |
|--------|--------------|------|
| 0x00 | 除以零异常 | 整数除以零 |
| 0x01 | 单步执行 | 调试用 |
| 0x02 | 非屏蔽中断 | NMI |
| 0x03 | 断点 | 调试用 |
| 0x04 | 溢出 | 有符号数溢出 |
| 0x05 | 越界 | 数组越界 |
| 0x06 | 无效操作码 | 非法指令 |
| 0x07 | 设备不可用 | FPU不可用 |
| 0x08 | 双重故障 | 异常处理异常 |
| 0x0A | 无效TSS | 任务状态段错误 |
| 0x0B | 段不存在 | 段选择子无效 |
| 0x0C | 栈段故障 | 栈溢出 |
| 0x0D | 保护故障 | 内存保护违规 |
| 0x0E | 页故障 | 页表缺失 |
| 0x10 | 浮点异常 | FPU错误 |
| 0x11 | 对齐检查 | 内存对齐错误 |
| 0x12 | 机器检查 | 硬件错误 |
| 0x13 | SIMD异常 | SSE错误 |
| 0x20 | 时钟中断 | 系统时钟 |
| 0x21 | 键盘中断 | 键盘输入 |
| 0x22 | 级联中断 | 从PIC |
| 0x23 | 串口1中断 | 串行通信 |
| 0x24 | 并口1中断 | 并行通信 |
| 0x25 | 软盘中断 | 软驱 |
| 0x26 | 并口2中断 | 并行通信 |
| 0x27 | 实时时钟中断 | 系统时间 |
| 0x28 | 串口2中断 | 串行通信 |
| 0x29 | 网卡中断 | 网络 |
| 0x2A | SCSI中断 | 磁盘 |
| 0x2B | 声卡中断 | 音频 |

---

## 📋 GDT描述符格式

```
63-56: 基址高8位 (Base 31:24)
55:    粒度标志 (G)
54:    默认操作数大小 (D/B)
53:    保留 (0)
52:    可用 (AVL)
51-48: 段界限高4位 (Limit 19:16)
47:    P（存在位）
46-45: DPL（特权级）
44:    S（描述符类型）
43-40: 类型 (Type)
39-32: 基址中间8位 (Base 23:16)
31-16: 基址低16位 (Base 15:0)
15-0:  段界限低16位 (Limit 15:0)
```

**类型字段（43-40）：**
- 0x0：数据段（只读）
- 0x2：数据段（读写）
- 0x4：栈段（只读）
- 0x6：栈段（读写）
- 0x8：代码段（只执行）
- 0xA：代码段（执行/读）
- 0xC：代码段（只执行，一致）
- 0xE：代码段（执行/读，一致）

---

## 🔐 CR0寄存器标志

| 位 | 名称 | 说明 |
|----|------|------|
| 0 | PE | 保护模式使能 |
| 1 | MP | 数学处理器 |
| 2 | EM | 仿真 |
| 3 | TS | 任务切换 |
| 4 | ET | 扩展类型 |
| 5 | NE | 数值错误 |
| 16 | WP | 写保护 |
| 18 | AM | 对齐掩码 |
| 29 | NW | 非写通 |
| 30 | CD | 缓存禁用 |
| 31 | PG | 分页 |

---

## 📊 EFLAGS寄存器标志

| 位 | 名称 | 说明 |
|----|------|------|
| 0 | CF | 进位标志 |
| 2 | PF | 奇偶标志 |
| 4 | AF | 辅助进位标志 |
| 6 | ZF | 零标志 |
| 7 | SF | 符号标志 |
| 8 | TF | 陷阱标志 |
| 9 | IF | 中断标志 |
| 10 | DF | 方向标志 |
| 11 | OF | 溢出标志 |
| 12-13 | IOPL | I/O特权级 |
| 14 | NT | 嵌套任务 |
| 16 | RF | 恢复标志 |
| 17 | VM | 虚拟8086模式 |
| 18 | AC | 对齐检查 |
| 19 | VIF | 虚拟中断标志 |
| 20 | VIP | 虚拟中断待处理 |
| 21 | ID | ID标志 |

---

## 🎓 学习资源速查

### 官方文档
- [Intel x86 Architecture Reference Manual](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html)
- [AMD64 Architecture Programmer's Manual](https://www.amd.com/en/technologies/amd64)
- [Linux Kernel Documentation](https://www.kernel.org/doc/)

### 在线社区
- [OSDev.org](https://wiki.osdev.org/)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/x86)
- [Reddit r/osdev](https://www.reddit.com/r/osdev/)

### 开源项目
- [Linux Kernel](https://github.com/torvalds/linux)
- [MINIX](https://github.com/Stichting-MINIX-Research-Foundation/minix)
- [xv6](https://github.com/mit-pdos/xv6-public)

---

## 💾 常用数据结构

### 进程控制块（PCB）

```c
struct process {
    int pid;                    // 进程ID
    int ppid;                   // 父进程ID
    int state;                  // 进程状态
    unsigned int esp;           // 栈指针
    unsigned int ebp;           // 基指针
    unsigned int eip;           // 指令指针
    struct page_table *pgt;     // 页表
    struct file_descriptor *fds; // 文件描述符
};
```

### 文件描述符

```c
struct file_descriptor {
    int fd;                     // 文件描述符
    struct inode *inode;        // inode指针
    unsigned int offset;        // 文件偏移
    int flags;                  // 打开标志
};
```

### inode结构

```c
struct inode {
    unsigned int ino;           // inode号
    unsigned int size;          // 文件大小
    unsigned int mode;          // 文件模式
    unsigned int uid;           // 用户ID
    unsigned int gid;           // 组ID
    unsigned int atime;         // 访问时间
    unsigned int mtime;         // 修改时间
    unsigned int ctime;         // 创建时间
    unsigned int blocks[12];    // 直接块指针
    unsigned int indirect;      // 一级间接块
    unsigned int double_indirect; // 二级间接块
};
```

---

**祝你学习顺利！** 🚀