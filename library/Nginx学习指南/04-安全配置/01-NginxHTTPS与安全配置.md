# Nginx HTTPS与安全配置

> 模块：安全配置
> 更新时间：2026-03-29

---

## 一、SSL证书配置

### 免费证书申请（Let's Encrypt）

```bash
# 使用certbot申请证书
yum install -y certbot python3-certbot-nginx

# 申请证书
certbot --nginx -d example.com -d www.example.com

# 自动续期
certbot renew --dry-run
```

### SSL基础配置

```nginx
server {
    listen 443 ssl http2;
    server_name example.com;
    
    # SSL证书配置
    ssl_certificate /etc/nginx/ssl/example.com.pem;      # 证书文件
    ssl_certificate_key /etc/nginx/ssl/example.com.key;  # 私钥文件
    
    # SSL协议版本（禁用老旧版本）
    ssl_protocols TLSv1.2 TLSv1.3;
    
    # 加密套件（现代配置）
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers on;
    
    # 其他SSL配置
    ssl_session_cache shared:SSL:10m;     # 会话缓存
    ssl_session_timeout 1d;                # 会话超时
    ssl_session_tickets off;               # 禁用会话票据
    ssl_stapling on;                     # OCSP Stapling
    ssl_stapling_verify on;               # 验证OCSP响应
}
```

### HTTP重定向到HTTPS

```nginx
# HTTP服务器（80端口）
server {
    listen 80;
    server_name example.com;
    
    # 永久重定向到HTTPS
    return 301 https://$host$request_uri;
}

# HTTPS服务器（443端口）
server {
    listen 443 ssl http2;
    server_name example.com;
    
    ssl_certificate /etc/nginx/ssl/example.com.pem;
    ssl_certificate_key /etc/nginx/ssl/example.com.key;
    
    location / {
        proxy_pass http://127.0.0.1:8080;
    }
}
```

---

## 二、安全响应头

```nginx
server {
    listen 443 ssl http2;
    server_name example.com;
    
    # === 安全响应头 ===
    
    # 1. X-Frame-Options：防止点击劫持
    add_header X-Frame-Options "SAMEORIGIN" always;
    
    # 2. X-Content-Type-Options：禁用MIME类型嗅探
    add_header X-Content-Type-Options "nosniff" always;
    
    # 3. X-XSS-Protection：XSS过滤
    add_header X-XSS-Protection "1; mode=block" always;
    
    # 4. Strict-Transport-Security：强制HTTPS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    
    # 5. Content-Security-Policy：内容安全策略
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' https://cdn.example.com; style-src 'self' 'unsafe-inline' https://cdn.example.com; img-src 'self' data: https:; font-src 'self' https://cdn.example.com;" always;
    
    # 6. Referrer-Policy：引用来源策略
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    
    # 7. Permissions-Policy：权限策略
    add_header Permissions-Policy "accelerometer=(), camera=(), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), payment=(), usb=()" always;
    
    # 8. X-Permitted-Cross-Domain-Policies：跨域策略
    add_header X-Permitted-Cross-Domain-Policies "none" always;
}
```

---

## 三、访问限制

### IP黑白名单

```nginx
# 白名单（允许访问）
server {
    listen 80;
    server_name example.com;
    
    # 只允许指定IP访问
    allow 192.168.1.0/24;   # 允许内网
    allow 10.0.0.0/8;
    allow 127.0.0.1;
    deny all;                   # 拒绝其他
    
    location / {
        proxy_pass http://127.0.0.1:8080;
    }
}

# 黑名单（禁止访问）
server {
    listen 80;
    server_name example.com;
    
    # 禁止指定IP访问
    deny 192.168.1.100;
    deny 10.0.0.50;
    
    location / {
        proxy_pass http://127.0.0.1:8080;
    }
}
```

### 请求限流

```nginx
# 定义限流区域
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;

server {
    listen 80;
    server_name example.com;
    
    # 限流应用
    location /api/ {
        # burst=20：突发20个请求
        # nodelay：不延迟处理突发请求
        limit_req zone=api_limit burst=20 nodelay;
        
        proxy_pass http://127.0.0.1:8080;
    }
    
    # 返回限流提示
    error_page 503 /503.html;
}

# 连接数限制
limit_conn_zone $binary_remote_addr zone=addr:10m;

server {
    listen 80;
    
    location / {
        limit_conn addr 10;  # 单IP最大10个连接
        proxy_pass http://127.0.0.1:8080;
    }
}
```

### 请求大小限制

```nginx
server {
    # 限制请求体大小（默认8m）
    client_max_body_size 10m;
    
    # 限制请求头大小
    client_header_buffer_size 1k;
    large_client_header_buffers 4 8k;
    
    # 限制请求超时
    client_body_timeout 15s;
    client_header_timeout 15s;
    
    location /upload {
        # 上传目录可以设置更大
        client_max_body_size 100m;
        proxy_pass http://127.0.0.1:8080;
    }
}
```

---

## 四、防盗链配置

```nginx
server {
    listen 80;
    server_name example.com;
    
    # 图片防盗链
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        # 检查Referer头
        valid_referers none blocked server_names
                     ~\.google\. 
                     ~\.baidu\.;
        
        # 非法来源返回403或指定图片
        if ($invalid_referer) {
            return 403;
            # 或返回防盗链图片
            # rewrite ^/.*$ /images/hotlink.jpg break;
        }
        
        root /var/www/html;
        expires 30d;
    }
}

# 说明：
# none：Referer为空
# blocked：Referer被防火墙删除
# server_names：当前server_name
# 正则：允许的外部域名
```

---

## 五、敏感文件保护

```nginx
server {
    listen 80;
    server_name example.com;
    
    # 禁止访问隐藏文件
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # 禁止访问敏感文件
    location ~* \.(env|git|htaccess|htpasswd|ini|log|sh|sql|conf|bak)$ {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # 禁止访问配置目录
    location ~ /\.(?!well-known) {
        deny all;
    }
}
```

---

*下一步：跨域与缓存配置*
