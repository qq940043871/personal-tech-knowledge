# CPU调度原理

> 模块：CPU调度
> 更新时间：2026-03-29

---

## 一、调度器架构

### Linux调度器历史

```
Linux 2.4: O(n)调度器 - 时间片轮转,高复杂度
Linux 2.6: O(1)调度器 - 优先级数组,恒定时间
Linux 2.6.23: CFS - 完全公平调度器
Linux 4.20+: EEVDF - Earliest Eligible Virtual Deadline First
```

### CFS原理

```
CFS(Completely Fair Scheduler)完全公平调度器

核心思想: 虚拟运行时间(vruntime)决定调度顺序
- vruntime最小 → 最需要CPU → 优先调度
- 每个进程获得相等的CPU时间

理想状态: 所有进程同时运行,每个进程获得 1/N CPU时间
实际: 进程依次运行,保证统计公平
```

---

## 二、调度策略

### 调度策略分类

```bash
# 1. SCHED_NORMAL (CFS) - 普通进程
# 2. SCHED_FIFO - 实时FIFO
# 3. SCHED_RR - 实时轮转
# 4. SCHED_BATCH - 批处理
# 5. SCHED_IDLE - 空闲

# 查看进程调度策略
chrt -p PID

# 设置调度策略
chrt -f 50 -p PID   # FIFO, 优先级50
chrt -r 50 -p PID   # RR, 优先级50
chrt -o -p PID      # OTHER/NORMAL
```

### 优先级

```
nice值: -20(最高) ~ 19(最低)
  ↓
权重映射
  ↓
虚拟运行时间(vruntime)

nice值影响:
- nice=-20 → 权重高 → vruntime增长慢 → 获得更多CPU
- nice=19  → 权重低 → vruntime增长快 → 获得更少CPU
```

---

## 三、时间片与抢占

### 时间片分配

```bash
# 查看调度参数
cat /proc/sys/kernel/sched_min_granularity_ns  # 最小时间粒度
cat /proc/sys/kernel/sched_latency_ns          # 调度周期
cat /proc/sys/kernel/sched_tunable_scaling     # 缩放因子

# 计算时间片
# 时间片 ≈ sched_latency_ns / 进程数
# 最小时间片 = sched_min_granularity_ns
```

### 抢占机制

```
两种抢占:
1. 周期性调度器 - 固定时间检查
2. 空闲唤醒 - 事件触发

抢占条件:
- 时间片用完
- 有更高优先级进程就绪
- 进程主动放弃CPU(yield)
- 中断处理完成
```

---

## 四、上下文切换

### 上下文切换原理

```
CPU上下文切换:
1. 保存当前进程寄存器
2. 保存程序计数器(PC)
3. 保存堆栈指针
4. 切换页表
5. 恢复下一个进程状态
6. 恢复寄存器
7. 跳转到PC位置

成本: 约3-5微秒/次
```

### 查看上下文切换

```bash
# vmstat
vmstat 1
# cs列: 每秒上下文切换次数

# pidstat
apt install sysstat
pidstat -w 1                      # 每秒报告
pidstat -w -p PID 1               # 监控特定进程

# cswch/s: 自愿上下文切换(进程等待I/O等)
# nvcswch/s: 非自愿上下文切换(时间片用完,被抢占)
```

---

## 五、CPU亲和性

### taskset

```bash
# 查看CPU亲和性
taskset -p PID                    # 查看
taskset -cp PID                   # 查看(显示CPU列表)

# 设置CPU亲和性
taskset -c 0 -p PID              # 绑定到CPU0
taskset -c 0,1 -p PID            # 绑定到CPU0,1
taskset -c 0-3 -p PID            # 绑定到CPU0-3
taskset -c 0-7 -p PID            # 绑定到所有CPU

# 启动时绑定
taskset -c 0 ./program            # CPU0运行
taskset -c 1,3 ./program         # CPU1或3运行
```

### numactl

```bash
# 查看NUMA拓扑
numactl --hardware
numactl --show

# 绑定到节点
numactl -m 0 ./program            # 内存分配在节点0
numactl -N 0 ./program            # 在节点0执行
numactl --membind=0 --cpunodebind=0 ./program  # 内存+CPU

# 查看进程NUMA信息
numastat PID
numastat -p PID
```

---

## 六、负载与调度

### Load Average

```bash
uptime
# 输出: 10:30:00 up 5 days, 2:15, 2 users, load average: 0.52, 0.48, 0.45
#                                              1min   5min   15min

# 负载含义:
# 负载 = 运行中进程 + 不可中断等待进程(等待I/O/锁)
# 负载/CPU核心数 < 1.0 → 正常
# 负载/CPU核心数 > 1.0 → 有积压

# CPU核心数
nproc                         # 逻辑CPU数
lscpu | grep "^CPU(s)"       # 逻辑CPU数
lscpu | grep "Core"          # 每核心线程数
```

### uptime详细说明

```
理想负载范围:
CPU数×1.0:   满负荷,所有CPU都在工作
CPU数×0.7:   理想负载,有一定余量
CPU数×0.0:   完全空闲

负载高但CPU低可能原因:
- I/O瓶颈(等待磁盘/网络)
- 锁竞争
- 大量进程在睡眠态(D状态)
```

---

## 七、调度器调优

### sysctl参数

```bash
# 调度延迟(调度周期)
sysctl -w kernel.sched_latency_ns=20000000  # 20ms

# 最小时间粒度
sysctl -w kernel.sched_min_granularity_ns=1000000  # 1ms

# 抢占延迟
sysctl -w kernel.sched_migration_cost_ns=500000  # 0.5ms

# CFS带宽控制
sysctl -w kernel.sched_rt_runtime_us=950000   # 实时进程运行时间
sysctl -w kernel.sched_rt_period_us=1000000   # 实时周期
```

---

*下一步：CPU性能分析*
