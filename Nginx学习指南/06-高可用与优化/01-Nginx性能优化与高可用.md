# Nginx性能优化与高可用

> 模块：高可用与优化
> 更新时间：2026-03-29

---

## 一、性能优化配置

### 1. Worker进程优化

```nginx
# 工作进程数（auto自动检测CPU核心数）
worker_processes auto;

# 工作进程优先级
worker_priority -10;

# 绑定CPU核心
worker_cpu_affinity auto;

# 同时接受多个新连接
multi_accept on;

# 事件处理模型
events {
    use epoll;           # Linux推荐epoll
    worker_connections 10240;  # 单worker最大连接数
}
```

### 2. 文件传输优化

```nginx
http {
    # 开启高效文件传输
    sendfile on;
    
    # 减少网络报文段数量
    tcp_nopush on;       # 在sendfile开启时有效
    tcp_nodelay on;      # 禁用Nagle算法
    
    # 缓冲区大小
    client_body_buffer_size 16k;
    client_header_buffer_size 1k;
    large_client_header_buffers 4 8k;
    
    # 零拷贝（需要支持）
    sendfile_max_chunk 512k;
}
```

### 3. Gzip压缩

```nginx
http {
    gzip on;
    gzip_vary on;                    # 添加Vary头
    gzip_proxied any;                 # 代理的响应也压缩
    gzip_comp_level 6;                # 压缩级别(1-9)
    gzip_min_length 1024;            # 最小压缩大小
    gzip_buffers 16 8k;
    gzip_types                      # 压缩类型
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml
        application/xml+rss
        image/svg+xml;
    gzip_disable "msie6";           # 禁用IE6压缩
}
```

### 4. 连接复用

```nginx
http {
    # 客户端长连接
    keepalive_timeout 65;
    keepalive_requests 100;         # 单连接最大请求数
    
    # upstream长连接（重要！）
    upstream backend {
        server 127.0.0.1:8080;
        
        # 开启与后端的长连接
        keepalive 32;              # 空闲长连接数
        keepalive_requests 1000;  # 单连接最大请求
        keepalive_timeout 60s;     # 空闲超时
    }
    
    server {
        location / {
            proxy_pass http://backend;
            proxy_http_version 1.1;      # 启用HTTP/1.1
            proxy_set_header Connection "";  # 清空连接头（自动长连接）
        }
    }
}
```

---

## 二、Nginx+Keepalived高可用

### 架构图

```
                    ┌─────────────┐
                    │   Client    │
                    └──────┬──────┘
                           │
              ┌─────────────┴─────────────┐
              │                           │
              ▼                           ▼
     ┌─────────────┐           ┌─────────────┐
     │  Nginx-1    │           │  Nginx-2    │
     │  (Master)   │◀─────────▶│  (Backup)   │
     │ 192.168.1.10│  VRRP     │ 192.168.1.11│
     └──────┬──────┘           └─────────────┘
            │
            └──────────────┬──────────────┘
                             │
              ┌─────────────┴─────────────┐
              │                           │
              ▼                           ▼
     ┌─────────────┐           ┌─────────────┐
     │  Backend-1  │           │  Backend-2  │
     └─────────────┘           └─────────────┘
```

### Keepalived配置（Master节点）

```bash
# 安装keepalived
yum install -y keepalived

# Master配置
cat > /etc/keepalived/keepalived.conf << EOF
! Configuration File for keepalived

global_defs {
    router_id nginx_master
    script_user root
}

# 健康检查脚本
vrrp_script check_nginx {
    script "/etc/keepalived/check_nginx.sh"
    interval 2
    weight -20
}

vrrp_instance VI_1 {
    state MASTER
    interface eth0              # 网卡名称
    virtual_router_id 51
    priority 100                 # 主服务器优先级
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    
    # 虚拟IP
    virtual_ipaddress {
        192.168.1.100/24 dev eth0
    }
    
    # 健康检查
    track_script {
        check_nginx
    }
    
    # 切换通知
    notify_master "/etc/keepalived/nginx.sh master"
    notify_backup "/etc/keepalived/nginx.sh backup"
    notify_fault "/etc/keepalived/nginx.sh fault"
}
EOF
```

### Keepalived配置（Backup节点）

```bash
# Backup配置（与Master区别：state和priority）
cat > /etc/keepalived/keepalived.conf << EOF
! Configuration File for keepalived

global_defs {
    router_id nginx_backup
}

vrrp_script check_nginx {
    script "/etc/keepalived/check_nginx.sh"
    interval 2
    weight -20
}

vrrp_instance VI_1 {
    state BACKUP
    interface eth0
    virtual_router_id 51
    priority 90               # Backup优先级低
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    
    virtual_ipaddress {
        192.168.1.100/24 dev eth0
    }
    
    track_script {
        check_nginx
    }
}
EOF
```

### 健康检查脚本

```bash
#!/bin/bash
# /etc/keepalived/check_nginx.sh

# 检查nginx进程是否存在
nginx_process=$(ps -ef | grep nginx | grep -v grep | wc -l)

if [ $nginx_process -eq 0 ]; then
    # nginx进程不存在，尝试启动
    systemctl start nginx
    sleep 2
    nginx_process=$(ps -ef | grep nginx | grep -v grep | wc -l)
    if [ $nginx_process -eq 0 ]; then
        exit 1  # 启动失败，标记为失败
    fi
fi

# 检查nginx端口是否监听
nginx_port=$(netstat -tlnp | grep nginx | grep 80 | wc -l)
if [ $nginx_port -eq 0 ]; then
    exit 1
fi

exit 0
```

### 启动服务

```bash
# 启动keepalived
systemctl enable keepalived
systemctl start keepalived
systemctl status keepalived

# 查看VIP绑定
ip addr show eth0

# 测试VIP访问
curl -I http://192.168.1.100

# 模拟故障切换
# 在Master上停止keepalived
systemctl stop keepalived

# 观察VIP是否飘移到Backup
ip addr show eth0
```

---

## 三、日志配置

```nginx
http {
    # 日志格式定义
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for" '
                    'upstream: $upstream_addr '
                    'request_time: $request_time';
    
    # 访问日志
    access_log /var/log/nginx/access.log main;
    
    # 错误日志（级别：debug|info|notice|warn|error|crit）
    error_log /var/log/nginx/error.log warn;
    
    # 条件日志（不记录静态资源的访问）
    map $request_filename $loggable {
        ~*\.(js|css|png|jpg|jpeg|gif|ico)$ 0;
        default 1;
    }
    
    server {
        access_log /var/log/nginx/example.com.access.log main if=$loggable;
    }
}
```

---

*文档完成！*
