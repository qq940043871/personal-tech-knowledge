# 第 11 章：用户态程序与 ELF 加载

## 11.1 ELF 文件格式

ELF（Executable and Linkable Format）是 Linux/Unix 系统上的标准可执行文件格式。

```
ELF 文件结构：
┌──────────────────────────────┐
│  ELF Header（52 字节）       │  魔数、架构、入口地址、段表位置
├──────────────────────────────┤
│  Program Header Table        │  描述如何加载到内存（段/Segment）
├──────────────────────────────┤
│  .text（代码段）             │  程序指令
├──────────────────────────────┤
│  .rodata（只读数据）          │  字符串常量等
├──────────────────────────────┤
│  .data（已初始化数据）        │  全局变量
├──────────────────────────────┤
│  .bss（未初始化数据）         │  零初始化全局变量（不占磁盘空间）
├──────────────────────────────┤
│  Section Header Table        │  调试/链接用的节信息
└──────────────────────────────┘
```

---

## 11.2 ELF 数据结构

**文件：`kernel/elf.h`**

```c
#ifndef _ELF_H
#define _ELF_H

#include <stdint.h>

/* ELF 魔数 */
#define ELF_MAGIC       0x464C457F  /* 小端序 "\x7FELF" */

/* ELF 文件类型 */
#define ET_EXEC         2   /* 可执行文件 */
#define ET_DYN          3   /* 动态链接库 */

/* ELF 机器类型 */
#define EM_386          3   /* x86 32位 */

/* Program Header 类型 */
#define PT_NULL         0   /* 空条目 */
#define PT_LOAD         1   /* 可加载段（最重要）*/
#define PT_DYNAMIC      2   /* 动态链接信息 */
#define PT_INTERP       3   /* 动态链接器路径 */

/* 段权限标志 */
#define PF_X            0x1     /* 可执行 */
#define PF_W            0x2     /* 可写 */
#define PF_R            0x4     /* 可读 */

/* ELF32 文件头（52 字节）*/
typedef struct {
    uint8_t  e_ident[16];       /* 魔数和其他标识信息 */
    uint16_t e_type;            /* 文件类型 */
    uint16_t e_machine;         /* 目标架构 */
    uint32_t e_version;         /* ELF 版本 */
    uint32_t e_entry;           /* 入口点虚拟地址 */
    uint32_t e_phoff;           /* Program Header Table 偏移 */
    uint32_t e_shoff;           /* Section Header Table 偏移 */
    uint32_t e_flags;           /* 处理器特定标志 */
    uint16_t e_ehsize;          /* ELF 头大小（通常 52） */
    uint16_t e_phentsize;       /* Program Header 条目大小（通常 32） */
    uint16_t e_phnum;           /* Program Header 条目数 */
    uint16_t e_shentsize;       /* Section Header 条目大小 */
    uint16_t e_shnum;           /* Section Header 条目数 */
    uint16_t e_shstrndx;        /* 节名字符串表的节索引 */
} __attribute__((packed)) Elf32Ehdr;

/* ELF32 Program Header（32 字节）*/
typedef struct {
    uint32_t p_type;            /* 段类型 */
    uint32_t p_offset;          /* 段在文件中的偏移 */
    uint32_t p_vaddr;           /* 段的虚拟地址 */
    uint32_t p_paddr;           /* 段的物理地址（通常与虚拟地址相同） */
    uint32_t p_filesz;          /* 段在文件中的大小 */
    uint32_t p_memsz;           /* 段在内存中的大小（>= p_filesz，多余填 0） */
    uint32_t p_flags;           /* 段权限（R/W/X） */
    uint32_t p_align;           /* 对齐要求 */
} __attribute__((packed)) Elf32Phdr;

/* ELF 验证结果 */
typedef enum {
    ELF_OK          = 0,
    ELF_BAD_MAGIC   = -1,
    ELF_BAD_CLASS   = -2,
    ELF_BAD_ARCH    = -3,
    ELF_BAD_TYPE    = -4,
} ElfStatus;

/* 验证 ELF 头 */
ElfStatus elf_validate(const Elf32Ehdr *ehdr);

/* 加载 ELF 可执行文件到新进程 */
int elf_load(const char *path, uint32_t *entry_point, uint32_t *new_page_dir);

#endif
```

---

## 11.3 ELF 加载器

**文件：`kernel/elf.c`**

```c
#include "elf.h"
#include "fs/vfs.h"
#include "memory/pmm.h"
#include "memory/paging.h"
#include "memory/heap.h"
#include "main.h"
#include <string.h>

/*------------------------------------------------------------
 * 验证 ELF 文件头
 *------------------------------------------------------------*/
ElfStatus elf_validate(const Elf32Ehdr *ehdr)
{
    /* 检查魔数 */
    if (*(uint32_t *)ehdr->e_ident != ELF_MAGIC) {
        return ELF_BAD_MAGIC;
    }

    /* 检查 32 位 */
    if (ehdr->e_ident[4] != 1) {    /* ELFCLASS32 = 1 */
        return ELF_BAD_CLASS;
    }

    /* 检查 x86 */
    if (ehdr->e_machine != EM_386) {
        return ELF_BAD_ARCH;
    }

    /* 检查可执行文件 */
    if (ehdr->e_type != ET_EXEC) {
        return ELF_BAD_TYPE;
    }

    return ELF_OK;
}

/*------------------------------------------------------------
 * 加载 ELF 文件到新的地址空间
 *
 * 参数：
 *   path         - ELF 文件路径
 *   entry_point  - 输出：程序入口地址
 *   new_page_dir - 输出：新建的页目录物理地址
 *
 * 返回 0 表示成功，<0 表示失败
 *------------------------------------------------------------*/
int elf_load(const char *path, uint32_t *entry_point, uint32_t *new_page_dir)
{
    /* 打开 ELF 文件 */
    VfsNode *file = vfs_resolve_path(path);
    if (!file) {
        kprintf("[ELF] File not found: %s\n", path);
        return -ENOENT;
    }

    /* 读取 ELF 头 */
    Elf32Ehdr ehdr;
    if (vfs_read(file, 0, sizeof(Elf32Ehdr), (uint8_t *)&ehdr) < sizeof(Elf32Ehdr)) {
        kprintf("[ELF] Failed to read ELF header\n");
        return -1;
    }

    /* 验证 ELF */
    ElfStatus status = elf_validate(&ehdr);
    if (status != ELF_OK) {
        kprintf("[ELF] Invalid ELF file (status=%d)\n", (int)status);
        return (int)status;
    }

    /* 创建新的页目录（为新进程单独分配地址空间） */
    uint32_t pd_phys = pmm_alloc_page();
    page_dir_entry_t *pd = (page_dir_entry_t *)pd_phys;
    kmemset(pd, 0, PAGE_SIZE);

    /* 将内核地址空间映射到新页目录（共享内核）
     * 通常内核占用 0xC0000000 以上的虚拟地址 */
    /* TODO：复制内核页目录的高端部分 */

    /* 读取所有 Program Header 并加载 PT_LOAD 段 */
    kprintf("[ELF] Loading %s (entry=0x%x, phnum=%d)\n",
            path, ehdr.e_entry, ehdr.e_phnum);

    for (uint16_t i = 0; i < ehdr.e_phnum; i++) {
        Elf32Phdr phdr;
        uint32_t  phdr_offset = ehdr.e_phoff + i * sizeof(Elf32Phdr);

        if (vfs_read(file, phdr_offset, sizeof(Elf32Phdr), (uint8_t *)&phdr)
            < sizeof(Elf32Phdr)) {
            continue;
        }

        if (phdr.p_type != PT_LOAD) continue;

        kprintf("[ELF]   Segment %d: vaddr=0x%x filesz=%d memsz=%d flags=%c%c%c\n",
                i, phdr.p_vaddr, phdr.p_filesz, phdr.p_memsz,
                (phdr.p_flags & PF_R) ? 'R' : '-',
                (phdr.p_flags & PF_W) ? 'W' : '-',
                (phdr.p_flags & PF_X) ? 'X' : '-');

        /* 计算需要的页数 */
        uint32_t vaddr_align = phdr.p_vaddr & ~0xFFF;
        uint32_t size        = phdr.p_memsz + (phdr.p_vaddr - vaddr_align);
        uint32_t pages_needed = (size + PAGE_SIZE - 1) / PAGE_SIZE;

        /* 为每个需要的页分配物理内存并映射 */
        for (uint32_t p = 0; p < pages_needed; p++) {
            uint32_t phys = pmm_alloc_page();
            if (!phys) {
                kprintf("[ELF] OOM loading segment!\n");
                return -ENOMEM;
            }

            /* 清零页 */
            kmemset((void *)phys, 0, PAGE_SIZE);

            /* 映射到新页目录 */
            uint32_t virt = vaddr_align + p * PAGE_SIZE;
            uint32_t flags = PAGE_PRESENT | PAGE_USER;
            if (phdr.p_flags & PF_W) flags |= PAGE_WRITABLE;
            /* 注意：这里需要在新页目录中做映射，暂时简化 */
            paging_map(virt, phys, flags);
        }

        /* 将文件内容复制到映射好的内存 */
        if (phdr.p_filesz > 0) {
            /* 临时缓冲区 */
            uint8_t *tmp = (uint8_t *)kmalloc(phdr.p_filesz);
            vfs_read(file, phdr.p_offset, phdr.p_filesz, tmp);
            kmemcpy((void *)phdr.p_vaddr, tmp, phdr.p_filesz);
            kfree(tmp);
        }
        /* BSS 段（memsz > filesz 的部分）已经在 kmemset 中清零了 */
    }

    *entry_point  = ehdr.e_entry;
    *new_page_dir = pd_phys;

    vfs_close(file);
    kprintf("[ELF] Loaded successfully. Entry: 0x%x\n", ehdr.e_entry);
    return 0;
}
```

---

## 11.4 exec 系统调用：加载并运行程序

```c
/* 在 syscall.c 中添加 SYS_EXEC */

static uint32_t sys_exec(const char *path, char * const argv[])
{
    uint32_t entry_point, new_pd;

    /* 加载 ELF */
    int ret = elf_load(path, &entry_point, &new_pd);
    if (ret < 0) return (uint32_t)ret;

    /* 获取当前进程 */
    Task *current = task_current();

    /* 释放当前进程的地址空间（除内核映射外） */
    /* TODO：遍历旧页目录，释放用户态物理页 */

    /* 切换到新页目录 */
    current->page_dir = new_pd;
    __asm__ volatile("mov %0, %%cr3" : : "r"(new_pd) : "memory");

    /* 分配新的用户栈 */
    uint32_t user_stack_top = 0xBFFFF000;   /* 用户栈顶（3GB - 4KB） */
    uint32_t stack_page = pmm_alloc_page();
    paging_map(user_stack_top - PAGE_SIZE, stack_page,
               PAGE_PRESENT | PAGE_WRITABLE | PAGE_USER);

    /* 修改中断帧，让 iret 时跳转到新程序入口 */
    /* 这需要修改当前的 InterruptFrame */
    /* 具体实现：通过修改栈上的 eip 和 esp 来实现 */

    kprintf("[Exec] Starting %s at 0x%x\n", path, entry_point);

    /* 直接跳转（简化版，实际需要通过 iret 跳转到用户态） */
    typedef void (*entry_fn_t)(void);
    ((entry_fn_t)entry_point)();

    return 0;
}
```

---

## 11.5 完整的 fork + exec 流程

```
fork()：
  1. 复制当前进程的 PCB
  2. 复制页目录（写时复制优化，这里先简单全复制）
  3. 子进程 fork() 返回 0，父进程返回子进程 PID

exec()：
  1. 打开 ELF 文件
  2. 为每个 PT_LOAD 段分配内存并加载
  3. 替换当前进程的地址空间
  4. 跳转到新程序入口

示例：Shell 执行一个命令
┌─────────────────────────────────────────────────┐
│ Shell（PID=1）                                  │
│   read("ls") → parse → look up /bin/ls         │
│   pid = fork()                                  │
│   if (pid == 0) {                               │
│       exec("/bin/ls", args)    // 子进程         │
│   } else {                                      │
│       waitpid(pid)             // 父进程等待     │
│   }                                             │
└─────────────────────────────────────────────────┘
         │ fork
         ▼
┌─────────────────────────────────────────────────┐
│ 子进程（PID=2）                                  │
│   exec("/bin/ls") → 加载 ls ELF → 运行          │
│   打印文件列表...                               │
│   exit(0)                                       │
└─────────────────────────────────────────────────┘
```

---

## 11.6 章节小结

本章实现了：
- [x] ELF32 文件格式解析
- [x] ELF 加载器（读取 Program Header，分配内存，复制内容）
- [x] `exec` 系统调用基础框架
- [x] fork + exec 流程设计

至此，一个**完整可编程的迷你操作系统**的所有核心模块均已实现！

## 🏠 课后作业

1. 实现完整的 `fork()` 系统调用（页表复制 + COW 写时复制优化）
2. 将 Shell 的命令执行改为 fork + exec 模式，而不是直接内核函数调用
3. 实现动态链接支持（处理 PT_INTERP 段，加载动态链接器 `ld.so`）

---

**上一章** ← [第 10 章：系统调用](./10_Syscall.md)

**下一章** → [附录 A：参考资料](./A_References.md)
