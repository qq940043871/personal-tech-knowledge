# Chroma向量数据库

> 模块：向量数据库
> 更新时间：2026-03-29

---

## 一、框架介绍

Chroma是一个开源的向量数据库，专门为LLM应用设计，专注于存储和检索嵌入向量。

**官网**：[https://www.trychroma.com](https://www.trychroma.com)
**GitHub**：[https://github.com/chroma-core/chroma](https://github.com/chroma-core/chroma)

**核心特点**：
- 轻量级，易于部署
- 支持元数据过滤
- 与LangChain/LlamaIndex无缝集成
- 支持Python和JavaScript
- 本地存储，无需云服务

---

## 二、核心概念

```
Chroma核心概念：
  - Collection（集合）：类似表
  - Embeddings（嵌入）：向量数据
  - Documents（文档）：原始文本
  - Metadata（元数据）：附加信息
```

---

## 三、实际业务应用场景

### 场景1：快速入门

```python
import chromadb

# 1. 创建客户端
client = chromadb.Client()

# 2. 创建集合
collection = client.create_collection(
    name="my_documents",
    metadata={"hnsw:space": "cosine"}  # 距离度量
)

# 3. 添加数据
collection.add(
    documents=[
        "Python是一种高级编程语言",
        "JavaScript用于Web开发",
        "机器学习是AI的子领域"
    ],
    ids=["doc1", "doc2", "doc3"],
    metadatas=[
        {"source": "python", "category": "编程"},
        {"source": "javascript", "category": "编程"},
        {"source": "ml", "category": "AI"}
    ]
)

# 4. 查询
results = collection.query(
    query_texts=["什么是Python？"],
    n_results=2
)

print(results)

# 5. 查找带过滤
results = collection.query(
    query_texts=["编程语言"],
    where={"category": "编程"}  # 元数据过滤
)
```

### 场景2：持久化存储

```python
import chromadb

# 持久化客户端
client = chromadb.PersistentClient(
    path="./chroma_data"  # 本地存储路径
)

# 创建或获取集合
collection = client.get_or_create_collection("my_docs")

# 后续可以直接加载
# client = chromadb.PersistentClient(path="./chroma_data")
# collection = client.get_collection("my_docs")
```

### 场景3：与LangChain集成

```python
from langchain.document_loaders import TextLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.embeddings import OpenAIEmbeddings
from langchain.vectorstores import Chroma

# 1. 加载文档
loader = TextLoader("document.txt")
documents = loader.load()

# 2. 分块
splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=50)
chunks = splitter.split_documents(documents)

# 3. 存入Chroma
vectorstore = Chroma.from_documents(
    documents=chunks,
    embedding=OpenAIEmbeddings(),
    persist_directory="./chroma_db"  # 持久化
)

# 4. 检索
docs = vectorstore.similarity_search("Python的特点", k=3)

# 5. 保存
vectorstore.persist()
```

### 场景4：元数据过滤

```python
# 创建带元数据的集合
collection.add(
    documents=[
        "产品A的详细描述...",
        "产品B的详细描述...",
        "产品C的详细描述..."
    ],
    ids=["p1", "p2", "p3"],
    metadatas=[
        {"category": "电子产品", "price": 2999, "in_stock": True},
        {"category": "服装", "price": 199, "in_stock": True},
        {"category": "电子产品", "price": 5999, "in_stock": False}
    ]
)

# 过滤查询：找电子产品且有库存
results = collection.query(
    query_texts=["好的产品推荐"],
    where={
        "category": "电子产品",
        "in_stock": True
    }
)

# 价格范围过滤
results = collection.query(
    query_texts=["性价比高的"],
    where={
        "price": {"$gte": 1000, "$lte": 5000}
    }
)
```

---

## 四、高级特性

### 1. 批量操作

```python
# 批量添加
collection.add(
    documents=["doc1", "doc2", "doc3"],
    ids=["id1", "id2", "id3"],
    embeddings=[[0.1, 0.2], [0.3, 0.4], [0.5, 0.6]]  # 可选
)

# 批量更新
collection.update(
    ids=["id1"],
    documents=["更新的内容"]
)

# 批量删除
collection.delete(ids=["id1", "id2"])
```

### 2. 获取和计数

```python
# 获取集合中所有数据
all_data = collection.get()

# 获取指定ID
data = collection.get(ids=["id1", "id2"])

# 统计数量
count = collection.count()

# 列出所有集合
collections = client.list_collections()
```

### 3. 距离度量

```python
# 余弦相似度（默认）
collection = client.create_collection(
    name="cosine_demo",
    metadata={"hnsw:space": "cosine"}
)

# 欧氏距离
collection = client.create_collection(
    name="l2_demo",
    metadata={"hnsw:space": "l2"}
)

# 点积
collection = client.create_collection(
    name="ip_demo",
    metadata={"hnsw:space": "ip"}
)
```

---

## 五、部署方式

### 1. 本地模式（开发）

```python
# 直接使用客户端
client = chromadb.Client()
```

### 2. 服务模式（生产）

```bash
# 启动Chroma服务
pip install chromadb[server]
chroma run --host localhost --port 8000

# 客户端连接
client = chromadb.HttpClient(host="localhost", port=8000)
```

### 3. Docker部署

```yaml
version: '3.8'

services:
  chroma:
    image: chromadb/chroma:latest
    ports:
      - "8000:8000"
    volumes:
      - chroma_data:/chroma/chroma
```

---

## 六、总结

Chroma是入门向量数据库的最佳选择，轻量、简单、功能齐全。

**学习要点**：
1. 理解Collection和Document概念
2. 掌握添加、查询、过滤操作
3. 熟练与LangChain/LlamaIndex集成
4. 了解不同的距离度量方式
5. 理解持久化存储

**适用场景**：
- 个人项目/小规模应用
- 原型验证
- 学习和实验
- 简单RAG系统

**注意**：对于大规模生产环境，建议使用Milvus或Pinecone。

---

*下一步：Milvus分布式向量数据库*
