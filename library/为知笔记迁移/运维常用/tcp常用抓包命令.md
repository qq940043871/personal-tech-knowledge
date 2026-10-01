tcp常用抓包命令.md### 抓包存取
>  抓取所有经过网卡，目的主机为.的端口的网络数据并存储
tcpdump -i eth host . and port  -w /tmp/xxx.cap

### 过滤主机ip
> 抓取所有经过网卡，目的IP为.的网络数据
tcpdump -i eth host .

### 过滤端口
> 抓取所有经过网卡，目的端口为的网络数据
tcpdump -i eth dst port

### 过滤特定协议：
> 抓取所有经过网卡，协议类型为UDP的网络数据
tcpdump -i eth udp

### 抓取特定类型的数据包
> 抓取所有经过网卡的SYN类型数据包
tcpdump -i eth ‘tcp[tcpflags] = tcp-syn’

### 逻辑语句过滤
> 抓取所有经过网卡，目的网络是，但目的主机不是.的TCP数据
tcpdump -i eth ‘((tcp) and ((dst net ) and (not dst host .)))’