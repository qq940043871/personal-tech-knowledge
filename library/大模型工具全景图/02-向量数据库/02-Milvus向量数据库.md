# Milvus向量数据库

> 模块：向量数据库
> 更新时间：2026-03-29

---

## 一、框架介绍

Milvus是Apache软件基金会的顶级项目，是一个开源的分布式向量数据库，专为大规模向量相似性搜索设计。

**官网**：[https://milvus.io](https://milvus.io)
**GitHub**：[https://github.com/milvus-io/milvus](https://github.com/milvus-io/milvus)

**核心特点**：
- 十亿级向量支持
- 分布式架构
- 多种索引类型
- 高性能检索
- 云原生设计

---

## 二、核心概念

```
Milvus核心概念：
  - Collection（集合）：相当于表
  - Partition（分区）：集合的逻辑分区
  - Field（字段）：Collection的列
  - Entity（实体）：Collection的行
  - Shard（分片）：数据分片
  - Segment（段）：数据存储单元
```

---

## 三、实际业务应用场景

### 场景1：Python SDK基础操作

```python
from pymilvus import connections, Collection, FieldSchema, CollectionSchema, Collection, DataType, utility

# 1. 连接
connections.connect(
    alias="default",
    host="localhost",
    port="19530"
)

# 2. 定义Schema
fields = [
    FieldSchema(name="id", dtype=DataType.INT64, is_primary=True),
    FieldSchema(name="embedding", dtype=DataType.FLOAT_VECTOR, dim=768),
    FieldSchema(name="content", dtype=DataType.VARCHAR, max_length=65535),
    FieldSchema(name="category", dtype=DataType.VARCHAR, max_length=100)
]
schema = CollectionSchema(fields=fields, description="文档集合")

# 3. 创建Collection
collection = Collection(name="my_documents", schema=schema)

# 4. 创建索引
index_params = {
    "index_type": "IVF_FLAT",
    "metric_type": "L2",
    "params": {"nlist": 128}
}
collection.create_index(
    field_name="embedding",
    index_params=index_params
)

# 5. 插入数据
import numpy as np

entities = [
    [1, 2, 3],  # id
    np.random.rand(3, 768).tolist(),  # embedding
    ["内容1", "内容2", "内容3"],  # content
    ["科技", "教育", "娱乐"]  # category
]
insert_result = collection.insert(entities)

# 6. 加载到内存
collection.load()

# 7. 搜索
search_params = {"metric_type": "L2", "params": {"nprobe": 10}}

results = collection.search(
    data=[np.random.rand(768).tolist()],  # 查询向量
    anns_field="embedding",
    param=search_params,
    limit=10,
    expr='category == "科技"',  # 过滤条件
    output_fields=["id", "content", "category"]
)

for result in results[0]:
    print(f"ID: {result.id}, Distance: {result.distance}, Content: {result.entity.get('content')}")

# 8. 查询
results = collection.query(
    expr='category == "科技"',
    output_fields=["id", "content", "category"],
    limit=10
)
```

### 场景2：混合搜索

```python
# 搜索时同时返回向量
results = collection.search(
    data=[query_vector],
    anns_field="embedding",
    param=search_params,
    limit=10,
    output_fields=["id", "content", "category"]
)

# 获取原始向量用于重排序
results = collection.search(
    data=[query_vector],
    anns_field="embedding",
    param={"metric_type": "L2", "params": {"nprobe": 100}},  # 检索更多
    limit=50,  # 取更多候选
    output_fields=["embedding", "content"]
)

# 本地重排序（使用更精确的模型）
reranked = rerank_with_cross_encoder(results, query)
```

### 场景3：分区管理

```python
# 创建分区
collection.create_partition("category_科技")
collection.create_partition("category_教育")

# 插入到分区
collection.insert(
    entities,
    partition_name="category_科技"
)

# 分区搜索（更快）
results = collection.search(
    data=[query_vector],
    partition_names=["category_科技"],  # 指定分区
    param=search_params,
    limit=10
)
```

---

## 四、索引类型

| 索引类型 | 适用场景 | 特点 |
|---------|---------|------|
| FLAT | 小规模数据 | 精确检索，100%召回 |
| IVF_FLAT | 中等规模 | 聚类+精确检索 |
| IVF_SQ8 | 大规模数据 | 量化压缩 |
| HNSW | 追求速度 | 图索引，高召回 |
| ANNOY | 追求内存效率 | 树索引 |

```python
# 选择索引
index_params = {
    "index_type": "HNSW",  # 图索引
    "metric_type": "L2",
    "params": {"M": 16, "efConstruction": 200}
}
```

---

## 五、部署方式

### 1. Docker Compose（开发）

```yaml
# docker-compose.yml
version: '3.8'

services:
  etcd:
    image: quay.io/coreos/etcd:v3.5.5
    environment:
      - ETCD_AUTO_COMPACTION_MODE=revision
      - ETCD_AUTO_COMPACTION_RETENTION=1000
    volumes:
      - etcd_data:/etcd
  
  minio:
    image: minio/minio:RELEASE.2023-03-20T20-16-18Z
    environment:
      MINIO_ACCESS_KEY: minioadmin
      MINIO_SECRET_KEY: minioadmin
    volumes:
      - minio_data:/minio_data
  
  milvus:
    image: milvusdb/milvus:v2.3.3
    ports:
      - "19530:19530"
      - "9091:9091"
    environment:
      ETCD_ENDPOINTS: etcd:2379
      MINIO_ADDRESS: minio:9000
    volumes:
      - milvus_data:/var/lib/milvus
    depends_on:
      - etcd
      - minio
```

### 2. Kubernetes生产部署

```yaml
# milvus-cluster.yaml
apiVersion: milvus.io/v1beta1
kind: Milvus
metadata:
  name: my-milvus
spec:
  mode: cluster
  components:
    coord:
      replicas: 1
    data:
      replicas: 2
    index:
      replicas: 2
    query:
      replicas: 2
  config:
    etcd:
      endpoints:
        - etcd:2379
    storage:
      type: minio
```

---

## 六、Attu图形界面

```bash
# 启动Attu
docker run -d -p 8000:3000 -e MILVUS_URL=http://localhost:19530 zilliz/attu:latest
```

然后访问 http://localhost:8000 查看Milvus的Web管理界面。

---

## 七、总结

Milvus是企业级向量数据库的首选，支持大规模数据、高并发、分布式部署。

**学习要点**：
1. 理解Collection和Partition概念
2. 掌握不同索引类型的适用场景
3. 熟练使用Python SDK
4. 理解分区策略
5. 了解分布式架构

**适用场景**：
- 大规模向量检索（亿级）
- 生产级RAG系统
- 推荐系统
- 图像/视频检索

---

*下一步：Embedding模型详解*
