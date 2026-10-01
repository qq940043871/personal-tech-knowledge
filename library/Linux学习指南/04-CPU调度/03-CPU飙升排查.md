# CPU飙升排查

> 模块：CPU调度
> 更新时间：2026-05-19

---

## 一、快速定位

### 第一步：top确认

```bash
# 查看系统整体CPU
top                                       # 按P按CPU排序
uptime                                    # 查看负载(1/5/15分钟)

# 负载解读
# 负载 < CPU核数: 正常
# 负载 = CPU核数: 满载
# 负载 > CPU核数: 过载

# 查看CPU核数
nproc
cat /proc/cpuinfo | grep processor | wc -l

# 快速找出CPU消耗最高的进程
ps aux --sort=-%cpu | head -10
top -b -n 1 | head -20
```

### 第二步：strace跟踪

```bash
# 跟踪进程系统调用
strace -c -p PID                          # 统计系统调用
strace -p PID -e trace=all                # 实时跟踪所有调用

# 常见热点系统调用
# futex: 锁竞争
# read/write: IO操作
# epoll_wait: 事件等待
# clock_gettime: 时间获取

# 跟踪特定系统调用
strace -p PID -e trace=read,write         # IO操作
strace -p PID -e trace=network            # 网络操作
strace -p PID -e trace=futex              # 锁操作

# 统计输出
strace -c -p PID -e trace=all sleep 10
# 输出: calls, errors, syscall, time, etc.
```

---

## 二、perf深入分析

### perf定位热点函数

```bash
# 实时查看热点
perf top -p PID

# 采样分析
perf record -p PID -g -F 99 sleep 30
perf report --stdio

# 分析热点函数
perf report --sort=symbol,dso
# 输出: Overhead, Symbol, Shared Object

# 查看调用链
perf report --call-graph=graph
perf report --children                  # 包含子调用
```

### 火焰图分析

```bash
# 生成火焰图
perf record -p PID -g -F 99 sleep 30
perf script > /tmp/out.perf

# 使用FlameGraph
cd FlameGraph
./stackcollapse-perf.pl /tmp/out.perf > /tmp/out.folded
./flamegraph.pl --title="CPU Flame Graph" /tmp/out.folded > /tmp/cpu.svg

# 分析火焰图
# 1. 找最宽的函数(CPU占比最高)
# 2. 查看调用栈(从下往上)
# 3. 定位到业务代码
```

---

## 三、常见CPU飙升原因

### 死循环

```bash
# 特征: 单核100%，持续不变
top -p PID                                # 观察CPU是否稳定100%

# 定位: 查看线程
top -H -p PID                            # 按线程查看
printf "%x\n" TID                        # 转换TID为十六进制

# Java线程dump
jstack PID > /tmp/thread_dump.txt
grep "nid=0xHEX_TID" /tmp/thread_dump.txt -A 20

# GDB调试
gdb -p PID
(gdb) thread apply all bt                # 所有线程堆栈
(gdb) info threads                       # 线程列表
(gdb) thread TID                         # 切换线程
(gdb) bt                                 # 查看堆栈
```

### GC风暴

```bash
# 特征: CPU高，伴有频繁GC
jstat -gcutil PID 1000                   # 每秒查看GC
# 关注: YGC, YGCT, FGC, FGCT

# 查看GC日志
# JVM参数: -Xlog:gc*:file=gc.log
tail -f gc.log | grep -E "GC|Full GC"

# 解决方案
# 1. 调整堆大小: -Xmx4g -Xms4g
# 2. 选择合适GC: -XX:+UseG1GC
# 3. 排查内存泄漏
```

### 锁竞争

```bash
# 特征: 多线程CPU高，strace显示futex
strace -c -p PID | grep futex

# Java锁分析
jstack PID | grep -i "waiting.*lock\|blocked" | wc -l

# 线程状态分析
jstack PID | grep "java.lang.Thread.State" | sort | uniq -c

# 解决方案
# 1. 减小锁粒度
# 2. 使用无锁数据结构
# 3. 读写锁替代互斥锁
```

---

## 四、Java应用排查

```bash
# 完整排查流程

# 1. 找到Java进程
ps aux | grep java

# 2. 查看线程CPU使用
top -H -p PID
# 记录CPU高的线程TID

# 3. 转换TID
printf "%x\n" TID

# 4. 获取线程堆栈
jstack PID > /tmp/thread.txt
grep -A 30 "nid=0xHEX" /tmp/thread.txt

# 5. 或使用jcmd
jcmd PID Thread.print > /tmp/thread.txt
jcmd PID GC.heap_info
jcmd PID VM.flags

# 6. 生成火焰图(推荐)
# 使用async-profiler
./profiler.sh -d 30 -f /tmp/flame.html PID
```

---

## 五、排查检查清单

```bash
# CPU飙升排查步骤
# 1. top/uptime 确认CPU和负载
# 2. top -H -p PID 找到高CPU线程
# 3. strace -p PID 跟踪系统调用
# 4. perf top -p PID 查看热点函数
# 5. jstack/gdb 获取线程堆栈
# 6. 生成火焰图分析调用链
# 7. 定位代码并修复

# 常见原因
# - 死循环/无限递归
# - 频繁GC
# - 锁竞争
# - 正则回溯
# - 序列化/反序列化
# - 加密/解密操作
```

---

*下一步：网络协议栈原理*
