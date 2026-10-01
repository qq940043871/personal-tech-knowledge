Linux查看硬件配置命令.md### 资源
>
 du -ah --max-depth=  查看文件大小

 for i in /*; do echo $i;find $i|wc -l;done 目录下文件个数

 df -i 磁盘inode节点数量

 lsof| grep delete|more 僵尸文件

 du -s /usr/*  |sort -nr #查看文件大小并排序

 free -m # 查看内存使用量和交换区使用量
 df -h # 查看各分区使用情况
 du -sh <目录名> # 查看指定目录的大小
 uptime # 查看系统运行时间、用户数、负载
 cat /proc/loadavg # 查看系统负载

### 网络
>
 ifconfig # 查看所有网络接口的属性
 iptables -L # 查看防火墙设置
 route -n # 查看路由表
 netstat -lntp # 查看所有监听端口
 netstat -antp # 查看所有已经建立的连接
 netstat -s # 查看网络统计信息
### 进程
>
 ps -ef # 查看所有进程
 top # 实时显示进程状态
 /proc/pid #查看进程所在路径

### 系统
>
 uname -a # 查看内核/操作系统/CPU信息
 head -n  /etc/issue # 查看操作系统版本
 cat /proc/cpuinfo # 查看CPU信息
 hostname # 查看计算机名
 lspci -tv # 列出所有PCI设备
 lsusb -tv # 列出所有USB设备
 lsmod # 列出加载的内核模块
 env # 查看环境变量
### 磁盘和分区
>
 mount | column -t # 查看挂接的分区状态
 fdisk -l # 查看所有分区
 swapon -s # 查看所有交换分区
 hdparm -i /dev/hda # 查看磁盘参数(仅适用于IDE设备)
 dmesg | grep IDE # 查看启动时IDE设备检测状况

来源： http://www.lian.com/edu//-/html