# MiniIO集群与运维

> 模块：运维配置
> 更新时间：2026-04-06

---

## 一、分布式集群部署

### 1.1 集群架构

```
┌─────────────────────────────────────────────────────────────┐
│                      负载均衡器 (Nginx/HAProxy)              │
└─────────────────────────┬───────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ▼                 ▼                 ▼
┌───────────────┐ ┌───────────────┐ ┌───────────────┐
│   MinIO Node1 │ │   MinIO Node2 │ │   MinIO Node3 │
│   /data1      │ │   /data1      │ │   /data1      │
│   /data2      │ │   /data2      │ │   /data2      │
└───────────────┘ └───────────────┘ └───────────────┘
        │                 │                 │
        └─────────────────┼─────────────────┘
                          │
                  纠删码存储 (EC:2)
```

### 1.2 Docker Compose集群

```yaml
version: '3.8'

services:
  minio1:
    image: minio/minio:latest
    hostname: minio1
    ports:
      - "9001:9000"
      - "9002:9001"
    volumes:
      - data1-1:/data1
      - data1-2:/data2
    environment:
      MINIO_ROOT_USER: admin
      MINIO_ROOT_PASSWORD: admin123456
    command: server http://minio{1...4}/data{1...2} --console-address ":9001"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 20s
      retries: 3

  minio2:
    image: minio/minio:latest
    hostname: minio2
    ports:
      - "9003:9000"
      - "9004:9001"
    volumes:
      - data2-1:/data1
      - data2-2:/data2
    environment:
      MINIO_ROOT_USER: admin
      MINIO_ROOT_PASSWORD: admin123456
    command: server http://minio{1...4}/data{1...2} --console-address ":9001"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 20s
      retries: 3

  minio3:
    image: minio/minio:latest
    hostname: minio3
    ports:
      - "9005:9000"
      - "9006:9001"
    volumes:
      - data3-1:/data1
      - data3-2:/data2
    environment:
      MINIO_ROOT_USER: admin
      MINIO_ROOT_PASSWORD: admin123456
    command: server http://minio{1...4}/data{1...2} --console-address ":9001"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 20s
      retries: 3

  minio4:
    image: minio/minio:latest
    hostname: minio4
    ports:
      - "9007:9000"
      - "9008:9001"
    volumes:
      - data4-1:/data1
      - data4-2:/data2
    environment:
      MINIO_ROOT_USER: admin
      MINIO_ROOT_PASSWORD: admin123456
    command: server http://minio{1...4}/data{1...2} --console-address ":9001"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 20s
      retries: 3

  nginx:
    image: nginx:latest
    ports:
      - "9000:9000"
      - "9090:9090"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - minio1
      - minio2
      - minio3
      - minio4

volumes:
  data1-1:
  data1-2:
  data2-1:
  data2-2:
  data3-1:
  data3-2:
  data4-1:
  data4-2:
```

### 1.3 Nginx负载均衡配置

```nginx
events {
    worker_connections 1024;
}

http {
    upstream minio_api {
        least_conn;
        server minio1:9000;
        server minio2:9000;
        server minio3:9000;
        server minio4:9000;
    }

    upstream minio_console {
        least_conn;
        server minio1:9001;
        server minio2:9001;
        server minio3:9001;
        server minio4:9001;
    }

    server {
        listen 9000;
        server_name localhost;

        client_max_body_size 1000m;
        client_body_timeout 300s;

        location / {
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_connect_timeout 300;
            proxy_http_version 1.1;
            proxy_set_header Connection "";
            chunked_transfer_encoding off;
            proxy_pass http://minio_api;
        }
    }

    server {
        listen 9090;
        server_name localhost;

        location / {
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_pass http://minio_console;
        }
    }
}
```

---

## 二、纠删码配置

### 2.1 纠删码原理

```
EC:N 表示数据分片和校验分片

EC:2 (默认) - 4节点集群
├── 数据分片: 2
├── 校验分片: 2
└── 容错能力: 可丢失2个分片

数据写入流程:
原始数据 → 分片 → 计算校验 → 分布存储
  10MB   →  5MB  × 4分片 → 4个节点

数据恢复流程:
部分分片 → 解码计算 → 原始数据
  2分片  →  解码    →  10MB
```

### 2.2 存储容量计算

```
有效容量 = 原始容量 × (数据分片 / 总分片)

示例: 4节点 × 2盘 × 1TB = 8TB
EC:2 配置: 8TB × (2/4) = 4TB 有效容量
```

---

## 三、监控配置

### 3.1 Prometheus监控

```yaml
scrape_configs:
  - job_name: 'minio'
    metrics_path: /minio/v2/metrics/cluster
    scheme: http
    static_configs:
      - targets: ['minio1:9000', 'minio2:9000', 'minio3:9000', 'minio4:9000']
```

### 3.2 关键监控指标

```
minio_cluster_disk_total_bytes         # 总存储容量
minio_cluster_disk_used_bytes           # 已用存储
minio_cluster_disk_free_bytes           # 可用存储
minio_cluster_nodes_online_total        # 在线节点数
minio_cluster_drive_online_total        # 在线磁盘数
minio_cluster_drive_offline_total       # 离线磁盘数
minio_s3_requests_total                 # S3请求总数
minio_s3_errors_total                   # S3错误总数
minio_network_received_bytes_total      # 网络接收
minio_network_sent_bytes_total          # 网络发送
```

### 3.3 Grafana Dashboard

```json
{
  "dashboard": {
    "title": "MinIO Dashboard",
    "panels": [
      {
        "title": "Storage Usage",
        "type": "gauge",
        "targets": [
          {
            "expr": "minio_cluster_disk_used_bytes / minio_cluster_disk_total_bytes * 100"
          }
        ]
      },
      {
        "title": "Online Nodes",
        "type": "stat",
        "targets": [
          {
            "expr": "minio_cluster_nodes_online_total"
          }
        ]
      },
      {
        "title": "Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(minio_s3_requests_total[5m])"
          }
        ]
      }
    ]
  }
}
```

---

## 四、备份与恢复

### 4.1 mc镜像备份

```bash
mc alias set source http://source-minio:9000 admin password
mc alias set target http://backup-minio:9000 admin password

mc mirror source/bucket target/backup-bucket

mc mirror --watch source/bucket target/backup-bucket
```

### 4.2 定时备份脚本

```bash
#!/bin/bash
# minio_backup.sh

SOURCE_ALIAS="source"
BACKUP_ALIAS="backup"
BUCKETS=("bucket1" "bucket2" "bucket3")
DATE=$(date +%Y%m%d)

for bucket in "${BUCKETS[@]}"; do
    echo "Backing up $bucket..."
    mc mirror $SOURCE_ALIAS/$bucket $BACKUP_ALIAS/$bucket-$DATE --overwrite
    
    if [ $? -eq 0 ]; then
        echo "Backup completed: $bucket-$DATE"
    else
        echo "Backup failed: $bucket"
        exit 1
    fi
done

echo "All backups completed at $(date)"
```

### 4.3 数据恢复

```bash
mc mirror backup/bucket-backup-20260406 source/bucket-restored
```

---

## 五、扩容操作

### 5.1 水平扩容（增加节点）

```bash
docker-compose down

docker-compose up -d --scale minio=6

mc admin rebalance start myminio
mc admin rebalance status myminio
```

### 5.2 垂直扩容（增加磁盘）

```yaml
services:
  minio1:
    volumes:
      - data1-1:/data1
      - data1-2:/data2
      - data1-3:/data3
      - data1-4:/data4
    command: server http://minio{1...4}/data{1...4} --console-address ":9001"
```

---

## 六、安全配置

### 6.1 TLS/SSL配置

```bash
openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
  -keyout private.key \
  -out public.crt

mkdir -p /root/.minio/certs
cp private.key public.crt /root/.minio/certs/

docker run -d \
  -p 9000:9000 \
  -v /data:/data \
  -v /root/.minio/certs:/root/.minio/certs \
  -e "MINIO_ROOT_USER=admin" \
  -e "MINIO_ROOT_PASSWORD=admin123" \
  minio/minio server /data
```

### 6.2 IAM策略配置

```bash
mc admin policy create myminio readwrite-policy readwrite-policy.json

mc admin user add myminio newuser newpassword

mc admin policy attach myminio readwrite-policy --user newuser
```

### 6.3 策略文件示例

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::my-bucket",
        "arn:aws:s3:::my-bucket/*"
      ]
    }
  ]
}
```

---

## 七、性能优化

### 7.1 内核参数优化

```bash
# /etc/sysctl.conf
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15
vm.swappiness = 10
vm.dirty_ratio = 40
vm.dirty_background_ratio = 10

sysctl -p
```

### 7.2 磁盘优化

```bash
# 使用XFS文件系统
mkfs.xfs -f /dev/sdb

# 挂载选项
mount -o noatime,nodiratime,logbufs=8,logbsize=256k /dev/sdb /data

# /etc/fstab
/dev/sdb /data xfs noatime,nodiratime,logbufs=8,logbsize=256k 0 0
```

### 7.3 MinIO启动参数

```bash
minio server /data \
  --console-address ":9001" \
  --address ":9000" \
  --parallel 8 \
  --offline
```

---

## 八、故障排查

### 8.1 常见问题

```bash
mc admin info myminio

mc admin heal myminio

mc admin trace myminio -v

mc admin console myminio
```

### 8.2 节点恢复

```bash
mc admin service restart myminio

mc admin decommission start myminio myminio/node4

mc admin decommission status myminio myminio/node4
```

### 8.3 数据修复

```bash
mc admin heal myminio --recursive

mc admin heal myminio --dry-run

mc admin heal myminio bucket-name --force
```

---

## 九、运维脚本

### 9.1 健康检查脚本

```bash
#!/bin/bash
# health_check.sh

ALIAS="myminio"
WEBHOOK="https://hooks.slack.com/services/xxx"

check_health() {
    INFO=$(mc admin info $ALIAS --json 2>/dev/null)
    
    ONLINE=$(echo $INFO | jq '.servers | map(select(.state == "online")) | length')
    TOTAL=$(echo $INFO | jq '.servers | length')
    USED=$(echo $INFO | jq '.storage.used')
    TOTAL_STORAGE=$(echo $INFO | jq '.storage.total')
    
    USAGE=$(echo "scale=2; $USED / $TOTAL_STORAGE * 100" | bc)
    
    if [ "$ONLINE" != "$TOTAL" ]; then
        curl -X POST $WEBHOOK -d "{\"text\": \"⚠️ MinIO节点异常: $ONLINE/$TOTAL 在线\"}"
    fi
    
    if [ $(echo "$USAGE > 80" | bc) -eq 1 ]; then
        curl -X POST $WEBHOOK -d "{\"text\": \"⚠️ MinIO存储使用率: ${USAGE}%\"}"
    fi
}

check_health
```

### 9.2 自动清理脚本

```bash
#!/bin/bash
# cleanup.sh

BUCKET="temp-files"
DAYS=30

mc find myminio/$BUCKET --older-than ${DAYS}d --exec "mc rm {}"

echo "Cleaned up files older than $DAYS days"
```

---

*文档完成*
