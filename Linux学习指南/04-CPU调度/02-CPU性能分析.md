# CPU性能分析

> 模块：CPU调度
> 更新时间：2026-05-19

---

## 一、top 实时监控

### 基础用法

```bash
# 基础使用
top                                       # 实时监控
top -p PID1,PID2                         # 监控指定进程
top -u username                          # 监控指定用户
top -b -n 1 > top_output.txt             # 批处理模式，输出到文件

# top交互命令
# 1: 显示每个CPU核心
# P: 按CPU排序
# M: 按内存排序
# c: 显示完整命令行
# H: 显示线程
# k: kill进程
# r: renice进程
```

### top输出解读

```bash
# 关键字段
# %Cpu(s):  us(user) sy(system) ni(nice) id(idle) wa(iowait) hi(irq) si(softirq) st(steal)
# us: 用户空间CPU占比
# sy: 内核空间CPU占比
# wa: IO等待占比
# st: 虚拟机被宿主机偷走的CPU时间

# 进程字段
# %CPU: 进程CPU使用率
# %MEM: 进程内存使用率
# TIME+: 累计CPU时间
# COMMAND: 命令名
```

---

## 二、mpstat 多核分析

### 基础用法

```bash
# 安装sysstat
apt install sysstat                       # Debian/Ubuntu
yum install sysstat                       # CentOS/RHEL

# 查看所有CPU核心
mpstat -P ALL                             # 所有核心
mpstat -P ALL 1 5                         # 每秒刷新，共5次
mpstat -P 0,1,2,3                         # 指定核心

# 输出解读
# %usr: 用户空间
# %sys: 内核空间
# %iowait: IO等待
# %irq: 硬中断
# %soft: 软中断
# %idle: 空闲
```

### CPU负载不均排查

```bash
# 查看各核心负载
mpstat -P ALL 1 | awk '/^Average/ && $NF < 20 {print "Core", $2, "idle:", $NF"%"}'

# 查看中断分布
cat /proc/interrupts | head -5
watch -n 1 'cat /proc/interrupts | grep -E "CPU0|CPU1|CPU2|CPU3"'

# 绑定进程到特定CPU
taskset -c 0,1 ./program                  # 绑定到CPU 0,1
taskset -pc 0 PID                         # 修改运行中进程
```

---

## 三、perf 性能分析

### 基础采样

```bash
# 安装perf
apt install linux-tools-common linux-tools-$(uname -r)

# 系统级CPU采样
perf top                                  # 实时热点函数
perf stat -a sleep 10                     # 系统级统计10秒
perf record -a -g -F 99 sleep 30         # 采样30秒，99Hz
perf report                               # 分析采样结果

# 进程级采样
perf top -p PID                           # 实时查看进程热点
perf record -p PID -g sleep 30           # 采样进程30秒
perf report --stdio                       # 文本输出报告
```

### perf stat 统计

```bash
# 基础统计
perf stat ./program                       # 运行并统计

# 系统级统计
perf stat -a -I 1000 sleep 10            # 每秒输出一次

# 指定事件
perf stat -e cache-misses,cache-references,instructions,cycles ./program

# 常用事件
# cpu-cycles: CPU周期数
# instructions: 指令数
# cache-misses: 缓存未命中
# branch-misses: 分支预测失败
# context-switches: 上下文切换
# page-faults: 缺页中断
```

### perf record 深入分析

```bash
# 记录调用栈
perf record -g -p PID sleep 30           # 记录30秒

# 分析火焰图数据
perf script > out.perf                    # 导出原始数据

# 按线程分析
perf record -g --tid=PID -p PID sleep 10

# 分析特定事件
perf record -e cache-misses -g -p PID sleep 10

# 实时分析
perf top -g -p PID                       # 带调用栈的实时热点
```

---

## 四、火焰图生成

### 使用FlameGraph工具

```bash
# 下载FlameGraph
git clone https://github.com/brendangregg/FlameGraph.git
cd FlameGraph

# 生成CPU火焰图
perf record -F 99 -a -g sleep 30
perf script > out.perf
./stackcollapse-perf.pl out.perf > out.folded
./flamegraph.pl out.folded > cpu.svg

# 一行命令
perf record -F 99 -a -g sleep 30 | \
perf script | \
./stackcollapse-perf.pl | \
./flamegraph.pl > cpu.svg
```

### 火焰图解读

```bash
# 火焰图关键概念
# X轴: 采样占比(越宽表示占用CPU越多)
# Y轴: 调用栈深度(越深表示调用链越长)
# 颜色: 随机颜色，无特殊含义

# 交互操作
# 点击: 放大该函数
# 搜索: Ctrl+F 搜索函数名

# 生成on-CPU火焰图(分析CPU使用)
perf record -F 99 -a -g sleep 30
./flamegraph.pl --title="CPU Flame Graph" out.folded > cpu.svg

# 生成off-CPU火焰图(分析阻塞)
# 需要使用BCC工具
```

---

## 五、常用分析场景

```bash
# 场景1: 找出CPU使用最高的函数
perf top -p PID
# 或
perf record -p PID -g sleep 10 && perf report

# 场景2: 分析缓存命中率
perf stat -e cache-references,cache-misses -p PID sleep 10

# 场景3: 分析分支预测
perf stat -e branch-instructions,branch-misses -p PID sleep 10

# 场景4: 分析上下文切换
perf stat -e context-switches,cpu-migrations -p PID sleep 10

# 场景5: 系统级热点分析
perf record -a -g -F 99 sleep 60
perf report --sort=dso                    # 按动态库排序
perf report --sort=comm                   # 按进程排序
```

---

*下一步：CPU飙升排查*
