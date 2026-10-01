# Nginx核心配置结构

> 模块：基础配置
> 更新时间：2026-03-29

---

## 一、nginx.conf结构

```nginx
# 运行用户
user nginx;

# 工作进程数（auto自动检测CPU核心数）
worker_processes auto;

# 错误日志
error_log /var/log/nginx/error.log warn;

# PID文件
pid /run/nginx.pid;

# 事件模块配置
events {
    # 单个worker的最大连接数
    worker_connections 1024;
    
    # 使用epoll（Linux）
    use epoll;
    
    # 加速网络传输
    multi_accept on;
}

# HTTP模块配置
http {
    # 引入MIME类型
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # 日志格式
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    
    # 访问日志
    access_log /var/log/nginx/access.log main;
    
    # 高效文件传输
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    
    # 超时配置
    keepalive_timeout 65;
    types_hash_max_size 2048;
    
    # Gzip压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    
    # 引入其他配置
    include /etc/nginx/conf.d/*.conf;
}

# TCP/UDP代理配置（stream模块）
stream {
    include /etc/nginx/stream.conf.d/*.conf;
}
```

---

## 二、server和location

```nginx
# server块：定义一个虚拟主机
server {
    # 监听端口
    listen 80;
    listen 443 ssl http2;
    
    # 域名配置
    server_name example.com www.example.com;
    server_name ~^www\d+\.example\.com$;  # 正则匹配
    server_name .example.com;              # 通配符匹配
    
    # 字符集
    charset utf-8;
    
    # 根目录
    root /usr/share/nginx/html;
    
    # 默认首页
    index index.html index.htm;
    
    # 日志（可选）
    access_log /var/log/nginx/example.access.log;
    error_log /var/log/nginx/example.error.log;
    
    # location块：匹配URL路径
    location / {
        # 处理逻辑
    }
}

# location语法
location [ = | ~ | ~* | ^~ ] uri { ... }

# 匹配符优先级
# 1. =    精确匹配
# 2. ^~   前缀匹配（不检查正则）
# 3. ~    正则匹配（区分大小写）
# 4. ~*   正则匹配（不区分大小写）
# 5. /    普通前缀匹配
```

---

## 三、常用内置变量

```nginx
# 请求相关
$request              # 完整请求行
$request_method      # 请求方法（GET/POST）
$request_uri         # 完整URI（含参数）
$uri                 # 当前URI（不含参数）
$args                # URL参数
$query_string       # URL参数字符串

# 客户端相关
$remote_addr        # 客户端IP
$remote_port        # 客户端端口
$http_user_agent    # 用户代理（浏览器）
$http_cookie        # Cookie信息
$http_x_forwarded_for  # 代理链的真实IP

# 服务端相关
$server_name        # 匹配的server_name
$host               # 请求的Host头
$server_addr        # 服务器IP
$server_port        # 服务器端口
$scheme             # 协议（http/https）

# 响应相关
$status             # 响应状态码
$body_bytes_sent    # 发送的字节数
$request_time       # 请求处理时间（秒）

# 其他
$http_*             # 任意HTTP头（$http_content_type等）
$connection         # 连接序号
$connection_requests  # 当前连接的请求数
```

---

## 四、if判断

```nginx
# if条件判断（慎用，应优先使用location）

# 变量判断
if ($request_method = POST) {
    return 405;
}

# 正则匹配
if ($http_user_agent ~ MSIE) {
    rewrite ^(.*)$ /ie/$1 break;
}

# 否定匹配
if ($invalid_referer) {
    return 403;
}

# 常见条件
# =      等于
# !=     不等于
# ~      正则匹配（区分大小写）
# ~*     正则匹配（不区分大小写）
# -f     文件存在
# !-f    文件不存在
# -d     目录存在
# !-d    目录不存在
# -e     文件或目录存在
# -z     值为空
```

---

## 五、变量操作

```nginx
# 设置变量
set $variable_name value;

# 常用set示例
set $scheme $http_x_forwarded_proto;
set $proxy_host "";
set $real_ip "";

# map模块（复杂变量映射）
map $request_method $log_request {
    default     "unknown";
    GET        "yes";
    POST       "yes";
    DELETE     "yes";
}

# geo模块（IP地理位置）
geo $geo {
    default        unknown;
    127.0.0.1     local;
    10.0.0.0/8    internal;
    192.168.0.0/16  internal;
}
```

---

*下一步：常用指令详解*
