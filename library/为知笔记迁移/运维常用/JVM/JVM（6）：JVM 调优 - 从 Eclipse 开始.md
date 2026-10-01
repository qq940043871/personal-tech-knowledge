JVM（）：JVM 调优 - 从 Eclipse 开始

## JVM（）：JVM 调优 - 从 Eclipse 开始

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

**概述**

什么是jvm调优呢？jvm调优就是根据gc日志分析jvm内存分配、回收的情况来调整各区域内存比例或者gc回收的策略；更深一层就是根据dump出来的内存结构和线程栈来分析代码中不合理的地方给予改进。eclipse优化主要涉及的是前者，通过gc日志来分析。本文主要是通过分析eclipse gc日志为例来示例如何根据gc日志来分析jvm内存而进行调优,像根据关闭eclipse启动项、关闭各种校验等措施来优化eclipse本文不再阐述，网上有很多，本次测试的eclipse已经进行了配置上面的优化。

**准备环境**

eclipse版本：Release .
eclipse 默认配置：eclipse.ini

> \-startup
>
> plugins/org.eclipse.equinox.launcher\_.v-jar
>
> \--launcher.library
>
> plugins/org.eclipse.equinox.launcher.winwinx\_\_.v->
> \-product
>
> org.eclipse.epp.package.jee.product
>
> \--launcher.defaultAction
>
> openFile
>
> \--launcher.XXMaxPermSize
>
> >
> \-showsplash
>
> org.eclipse.platform
>
> \--launcher.XXMaxPermSize
>
> >
> \--launcher.defaultAction
>
> openFile
>
> \--launcher.appendVmargs
>
> \-vmargs
>
> \-Dosgi.requiredJavaVersion=>
> \-Xms>
> \-Xmx

在配置的末尾处添加如下配置文件：

\-XX:+PrintGCDetails   // 输出GC的详细日志

\-XX:+PrintGCDateStamps // 输出GC的时间戳（以日期的形式）

\-Xloggc:gc.log  // 输出GC的详细日志

eclipse启动计时插件：

http://www.chendd.cn/information/viewInformation/experienceShare/a

GChisto.jar:gc日志分析工具jar包一个

Visual GC: java自带的内存监控工具，通过visual gc可以实时的监控到各个内存区域的变化。 

**如何分析GC日志**

摘录GC日志一部分（绿色为年轻代gc回收；蓝色为full gc回收）：

> --::+: : \[GC \[PSYoungGen: ->()\] ->(),  secs\] \[Times: user= sys=, real= secs\]

> --::+: : \[Full GC \[PSYoungGen: ->()\] \[ParOldGen: ->()\] ->() \[PSPermGen: ->()\],  secs\] \[Times: user= sys=, real= secs\]

通过上面日志分析得出，PSYoungGen、ParOldGen、PSPermGen属于Parallel收集器。其中PSYoungGen表示gc回收前后年轻代的内存变化；ParOldGen表示gc回收前后老年代的内存变化；PSPermGen表示gc回收前后永久区的内存变化。young gc 主要是针对年轻代进行内存回收比较频繁，耗时短；full gc 会对整个堆内存进行回城，耗时长，因此一般尽量减少full gc的次数

通过两张图非常明显看出gc日志构成：

young gc 日志

Full GC日志

**启动调优**

启动eclipse查看默认配置下启动时间大概是秒。

根据GChisto分析gc日志看出来，启动过程中进行了一次full gc,次minor gc;full gc和young gc的时间差不多都是秒左右。

**第一步优化：**

为了避免内存频繁的动态扩展，直接把-Xms配置和-Xmx一致，修改如下：

\-Xms

修改完毕，重新启动： 

启动时间缩小到秒，分析gc日志得出young gc次，full gc没有了! 但是young gc增加了两次。

**第二步优化：**

因为本机的内存,给eclipse分配还是有点小了，简单粗暴直接所有内存配置加倍。

配置如下：

–launcher.XXMaxPermSize

–launcher.XXMaxPermSize

\-Xms

\-Xmx

启动时间缩小到秒，但是 young gc已经缩短到只有次，说明因为gc回收导致eclipse 启动慢的问题已经初步解决

**第三步优化：**

通过Visual GC看到在eclipse启动的时候classloader加载class的时间有一些，关闭字节码可能会优化一部分启动时间，加入如下参数：

\-Xverify:none（关闭Java字节码验证，从而加快了类装入的速度）

重新启动测试,启动时间已经优化到了秒！

查看启动日志，young gc 的次数仅仅只有了一次！

至此优化结束，附最终的eclipse.ini文件

> \-startup
>
> plugins/org.eclipse.equinox.launcher\_.v-jar
>
> \--launcher.library
>
> plugins/org.eclipse.equinox.launcher.winwinx\_\_.v->
> \-product
>
> org.eclipse.epp.package.jee.product
>
> \--launcher.defaultAction
>
> openFile
>
> \--launcher.XXMaxPermSize
>
> >
> \-showsplash
>
> org.eclipse.platform
>
> \--launcher.XXMaxPermSize
>
> >
> \--launcher.defaultAction
>
> openFile
>
> \--launcher.appendVmargs
>
> \-vmargs
>
> \-Dosgi.requiredJavaVersion=>
> \-Xms>
> \-Xmx>
> \-Xverify:none
>
> \-XX:+PrintGCDetails
>
> \-XX:+PrintGCDateStamps
>
> \-Xloggc:gc.log

**本系列：**

[JVM（）：Java 类的加载机制](http://mp.weixin.qq.com/s?__biz=MjMNzMyMjAwMA==&mid=&idx=&sn=eefeecdfde&chksm=bdaaccfedeacfefadcdddfcc&scene=#wechat_redirect)

[JVM（）：JVM内存结构](http://mp.weixin.qq.com/s?__biz=MjMNzMyMjAwMA==&mid=&idx=&sn=eefcffbefa&chksm=bdacfddddffccdaaefcfa&scene=#wechat_redirect)

[JVM（）：Java GC算法 垃圾收集器](http://mp.weixin.qq.com/s?__biz=MjMNzMyMjAwMA==&mid=&idx=&sn=fecbdffedeec&chksm=bdacaffcdcecefafceec&scene=#wechat_redirect)

[JVM（）：Jvm调优-命令篇](http://mp.weixin.qq.com/s?__biz=MjMNzMyMjAwMA==&mid=&idx=&sn=acaedecddddc&chksm=bdcacacaeacfaaaaabdedade&scene=#wechat_redirect)

[JVM（）：tomcat性能调优和性能监控（visualvm）](http://mp.weixin.qq.com/s?__biz=MjMNzMyMjAwMA==&mid=&idx=&sn=dcbfdcabcdfde&chksm=bdacfadccdafefcfddffdea&scene=#wechat_redirect)

JVM（）：JVM调优-从eclipse开始

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