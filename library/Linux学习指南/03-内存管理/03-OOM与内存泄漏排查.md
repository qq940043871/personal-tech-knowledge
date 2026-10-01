# OOM与内存泄漏排查

> 模块：内存管理
> 更新时间：2026-05-19

---

## 一、OOM Killer机制

### OOM触发条件

```bash
# OOM Killer触发时机
# 1. 系统内存耗尽，无法分配新内存
# 2. Swap空间已满或未配置
# 3. 内核无法回收足够的缓存

# 查看OOM相关日志
dmesg | grep -i "oom\|out of memory"
journalctl -k | grep -i "oom"
grep -i "oom" /var/log/messages
```

### OOM评分机制

```bash
# 查看进程OOM评分(0-1000, 越高越容易被kill)
cat /proc/PID/oom_score                   # 当前评分
cat /proc/PID/oom_score_adj               # 调整值(-1000到1000)

# 批量查看所有进程OOM评分
for pid in /proc/[0-9]*/; do
    name=$(cat $pid/comm 2>/dev/null)
    score=$(cat $pid/oom_score 2>/dev/null)
    echo "$score $name $(basename $pid)"
done | sort -rn | head -20

# 保护关键进程不被OOM Kill
echo -1000 > /proc/PID/oom_score_adj      # 完全保护
echo 1000 > /proc/PID/oom_score_adj       # 优先kill

# 永久保护: 使用systemd
# [Service]
# OOMScoreAdjust=-1000
```

### OOM日志分析

```bash
# 分析OOM日志关键信息
dmesg | grep -A 20 "Out of memory"

# 日志关键字段
# Killed process PID (name): total-vm, anon-rss, file-rss, shmem-rss
# oom-kill: constraint=CONSTRAINT_MEMCG, ...
# memory: usage / limit

# 实时监控内存压力
vmstat 1 | awk 'NR>2 {if($7>0 || $8>0) print "Swap in/out detected:", $7, $8}'
```

---

## 二、内存泄漏定位

### 初步排查

```bash
# 1. 观察内存增长趋势
while true; do
    echo "$(date '+%H:%M:%S') $(ps -o rss= -p PID)"
    sleep 5
done

# 2. 查看进程内存分布
pmap -x PID | tail -1

# 3. 对比内存快照
cat /proc/PID/smaps > /tmp/smaps_1.txt
sleep 300
cat /proc/PID/smaps > /tmp/smaps_2.txt
diff /tmp/smaps_1.txt /tmp/smaps_2.txt | head -50

# 4. 查看堆内存增长
cat /proc/PID/status | grep -i vm
pmap -x PID | grep heap
```

### Java应用内存泄漏

```bash
# 查看JVM堆内存
jmap -heap PID

# 生成堆dump
jmap -dump:format=b,file=heap.hprof PID

# 查看对象统计
jmap -histo PID | head -30
jmap -histo:live PID | head -30        # 触发GC后统计

# 使用jcmd(推荐)
jcmd PID GC.heap_info
jcmd PID GC.run
jcmd PID VM.native_memory summary

# 启用NMT(需要启动参数)
# -XX:NativeMemoryTracking=summary
jcmd PID VM.native_memory summary
jcmd PID VM.native_memory detail
```

---

## 三、Valgrind内存检测

### 基础用法

```bash
# 安装Valgrind
apt install valgrind                     # Debian/Ubuntu
yum install valgrind                     # CentOS/RHEL

# 检测内存泄漏
valgrind --leak-check=full \
         --show-leak-kinds=all \
         --track-origins=yes \
         --verbose \
         ./program

# 输出解读
# definitely lost: 确定泄漏的内存
# indirectly lost: 间接泄漏(如链表节点)
# possibly lost: 可能泄漏
# still reachable: 未释放但仍有指针指向
```

### Valgrind高级选项

```bash
# 生成XML报告
valgrind --xml=yes --xml-file=report.xml ./program

# 限制输出
valgrind --leak-check=full --num-callers=30 ./program

# 检测未初始化内存
valgrind --track-origins=yes ./program

# 检测无效读写
valgrind --tool=memcheck ./program

# 缓存分析
valgrind --tool=cachegrind ./program

# 性能分析
valgrind --tool=callgrind ./program
callgrind_annotate callgrind.out.PID
```

---

## 四、AddressSanitizer

### 编译时启用

```bash
# GCC/Clang编译时启用ASan
gcc -fsanitize=address -g -o program program.c
clang -fsanitize=address -g -o program program.c

# 启用LeakSanitizer(LSan)
gcc -fsanitize=leak -g -o program program.c

# 同时启用多个检测
gcc -fsanitize=address,undefined -g -o program program.c

# 运行检测
./program
# ASan会自动输出内存错误信息
```

### ASan输出解读

```bash
# 常见错误类型
# 1. heap-buffer-overflow: 堆缓冲区溢出
# 2. stack-buffer-overflow: 栈缓冲区溢出
# 3. use-after-free: 使用已释放内存
# 4. use-after-return: 使用已返回栈内存
# 5. double-free: 重复释放
# 6. memory-leak: 内存泄漏

# 环境变量控制
ASAN_OPTIONS=detect_leaks=1 ./program
ASAN_OPTIONS=halt_on_error=0 ./program   # 不停止，收集所有错误
```

---

## 五、实战排查流程

### 完整排查步骤

```bash
# 步骤1: 确认内存泄漏
watch -n 5 'ps -o pid,rss,comm -p PID'

# 步骤2: 分析内存分布
pmap -x PID > /tmp/pmap_output.txt
cat /proc/PID/smaps | awk '/^[0-9a-f]/{region=$0} /Rss:/{print $2, region}' | sort -rn | head -20

# 步骤3: 抓取内存快照对比
for i in $(seq 1 10); do
    cat /proc/PID/status | grep VmRSS >> /tmp/rss_trend.txt
    sleep 60
done

# 步骤4: 使用工具定位
# C/C++: Valgrind / ASan
# Java: jmap + MAT分析
# Go: pprof

# 步骤5: 临时缓解
# 重启进程
systemctl restart service_name
# 或设置内存限制
echo $((1024*1024*1024)) > /sys/fs/cgroup/memory/group_name/memory.limit_in_bytes
```

---

*下一步：CPU调度原理*
