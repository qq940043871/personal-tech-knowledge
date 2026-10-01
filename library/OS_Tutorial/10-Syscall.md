# 第 10 章：系统调用接口设计

## 10.1 系统调用概念

**系统调用（Syscall）**：用户态程序请求内核服务的唯一合法通道。

```
用户程序（Ring 3）        内核（Ring 0）
      │                        │
      │  int 0x80 / SYSENTER  │
      │ ─────────────────────►│
      │  传递参数（寄存器）     │  执行内核服务
      │                        │  （文件I/O、进程控制等）
      │◄─────────────────────  │
      │  返回结果（EAX）        │
```

### Linux 兼容的调用约定

我们参考 Linux i386 系统调用约定：

| 寄存器 | 用途 |
|--------|------|
| EAX    | 系统调用号 |
| EBX    | 参数 1 |
| ECX    | 参数 2 |
| EDX    | 参数 3 |
| ESI    | 参数 4 |
| EDI    | 参数 5 |
| EAX    | 返回值（调用结束后） |

---

## 10.2 系统调用号定义

**文件：`kernel/syscall/syscall.h`**

```c
#ifndef _SYSCALL_H
#define _SYSCALL_H

#include <stdint.h>

/* 系统调用号（参考 Linux 编号） */
#define SYS_EXIT        1
#define SYS_FORK        2
#define SYS_READ        3
#define SYS_WRITE       4
#define SYS_OPEN        5
#define SYS_CLOSE       6
#define SYS_WAITPID     7
#define SYS_CREAT       8
#define SYS_GETPID      20
#define SYS_GETPPID     64
#define SYS_SLEEP       162     /* 自定义 */
#define SYS_YIELD       163     /* 自定义：主动让出 CPU */
#define SYS_MMAP        90
#define SYS_MUNMAP      91

/* 错误码 */
#define ENOENT      2   /* No such file or directory */
#define EBADF       9   /* Bad file descriptor */
#define ENOMEM      12  /* Out of memory */
#define EACCES      13  /* Permission denied */
#define EINVAL      22  /* Invalid argument */

/* 文件打开标志（用户态使用） */
#define O_RDONLY    0x0001
#define O_WRONLY    0x0002
#define O_RDWR      0x0003
#define O_CREAT     0x0100
#define O_TRUNC     0x0200
#define O_APPEND    0x0400

/* 标准文件描述符 */
#define STDIN_FILENO    0
#define STDOUT_FILENO   1
#define STDERR_FILENO   2

/* 初始化系统调用处理 */
void syscall_init(void);

/* 系统调用分发函数（被 isr128 调用） */
uint32_t syscall_dispatch(uint32_t num, uint32_t arg1, uint32_t arg2,
                          uint32_t arg3, uint32_t arg4, uint32_t arg5);

#endif
```

---

## 10.3 系统调用实现

**文件：`kernel/syscall/syscall.c`**

```c
#include "syscall.h"
#include "../interrupt/idt.h"
#include "../process/task.h"
#include "../process/scheduler.h"
#include "../fs/vfs.h"
#include "../drivers/vga.h"
#include "../memory/heap.h"
#include <stdint.h>

/*------------------------------------------------------------
 * 各系统调用的具体实现
 *------------------------------------------------------------*/

/* SYS_EXIT：终止进程 */
static uint32_t sys_exit(uint32_t exit_code)
{
    task_exit((int32_t)exit_code);
    /* task_exit 不会返回 */
    return 0;
}

/* SYS_GETPID：获取当前进程 PID */
static uint32_t sys_getpid(void)
{
    Task *current = task_current();
    return current ? current->pid : 0;
}

/* SYS_GETPPID：获取父进程 PID */
static uint32_t sys_getppid(void)
{
    Task *current = task_current();
    return current ? current->parent_pid : 0;
}

/* SYS_WRITE：向文件描述符写数据 */
static uint32_t sys_write(int fd, const void *buf, size_t count)
{
    Task *current = task_current();

    /* 标准输出：直接写 VGA */
    if (fd == STDOUT_FILENO || fd == STDERR_FILENO) {
        const char *str = (const char *)buf;
        for (size_t i = 0; i < count; i++) {
            vga_putchar(str[i]);
        }
        return (uint32_t)count;
    }

    /* 其他文件描述符 */
    if (fd < 0 || fd >= MAX_FILES_PER_PROC) return (uint32_t)-EBADF;
    VfsNode *node = (VfsNode *)current->files[fd];
    if (!node) return (uint32_t)-EBADF;

    return vfs_write(node, 0, (uint32_t)count, (const uint8_t *)buf);
}

/* SYS_READ：从文件描述符读数据 */
static uint32_t sys_read(int fd, void *buf, size_t count)
{
    Task *current = task_current();

    /* 标准输入：从键盘读 */
    if (fd == STDIN_FILENO) {
        char *out = (char *)buf;
        size_t n = 0;
        while (n < count) {
            char c = keyboard_getchar();
            out[n++] = c;
            if (c == '\n') break;
        }
        return (uint32_t)n;
    }

    if (fd < 0 || fd >= MAX_FILES_PER_PROC) return (uint32_t)-EBADF;
    VfsNode *node = (VfsNode *)current->files[fd];
    if (!node) return (uint32_t)-EBADF;

    return vfs_read(node, 0, (uint32_t)count, (uint8_t *)buf);
}

/* SYS_OPEN：打开文件，返回文件描述符 */
static uint32_t sys_open(const char *path, int flags)
{
    Task *current = task_current();

    VfsNode *node = vfs_open(path, (uint32_t)flags);
    if (!node) return (uint32_t)-ENOENT;

    /* 找一个空闲的文件描述符槽 */
    for (int i = 3; i < MAX_FILES_PER_PROC; i++) {
        if (!current->files[i]) {
            current->files[i] = node;
            return (uint32_t)i;
        }
    }

    vfs_close(node);
    return (uint32_t)-EINVAL;
}

/* SYS_CLOSE：关闭文件描述符 */
static uint32_t sys_close(int fd)
{
    Task *current = task_current();
    if (fd < 3 || fd >= MAX_FILES_PER_PROC) return (uint32_t)-EBADF;

    VfsNode *node = (VfsNode *)current->files[fd];
    if (!node) return (uint32_t)-EBADF;

    vfs_close(node);
    current->files[fd] = NULL;
    return 0;
}

/* SYS_SLEEP：睡眠指定毫秒数 */
static uint32_t sys_sleep(uint32_t ms)
{
    sleep_ms(ms);
    return 0;
}

/* SYS_YIELD：主动让出 CPU */
static uint32_t sys_yield(void)
{
    scheduler_schedule();
    return 0;
}

/*------------------------------------------------------------
 * 系统调用分发表
 *------------------------------------------------------------*/
typedef uint32_t (*syscall_fn_t)(uint32_t, uint32_t, uint32_t,
                                 uint32_t, uint32_t);

static syscall_fn_t syscall_table[256] = {
    [SYS_EXIT]    = (syscall_fn_t)sys_exit,
    [SYS_GETPID]  = (syscall_fn_t)sys_getpid,
    [SYS_GETPPID] = (syscall_fn_t)sys_getppid,
    [SYS_WRITE]   = (syscall_fn_t)sys_write,
    [SYS_READ]    = (syscall_fn_t)sys_read,
    [SYS_OPEN]    = (syscall_fn_t)sys_open,
    [SYS_CLOSE]   = (syscall_fn_t)sys_close,
    [SYS_SLEEP]   = (syscall_fn_t)sys_sleep,
    [SYS_YIELD]   = (syscall_fn_t)sys_yield,
};

/*------------------------------------------------------------
 * 系统调用分发入口（由 INT 0x80 的处理函数调用）
 *------------------------------------------------------------*/
uint32_t syscall_dispatch(uint32_t num, uint32_t arg1, uint32_t arg2,
                          uint32_t arg3, uint32_t arg4, uint32_t arg5)
{
    if (num >= 256 || !syscall_table[num]) {
        kprintf("[Syscall] Unknown syscall #%d\n", num);
        return (uint32_t)-EINVAL;
    }
    return syscall_table[num](arg1, arg2, arg3, arg4, arg5);
}

/*------------------------------------------------------------
 * 对接 IDT 的中断处理函数
 *------------------------------------------------------------*/
static void syscall_handler(InterruptFrame *frame)
{
    uint32_t result = syscall_dispatch(
        frame->eax,     /* 系统调用号 */
        frame->ebx,     /* 参数 1 */
        frame->ecx,     /* 参数 2 */
        frame->edx,     /* 参数 3 */
        frame->esi,     /* 参数 4 */
        frame->edi      /* 参数 5 */
    );

    /* 将返回值存入 EAX（iret 后用户程序从 EAX 读取结果） */
    frame->eax = result;
}

void syscall_init(void)
{
    /* 注册 INT 0x80（DPL=3，用户态可调用） */
    register_interrupt_handler(0x80, syscall_handler);
    kprintf("[Syscall] System call interface initialized\n");
}
```

---

## 10.4 用户态系统调用库（libc 精简版）

用户程序不直接用 `int 0x80`，而是通过封装好的 C 函数调用：

**文件：`user/libc/syscall.h`**

```c
#ifndef _USER_SYSCALL_H
#define _USER_SYSCALL_H

#include <stdint.h>

/* 系统调用包装宏 */
#define SYSCALL0(num) ({                    \
    uint32_t _ret;                          \
    __asm__ volatile(                       \
        "int $0x80"                         \
        : "=a"(_ret)                        \
        : "a"(num)                          \
        : "memory");                        \
    _ret; })

#define SYSCALL1(num, a1) ({                \
    uint32_t _ret;                          \
    __asm__ volatile(                       \
        "int $0x80"                         \
        : "=a"(_ret)                        \
        : "a"(num), "b"(a1)                 \
        : "memory");                        \
    _ret; })

#define SYSCALL2(num, a1, a2) ({            \
    uint32_t _ret;                          \
    __asm__ volatile(                       \
        "int $0x80"                         \
        : "=a"(_ret)                        \
        : "a"(num), "b"(a1), "c"(a2)        \
        : "memory");                        \
    _ret; })

#define SYSCALL3(num, a1, a2, a3) ({        \
    uint32_t _ret;                          \
    __asm__ volatile(                       \
        "int $0x80"                         \
        : "=a"(_ret)                        \
        : "a"(num), "b"(a1), "c"(a2),       \
          "d"(a3)                           \
        : "memory");                        \
    _ret; })

/* 用户态 C 函数封装 */
static inline void _exit(int code) {
    SYSCALL1(1, code);
}

static inline int getpid(void) {
    return (int)SYSCALL0(20);
}

static inline int write(int fd, const void *buf, uint32_t count) {
    return (int)SYSCALL3(4, fd, (uint32_t)buf, count);
}

static inline int read(int fd, void *buf, uint32_t count) {
    return (int)SYSCALL3(3, fd, (uint32_t)buf, count);
}

static inline int open(const char *path, int flags) {
    return (int)SYSCALL2(5, (uint32_t)path, flags);
}

static inline int close(int fd) {
    return (int)SYSCALL1(6, fd);
}

static inline void sleep(uint32_t ms) {
    SYSCALL1(162, ms);
}

static inline void yield(void) {
    SYSCALL0(163);
}

/* 简单的 printf 实现（用于用户程序） */
static inline int puts(const char *s) {
    int len = 0;
    while (s[len]) len++;
    return write(1, s, len);
}

#endif
```

---

## 10.5 用户态程序示例

**文件：`user/programs/hello.c`**

```c
/* 第一个用户态程序：Hello World */
#include "../libc/syscall.h"

int main(void)
{
    puts("Hello from user space!\n");
    puts("My PID is: ");

    /* 打印 PID */
    int pid = getpid();
    char buf[12];
    int i = 0;
    if (pid == 0) { buf[i++] = '0'; }
    else {
        int tmp = pid;
        while (tmp > 0) { buf[i++] = '0' + tmp % 10; tmp /= 10; }
        /* 反转 */
        for (int l = 0, r = i - 1; l < r; l++, r--) {
            char t = buf[l]; buf[l] = buf[r]; buf[r] = t;
        }
    }
    buf[i++] = '\n';
    write(1, buf, i);

    _exit(0);
    return 0;
}
```

**编译用户程序：**

```makefile
# 编译用户程序（完全独立，不链接任何标准库）
user/programs/hello.bin: user/programs/hello.c
	$(CC) -m32 -ffreestanding -fno-stack-protector \
	      -nostdlib -nostdinc \
	      -I user/libc \
	      -T user/user.ld \
	      -o $@ $<
```

**用户态链接脚本 `user/user.ld`：**

```ld
ENTRY(main)
SECTIONS
{
    . = 0x80000000;    /* 用户程序加载到 2GB 虚拟地址 */
    .text  : { *(.text) }
    .rodata : { *(.rodata*) }
    .data  : { *(.data) }
    .bss   : { __bss_start = .; *(.bss) *(COMMON); __bss_end = .; }
}
```

---

## 10.6 章节小结

本章实现了：
- [x] INT 0x80 系统调用接口
- [x] 系统调用号定义（兼容 Linux 编号）
- [x] 核心系统调用：exit, getpid, read, write, open, close, sleep, yield
- [x] 用户态 libc 系统调用封装
- [x] 第一个用户态程序

## 🏠 课后作业

1. 实现 `SYS_FORK` 系统调用（复制当前进程的页目录，创建子进程）
2. 实现 `SYS_EXEC` 系统调用（加载 ELF 文件替换当前进程的地址空间）
3. 将系统调用升级为 `SYSENTER/SYSEXIT` 机制（比 INT 0x80 快 3-5 倍）

---

**上一章** ← [第 9 章：Shell](./09_Shell.md)

**下一章** → [第 11 章：用户态程序与 ELF 加载](./11_UserPrograms.md)
