# Nginx跨域配置CORS

> 模块：跨域与缓存
> 更新时间：2026-03-29

---

## 一、CORS跨域基础

### 什么是跨域

```
跨域请求：当一个域向另一个域发起请求时

协议://域名:端口 三者任一不同即为跨域
- http://a.com → https://a.com        （协议不同）
- http://a.com → http://b.com        （域名不同）
- http://a.com → http://a.com:8080   （端口不同）

同源策略(SOP)：浏览器阻止跨域请求的响应被页面JS读取
```

---

## 二、CORS请求流程

### 简单请求 vs 预检请求

```nginx
# 简单请求（满足以下条件）：
# 1. GET/HEAD/POST之一
# 2. Content-Type为：
#    - application/x-www-form-urlencoded
#    - multipart/form-data
#    - text/plain
# 3. 无自定义Header

# 预检请求(Preflight)：
# 不满足上述条件时，先发OPTIONS请求探测
```

### CORS响应头

```nginx
# 必须的响应头
Access-Control-Allow-Origin     # 允许的来源（必需）
Access-Control-Allow-Methods    # 允许的方法
Access-Control-Allow-Headers   # 允许的请求头
Access-Control-Max-Age         # 预检结果缓存时间

# 可选的响应头
Access-Control-Allow-Credentials # 是否允许携带凭证
Access-Control-Expose-Headers   # JS可访问的响应头
```

---

## 三、Nginx跨域配置

### 基础配置

```nginx
server {
    listen 80;
    server_name example.com;
    
    location / {
        # 允许所有来源（生产环境不推荐）
        add_header Access-Control-Allow-Origin *;
        
        # 允许的方法
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
        
        # 允许的请求头
        add_header Access-Control-Allow-Headers "Content-Type, Authorization, X-Requested-With";
        
        # 缓存预检结果（减少OPTIONS请求）
        add_header Access-Control-Max-Age 3600;
        
        # 处理预检请求
        if ($request_method = 'OPTIONS') {
            return 204;
        }
        
        proxy_pass http://127.0.0.1:8080;
    }
}
```

### 生产环境推荐配置

```nginx
server {
    listen 80;
    server_name api.example.com;
    
    # CORS配置（白名单方式）
    location / {
        # 处理OPTIONS预检请求
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "https://www.example.com";
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
            add_header Access-Control-Allow-Headers "Content-Type, Authorization, X-Requested-With, X-Token";
            add_header Access-Control-Allow-Credentials "true";  # 允许携带Cookie
            add_header Access-Control-Max-Age 86400;
            return 204;
        }
        
        # 正常请求也添加CORS头
        add_header Access-Control-Allow-Origin "https://www.example.com" always;
        add_header Access-Control-Allow-Credentials "true" always;
        add_header Access-Control-Expose-Headers "Content-Length,Content-Type,X-Request-Id" always;
        
        proxy_pass http://127.0.0.1:8080;
    }
}
```

### 动态跨域配置（map方式）

```nginx
# 在http块中定义允许的域名列表
map $http_origin $cors_origin {
    default "";
    "~^https?://(www\.)?example\.com$" $http_origin;
    "~^https?://(www\.)?api\.example\.com$" $http_origin;
    "~^https?://localhost(:[0-9]+)?$" $http_origin;
    "~^https?://127\.0\.0\.1(:[0-9]+)?$" $http_origin;
}

server {
    listen 80;
    server_name api.example.com;
    
    location / {
        # 使用map变量的值
        add_header Access-Control-Allow-Origin $cors_origin;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
        add_header Access-Control-Allow-Headers "Content-Type, Authorization, X-Requested-With";
        add_header Access-Control-Allow-Credentials "true";
        add_header Access-Control-Max-Age 86400;
        
        if ($request_method = 'OPTIONS') {
            return 204;
        }
        
        proxy_pass http://127.0.0.1:8080;
    }
}
```

---

## 四、JSONP跨域（遗留方案）

```nginx
# JSONP使用<script>标签，只能用于GET请求
# 不推荐，仅作为备选方案

server {
    listen 80;
    server_name api.example.com;
    
    location /jsonp {
        # 获取回调函数名
        set $callback "";
        if ($arg_callback) {
            set $callback $arg_callback;
        }
        
        proxy_pass http://127.0.0.1:8080/api/data;
        
        # 包装为JSONP格式
        sub_filter_once on;
        sub_filter_types application/json;
        sub_filter '"data"' '"$callback(data)';
    }
}
```

---

## 五、常见问题

### 问题1：Nginx add_header不生效

```nginx
# if块内的add_header可能不生效
location / {
    # 错误写法
    if ($request_method = 'OPTIONS') {
        add_header Access-Control-Allow-Origin *;
        return 204;
    }
    
    # 正确写法：将header放在if外面
    location / {
        add_header Access-Control-Allow-Origin *;
        
        if ($request_method = 'OPTIONS') {
            return 204;
        }
        
        proxy_pass http://127.0.0.1:8080;
    }
}
```

### 问题2：Cookie不生效

```nginx
# CORS需要配置以下才能携带Cookie：
# 1. Access-Control-Allow-Credentials: true
# 2. Access-Control-Allow-Origin 不能为 *

# 正确配置
location / {
    add_header Access-Control-Allow-Origin $http_origin;  # 使用实际origin
    add_header Access-Control-Allow-Credentials "true";
}
```

### 问题3：自定义Header不生效

```nginx
# 自定义Header需要显式声明
location / {
    add_header Access-Control-Allow-Headers "Content-Type, Authorization, X-Custom-Header";
    add_header Access-Control-Expose-Headers "X-Custom-Response-Header";  # JS能读取的自定义响应头
}
```

---

*下一步：浏览器缓存与代理缓存*
