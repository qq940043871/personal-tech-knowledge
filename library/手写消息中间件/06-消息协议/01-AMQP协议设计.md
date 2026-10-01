# 6.1 AMQP 协议设计

## 概述

AMQP（Advanced Message Queuing Protocol）是消息中间件的标准协议，定义了消息的格式、路由和传递机制。本系统兼容 AMQP 0-9-1，并支持向 AMQP 1.0 扩展。

## 协议分层架构

```
┌────────────────────────────────────────┐
│           Application Layer            │
│      (消息属性、消息体、业务逻辑)        │
├────────────────────────────────────────┤
│           Session Layer                │
│      (信道管理、事务、确认)              │
├────────────────────────────────────────┤
│           Transport Layer              │
│      (帧编码、心跳、连接管理)            │
└────────────────────────────────────────┘
```

## 数据库设计

### 表结构：amqp_connection（AMQP连接表）

```sql
CREATE TABLE amqp_connection (
    connection_id       VARCHAR(64)      NOT NULL COMMENT '连接ID',
    
    -- 连接信息
    vhost              VARCHAR(128)      NOT NULL DEFAULT '/',
    remote_address     VARCHAR(45)       NOT NULL COMMENT '远程地址',
    remote_port        INT               NOT NULL COMMENT '远程端口',
    local_address      VARCHAR(45)       DEFAULT NULL COMMENT '本地地址',
    
    -- 客户端
    client_properties  JSON             DEFAULT NULL COMMENT '客户端属性',
    /*
    {
      "product": "MyApp",
      "version": "1.0.0",
      "platform": "Java 17",
      "capabilities": {
        "publisher_confirms": true,
        "consumer_cancel_notify": true
      }
    }
    */
    
    -- 连接配置
    channel_max        INT               DEFAULT 0 COMMENT '最大信道数(0=不限)',
    frame_max          INT               DEFAULT 131072 COMMENT '最大帧大小',
    heartbeat          INT               DEFAULT 0 COMMENT '心跳间隔(秒,0=关闭)',
    
    -- 用户
    username           VARCHAR(128)      NOT NULL COMMENT '认证用户',
    
    -- 状态
    status             ENUM('opening', 'running', 'closing', 'closed') DEFAULT 'opening',
    channels_open      INT               NOT NULL DEFAULT 0 COMMENT '打开的信道数',
    
    -- 审计
    connected_at       DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    disconnected_at     DATETIME(3)      DEFAULT NULL,
    close_reason       VARCHAR(512)      DEFAULT NULL COMMENT '关闭原因',
    
    PRIMARY KEY (connection_id),
    INDEX idx_vhost (vhost),
    INDEX idx_status (status),
    INDEX idx_remote (remote_address),
    INDEX idx_username (username)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = 'AMQP连接表';
```

### 表结构：amqp_channel（AMQP信道表）

```sql
CREATE TABLE amqp_channel (
    channel_id         VARCHAR(64)       NOT NULL COMMENT '信道ID',
    connection_id      VARCHAR(64)       NOT NULL COMMENT '所属连接ID',
    channel_number     INT               NOT NULL COMMENT '信道编号',
    
    -- 信道状态
    status             ENUM('opening', 'running', 'flow', 'closing', 'closed') DEFAULT 'opening',
    
    -- 事务
    transaction_active BOOLEAN           NOT NULL DEFAULT FALSE COMMENT '是否有活跃事务',
    transaction_id     VARCHAR(64)       DEFAULT NULL COMMENT '事务ID',
    
    -- 确认
    confirm_mode       BOOLEAN           NOT NULL DEFAULT FALSE COMMENT '是否开启confirm模式',
    unconfirmed_count  INT               NOT NULL DEFAULT 0 COMMENT '未确认消息数',
    
    -- 消费者
    consumer_count     INT               NOT NULL DEFAULT 0 COMMENT '该信道的消费者数',
    
    -- 审计
    opened_at          DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    closed_at          DATETIME(3)       DEFAULT NULL,
    
    PRIMARY KEY (channel_id),
    UNIQUE KEY uk_connection_number (connection_id, channel_number)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = 'AMQP信道表';
```

---

## AMQP 帧类型

| 类型 | 代码 | 说明 |
|------|------|------|
| METHOD | 1 | AMQP 方法帧 |
| HEADER | 2 | 内容头帧 |
| BODY | 3 | 消息体帧 |
| HEARTBEAT | 8 | 心跳帧 |

---

## API 操作

### 查询连接列表

```json
GET /api/v1/connections?vhost=/&status=running
```

### 关闭连接

```json
DELETE /api/v1/connections/{connection_id}
{
  "reason": "管理操作强制关闭"
}
```

---

*文档版本：v1.0 | 更新日期：2026-03-29*
