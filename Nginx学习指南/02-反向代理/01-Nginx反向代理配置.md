# Nginx反向代理配置

> 模块：反向代理
> 更新时间：2026-03-29

---

## 一、反向代理基础

### 核心概念

```
┌──────────┐         ┌───────────┐         ┌────────────┐
│  Client  │────────▶│   Nginx   │────────▶│   Backend  │
│          │◀────────│  (Proxy)  │◀────────│   Server   │
└──────────┘         └───────────┘         └────────────┘
     IP:A                IP:B                 IP:C
     
客户端只看到Nginx的IP，真实后端IP被隐藏
```

### 基础配置

```nginx
server {
    listen 80;
    server_name example.com;
    
    location / {
        # proxy_pass指定后端服务器
        proxy_pass http://127.0.0.1:8080;
        
        # 基础代理配置
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

---

## 二、proxy_pass详解

### 基本用法

```nginx
# 1. 最简形式
location / {
    proxy_pass http://127.0.0.1:8080;
}

# 2. 带上URI（会替换location匹配的URI部分）
location /api/ {
    proxy_pass http://127.0.0.1:8080/;  # 去掉/api/
}
# /api/users → http://127.0.0.1:8080/users

# 3. 不带URI（保留原始URI）
location /api/ {
    proxy_pass http://127.0.0.1:8080;
}
# /api/users → http://127.0.0.1:8080/api/users

# 4. 代理到Unix Socket
location / {
    proxy_pass http://unix:/var/run/app.sock;
}
```

### 路径替换规则

```nginx
# 规则：proxy_pass的URI部分会替换location匹配的URI

# 情况1：proxy_pass不带URI
location /api/ {
    proxy_pass http://backend;  # 保留/api/
}
# /api/users → http://backend/api/users

# 情况2：proxy_pass带URI（以/结尾）
location /api/ {
    proxy_pass http://backend/;  # 替换为/
}
# /api/users → http://backend/users

# 情况3：proxy_pass带URI（以/结尾）且有捕获组
location ~ ^/api/v(\d+)/(.*)$ {
    proxy_pass http://backend/v$1/$2;  # 捕获组替换
}
# /api/v1/users → http://backend/v1/users

# 注意：proxy_pass不带尾部斜杠时的行为
location /api {
    proxy_pass http://backend/;
}
# /apiproxy → http://backend/proxy  (不完全匹配时)
```

---

## 三、代理头设置（重要）

```nginx
location / {
    proxy_pass http://127.0.0.1:8080;
    
    # 必须设置的Header
    # 1. Host：原始请求的Host
    proxy_set_header Host $host;
    
    # 2. X-Real-IP：客户端真实IP
    proxy_set_header X-Real-IP $remote_addr;
    
    # 3. X-Forwarded-For：代理链IP列表
    # 格式：client, proxy1, proxy2
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    
    # 4. X-Forwarded-Proto：原始协议
    proxy_set_header X-Forwarded-Proto $scheme;
    
    # 5. X-Forwarded-Host：原始Host
    proxy_set_header X-Forwarded-Host $host;
    
    # 6. X-Forwarded-Port：原始端口
    proxy_set_header X-Forwarded-Port $server_port;
    
    # 7. Connection：关闭连接
    proxy_set_header Connection "";
    
    # 8. 用户IP（非必须）
    proxy_set_header X-Real-IP $remote_addr;
}
```

### 后端获取真实IP

```java
// Java/Spring获取真实IP
public String getRealIp(HttpServletRequest request) {
    String ip = request.getHeader("X-Forwarded-For");
    if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
        ip = request.getHeader("X-Real-IP");
    }
    if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
        ip = request.getRemoteAddr();
    }
    // 多个代理时，取第一个IP
    if (ip != null && ip.contains(",")) {
        ip = ip.split(",")[0].trim();
    }
    return ip;
}
```

---

## 四、超时和缓冲配置

```nginx
location / {
    proxy_pass http://127.0.0.1:8080;
    
    # 连接超时
    proxy_connect_timeout 60s;    # 默认60秒
    
    # 发送请求超时
    proxy_send_timeout 60s;
    
    # 读取响应超时
    proxy_read_timeout 60s;
    
    # 缓冲配置
    proxy_buffering on;             # 开启缓冲
    proxy_buffer_size 4k;           # 响应头缓冲大小
    proxy_buffers 8 4k;            # 响应体缓冲（数量 大小）
    proxy_busy_buffers_size 8k;    # 忙碌时缓冲
    proxy_max_temp_file_size 1024m; # 临时文件最大size
    
    # 关闭缓冲（实时推送场景）
    proxy_buffering off;
    proxy_cache off;
}
```

---

## 五、WebSocket代理

```nginx
server {
    listen 80;
    server_name example.com;
    
    location /ws/ {
        proxy_pass http://127.0.0.1:8080/;
        
        # WebSocket必需配置
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        
        # 超时设置（WebSocket长连接需要较长超时）
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }
}
```

---

## 六、完整反向代理配置模板

```nginx
server {
    listen 80;
    server_name example.com;
    
    access_log /var/log/nginx/example.access.log main;
    error_log /var/log/nginx/example.error.log;
    
    location / {
        # 后端地址
        proxy_pass http://127.0.0.1:8080;
        
        # === Header设置 ===
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header Connection "";
        
        # === 超时设置 ===
        proxy_connect_timeout 30s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # === 缓冲设置 ===
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 16k;
        proxy_busy_buffers_size 32k;
        
        # === 其他 ===
        proxy_redirect off;
    }
}
```

---

*下一步：负载均衡配置*
