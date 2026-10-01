# 内存溢出OOM案例

> 模块：实战案例
> 更新时间：2026-03-29

---

## 问题描述

```
Java应用被OOM Killer杀死
进程日志无异常,服务突然中断
```

---

## 排查过程

### 第一步：查看OOM日志

```bash
# 查看内核日志
dmesg -T | grep -i oom | tail -20

# 输出:
# [Mon Mar 29 10:30:15 2026] java invoked oom-killer: gfp_mask=0x
# [Mon Mar 29 10:30:15 2026] java: page allocation failure
# [Mon Mar 29 10:30:16 2026] Out of memory: Killed process 12345
```

### 第二步：分析内存

```bash
# 查看当时内存状态
free -h
# Mem: total=32G used=31G free=500M available=800M

# 查看具体内存分布
cat /proc/meminfo | grep -E "MemTotal|MemFree|MemAvailable|AnonPages|Cached"

# 发现: Cached过大,但应用申请的匿名页持续增长
```

### 第三步：分析进程

```bash
# 查看Java进程
ps aux | grep java

# 当时进程ID是12345
# 查看进程信息
cat /proc/12345/status | grep -E "VmPeak|VmSize|VmRSS|VmData|VmStk"

# 输出:
# VmPeak: 32768M
# VmSize: 32768M
# VmRSS: 30000M
# VmData: 28000M
```

### 第四步：Java堆分析

```bash
# jmap查看Java堆
jmap -heap 12345

# 发现:
# Heap Configuration:
#    MaxHeapSize = 32768M (32GB)
#    NewSize = 5120M
#    OldSize = 27648M
#
# GC后堆使用率仍然很高
# Old区使用率: 95%
```

### 第五步：导出堆分析

```bash
# 生成堆转储(注意: 会暂停应用)
jmap -dump:format=b,file=/tmp/heap.hprof 12345

# 使用MAT分析
# https://eclipse.org/mat/
# 导入heap.hprof
# 运行Leak Suspects报告
```

### 分析结果

```
发现:
1. ConcurrentHashMap持续增长,未清理
2. 缓存数据无上限
3. 对象引用未释放

根因: 代码中存在内存泄漏
```

---

## 问题代码

```java
// 问题代码
public class CacheService {
    private Map<String, UserData> cache = new ConcurrentHashMap<>();
    
    public void addData(String key, UserData data) {
        cache.put(key, data);  // 只增不减
    }
}
```

---

## 解决方案

```java
// 修复1: 使用带清理的缓存
public class CacheService {
    private LoadingCache<String, UserData> cache = Caffeine.newBuilder()
        .maximumSize(10000)           // 最大条目
        .expireAfterWrite(1, TimeUnit.HOURS)  // 写入后过期
        .removalListener((key, value) -> {
            // 清理监听
        })
        .build();
}

// 修复2: 定期清理
public class CacheService {
    private Map<String, UserData> cache = new ConcurrentHashMap<>();
    
    public void addData(String key, UserData data) {
        cache.put(key, data);
    }
    
    @Scheduled(fixedRate = 60000)  // 每分钟
    public void cleanup() {
        // 清理超过阈值的旧数据
        if (cache.size() > MAX_SIZE) {
            cache.entrySet().removeIf(e -> isOld(e.getValue()));
        }
    }
}

// 修复3: 限制堆外内存
// JVM参数添加:
-Xmx8g -XX:MaxMetaspaceSize=512m -XX:NativeMemoryTracking=detail
```

---

## 预防措施

```bash
# 1. 添加监控告警
# 内存使用超过80%告警

# 2. 添加OOM前日志
# JVM参数:
-XX:+HeapDumpOnOutOfMemoryError
-XX:HeapDumpPath=/var/log/java_oom.hprof

# 3. 限制进程内存
systemd:
MemoryMax=10G
MemorySwapMax=2G
```

---

## 总结

```
排查命令:
- dmesg | grep -i oom
- jmap -heap
- jmap -dump + MAT分析

根因: 缓存无上限,内存泄漏
修复: 使用带清理的缓存框架
```

---

*案例完成*
