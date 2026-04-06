# Docker Compose 单机部署

## 1. docker-compose.yml

```yaml
version: '3.8'

services:
  # === 消息中间件核心节点 ===
  broker-01:
    image: message-broker:v1.0
    container_name: broker-01
    hostname: broker-01
    restart: unless-stopped
    ports:
      - "5672:5672"     # AMQP
      - "15672:15672"   # Management API
      - "9090:9090"     # Prometheus metrics
    environment:
      # 节点配置
      NODE_NAME: broker-01
      CLUSTER_ENABLED: "true"
      CLUSTER_SEED_NODES: "broker-01:5672,broker-02:5672,broker-03:5672"
      
      # 数据库
      DB_HOST: postgres
      DB_PORT: 5432
      DB_NAME: message_broker
      DB_USER: ${DB_USER:-postgres}
      DB_PASSWORD: ${DB_PASSWORD:-postgres123}
      
      # 存储
      DATA_DIR: /data/broker
      MAX_DISK_SIZE_GB: 100
      
      # 安全
      ADMIN_USERNAME: admin
      ADMIN_PASSWORD: ${ADMIN_PASSWORD:-admin123}
      TLS_ENABLED: "false"
      
      # JVM（Java技术栈）
      JVM_HEAP_SIZE: 4g
      JVM_MAX_HEAP_SIZE: 4g
      
      # 日志
      LOG_LEVEL: info
    volumes:
      - broker01-data:/data/broker
      - broker01-logs:/var/log/broker
    networks:
      - broker-net
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:15672/api/v1/cluster/health"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 60s

  # === PostgreSQL 元数据库 ===
  postgres:
    image: postgres:16-alpine
    container_name: broker-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: message_broker
      POSTGRES_USER: ${DB_USER:-postgres}
      POSTGRES_PASSWORD: ${DB_PASSWORD:-postgres123}
    ports:
      - "5432:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./sql/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    command:
      - "postgres"
      - "-c"
      - "max_connections=500"
      - "-c"
      - "shared_buffers=512MB"
      - "-c"
      - "effective_cache_size=2GB"
      - "-c"
      - "maintenance_work_mem=128MB"
      - "-c"
      - "wal_buffers=16MB"
      - "-c"
      - "checkpoint_completion_target=0.9"
      - "-c"
      - "max_wal_size=2GB"
      - "-c"
      - "min_wal_size=1GB"
    networks:
      - broker-net
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d message_broker"]
      interval: 10s
      timeout: 5s
      retries: 5

  # === Redis（可选，Offset缓存）===
  redis:
    image: redis:7-alpine
    container_name: broker-redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    command:
      - redis-server
      - "--maxmemory 512mb"
      - "--maxmemory-policy allkeys-lru"
      - "--appendonly yes"
      - "--appendfsync everysec"
    volumes:
      - redis-data:/data
    networks:
      - broker-net
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  # === Prometheus 监控 ===
  prometheus:
    image: prom/prometheus:v2.48.0
    container_name: broker-prometheus
    restart: unless-stopped
    ports:
      - "9091:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus-data:/prometheus
    command:
      - "--config.file=/etc/prometheus/prometheus.yml"
      - "--storage.tsdb.path=/prometheus"
      - "--storage.tsdb.retention.time=15d"
      - "--web.enable-lifecycle"
    networks:
      - broker-net

  # === Grafana 可视化 ===
  grafana:
    image: grafana/grafana:10.2.2
    container_name: broker-grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      GF_SECURITY_ADMIN_USER: admin
      GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_PASSWORD:-grafana123}
      GF_USERS_ALLOW_SIGN_UP: "false"
    volumes:
      - grafana-data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
    networks:
      - broker-net
    depends_on:
      - prometheus

volumes:
  broker01-data:
  broker01-logs:
  postgres-data:
  redis-data:
  prometheus-data:
  grafana-data:

networks:
  broker-net:
    driver: bridge
```

## 2. prometheus.yml

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: []

scrape_configs:
  - job_name: 'message-broker'
    static_configs:
      - targets: ['broker-01:9090']
    metrics_path: '/metrics'
    scrape_interval: 10s

  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres:5432']
```

## 3. 一键启动脚本

```bash
#!/bin/bash
# deploy.sh - 部署消息中间件单机环境

set -e

echo "=== 消息中间件部署脚本 ==="

# 读取环境变量
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# 创建网络
docker network create broker-net 2>/dev/null || true

# 初始化数据库
echo "[1/4] 初始化数据库..."
docker compose up -d postgres
sleep 5

# 执行建表SQL
docker exec -i broker-postgres psql \
    -U postgres -d message_broker \
    < 99-实施指南/01-数据库建表SQL完整脚本.sql

# 启动所有服务
echo "[2/4] 启动 Broker..."
docker compose up -d broker-01

echo "[3/4] 启动中间件..."
docker compose up -d redis prometheus grafana

# 等待就绪
echo "[4/4] 等待服务就绪..."
sleep 10

# 健康检查
echo ""
echo "=== 部署完成 ==="
echo "Broker AMQP:     localhost:5672"
echo "Management API:  http://localhost:15672"
echo "Prometheus:      http://localhost:9091"
echo "Grafana:         http://localhost:3000 (admin/grafana123)"
echo ""
echo "默认账号: admin / admin123"
```

---

## Kubernetes 集群部署

## 4. namespace.yaml

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: message-broker
  labels:
    app.kubernetes.io/name: message-broker
    app.kubernetes.io/version: v1.0
```

## 5. configmap.yaml

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: broker-config
  namespace: message-broker
data:
  config.yaml: |
    server:
      host: "0.0.0.0"
      port: 5672
      management_port: 15672
    
    cluster:
      enabled: true
      consensus_algorithm: "raft"
      election_timeout_ms: 5000
      heartbeat_interval_ms: 1000
      default_replicas: 3
      discovery:
        type: "k8s"
        service_name: "broker-headless"
    
    storage:
      engine: "rocksdb"
      data_dir: "/data/broker"
      max_segment_size_mb: 512
    
    security:
      tls:
        enabled: false
      auth:
        enabled: true
        type: "builtin"
    
    monitoring:
      metrics:
        enabled: true
        port: 9090
```

## 6. statefulset.yaml（Broker 集群）

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: broker
  namespace: message-broker
  labels:
    app: broker
spec:
  serviceName: broker-headless
  replicas: 3
  podManagementPolicy: Parallel
  updateStrategy:
    type: RollingUpdate
  selector:
    matchLabels:
      app: broker
  template:
    metadata:
      labels:
        app: broker
    spec:
      terminationGracePeriodSeconds: 60
      
      initContainers:
        - name: init-chmod
          image: busybox:1.36
          command:
            - sh
            - -c
            - |
              mkdir -p /data/broker /var/log/broker
              chmod 755 /data/broker
          volumeMounts:
            - name: data
              mountPath: /data/broker
      
      containers:
        - name: broker
          image: message-broker:v1.0
          imagePullPolicy: IfNotPresent
          
          ports:
            - name: amqp
              containerPort: 5672
              protocol: TCP
            - name: mgmt
              containerPort: 15672
              protocol: TCP
            - name: metrics
              containerPort: 9090
              protocol: TCP
          
          env:
            - name: NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
            - name: CLUSTER_ENABLED
              value: "true"
            - name: DB_HOST
              value: postgres.message-broker.svc.cluster.local
            - name: DB_PORT
              value: "5432"
            - name: DB_NAME
              value: message_broker
            - name: DB_USER
              valueFrom:
                secretKeyRef:
                  name: broker-secrets
                  key: db-user
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: broker-secrets
                  key: db-password
            - name: ADMIN_USERNAME
              value: admin
            - name: ADMIN_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: broker-secrets
                  key: admin-password
          
          resources:
            requests:
              cpu: 500m
              memory: 2Gi
            limits:
              cpu: 2000m
              memory: 4Gi
          
          livenessProbe:
            httpGet:
              path: /api/v1/cluster/health
              port: mgmt
            initialDelaySeconds: 60
            periodSeconds: 30
            timeoutSeconds: 10
            failureThreshold: 3
          
          readinessProbe:
            httpGet:
              path: /api/v1/cluster/health
              port: mgmt
            initialDelaySeconds: 30
            periodSeconds: 10
            timeoutSeconds: 5
          
          volumeMounts:
            - name: config
              mountPath: /etc/broker/config.yaml
              subPath: config.yaml
            - name: data
              mountPath: /data/broker
            - name: logs
              mountPath: /var/log/broker
      
      volumes:
        - name: config
          configMap:
            name: broker-config
        - name: logs
          emptyDir: {}

  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: fast-ssd
        resources:
          requests:
            storage: 50Gi
```

## 7. service.yaml

```yaml
# Headless Service（集群内部通信）
apiVersion: v1
kind: Service
metadata:
  name: broker-headless
  namespace: message-broker
spec:
  clusterIP: None
  selector:
    app: broker
  ports:
    - name: amqp
      port: 5672
      targetPort: 5672
    - name: mgmt
      port: 15672
      targetPort: 15672

---
# ClusterIP Service（对外暴露管理接口）
apiVersion: v1
kind: Service
metadata:
  name: broker
  namespace: message-broker
spec:
  type: ClusterIP
  selector:
    app: broker
  ports:
    - name: amqp
      port: 5672
      targetPort: 5672
    - name: mgmt
      port: 15672
      targetPort: 15672
    - name: metrics
      port: 9090
      targetPort: 9090

---
# LoadBalancer Service（公网访问）
apiVersion: v1
kind: Service
metadata:
  name: broker-lb
  namespace: message-broker
spec:
  type: LoadBalancer
  selector:
    app: broker
  ports:
    - name: amqp
      port: 5672
      targetPort: 5672
    - name: mgmt
      port: 15672
      targetPort: 15672
```

## 8. secret.yaml

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: broker-secrets
  namespace: message-broker
type: Opaque
stringData:
  db-user: postgres
  db-password: postgres123
  admin-password: admin123
```

## 9. hpa.yaml（自动扩缩容）

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: broker-hpa
  namespace: message-broker
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: StatefulSet
    name: broker
  minReplicas: 3
  maxReplicas: 9
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Percent
          value: 10
          periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
        - type: Percent
          value: 100
          periodSeconds: 15
```

---

*文档版本：v1.0 | 更新日期：2026-03-29*
