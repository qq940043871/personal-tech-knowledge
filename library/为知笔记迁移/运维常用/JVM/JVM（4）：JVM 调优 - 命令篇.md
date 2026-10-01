JVM（）：JVM 调优 - 命令篇

## JVM（）：JVM 调优 - 命令篇

_--_ [ImportNew](##) ImportNew

**ImportNew**

微信号 importnew

功能介绍 伯乐在线旗下账号，专注Java技术分享，包括Java基础技术、进阶技能、架构设计和Java技术领域动态等。

（点击上方公众号，可快速关注）

> 来源：纯洁的微笑，
>
> http://www.ityouknow.com/java/>
> [如有好文章投稿，请点击 → 这里了解详情](http://mp.weixin.qq.com/s?__biz=MjMNzMyMjAwMA==&mid=&idx=&sn=dbcfdcdfdfca&scene=#wechat_redirect)

运用jvm自带的命令可以方便的在生产监控和打印堆栈的日志信息帮忙我们来定位问题！虽然jvm调优成熟的工具已经有很多：jconsole、大名鼎鼎的VisualVM，IBM的Memory Analyzer等等，但是在生产环境出现问题的时候，一方面工具的使用会有所限制，另一方面喜欢装X的我们，总喜欢在出现问题的时候在终端输入一些命令来解决。所有的工具几乎都是依赖于jdk的接口和底层的这些命令，研究这些命令的使用也让我们更能了解jvm构成和特性。

Sun JDK监控和故障处理命令有jps jstat jmap jhat jstack jinfo下面做一一介绍。

**jps**

JVM Process Status Tool,显示指定系统内所有的HotSpot虚拟机进程。

**命令格式**

> jps \[options\] \[hostid\]

**option参数**

*   \-l : 输出主类全名或jar路径

*   \-q : 只输出LVMID

*   \-m : 输出JVM启动时传递给main()的参数

*   \-v : 输出JVM启动时显示指定的JVM参数

其中\[option\]、\[hostid\]参数也可以不写。

**示例**

> $ jps -l -m
>
>   org.apache.catalina.startup.Bootstrap start
>
>   org.apache.catalina.startup.Bootstrap start
>
>   sun.tools.jps.Jps -l -m

**jstat**

jstat(JVM statistics Monitoring)是用于监视虚拟机运行时状态信息的命令，它可以显示出虚拟机进程中的类装载、内存、垃圾收集、JIT编译等运行数据。

**命令格式**

> jstat \[option\] LVMID \[interval\] \[count\]

**参数**

*   \[option\] : 操作参数

*   LVMID : 本地虚拟机进程ID

*   \[interval\] : 连续输出的时间间隔

*   \[count\] : 连续输出的次数

**option 参数总览**

**option 参数详解**

**\-class**

监视类装载、卸载数量、总空间以及耗费的时间

> $ jstat -class >
>  Loaded  Bytes  Unloaded  Bytes     Time
>
>                    

*   Loaded : 加载class的数量

*   Bytes : class字节大小

*   Unloaded : 未加载class的数量

*   Bytes : 未加载class的字节大小

*   Time : 加载时间

**\-compiler**

输出JIT编译过的方法数量耗时等

> $ jstat -compiler >
> Compiled Failed Invalid   Time   FailedType FailedMethod
>
>                              org/apache/catalina/loader/WebappClassLoader findResourceInternal

*   Compiled : 编译数量

*   Failed : 编译失败数量

*   Invalid : 无效数量

*   Time : 编译耗时

*   FailedType : 失败类型

*   FailedMethod : 失败方法的全限定名

**\-gc**

垃圾回收堆的行为统计，常用命令

> $ jstat -gc >
>  SC    SC     SU     SU   EC       EU        OC         OU        PC       PU         YGC    YGCT    FGC    FGCT     GCT
>
>                                       

C即Capacity 总容量，U即Used 已使用的容量

*   SC : survivor区的总容量

*   SC : survivor区的总容量

*   SU : survivor区已使用的容量

*   SC : survivor区已使用的容量

*   EC : Eden区的总容量

*   EU : Eden区已使用的容量

*   OC : Old区的总容量

*   OU : Old区已使用的容量

*   PC 当前perm的容量 (KB)

*   PU perm的使用 (KB)

*   YGC : 新生代垃圾回收次数

*   YGCT : 新生代垃圾回收时间

*   FGC : 老年代垃圾回收次数

*   FGCT : 老年代垃圾回收时间

*   GCT : 垃圾回收总消耗时间

> $ jstat -gc

这个命令意思就是每隔s输出的gc情况，一共输出次

**\-gccapacity**

同-gc，不过还会输出Java堆各区域使用到的最大、最小空间

> $ jstat -gccapacity >
>  NGCMN    NGCMX     NGC    SC   SC       EC         OGCMN      OGCMX      OGC        OC       PGCMN    PGCMX     PGC      PC         YGC    FGC
>
>                              

*   NGCMN : 新生代占用的最小空间

*   NGCMX : 新生代占用的最大空间

*   OGCMN : 老年代占用的最小空间

*   OGCMX : 老年代占用的最大空间

*   OGC：当前年老代的容量 (KB)

*   OC：当前年老代的空间 (KB)

*   PGCMN : perm占用的最小空间

*   PGCMX : perm占用的最大空间

**\-gcutil**

同-gc，不过输出的是已使用空间占总空间的百分比

> $ jstat -gcutil >
>  S     S     E      O      P     YGC     YGCT    FGC    FGCT     GCT
>
>                                   

**\-gccause**

垃圾收集统计概述（同-gcutil），附加最近两次垃圾回收事件的原因

> $ jstat -gccause >
>  S     S     E      O      P       YGC     YGCT    FGC    FGCT     GCT    LGCC                 GCC
>
>                                       Allocation Failure   No GC

*   LGCC：最近垃圾回收的原因

*   GCC：当前垃圾回收的原因

**\-gcnew**

统计新生代的行为

> $ jstat -gcnew >
>  SC      SC      SU        SU  TT  MTT  DSS      EC        EU         YGC     YGCT
>
>                           

*   TT：Tenuring threshold(提升阈值)

*   MTT：最大的tenuring threshold

*   DSS：survivor区域大小 (KB)

**\-gcnewcapacity**

新生代与其相应的内存空间的统计

> $ jstat -gcnewcapacity >
>  NGCMN      NGCMX       NGC      SCMX     SC     SCMX     SC       ECMX        EC        YGC   FGC
>
>                       

*   NGC:当前年轻代的容量 (KB)

*   SCMX:最大的S空间 (KB)

*   SC:当前S空间 (KB)

*   ECMX:最大eden空间 (KB)

*   EC:当前eden空间 (KB)

**\-gcold**

统计旧生代的行为

> $ jstat -gcold >
>  PC       PU        OC           OU       YGC    FGC    FGCT     GCT
>
>                                 

**\-gcoldcapacity**

统计旧生代的大小和空间

> $ jstat -gcoldcapacity >
>  OGCMN       OGCMX        OGC         OC         YGC   FGC    FGCT     GCT
>
>                             

**\-gcpermcapacity**

永生代行为统计

> $ jstat -gcpermcapacity >
>  PGCMN      PGCMX       PGC         PC      YGC   FGC    FGCT     GCT
>
>                          

**\-printcompilation**

hotspot编译方法统计

> $ jstat -printcompilation >
>  Compiled  Size  Type Method
>
>                 java/util/ArrayList indexOf

*   Compiled：被执行的编译任务的数量

*   Size：方法字节码的字节数

*   Type：编译类型

*   Method：编译方法的类名和方法名。类名使用”/” 代替 “.” 作为空间分隔符. 方法名是给出类的方法名. 格式是一致于HotSpot – XX:+PrintComplation 选项

**jmap**

jmap(JVM Memory Map)命令用于生成heap dump文件，如果不使用这个命令，还阔以使用-XX:+HeapDumpOnOutOfMemoryError参数来让虚拟机出现OOM的时候·自动生成dump文件。 jmap不仅能生成dump文件，还阔以查询finalize执行队列、Java堆和永久代的详细信息，如当前使用率、当前使用的是哪种收集器等。

**命令格式**

> jmap \[option\] LVMID

**option参数**

*   dump : 生成堆转储快照

*   finalizerinfo : 显示在F-Queue队列等待Finalizer线程执行finalizer方法的对象

*   heap : 显示Java堆详细信息

*   histo : 显示堆中对象的统计信息

*   permstat : to print permanent generation statistics

*   F : 当-dump没有响应时，强制生成dump快照

**示例**

**\-dump**

常用格式

> \-dump::live,format=b,file=<filename> pid

dump堆到文件,format指定输出格式，live指明是活着的对象,file指定文件名

> $ jmap -dump:live,format=b,file=dump.hprof >
>  Dumping heap to /home/xxx/dump.hprof ...
>
>  Heap dump file created

dump.hprof这个后缀是为了后续可以直接用MAT(Memory Anlysis Tool)打开。

**\-finalizerinfo**

打印等待回收对象的信息

> $ jmap -finalizerinfo >
>  Attaching to process ID , please wait...
>
>  Debugger attached successfully.
>
>  Server compiler detected.
>
>  JVM version is -b>
>  Number of objects pending for finalization:

可以看到当前F-QUEUE队列中并没有等待Finalizer线程执行finalizer方法的对象。

**\-heap**

打印heap的概要信息，GC使用的算法，heap的配置及wise heap的使用情况,可以用此来判断内存目前的使用情况以及垃圾回收情况

> $ jmap -heap >
>  Attaching to process ID , please wait...
>
>  Debugger attached successfully.
>
>  Server compiler detected.
>
>  JVM version is -b
>
>  using thread-local object allocation.
>
>  Parallel GC with  thread(s)//GC 方式
>
>  Heap Configuration: //堆内存初始化配置
>
>  MinHeapFreeRatio =  //对应jvm启动参数-XX:MinHeapFreeRatio设置JVM堆最小空闲比率(default )
>
>  MaxHeapFreeRatio =  //对应jvm启动参数 -XX:MaxHeapFreeRatio设置JVM堆最大空闲比率(default )
>
>  MaxHeapSize      =  () //对应jvm启动参数-XX:MaxHeapSize=设置JVM堆的最大大小
>
>  NewSize          =  ()//对应jvm启动参数-XX:NewSize=设置JVM堆的‘新生代’的默认大小
>
>  MaxNewSize       =  MB//对应jvm启动参数-XX:MaxNewSize=设置JVM堆的‘新生代’的最大大小
>
>  OldSize          =  ()//对应jvm启动参数-XX:OldSize=<value>:设置JVM堆的‘老生代’的大小
>
>  NewRatio         =  //对应jvm启动参数-XX:NewRatio=:‘新生代’和‘老生代’的大小比率
>
>  SurvivorRatio    =  //对应jvm启动参数-XX:SurvivorRatio=设置年轻代中Eden区与Survivor区的大小比值
>
>  PermSize         =  ()  //对应jvm启动参数-XX:PermSize=<value>:设置JVM堆的‘永生代’的初始大小
>
>  MaxPermSize      =  ()//对应jvm启动参数-XX:MaxPermSize=<value>:设置JVM堆的‘永生代’的最大大小
>
>  GHeapRegionSize =  ()
>
>  Heap Usage://堆内存使用情况
>
>  PS Young Generation
>
>  Eden Space://Eden区内存分布
>
>  capacity =  ()//Eden区总容量
>
>  used     =  ()  //Eden区已使用
>
>  free     =  ()  //Eden区剩余容量
>
>  % used //Eden区使用比率
>
>  From Space:  //其中一个Survivor区的内存分布
>
>  capacity =  ()
>
>  used     =  ()
>
>  free     =  ()
>
>  % used
>
>  To Space:  //另一个Survivor区的内存分布
>
>  capacity =  ()
>
>  used     =  ()
>
>  free     =  ()
>
>  % used
>
>  PS Old Generation //当前的Old区内存分布
>
>  capacity =  ()
>
>  used     =  ()
>
>  free     =  ()
>
>  % used
>
>  PS Perm Generation//当前的 “永生代” 内存分布
>
>  capacity =  ()
>
>  used     =  ()
>
>  free     =  ()
>
>  % used
>
>   interned Strings occupying  bytes.

可以很清楚的看到Java堆中各个区域目前的情况。

**\-histo**

打印堆的对象统计，包括对象数、内存大小等等 （因为在dump:live前会进行full gc，如果带上live则只统计活对象，因此不加live的堆大小要大于加live堆的大小 ）

> $ jmap -histo:live  | more
>
>  num     #instances         #bytes  class name
>
> \----------------------------------------------
>
>  :                  <constMethodKlass>
>
>  :                  \[B
>
>  :                  <methodKlass>
>
>  :                  \[C
>
>  :                    <constantPoolKlass>
>
>  :                    <instanceKlassKlass>
>
>  :                    <constantPoolCacheKlass>
>
>  :                   java.lang.String
>
>  :                    <methodDataKlass>
>
>  :                     java.lang.Class
>
>  ....

xml class name是对象类型，说明如下：

> B  byte
>
> C  char
>
> D  double
>
> F  float
>
> I  int
>
> J  long
>
> Z  boolean
>
> \[  数组，如\[I表示int\[\]
>
> \[L+类名 其他对象

**\-permstat**

打印Java堆内存的永久保存区域的类加载器的智能统计信息。对于每个类加载器而言，它的名称、活跃度、地址、父类加载器、它所加载的类的数量和大小都会被打印。此外，包含的字符串数量和大小也会被打印。

> $ jmap -permstat >
>  Attaching to process ID , please wait...
>
>  Debugger attached successfully.
>
>  Server compiler detected.
>
>  JVM version is -b>
>  finding class loader instances ..done.
>
>  computing per loader stat ..done.
>
>  please wait.. computing liveness.liveness analysis may be inaccurate ...

>  class\_loader            classes bytes   parent\_loader           alive?  type
>
>  <bootstrap>                           null          live    <internal>
>
>  xcf                 xf      dead    sun/reflect/DelegatingClassLoader@xa>
>  xfcb                 xf      dead    sun/reflect/DelegatingClassLoader@xa>
>  xdb                    xdfc      dead    java/util/ResourceBundle$RBClassLoader@xec>
>  xd                   null          dead    sun/reflect/DelegatingClassLoader@xa

**\-F**

强制模式。如果指定的pid没有响应，请使用jmap -dump或jmap -histo选项。此模式下，不支持live子选项。

**jhat**

jhat(JVM Heap Analysis Tool)命令是与jmap搭配使用，用来分析jmap生成的dump，jhat内置了一个微型的HTTP/HTML服务器，生成dump的分析结果后，可以在浏览器中查看。在此要注意，一般不会直接在服务器上进行分析，因为jhat是一个耗时并且耗费硬件资源的过程，一般把服务器生成的dump文件复制到本地或其他机器上进行分析。

**命令格式**

> jhat \[dumpfile\]

**参数**

*   \-stack false|true 关闭对象分配调用栈跟踪(tracking object allocation call stack)。 如果分配位置信息在堆转储中不可用. 则必须将此标志设置为 false. 默认值为 true.>

*   \-refs false|true 关闭对象引用跟踪(tracking of references to objects)。 默认值为 true. 默认情况下, 返回的指针是指向其他特定对象的对象,如反向链接或输入引用(referrers or incoming references), 会统计/计算堆中的所有对象。>

*   \-port port-number 设置 jhat HTTP server 的端口号. 默认值 >

*   \-exclude exclude-file 指定对象查询时需要排除的数据成员列表文件(a file that lists data members that should be excluded from the reachable objects query)。 例如, 如果文件列列出了 java.lang.String.value , 那么当从某个特定对象 Object o 计算可达的对象列表时, 引用路径涉及 java.lang.String.value 的都会被排除。>

*   \-baseline exclude-file 指定一个基准堆转储(baseline heap dump)。 在两个 heap dumps 中有相同 object ID 的对象会被标记为不是新的(marked as not being new). 其他对象被标记为新的(new). 在比较两个不同的堆转储时很有用.>

*   \-debug int 设置 debug 级别.  表示不输出调试信息。 值越大则表示输出更详细的 debug 信息.>

*   \-version 启动后只显示版本信息就退出>

*   \-J< flag > 因为 jhat 命令实际上会启动一个JVM来执行, 通过 -J 可以在启动JVM时传入一些启动参数. 例如, -J-Xmx 则指定运行 jhat 的Java虚拟机使用的最大堆内存为  MB. 如果需要使用多个JVM启动参数,则传入多个 -Jxxxxxx.

**示例**

> $ jhat -J-Xmx dump.hprof
>
>  eading from dump.hprof...
>
>  Dump file created Fri Mar  :: CST >
>  Snapshot read, resolving...
>
>  Resolving  objects...
>
>  Chasing references, expect  dots......................................................
>
>  Eliminating duplicate references......................................................
>
>  Snapshot resolved.
>
>  Started HTTP server on port >
>  Server is ready.

中间的-J-Xmx是在dump快照很大的情况下分配内存去启动HTTP服务器，运行完之后就可在浏览器打开Http://localhost:进行快照分析 堆快照分析主要在最后面的Heap Histogram里，里面根据class列出了dump的时候所有存活对象。

分析同样一个dump快照，MAT需要的额外内存比jhat要小的多的多，所以建议使用MAT来进行分析，当然也看个人偏好。

**分析**

打开浏览器Http://localhost:，该页面提供了几个查询功能可供使用：

> All classes including platform
>
> Show all members of the rootset
>
> Show instance counts for all classes (including platform)
>
> Show instance counts for all classes (excluding platform)
>
> Show heap histogram
>
> Show finalizer summary
>
> Execute Object Query Language (OQL) query

一般查看堆异常情况主要看这个两个部分： Show instance counts for all classes (excluding platform)，平台外的所有对象信息。如下图： 

Show heap histogram 以树状图形式展示堆情况。如下图： 

具体排查时需要结合代码，观察是否大量应该被回收的对象在一直被引用或者是否有占用内存特别大的对象无法被回收。

一般情况，会down到客户端用工具来分析

**jstack**

jstack用于生成java虚拟机当前时刻的线程快照。线程快照是当前java虚拟机内每一条线程正在执行的方法堆栈的集合，生成线程快照的主要目的是定位线程出现长时间停顿的原因，如线程间死锁、死循环、请求外部资源导致的长时间等待等。 线程出现停顿的时候通过jstack来查看各个线程的调用堆栈，就可以知道没有响应的线程到底在后台做什么事情，或者等待什么资源。 如果java程序崩溃生成core文件，jstack工具可以用来获得core文件的java stack和native stack的信息，从而可以轻松地知道java程序是如何崩溃和在程序何处发生问题。另外，jstack工具还可以附属到正在运行的java程序中，看到当时运行的java程序的java stack和native stack的信息, 如果现在运行的java程序呈现hung的状态，jstack是非常有用的。

**命令格式**

> jstack \[option\] LVMID

**option参数**

*   \-F : 当正常输出请求不被响应时，强制输出线程堆栈

*   \-l : 除堆栈外，显示关于锁的附加信息

*   \-m : 如果调用到本地方法的话，可以显示C/C++的堆栈

**示例**

> $ jstack -l |more
>
> -- ::>
> Full thread dump Java HotSpot(TM) -Bit Server VM (-b mixed mode):
>
> "Attach Listener" daemon prio= tid=xfebb nid=xf waiting on condition \[x\]
>
>  java.lang.Thread.State: RUNNABLE
>
>  Locked ownable synchronizers:
>
>  - None
>
> "http-bio--exec-" daemon prio= tid=xfeb nid=xc waiting on condition \[xfeafe\]
>
>  java.lang.Thread.State: WAITING (parking)
>
>  at sun.misc.Unsafe.park(Native Method)
>
>  - parking to wait for  <xcae> (a java.util.concurrent.locks.AbstractQueuedSynchronizer$ConditionObject)
>
>  at java.util.concurrent.locks.LockSupport.park(LockSupport.java:)
>
>  at java.util.concurrent.locks.AbstractQueuedSynchronizer$ConditionObject.await(AbstractQueuedSynchronizer.java:)
>
>  at java.util.concurrent.LinkedBlockingQueue.take(LinkedBlockingQueue.java:)
>
>  at org.apache.tomcat.util.threads.TaskQueue.take(TaskQueue.java:)
>
>  at org.apache.tomcat.util.threads.TaskQueue.take(TaskQueue.java:)
>
>  at java.util.concurrent.ThreadPoolExecutor.getTask(ThreadPoolExecutor.java:)
>
>  at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:)
>
>  at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:)
>
>  at org.apache.tomcat.util.threads.TaskThread$WrappingRunnable.run(TaskThread.java:)
>
>  at java.lang.Thread.run(Thread.java:)
>
>  Locked ownable synchronizers:
>
>  - None
>
>  .....

**分析**

这里有一篇文章解释的很好 分析打印出的文件内容（http://www.hollischuang.com/archives/）。

**jinfo**

jinfo(JVM Configuration info)这个命令作用是实时查看和调整虚拟机运行参数。 之前的jps -v口令只能查看到显示指定的参数，如果想要查看未被显示指定的参数的值就要使用jinfo口令

**命令格式**

> jinfo \[option\] \[args\] LVMID

**option参数**

*   \-flag : 输出指定args参数的值

*   \-flags : 不需要args参数，输出所有JVM参数的值

*   \-sysprops : 输出系统属性，等同于System.getProperties()

**示例**

> $ jinfo -flag >
> \-XX:CMSInitiatingOccupancyFraction=

**本系列：**

[JVM（）：Java 类的加载机制](http://mp.weixin.qq.com/s?__biz=MjMNzMyMjAwMA==&mid=&idx=&sn=eefeecdfde&chksm=bdaaccfedeacfefadcdddfcc&scene=#wechat_redirect)

[JVM（）：JVM内存结构](http://mp.weixin.qq.com/s?__biz=MjMNzMyMjAwMA==&mid=&idx=&sn=eefcffbefa&chksm=bdacfddddffccdaaefcfa&scene=#wechat_redirect)

[JVM（）：Java GC算法 垃圾收集器](http://mp.weixin.qq.com/s?__biz=MjMNzMyMjAwMA==&mid=&idx=&sn=fecbdffedeec&chksm=bdacaffcdcecefafceec&scene=#wechat_redirect)

JVM（）：Jvm调优-命令篇

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