JVM（）：Tomcat 性能调优和性能监控（visualvm）

## JVM（）：Tomcat 性能调优和性能监控（visualvm）

_--_ [ImportNew](##) ImportNew

**ImportNew**

微信号 importnew

功能介绍 伯乐在线旗下账号，专注Java技术分享，包括Java基础技术、进阶技能、架构设计和Java技术领域动态等。

（点击上方公众号，可快速关注）

> 来源：纯洁的微笑，
>
> www.cnblogs.com/ityouknow/p/html
>
> [如有好文章投稿，请点击 → 这里了解详情](http://mp.weixin.qq.com/s?__biz=MjMNzMyMjAwMA==&mid=&idx=&sn=dbcfdcdfdfca&scene=#wechat_redirect)

**tomcat服务器优化**

**、JDK内存优化**

根据服务器物理内容情况配置相关参数优化tomcat性能。当应用程序需要的内存超出堆的最大值时虚拟机就会提示内存溢出，并且导致应用服务崩溃。因此一般建议堆的最大值设置为可用内存的最大值的%。 Tomcat默认可以使用的内存为，在较大型的应用项目中，这点内存是不够的，需要调大.

Tomcat默认可以使用的内存为,Windows下,在文件/bin/catalina.bat，Unix下，在文件/bin/catalina.sh的前面，增加如下设置： JAVA\_OPTS=’-Xms【初始化内存大小】 -Xmx【可以使用的最大内存】 -XX:PermSize= -XX:MaxPermSize=’ 需要把几个参数值调大。例如： JAVA\_OPTS=’-Xms -Xmx’ 表示初始化内存为，可以使用的最大内存为。

**参数详解**

> \-server  启用jdk 的 server 版；
>
> \-Xms    java虚拟机初始化时的最小内存；
>
> \-Xmx    java虚拟机可使用的最大内存；
>
> \-XX:PermSize    内存永久保留区域
>
> \-XX:MaxPermSize   内存最大永久保留区域
>
> \-Xmn    jvm最小内存

内存配置示例：

> JAVA\_OPTS="$JAVA\_OPTS  -Xms -Xmx -XX:PermSize= -XX:MaxPermSize= -Xshare:off -Xmn

**、tomcat线程优化**

在tomcat配置文件server.xml中的配置中，和连接数相关的参数有：

maxThreads： Tomcat使用线程来处理接收的每个请求。这个值表示Tomcat可创建的最大的线程数。默认值。

acceptCount： 指定当所有可以使用的处理请求的线程数都被使用时，可以放到处理队列中的请求数，超过这个数的请求将不予处理。默认值。

minSpareThreads： Tomcat初始化时创建的线程数。默认值。

maxSpareThreads： 一旦创建的线程超过这个值，Tomcat就会关闭不再需要的socket线程。默认值。

enableLookups： 是否反查域名，默认值为true。为了提高处理能力，应设置为false

connnectionTimeout： 网络连接超时，默认值，单位：毫秒。设置为表示永不超时，这样设置有隐患的。通常可设置为毫秒。

maxKeepAliveRequests： 保持请求数量，默认值。 bufferSize： 输入流缓冲大小，默认值 bytes。

compression： 压缩传输，取值on/off/force，默认值off。 其中和最大连接数相关的参数为maxThreads和acceptCount。如果要加大并发连接数，应同时加大这两个参数。

内存配置示例：

> <Connector port="" protocol="HTTP/"
>
>  connectionTimeout="" maxThreads="" minSpareThreads="" maxSpareThreads=""  acceptCount=""
>
>  redirectPort="" URIEncoding="utf-"/>

**使用visualvm性能监控**

**、什么是VisualVM**

visualvm是jdk自带的一款监控工具。它提供了一个可视界面，用于查看 Java 虚拟机上运行的基于 Java 技术的程序的详细信息。VisualVM 对 Java Development Kit (JDK) 工具所检索的 JVM 软件相关数据进行组织，并通过一种使您可以快速查看有关多个 Java 应用程序的数据的方式提供该信息。您可以查看本地应用程序以及远程主机上运行的应用程序的相关数据

**、如何安装**

在jkd bin目录下有一个jvisualvm.exe文件 双击就可以使用

**、如何使用jvisualvm**

、配置JMX管理tomcat；

> set JAVA\_OPTS=-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port= -Dcom.sun.management.jmxremote.authenticate=false -    Dcom.sun.management.jmxremote.ssl=false

、重启tomcat即可；

、双击jvisualvm.exe 添加服务器IP地址，添加需要监控jmx端口即可。

效果如下：

**本系列：**

[JVM（）：Java 类的加载机制](http://mp.weixin.qq.com/s?__biz=MjMNzMyMjAwMA==&mid=&idx=&sn=eefeecdfde&chksm=bdaaccfedeacfefadcdddfcc&scene=#wechat_redirect)

[JVM（）：JVM内存结构](http://mp.weixin.qq.com/s?__biz=MjMNzMyMjAwMA==&mid=&idx=&sn=eefcffbefa&chksm=bdacfddddffccdaaefcfa&scene=#wechat_redirect)

[JVM（）：Java GC算法 垃圾收集器](http://mp.weixin.qq.com/s?__biz=MjMNzMyMjAwMA==&mid=&idx=&sn=fecbdffedeec&chksm=bdacaffcdcecefafceec&scene=#wechat_redirect)

[JVM（）：Jvm调优-命令篇](http://mp.weixin.qq.com/s?__biz=MjMNzMyMjAwMA==&mid=&idx=&sn=acaedecddddc&chksm=bdcacacaeacfaaaaabdedade&scene=#wechat_redirect)

JVM（）：tomcat性能调优和性能监控（visualvm）

看完本文有收获？请转发分享给更多人

****关注「ImportNew」，提升Java技能****

[阅读原文](##)

阅读

[投诉](##)

精选留言

该文章作者已设置需关注才可以留言

写留言

该文章作者已设置需关注才可以留言

写留言

 加载中

以上留言由公众号筛选后显示

[了解留言功能详情](http://kf.qq.com/touch/sappfaq/YfyMVjqmMbyi.html?scene_id=kf)

微信扫一扫
关注该公众号