# MVCC多版本并发控制

> 模块：事务管理
> 更新时间：2026-03-29

---

## 一、MVCC原理

```
MVCC（Multi-Version Concurrency Control）：
  - 每个事务看到数据的一致性快照
  - 读写不阻塞
  - 通过版本链实现

关键概念：
  - ReadView：事务的视图
  - transaction_id：创建版本的事务ID
  - roll_pointer：指向旧版本的指针
  - undo日志：存储历史版本
```

---

## 二、版本链

```
行的版本链：
┌────────────┐     ┌────────────┐     ┌────────────┐
│  版本3     │ ←── │  版本2     │ ←── │  版本1     │
│ txId=100   │     │ txId=80    │     │ txId=50    │
│ roll_ptr   │     │ roll_ptr   │     │ roll_ptr   │
└────────────┘     └────────────┘     └────────────┘
     ↑                                     ↓
     └─────────────── undo日志 ─────────────┘
```

---

## 三、ReadView

```java
public class ReadView {
    private long creatorTrxId;
    private List<Long> activeTransactions;
    private long minTrxId;
    private long maxTrxId;
    
    public boolean isVisible(long rowTrxId) {
        // 如果版本由当前事务创建，则可见
        if (rowTrxId == creatorTrxId) {
            return true;
        }
        
        // 如果版本在视图创建前已提交，则可见
        if (rowTrxId < minTrxId) {
            return true;
        }
        
        // 如果版本由未提交事务创建，则不可见
        if (rowTrxId >= maxTrxId) {
            return false;
        }
        
        // 如果版本由活跃事务创建，则不可见
        if (activeTransactions.contains(rowTrxId)) {
            return false;
        }
        
        return true;
    }
}

public class MVCCManager {
    private TransactionManager txManager;
    private UndoLogManager undoManager;
    
    public RowVersion getRowVersion(long pageId, int slot, ReadView readView) {
        // 从最新版本开始遍历版本链
        RowVersion current = loadRowVersion(pageId, slot);
        
        while (current != null) {
            if (readView.isVisible(current.getTransactionId())) {
                return current;
            }
            current = undoManager.getPreviousVersion(current);
        }
        
        return null;  // 没有可见版本
    }
}
```

---

## 四、快照读与当前读

```
快照读（Snapshot Read）：
  SELECT * FROM users  -- 读取快照

当前读（Current Read）：
  SELECT * FROM users FOR UPDATE  -- 读取最新版本
  INSERT/UPDATE/DELETE  -- 读取最新版本
```

---

*下一步：死锁检测*
