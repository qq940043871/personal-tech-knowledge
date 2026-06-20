# JVM调优实战

> 模块：手写JVM / 08-性能优化
> 更新时间：2026-06-20

---

## 一、调优目标

| 指标 | 目标 |
|------|------|
| GC停顿时间 | < 100ms |
| GC频率 | Minor GC < 1次/秒 |
| Full GC | < 1次/小时 |
| 堆内存使用率 | < 80% |

---

## 二、调优流程

```
1. 监控分析 → 发现问题
2. 定位原因 → 分析GC日志
3. 调整参数 → 优化配置
4. 验证效果 → 压测验证
```

---

## 三、GC日志分析

### 3.1 开启GC日志

```bash
# JDK 8
-XX:+PrintGCDetails
-XX:+PrintGCDateStamps
-XX:+PrintGCTimeStamps
-Xloggc:gc.log

# JDK 11+
-Xlog:gc*:file=gc.log:time,uptime,level,tags:filecount=10,filesize=100m
```

### 3.2 日志解读

```
[GC (Allocation Failure) [PSYoungGen: 65536K->10240K(76288K)] 
65536K->10240K(251392K), 0.0123456 secs]
```

- `GC` — GC类型
- `Allocation Failure` — 触发原因
- `PSYoungGen` — 使用的收集器
- `65536K->10240K` — GC前后新生代大小
- `76288K` — 新生代总大小
- `65536K->10240K` — GC前后堆大小
- `251392K` — 堆总大小
- `0.0123456 secs` — GC耗时

---

## 四、常用JVM参数

### 4.1 堆内存

```bash
-Xms4g          # 初始堆大小
-Xmx4g          # 最大堆大小
-Xmn2g          # 新生代大小
-XX:SurvivorRatio=8  # Eden:Survivor=8:1
-XX:MaxTenuringThreshold=15  # 晋升阈值
```

### 4.2 元空间

```bash
-XX:MetaspaceSize=256m
-XX:MaxMetaspaceSize=256m
```

### 4.3 GC选择

```bash
# G1收集器
-XX:+UseG1GC
-XX:MaxGCPauseMillis=200
-XX:G1HeapRegionSize=4m

# ZGC收集器（JDK 11+）
-XX:+UseZGC
```

### 4.4 GC日志

```bash
-XX:+PrintGCDetails
-XX:+PrintGCDateStamps
-Xloggc:gc.log
-XX:+UseGCLogFileRotation
-XX:NumberOfGCLogFiles=10
-XX:GCLogFileSize=100m
```

---

## 五、常见问题

### 5.1 频繁Full GC

**原因：**
- 老年代空间不足
- 内存泄漏
- 大对象直接进入老年代

**解决：**
```bash
# 增加老年代大小
-XX:NewRatio=2

# 减少大对象阈值
-XX:PretenureSizeThreshold=1m

# 检查内存泄漏
jmap -dump:format=b,file=heap.hprof <pid>
```

### 5.2 GC停顿时间长

**原因：**
- 堆内存过大
- 使用CMS/G1收集器

**解决：**
```bash
# 使用G1收集器
-XX:+UseG1GC
-XX:MaxGCPauseMillis=200

# 使用ZGC（JDK 11+）
-XX:+UseZGC
```

### 5.3 OOM问题

**原因：**
- 内存泄漏
- 堆内存不足

**解决：**
```bash
# OOM时dump堆
-XX:+HeapDumpOnOutOfMemoryError
-XX:HeapDumpPath=/path/to/dump.hprof

# 分析堆转储
jhat heap.hprof
# 或使用MAT/VisualVM
```

---

## 六、监控工具

### 6.1 jstat

```bash
# 查看GC统计
jstat -gc <pid> 1000 10

# 查看内存使用
jstat -gccapacity <pid>

# 查看GC原因
jstat -gcutil <pid>
```

### 6.2 jmap

```bash
# 查看堆内存
jmap -heap <pid>

# 查看对象统计
jmap -histo <pid>

# 生成堆转储
jmap -dump:format=b,file=heap.hprof <pid>
```

### 6.3 jstack

```bash
# 查看线程状态
jstack <pid>

# 查看死锁
jstack -l <pid>
```

### 6.4 VisualVM

```bash
# 启动VisualVM
jvisualvm
```

---

## 七、调优案例

### 7.1 案例1：频繁Full GC

```bash
# 现象：每10分钟一次Full GC
# 原因：老年代空间不足
# 解决：
-Xms4g -Xmx4g -Xmn2g
-XX:SurvivorRatio=8
-XX:MaxTenuringThreshold=15
```

### 7.2 案例2：GC停顿时间长

```bash
# 现象：每次GC停顿500ms
# 原因：使用CMS收集器
# 解决：
-XX:+UseG1GC
-XX:MaxGCPauseMillis=200
-XX:G1HeapRegionSize=4m
```

---

## 八、最佳实践

1. **先监控再调优** — 用数据说话
2. **逐步调整** — 每次只调整一个参数
3. **压测验证** — 调优后必须压测
4. **保留日志** — 记录GC日志用于分析
5. **持续优化** — 定期review GC日志

---

*JVM调优是性能优化的重要环节，需要结合具体场景进行。*
