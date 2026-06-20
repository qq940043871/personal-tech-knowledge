Jvm常用命令

*   jvm内存使用情况

*   jmap -histo pid | head -n  查看前位
*   jmap -histo pid | sort -k  -g -r 查看对象数最多的对象，按降序输出
*   jmap -histo pid | sort -k  -g -r 查看内存的对象，按降序输出
*   jmap -dump:format=b,file=heap.hprof *   jmap -heap \[pid\]:查看jvm空间分布

*   jstat：Java虚拟机统计工具，可以用于监视JVM各种堆和非堆内存大小和使用量

*   jstat -class pid：输出加载类的数量及所占空间信息
*   jstat -gc pid：输出gc信息，包括gc次数和时间，内存使用状况（可带时间和显示条目参数）

*   jstack

*   jstack pid jvm线程情况

*   jstat

*   jstat -gcutil
*   vi

*   显示行号 :set number
*   跳转到最后一行 :$
*   跳转到第一行 :*   跳转到任一行 :行号 $表示跳转到行尾