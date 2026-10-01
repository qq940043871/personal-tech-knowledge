# MySQL

> 模块：数据库
> 更新时间：2026-03-29

---

## 一、数据库介绍

MySQL是开源关系型数据库，是Web应用最流行的数据库之一。

**官网**：[https://www.mysql.com](https://www.mysql.com)

**核心特性**：
- 关系型存储
- ACID事务支持
- 主从复制
- 分区表

---

## 二、实际业务应用场景

### 场景1：表设计

```sql
-- 用户表
CREATE TABLE t_user (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    status TINYINT DEFAULT 1,
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 订单表
CREATE TABLE t_order (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    order_no VARCHAR(32) NOT NULL UNIQUE,
    user_id BIGINT NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    status TINYINT DEFAULT 0,
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id)
);
```

### 场景2：事务

```sql
START TRANSACTION;

INSERT INTO t_order (order_no, user_id, total_amount) 
VALUES ('ORD2026032901', 1, 100.00);

COMMIT;
-- 或 ROLLBACK;
```

---

## 三、总结

MySQL是Java后端开发的基础，配合MyBatis使用。

**学习要点**：
1. 索引设计和优化
2. 分页查询
3. 事务隔离级别
4. 主从复制

---

*下一步：Kafka消息队列*
