# Docker容器化

> 模块：虚拟化与容器技术
> 更新时间：2026-03-28

---

## 一、理论基础

### 1. Docker架构

```
┌─────────────────────────────────────────────────┐
│                    Docker Client                  │
│              (docker CLI / SDK)                  │
└─────────────────────┬───────────────────────────┘
                      │ REST API
                      ▼
┌─────────────────────────────────────────────────┐
│                    Docker Daemon                  │
│  ┌─────────┐  ┌─────────┐  ┌───────────────┐   │
│  │ Container│  │  Image  │  │   Network    │   │
│  │ Manager │  │ Manager │  │   Manager    │   │
│  └────┬────┘  └────┬────┘  └───────┬───────┘   │
│       └────────────┴───────────────┘            │
│                    │                            │
│            ┌──────▼──────┐                     │
│            │ containerd   │  ← 容器运行时       │
│            │   (runc)     │                     │
│            └─────────────┘                      │
└─────────────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────┐
│               Linux Kernel                       │
│  ┌──────────┐  ┌──────────┐  ┌─────────────┐  │
│  │namespace │  │ cgroup   │  │ unionfs     │  │
│  │ 隔离      │  │ 资源限制  │  │ 层叠文件系统 │  │
│  └──────────┘  └──────────┘  └─────────────┘  │
└─────────────────────────────────────────────────┘
```

### 2. 容器核心技术

#### Linux Namespace（命名空间）

```
6种Namespace：

PID Namespace（进程隔离）
  - 每个容器有独立的进程树
  - 容器的PID从1开始
  - 容器外看不到容器内进程

Network Namespace（网络隔离）
  - 独立的网络协议栈
  - 独立的IP、端口、路由表
  - 通过veth pair连接宿主机

Mount Namespace（挂载隔离）
  - 独立的文件系统视图
  - 容器内根文件系统独立

User Namespace（用户隔离）
  - 独立的UID/GID映射
  - 容器内root映射为宿主机普通用户

UTS Namespace（主机名隔离）
  - 独立的hostname和domainname

IPC Namespace（进程间通信隔离）
  - 独立的信号量、共享内存、消息队列
```

#### Cgroup（控制组）

```
作用：限制和隔离进程组的资源

子系统：
  cpu：CPU时间分配
  cpuacct：CPU统计
  memory：内存限制
  blkio：块设备IO限制
  devices：设备访问控制
  freezer：暂停/恢复进程

示例：
  # 限制内存为512MB
  docker run -m 512m nginx
  
  # 限制CPU为0.5核
  docker run --cpus 0.5 nginx
  
  # 限制IO
  docker run --device-write-iops bdev:rw=100 nginx
```

#### UnionFS（联合文件系统）

```
原理：多个只读层叠成一个视图

Docker镜像层：
  ┌─────────────────┐
  │ Container Layer │  可写层（容器特有）
  ├─────────────────┤
  │     Layer 4     │  只读层（镜像层）
  ├─────────────────┤
  │     Layer 3     │
  ├─────────────────┤
  │     Layer 2     │
  ├─────────────────┤
  │     Layer 1     │
  ├─────────────────┤
  │    Base Image   │
  └─────────────────┘

存储驱动：
  - overlay2：推荐，性能好
  - devicemapper：老版默认
  - btrfs/zfs：文件系统级支持
  - vfs：简单但性能差
```

### 3. Docker网络

```
网络模式：

bridge（桥接模式，默认）
  docker0 ── veth ── eth0（容器内）
  容器通过NAT访问外部
  容器间通过docker0通信

host（主机模式）
  容器共享宿主机网络
  性能最好，但端口冲突

container（容器模式）
  与另一个容器共享网络栈
  localhost指向同一网络命名空间

none（无网络）
  完全隔离，无网络接口

自定义网络（推荐）
  docker network create mynet
  容器间通过名字互相访问
```

---

## 二、实践应用

### 1. 镜像优化

```dockerfile
# 多阶段构建
# 构建阶段
FROM maven:3.8 AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn package -DskipTests

# 运行阶段
FROM openjdk:11-jre-slim
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar

# 优化：
# 1. 使用轻量级基础镜像
FROM alpine:3.18
# 或
FROM gcr.io/distroless/java11

# 2. 减少层数
RUN apt-get update && \
    apt-get install -y package && \
    rm -rf /var/lib/apt/lists/*

# 3. .dockerignore排除
# .dockerignore
# node_modules
# .git
# *.log

# 4. 合并RUN指令减少层
```

### 2. 资源限制

```yaml
# docker-compose.yml
services:
  app:
    image: myapp:latest
    deploy:
      resources:
        limits:
          cpus: '0.5'          # 最大0.5核
          memory: 512M         # 最大512MB
          pids: 100            # 最大进程数
        reservations:
          cpus: '0.25'
          memory: 256M
```

```bash
# 命令行参数
docker run \
  --memory=512m \
  --memory-swap=1g \
  --cpus=0.5 \
  --cpuset-cpus="0,1" \
  --pids-limit=100 \
  --blkio-weight=300 \
  --ulimit nofile=1024:2048 \
  nginx
```

### 3. 网络配置

```bash
# 创建自定义网络
docker network create --driver bridge \
  --subnet=172.20.0.0/16 \
  --gateway=172.20.0.1 \
  mynet

# 运行容器加入网络
docker run --network=mynet --name=app nginx

# 容器间通过名字访问
# 同一网络中，容器名即DNS名
docker run --network=mynet --name=db postgres
# app容器中可以通过 db 访问 postgres

# 查看网络
docker network ls
docker network inspect mynet
```

---

## 三、生产环境问题案例

### 案例1：容器内时间不同步

**问题现象：**
容器内时间和宿主机不一致。

**分析过程：**
```bash
# 查看宿主机时间
date
# Sat Mar 28 21:00:00 CST 2026

# 查看容器时间
docker exec <container> date
# Sat Mar 28 13:00:00 UTC 2026

# 时区不同步
# 容器使用UTC，宿主机使用CST
```

**解决方案：**
```dockerfile
# 方案1：挂载时区文件
docker run -v /etc/localtime:/etc/localtime:ro \
         -v /etc/timezone:/etc/timezone:ro \
         nginx

# 方案2：在Dockerfile中设置
FROM nginx
RUN apt-get update && apt-get install -y tzdata && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo 'Asia/Shanghai' > /etc/timezone

# 方案3：使用环境变量（Java应用）
-e TZ=Asia/Shanghai
```

---

### 案例2：容器无法解析DNS

**问题现象：**
容器内ping不通域名，但能ping通IP。

**分析过程：**
```bash
# 检查DNS配置
docker exec <container> cat /etc/resolv.conf
# nameserver 8.8.8.8

# 测试DNS
docker exec <container> nslookup google.com
# 失败：Server failed

# 检查网络
docker network inspect bridge
# 发现：DNS服务器配置正确
```

**根因分析：**
DNS服务器无法访问，或DNS配置缺失。

**解决方案：**
```bash
# 方案1：指定DNS
docker run --dns=8.8.8.8 --dns=114.114.114.114 nginx

# 方案2：指定自定义DNS
docker network create --dns=8.8.8.8 mynet

# 方案3：检查宿主机iptables
iptables -t nat -L -n | grep DNS
# 可能有规则拦截
```

---

### 案例3：存储空间不足

**问题现象：**
无法创建容器，磁盘空间不足。

**分析过程：**
```bash
# 查看Docker磁盘使用
docker system df

# 详细分析
docker system df -v

# 查看占用最大的镜像/容器
```

**解决方案：**
```bash
# 清理未使用的资源
docker system prune -a    # 清理所有未使用镜像
docker system prune --volumes  # 包括volumes
docker container prune     # 未使用的容器
docker image prune         # 未使用的镜像
docker volume prune        # 未使用的volumes

# 清理旧版本镜像
docker image prune -a --filter "until=24h"

# 修改Docker存储位置
# /etc/docker/daemon.json
{
  "data-root": "/mnt/docker"
}
```

**经验教训：**
- 定期清理未使用资源
- 监控磁盘使用率
- 配置日志轮转

---

## 四、安全最佳实践

```dockerfile
# 1. 非root用户
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# 2. 最小权限
# 只开放必要端口
EXPOSE 80 443

# 3. 依赖安全
# 使用官方镜像
# 定期更新基础镜像
RUN apt-get update && apt-get upgrade

# 4. 敏感信息
# 使用Docker secrets（Swarm模式）
# 或Kubernetes secrets
# 绝对不要在镜像中存储密码

# 5. 健康检查
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD curl -f http://localhost/ || exit 1
```

---

## 五、延伸阅读

### 书籍
- 《Docker技术入门与实战》
- 《自己动手写Docker》

### 工具
- Portainer：Web UI管理
- Dive：镜像层分析
- Hadolint：Dockerfile检查

---

*下一步：Kubernetes编排*
