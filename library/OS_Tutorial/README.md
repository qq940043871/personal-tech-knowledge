# 从零开始设计一个可编程操作系统

> **教程定位**：面向有 C 语言基础的开发者，从零开始，一步步构建一个运行在 x86 架构上的迷你操作系统（MiniOS）。
> 
> **目标成果**：一个支持多任务调度、内存管理、文件系统、驱动程序，并配有交互式 Shell 的**可编程操作系统内核**。

---

## 📚 教程目录

| 章节 | 内容 | 难度 |
|------|------|------|
| [第 0 章](./00_Prerequisites.md) | 前置知识与工具准备 | ⭐ |
| [第 1 章](./01_Bootloader.md) | 编写 Bootloader 引导程序 | ⭐⭐ |
| [第 2 章](./02_ProtectedMode.md) | 进入保护模式 | ⭐⭐⭐ |
| [第 3 章](./03_Kernel_Entry.md) | 内核入口与 C 语言环境 | ⭐⭐⭐ |
| [第 4 章](./04_Memory.md) | 内存管理（分页/分段） | ⭐⭐⭐⭐ |
| [第 5 章](./05_Interrupts.md) | 中断与异常处理 | ⭐⭐⭐⭐ |
| [第 6 章](./06_Process.md) | 进程管理与任务调度 | ⭐⭐⭐⭐ |
| [第 7 章](./07_FileSystem.md) | 文件系统设计与实现 | ⭐⭐⭐⭐ |
| [第 8 章](./08_Drivers.md) | 设备驱动程序（键盘/磁盘/显示器） | ⭐⭐⭐ |
| [第 9 章](./09_Shell.md) | 编写交互式 Shell | ⭐⭐⭐ |
| [第 10 章](./10_Syscall.md) | 系统调用接口设计 | ⭐⭐⭐⭐ |
| [第 11 章](./11_UserPrograms.md) | 用户态程序与 ELF 加载 | ⭐⭐⭐⭐⭐ |
| [附录 A](./A_References.md) | 参考资料与延伸阅读 | — |

---

## 🏗️ 项目最终架构

```
MiniOS/
├── boot/
│   ├── boot.asm          # MBR 引导扇区（512 字节）
│   └── loader.asm        # 二级引导器（加载内核）
├── kernel/
│   ├── kernel_entry.asm  # 内核汇编入口
│   ├── main.c            # 内核 C 语言主函数
│   ├── memory/
│   │   ├── gdt.c         # 全局描述符表
│   │   ├── paging.c      # 分页管理
│   │   └── heap.c        # 堆内存分配
│   ├── interrupt/
│   │   ├── idt.c         # 中断描述符表
│   │   └── isr.asm       # 中断服务例程
│   ├── process/
│   │   ├── scheduler.c   # 进程调度器
│   │   └── task.c        # 任务管理
│   ├── fs/
│   │   ├── vfs.c         # 虚拟文件系统
│   │   └── fat16.c       # FAT16 文件系统
│   └── drivers/
│       ├── keyboard.c    # 键盘驱动
│       ├── disk.c        # 磁盘驱动（ATA）
│       └── vga.c         # VGA 文字模式驱动
├── shell/
│   └── shell.c           # 交互式 Shell
├── user/
│   ├── libc/             # 迷你 C 标准库
│   └── programs/         # 用户态程序示例
├── Makefile              # 构建脚本
└── run.sh                # QEMU 启动脚本
```

---

## 🔧 技术栈

- **架构**：x86 (32-bit Protected Mode)
- **汇编**：NASM
- **内核语言**：C (GCC 交叉编译)
- **构建工具**：GNU Make
- **仿真环境**：QEMU
- **调试工具**：GDB + QEMU 远程调试

---

## ⚡ 快速开始

```bash
# 1. 安装依赖（Ubuntu/Debian）
sudo apt install nasm gcc make qemu-system-x86 gdb

# 2. 克隆/创建项目目录
mkdir MiniOS && cd MiniOS

# 3. 按照教程章节依次编写代码

# 4. 构建并运行
make && make run
```

---

## 📖 阅读建议

1. **按章节顺序阅读**，每章都依赖前面章节的成果
2. **动手敲代码**，不要只看不练
3. 遇到问题先查[附录 A](./A_References.md) 的参考资料
4. 每章末尾有**作业题**，做完再进入下一章

---

*本教程覆盖约 5000 行代码，完整实现一个可编程的迷你操作系统内核。*
