# Linux内核调优

> 模块：操作系统
> 更新时间：2026-03-28

---

## 一、理论基础

### 1. 内核参数体系

```
/proc/sys vs /etc/sysctl.conf：

/proc/sys（临时，重启失效）：
  echo 65535 > /proc/sys/net/core/somaxconn

/etc/sysctl.conf（永久，重启生效）：
  net.core.somaxconn = 65535
  sysctl -p  # 立即生效

参数生效顺序：
  1. /etc/sysctl.conf（系统默认）
  2. /etc/sysctl.d/*.conf（自定义配置）
  3. 命令行 sysctl -w（临时调整）
  4. /proc/sys（直接修改）
```

### 2. 网络参数调优

```
连接队列：
  net.core.somaxconn          # 服务端listen队列上限
  net.ipv4.tcp_max_syn_backlog # SYN队列长度

TCP时间管理：
  net.ipv4.tcp_fin_timeout    # FIN_WAIT_2超时
  net.ipv4.tcp_keepalive_time  # TCP保活检测间隔
  net.ipv4.tcp_keepalive_intvl # 保活探测间隔
  net.ipv4.tcp_keepalive_probes # 保活探测次数

TCP内存：
  net.ipv4.tcp_mem            # TCP内存页数（low/pressure/high）
  net.ipv4.tcp_rmem           # 接收缓冲区(min/default/max)
  net.ipv4.tcp_wmem           # 发送缓冲区(min/default/max)

TIME_WAIT优化：
  net.ipv4.tcp_tw_reuse = 1   # 重用TIME_WAIT连接
  net.ipv4.tcp_tw_recycle = 1 # 快速回收（公网慎用）
  net.ipv4.ip_local_port_range # 客户端可用端口范围
```

### 3. 内存参数调优

```
Swappiness：
  vm.swappiness = 60  # 0-100，越高越倾向使用Swap

脏页管理：
  vm.dirty_ratio = 20        # 脏页占比超此值，写操作阻塞
  vm.dirty_background_ratio = 10  # 后台刷盘阈值
  vm.dirty_expire_centisecs = 3000  # 脏页过期时间
  vm.dirty_writeback_centisecs = 500  # 刷盘间隔

内存分配：
  vm.overcommit_memory = 0   # 0=启发式，1=始终允许，2=严格限制
  vm.overcommit_ratio = 50   # overcommit时可用比例

内存映射：
  vm.max_map_count = 655360  # 最大内存映射区域数
  vm.nr_hugepages = 1024     # 大页数量
```

### 4. 文件系统参数

```
文件句柄：
  fs.file-max = 1000000      # 系统级文件描述符上限
  fs.nr_open = 1000000        # 单进程文件描述符上限

Inode缓存：
  fs.inotify.max_user_watches = 524288  # inotify监控数
  fs.inotify.max_user_instances = 1024  # inotify实例数

临时文件：
  fs.nr_open = 1000000
```

### 5. 内核模块参数

```bash
# 查看模块列表
lsmod

# 查看模块参数
modinfo <module_name>

# 临时修改参数
echo <value> > /sys/module/<module>/parameters/<param>

# 永久修改
# /etc/modprobe.d/*.conf
options <module_name> <param>=<value>
```

---

## 二、实践应用

### 1. 完整调优脚本

```bash
#!/bin/bash
# sysctl_tune.sh - Linux内核参数调优

cat >> /etc/sysctl.conf << 'EOF'
# ============= 网络优化 =============

# 连接队列
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535

# TCP时间管理
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 3

# TCP内存
net.ipv4.tcp_mem = 786432 1097152 1572864
net.ipv4.tcp_rmem = 4096 87380 6291456
net.ipv4.tcp_wmem = 4096 65536 4194304
net.core.rmem_max = 6291456
net.core.wmem_max = 4194304
net.core.rmem_default = 65536
net.core.wmem_default = 65536

# TIME_WAIT优化
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.ip_local_port_range = 1024 65535

# 连接复用
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fack = 1

# ============= 内存优化 =============

vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.dirty_expire_centisecs = 500
vm.dirty_writeback_centisecs = 100

vm.overcommit_memory = 1
vm.max_map_count = 655360

# ============= 文件系统 =============

fs.file-max = 1000000
fs.nr_open = 1000000
fs.inotify.max_user_watches = 524288
EOF

# 生效
sysctl -p
```

### 2. limits.conf优化

```bash
cat >> /etc/security/limits.conf << 'EOF'
# 文件描述符
* soft nofile 1000000
* hard nofile 1000000

# 进程数
* soft nproc 65535
* hard nproc 65535

# 核心转储
* soft core unlimited
* hard core unlimited

# 锁定内存
* soft memlock unlimited
* hard memlock unlimited
EOF

# 生效（需要重新登录）
```

### 3. 验证优化效果

```bash
# 查看当前网络参数
sysctl net.core.somaxconn
sysctl net.ipv4.tcp_max_syn_backlog

# 查看文件句柄
ulimit -n
cat /proc/sys/fs/file-nr

# 查看TIME_WAIT连接数
netstat -an | awk '/^tcp/ {s[$6]++} END {for(k in s) print k, s[k]}'

# 压测验证
# 使用wrk/ab进行压力测试，观察是否达到预期
wrk -t4 -c1000 -d30s http://localhost/
```

---

## 三、生产环境问题案例

### 案例1：突发大量连接导致连接失败

**问题现象：**
活动促销时，大量请求失败，连接被拒绝。

**分析过程：**
```bash
# 1. 查看连接状态
netstat -an | awk '/^tcp/ {s[$6]++} END {for(k in s) print k, s[k]}'

# 结果：
# ESTABLISHED 50000
# TIME_WAIT 40000
# SYN_RECV 10000  ← 积压

# 2. 查看队列长度
ss -ltn | grep :80

# 3. 查看内核参数
sysctl net.ipv4.tcp_max_syn_backlog
# 结果：128（默认值太小）

# 4. 分析
# 连接积压在SYN队列，accept不及时
```

**根因分析：**
tcp_max_syn_backlog和somaxconn默认值太小，无法应对突发。

**解决方案：**
```bash
# 立即生效
sysctl -w net.ipv4.tcp_max_syn_backlog=65535
sysctl -w net.core.somaxconn=65535

# 永久保存到配置
echo "net.ipv4.tcp_max_syn_backlog = 65535" >> /etc/sysctl.conf
echo "net.core.somaxconn = 65535" >> /etc/sysctl.conf

# Nginx配置
server {
    listen 80 backlog=65535;
}
```

**经验教训：**
- 高并发服务要调整连接队列
- 队列长度要和应用accept能力匹配
- 监控SYN_RECV连接数

---

### 案例2：端口耗尽

**问题现象：**
作为客户端调用外部服务，出现"Cannot assign requested address"错误。

**分析过程：**
```bash
# 1. 查看可用端口范围
sysctl net.ipv4.ip_local_port_range
# 结果：32768 60999（只有约28000个端口）

# 2. 查看TIME_WAIT连接
netstat -an | awk '/^tcp/ && $6=="TIME_WAIT" {s++} END {print s}'
# 结果：50000+

# 3. 分析
# 作为客户端发起大量短连接，端口快速耗尽
```

**根因分析：**
ip_local_port_range范围不够 + TIME_WAIT连接占用端口。

**解决方案：**
```bash
# 扩大端口范围
sysctl -w net.ipv4.ip_local_port_range="1024 65535"

# 开启端口重用
sysctl -w net.ipv4.tcp_tw_reuse=1

# 应用层面：使用连接池复用连接
# Nginx反向代理
# RPC长连接
```

**经验教训：**
- 大量短连接场景要扩大端口范围
- 优先使用长连接/连接池
- TIME_WAIT状态会占用端口

---

### 案例3：服务崩溃后无法重启

**问题现象：**
服务异常退出后，端口仍被占用，无法立即重启。

**分析过程：**
```bash
# 1. 查看端口占用
netstat -tlnp | grep :8080
# 结果：进程已不存在，但端口仍显示LISTEN

# 2. 查看连接状态
netstat -an | grep :8080
# 结果：存在半关闭连接（CLOSE_WAIT）
#       或者僵死进程未完全释放

# 3. 查看进程
ps aux | grep :8080
# 无进程，但端口占用

# 4. 分析
# 内核层面的socket未完全清理
```

**根因分析：**
进程异常退出但socket未正确关闭，状态残留。

**解决方案：**
```bash
# 方法1：等待内核清理（约1-2分钟）
# TIME_WAIT：2*MSL（通常1分钟）
# CLOSE_WAIT：取决于应用程序

# 方法2：强制关闭socket
# 使用ss命令找到并清理
ss -K state near/4a494f4e dst <ip> dport = 8080

# 方法3：快速重启
# 设置SO_REUSEADDR（应用程序）
# Nginx: listen 80 reuseport;

# 方法4：修改内核参数
sysctl -w net.ipv4.tcp_fin_timeout=15  # 缩短FIN_WAIT_2超时
```

**经验教训：**
- 服务要有优雅退出机制
- 配置reuseaddr/reuseport
- CLOSE_WAIT积压说明代码有bug

---

## 四、调优checklist

### 新机器上线前必做

```bash
# 1. 网络参数
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_tw_reuse = 1

# 2. 文件描述符
fs.file-max = 1000000
* soft nofile 1000000
* hard nofile 1000000

# 3. 内存参数
vm.swappiness = 10
vm.overcommit_memory = 1

# 4. 生效
sysctl -p
source /etc/security/limits.conf
```

### 验证命令

```bash
# 检查配置是否生效
sysctl -a | grep -E "somaxconn|file-max|tcp_tw_reuse"

# 检查限制
ulimit -n
cat /proc/sys/fs/file-nr

# 压测验证
```

---

*下一步：浏览器与Web技术 - 浏览器渲染原理*
