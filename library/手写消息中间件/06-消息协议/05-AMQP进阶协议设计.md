# 6.5 AMQP 进阶协议设计

## 概述

本章节补充 AMQP 协议的进阶特性设计，包括扩展头、事务增强、流控机制和协议协商等高级功能。

## 数据库设计

### 表结构：amqp_extension_header（AMQP扩展头定义表）

```sql
CREATE TABLE amqp_extension_header (
    header_id         VARCHAR(64)       NOT NULL COMMENT '扩展头ID',
    header_name       VARCHAR(128)      NOT NULL COMMENT '扩展头名称',
    header_code       VARCHAR(64)       NOT NULL COMMENT '头代码(如 x-shared-vhost)',
    protocol_version   VARCHAR(16)      NOT NULL COMMENT '适用协议版本',
    
    -- 定义
    data_type         ENUM('boolean', 'int8', 'int16', 'int32', 'int64', 
                           'float', 'double', 'string', 'binary', 'map', 'list') 
                      NOT NULL COMMENT '数据类型',
    is_mandatory      BOOLEAN           NOT NULL DEFAULT FALSE COMMENT '是否必填',
    default_value     TEXT              DEFAULT NULL COMMENT '默认值',
    valid_range       VARCHAR(256)      DEFAULT NULL COMMENT '有效值范围',
    description        VARCHAR(512)     DEFAULT NULL COMMENT '说明',
    
    -- 兼容性
    deprecated        BOOLEAN           NOT NULL DEFAULT FALSE COMMENT '是否已废弃',
    replacement_id    VARCHAR(64)       DEFAULT NULL COMMENT '替代扩展头ID',
    
    -- 审计
    created_at        DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at        DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    
    PRIMARY KEY (header_id),
    UNIQUE KEY uk_code_version (header_code, protocol_version),
    INDEX idx_protocol (protocol_version),
    INDEX idx_deprecated (deprecated)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = 'AMQP扩展头定义表';
```

### 表结构：amqp_feature_negotiation（协议特性协商表）

```sql
CREATE TABLE amqp_feature_negotiation (
    negotiation_id    VARCHAR(64)       NOT NULL COMMENT '协商ID',
    connection_id      VARCHAR(64)       NOT NULL COMMENT '连接ID',
    
    -- 协商特性
    feature_name       VARCHAR(128)      NOT NULL COMMENT '特性名称',
    feature_version    VARCHAR(32)      NOT NULL COMMENT '特性版本',
    
    -- 协商状态
    client_supported   BOOLEAN          NOT NULL COMMENT '客户端是否支持',
    server_supported   BOOLEAN          NOT NULL COMMENT '服务端是否支持',
    negotiated         BOOLEAN          NOT NULL DEFAULT FALSE COMMENT '是否协商成功',
    negotiated_value   TEXT              DEFAULT NULL COMMENT '协商后的值',
    
    -- 优先级
    priority          INT               NOT NULL DEFAULT 0 COMMENT '协商优先级',
    
    -- 审计
    negotiated_at      DATETIME(3)       NOT NULL COMMENT '协商时间',
    
    PRIMARY KEY (negotiation_id),
    INDEX idx_connection (connection_id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = 'AMQP特性协商记录表';
```

### 表结构：amqp_flow_control（AMQP流控记录表）

```sql
CREATE TABLE amqp_flow_control (
    flow_id           VARCHAR(64)       NOT NULL COMMENT '流控ID',
    channel_id        VARCHAR(64)       NOT NULL COMMENT '信道ID',
    
    -- 令牌桶配置
    token_bucket_enabled BOOLEAN         NOT NULL DEFAULT FALSE COMMENT '是否启用令牌桶',
    token_rate         INT               NOT NULL DEFAULT 0 COMMENT '令牌产生速率(个/秒)',
    bucket_capacity    INT               NOT NULL DEFAULT 0 COMMENT '令牌桶容量',
    available_tokens   INT               NOT NULL DEFAULT 0 COMMENT '当前可用令牌数',
    
    -- 信用控制
    credit_mode       ENUM('none', 'prefetch', 'window') NOT NULL DEFAULT 'prefetch' COMMENT '信用模式',
    credit_value       INT               NOT NULL DEFAULT 10 COMMENT '信用额度',
    
    -- 主动关闭
    drain_enabled     BOOLEAN           NOT NULL DEFAULT FALSE COMMENT '是否启用主动排空',
    
    -- 状态
    is_blocked        BOOLEAN           NOT NULL DEFAULT FALSE COMMENT '信道是否阻塞',
    blocked_reason     VARCHAR(512)      DEFAULT NULL COMMENT '阻塞原因',
    
    -- 审计
    updated_at         DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    
    PRIMARY KEY (flow_id),
    UNIQUE KEY uk_channel (channel_id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = 'AMQP信道流控状态表';
```

---

## AMQP 0-9-1 帧结构详解

### 帧格式

```
┌────────┬────────┬────────┬─────────────────┬────────┐
│ Channel│   Size │ DoM    │    Payload       │  End   │
│  (2B)  │  (4B)  │ (1B)   │    (Size bytes)  │ (1B)   │
└────────┴────────┴────────┴─────────────────┴────────┘
  信道号   帧大小   帧类型    帧内容             帧结束(0xCE)

DoM (Type of Frame):
  0x01 = METHOD     方法帧
  0x02 = HEADER     内容头帧
  0x03 = BODY       消息体帧
  0x08 = HEARTBEAT  心跳帧
```

### 常用方法帧

| 类 | 方法 | 说明 |
|----|------|------|
| Connection | Start / Start-OK | 连接建立 |
| Connection | Tune / Tune-OK | 协商连接参数 |
| Connection | Open / Open-OK | 打开虚拟主机 |
| Channel | Open / Open-OK | 打开信道 |
| Channel | Flow / Flow-OK | 流控 |
| Queue | Declare / Declare-OK | 声明队列 |
| Queue | Bind / Bind-OK | 绑定 |
| Basic | Publish | 发布消息 |
| Basic | Consume / Consume-OK | 开始消费 |
| Basic | Get / Get-OK | 拉取消息 |
| Basic | ACK | 确认 |
| Basic | NACK | 拒绝 |
| Basic | Reject | 拒绝单条 |

---

## Publisher Confirms 机制

```
生产者                              Broker
  │                                  │
  │── Publish(delivery_tag=1) ──────▶│
  │                                  │
  │── Publish(delivery_tag=2) ──────▶│
  │                                  │
  │◀── ACK(delivery_tag=1) ─────────│ (消息持久化成功)
  │                                  │
  │── Publish(delivery_tag=3) ──────▶│
  │                                  │
  │◀── NACK(delivery_tag=2) ─────────│ (持久化失败)
  │   reason: queue_full             │
  │                                  │
  │── Publish(delivery_tag=4) ──────▶│
  │◀── ACK(delivery_tag=3) ─────────│
  │◀── ACK(delivery_tag=4) ─────────│
```

---

## Broker 消息退回（Returns）

```
生产者                              Broker
  │                                  │
  │── Publish(mandatory=true) ──────▶│
  │                                  │
  │     路由失败(无匹配队列)          │
  │                                  │
  │◀── RETURN(300, no_route) ───────│
  │                                  │
```

---

*文档版本：v1.0 | 更新日期：2026-03-29*
