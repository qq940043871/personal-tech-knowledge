# Nginx实战配置模板

> 模块：实战配置
> 更新时间：2026-03-29

---

## 一、最完整反向代理+HTTPS模板

```nginx
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /run/nginx.pid;

events {
    worker_connections 10240;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # 日志格式
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for" '
                    'rt=$request_time uct="$upstream_connect_time" '
                    'uht="$upstream_header_time" urt="$upstream_response_time"';
    
    access_log /var/log/nginx/access.log main;
    
    # 基础优化
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    
    # Gzip压缩
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml application/json 
               application/javascript application/xml
               application/xml+rss image/svg+xml;
    
    # upstream后端服务器
    upstream backend_servers {
        least_conn;
        server 127.0.0.1:8080 weight=5 max_fails=3 fail_timeout=10s;
        server 127.0.0.1:8081 weight=3 max_fails=3 fail_timeout=10s;
        keepalive 32;
    }
    
    # HTTP服务器
    server {
        listen 80;
        server_name example.com www.example.com;
        
        # 强制HTTPS
        return 301 https://$host$request_uri;
    }
    
    # HTTPS服务器
    server {
        listen 443 ssl http2;
        server_name example.com www.example.com;
        
        # SSL证书
        ssl_certificate /etc/nginx/ssl/example.com.pem;
        ssl_certificate_key /etc/nginx/ssl/example.com.key;
        ssl_session_timeout 1d;
        ssl_session_cache shared:SSL:50m;
        ssl_session_tickets off;
        
        # SSL协议和加密套件
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
        ssl_prefer_server_ciphers off;
        
        # 安全响应头
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        
        # 主站代理
        location / {
            proxy_pass http://backend_servers;
            
            # 基础Header
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $host;
            
            # 超时设置
            proxy_connect_timeout 30s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
            
            # 缓冲设置
            proxy_buffering on;
            proxy_buffer_size 4k;
            proxy_buffers 8 16k;
            proxy_busy_buffers_size 32k;
        }
        
        # API接口（独立配置）
        location /api/ {
            # 限流
            limit_req zone=api_limit burst=20 nodelay;
            
            proxy_pass http://backend_servers;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
        
        # 静态资源（本地缓存）
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            root /var/www/html/static;
            expires 30d;
            add_header Cache-Control "public, immutable";
            access_log off;
        }
        
        # 健康检查
        location /health {
            return 200 'OK';
            access_log off;
        }
        
        # 禁止访问的文件
        location ~ /\. {
            deny all;
        }
    }
}
```

---

## 二、微服务网关配置

```nginx
http {
    # 动态upstream配置
    upstream user_service {
        server 192.168.1.10:8080;
        server 192.168.1.11:8080;
    }
    
    upstream order_service {
        server 192.168.1.20:8080;
        server 192.168.1.21:8080;
    }
    
    upstream product_service {
        server 192.168.1.30:8080;
        server 192.168.1.31:8080;
    }
    
    server {
        listen 80;
        server_name api.example.com;
        
        # 用户服务 /user/**
        location ^~ /user/ {
            proxy_pass http://user_service/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
        
        # 订单服务 /order/**
        location ^~ /order/ {
            proxy_pass http://order_service/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
        
        # 商品服务 /product/**
        location ^~ /product/ {
            proxy_pass http://product_service/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
}
```

---

## 三、限流配置

```nginx
http {
    # 限流区域定义
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=login_limit:10m rate=1r/s;
    limit_req_zone $server_name zone=server_limit:10m rate=100r/s;
    
    # 连接数限制
    limit_conn_zone $binary_remote_addr zone=addr:10m;
    
    server {
        listen 80;
        server_name example.com;
        
        # 默认限流
        location / {
            limit_req zone=api_limit burst=20 nodelay;
            limit_conn addr 10;
            
            proxy_pass http://backend;
        }
        
        # 登录接口更严格限流
        location /api/login {
            limit_req zone=login_limit burst=5 nodelay;
            
            proxy_pass http://backend;
        }
        
        # 限流提示
        error_page 503 = @ratelimit_fallback;
        
        location @ratelimit_fallback {
            default_type application/json;
            return 503 '{"code":429,"msg":"请求过于频繁，请稍后重试"}';
        }
    }
}
```

---

## 四、完整安全配置

```nginx
http {
    # 请求大小限制
    client_max_body_size 10m;
    client_header_buffer_size 1k;
    large_client_header_buffers 4 8k;
    
    # 超时限制
    client_body_timeout 15s;
    client_header_timeout 15s;
    send_timeout 15s;
    
    server {
        listen 80;
        server_name example.com;
        
        # IP白名单
        geo $white_ip {
            default 1;
            192.168.0.0/16 0;
            10.0.0.0/8 0;
            127.0.0.1 0;
        }
        
        # 黑名单IP返回403
        if ($white_ip = 1) {
            return 403;
        }
        
        # 禁止User-Agent
        if ($http_user_agent ~* "curl|wget|python|java|Go-http-client") {
            return 403;
        }
        
        # 防盗链
        location ~* \.(jpg|png|gif|css|js)$ {
            valid_referers none blocked server_names ~\.google\. ~\.baidu\.;
            if ($invalid_referer) {
                return 403;
            }
        }
        
        # 禁止访问敏感路径
        location ~* \.(env|git|htaccess|ini|log|sql|conf)$ {
            deny all;
        }
        
        # 隐藏Nginx版本号
        server_tokens off;
        
        # 禁止通过IP访问
        if ($host != $server_name) {
            return 444;
        }
    }
}
```

---

## 五、日常运维命令

```bash
# 配置文件语法检查
nginx -t

# 重新加载配置
nginx -s reload

# 日志切割（手动）
mv /var/log/nginx/access.log /var/log/nginx/access.log.old
nginx -s reopen
# 或使用logrotate

# 查看连接状态
curl http://127.0.0.1/nginx_status

# 监控指标
awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head

# 分析慢请求
awk '($NF > 1) {print $NF " " $0}' /var/log/nginx/access.log | sort -rn | head
```

---

*文档完成！*
