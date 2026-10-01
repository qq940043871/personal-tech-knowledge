# ACID特性

> 模块：事务管理
> 更新时间：2026-03-29

---

## 一、事务概述

```
事务（Transaction）：
  一组原子性的数据库操作序列
  要么全部成功，要么全部失败

ACID特性：
  A - Atomicity（原子性）
  C - Consistency（一致性）
  I - Isolation（隔离性）
  D - Durability（持久性）
```

---

## 二、事务接口

```java
public interface Transaction {
    long getTransactionId();
    void begin();
    void commit();
    void rollback();
    TransactionState getState();
}

public class TransactionImpl implements Transaction {
    private long txId;
    private TransactionState state;
    private List<Operation> operations;
    private TransactionManager manager;
    
    @Override
    public void begin() {
        this.txId = manager.generateTransactionId();
        this.state = TransactionState.ACTIVE;
        this.operations = new ArrayList<>();
        
        // 写入BEGIN日志
        logManager.logBegin(txId);
    }
    
    @Override
    public void commit() {
        if (state != TransactionState.ACTIVE) {
            throw new TransactionException("Transaction not active");
        }
        
        state = TransactionState.COMMITTING;
        
        // 写COMMIT日志
        logManager.logCommit(txId);
        logManager.flushLog();
        
        state = TransactionState.COMMITTED;
    }
    
    @Override
    public void rollback() {
        if (state != TransactionState.ACTIVE) {
            throw new TransactionException("Transaction not active");
        }
        
        state = TransactionState.ROLLING_BACK;
        
        // 回滚所有操作
        for (int i = operations.size() - 1; i >= 0; i--) {
            operations.get(i).undo();
        }
        
        // 写ROLLBACK日志
        logManager.logRollback(txId);
        
        state = TransactionState.ROLLED_BACK;
    }
}

public enum TransactionState {
    ACTIVE,
    COMMITTING,
    COMMITTED,
    ROLLING_BACK,
    ROLLED_BACK
}
```

---

## 三、事务边界

```java
public class TransactionManager {
    private ConcurrentMap<Long, Transaction> activeTransactions;
    private LockManager lockManager;
    private LogManager logManager;
    
    public Transaction beginTransaction() {
        Transaction tx = new TransactionImpl(generateTxId(), this);
        activeTransactions.put(tx.getTransactionId(), tx);
        return tx;
    }
    
    public void commitTransaction(long txId) {
        Transaction tx = activeTransactions.get(txId);
        if (tx == null) {
            throw new TransactionException("Transaction not found");
        }
        
        tx.commit();
        lockManager.releaseAllLocks(txId);
        activeTransactions.remove(txId);
    }
    
    public void rollbackTransaction(long txId) {
        Transaction tx = activeTransactions.get(txId);
        if (tx == null) {
            throw new TransactionException("Transaction not found");
        }
        
        tx.rollback();
        lockManager.releaseAllLocks(txId);
        activeTransactions.remove(txId);
    }
}
```

---

*下一步：锁机制*
