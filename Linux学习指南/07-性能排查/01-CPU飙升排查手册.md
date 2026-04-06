# CPU飙升排查手册

> 模块：性能排查
> 更新时间：2026-03-29

---

## 一、排查流程

```
┌─────────────────────────────────────────────┐
│  1. top - 查看整体CPU使用                    │
│  2. top -H -p PID - 找出CPU高的线程         │
│  3. printf "%x\n" TID - 线程ID转16进制       │
│  4. jstack/gdb/perf - 获取堆栈               │
│  5. 分析代码定位问题                         │
└─────────────────────────────────────────────┘
```

---

## 二、完整排查步骤

### 第一步：定位CPU高的进程

```bash
# 查看整体CPU状态
top -bn1 | head -20

# 按CPU排序
top
# 按P键排序

# 查看CPU使用详情
mpstat -P ALL 1 5               # 每CPU统计
```

### 第二步：定位CPU高的线程

```bash
# top查看线程
top -H -p PID

# ps查看线程CPU
ps -eLo pid,lwp,nlwp,comm,pcpu | grep -i java | sort -k4 -nr | head -20

# 查看特定线程
top -H -p PID -b -n 1 | grep -E "PID|java"
```

### 第三步：获取线程堆栈

```bash
# Java应用 - jstack
jstack PID > /tmp/jstack.log

# 找到CPU高的线程
top -H -p PID
# 假设线程TID=12345

# 转换为16进制
printf "%x\n" 12345
# 输出: 3039

# 查找堆栈
grep -A 50 "nid=0x3039" /tmp/jstack.log
```

### 第四步：系统级采样

```bash
# perf采样
perf top -p PID                 # 实时热点函数
perf record -F 99 -p PID -g -- sleep 30
perf report                     # 查看报告
```

---

## 三、火焰图生成

### perf + FlameGraph

```bash
# 1. 安装perf (需要root)
apt install linux-perf / yum install perf

# 2. 安装FlameGraph
git clone https://github.com/brendangregg/FlameGraph.git
export PATH=$PATH:~/FlameGraph

# 3. 采样
perf record -F 99 -p PID -g -- sleep 60

# 4. 生成火焰图
perf script -i perf.data > /tmp/out.perf
./stackcollapse-perf.pl /tmp/out.perf > /tmp/out.folded
./flamegraph.pl /tmp/out.folded > /tmp/flamegraph.svg

# 5. 下载查看
scp user@host:/tmp/flamegraph.svg .
```

---

## 四、常见问题分析

### 问题1：GC频繁

```
症状: CPU高,GC日志频繁
原因: 内存分配过快或内存设置不合理

排查:
1. jstat -gcutil PID 1000
2. 检查GC日志
3. 调整堆大小或GC策略
```

### 问题2：死循环

```
症状: 单线程CPU 100%
原因: 代码死循环

排查:
1. jstack查看线程状态
2. 找到RUNNABLE状态的高CPU线程
3. 分析堆栈定位问题代码
```

### 问题3：正则表达式灾难

```
症状: CPU飙升,请求变慢
原因: 正则表达式回溯

排查:
1. jstack查看热点
2. 检查代码中的正则使用
3. 使用非回溯正则
```

---

*下一步：内存不足排查手册*
