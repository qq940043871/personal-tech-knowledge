# Kubernetes编排

> 模块：虚拟化与容器技术
> 更新时间：2026-03-28

---

## 一、理论基础

### 1. K8s架构

```
┌─────────────────────────────────────────────────────────────┐
│                      Kubernetes Cluster                        │
│                                                              │
│  ┌─────────────────┐              ┌─────────────────────┐  │
│  │    Master Node    │              │    Worker Node 1    │  │
│  │  ┌─────────────┐ │              │  ┌─────────────┐   │  │
│  │  │ API Server  │ │              │  │    kubelet   │   │  │
│  │  └─────────────┘ │              │  └─────────────┘   │  │
│  │  ┌─────────────┐ │              │  ┌─────────────┐   │  │
│  │  │ etcd        │ │              │  │ kube-proxy  │   │  │
│  │  └─────────────┘ │              │  └─────────────┘   │  │
│  │  ┌─────────────┐ │              │  ┌─────────────┐   │  │
│  │  │ Scheduler   │ │              │  │   Pod       │   │  │
│  │  └─────────────┘ │              │  │  └─ nginx  │   │  │
│  │  ┌─────────────┐ │              │  │  └─ redis  │   │  │
│  │  │ControllerMgr│ │              │  └─────────────┘   │  │
│  │  └─────────────┘ │              └─────────────────────┘  │
│  └─────────────────┘                                        │
└─────────────────────────────────────────────────────────────┘

核心组件：
  API Server：REST API入口，所有操作通过它
  etcd：分布式键值存储，保存集群状态
  Scheduler：调度Pod到合适节点
  Controller Manager：运行各种控制器
  kubelet：节点代理，管理Pod生命周期
  kube-proxy：网络代理，维护网络规则
```

### 2. 核心概念

```
Pod：
  - K8s最小调度单元
  - 一个或多个容器（共享网络、存储）
  - 拥有独立IP地址和存储卷
  - 生命周期短，可重启

Deployment：
  - 管理Pod副本数
  - 支持滚动更新、回滚
  - 声明式更新

Service：
  - 抽象Pod访问方式
  - 负载均衡
  - 类型：ClusterIP/NodePort/LoadBalancer

ConfigMap/Secret：
  - 配置和敏感信息管理
  - 以环境变量或挂载文件形式注入

StatefulSet：
  - 有状态应用管理
  - 稳定的网络标识
  - 稳定的存储

DaemonSet：
  - 每个节点运行一个Pod
  - 日志采集、监控代理
```

---

## 二、实践应用

### 1. 常用命令

```bash
# Pod操作
kubectl get pods                    # 列出Pod
kubectl get pods -o wide           # 详细
kubectl describe pod <name>        # 详情
kubectl logs <pod>                 # 日志
kubectl exec -it <pod> -- /bin/sh  # 进入容器
kubectl apply -f pod.yaml          # 创建
kubectl delete pod <name>          # 删除

# Deployment操作
kubectl get deployments
kubectl scale deployment <name> --replicas=3
kubectl rollout status deployment/<name>
kubectl rollout undo deployment/<name>

# Service操作
kubectl get services
kubectl expose deployment <name> --port=80 --target-port=8080
kubectl port-forward svc/<name> 8080:80

# 调试
kubectl top nodes                  # 资源使用
kubectl top pods
kubectl get events                  # 查看事件
kubectl explain pod.spec           # 查看字段说明
```

### 2. YAML配置

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "128Mi"
            cpu: "250m"
          limits:
            memory: "256Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 5
        readinessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 3
---
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  selector:
    app: web
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 80
```

---

## 三、生产环境问题案例

### 案例1：Pod不断重启

**问题现象：**
Pod处于CrashLoopBackOff状态，不断重启。

**分析过程：**
```bash
# 1. 查看Pod状态
kubectl get pods
# NAME        READY   STATUS              RESTARTS   AGE
# web-app-xxx   0/1   CrashLoopBackOff   5          10m

# 2. 查看日志
kubectl logs web-app-xxx --previous
# 发现：连接数据库失败

# 3. 查看详情
kubectl describe pod web-app-xxx
# Events显示：OOMKilled / Error / 退出码

# 4. 检查资源配置
# memory limit是否太小
```

**解决方案：**
1. 修复应用问题（数据库连接、配置错误）
2. 调整资源限制
3. 添加健康检查

```yaml
resources:
  limits:
    memory: "512Mi"
  requests:
    memory: "256Mi"
```

**经验教训：**
- CrashLoopBackOff要查看--previous日志
- 添加liveness/readiness探针
- 合理设置资源限制

---

### 案例2：Service无法访问

**问题现象：**
集群内部无法通过Service访问应用。

**分析过程：**
```bash
# 1. 检查Endpoints
kubectl get endpoints <service-name>
# 如果为空，说明selector没有匹配到Pod

# 2. 检查Pod标签
kubectl get pods --show-labels

# 3. 检查Service配置
kubectl describe service <service-name>
```

**根因分析：**
Deployment的Pod标签与Service的selector不匹配。

**解决方案：**
```yaml
# 确保标签匹配
# Deployment
spec:
  template:
    metadata:
      labels:
        app: web  # 这个标签

# Service
spec:
  selector:
    app: web    # 必须与Pod标签一致
```

---

*下一步：MySQL数据库 - 架构与存储引擎*
