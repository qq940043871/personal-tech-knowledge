# 第 9 章：编写交互式 Shell

## 9.1 Shell 是什么？

Shell 是用户与操作系统之间的**命令解释器**。它：
1. 读取用户输入
2. 解析命令和参数
3. 查找并执行对应程序
4. 显示输出结果

```
用户键入 "ls -l /home"
    │
    ▼
Shell 读取输入（keyboard_getchar）
    │
    ▼
解析：命令 = "ls"，参数 = ["-l", "/home"]
    │
    ▼
在文件系统中查找 /bin/ls
    │
    ▼
fork() 创建子进程 → exec() 加载执行
    │
    ▼
等待子进程结束（wait）
    │
    ▼
显示结果，打印提示符，等待下一条命令
```

---

## 9.2 Shell 核心实现

**文件：`shell/shell.c`**

```c
/*============================================================
 * shell.c - MiniOS 交互式 Shell
 *============================================================*/

#include "shell.h"
#include "../kernel/drivers/vga.h"
#include "../kernel/drivers/keyboard.h"
#include "../kernel/fs/vfs.h"
#include "../kernel/memory/heap.h"
#include "../kernel/process/task.h"
#include <stdint.h>

#define SHELL_MAX_INPUT     256     /* 最大输入长度 */
#define SHELL_MAX_ARGS      16      /* 最大参数数量 */
#define SHELL_HISTORY_SIZE  32      /* 历史命令数量 */
#define SHELL_PROMPT        "MiniOS> "

/* 当前工作目录 */
static char cwd[MAX_PATH_LEN] = "/";

/* 命令历史 */
static char history[SHELL_HISTORY_SIZE][SHELL_MAX_INPUT];
static int  history_count = 0;
static int  history_pos   = 0;

/*------------------------------------------------------------
 * 字符串辅助函数
 *------------------------------------------------------------*/
static int shell_strcmp(const char *a, const char *b)
{
    while (*a && *b && *a == *b) { a++; b++; }
    return (unsigned char)*a - (unsigned char)*b;
}

static int shell_strlen(const char *s)
{
    int n = 0;
    while (s[n]) n++;
    return n;
}

static void shell_strcpy(char *dst, const char *src)
{
    while ((*dst++ = *src++));
}

/*------------------------------------------------------------
 * 内置命令实现
 *------------------------------------------------------------*/

/* help - 显示帮助 */
static void cmd_help(int argc, char **argv)
{
    (void)argc; (void)argv;
    vga_puts("MiniOS Shell Commands:\n");
    vga_puts("  help          - Show this help message\n");
    vga_puts("  clear         - Clear the screen\n");
    vga_puts("  ls [path]     - List directory contents\n");
    vga_puts("  cat <file>    - Print file contents\n");
    vga_puts("  mkdir <dir>   - Create directory\n");
    vga_puts("  rm <file>     - Remove file\n");
    vga_puts("  cd <path>     - Change directory\n");
    vga_puts("  pwd           - Print working directory\n");
    vga_puts("  echo <text>   - Print text\n");
    vga_puts("  ps            - List running processes\n");
    vga_puts("  mem           - Show memory usage\n");
    vga_puts("  reboot        - Reboot system\n");
    vga_puts("  halt          - Halt system\n");
}

/* clear - 清屏 */
static void cmd_clear(int argc, char **argv)
{
    (void)argc; (void)argv;
    vga_clear();
}

/* pwd - 打印当前目录 */
static void cmd_pwd(int argc, char **argv)
{
    (void)argc; (void)argv;
    vga_puts(cwd);
    vga_putchar('\n');
}

/* echo - 打印参数 */
static void cmd_echo(int argc, char **argv)
{
    for (int i = 1; i < argc; i++) {
        if (i > 1) vga_putchar(' ');
        vga_puts(argv[i]);
    }
    vga_putchar('\n');
}

/* cd - 切换目录 */
static void cmd_cd(int argc, char **argv)
{
    const char *path = (argc > 1) ? argv[1] : "/";

    /* 处理特殊路径 */
    if (shell_strcmp(path, "..") == 0) {
        /* 返回上级目录 */
        int len = shell_strlen(cwd);
        if (len > 1) {
            /* 找到最后一个 '/' 并截断 */
            int i = len - 1;
            while (i > 0 && cwd[i] != '/') i--;
            if (i == 0) cwd[1] = '\0';  /* 回到根目录 */
            else        cwd[i] = '\0';
        }
        return;
    }

    /* 构建绝对路径 */
    char new_path[MAX_PATH_LEN];
    if (path[0] == '/') {
        shell_strcpy(new_path, path);
    } else {
        shell_strcpy(new_path, cwd);
        if (cwd[1] != '\0') {
            int len = shell_strlen(new_path);
            new_path[len] = '/';
            new_path[len + 1] = '\0';
        }
        /* 拼接相对路径 */
        int base_len = shell_strlen(new_path);
        for (int i = 0; path[i] && base_len < MAX_PATH_LEN - 1; i++) {
            new_path[base_len++] = path[i];
        }
        new_path[base_len] = '\0';
    }

    /* 验证路径是否存在 */
    VfsNode *node = vfs_resolve_path(new_path);
    if (!node) {
        vga_puts("cd: ");
        vga_puts(path);
        vga_puts(": No such directory\n");
        return;
    }
    if (!(node->flags & VFS_DIRECTORY)) {
        vga_puts("cd: ");
        vga_puts(path);
        vga_puts(": Not a directory\n");
        return;
    }

    shell_strcpy(cwd, new_path);
}

/* ls - 列目录 */
static void cmd_ls(int argc, char **argv)
{
    const char *path = (argc > 1) ? argv[1] : cwd;

    /* 解析路径 */
    char abs_path[MAX_PATH_LEN];
    if (path[0] == '/') {
        shell_strcpy(abs_path, path);
    } else {
        shell_strcpy(abs_path, cwd);
        int len = shell_strlen(abs_path);
        if (abs_path[len - 1] != '/') abs_path[len++] = '/';
        for (int i = 0; path[i]; i++) abs_path[len++] = path[i];
        abs_path[len] = '\0';
    }

    VfsNode *dir = vfs_resolve_path(abs_path);
    if (!dir) {
        vga_puts("ls: ");
        vga_puts(path);
        vga_puts(": No such file or directory\n");
        return;
    }

    if (!(dir->flags & VFS_DIRECTORY)) {
        /* 单个文件 */
        vga_puts(dir->name);
        vga_putchar('\n');
        return;
    }

    /* 遍历目录 */
    int col = 0;
    for (uint32_t i = 0; ; i++) {
        Dirent *de = vfs_readdir(dir, i);
        if (!de) break;

        /* 跳过隐藏文件（以.开头）*/
        if (de->name[0] == '.') continue;

        /* 检查是否是目录 */
        VfsNode *child = vfs_finddir(dir, de->name);
        if (child && (child->flags & VFS_DIRECTORY)) {
            vga_set_color(VGA_COLOR(VGA_LIGHT_BLUE, VGA_BLACK));
        }

        /* 对齐打印 */
        int name_len = shell_strlen(de->name);
        vga_puts(de->name);
        vga_set_color(VGA_COLOR(VGA_LIGHT_GREY, VGA_BLACK));

        /* 每行最多 4 个文件名，对齐到 20 字符宽 */
        for (int p = name_len; p < 20; p++) vga_putchar(' ');
        col++;
        if (col % 4 == 0) vga_putchar('\n');
    }
    if (col % 4 != 0) vga_putchar('\n');
}

/* cat - 打印文件内容 */
static void cmd_cat(int argc, char **argv)
{
    if (argc < 2) {
        vga_puts("Usage: cat <filename>\n");
        return;
    }

    /* 构建绝对路径 */
    char path[MAX_PATH_LEN];
    if (argv[1][0] == '/') {
        shell_strcpy(path, argv[1]);
    } else {
        shell_strcpy(path, cwd);
        int len = shell_strlen(path);
        if (path[len - 1] != '/') path[len++] = '/';
        for (int i = 0; argv[1][i]; i++) path[len++] = argv[1][i];
        path[len] = '\0';
    }

    VfsNode *file = vfs_resolve_path(path);
    if (!file) {
        vga_puts("cat: ");
        vga_puts(argv[1]);
        vga_puts(": No such file\n");
        return;
    }

    if (file->flags & VFS_DIRECTORY) {
        vga_puts("cat: ");
        vga_puts(argv[1]);
        vga_puts(": Is a directory\n");
        return;
    }

    /* 分块读取并显示 */
    uint8_t buf[512];
    uint32_t offset = 0;
    uint32_t n;
    while ((n = vfs_read(file, offset, sizeof(buf) - 1, buf)) > 0) {
        buf[n] = '\0';
        vga_puts((char *)buf);
        offset += n;
        if (n < sizeof(buf) - 1) break;
    }
    vga_putchar('\n');
}

/* ps - 列出进程 */
static void cmd_ps(int argc, char **argv)
{
    (void)argc; (void)argv;
    vga_puts("PID  STATE    PRI  NAME\n");
    vga_puts("---  -------  ---  --------\n");

    extern Task *task_table[];  /* 来自 task.c */
    for (int i = 0; i < MAX_TASKS; i++) {
        Task *t = task_table[i];
        if (!t) continue;

        /* 打印 PID */
        char pid_buf[8];
        int_to_str(t->pid, pid_buf);
        vga_puts(pid_buf);
        for (int p = shell_strlen(pid_buf); p < 5; p++) vga_putchar(' ');

        /* 打印状态 */
        const char *state_names[] = {"Ready  ", "Running", "Blocked", "Zombie ", "Dead   "};
        vga_puts(state_names[t->state]);
        vga_puts("  ");

        /* 打印优先级 */
        char pri_buf[8];
        int_to_str(t->priority, pri_buf);
        vga_puts(pri_buf);
        for (int p = shell_strlen(pri_buf); p < 5; p++) vga_putchar(' ');

        /* 打印名称 */
        vga_puts(t->name);
        vga_putchar('\n');
    }
}

/* mem - 显示内存使用情况 */
static void cmd_mem(int argc, char **argv)
{
    (void)argc; (void)argv;
    uint32_t free_pages = pmm_free_page_count();

    vga_puts("Memory Usage:\n");
    vga_puts("  Free physical pages: ");
    char buf[16];
    int_to_str(free_pages, buf);
    vga_puts(buf);
    vga_puts(" (");
    int_to_str(free_pages * 4, buf);
    vga_puts(buf);
    vga_puts(" KB)\n");
}

/* reboot - 重启系统 */
static void cmd_reboot(int argc, char **argv)
{
    (void)argc; (void)argv;
    vga_puts("Rebooting...\n");

    /* 通过键盘控制器发送重置信号 */
    uint8_t temp;
    do {
        /* 等待键盘控制器输入缓冲区为空 */
        temp = inb(0x64);
        if (temp & 0x01) inb(0x60);    /* 清除输出缓冲区 */
    } while (temp & 0x02);
    outb(0x64, 0xFE);   /* 发送重置命令 */

    /* 如果上面失败了，用三重错误触发重启 */
    __asm__ volatile("int $0xFF");  /* 触发未定义中断 */
}

/* halt - 停机 */
static void cmd_halt(int argc, char **argv)
{
    (void)argc; (void)argv;
    vga_puts("System halted.\n");
    __asm__ volatile("cli; hlt");   /* 关中断并停机 */
}

/*------------------------------------------------------------
 * 命令表（内置命令注册）
 *------------------------------------------------------------*/
typedef struct {
    const char *name;
    void (*handler)(int argc, char **argv);
    const char *desc;
} ShellCommand;

static const ShellCommand builtin_commands[] = {
    { "help",   cmd_help,   "Show help" },
    { "clear",  cmd_clear,  "Clear screen" },
    { "cls",    cmd_clear,  "Clear screen (alias)" },
    { "ls",     cmd_ls,     "List directory" },
    { "dir",    cmd_ls,     "List directory (alias)" },
    { "cat",    cmd_cat,    "Print file" },
    { "cd",     cmd_cd,     "Change directory" },
    { "pwd",    cmd_pwd,    "Print working dir" },
    { "echo",   cmd_echo,   "Print text" },
    { "ps",     cmd_ps,     "List processes" },
    { "mem",    cmd_mem,    "Memory info" },
    { "reboot", cmd_reboot, "Reboot system" },
    { "halt",   cmd_halt,   "Halt system" },
    { NULL, NULL, NULL }
};

/*------------------------------------------------------------
 * 命令行解析：将输入字符串分解为 argc + argv
 *------------------------------------------------------------*/
static int parse_cmdline(char *line, char **argv, int max_args)
{
    int argc = 0;
    char *p = line;

    while (*p && argc < max_args) {
        /* 跳过空白 */
        while (*p == ' ' || *p == '\t') p++;
        if (!*p) break;

        /* 处理引号 */
        if (*p == '"') {
            p++;
            argv[argc++] = p;
            while (*p && *p != '"') p++;
            if (*p == '"') *p++ = '\0';
        } else {
            argv[argc++] = p;
            while (*p && *p != ' ' && *p != '\t') p++;
            if (*p) *p++ = '\0';
        }
    }

    argv[argc] = NULL;
    return argc;
}

/*------------------------------------------------------------
 * 执行一条命令
 *------------------------------------------------------------*/
static void execute_command(char *cmdline)
{
    /* 跳过空行 */
    char *p = cmdline;
    while (*p == ' ' || *p == '\t') p++;
    if (!*p) return;

    /* 保存到历史 */
    shell_strcpy(history[history_count % SHELL_HISTORY_SIZE], cmdline);
    history_count++;
    history_pos = history_count;

    /* 解析命令和参数 */
    char *argv[SHELL_MAX_ARGS];
    int   argc = parse_cmdline(cmdline, argv, SHELL_MAX_ARGS);
    if (argc == 0) return;

    /* 查找并执行内置命令 */
    for (int i = 0; builtin_commands[i].name; i++) {
        if (shell_strcmp(argv[0], builtin_commands[i].name) == 0) {
            builtin_commands[i].handler(argc, argv);
            return;
        }
    }

    /* 未找到命令 */
    vga_puts(argv[0]);
    vga_puts(": command not found\n");
}

/*------------------------------------------------------------
 * 读取一行输入（支持退格、方向键）
 *------------------------------------------------------------*/
static int readline(char *buf, int max_len)
{
    int pos = 0;

    while (1) {
        char c = keyboard_getchar();

        if (c == '\n' || c == '\r') {
            /* 回车：提交输入 */
            buf[pos] = '\0';
            vga_putchar('\n');
            return pos;
        } else if (c == '\b') {
            /* 退格 */
            if (pos > 0) {
                pos--;
                vga_putchar('\b');
                vga_putchar(' ');
                vga_putchar('\b');
            }
        } else if (c >= 0x20 && c < 0x7F && pos < max_len - 1) {
            /* 可打印字符 */
            buf[pos++] = c;
            vga_putchar(c);
        }
        /* TODO：处理方向键（读取扩展扫描码） */
    }
}

/*------------------------------------------------------------
 * Shell 主循环
 *------------------------------------------------------------*/
void shell_run(void)
{
    char input[SHELL_MAX_INPUT];

    vga_clear();
    vga_set_color(VGA_COLOR(VGA_LIGHT_GREEN, VGA_BLACK));
    vga_puts("  ___  ___         _ ___  ___ \n");
    vga_puts(" |  \\/  |         (_)  _|/ _ \\\n");
    vga_puts(" | .  . |_ _ __  _| | | | | | |\n");
    vga_puts(" | |\\/| | | '_ \\| | | | | | | |\n");
    vga_puts(" | |  | | | | | | | |_| | |_| |\n");
    vga_puts(" |_|  |_|_|_| |_|_|_(__) \\___/ \n");
    vga_set_color(VGA_COLOR(VGA_WHITE, VGA_BLACK));
    vga_puts("\nWelcome to MiniOS Shell!\nType 'help' for available commands.\n\n");

    while (1) {
        /* 打印提示符（用颜色区分） */
        vga_set_color(VGA_COLOR(VGA_LIGHT_GREEN, VGA_BLACK));
        vga_puts("[root@MiniOS ");
        vga_set_color(VGA_COLOR(VGA_LIGHT_CYAN, VGA_BLACK));
        vga_puts(cwd);
        vga_set_color(VGA_COLOR(VGA_LIGHT_GREEN, VGA_BLACK));
        vga_puts("]$ ");
        vga_set_color(VGA_COLOR(VGA_WHITE, VGA_BLACK));

        /* 读取输入 */
        int len = readline(input, SHELL_MAX_INPUT);
        if (len == 0) continue;

        /* 执行命令 */
        execute_command(input);
    }
}
```

---

## 9.3 集成 Shell 到内核

```c
/* kernel/main.c 最后加入 Shell 启动 */
void kernel_main(void)
{
    /* ... 所有初始化 ... */

    /* 将 Shell 作为一个内核任务启动 */
    task_create_kernel("shell", shell_run, 50);

    /* 开启调度器 */
    __asm__ volatile("sti");

    /* 内核主循环 */
    while (1) __asm__ volatile("hlt");
}
```

---

## 9.4 Shell 运行效果

启动后的 MiniOS Shell 界面：

```
  ___  ___         _ ___  ___ 
 |  \/  |         (_)  _|/ _ \
 | .  . |_ _ __  _| | | | | | |
 | |\/| | | '_ \| | | | | | | |
 | |  | | | | | | | |_| | |_| |
 |_|  |_|_|_| |_|_|_(__) \___/ 

Welcome to MiniOS Shell!
Type 'help' for available commands.

[root@MiniOS /]$ help
MiniOS Shell Commands:
  help          - Show this help message
  clear         - Clear the screen
  ls [path]     - List directory contents
  ...

[root@MiniOS /]$ ls
bin/                lib/                home/               etc/
[root@MiniOS /]$ cd /etc
[root@MiniOS /etc]$ cat motd
Welcome to MiniOS!
[root@MiniOS /etc]$ ps
PID  STATE    PRI  NAME
---  -------  ---  --------
1    Running  50   shell
2    Ready    255  idle
[root@MiniOS /etc]$ mem
Memory Usage:
  Free physical pages: 7680 (30720 KB)
```

---

## 9.5 章节小结

本章实现了：
- [x] 完整的交互式 Shell
- [x] 命令行解析（参数拆分、引号处理）
- [x] 内置命令：ls, cat, cd, pwd, ps, mem, echo, help, reboot, halt
- [x] 历史命令记录
- [x] 彩色提示符和输出

## 🏠 课后作业

1. 为 Shell 添加**管道**支持（`ls | cat`）
2. 添加**重定向**支持（`cat file > output.txt`）
3. 添加**Tab 补全**功能（按 Tab 键自动补全文件名）

---

**上一章** ← [第 8 章：设备驱动](./08_Drivers.md)

**下一章** → [第 10 章：系统调用接口](./10_Syscall.md)
