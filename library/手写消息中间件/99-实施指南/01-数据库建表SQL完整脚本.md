# 数据库建表 SQL 完整脚本

> 本文件整合了所有模块中的建表语句，复制到数据库执行即可初始化完整 schema。

---

## 初始化脚本

```sql
-- ==============================================
-- 消息中间件数据库 - 完整建表脚本
-- 版本: v1.0
-- 日期: 2026-03-29
-- ==============================================

CREATE DATABASE IF NOT EXISTS message_broker
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE message_broker;

-- =============================================
-- 1. 概要设计模块
-- =============================================

-- (无独立表，概要设计为文档说明模块)

-- =============================================
-- 2. 核心数据模型
-- =============================================

-- 2.1 队列元数据表
CREATE TABLE IF NOT EXISTS queue_info (
    queue_id         VARCHAR(64)         NOT NULL COMMENT '队列唯一标识(UUID)',
    queue_name       VARCHAR(255)       NOT NULL COMMENT '队列名称',
    vhost            VARCHAR(128)       NOT NULL DEFAULT '/'  COMMENT '虚拟主机',
    exchange_name    VARCHAR(255)       NOT NULL COMMENT '绑定的交换机名称',
    binding_key      VARCHAR(255)       NOT NULL COMMENT '绑定键',
    queue_type       ENUM('classic', 'quorum', 'stream') NOT NULL DEFAULT 'classic' COMMENT '队列类型',
    durable          BOOLEAN            NOT NULL DEFAULT TRUE COMMENT '是否持久化',
    auto_delete      BOOLEAN            NOT NULL DEFAULT FALSE COMMENT '所有消费者断开后是否自动删除',
    exclusive        BOOLEAN            NOT NULL DEFAULT FALSE COMMENT '是否独占队列',
    arguments        JSON               DEFAULT NULL COMMENT '队列扩展参数(JSON)',
    max_length       BIGINT             DEFAULT NULL COMMENT '队列最大消息数',
    max_bytes        BIGINT             DEFAULT NULL COMMENT '队列最大字节数',
    overflow_policy  ENUM('reject-publish', 'drop-head', 'flow-control') DEFAULT NULL COMMENT '溢出策略',
    dead_letter_exchange   VARCHAR(255)  DEFAULT NULL COMMENT '死信交换机名称',
    dead_letter_routing_key VARCHAR(255)  DEFAULT NULL COMMENT '死信路由键',
    message_ttl      BIGINT             DEFAULT NULL COMMENT '队列默认消息TTL(毫秒)',
    status           ENUM('running', 'suspending', 'deleted') DEFAULT 'running' COMMENT '队列状态',
    message_count    BIGINT             NOT NULL DEFAULT 0 COMMENT '当前消息数量',
    consumer_count   INT                NOT NULL DEFAULT 0 COMMENT '当前消费者数量',
    created_at       DATETIME(3)         NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    updated_at       DATETIME(3)         NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
    deleted_at       DATETIME(3)         DEFAULT NULL COMMENT '软删除时间',
    PRIMARY KEY (queue_id),
    UNIQUE KEY uk_vhost_queue_name (vhost, queue_name),
    INDEX idx_exchange_binding (exchange_name, binding_key),
    INDEX idx_status (status)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '队列元数据表';

-- 2.2 队列统计表
CREATE TABLE IF NOT EXISTS queue_stats (
    stat_id          BIGINT             NOT NULL AUTO_INCREMENT COMMENT '统计记录ID',
    queue_id         VARCHAR(64)        NOT NULL COMMENT '队列ID',
    stat_time        DATETIME(3)        NOT NULL COMMENT '统计时间点',
    message_count    BIGINT             NOT NULL DEFAULT 0 COMMENT '当前消息数',
    message_rate_in  DECIMAL(10,2)      DEFAULT 0 COMMENT '消息入队速率(条/秒)',
    message_rate_out DECIMAL(10,2)      DEFAULT 0 COMMENT '消息出队速率(条/秒)',
    consumer_count   INT                NOT NULL DEFAULT 0 COMMENT '消费者数量',
    unacked_count    BIGINT             NOT NULL DEFAULT 0 COMMENT '未确认消息数',
    queue_size_bytes BIGINT             NOT NULL DEFAULT 0 COMMENT '队列总字节数',
    avg_latency_ms   DECIMAL(10,2)      DEFAULT NULL COMMENT '平均消息延迟(毫秒)',
    PRIMARY KEY (stat_id),
    UNIQUE KEY uk_queue_stat_time (queue_id, stat_time),
    INDEX idx_stat_time (stat_time)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '队列运行时统计表';

-- 2.3 主题元数据表
CREATE TABLE IF NOT EXISTS topic_info (
    topic_id         VARCHAR(64)         NOT NULL COMMENT '主题唯一标识(UUID)',
    topic_name       VARCHAR(255)        NOT NULL COMMENT '主题名称',
    vhost            VARCHAR(128)        NOT NULL DEFAULT '/'  COMMENT '虚拟主机',
    topic_type       ENUM('fanout', 'hierarchical', 'tagged') NOT NULL DEFAULT 'tagged' COMMENT '主题类型',
    durable          BOOLEAN             NOT NULL DEFAULT TRUE COMMENT '是否持久化',
    auto_delete      BOOLEAN             NOT NULL DEFAULT FALSE COMMENT '无订阅者时是否自动删除',
    message_ttl      BIGINT             DEFAULT NULL COMMENT '消息默认TTL(毫秒)',
    max_msg_size     BIGINT             DEFAULT 1048576 COMMENT '单条消息最大字节数(默认1MB)',
    retention_days   INT                DEFAULT 7 COMMENT '消息保留天数',
    compaction       BOOLEAN            NOT NULL DEFAULT FALSE COMMENT '是否启用日志压缩',
    subscription_count  INT               NOT NULL DEFAULT 0 COMMENT '活跃订阅数',
    message_count       BIGINT           NOT NULL DEFAULT 0 COMMENT '当前消息总数',
    byte_count          BIGINT           NOT NULL DEFAULT 0 COMMENT '当前总字节数',
    created_at        DATETIME(3)         NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at        DATETIME(3)         NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    deleted_at        DATETIME(3)         DEFAULT NULL,
    PRIMARY KEY (topic_id),
    UNIQUE KEY uk_vhost_topic_name (vhost, topic_name),
    INDEX idx_topic_type (topic_type)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '主题元数据表';

-- 2.4 消息主表
CREATE TABLE IF NOT EXISTS message (
    message_id           VARCHAR(64)         NOT NULL COMMENT '消息唯一标识(UUID)',
    vhost                VARCHAR(128)       NOT NULL DEFAULT '/' COMMENT '虚拟主机',
    exchange_name        VARCHAR(255)       NOT NULL COMMENT '入站交换机',
    routing_key          VARCHAR(1024)      NOT NULL COMMENT '入站路由键',
    destination_type     ENUM('queue', 'topic') NOT NULL COMMENT '目的地类型',
    destination_id       VARCHAR(64)        NOT NULL COMMENT '目的地ID(队列或主题ID)',
    content_type         VARCHAR(128)       DEFAULT 'application/json' COMMENT '内容类型',
    content_encoding     VARCHAR(64)        DEFAULT 'utf-8' COMMENT '内容编码',
    delivery_mode        TINYINT            NOT NULL DEFAULT 1 COMMENT '1=非持久, 2=持久',
    priority             TINYINT            NOT NULL DEFAULT 5 COMMENT '优先级 0-9',
    message_timestamp    DATETIME(3)        NOT NULL COMMENT '消息创建时间',
    payload_size         INT                NOT NULL COMMENT '消息体大小(字节)',
    payload_checksum     VARCHAR(32)        DEFAULT NULL COMMENT '消息体校验和(MD5)',
    payload_ref          VARCHAR(512)       DEFAULT NULL COMMENT '大消息体引用(外部存储)',
    producer_id          VARCHAR(64)        NOT NULL COMMENT '生产者ID',
    producer_session_id  VARCHAR(64)        DEFAULT NULL COMMENT '生产者会话ID',
    user_id              VARCHAR(128)       DEFAULT NULL COMMENT '应用级用户ID',
    message_status       ENUM('pending', 'delivered', 'acknowledged', 'dead', 'expired') 
                         NOT NULL DEFAULT 'pending' COMMENT '消息状态',
    redelivered          BOOLEAN            NOT NULL DEFAULT FALSE COMMENT '是否重投',
    redelivery_count     INT                NOT NULL DEFAULT 0 COMMENT '重投次数',
    expiration           BIGINT             DEFAULT NULL COMMENT '消息过期时间(毫秒Unix时间戳)',
    ttl                  BIGINT             DEFAULT NULL COMMENT 'TTL(毫秒)',
    delivery_start_time  DATETIME(3)        DEFAULT NULL COMMENT '可开始投递时间(延迟消息)',
    transaction_id       VARCHAR(64)        DEFAULT NULL COMMENT '所属事务ID',
    is_transactional     BOOLEAN            NOT NULL DEFAULT FALSE COMMENT '是否事务消息',
    correlation_id       VARCHAR(255)       DEFAULT NULL COMMENT '关联ID(用于响应链)',
    reply_to             VARCHAR(255)       DEFAULT NULL COMMENT '回复目标地址',
    created_at            DATETIME(3)        NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at            DATETIME(3)        NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (message_id),
    INDEX idx_destination (destination_type, destination_id),
    INDEX idx_status (message_status),
    INDEX idx_expiration (expiration),
    INDEX idx_delivery_start (delivery_start_time),
    INDEX idx_timestamp (message_timestamp),
    INDEX idx_producer (producer_id),
    INDEX idx_routing_key (routing_key(255)),
    INDEX idx_transaction (transaction_id),
    INDEX idx_correlation (correlation_id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '消息主表';

-- 2.5 消息扩展属性表
CREATE TABLE IF NOT EXISTS message_header (
    id              BIGINT            NOT NULL AUTO_INCREMENT COMMENT '属性ID',
    message_id      VARCHAR(64)       NOT NULL COMMENT '消息ID',
    header_key      VARCHAR(255)      NOT NULL COMMENT '属性键',
    header_value    TEXT              NOT NULL COMMENT '属性值(JSON序列化)',
    header_type     ENUM('string', 'number', 'boolean', 'json') DEFAULT 'string' COMMENT '值类型',
    is_system       BOOLEAN           NOT NULL DEFAULT FALSE COMMENT '是否系统属性',
    created_at      DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    UNIQUE KEY uk_message_header (message_id, header_key),
    INDEX idx_message (message_id),
    INDEX idx_header_key (header_key)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '消息扩展属性表';

-- 2.6 消费者元数据表
CREATE TABLE IF NOT EXISTS consumer_info (
    consumer_id         VARCHAR(64)         NOT NULL COMMENT '消费者唯一标识(UUID)',
    consumer_tag        VARCHAR(255)        NOT NULL COMMENT '消费者标签(客户端指定)',
    vhost               VARCHAR(128)       NOT NULL DEFAULT '/' COMMENT '虚拟主机',
    user_id             VARCHAR(128)       DEFAULT NULL COMMENT '所属用户ID',
    application_id      VARCHAR(128)      DEFAULT NULL COMMENT '应用ID',
    connection_id       VARCHAR(64)        NOT NULL COMMENT '所属连接ID',
    remote_ip           VARCHAR(45)        DEFAULT NULL COMMENT '客户端IP',
    client_name         VARCHAR(255)       DEFAULT NULL COMMENT '客户端名称',
    client_version      VARCHAR(64)        DEFAULT NULL COMMENT '客户端版本',
    protocol_version    VARCHAR(16)        DEFAULT NULL COMMENT '协议版本',
    consume_mode        ENUM('exclusive', 'shared', 'work') NOT NULL DEFAULT 'shared' COMMENT '消费模式',
    prefetch_count      INT                NOT NULL DEFAULT 10 COMMENT '预取消息数量',
    prefetch_size       INT                DEFAULT 0 COMMENT '预取大小(字节)',
    auto_ack            BOOLEAN            NOT NULL DEFAULT FALSE COMMENT '是否自动确认',
    status              ENUM('active', 'idle', 'paused', 'disconnected') DEFAULT 'active' COMMENT '消费者状态',
    last_heartbeat      DATETIME(3)        DEFAULT NULL COMMENT '最后心跳时间',
    messages_consumed   BIGINT             NOT NULL DEFAULT 0 COMMENT '累计消费消息数',
    bytes_consumed      BIGINT             NOT NULL DEFAULT 0 COMMENT '累计消费字节数',
    avg_latency_ms      DECIMAL(10,3)      DEFAULT NULL COMMENT '平均消费延迟(毫秒)',
    connected_at        DATETIME(3)        NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '连接时间',
    disconnected_at     DATETIME(3)        DEFAULT NULL COMMENT '断开时间',
    created_at          DATETIME(3)        NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at          DATETIME(3)        NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (consumer_id),
    UNIQUE KEY uk_connection_tag (connection_id, consumer_tag),
    INDEX idx_vhost_user (vhost, user_id),
    INDEX idx_status (status),
    INDEX idx_connection (connection_id),
    INDEX idx_last_heartbeat (last_heartbeat)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '消费者元数据表';

-- 2.7 消费者偏移量表
CREATE TABLE IF NOT EXISTS consumer_offset (
    offset_id          VARCHAR(64)        NOT NULL COMMENT '偏移量记录ID',
    consumer_id        VARCHAR(64)        NOT NULL COMMENT '消费者ID',
    destination_type   ENUM('queue', 'topic') NOT NULL COMMENT '目的地类型',
    destination_id     VARCHAR(64)        NOT NULL COMMENT '目的地ID',
    offset             BIGINT             NOT NULL COMMENT '当前消费偏移量',
    offset_type        ENUM('message_id', 'sequence', 'timestamp', 'log_offset') NOT NULL DEFAULT 'sequence' COMMENT '偏移量类型',
    partition_id       INT                DEFAULT NULL COMMENT '分区ID',
    pending_offset     BIGINT             DEFAULT NULL COMMENT '待确认的偏移量(in-flight)',
    acknowledged_offset BIGINT             DEFAULT NULL COMMENT '已确认的最大偏移量',
    last_consumed_at   DATETIME(3)        DEFAULT NULL COMMENT '最后消费时间',
    lag                BIGINT             DEFAULT 0 COMMENT '当前消费滞后量',
    created_at         DATETIME(3)        NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at         DATETIME(3)        NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (offset_id),
    UNIQUE KEY uk_consumer_destination_offset (consumer_id, destination_type, destination_id, partition_id),
    INDEX idx_offset (destination_type, destination_id, partition_id, offset)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '消费者消费偏移量表';

-- 2.8 生产者元数据表
CREATE TABLE IF NOT EXISTS producer_info (
    producer_id         VARCHAR(64)         NOT NULL COMMENT '生产者唯一标识(UUID)',
    producer_name       VARCHAR(255)       NOT NULL COMMENT '生产者名称(客户端指定)',
    vhost               VARCHAR(128)       NOT NULL DEFAULT '/' COMMENT '虚拟主机',
    user_id             VARCHAR(128)       DEFAULT NULL COMMENT '所属用户ID',
    application_id      VARCHAR(128)      DEFAULT NULL COMMENT '应用ID',
    connection_id       VARCHAR(64)        NOT NULL COMMENT '所属连接ID',
    remote_ip           VARCHAR(45)        DEFAULT NULL COMMENT '客户端IP',
    client_name         VARCHAR(255)       DEFAULT NULL COMMENT '客户端名称',
    client_version      VARCHAR(64)        DEFAULT NULL COMMENT '客户端版本',
    protocol_version    VARCHAR(16)        DEFAULT NULL COMMENT '协议版本',
    publisher_confirms  BOOLEAN            NOT NULL DEFAULT FALSE COMMENT '是否启用发布确认',
    publisher_returns   BOOLEAN            NOT NULL DEFAULT FALSE COMMENT '是否启用退回消息',
    channel_max         INT                DEFAULT 0 COMMENT '最大信道数',
    status              ENUM('active', 'idle', 'blocked', 'disconnected') DEFAULT 'active',
    last_heartbeat      DATETIME(3)        DEFAULT NULL COMMENT '最后心跳时间',
    messages_sent       BIGINT             NOT NULL DEFAULT 0 COMMENT '累计发送消息数',
    bytes_sent          BIGINT             NOT NULL DEFAULT 0 COMMENT '累计发送字节数',
    confirm_success     BIGINT             NOT NULL DEFAULT 0 COMMENT '确认成功次数',
    confirm_failed      BIGINT             NOT NULL DEFAULT 0 COMMENT '确认失败次数',
    return_count        BIGINT             NOT NULL DEFAULT 0 COMMENT '退回消息次数',
    connected_at        DATETIME(3)        NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    disconnected_at     DATETIME(3)        DEFAULT NULL,
    created_at          DATETIME(3)        NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at          DATETIME(3)        NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (producer_id),
    UNIQUE KEY uk_connection_name (connection_id, producer_name),
    INDEX idx_vhost_user (vhost, user_id),
    INDEX idx_status (status)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '生产者元数据表';

-- 2.9 交换机元数据表
CREATE TABLE IF NOT EXISTS exchange_info (
    exchange_id        VARCHAR(64)       NOT NULL COMMENT '交换机ID(UUID)',
    exchange_name      VARCHAR(255)       NOT NULL COMMENT '交换机名称',
    vhost              VARCHAR(128)      NOT NULL DEFAULT '/' COMMENT '虚拟主机',
    exchange_type      ENUM('direct', 'fanout', 'topic', 'headers') NOT NULL COMMENT '交换机类型',
    durable            BOOLEAN           NOT NULL DEFAULT TRUE COMMENT '是否持久化',
    auto_delete        BOOLEAN           NOT NULL DEFAULT FALSE COMMENT '无绑定关系时自动删除',
    internal           BOOLEAN           NOT NULL DEFAULT FALSE COMMENT '是否为内部交换机',
    arguments          JSON              DEFAULT NULL COMMENT '扩展参数',
    alternate_exchange VARCHAR(255)       DEFAULT NULL COMMENT '备用交换机',
    binding_count      INT               NOT NULL DEFAULT 0 COMMENT '绑定数量',
    message_in_count   BIGINT            NOT NULL DEFAULT 0 COMMENT '累计接收消息数',
    message_out_count  BIGINT            NOT NULL DEFAULT 0 COMMENT '累计转发消息数',
    message_drop_count BIGINT            NOT NULL DEFAULT 0 COMMENT '累计丢弃消息数',
    status             ENUM('running', 'stopped', 'deleted') DEFAULT 'running',
    created_at         DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at         DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    deleted_at         DATETIME(3)        DEFAULT NULL,
    PRIMARY KEY (exchange_id),
    UNIQUE KEY uk_vhost_name (vhost, exchange_name),
    INDEX idx_type (exchange_type),
    INDEX idx_status (status)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '交换机元数据表';

-- 2.10 绑定关系表
CREATE TABLE IF NOT EXISTS binding (
    binding_id         VARCHAR(64)       NOT NULL COMMENT '绑定ID(UUID)',
    source_exchange    VARCHAR(255)      NOT NULL COMMENT '源交换机名称',
    destination_type   ENUM('queue', 'exchange') NOT NULL DEFAULT 'queue' COMMENT '目标类型',
    destination_name   VARCHAR(255)      NOT NULL COMMENT '目标队列或交换机名称',
    vhost              VARCHAR(128)      NOT NULL DEFAULT '/',
    binding_key        VARCHAR(1024)     DEFAULT '' COMMENT '绑定键',
    binding_headers    JSON              DEFAULT NULL COMMENT '头匹配规则(Headers交换机)',
    arguments          JSON              DEFAULT NULL COMMENT '扩展参数',
    is_dlx             BOOLEAN           NOT NULL DEFAULT FALSE COMMENT '是否为死信绑定',
    active             BOOLEAN           NOT NULL DEFAULT TRUE COMMENT '是否激活',
    messages_routed    BIGINT            NOT NULL DEFAULT 0 COMMENT '累计路由消息数',
    created_at         DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at         DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (binding_id),
    UNIQUE KEY uk_source_dest_key (vhost, source_exchange, destination_type, destination_name, binding_key),
    INDEX idx_source (source_exchange),
    INDEX idx_destination (destination_type, destination_name),
    INDEX idx_active (active)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '绑定关系表';

-- =============================================
-- 3. 消息管理
-- =============================================

-- 3.1 消息生命周期状态表
CREATE TABLE IF NOT EXISTS message_lifecycle (
    lifecycle_id        VARCHAR(64)       NOT NULL COMMENT '生命周期记录ID',
    message_id          VARCHAR(64)       NOT NULL COMMENT '消息ID',
    current_state       ENUM('created', 'confirmed', 'ready', 'in_flight', 'backlog', 
                              'acknowledged', 'redelivered', 'dead_letter', 'expired', 'archived') 
                         NOT NULL DEFAULT 'created',
    state_changed_at   DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '状态变更时间',
    consumer_id         VARCHAR(64)       DEFAULT NULL COMMENT '当前持有消费者ID',
    delivery_tag        BIGINT            DEFAULT NULL COMMENT '投递标签',
    delivery_start_at   DATETIME(3)       DEFAULT NULL COMMENT '开始投递时间',
    redelivery_count    INT               NOT NULL DEFAULT 0 COMMENT '重投次数',
    max_redeliveries    INT               NOT NULL DEFAULT 10 COMMENT '最大重投次数',
    last_redelivery_at  DATETIME(3)       DEFAULT NULL COMMENT '上次重投时间',
    redelivery_reason   VARCHAR(512)      DEFAULT NULL COMMENT '重投原因',
    created_at          DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    expires_at          DATETIME(3)       DEFAULT NULL COMMENT '过期时间',
    archived_at         DATETIME(3)       DEFAULT NULL COMMENT '归档时间',
    state_history       JSON              DEFAULT NULL COMMENT '状态历史变更链',
    PRIMARY KEY (lifecycle_id),
    UNIQUE KEY uk_message (message_id),
    INDEX idx_current_state (current_state),
    INDEX idx_consumer (consumer_id),
    INDEX idx_expires (expires_at)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '消息生命周期状态表';

-- 3.2 存储分段表
CREATE TABLE IF NOT EXISTS storage_segment (
    segment_id          VARCHAR(64)       NOT NULL COMMENT '分段ID',
    destination_type    ENUM('queue', 'topic') NOT NULL COMMENT '目的地类型',
    destination_id      VARCHAR(64)       NOT NULL COMMENT '目的地ID',
    partition_id        INT               DEFAULT 0 COMMENT '分区ID',
    segment_index       INT               NOT NULL COMMENT '分段序号',
    segment_type        ENUM('write', 'read', 'archive') DEFAULT 'write' COMMENT '分段类型',
    file_path           VARCHAR(1024)     NOT NULL COMMENT '物理文件路径',
    file_size           BIGINT            NOT NULL DEFAULT 0 COMMENT '当前文件大小(字节)',
    max_file_size       BIGINT            NOT NULL DEFAULT 536870912 COMMENT '最大文件大小(默认512MB)',
    start_offset        BIGINT            NOT NULL COMMENT '起始偏移量',
    end_offset          BIGINT            NOT NULL COMMENT '结束偏移量',
    message_count       INT               NOT NULL DEFAULT 0 COMMENT '消息数量',
    status              ENUM('active', 'sealed', 'archived', 'deleted') DEFAULT 'active',
    sealed_at           DATETIME(3)       DEFAULT NULL COMMENT '封存时间',
    first_message_time  DATETIME(3)       DEFAULT NULL COMMENT '首条消息时间',
    last_message_time   DATETIME(3)       DEFAULT NULL COMMENT '末条消息时间',
    created_at          DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at          DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (segment_id),
    UNIQUE KEY uk_destination_segment (destination_type, destination_id, partition_id, segment_index),
    INDEX idx_destination_status (destination_type, destination_id, status),
    INDEX idx_file_path (file_path)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '存储分段表';

-- =============================================
-- 4. 高可用与集群
-- =============================================

-- 4.1 集群节点表
CREATE TABLE IF NOT EXISTS cluster_node (
    node_id            VARCHAR(64)       NOT NULL COMMENT '节点ID',
    node_name          VARCHAR(128)      NOT NULL COMMENT '节点名称',
    host               VARCHAR(255)      NOT NULL COMMENT '主机地址',
    port               INT               NOT NULL DEFAULT 5672 COMMENT 'AMQP端口',
    management_port    INT               DEFAULT 15672 COMMENT '管理API端口',
    cluster_id         VARCHAR(64)       NOT NULL COMMENT '所属集群ID',
    node_type          ENUM('leader', 'follower', 'standalone') DEFAULT 'standalone' COMMENT '节点类型',
    role               ENUM('primary', 'secondary', 'arbiter') DEFAULT 'primary' COMMENT '角色',
    data_center        VARCHAR(64)       DEFAULT NULL COMMENT '数据中心',
    cpu_cores          INT               DEFAULT NULL COMMENT 'CPU核心数',
    memory_bytes       BIGINT            DEFAULT NULL COMMENT '内存大小',
    disk_bytes         BIGINT            DEFAULT NULL COMMENT '磁盘大小',
    status             ENUM('running', 'stopped', 'joining', 'leaving', 'failed') DEFAULT 'running',
    version            VARCHAR(32)       DEFAULT NULL COMMENT '节点版本',
    uptime_seconds     BIGINT            DEFAULT 0 COMMENT '运行时间(秒)',
    connections_count  INT               NOT NULL DEFAULT 0 COMMENT '连接数',
    channels_count     INT               NOT NULL DEFAULT 0 COMMENT '信道数',
    queues_count       INT               NOT NULL DEFAULT 0 COMMENT '队列数',
    consumers_count    INT               NOT NULL DEFAULT 0 COMMENT '消费者数',
    joined_at          DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '加入集群时间',
    last_heartbeat_at  DATETIME(3)       DEFAULT NULL COMMENT '最后心跳',
    PRIMARY KEY (node_id),
    UNIQUE KEY uk_node_name (node_name),
    INDEX idx_cluster (cluster_id),
    INDEX idx_status (status)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '集群节点表';

-- 4.2 集群配置表
CREATE TABLE IF NOT EXISTS cluster_config (
    cluster_id         VARCHAR(64)       NOT NULL COMMENT '集群ID',
    cluster_name       VARCHAR(128)      NOT NULL COMMENT '集群名称',
    consensus_algorithm ENUM('raft', 'gossip', 'zab', 'paxos') DEFAULT 'raft' COMMENT '共识算法',
    election_timeout_ms BIGINT            NOT NULL DEFAULT 5000 COMMENT '选举超时(毫秒)',
    heartbeat_interval_ms BIGINT          NOT NULL DEFAULT 1000 COMMENT '心跳间隔(毫秒)',
    default_replicas   INT               NOT NULL DEFAULT 2 COMMENT '默认副本数',
    discovery_type     ENUM('static', 'dns', 'etcd', 'k8s') DEFAULT 'static' COMMENT '节点发现方式',
    discovery_config   JSON              DEFAULT NULL COMMENT '发现配置',
    status             ENUM('healthy', 'degraded', 'unavailable') DEFAULT 'healthy',
    node_count         INT               NOT NULL DEFAULT 1 COMMENT '节点数',
    created_at         DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at         DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (cluster_id),
    UNIQUE KEY uk_name (cluster_name)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '集群配置表';

-- =============================================
-- 5. 安全与权限
-- =============================================

-- 5.1 用户表
CREATE TABLE IF NOT EXISTS user (
    user_id            VARCHAR(64)       NOT NULL COMMENT '用户ID',
    username           VARCHAR(128)      NOT NULL COMMENT '用户名',
    vhost              VARCHAR(128)      DEFAULT '/' COMMENT '默认虚拟主机',
    auth_type          ENUM('password', 'token', 'certificate', 'ldap', 'oauth2') 
                      NOT NULL DEFAULT 'password' COMMENT '认证方式',
    password_hash      VARCHAR(255)      DEFAULT NULL COMMENT '密码哈希(bcrypt)',
    salt               VARCHAR(64)       DEFAULT NULL COMMENT '盐值',
    access_token       VARCHAR(512)      DEFAULT NULL COMMENT '访问令牌',
    token_expires_at   DATETIME(3)       DEFAULT NULL COMMENT '令牌过期时间',
    status             ENUM('active', 'disabled', 'locked') DEFAULT 'active',
    login_attempts     INT               NOT NULL DEFAULT 0 COMMENT '连续登录失败次数',
    max_login_attempts INT               NOT NULL DEFAULT 5 COMMENT '最大登录尝试',
    locked_until       DATETIME(3)       DEFAULT NULL COMMENT '锁定截止时间',
    tags               JSON              DEFAULT NULL COMMENT '用户标签',
    created_at         DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at         DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    last_login_at      DATETIME(3)       DEFAULT NULL COMMENT '最后登录时间',
    PRIMARY KEY (user_id),
    UNIQUE KEY uk_username (username)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '用户表';

-- 5.2 角色表
CREATE TABLE IF NOT EXISTS role (
    role_id            VARCHAR(64)       NOT NULL COMMENT '角色ID',
    role_name          VARCHAR(128)      NOT NULL COMMENT '角色名称',
    description        VARCHAR(512)      DEFAULT NULL COMMENT '角色描述',
    parent_role_id     VARCHAR(64)       DEFAULT NULL COMMENT '父角色ID',
    status             ENUM('active', 'disabled') DEFAULT 'active',
    created_at         DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at         DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (role_id),
    UNIQUE KEY uk_name (role_name)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '角色表';

-- 5.3 权限表
CREATE TABLE IF NOT EXISTS permission (
    permission_id      VARCHAR(64)       NOT NULL COMMENT '权限ID',
    role_id            VARCHAR(64)       NOT NULL COMMENT '角色ID',
    vhost              VARCHAR(128)      NOT NULL DEFAULT '/' COMMENT '虚拟主机',
    resource_type      ENUM('queue', 'exchange', 'topic', 'connection', 'channel', 'user', 'policy', 'parameter', 'vhost') 
                      NOT NULL COMMENT '资源类型',
    resource_name      VARCHAR(255)      NOT NULL COMMENT '资源名称(支持通配符)',
    actions            JSON              NOT NULL COMMENT '允许的操作列表',
    active             BOOLEAN           NOT NULL DEFAULT TRUE,
    PRIMARY KEY (permission_id),
    INDEX idx_role (role_id),
    INDEX idx_resource (resource_type, resource_name)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '权限表';

-- 5.4 审计日志表
CREATE TABLE IF NOT EXISTS audit_log (
    log_id             BIGINT            NOT NULL AUTO_INCREMENT COMMENT '日志ID',
    user_id            VARCHAR(64)       DEFAULT NULL COMMENT '操作用户ID',
    username           VARCHAR(128)      DEFAULT NULL COMMENT '操作用户名',
    client_ip          VARCHAR(45)       DEFAULT NULL COMMENT '客户端IP',
    session_id         VARCHAR(64)       DEFAULT NULL COMMENT '会话ID',
    operation_type     ENUM('create', 'update', 'delete', 'read', 'config_change', 
                           'auth_success', 'auth_failure', 'acl_check', 'admin_action') 
                      NOT NULL COMMENT '操作类型',
    resource_type      VARCHAR(64)       NOT NULL COMMENT '资源类型',
    resource_name      VARCHAR(255)      DEFAULT NULL COMMENT '资源名称',
    resource_id        VARCHAR(64)       DEFAULT NULL COMMENT '资源ID',
    success            BOOLEAN           NOT NULL DEFAULT TRUE COMMENT '是否成功',
    error_message      TEXT              DEFAULT NULL COMMENT '错误信息',
    event_time         DATETIME(3)       NOT NULL COMMENT '事件时间',
    duration_ms        INT               DEFAULT NULL COMMENT '操作耗时(毫秒)',
    archived           BOOLEAN           NOT NULL DEFAULT FALSE COMMENT '是否已归档',
    PRIMARY KEY (log_id),
    INDEX idx_user_time (user_id, event_time),
    INDEX idx_resource (resource_type, resource_id),
    INDEX idx_type (operation_type),
    INDEX idx_event_time (event_time)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '审计日志表';

-- =============================================
-- 6. 监控与运维
-- =============================================

-- 6.1 告警规则表
CREATE TABLE IF NOT EXISTS alert_rule (
    rule_id            VARCHAR(64)       NOT NULL COMMENT '规则ID',
    rule_name          VARCHAR(255)      NOT NULL COMMENT '规则名称',
    metric_name        VARCHAR(128)      NOT NULL COMMENT '监控指标',
    condition_type     ENUM('threshold', 'rate', 'absence', 'anomaly') NOT NULL COMMENT '条件类型',
    operator           ENUM('gt', 'gte', 'lt', 'lte', 'eq', 'neq') NOT NULL COMMENT '比较运算符',
    threshold          DOUBLE            NOT NULL COMMENT '阈值',
    duration_seconds   INT               DEFAULT 0 COMMENT '持续时长(秒)',
    severity           ENUM('critical', 'warning', 'info') NOT NULL COMMENT '告警级别',
    notify_channels    JSON              NOT NULL COMMENT '通知渠道',
    silence_period_min INT               DEFAULT 0 COMMENT '静默周期(分钟)',
    repeat_interval_min INT              DEFAULT 60 COMMENT '重复通知间隔(分钟)',
    enabled            BOOLEAN           NOT NULL DEFAULT TRUE,
    labels             JSON              DEFAULT NULL COMMENT '告警标签',
    created_at         DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at         DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (rule_id),
    UNIQUE KEY uk_name (rule_name),
    INDEX idx_metric (metric_name),
    INDEX idx_severity (severity),
    INDEX idx_enabled (enabled)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '告警规则表';

-- 6.2 运维操作记录表
CREATE TABLE IF NOT EXISTS ops_record (
    ops_id             VARCHAR(64)       NOT NULL COMMENT '操作记录ID',
    operator_id        VARCHAR(64)       NOT NULL COMMENT '操作人ID',
    operator_name      VARCHAR(128)      NOT NULL COMMENT '操作人名称',
    operation_type     ENUM('queue_create', 'queue_delete', 'queue_purge', 'connection_close',
                           'consumer_kick', 'policy_set', 'cluster_restart', 'backup', 'restore',
                           'config_change', 'failover_trigger') NOT NULL COMMENT '操作类型',
    resource_type      VARCHAR(64)       DEFAULT NULL COMMENT '资源类型',
    resource_id        VARCHAR(64)       DEFAULT NULL COMMENT '资源ID',
    resource_name      VARCHAR(255)      DEFAULT NULL COMMENT '资源名称',
    description        TEXT              DEFAULT NULL COMMENT '操作描述',
    params             JSON              DEFAULT NULL COMMENT '操作参数',
    result             TEXT              DEFAULT NULL COMMENT '操作结果',
    affected_messages  INT               DEFAULT NULL COMMENT '影响消息数',
    affected_consumers INT               DEFAULT NULL COMMENT '影响消费者数',
    executed_at        DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    client_ip          VARCHAR(45)       DEFAULT NULL COMMENT '操作来源IP',
    PRIMARY KEY (ops_id),
    INDEX idx_operator (operator_id),
    INDEX idx_type (operation_type),
    INDEX idx_time (executed_at)
) ENGINE = InnoDB DEFAULT CHARS