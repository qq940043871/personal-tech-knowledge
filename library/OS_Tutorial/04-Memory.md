# 第 4 章：内存管理（分页/分段）

## 4.1 内存管理概述

内存管理是操作系统最核心的功能之一，主要解决三个问题：

1. **内存在哪里**：通过 E820 探测物理内存分布
2. **如何分配小内存**：堆分配器（`kmalloc` / `kfree`）
3. **如何隔离进程**：分页机制（每个进程独立的虚拟地址空间）

```
内存管理层次：
┌─────────────────────────────┐
│        用户态进程            │  虚拟地址（0x00000000 ~ 0xBFFFFFFF）
├─────────────────────────────┤
│  虚拟内存管理（VMM）         │  虚拟地址 ↔ 物理地址 映射
├─────────────────────────────┤
│  物理内存管理（PMM）         │  管理哪些物理页空闲/已用
├─────────────────────────────┤
│       物理内存               │  从 E820 获取真实可用区域
└─────────────────────────────┘
```

---

## 4.2 物理内存管理（PMM）

### 物理页帧

将物理内存划分为固定大小的**页帧**（Page Frame），每页 4KB：

```
物理内存：
┌────────────────────────────────────────────────────┐
│ 页帧0  │ 页帧1  │ 页帧2  │ 页帧3  │ ... │ 页帧N  │
│ 0~4KB  │ 4~8KB  │ 8~12KB │ ...    │     │        │
└────────────────────────────────────────────────────┘

管理方式：位图（Bitmap）
  每个 bit 代表一个页帧的状态：0 = 空闲，1 = 已使用
  4GB 内存 / 4KB 每页 = 1M 页帧 = 128KB 位图
```

### 实现 PMM

**文件：`kernel/memory/pmm.h`**

```c
#ifndef _PMM_H
#define _PMM_H

#include <stdint.h>

#define PAGE_SIZE       4096        /* 4KB */
#define PMM_BITMAP_ADDR 0x20000     /* 位图存放在物理地址 128KB 处 */

/* 内存区域类型（来自 BIOS E820） */
#define MEM_TYPE_USABLE     1
#define MEM_TYPE_RESERVED   2
#define MEM_TYPE_ACPI       3

/* E820 内存映射条目 */
typedef struct {
    uint64_t base;      /* 起始地址 */
    uint64_t length;    /* 长度 */
    uint32_t type;      /* 类型 */
    uint32_t acpi_attr; /* ACPI 扩展属性 */
} __attribute__((packed)) E820Entry;

/* 初始化物理内存管理器 */
void pmm_init(E820Entry *entries, uint32_t count);

/* 分配一个物理页帧，返回物理地址（失败返回 0） */
uint32_t pmm_alloc_page(void);

/* 释放一个物理页帧 */
void pmm_free_page(uint32_t physical_addr);

/* 查询空闲页帧数量 */
uint32_t pmm_free_page_count(void);

#endif
```

**文件：`kernel/memory/pmm.c`**

```c
#include "pmm.h"
#include "../main.h"    /* kprintf 等 */

/* 物理页帧位图（全局） */
static uint8_t  *pmm_bitmap;
static uint32_t  pmm_total_pages;
static uint32_t  pmm_free_pages;

/* 位图操作宏 */
#define PMM_BIT_SET(bit)    (pmm_bitmap[(bit) / 8] |=  (1 << ((bit) % 8)))
#define PMM_BIT_CLEAR(bit)  (pmm_bitmap[(bit) / 8] &= ~(1 << ((bit) % 8)))
#define PMM_BIT_TEST(bit)   (pmm_bitmap[(bit) / 8] &   (1 << ((bit) % 8)))

/* 地址 → 页帧号 */
#define ADDR_TO_PAGE(addr)  ((addr) / PAGE_SIZE)
/* 页帧号 → 地址 */
#define PAGE_TO_ADDR(page)  ((page) * PAGE_SIZE)

/*------------------------------------------------------------
 * 初始化物理内存管理器
 *------------------------------------------------------------*/
void pmm_init(E820Entry *entries, uint32_t count)
{
    /* 位图存放在固定地址 */
    pmm_bitmap = (uint8_t *)PMM_BITMAP_ADDR;

    /* 找出最大物理地址，确定总页数 */
    uint64_t max_addr = 0;
    for (uint32_t i = 0; i < count; i++) {
        uint64_t end = entries[i].base + entries[i].length;
        if (end > max_addr) max_addr = end;
    }
    pmm_total_pages = (uint32_t)(max_addr / PAGE_SIZE);
    pmm_free_pages  = 0;

    /* 默认将所有页标记为"已使用" */
    uint32_t bitmap_bytes = (pmm_total_pages + 7) / 8;
    for (uint32_t i = 0; i < bitmap_bytes; i++) {
        pmm_bitmap[i] = 0xFF;   /* 全部标记为已使用 */
    }

    /* 将 E820 报告的可用内存区域标记为"空闲" */
    for (uint32_t i = 0; i < count; i++) {
        if (entries[i].type == MEM_TYPE_USABLE) {
            uint32_t start_page = (uint32_t)(entries[i].base / PAGE_SIZE);
            uint32_t page_count = (uint32_t)(entries[i].length / PAGE_SIZE);

            for (uint32_t p = start_page; p < start_page + page_count; p++) {
                if (p < pmm_total_pages) {
                    PMM_BIT_CLEAR(p);
                    pmm_free_pages++;
                }
            }
        }
    }

    /* 保护低 1MB 内存（内核、Loader、VGA 等都在这里） */
    for (uint32_t p = 0; p < ADDR_TO_PAGE(0x100000); p++) {
        PMM_BIT_SET(p);
    }

    /* 保护位图自身占用的内存 */
    uint32_t bitmap_pages = (bitmap_bytes + PAGE_SIZE - 1) / PAGE_SIZE;
    uint32_t bitmap_start = ADDR_TO_PAGE(PMM_BITMAP_ADDR);
    for (uint32_t p = bitmap_start; p < bitmap_start + bitmap_pages; p++) {
        PMM_BIT_SET(p);
    }

    kprintf("[PMM] Total pages: ");
    kprint_int(pmm_total_pages);
    kprintf(", Free pages: ");
    kprint_int(pmm_free_pages);
    kprintf(" (");
    kprint_int(pmm_free_pages * 4 / 1024);
    kprintf(" MB)\n");
}

/*------------------------------------------------------------
 * 分配一个物理页（首次适配算法）
 *------------------------------------------------------------*/
uint32_t pmm_alloc_page(void)
{
    /* 从第 256 页（1MB 之后）开始搜索空闲页 */
    for (uint32_t p = 256; p < pmm_total_pages; p++) {
        if (!PMM_BIT_TEST(p)) {
            PMM_BIT_SET(p);     /* 标记为已使用 */
            pmm_free_pages--;
            return PAGE_TO_ADDR(p);
        }
    }
    return 0;   /* 内存不足 */
}

/*------------------------------------------------------------
 * 释放一个物理页
 *------------------------------------------------------------*/
void pmm_free_page(uint32_t physical_addr)
{
    uint32_t page = ADDR_TO_PAGE(physical_addr);
    if (page < pmm_total_pages && PMM_BIT_TEST(page)) {
        PMM_BIT_CLEAR(page);
        pmm_free_pages++;
    }
}

uint32_t pmm_free_page_count(void)
{
    return pmm_free_pages;
}
```

---

## 4.3 分页机制（Virtual Memory）

### x86 二级分页结构

```
虚拟地址（32位）：
┌────────────┬────────────┬────────────┐
│ 页目录索引  │ 页表索引   │  页内偏移  │
│  Bits 31-22│ Bits 21-12 │ Bits 11-0  │
│  (10 bits) │ (10 bits)  │ (12 bits)  │
└────────────┴────────────┴────────────┘
      │              │           │
      ▼              ▼           │
  页目录（PD）    页表（PT）      │
  1024 项        1024 项         │
  每项 4 字节    每项 4 字节     │
      │              │           │
      └──> 页表基址  └──> 物理页基址 + 偏移 = 物理地址

CR3 寄存器 → 页目录物理基地址
```

### 页目录/页表条目格式

```
31                  12 11  9  8  7  6  5  4  3  2  1  0
┌─────────────────────┬───┬──┬──┬──┬──┬──┬──┬──┬──┬──┐
│  物理页帧地址[31:12] │ 保│ G│ S│ D│ A│CD│WT│US│RW│ P│
└─────────────────────┴───┴──┴──┴──┴──┴──┴──┴──┴──┴──┘

P  (Present)    : 1 = 页存在于内存中
RW (Read/Write) : 0 = 只读, 1 = 可读写
US (User/Super) : 0 = 内核, 1 = 用户可访问
A  (Accessed)   : CPU 访问过该页时自动置 1
D  (Dirty)      : CPU 写入该页时自动置 1
```

### 实现分页

**文件：`kernel/memory/paging.h`**

```c
#ifndef _PAGING_H
#define _PAGING_H

#include <stdint.h>

#define PAGE_SIZE           4096
#define PAGE_PRESENT        0x01    /* 页存在 */
#define PAGE_WRITABLE       0x02    /* 可写 */
#define PAGE_USER           0x04    /* 用户态可访问 */

/* 页目录和页表的条目数 */
#define PAGE_DIR_ENTRIES    1024
#define PAGE_TABLE_ENTRIES  1024

/* 类型定义 */
typedef uint32_t page_dir_entry_t;
typedef uint32_t page_table_entry_t;

/* 虚拟地址拆分宏 */
#define VADDR_PD_INDEX(va)  (((va) >> 22) & 0x3FF)
#define VADDR_PT_INDEX(va)  (((va) >> 12) & 0x3FF)
#define VADDR_OFFSET(va)    ((va) & 0xFFF)

/* 初始化分页 */
void paging_init(void);

/* 映射虚拟地址到物理地址 */
void paging_map(uint32_t virtual_addr, uint32_t physical_addr, uint32_t flags);

/* 解除映射 */
void paging_unmap(uint32_t virtual_addr);

/* 虚拟地址转物理地址 */
uint32_t paging_virt_to_phys(uint32_t virtual_addr);

/* 创建新的页目录（用于新进程） */
page_dir_entry_t *paging_create_page_dir(void);

#endif
```

**文件：`kernel/memory/paging.c`**

```c
#include "paging.h"
#include "pmm.h"
#include "../main.h"
#include <string.h>     /* 自制的 memset */

/* 内核页目录（物理地址） */
static page_dir_entry_t *kernel_page_dir;

/*------------------------------------------------------------
 * 在指定页目录中映射一个虚拟页到物理页
 *------------------------------------------------------------*/
static void _map_page(page_dir_entry_t *pd,
                      uint32_t virtual_addr,
                      uint32_t physical_addr,
                      uint32_t flags)
{
    uint32_t pd_idx = VADDR_PD_INDEX(virtual_addr);
    uint32_t pt_idx = VADDR_PT_INDEX(virtual_addr);

    page_table_entry_t *pt;

    /* 如果页表不存在，分配并创建 */
    if (!(pd[pd_idx] & PAGE_PRESENT)) {
        uint32_t pt_phys = pmm_alloc_page();
        if (!pt_phys) {
            kernel_panic("paging: out of memory for page table");
            return;
        }
        pt = (page_table_entry_t *)pt_phys;
        kmemset(pt, 0, PAGE_SIZE);
        pd[pd_idx] = pt_phys | PAGE_PRESENT | PAGE_WRITABLE | (flags & PAGE_USER);
    } else {
        pt = (page_table_entry_t *)(pd[pd_idx] & ~0xFFF);
    }

    /* 写入页表条目 */
    pt[pt_idx] = (physical_addr & ~0xFFF) | flags | PAGE_PRESENT;

    /* 刷新 TLB */
    __asm__ volatile("invlpg (%0)" : : "r"(virtual_addr) : "memory");
}

/*------------------------------------------------------------
 * 初始化内核分页（恒等映射低 4MB）
 *------------------------------------------------------------*/
void paging_init(void)
{
    /* 分配内核页目录（必须是页对齐的物理内存） */
    uint32_t pd_phys = pmm_alloc_page();
    kernel_page_dir = (page_dir_entry_t *)pd_phys;
    kmemset(kernel_page_dir, 0, PAGE_SIZE);

    /* 恒等映射（Identity Mapping）前 4MB 内存
     * 虚拟地址 0x00000000 ~ 0x003FFFFF = 物理地址 0x00000000 ~ 0x003FFFFF
     * 这样内核代码可以继续使用当前地址运行 */
    for (uint32_t addr = 0; addr < 4 * 1024 * 1024; addr += PAGE_SIZE) {
        _map_page(kernel_page_dir, addr, addr,
                  PAGE_PRESENT | PAGE_WRITABLE);
    }

    /* 同时将内核映射到虚拟地址高端（0xC0000000 起，即 3GB）
     * 最终内核将运行在高端地址（Higher Half Kernel）
     * 这里先做简单恒等映射 */

    /* 加载页目录地址到 CR3，开启分页 */
    __asm__ volatile(
        "mov %0, %%cr3\n"       /* 设置 CR3 = 页目录物理地址 */
        "mov %%cr0, %%eax\n"
        "or $0x80000000, %%eax\n"   /* 设置 CR0.PG 位（开启分页） */
        "mov %%eax, %%cr0\n"
        : : "r"(pd_phys) : "eax", "memory"
    );

    kprintf("[VMM] Paging enabled. Kernel page dir at: ");
    kprint_hex(pd_phys);
    kprintf("\n");
}

/*------------------------------------------------------------
 * 公开接口：映射虚拟地址
 *------------------------------------------------------------*/
void paging_map(uint32_t virtual_addr, uint32_t physical_addr, uint32_t flags)
{
    _map_page(kernel_page_dir, virtual_addr, physical_addr, flags);
}
```

---

## 4.4 内核堆分配器（kmalloc / kfree）

### 实现一个简单的堆分配器

使用**链表式分配**（First-Fit 策略）：

**文件：`kernel/memory/heap.h`**

```c
#ifndef _HEAP_H
#define _HEAP_H

#include <stdint.h>

/* 初始化堆（起始地址，大小） */
void heap_init(uint32_t start_addr, uint32_t size);

/* 分配内存 */
void *kmalloc(size_t size);

/* 分配并清零内存 */
void *kzalloc(size_t size);

/* 释放内存 */
void kfree(void *ptr);

#endif
```

**文件：`kernel/memory/heap.c`**

```c
#include "heap.h"
#include "../main.h"
#include <string.h>

/*
 * 堆内存块头部结构
 * 每次分配时在数据前面附加这个头部
 */
typedef struct HeapBlock {
    size_t             size;    /* 数据区大小（不含头部） */
    uint8_t            used;    /* 0 = 空闲, 1 = 已使用 */
    struct HeapBlock  *next;    /* 链表下一个块 */
    struct HeapBlock  *prev;    /* 链表上一个块 */
} HeapBlock;

static HeapBlock *heap_start = NULL;
static uint32_t   heap_end   = 0;

#define HEAP_BLOCK_SIZE  sizeof(HeapBlock)
#define HEAP_MIN_SPLIT   32     /* 块分裂的最小剩余大小 */

/*------------------------------------------------------------
 * 初始化堆
 *------------------------------------------------------------*/
void heap_init(uint32_t start_addr, uint32_t size)
{
    heap_start = (HeapBlock *)start_addr;
    heap_end   = start_addr + size;

    /* 创建初始大块 */
    heap_start->size = size - HEAP_BLOCK_SIZE;
    heap_start->used = 0;
    heap_start->next = NULL;
    heap_start->prev = NULL;

    kprintf("[Heap] Initialized at 0x");
    kprint_hex(start_addr);
    kprintf(", size = ");
    kprint_int(size / 1024);
    kprintf(" KB\n");
}

/*------------------------------------------------------------
 * 分配内存（First-Fit 策略）
 *------------------------------------------------------------*/
void *kmalloc(size_t size)
{
    if (!size || !heap_start) return NULL;

    /* 对齐到 4 字节 */
    size = (size + 3) & ~3;

    /* 遍历链表，找第一个足够大的空闲块 */
    HeapBlock *block = heap_start;
    while (block) {
        if (!block->used && block->size >= size) {
            /* 找到了！尝试分裂 */
            if (block->size >= size + HEAP_BLOCK_SIZE + HEAP_MIN_SPLIT) {
                /* 分裂成两块 */
                HeapBlock *new_block = (HeapBlock *)((uint8_t *)block
                                        + HEAP_BLOCK_SIZE + size);
                new_block->size = block->size - size - HEAP_BLOCK_SIZE;
                new_block->used = 0;
                new_block->next = block->next;
                new_block->prev = block;

                if (block->next) {
                    block->next->prev = new_block;
                }
                block->next = new_block;
                block->size = size;
            }

            block->used = 1;
            return (void *)((uint8_t *)block + HEAP_BLOCK_SIZE);
        }
        block = block->next;
    }

    kernel_panic("kmalloc: out of heap memory!");
    return NULL;
}

/*------------------------------------------------------------
 * 分配并清零内存
 *------------------------------------------------------------*/
void *kzalloc(size_t size)
{
    void *ptr = kmalloc(size);
    if (ptr) kmemset(ptr, 0, size);
    return ptr;
}

/*------------------------------------------------------------
 * 释放内存（并合并相邻空闲块）
 *------------------------------------------------------------*/
void kfree(void *ptr)
{
    if (!ptr) return;

    HeapBlock *block = (HeapBlock *)((uint8_t *)ptr - HEAP_BLOCK_SIZE);
    block->used = 0;

    /* 与后继块合并 */
    if (block->next && !block->next->used) {
        block->size += HEAP_BLOCK_SIZE + block->next->size;
        block->next  = block->next->next;
        if (block->next) block->next->prev = block;
    }

    /* 与前驱块合并 */
    if (block->prev && !block->prev->used) {
        block->prev->size += HEAP_BLOCK_SIZE + block->size;
        block->prev->next  = block->next;
        if (block->next) block->next->prev = block->prev;
    }
}
```

---

## 4.5 在内核主函数中初始化内存

更新 `kernel/main.c`：

```c
/* 全局变量：E820 内存映射（从 Loader 传递过来） */
#define MEM_MAP_ADDR    0x8000      /* Loader 将 E820 数据存放在这个地址 */

void kernel_main(void)
{
    vga_clear();
    kprintf("===========================================\n");
    kprintf("  MiniOS - Memory Management\n");
    kprintf("===========================================\n\n");

    /* 1. 初始化物理内存管理 */
    E820Entry *mem_map = (E820Entry *)MEM_MAP_ADDR;
    uint16_t   mem_count = *(uint16_t *)(MEM_MAP_ADDR - 2);
    pmm_init(mem_map, mem_count);

    /* 2. 初始化分页 */
    paging_init();

    /* 3. 初始化内核堆（从 3MB 开始，大小 4MB） */
    heap_init(0x300000, 4 * 1024 * 1024);

    /* 4. 测试内存分配 */
    kprintf("\n[Test] Testing kmalloc/kfree...\n");

    int *arr = (int *)kmalloc(10 * sizeof(int));
    if (arr) {
        for (int i = 0; i < 10; i++) arr[i] = i * i;
        kprintf("[Test] kmalloc OK: arr[9] = ");
        kprint_int(arr[9]);
        kprintf("\n");
        kfree(arr);
        kprintf("[Test] kfree OK\n");
    }

    kprintf("\n[Kernel] Memory system ready!\n");

    while (1) __asm__ volatile("hlt");
}
```

---

## 4.6 章节小结

本章实现了：
- [x] 物理内存管理（PMM）：位图分配器
- [x] 虚拟内存管理（VMM）：x86 二级分页
- [x] 内核堆分配器：`kmalloc` / `kfree`
- [x] 在内核中集成内存初始化

## 🏠 课后作业

1. 实现 `kmalloc` 的内存统计：记录已分配/空闲内存量
2. 为分页机制添加按需分配（Page Fault 处理，见第5章）
3. 实现 `paging_virt_to_phys()` 函数，通过遍历页表查找物理地址

---

**上一章** ← [第 3 章：内核入口](./03_Kernel_Entry.md)

**下一章** → [第 5 章：中断与异常处理](./05_Interrupts.md)
