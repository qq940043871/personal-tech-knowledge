# Undo日志

> 模块：恢复机制
> 更新时间：2026-03-29

---

## 一、Undo日志原理

```
Undo日志作用：
  - 记录修改前的数据
  - 用于事务回滚
  - 支持MVCC

特点：
  - 记录修改前的值
  - 回滚未提交事务
  - 可循环利用
```

---

## 二、日志记录

```java
public class UndoLogRecord {
    private long undoLSN;       // Undo日志序列号
    private long txId;          // 事务ID
    private long pageId;        // 页ID
    private int offset;         // 行偏移
    private byte[] beforeImage; // 修改前的数据
    private long prevUndoLSN;   // 前一个Undo日志
}
```

---

## 三、回滚流程

```java
public class TransactionRollback {
    private UndoLogManager undoManager;
    private LockManager lockManager;
    
    public void rollback(long txId) {
        // 获取该事务的最后一条Undo日志
        long undoLSN = undoManager.getLastUndoLSN(txId);
        
        while (undoLSN != 0) {
            UndoLogRecord record = undoManager.getUndoLog(undoLSN);
            
            // 应用Undo
            Page page = bufferPool.getPage(record.getPageId());
            page.applyUpdate(record.getOffset(), record.getBeforeImage());
            
            // 移动到前一条Undo
            undoLSN = record.getPrevUndoLSN();
        }
        
        // 释放锁
        lockManager.releaseAllLocks(txId);
    }
}
```

---

*下一步：检查点机制*
