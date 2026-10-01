# 第 6 章：进程管理与任务调度

## 6.1 进程概念

**进程（Process）**：程序的一次运行实例，拥有独立的内存空间、寄存器状态、文件描述符等资源。

```
进程控制块（PCB = Process Control Block）：
┌─────────────────────────────────────┐
│  PID（进程 ID）                      │
│  状态（Running / Ready / Blocked）   │
│  程序计数器（EIP）                    │
│  寄存器快照（EAX,EBX,...,ESP,EBP）   │
│  内存映射（页目录地址 CR3）           │
│  内核栈（Ring 0 时使用的栈）          │
│  文件描述符表                         │
│  优先级                              │
│  时间片计数                           │
│  父进程 PID                          │
└─────────────────────────────────────┘
```

---

## 6.2 进程状态机

```
                  schedule()
   创建 ─────────────▶ 就绪（Ready）
                          │    ▲
                 dispatch │    │ preempt/yield
                          ▼    │
                       运行（Running）
                          │
              等待事件     │    事件发生
   阻塞（Blocked）◀────────┘────────────▶ 就绪
        │
        └────── 僵尸（Zombie）──── 父进程 wait() ──▶ 消亡
```

---

## 6.3 进程控制块实现

**文件：`kernel/process/task.h`**

```c
#ifndef _TASK_H
#define _TASK_H

#include <stdint.h>

#define MAX_TASKS       64
#define KERNEL_STACK_SIZE   8192    /* 每个进程的内核栈 8KB */
#define USER_STACK_SIZE     16384   /* 用户栈 16KB */
#define MAX_FILES_PER_PROC  32      /* 每个进程最多打开 32 个文件 */

/* 进程状态枚举 */
typedef enum {
    TASK_READY    = 0,
    TASK_RUNNING  = 1,
    TASK_BLOCKED  = 2,
    TASK_ZOMBIE   = 3,
    TASK_DEAD     = 4,
} TaskState;

/* CPU 寄存器快照（上下文切换时保存/恢复） */
typedef struct {
    uint32_t edi, esi, ebp;
    uint32_t ebx, edx, ecx, eax;
    uint32_t eip;           /* 下次恢复执行的地址 */
    uint32_t cs;
    uint32_t eflags;
    uint32_t esp;           /* 用户栈指针 */
    uint32_t ss;
} CpuContext;

/* 进程控制块 */
typedef struct Task {
    uint32_t    pid;            /* 进程 ID */
    uint32_t    parent_pid;     /* 父进程 ID */
    TaskState   state;          /* 当前状态 */
    uint8_t     priority;       /* 优先级（0=最高，255=最低） */
    int32_t     time_slice;     /* 剩余时间片（定时器 tick 数） */
    CpuContext  context;        /* CPU 上下文 */
    uint32_t    page_dir;       /* 页目录物理地址（CR3） */
    uint32_t    kernel_stack;   /* 内核栈底部地址 */
    uint32_t    kernel_esp;     /* 内核栈当前 ESP */
    char        name[32];       /* 进程名称 */
    struct Task *next;          /* 就绪队列链表 */
    void       *files[MAX_FILES_PER_PROC];  /* 文件描述符表 */
} Task;

/* 创建内核线程 */
Task *task_create_kernel(const char *name,
                         void (*entry)(void),
                         uint8_t priority);

/* 创建用户进程 */
Task *task_create_user(const char *name,
                       uint32_t entry_vaddr,
                       uint32_t page_dir,
                       uint8_t  priority);

/* 退出当前进程 */
void task_exit(int32_t exit_code);

/* 根据 PID 查找进程 */
Task *task_find(uint32_t pid);

/* 获取当前正在运行的进程 */
Task *task_current(void);

#endif
```

**文件：`kernel/process/task.c`**

```c
#include "task.h"
#include "scheduler.h"
#include "../memory/heap.h"
#include "../memory/paging.h"
#include "../main.h"
#include <string.h>

/* 全局进程表 */
static Task   *task_table[MAX_TASKS];
static uint32_t next_pid = 1;

/* 当前正在运行的进程 */
static Task *current_task = NULL;

/*------------------------------------------------------------
 * 创建内核线程
 *------------------------------------------------------------*/
Task *task_create_kernel(const char *name,
                         void (*entry)(void),
                         uint8_t priority)
{
    /* 分配 PCB */
    Task *task = (Task *)kzalloc(sizeof(Task));
    if (!task) return NULL;

    /* 分配内核栈 */
    task->kernel_stack = (uint32_t)kmalloc(KERNEL_STACK_SIZE);
    if (!task->kernel_stack) {
        kfree(task);
        return NULL;
    }

    /* 设置基本属性 */
    task->pid        = next_pid++;
    task->parent_pid = current_task ? current_task->pid : 0;
    task->state      = TASK_READY;
    task->priority   = priority;
    task->time_slice = (256 - priority) / 4 + 1;
    task->page_dir   = /* 内核页目录 */ 0;

    /* 复制进程名 */
    int i;
    for (i = 0; name[i] && i < 31; i++) task->name[i] = name[i];
    task->name[i] = '\0';

    /* 初始化内核栈
     * 预先在栈上布置好一个"假的"中断返回帧，
     * 这样第一次被调度时，就像从中断返回一样开始执行 */
    uint32_t *stack_top = (uint32_t *)(task->kernel_stack + KERNEL_STACK_SIZE);

    *(--stack_top) = 0x00000010;    /* SS（内核数据段） */
    *(--stack_top) = (uint32_t)(task->kernel_stack + KERNEL_STACK_SIZE); /* ESP */
    *(--stack_top) = 0x00000202;    /* EFLAGS（IF=1，允许中断） */
    *(--stack_top) = 0x00000008;    /* CS（内核代码段） */
    *(--stack_top) = (uint32_t)entry;  /* EIP（入口地址） */

    /* pushad 寄存器（8 个，初始全为 0） */
    for (int i = 0; i < 8; i++) *(--stack_top) = 0;

    task->kernel_esp = (uint32_t)stack_top;

    /* 注册到进程表 */
    for (int i = 0; i < MAX_TASKS; i++) {
        if (!task_table[i]) {
            task_table[i] = task;
            break;
        }
    }

    /* 加入就绪队列 */
    scheduler_add_task(task);

    kprintf("[Task] Created kernel task '%s' (PID=%d)\n",
            task->name, task->pid);

    return task;
}

Task *task_current(void)
{
    return current_task;
}

void task_set_current(Task *task)
{
    current_task = task;
}
```

---

## 6.4 轮转调度器（Round-Robin）

**文件：`kernel/process/scheduler.c`**

```c
#include "scheduler.h"
#include "task.h"
#include "../interrupt/timer.h"
#include "../interrupt/idt.h"
#include "../main.h"

/* 就绪队列（循环链表） */
static Task *ready_head = NULL;     /* 队列头 */
static Task *ready_tail = NULL;     /* 队列尾 */
static Task *idle_task  = NULL;     /* 空闲任务（当没有其他任务时运行） */

/*------------------------------------------------------------
 * 添加任务到就绪队列
 *------------------------------------------------------------*/
void scheduler_add_task(Task *task)
{
    task->state = TASK_READY;
    task->next  = NULL;

    if (!ready_head) {
        ready_head = ready_tail = task;
    } else {
        ready_tail->next = task;
        ready_tail = task;
    }
}

/*------------------------------------------------------------
 * 从就绪队列移除任务
 *------------------------------------------------------------*/
static void remove_from_ready(Task *task)
{
    if (ready_head == task) {
        ready_head = task->next;
        if (ready_tail == task) ready_tail = NULL;
        return;
    }

    Task *prev = ready_head;
    while (prev && prev->next != task) prev = prev->next;
    if (prev) {
        prev->next = task->next;
        if (ready_tail == task) ready_tail = prev;
    }
    task->next = NULL;
}

/*------------------------------------------------------------
 * 上下文切换（汇编实现）
 * 保存当前任务的 ESP，加载下一个任务的 ESP
 *------------------------------------------------------------*/
void switch_context(uint32_t *old_esp, uint32_t new_esp);

__asm__(
    ".global switch_context\n"
    "switch_context:\n"
    "    push %ebp\n"
    "    push %ebx\n"
    "    push %esi\n"
    "    push %edi\n"
    "    pushfl\n"
    /* 保存当前 ESP */
    "    mov 24(%esp), %eax\n"      /* 参数 old_esp */
    "    mov %esp, (%eax)\n"
    /* 加载新 ESP */
    "    mov 28(%esp), %esp\n"      /* 参数 new_esp */
    /* 恢复寄存器 */
    "    popfl\n"
    "    pop %edi\n"
    "    pop %esi\n"
    "    pop %ebx\n"
    "    pop %ebp\n"
    "    ret\n"
);

/*------------------------------------------------------------
 * 调度器主函数：选择下一个要运行的任务
 *------------------------------------------------------------*/
void scheduler_schedule(void)
{
    Task *current = task_current();
    Task *next    = NULL;

    /* 在就绪队列中找下一个任务 */
    if (ready_head) {
        next = ready_head;
        remove_from_ready(next);
    } else {
        next = idle_task;   /* 队列为空，运行空闲任务 */
    }

    if (!next || next == current) return;

    /* 如果当前任务还在运行，重新加入队列尾部（Round-Robin） */
    if (current && current->state == TASK_RUNNING) {
        current->state = TASK_READY;
        scheduler_add_task(current);
    }

    /* 切换到新任务 */
    next->state = TASK_RUNNING;
    task_set_current(next);

    /* 执行上下文切换 */
    switch_context(&current->kernel_esp, next->kernel_esp);
}

/*------------------------------------------------------------
 * 定时器中断触发的调度
 *------------------------------------------------------------*/
void scheduler_tick(void)
{
    Task *current = task_current();
    if (!current) return;

    current->time_slice--;
    if (current->time_slice <= 0) {
        /* 时间片耗尽，重新设置并触发调度 */
        current->time_slice = (256 - current->priority) / 4 + 1;
        scheduler_schedule();
    }
}

/*------------------------------------------------------------
 * 空闲任务（CPU 无事可做时执行）
 *------------------------------------------------------------*/
static void idle_task_func(void)
{
    while (1) {
        __asm__ volatile("hlt");    /* CPU 睡眠，等待下一个中断 */
    }
}

/*------------------------------------------------------------
 * 初始化调度器
 *------------------------------------------------------------*/
void scheduler_init(void)
{
    /* 创建空闲任务（最低优先级） */
    idle_task = task_create_kernel("idle", idle_task_func, 255);

    kprintf("[Scheduler] Round-Robin scheduler initialized\n");
}
```

---

## 6.5 在内核中使用多任务

```c
/* 示例：创建多个内核任务 */

static void task_a(void)
{
    int count = 0;
    while (1) {
        if (count % 100 == 0) {
            kprintf("[Task A] Running, count=%d\n", count);
        }
        count++;
        /* 主动让出 CPU */
        scheduler_schedule();
    }
}

static void task_b(void)
{
    while (1) {
        kprintf("[Task B] Hello from task B!\n");
        sleep_ms(1000);     /* 睡眠 1 秒 */
    }
}

void kernel_main(void)
{
    /* ... 其他初始化 ... */

    /* 初始化调度器 */
    scheduler_init();

    /* 创建内核任务 */
    task_create_kernel("task_a", task_a, 100);
    task_create_kernel("task_b", task_b, 100);

    /* 开启中断，调度器开始工作 */
    __asm__ volatile("sti");

    /* 主循环（会被调度器打断） */
    while (1) __asm__ volatile("hlt");
}
```

---

## 6.6 TSS（任务状态段）

当从用户态（Ring 3）切换到内核态（Ring 0）时，CPU 需要知道内核栈在哪里，这由 TSS（Task State Segment）提供：

```c
/* TSS 结构（x86 32位，只使用关键字段） */
typedef struct {
    uint32_t prev_tss;
    uint32_t esp0;      /* Ring 0 的栈指针（重要！） */
    uint32_t ss0;       /* Ring 0 的栈段（重要！） */
    /* ... 其他字段（全部置 0）... */
    uint8_t  iomap_base[8192 / 8];  /* I/O 权限位图 */
} __attribute__((packed)) TSS;

static TSS kernel_tss;

void tss_init(void)
{
    /* 清零 TSS */
    kmemset(&kernel_tss, 0, sizeof(TSS));

    /* 设置 Ring 0 栈 */
    kernel_tss.ss0  = 0x10;     /* 内核数据段 */
    kernel_tss.esp0 = 0;        /* 由任务切换时动态更新 */

    /* 将 TSS 添加到 GDT（第 5 项，索引 4） */
    gdt_add_tss_entry(4, (uint32_t)&kernel_tss, sizeof(TSS));

    /* 加载 TR（Task Register） */
    __asm__ volatile("ltr %%ax" : : "a"(0x20 | 0x3));  /* 0x20 = TSS 选择子 */

    kprintf("[TSS] Task State Segment initialized\n");
}

/* 任务切换时更新 TSS 的 esp0 */
void tss_update_esp0(uint32_t new_esp0)
{
    kernel_tss.esp0 = new_esp0;
}
```

---

## 6.7 章节小结

本章实现了：
- [x] 进程控制块（PCB）数据结构
- [x] 内核任务创建
- [x] 汇编级上下文切换
- [x] 轮转调度算法（Round-Robin）
- [x] 基于定时器的抢占式调度
- [x] TSS 初始化（用户态支持基础）

## 🏠 课后作业

1. 实现 `task_sleep(ms)` 函数：阻塞当前任务，ms 毫秒后唤醒
2. 实现优先级调度：将就绪队列改为按优先级排序的优先队列
3. 实现 `wait()` 和 `exit()` 系统调用，让父进程可以等待子进程结束并获取退出码

---

**上一章** ← [第 5 章：中断处理](./05_Interrupts.md)

**下一章** → [第 7 章：文件系统](./07_FileSystem.md)
