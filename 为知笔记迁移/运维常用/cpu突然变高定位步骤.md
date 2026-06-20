cpu突然变高定位步骤.md### 处理思路
>
 top 定位cpu高进程 >>pid
 top -Hp pid 定位cpu高线程 >>tpid
 printf "%x \n" tpid 转化为进制 >>tpid_ jstack pid | grep -A  tpid_ 显示此线程的后行
 for ((i=;i<;i++)); do jstack pid |grep -A  tpid_;sleep ;done >> pid.jstack  抓取多次线程栈

### top小技巧
>
 top按照cpu排序 top界面按键大写P
 top按照内存排序 top界面按键大写M
 top查看交换分区 top界面按键小写f