# 10.6 JVM 调优与性能诊断

## 概述

JVM 是消息中间件的核心运行环境。本章节提供完整的 JVM 调优指南和性能诊断方法。

## 数据库设计

### 表结构：jvm_diagnostic_snapshot（JVM诊断快照表）

```sql
CREATE TABLE jvm_diagnostic_snapshot (
    snapshot_id        VARCHAR(64)       NOT NULL COMMENT '快照ID',
    node_name          VARCHAR(128)      NOT NULL COMMENT '节点名称',
    
    -- JVM 信息
    jvm_version        VARCHAR(128)      NOT NULL COMMENT 'JVM版本',
    java_version        VARCHAR(128)      NOT NULL COMMENT 'Java版本',
    vm_name            VARCHAR(128)      NOT NULL COMMENT '虚拟机名称',
    
    -- 运行时
    uptime_seconds     BIGINT            NOT NULL COMMENT '运行时长(秒)',
    start_time         DATETIME(3)       NOT NULL COMMENT '启动时间',
    snapshot_time       DATETIME(3)       NOT NULL COMMENT '快照时间',
    
    -- 堆内存
    heap_init_mb      BIGINT            NOT NULL COMMENT '堆初始化(MB)',
    heap_used_mb       BIGINT            NOT NULL COMMENT '堆已用(MB)',
    heap_committed_mb  BIGINT            NOT NULL COMMENT '堆提交(MB)',
    heap_max_mb        BIGINT            NOT NULL COMMENT '堆最大(MB)',
    heap_occupancy_pct DECIMAL(5,2)     NOT NULL COMMENT '堆占用比例(%)',
    
    -- 非堆内存
    nonheap_init_mb   BIGINT            NOT NULL COMMENT '非堆初始化(MB)',
    nonheap_used_mb   BIGINT            NOT NULL COMMENT '非堆已用(MB)',
    metaspace_used_mb BIGINT            NOT NULL COMMENT 'Metaspace已用(MB)',
    code_cache_used_mb BIGINT            NOT NULL COMMENT 'CodeCache已用(MB)',
    
    -- 线程
    thread_count       INT               NOT NULL COMMENT '线程总数',
    peak_thread_count  INT               NOT NULL COMMENT '峰值线程数',
    daemon_thread_count INT              NOT NULL COMMENT '守护线程数',
    
    -- 类加载
    classes_loaded     BIGINT            NOT NULL COMMENT '当前加载类数',
    classes_total_loaded BIGINT          NOT NULL COMMENT '累计加载类数',
    classes_unloaded   BIGINT            NOT NULL COMMENT '卸载类数',
    
    -- GC 统计
    young_gc_count    BIGINT            NOT NULL DEFAULT 0 COMMENT 'Young GC次数',
    young_gc_time_ms  BIGINT            NOT NULL DEFAULT 0 COMMENT 'Young GC总耗时',
    old_gc_count      BIGINT            NOT NULL DEFAULT 0 COMMENT 'Old GC次数',
    old_gc_time_ms    BIGINT            NOT NULL DEFAULT 0 COMMENT 'Old GC总耗时',
    
    -- 系统
    system_load_avg   DECIMAL(5,2)     DEFAULT NULL COMMENT '系统负载均值',
    cpu_usage_pct     DECIMAL(5,2)     DEFAULT NULL COMMENT 'CPU使用率(%)',
    open_fd_count     INT               DEFAULT NULL COMMENT '打开文件描述符数',
    max_fd_count      INT               DEFAULT NULL COMMENT '最大文件描述符数',
    
    PRIMARY KEY (snapshot_id),
    INDEX idx_node_time (node_name, snapshot_time)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = 'JVM诊断快照表';
```

### 表结构：thread_dump_record（线程快照表）

```sql
CREATE TABLE thread_dump_record (
    dump_id            VARCHAR(64)       NOT NULL COMMENT '快照ID',
    node_name          VARCHAR(128)      NOT NULL COMMENT '节点名称',
    snapshot_time       DATETIME(3)       NOT NULL COMMENT '快照时间',
    
    -- 线程信息
    thread_name        VARCHAR(255)      NOT NULL COMMENT '线程名称',
    thread_id          BIGINT            NOT NULL COMMENT '线程ID',
    thread_type        ENUM('user', 'daemon', 'system') NOT NULL COMMENT '线程类型',
    
    -- 状态
    thread_state        VARCHAR(32)       NOT NULL COMMENT '线程状态',
    is_suspended        BOOLEAN          NOT NULL COMMENT '是否挂起',
    is_in_native        BOOLEAN          NOT NULL COMMENT '是否执行本地代码',
    
    -- 堆栈
    stack_trace        TEXT              NOT NULL COMMENT '完整堆栈',
    monitor_info       JSON              DEFAULT NULL COMMENT '锁信息',
    /*
    {
      "locked_monitors": [
        {"class": "java.lang.Object", "identity_hash": "xxx", "locked_at": "stack_frame"}
      ],
      "locked_synchronizers": [
        {"class": "java.util.concurrent.locks.ReentrantLock", "identity_hash": "xxx"}
      ],
      "blocked_on": {"class": "xxx", "identity_hash": "xxx", "blocked_at": "stack_frame"}
    }
    */
    
    -- CPU
    cpu_time_ms        BIGINT            DEFAULT NULL COMMENT 'CPU占用时间(毫秒)',
    
    -- 上下文
    context_class_loader VARCHAR(256)    DEFAULT NULL COMMENT '上下文类加载器',
    stack_depth        INT               NOT NULL COMMENT '堆栈深度',
    
    PRIMARY KEY (dump_id),
    INDEX idx_node_time (node_name, snapshot_time),
    INDEX idx_thread_state (thread_state)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '线程快照表';
```

---

## JVM 调优决策树

```
问题：延迟高
    │
    ├── Young GC 频繁？
    │   ├── 是 → 增大 Young 区大小 (-XX:NewRatio)
    │   └── 否 ↓
    │
    ├── Full GC 频繁？
    │   ├── 是 → 检查内存泄漏 / 增大 Old 区
    │   └── 否 ↓
    │
    ├── STW 暂停长？
    │   ├── 是 → 换用 ZGC 或优化 G1 参数
    │   └── 否 ↓
    │
    └── 线程争用？
        ├── 是 → 检查锁竞争 / 增加线程池
        └── 否 → 排查网络 I/O

问题：吞吐量低
    │
    ├── CPU 使用率低？
    │   ├── 是 → 增加 I/O 线程 / 检查网络瓶颈
    │   └── 否 ↓
    │
    ├── GC 占比高？
    │   ├── 是 → 增大堆 / 减少对象分配
    │   └── 否 ↓
    │
    └── 线程阻塞多？
        └── 是 → 锁分析 / 线程池调优
```

---

## 常用 JVM 诊断命令

### jstat — GC 统计

```bash
# 每1秒输出GC统计，共10次
jstat -gcutil <pid> 1000 10

# 输出:
#   S0     S1     E      O      M     CCS    YGC   YGCT   FGC  FGCT   GCT
#   0.00  12.34  45.67  23.45  95.12  89.34   123  12.3    2   3.4  15.7
```

### jmap — 堆分析

```bash
# 堆直方图（按对象大小排序）
jmap -histo:live <pid> | head -30

# 堆dump
jmap -dump:live,format=b,file=heap.hprof <pid>
```

### jstack — 线程分析

```bash
# 导出线程快照
jstack -l <pid> > thread_dump.txt

# 查找死锁
jstack -l <pid> | grep -A 20 "Found one Java-level deadlock"
```

### jcmd — 综合诊断

```bash
# JVM 信息概览
jcmd <pid> VM.info

# 线程统计
jcmd <pid> Thread.print -l

# 类直方图
jcmd <pid> GC.class_histogram

# 编译器统计
jcmd <pid> Compiler.CompilerStat
```

---

## 常见问题排查

| 症状 | 可能原因 | 诊断方法 | 解决方案 |
|------|---------|---------|---------|
| OOM: Java heap space | 堆内存不足 | jmap -histo | 增大堆 / 修复内存泄漏 |
| OOM: Metaspace | 类加载过多 | -XX:MaxMetaspaceSize | 增大Metaspace |
| GC overhead limit | GC占比>98% | jstat -gcutil | 增大堆 / 优化对象分配 |
| Full GC频繁 | Old区填满快 | jmap -histo:live | 减少长生命周期对象 |
| 线程死锁 | 锁环 | jstack -l | 代码层面修复锁顺序 |
| CPU 100% | 死循环/热点 | jstack + top -Hp | 找到热点线程/方法 |

---

*文档版本：v1.0 | 更新日期：2026-03-29*