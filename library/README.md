# p000_0000_all · 个人知识库与工程实践全集

> 更新日期：2026-04-22
> 说明：本文档是对整个工作区（workspace）的全面说明，涵盖所有知识库、学习指南、"手写"系列项目、工具链体系等内容。
> 索引：分类导航见 [wiki.md](./wiki.md)

---

## 一、项目总体概览

`p000_0000_all` 是一个**大型的个人知识库与工程实践集合**，作者为一位拥有17年经验（2009年入行）的软件工程师。整个工作区融合了以下几大内容：

| 分类 | 说明 |
|------|------|
| **技术学习指南** | 涵盖 Linux、Nginx、Kafka、Redis、FFmpeg、OpenCV、ZooKeeper、MinIO、Openclaw、AI 类库等主流中间件和工具的学习笔记 |
| **"手写"系列** | 从零实现操作系统、Web容器、数据库、大模型、JVM、浏览器、游戏引擎、消息中间件等核心系统 |
| **17年经验总结** | 计算机组成原理 → 操作系统 → MySQL → Redis → 消息队列 → 架构设计，含大量生产环境实战案例 |
| **AI/大模型专题** | 大模型工具全景图、AI 学习大纲、AI 常用类库指南 |
| **为知笔记迁移** | 从为知笔记（WizNote）迁移过来的历史笔记库，涵盖运维、架构、项目管理、DevOps、JVM、生活理财等多个领域 |
| **实际工作项目** | 摄像头视频方案、智能体管理系统设计等真实项目文档 |
| **操作系统教程** | OS_Tutorial 英文教程（引导 → 内核 → 驱动 → Shell） |
| **文档体系** | 技术文档写作规范（Divio 四象限）、文档模板、贡献指南 |

---

## 二、目录结构总览

```
p000_0000_all/
│
├── app.py                          # Flask Web 服务（提供 Markdown 文件浏览 API）
├── python.html                     # 前端页面（Markdown 文档浏览器，基于 marked.js）
├── index.html                      # 另一个前端页面（知识库文档浏览器，带左侧目录树）
├── README.md                       # 本文件
├── CLAUDE.md                       # 项目说明
├── wiki.md                         # 知识库分类索引
│
├── 17年技术经验总结/               # 核心技术体系：基础 → 中间件 → 架构（38篇）
├── AI常用类库指南/                 # AI 各领域 Python 类库速查（9篇）
├── ClaudeCode学习指南/             # Claude Code AI 编程助手使用教程（29篇）
├── FFmpeg学习指南/                 # 音视频处理工具 FFmpeg 教程（6篇）
├── Java框架全景图/                 # Java 生态全部主流框架图谱（28篇）
├── Java避坑指南/                   # Java/Spring/数据库/微服务开发避坑（8篇）
├── Kafka学习指南/                  # 消息队列 Kafka 从入门到运维（9篇）
├── Linux学习指南/                  # Linux 基础命令、进程、内存、CPU、网络、文件系统（30篇）
├── MiniIO学习指南/                 # 对象存储 MinIO 教程（6篇）
├── Nginx学习指南/                  # Nginx 反向代理/负载均衡/安全配置（11篇）
├── Openclaw学习指南/               # Openclaw 开源智能体框架（26篇）
├── OpenCV学习指南/                 # 计算机视觉库 OpenCV 教程（6篇）
├── OS_Tutorial/                    # 操作系统实现教程·英文（14篇）
├── Redis学习指南/                  # Redis 数据类型/集群/缓存策略（12篇）
├── Zookeeper学习指南/              # 分布式协调服务 ZK 教程（7篇）
│
├── 手写JVM/                        # 从零实现 Java 虚拟机（27篇）
├── 手写Web容器/                    # 从零实现类 Tomcat（42篇）
├── 手写大模型/                     # 从零实现类 GPT 大模型应用框架（53篇）
├── 手写操作系统/                   # 从零实现操作系统，含 code/ 与 docs/（13篇）
├── 手写数据库/                     # 从零实现关系型数据库（43篇）
├── 手写浏览器/                     # 从零实现浏览器（37篇）
├── 手写游戏引擎/                   # 从零实现 2D/3D 游戏引擎（49篇）
├── 大模型工具全景图/               # LLM 工具链速查（14篇，含 AI 学习大纲）
│
├── 技术文档体系/                   # 文档规范与模板
│   ├── DOC_SYSTEM.md               # 文档体系总纲（Divio 四象限）
│   ├── WRITING_GUIDE.md            # 写作风格与格式规范
│   ├── CONTRIBUTING_DOCS.md        # 文档贡献指南
│   └── templates/                  # README、API、功能模板
│
├── 实际工作项目/                   # 实际工作中的项目文档
│   ├── 摄像头视频方案/             # FFmpeg拉流 → ZLM推流/回放/集成
│   └── 智能体管理系统设计/         # 基于 RuoYi 的智能体管理后台（Vue + Java）
│
└── 为知笔记迁移/                   # 从为知笔记导出的历史笔记（255篇）
    ├── My Notes/                   # SkyWalking、DevOps、ZK、微服务、MySQL、敏捷测试等课程笔记
    ├── My Tasks/                   # 个人规划与反思
    ├── 博客园/                     # 博客整理的七个技术专题
    ├── 宝宝知道/                   # 育儿知识
    ├── 工作记录/                   # 历史工作文档
    ├── 微权力下的项目管理/         # 项目管理系列学习
    ├── 炒股养家/                   # 投资笔记
    ├── 运维常用/                   # 日常运维命令、JVM 调优、架构师笔记
    └── 项目管理/                   # 项目管理方法论
```

---

## 三、技术知识体系 —— "17年技术经验总结"

这是整个知识库的**核心主干**，按"基础→中间件→架构"的递进结构编排：

### 3.1 计算机组成原理
- CPU 架构（x86/ARM）、指令流水线、分支预测
- 内存层级、缓存一致性（MESI）、NUMA 架构
- 存储层次与 IO 原理（HDD/SSD、RAID）
- **生产问题**：CPU 飙高、内存泄漏、IO 瓶颈

### 3.2 操作系统
- 进程调度、线程模型、上下文切换
- 虚拟内存、页表、TLB、内存映射
- 文件系统（ext4/xfs）、IO 模型（阻塞/非阻塞/多路复用）
- Linux 内核参数调优
- **生产问题**：进程僵死、OOM Killer、系统负载异常

### 3.3 浏览器与 Web 技术
- 渲染管线、DOM 解析、CSSOM、重绘回流
- HTTP 协议演进（HTTP/1.1→2→3/QUIC）、HTTPS
- 前端性能优化、缓存策略、CDN
- **生产问题**：白屏、加载慢、兼容性

### 3.4 虚拟化与容器
- 虚拟机原理（KVM/Xen/Hyper-V）
- Docker 原理（namespace/cgroup/unionfs）
- Kubernetes（Pod/Service/Deployment/ConfigMap）
- **生产问题**：容器网络、资源限制、镜像安全

### 3.5 MySQL 数据库
- InnoDB 架构（Buffer Pool、Change Buffer、Adaptive Hash Index）
- B+ 树索引、聚簇索引、覆盖索引、索引优化
- MVCC、事务隔离级别、锁类型、死锁排查
- 主从复制、GTID、MHA/Orchestrator
- **生产问题**：死锁、主从延迟、数据恢复

### 3.6 Redis 中间件
- 5+2 种数据结构底层实现（跳表、压缩列表、整数集合等）
- 持久化（RDB/AOF/混合）、主从复制、Sentinel、Cluster
- 缓存穿透/击穿/雪崩、缓存一致性
- **生产问题**：大 Key、热点 Key、内存碎片

### 3.7 消息中间件
- 消息模型（点对点/发布订阅）、投递语义
- RabbitMQ（路由模式、死信队列、延迟队列）
- Kafka（分区策略、消费者组、Exactly-Once）
- **生产问题**：消息丢失、重复消费、积压

### 3.8 架构设计与工程实践
- 分布式理论基础（CAP/BASE/一致性协议）
- 高并发设计模式（限流/降级/熔断/隔离）
- 故障排查方法论（日志/监控/链路追踪）
- 历史技术选型决策记录

---

## 四、"手写"系列项目

这个系列是**从零实现经典基础软件**的完整教程与设计文档，每个项目都有完整的目录结构、架构设计图、技术选型和里程碑规划：

| 项目 | 参考目标 | 核心技术栈 | 章节数 | 文档数 |
|------|---------|-----------|--------|--------|
| **手写操作系统** | Linux/xv6 | x86汇编 + C | 7 部分 | 13 篇 |
| **手写JVM** | OpenJDK HotSpot | Java/C++ | 10 阶段 | 27 篇 |
| **手写Web容器** | Tomcat 9/10 | Java NIO / Reactor | 10 模块 | 42 篇 |
| **手写数据库** | MySQL 8.0 | Java / B+树 / MVCC | 11 模块 | 43 篇 |
| **手写大模型** | GPT-4 / LangChain | Python / Transformer | 13 模块 | 53 篇 |
| **手写浏览器** | Chromium | C++ / Skia / V8 | 11 模块 | 37 篇 |
| **手写游戏引擎** | Unity / Godot | C++ / OpenGL / ECS | 13 模块 | 49 篇 |
| **手写消息中间件** | Kafka / RocketMQ | Java / 协议设计 | 11 模块 | 72 篇 |

### 亮点示例：手写大模型
这是最复杂的一个项目，覆盖了完整的 LLM 应用框架：
- **核心架构**：模型加载、推理引擎、对话管理
- **Tokenizer**：BPE 分词、词表管理
- **Attention**：Self-Attention、Multi-Head、KV-Cache、Flash Attention
- **Skill 系统**：插件化扩展、Skill 注册与执行
- **MCP 协议**：Model Context Protocol 服务端与客户端
- **RAG**：文档切分、Embedding、向量检索
- **Agent 编排**：任务规划、工具选择、多 Agent 协作

### 操作系统教程（OS_Tutorial）
英文操作系统实现教程（引导 → 内核 → 驱动 → Shell），共 14 篇：
```
OS_Tutorial/
├── 00-Prerequisites.md    → 前置知识
├── 01-Bootloader.md       → MBR 引导
├── 02-ProtectedMode.md    → 实模式→保护模式
├── 03-Kernel_Entry.md     → 内核入口
├── 04-Memory.md           → 内存管理
├── 05-Interrupts.md       → 中断处理
├── 06-Process.md          → 进程调度
├── 07-FileSystem.md       → 文件系统
├── 08-Drivers.md          → 设备驱动
├── 09-Shell.md            → 命令行 Shell
├── 10-Syscall.md          → 系统调用
├── 11-UserPrograms.md     → 用户程序
└── A-References.md        → 参考资料
```

---

## 五、AI / 大模型专题

### 5.1 大模型工具全景图
完整的 LLM 工具链速查，涵盖 9 大类工具：
- **应用框架**：LangChain、LlamaIndex、Semantic Kernel、AutoGen、CrewAI
- **向量数据库**：Pinecone、Milvus、Chroma、Weaviate、Qdrant、FAISS
- **Embedding**：OpenAI、BGE、M3E、Jina、Sentence-Transformers
- **微调工具**：LLaMA-Factory、Axolotl、DeepSpeed、PEFT、Unsloth、MLX
- **部署推理**：Ollama、vLLM、llama.cpp、TGI、GPTQ、AWQ
- **评估**：LangSmith Evals、RAGAS、HELM、BIG-bench、MMLU

### 5.2 AI 学习大纲
从零到一的系统性 AI 学习路线（位于 `大模型工具全景图/00-总览/`）：
1. 机器学习入门（概念 + 数学 + 经典算法）
2. 深度学习基础（神经网络 + CNN + Transformer）
3. 常用框架（NumPy/PyTorch/HuggingFace）
4. 机器学习实战（流程 + 项目 + 工程化）
5. NLP 实战（从传统 NLP 到大语言模型）
6. 图像识别实战（CNN + 目标检测 + 分割）
7. 大模型基础（发展历程 + 核心技术 + 局限性）
8. 大模型实战（Prompt + RAG + 微调 + Agent）

### 5.3 Claude Code 学习指南
专门针对 **Claude Code（AI 编程助手）** 的学习资料：
- 核心特性、安装配置、IDE 集成
- Skills 技能系统、Slash 命令、Hooks 钩子
- MCP 协议集成、QueryEngine 核心引擎
- 多 Agent 协作、CI/CD 集成
- 自定义 Skills 开发、远程会话

### 5.4 AI 常用类库指南
各 AI 领域的 Python 类库速查：
- 图像分类（timm/torchvision）、目标检测（YOLO/Detectron2）
- NLP（Transformers/spaCy/HuggingFace）、语音识别（Whisper）
- 语义理解（LangChain/Sentence-Transformers）
- 图像生成（Stable Diffusion/ControlNet）、视频生成（Sora）

---

## 六、中间件学习指南

| 学习指南 | 内容覆盖 | 定位 |
|----------|---------|------|
| **Linux** | 基础命令、进程管理、内存管理、CPU 调度、网络管理、文件系统 | 系统化 Linux 学习 |
| **Nginx** | 基础配置、反向代理、负载均衡、安全（HTTPS/SSL）、缓存、高可用 | 全面掌握 Nginx |
| **Kafka** | 安装入门、Topic/Partition、生产者消费者、存储机制、运维集群 | 消息中间件 |
| **Redis** | 数据类型、核心特性、高级特性、集群高可用、应用场景 | 缓存核心 |
| **FFmpeg** | 安装、常用命令、视频转码、音频处理、RTSP/RTMP 流媒体 | 音视频处理 |
| **OpenCV** | Python+OpenCV、图像处理、特征检测、摄像头捕获 | 计算机视觉 |
| **ZooKeeper** | 基础概念、ZAB 协议、Watch 机制、分布式锁 | 分布式协调 |
| **MinIO** | 安装配置、Java SDK、文件上传下载、集群运维 | 对象存储 |
| **Openclaw** | 概述、安装配置、使用指南、技术原理、应用场景、高级特性、最佳实践 | 智能体框架 |

**Java 框架全景图** 覆盖了整个 Java 生态的 17 大类框架（Spring Boot、MyBatis、Spring Cloud、Dubbo、Elasticsearch 等），含版本对应关系和技术选型建议。

**Java 避坑指南** 涵盖 Java 开发、Spring、数据库、微服务、开发规范五个维度的实战避坑经验。

---

## 七、为知笔记迁移（历史笔记库）

这是作者从**为知笔记（WizNote）** 迁移过来的历史笔记，是一个丰富的知识宝库：

### 课程笔记
| 课程 | 笔记篇数 |
|------|---------|
| SkyWalking 31 讲 | 12 篇 |
| DevOps 落地笔记 | 23 篇 |
| ZooKeeper 源码分析 | 3 篇 |
| 云原生微服务架构实战 | 9 篇 |
| 高性能 MySQL 实战 | 11 篇 |
| 高效敏捷测试 49 讲 | 35 篇 |
| 深入浅出 JVM | 5 篇 |
| 数据结构精讲 | 5 篇 |
| 运维高手 36 项修炼 | 25 篇 |

### 项目管理
- 微权力下的项目管理（含仆人式领导、有效管控风险、百万年薪之路、肖杨微电台等系列）
- 项目管理理论文集
- 工作记录与文档模板

### 运维与架构
- JVM 调优系列（8 篇）
- 架构师笔记系列（14 篇）
- 日常运维命令、性能排查
- IT 架构师技术知识图谱

### 个人成长
- 程序员知识体系梳理
- 程序人生四象限
- 一个 IT 工薪族的 4 年奋斗成果
- 投资笔记与股票账户（炒股养家）

### 博客园原创文章
- Java 开发、性能分析、数据结构、网络编程、计算机原理、软件工程、产品分析

### 生活与其他
- 育儿知识（宝宝知道）、结婚风俗、生活规划、投资理财（炒股养家）

---

## 八、文档体系与规范

`技术文档体系/` 目录定义了完整的文档管理规范：

| 文件 | 用途 |
|------|------|
| **DOC_SYSTEM.md** | 文档体系总纲 — 采用 Divio 四象限分类法，定义了文档目录规范、生命周期管理、质量门禁 |
| **WRITING_GUIDE.md** | 写作规范 — 语言风格、Markdown 格式、Mermaid 图表、检查清单 |
| **CONTRIBUTING_DOCS.md** | 文档贡献指南 — 流程、命名规范、常见文档类型写法 |
| **templates/readme-template.md** | README 模板 |
| **templates/api-reference-template.md** | API 参考文档模板 |
| **templates/feature-doc-template.md** | 功能模块文档模板 |

---

## 九、Web 浏览器阅读器

工作区通过 Flask 提供 Markdown 文档的在线浏览功能：

### 后端（app.py）
- 基于 Flask 的轻量级 Web 服务
- 遍历工作区读取所有 `.md` 文件
- 提供 REST API：
  - `GET /api/files` — 获取按目录分类的文件列表
  - `GET /api/file?path=xxx` — 获取指定 Markdown 文件的内容
- 启动：`python app.py`（默认端口 5000）

### 前端（python.html / index.html）
- 基于 **marked.js** 的 Markdown 渲染
- 左侧目录树 + 右侧内容区的经典布局
- 搜索过滤功能
- 面包屑导航

---

## 十、整体数据统计

| 指标 | 数值 |
|------|------|
| 顶级目录数量 | 27 个 |
| Markdown 文档总数 | **861 篇** |
| "手写"系列项目 | **8 个** |
| 中间件/工具学习指南 | **10 个** |
| 代码示例语言 | Python、Java、C++、x86 汇编、Vue、Nginx 配置 |
| 生产问题案例 | **20+ 个**（涵盖 CPU、内存、IO、容器、数据库等） |

---

## 十一、使用建议

### 按角色阅读

| 角色 | 推荐路径 |
|------|---------|
| **初级开发者** | Linux 学习指南 → Redis 学习指南 → "手写"系列入门 |
| **中级开发者** | 17 年技术经验总结 → Java 框架全景图 → 中间件指南 |
| **高级/架构师** | 架构设计篇 → "手写"系列 → 生产环境问题案例 |
| **AI 开发者** | 大模型工具全景图 → AI学习大纲 → ClaudeCode 指南 |
| **项目经理** | 为知笔记迁移/项目管理 → 技术文档体系 |
| **技术写作** | 技术文档体系 → 文档模板 |

### 学习路径示例

**后端工程师成长路径：**
1. 计算机组成原理 → 操作系统（17年经验总结）
2. MySQL + Redis + 消息队列（17年经验总结 + 学习指南）
3. 手写 Web 容器 + 手写数据库（深入理解中间件原理）
4. 架构设计 + 生产环境问题（实战提升）

**AI 工程师成长路径：**
1. AI 学习大纲（建立知识框架）
2. 大模型工具全景图（了解工具链）
3. 手写大模型（深入理解 LLM 原理）
4. AI 常用类库指南 + ClaudeCode 指南（动手实践）

---

## 十二、许可说明

本知识库为个人所有，内容仅供参考学习。文中提及的所有商标和产品名称均为各自所有者的财产。

---

> 📌 **维护说明**：本文档概述了 `p000_0000_all` 工作区的全部内容。如目录结构发生变化，请同步更新本文档与 `wiki.md` 分类索引。
