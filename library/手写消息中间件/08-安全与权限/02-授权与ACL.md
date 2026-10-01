# 8.2 授权与 ACL

## 概述

ACL（Access Control List）基于角色的权限控制，定义用户能对哪些资源执行哪些操作。

## 数据库设计

### 表结构：role（角色表）

```sql
CREATE TABLE role (
    role_id            VARCHAR(64)       NOT NULL COMMENT '角色ID',
    role_name          VARCHAR(128)      NOT NULL COMMENT '角色名称',
    description        VARCHAR(512)      DEFAULT NULL COMMENT '角色描述',
    
    -- 角色层级
    parent_role_id     VARCHAR(64)       DEFAULT NULL COMMENT '父角色ID(角色继承)',
    
    -- 状态
    status             ENUM('active', 'disabled') DEFAULT 'active',
    
    -- 审计
    created_at         DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at         DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    
    PRIMARY KEY (role_id),
    UNIQUE KEY uk_name (role_name),
    INDEX idx_parent (parent_role_id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '角色表';
```

### 表结构：permission（权限表）

```sql
CREATE TABLE permission (
    permission_id      VARCHAR(64)       NOT NULL COMMENT '权限ID',
    role_id            VARCHAR(64)       NOT NULL COMMENT '角色ID',
    vhost              VARCHAR(128)      NOT NULL DEFAULT '/' COMMENT '虚拟主机',
    
    -- 资源
    resource_type      ENUM('queue', 'exchange', 'topic', 'connection', 'channel', 'user', 'policy', 'parameter', 'vhost') 
                      NOT NULL COMMENT '资源类型',
    resource_name      VARCHAR(255)      NOT NULL COMMENT '资源名称(支持通配符)',
    
    -- 操作
    actions            JSON             NOT NULL COMMENT '允许的操作列表',
    /*
    示例: ["configure", "write", "read"]
    - configure: 创建/删除队列/交换机
    - write: 发送消息
    - read: 消费消息
    - manage: 管理策略/参数
    */
    
    -- 状态
    active             BOOLEAN           NOT NULL DEFAULT TRUE,
    
    PRIMARY KEY (permission_id),
    INDEX idx_role (role_id),
    INDEX idx_resource (resource_type, resource_name)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '权限表';
```

### 表结构：user_role（用户角色关联表）

```sql
CREATE TABLE user_role (
    id                 BIGINT            NOT NULL AUTO_INCREMENT COMMENT 'ID',
    user_id            VARCHAR(64)       NOT NULL COMMENT '用户ID',
    role_id            VARCHAR(64)       NOT NULL COMMENT '角色ID',
    
    -- 作用域
    vhost              VARCHAR(128)      DEFAULT NULL COMMENT '生效的虚拟主机(NULL=全部)',
    
    -- 时间
    granted_at         DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    expires_at         DATETIME(3)       DEFAULT NULL COMMENT '过期时间',
    
    PRIMARY KEY (id),
    UNIQUE KEY uk_user_role_vhost (user_id, role_id, vhost)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '用户角色关联表';
```

---

## 预置角色

| 角色 | 权限 | 说明 |
|------|------|------|
| `admin` | 全部操作 | 管理员 |
| `monitor` | 只读查询 | 监控人员 |
| `producer` | write | 生产者 |
| `consumer` | read | 消费者 |
| `developer` | configure, write, read | 开发者 |

---

## ACL 检查流程

```
操作请求
   │
   ▼
提取用户身份和目标资源
   │
   ▼
加载用户角色链
   │
   ▼
遍历角色权限
   │
   ├─ 匹配到权限? ──是──▶ 操作允许
   │
   └─ 无匹配 ──▶ 操作拒绝(403 Forbidden)
```

---

*文档版本：v1.0 | 更新日期：2026-03-29*
