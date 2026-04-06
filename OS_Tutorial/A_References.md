# 附录 A：参考资料与延伸阅读

## A.1 必读书籍

| 书名 | 作者 | 说明 |
|------|------|------|
| 《深入理解计算机系统》(CSAPP) | Bryant & O'Hallaron | 理解内存、进程、汇编的最佳教材 |
| 《操作系统：三大简易元素》(OSTEP) | Arpaci-Dusseau | 免费在线，OS 教学经典，极度推荐 |
| 《深入理解 Linux 内核》 | Bovet & Cesati | Linux 内核实现细节，进阶参考 |
| 《Orange'S：一个操作系统的实现》 | 于渊 | 中文 OS 开发教材，从零开始 |
| 《30天自制操作系统》 | 川合秀实 | 日文原著，风趣易懂的 OS 开发入门 |

---

## A.2 在线资源

### 官方规范文档
- **Intel 手册**：[https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html)
  - Volume 1：基础架构
  - Volume 2：指令集参考
  - Volume 3：系统编程指南（OS 开发必读）

- **NASM 文档**：[https://www.nasm.us/doc/](https://www.nasm.us/doc/)

- **OSDev Wiki**（OS 开发者圣经）：[https://wiki.osdev.org/](https://wiki.osdev.org/)
  - 包含几乎所有 OS 开发相关话题的详细文章

### 开源 OS 项目（可参考学习）

| 项目 | 语言 | 说明 |
|------|------|------|
| [SerenityOS](https://github.com/SerenityOS/serenity) | C++ | 现代图形界面 OS，代码质量极高 |
| [xv6](https://github.com/mit-pdos/xv6-public) | C | MIT 教学用 Unix，代码精简优雅 |
| [MINIX 3](https://www.minix3.org/) | C | 教学 OS，Tanenbaum 著作配套 |
| [ToaruOS](https://github.com/klange/toaruos) | C | 完整的类 Unix OS |
| [BlogOS](https://os.phil-opp.com/) | Rust | 用 Rust 写 OS 的优质博客系列 |

### 视频教程

- **Poncho's OS Dev Series**（YouTube）：[https://www.youtube.com/@RustedOS](https://www.youtube.com/@RustedOS)
- **CodePulse OS Dev**（YouTube）：手把手讲解 OS 开发
- **BrokenThorn Entertainment**：[http://www.brokenthorn.com/Resources/OSDevIndex.html](http://www.brokenthorn.com/Resources/OSDevIndex.html)

---

## A.3 工具文档

### QEMU
```bash
# 常用 QEMU 参数速查
qemu-system-i386 \
    -drive file=disk.img,format=raw \  # 磁盘镜像
    -m 32M \                           # 内存大小
    -display gtk \                     # 显示方式
    -serial stdio \                    # 串口重定向到终端（调试输出）
    -d int,cpu_reset \                 # 调试选项：打印中断和 CPU 重置
    -S \                               # 启动时暂停（等待 GDB）
    -gdb tcp::1234                     # GDB 服务器端口
```

### GDB 调试速查

```gdb
# 连接 QEMU
target remote localhost:1234

# 设置架构
set architecture i8086    # 实模式 16 位
set architecture i386     # 保护模式 32 位

# 断点
break *0x7C00             # 地址断点
break kernel_main         # 函数断点
info breakpoints          # 查看断点列表
delete 1                  # 删除断点 1

# 执行控制
continue                  # 继续运行
step / stepi              # 单步（s 进入函数，si 执行一条指令）
next / nexti              # 单步（n 不进入函数，ni 执行一条指令）
finish                    # 运行到函数返回

# 查看内存
x/10i $eip                # 查看 EIP 处的 10 条指令（反汇编）
x/32xb 0x7C00             # 查看 0x7C00 的 32 个字节（十六进制）
x/8xw $esp                # 查看栈顶 8 个双字

# 查看寄存器
info registers            # 所有寄存器
print $eax                # 单个寄存器
print/x $cr0              # 控制寄存器（十六进制）

# 查看变量
print variable_name       # 打印变量
print *ptr                # 解引用指针
print arr[3]              # 数组元素
```

### objdump / nm / readelf

```bash
# 反汇编内核 ELF
objdump -d kernel.elf | less

# 查看符号表
nm kernel.elf | sort | less

# 查看 ELF Program Headers
readelf -l kernel.elf

# 查看段信息
readelf -S kernel.elf

# 查看原始二进制
xxd kernel.bin | head -20
```

---

## A.4 常见错误与解决方案

### BIOS 不识别引导扇区
```
原因：最后两字节不是 0x55 0xAA，或扇区不足 512 字节
检查：xxd boot.bin | tail -2
修复：确认 times 510 - ($ - $$) db 0 和 dw 0xAA55
```

### 切换保护模式后屏幕无输出
```
原因：忘记更新数据段寄存器，或 VGA 地址错误
检查：切换后必须立即 mov ax, 0x10; mov ds, ax 等
修复：确认 VGA 地址 = 0xB8000，每字符 2 字节
```

### 内核跳转后三重错误/重启
```
原因：栈未设置、GDT 不正确、或跳转地址错误
调试：qemu -d int,cpu_reset 查看中断信息
     QEMU 串口输出: Triple fault at EIP=0x...
```

### kmalloc 总是返回 NULL
```
原因：堆未初始化，或堆内存已耗尽
检查：heap_init() 是否被调用，起始地址是否与内核冲突
修复：增大堆大小，或检查 PMM 是否正确初始化
```

### 中断不触发
```
原因：IDT 未加载、PIC 未初始化、或 IF 标志未设置
检查：确认 lidt 已执行，pic_init() 已调用，sti 已执行
调试：qemu -d int 观察中断发生情况
```

---

## A.5 进一步扩展方向

完成本教程后，可以继续探索以下方向：

### 内核完善
- [ ] SMP 多核支持（APIC 初始化，核间中断）
- [ ] 写时复制（Copy-on-Write）优化 fork
- [ ] 内存交换（Swap）到磁盘
- [ ] 信号机制（signal/kill）
- [ ] POSIX 完整性（select/poll/epoll）

### 文件系统
- [ ] EXT2/EXT4 文件系统
- [ ] 网络文件系统（NFS）
- [ ] tmpfs（内存文件系统）
- [ ] 日志文件系统（防止损坏）

### 驱动程序
- [ ] PCI 总线枚举与驱动框架
- [ ] USB HID 键鼠驱动
- [ ] E1000 网卡驱动 + TCP/IP 网络栈
- [ ] AHCI SATA 驱动
- [ ] VESA/GOP 图形显示

### 用户态
- [ ] 完整的 C 标准库（musl libc 移植）
- [ ] 动态链接器（ld.so）
- [ ] 图形界面（Xorg 协议、Wayland 协议）
- [ ] POSIX Shell（bash 移植）

### 安全
- [ ] 内核地址空间布局随机化（KASLR）
- [ ] 栈溢出保护（Stack Canary）
- [ ] 执行保护（NX/XD 位）
- [ ] 系统调用过滤（seccomp）

---

## A.6 本教程源码结构速查

```
MiniOS/
├── README.md              ← 总览和快速开始
├── Makefile               ← 构建脚本
├── boot/
│   ├── boot.asm           ← 第1章：MBR 一级引导器
│   └── loader.asm         ← 第1-2章：二级引导器（含保护模式切换）
├── kernel/
│   ├── kernel_entry.asm   ← 第3章：内核汇编入口
│   ├── main.c             ← 第3章：内核主函数
│   ├── main.h             ← 公共头文件（kprintf 等）
│   ├── kernel.ld          ← 链接脚本
│   ├── include/
│   │   └── stdint.h       ← 第3章：自制基础类型
│   ├── memory/
│   │   ├── pmm.c/h        ← 第4章：物理内存管理
│   │   ├── paging.c/h     ← 第4章：分页虚拟内存
│   │   └── heap.c/h       ← 第4章：kmalloc/kfree
│   ├── interrupt/
│   │   ├── idt.c/h        ← 第5章：IDT
│   │   ├── isr.asm        ← 第5章：中断汇编存根
│   │   ├── pic.c/h        ← 第5章：8259A PIC
│   │   └── timer.c/h      ← 第5章：PIT 定时器
│   ├── process/
│   │   ├── task.c/h       ← 第6章：进程管理
│   │   └── scheduler.c/h  ← 第6章：调度器
│   ├── fs/
│   │   ├── vfs.c/h        ← 第7章：虚拟文件系统
│   │   └── fat16.c/h      ← 第7章：FAT16 实现
│   ├── drivers/
│   │   ├── vga.c/h        ← 第8章：VGA 驱动
│   │   ├── keyboard.c/h   ← 第8章：键盘驱动
│   │   └── disk.c/h       ← 第8章：ATA 磁盘驱动
│   ├── syscall/
│   │   └── syscall.c/h    ← 第10章：系统调用
│   └── elf.c/h            ← 第11章：ELF 加载器
├── shell/
│   └── shell.c            ← 第9章：交互式 Shell
└── user/
    ├── libc/
    │   └── syscall.h      ← 第10章：用户态系统调用封装
    ├── user.ld            ← 用户态链接脚本
    └── programs/
        └── hello.c        ← 第11章：示例用户程序
```

---

*祝你的操作系统之旅愉快！💻*

*"The best way to understand a computer is to build one from scratch."*
