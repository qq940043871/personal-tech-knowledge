# Nginx安装与基本命令

> 模块：基础配置
> 更新时间：2026-03-29

---

## 一、安装方式

### 1. CentOS/RHEL (yum)

```bash
# 添加EPEL源
sudo yum install epel-release

# 安装Nginx
sudo yum install nginx

# 启动服务
sudo systemctl start nginx
sudo systemctl enable nginx
```

### 2. Ubuntu/Debian (apt)

```bash
# 安装
sudo apt update
sudo apt install nginx

# 启动服务
sudo systemctl start nginx
sudo systemctl enable nginx
```

### 3. Docker安装

```bash
# 官方镜像
docker pull nginx:latest

# 运行容器
docker run -d \
  --name nginx \
  -p 80:80 \
  -p 443:443 \
  -v /data/nginx/conf.d:/etc/nginx/conf.d \
  -v /data/nginx/html:/usr/share/nginx/html \
  nginx:latest
```

### 4. 编译安装（定制模块）

```bash
# 安装依赖
yum install -y gcc gcc-c++ make pcre pcre-devel zlib zlib-devel openssl openssl-devel

# 下载源码
wget http://nginx.org/download/nginx-1.24.0.tar.gz
tar -zxvf nginx-1.24.0.tar.gz
cd nginx-1.24.0

# 编译配置
./configure \
  --prefix=/usr/local/nginx \
  --with-http_ssl_module \
  --with-http_v2_module \
  --with-http_realip_module \
  --with-http_gzip_static_module \
  --with-stream

# 编译安装
make && make install

# 添加到PATH
export PATH=$PATH:/usr/local/nginx/sbin
```

---

## 二、基本命令

### 1. 服务管理

```bash
# 启动
nginx

# 停止（快速关闭）
nginx -s stop

# 优雅停止（处理完当前请求）
nginx -s quit

# 重新加载配置
nginx -s reload

# 检查配置文件语法
nginx -t

# 检查配置文件并显示内容
nginx -T

# 查看版本
nginx -v

# 显示详细版本和编译参数
nginx -V
```

### 2. 信号控制

```bash
# 查看Nginx进程
ps aux | grep nginx

# 主进程PID在 logs/nginx.pid

# 发送信号
kill -TERM <master_pid>    # 优雅关闭
kill -QUIT <master_pid>    # 等待 worker 完成后关闭
kill -HUP <master_pid>     # 重载配置
kill -USR1 <master_pid>     # 重新打开日志
kill -USR2 <master_pid>     # 平滑升级
```

### 3. 热加载配置

```bash
# 测试配置语法
nginx -t

# 重新加载配置（不中断服务）
nginx -s reload

# 重新打开日志文件
nginx -s reopen
```

---

## 三、目录结构

```bash
# RPM安装的目录结构
/etc/nginx/               # 配置目录
├── nginx.conf           # 主配置文件
└── conf.d/              # 额外配置目录
    └── default.conf     # 默认站点配置

/var/log/nginx/          # 日志目录
├── access.log           # 访问日志
└── error.log            # 错误日志

/usr/share/nginx/html/   # 默认静态文件目录
/var/cache/nginx/        # 缓存目录
/run/nginx.pid           # PID文件

# 编译安装的目录结构
/usr/local/nginx/         # 安装根目录
├── conf/nginx.conf       # 主配置
├── logs/                 # 日志
├── html/                 # 静态文件
└── sbin/nginx            # 执行文件
```

---

## 四、验证安装

```bash
# 检查版本
nginx -v

# 检查编译模块
nginx -V

# 测试配置文件
nginx -t

# 检查端口监听
netstat -tlnp | grep nginx
# 或
ss -tlnp | grep nginx

# 访问测试
curl -I http://localhost
# 或
curl http://localhost
```

---

## 五、systemd管理

```bash
# 创建服务文件
cat > /etc/systemd/system/nginx.service << EOF
[Unit]
Description=nginx - high performance web server
Documentation=https://nginx.org/en/docs/
After=network-online.target remote-fs.target nss-lookup.target
Wants=online.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

# 重新加载systemd
systemctl daemon-reload

# 管理服务
systemctl start nginx
systemctl stop nginx
systemctl restart nginx
systemctl reload nginx
systemctl status nginx
```

---

*下一步：核心配置结构*
