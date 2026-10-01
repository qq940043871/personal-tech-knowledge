# 第 7 章：文件系统设计与实现

## 7.1 文件系统架构

```
应用程序
    │
    │ open/read/write/close
    ▼
虚拟文件系统（VFS）层
    │ 统一接口，屏蔽底层差异
    ├──────────────────┬─────────────────┐
    ▼                  ▼                 ▼
FAT16 文件系统     EXT2 文件系统     tmpfs（内存文件系统）
    │
    ▼
磁盘驱动（ATA）
```

---

## 7.2 VFS（虚拟文件系统）接口

**文件：`kernel/fs/vfs.h`**

```c
#ifndef _VFS_H
#define _VFS_H

#include <stdint.h>

#define MAX_FILESYSTEMS     8
#define MAX_MOUNT_POINTS    16
#define MAX_PATH_LEN        256
#define MAX_OPEN_FILES      256

/* 文件类型 */
#define VFS_FILE        0x01    /* 普通文件 */
#define VFS_DIRECTORY   0x02    /* 目录 */
#define VFS_SYMLINK     0x04    /* 符号链接 */
#define VFS_CHARDEV     0x08    /* 字符设备 */
#define VFS_BLOCKDEV    0x10    /* 块设备 */

/* 文件打开模式 */
#define O_RDONLY    0x0001
#define O_WRONLY    0x0002
#define O_RDWR      0x0003
#define O_CREAT     0x0100
#define O_TRUNC     0x0200
#define O_APPEND    0x0400

/* 文件节点（inode）*/
typedef struct VfsNode {
    char     name[256];         /* 文件名 */
    uint32_t flags;             /* 文件类型标志 */
    uint32_t inode_no;          /* inode 号 */
    uint32_t size;              /* 文件大小（字节） */
    uint32_t uid, gid;          /* 用户/组 ID */
    uint32_t permissions;       /* 权限位 */
    uint32_t atime, mtime, ctime; /* 访问/修改/创建时间 */

    /* 操作函数指针（多态） */
    uint32_t (*read)  (struct VfsNode*, uint32_t offset, uint32_t size, uint8_t *buf);
    uint32_t (*write) (struct VfsNode*, uint32_t offset, uint32_t size, const uint8_t *buf);
    struct VfsNode *(*open)   (struct VfsNode*);
    void            (*close)  (struct VfsNode*);
    struct Dirent  *(*readdir)(struct VfsNode*, uint32_t index);
    struct VfsNode *(*finddir)(struct VfsNode*, const char *name);

    /* 私有数据（由具体文件系统使用） */
    void    *private_data;
    struct VfsNode *mount_point;  /* 如果是挂载点，指向真实文件系统根 */
} VfsNode;

/* 目录条目 */
typedef struct Dirent {
    char     name[256];
    uint32_t inode_no;
} Dirent;

/* 文件描述符 */
typedef struct {
    VfsNode *node;
    uint32_t offset;    /* 当前读写位置 */
    uint32_t flags;     /* 打开模式 */
    int      ref_count; /* 引用计数 */
} FileDescriptor;

/* VFS 初始化 */
void vfs_init(void);

/* 挂载文件系统 */
int vfs_mount(const char *path, VfsNode *root);

/* 文件操作 */
VfsNode *vfs_open(const char *path, uint32_t flags);
void     vfs_close(VfsNode *node);
uint32_t vfs_read(VfsNode *node, uint32_t offset, uint32_t size, uint8_t *buf);
uint32_t vfs_write(VfsNode *node, uint32_t offset, uint32_t size, const uint8_t *buf);

/* 目录操作 */
VfsNode *vfs_opendir(const char *path);
Dirent  *vfs_readdir(VfsNode *dir, uint32_t index);
VfsNode *vfs_finddir(VfsNode *dir, const char *name);

/* 路径解析 */
VfsNode *vfs_resolve_path(const char *path);

#endif
```

**文件：`kernel/fs/vfs.c`**

```c
#include "vfs.h"
#include "../memory/heap.h"
#include "../main.h"

static VfsNode *vfs_root = NULL;    /* 根节点 "/" */

void vfs_init(void)
{
    kprintf("[VFS] Virtual File System initialized\n");
}

void vfs_mount(const char *path, VfsNode *root)
{
    if (path[0] == '/' && path[1] == '\0') {
        vfs_root = root;
        kprintf("[VFS] Mounted root filesystem\n");
    }
    /* TODO：支持其他挂载点 */
}

uint32_t vfs_read(VfsNode *node, uint32_t offset, uint32_t size, uint8_t *buf)
{
    if (node && node->read) {
        return node->read(node, offset, size, buf);
    }
    return 0;
}

uint32_t vfs_write(VfsNode *node, uint32_t offset, uint32_t size, const uint8_t *buf)
{
    if (node && node->write) {
        return node->write(node, offset, size, buf);
    }
    return 0;
}

/* 路径解析（简化版，仅支持绝对路径） */
VfsNode *vfs_resolve_path(const char *path)
{
    if (!vfs_root || !path || path[0] != '/') return NULL;

    VfsNode *current = vfs_root;
    if (path[1] == '\0') return current;   /* 根目录 */

    /* 分解路径并逐级查找 */
    char component[256];
    const char *p = path + 1;

    while (*p) {
        /* 提取路径分量 */
        int i = 0;
        while (*p && *p != '/' && i < 255) {
            component[i++] = *p++;
        }
        component[i] = '\0';
        if (*p == '/') p++;

        /* 在当前目录中查找 */
        if (current->finddir) {
            current = current->finddir(current, component);
        } else {
            return NULL;
        }

        if (!current) return NULL;
    }

    return current;
}
```

---

## 7.3 FAT16 文件系统实现

### FAT16 磁盘布局

```
FAT16 磁盘布局（软盘/小硬盘）：
┌─────────────────────────────────────────────────────┐
│  扇区 0：引导扇区（Boot Sector）                     │
│    - BPB（BIOS 参数块）：磁盘几何参数                │
├─────────────────────────────────────────────────────┤
│  扇区 1 ~ N：FAT 表（File Allocation Table）         │
│    - 记录每个簇的状态（空闲/已用/坏块/结束）         │
│    - FAT1 和 FAT2（备份）                            │
├─────────────────────────────────────────────────────┤
│  扇区 N+1 ~ M：根目录区                              │
│    - 固定大小的目录项数组（每项 32 字节）             │
├─────────────────────────────────────────────────────┤
│  扇区 M+1 ~ 末尾：数据区                             │
│    - 文件内容按簇存储（FAT 链表串联）                 │
└─────────────────────────────────────────────────────┘
```

**文件：`kernel/fs/fat16.h`**

```c
#ifndef _FAT16_H
#define _FAT16_H

#include <stdint.h>
#include "vfs.h"

/* FAT16 引导扇区/BPB 结构 */
typedef struct {
    uint8_t  jmp_boot[3];       /* 跳转指令 */
    char     oem_name[8];       /* OEM 名称 */
    uint16_t bytes_per_sector;  /* 每扇区字节数（通常 512） */
    uint8_t  sectors_per_cluster; /* 每簇扇区数 */
    uint16_t reserved_sectors;  /* 保留扇区数（包含引导扇区） */
    uint8_t  num_fats;          /* FAT 表数量（通常 2） */
    uint16_t root_entry_count;  /* 根目录条目数 */
    uint16_t total_sectors_16;  /* 总扇区数（<32MB 时使用） */
    uint8_t  media_type;        /* 介质类型 */
    uint16_t sectors_per_fat;   /* 每个 FAT 表的扇区数 */
    uint16_t sectors_per_track; /* 每磁道扇区数 */
    uint16_t num_heads;         /* 磁头数 */
    uint32_t hidden_sectors;    /* 隐藏扇区数 */
    uint32_t total_sectors_32;  /* 总扇区数（≥32MB 时使用） */

    /* FAT16 扩展引导记录 */
    uint8_t  drive_number;
    uint8_t  reserved1;
    uint8_t  boot_signature;    /* 0x29 = 有效签名 */
    uint32_t volume_id;
    char     volume_label[11];
    char     fs_type[8];        /* "FAT16   " */
} __attribute__((packed)) Fat16BPB;

/* FAT16 目录条目（32 字节） */
typedef struct {
    char     name[8];           /* 文件名（8.3 格式，不含点） */
    char     ext[3];            /* 扩展名 */
    uint8_t  attributes;        /* 属性位 */
    uint8_t  reserved;
    uint8_t  create_time_tenth; /* 创建时间（10ms 精度） */
    uint16_t create_time;
    uint16_t create_date;
    uint16_t last_access_date;
    uint16_t first_cluster_high;/* FAT32 高 16 位（FAT16 不用） */
    uint16_t last_write_time;
    uint16_t last_write_date;
    uint16_t first_cluster;     /* 首簇号 */
    uint32_t file_size;         /* 文件大小 */
} __attribute__((packed)) Fat16DirEntry;

/* 属性位 */
#define FAT_ATTR_READ_ONLY  0x01
#define FAT_ATTR_HIDDEN     0x02
#define FAT_ATTR_SYSTEM     0x04
#define FAT_ATTR_VOLUME_ID  0x08
#define FAT_ATTR_DIRECTORY  0x10
#define FAT_ATTR_ARCHIVE    0x20
#define FAT_ATTR_LONG_NAME  0x0F    /* 长文件名条目 */

/* FAT16 文件系统私有数据 */
typedef struct {
    Fat16BPB   bpb;             /* 引导扇区参数 */
    uint32_t   fat_start;       /* FAT 表起始扇区 */
    uint32_t   root_dir_start;  /* 根目录起始扇区 */
    uint32_t   data_start;      /* 数据区起始扇区 */
    uint16_t  *fat_cache;       /* FAT 表缓存 */
} Fat16FS;

/* 初始化 FAT16 文件系统 */
VfsNode *fat16_init(uint32_t disk_start_sector);

/* 格式化为 FAT16 */
int fat16_format(uint32_t disk_start_sector, uint32_t total_sectors);

#endif
```

**文件：`kernel/fs/fat16.c`（核心实现）**

```c
#include "fat16.h"
#include "../drivers/disk.h"
#include "../memory/heap.h"
#include "../main.h"
#include <string.h>

/* 读取一个扇区到缓冲区 */
static void read_sector(uint32_t lba, void *buf)
{
    disk_read_sectors(lba, 1, buf);
}

/* 获取 FAT 链中指定簇的下一个簇 */
static uint16_t fat16_next_cluster(Fat16FS *fs, uint16_t cluster)
{
    return fs->fat_cache[cluster];
}

/* FAT16 特殊值 */
#define FAT16_FREE      0x0000
#define FAT16_BAD       0xFFF7
#define FAT16_EOC       0xFFF8  /* 簇链结束 */

/* 簇号转扇区号 */
static uint32_t cluster_to_lba(Fat16FS *fs, uint16_t cluster)
{
    return fs->data_start + (cluster - 2) * fs->bpb.sectors_per_cluster;
}

/*------------------------------------------------------------
 * 读取文件数据
 *------------------------------------------------------------*/
static uint32_t fat16_read(VfsNode *node, uint32_t offset,
                            uint32_t size, uint8_t *buf)
{
    Fat16FS *fs = (Fat16FS *)node->private_data;
    uint16_t cluster = (uint16_t)(uintptr_t)node->mount_point; /* 首簇号 */

    uint32_t cluster_size = fs->bpb.sectors_per_cluster * 512;
    uint32_t bytes_read   = 0;

    /* 跳过 offset 之前的簇 */
    while (offset >= cluster_size && cluster < 0xFFF8) {
        offset  -= cluster_size;
        cluster  = fat16_next_cluster(fs, cluster);
    }

    /* 逐簇读取 */
    static uint8_t sector_buf[512];
    while (bytes_read < size && cluster < 0xFFF8) {
        uint32_t lba = cluster_to_lba(fs, cluster);

        for (uint8_t s = 0; s < fs->bpb.sectors_per_cluster && bytes_read < size; s++) {
            read_sector(lba + s, sector_buf);

            uint32_t to_copy = 512 - offset;
            if (to_copy > size - bytes_read) to_copy = size - bytes_read;

            kmemcpy(buf + bytes_read, sector_buf + offset, to_copy);
            bytes_read += to_copy;
            offset = 0;
        }

        cluster = fat16_next_cluster(fs, cluster);
    }

    return bytes_read;
}

/*------------------------------------------------------------
 * 在目录中查找文件
 *------------------------------------------------------------*/
static VfsNode *fat16_finddir(VfsNode *dir, const char *name)
{
    Fat16FS *fs = (Fat16FS *)dir->private_data;

    Fat16DirEntry entry;
    uint32_t lba = (dir == NULL) ? fs->root_dir_start :
                   cluster_to_lba(fs, (uint16_t)(uintptr_t)dir->mount_point);

    /* 构建 8.3 格式的比较名 */
    char name83[12] = "           ";
    int  dot_pos    = -1;
    for (int i = 0; name[i]; i++) {
        if (name[i] == '.') { dot_pos = i; break; }
    }
    int base_len = dot_pos >= 0 ? dot_pos : (int)kstrlen(name);
    for (int i = 0; i < base_len && i < 8; i++) {
        name83[i] = (name[i] >= 'a' && name[i] <= 'z') ?
                    name[i] - 32 : name[i];
    }
    if (dot_pos >= 0) {
        for (int i = 0; name[dot_pos + 1 + i] && i < 3; i++) {
            char c = name[dot_pos + 1 + i];
            name83[8 + i] = (c >= 'a' && c <= 'z') ? c - 32 : c;
        }
    }

    /* 遍历目录条目 */
    for (uint32_t i = 0; i < fs->bpb.root_entry_count; i++) {
        uint32_t sec    = lba + (i * 32) / 512;
        uint32_t offset = (i * 32) % 512;

        static uint8_t buf[512];
        read_sector(sec, buf);
        kmemcpy(&entry, buf + offset, 32);

        if (entry.name[0] == 0x00) break;      /* 目录结束 */
        if (entry.name[0] == 0xE5) continue;   /* 已删除 */
        if (entry.attributes == FAT_ATTR_LONG_NAME) continue;

        /* 比较文件名 */
        char entry_name[12];
        kmemcpy(entry_name, entry.name, 8);
        kmemcpy(entry_name + 8, entry.ext, 3);
        entry_name[11] = '\0';

        if (kmemcmp(name83, entry_name, 11) == 0) {
            /* 找到了！创建 VfsNode */
            VfsNode *node = (VfsNode *)kzalloc(sizeof(VfsNode));
            kmemcpy(node->name, name, kstrlen(name) + 1);
            node->size         = entry.file_size;
            node->inode_no     = entry.first_cluster;
            node->private_data = fs;
            node->mount_point  = (VfsNode *)(uintptr_t)entry.first_cluster;

            if (entry.attributes & FAT_ATTR_DIRECTORY) {
                node->flags    = VFS_DIRECTORY;
                node->finddir  = fat16_finddir;
                node->readdir  = fat16_readdir;
            } else {
                node->flags    = VFS_FILE;
                node->read     = fat16_read;
            }

            return node;
        }
    }

    return NULL;    /* 未找到 */
}

/*------------------------------------------------------------
 * 初始化 FAT16
 *------------------------------------------------------------*/
VfsNode *fat16_init(uint32_t disk_start_sector)
{
    Fat16FS *fs = (Fat16FS *)kzalloc(sizeof(Fat16FS));

    /* 读取引导扇区 */
    static uint8_t boot_buf[512];
    disk_read_sectors(disk_start_sector, 1, boot_buf);
    kmemcpy(&fs->bpb, boot_buf, sizeof(Fat16BPB));

    /* 计算各区域起始位置 */
    fs->fat_start     = disk_start_sector + fs->bpb.reserved_sectors;
    fs->root_dir_start = fs->fat_start + fs->bpb.num_fats * fs->bpb.sectors_per_fat;
    uint32_t root_dir_sectors = (fs->bpb.root_entry_count * 32 + 511) / 512;
    fs->data_start    = fs->root_dir_start + root_dir_sectors;

    /* 缓存 FAT 表到内存 */
    uint32_t fat_size = fs->bpb.sectors_per_fat * 512;
    fs->fat_cache = (uint16_t *)kmalloc(fat_size);
    disk_read_sectors(fs->fat_start, fs->bpb.sectors_per_fat,
                      (uint8_t *)fs->fat_cache);

    kprintf("[FAT16] Volume: '%.11s', %d bytes/sector, %d sect/cluster\n",
            fs->bpb.volume_label,
            fs->bpb.bytes_per_sector,
            fs->bpb.sectors_per_cluster);

    /* 创建根目录 VfsNode */
    VfsNode *root = (VfsNode *)kzalloc(sizeof(VfsNode));
    kmemcpy(root->name, "/", 2);
    root->flags        = VFS_DIRECTORY;
    root->private_data = fs;
    root->finddir      = fat16_finddir;
    root->readdir      = fat16_readdir;

    return root;
}
```

---

## 7.4 在内核中挂载文件系统

```c
/* kernel/main.c 中的文件系统初始化 */
void kernel_main(void)
{
    /* ... 其他初始化 ... */

    /* 初始化 VFS */
    vfs_init();

    /* 初始化磁盘驱动（第8章）*/
    disk_init();

    /* 挂载 FAT16 根文件系统（从磁盘分区1开始） */
    VfsNode *fat16_root = fat16_init(2048);  /* 扇区 2048 = 第一个分区 */
    vfs_mount("/", fat16_root);

    /* 测试文件系统 */
    kprintf("[Test] Listing root directory:\n");
    VfsNode *root = vfs_resolve_path("/");
    if (root) {
        for (uint32_t i = 0; ; i++) {
            Dirent *de = vfs_readdir(root, i);
            if (!de) break;
            kprintf("  [%d] %s\n", i, de->name);
        }
    }

    /* 测试读文件 */
    VfsNode *file = vfs_resolve_path("/README.TXT");
    if (file) {
        uint8_t buf[256] = {0};
        uint32_t n = vfs_read(file, 0, sizeof(buf) - 1, buf);
        kprintf("[Test] README.TXT (%d bytes):\n%s\n", n, (char *)buf);
        vfs_close(file);
    }
}
```

---

## 7.5 章节小结

本章实现了：
- [x] VFS（虚拟文件系统）抽象层
- [x] FAT16 文件系统实现（读取部分）
- [x] 目录遍历与文件查找
- [x] 文件读取（按簇遍历）
- [x] 路径解析

## 🏠 课后作业

1. 实现 FAT16 的文件写入（需要分配新簇并更新 FAT 表）
2. 实现 `fat16_format()` 函数，在裸磁盘上创建一个全新的 FAT16 文件系统
3. 为 VFS 添加 `pipe()` 支持（匿名管道），用于进程间通信

---

**上一章** ← [第 6 章：进程管理](./06_Process.md)

**下一章** → [第 8 章：设备驱动程序](./08_Drivers.md)
