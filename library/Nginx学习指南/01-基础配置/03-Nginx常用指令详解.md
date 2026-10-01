# Nginx常用指令详解

> 模块：基础配置
> 更新时间：2026-03-29

---

## 一、listen指令

```nginx
# 基本语法
listen address[:port] [default_server] [ssl] [http2];
listen port [default_server] [ssl] [http2];
listen unix:path [default_server] [ssl] [http2];

# 示例
listen 80;                    # 监听80端口
listen 127.0.0.1:80;        # 监听指定IP
listen *:80;                  # 监听所有IP的80端口
listen unix:/var/run/nginx.sock;  # Unix域套接字

# 完整示例
listen 443 ssl http2;
listen 443 ssl http2 backlog=4096;
listen 443 ssl http2 deferred;  # 延迟接受（优化TCP）

# default_server：默认虚拟主机
listen 80 default_server;

# SSL配置
listen 443 ssl;
listen [::]:443 ssl http2;  # IPv6 + SSL

# 参数说明
# default_server   设为默认服务器
# ssl              启用SSL
# http2            启用HTTP/2
# backlog=n        连接队列大小
# deferred         延迟接受TCP连接
# reuseport        启用SO_REUSEPORT（性能优化）
```

---

## 二、server_name指令

```nginx
# 精确匹配
server_name example.com;

# 多个域名
server_name example.com www.example.com;

# 通配符（只能在首尾）
server_name *.example.com;           # 匹配任何子域名
server_name example.*;               # 匹配example开头

# 正则表达式
server_name ~^www\d+\.example\.com$;
server_name ~^(?<subdomain>.+)\.example\.com$;

# 捕获组使用
server_name ~^(?<user>.+)\.example\.com$;
location / {
    # $subdomain 变量可用
}

# 匹配优先级
# 1. 精确匹配（example.com）
# 2. 以*开头的通配符（*.example.com）
# 3. 以*结尾的通配符（example.*）
# 4. 正则匹配（按配置文件顺序）
```

---

## 三、root和alias

```nginx
# root：完整路径拼接
# 请求 /images/logo.png
# 文件路径 = root + /images/logo.png
server {
    root /var/www/html;
    
    location /images/ {
        # 文件在 /var/www/html/images/...
    }
}

# alias：路径别名，只替换location部分
# 请求 /images/logo.png
# 文件路径 = alias指定路径 + logo.png
server {
    location /images/ {
        alias /var/www/static/images/;
        # 文件在 /var/www/static/images/logo.png
    }
}

# root示例
location /static/ {
    root /var/www/html;
    # /static/css/style.css → /var/www/html/static/css/style.css
}

# alias示例
location /static/ {
    alias /var/www/static/;
    # /static/css/style.css → /var/www/static/css/style.css
}

# 注意：alias必须以/结尾
location /css/ {
    alias /var/www/css/;  # 正确
}
location /css {
    alias /var/www/css;   # 正确
}
location /css {
    alias /var/www/css/;  # 错误！
}
```

---

## 四、return和rewrite

```nginx
# return：直接返回响应
location / {
    return 200 "OK";
    # return 301 http://example.com;   # 重定向
    # return 403 "Forbidden";          # 403响应
}

# 常用状态码
# 200 OK
# 301 永久重定向
# 302 临时重定向
# 403 禁止访问
# 404 未找到
# 500 服务器错误
# 502 网关错误
# 503 服务不可用
# 504 网关超时

# rewrite：重写URL
# 语法：rewrite regex replacement [flag];
# flag: last|break|redirect|permanent

server {
    # 临时重定向（302）
    rewrite ^/old/(.*)$ /new/$1 redirect;
    
    # 永久重定向（301）
    rewrite ^/old/(.*)$ /new/$1 permanent;
    
    # last：重新匹配location
    rewrite ^/blog/(.*)$ /article/$1 last;
    
    # break：停止rewrite，继续处理
    rewrite ^/blog/(.*)$ /article/$1 break;
}

# 常用rewrite示例
# 1. 添加www前缀
if ($host = 'example.com') {
    return 301 http://www.example.com$request_uri;
}

# 2. 强制HTTPS
if ($scheme = 'http') {
    return 301 https://$host$request_uri;
}

# 3. 移除URI末尾斜杠
rewrite ^/(.*)/$ /$1 permanent;
```

---

## 五、try_files

```nginx
# 按顺序检查文件存在性

server {
    root /var/www/html;
    
    # 示例1：文件 → 目录 → 默认文件
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # 示例2：SPA应用
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # 示例3：多目录查找
    location /images/ {
        try_files 
            /images/$uri
            /images/cache/$uri
            =404;
    }
    
    # 示例4：命名location
    location / {
        try_files $uri @backend;
    }
    
    location @backend {
        proxy_pass http://127.0.0.1:8080;
    }
}
```

---

*下一步：location匹配规则*
