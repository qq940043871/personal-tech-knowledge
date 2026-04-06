# OpenAI Embeddings

> 模块：Embedding模型
> 更新时间：2026-03-29

---

## 一、模型介绍

OpenAI Embeddings是将文本转换为向量表示的模型服务，用于文本相似度计算、语义搜索等场景。

**官网**：[https://platform.openai.com/docs/guides/embeddings](https://platform.openai.com/docs/guides/embeddings)

**可用模型**：
- `text-embedding-3-large`：最新最强，3072维
- `text-embedding-3-small`：新性价比模型，1536维
- `text-embedding-ada-002`：经典模型，1536维

---

## 二、实际业务应用场景

### 场景1：基础使用

```python
from openai import OpenAI

client = OpenAI(api_key="your-api-key")

# 获取文本嵌入
response = client.embeddings.create(
    model="text-embedding-3-small",
    input="Python是一种高级编程语言"
)

embedding = response.data[0].embedding
print(f"向量维度: {len(embedding)}")
print(f"前5个值: {embedding[:5]}")
```

### 场景2：批量嵌入

```python
# 批量处理
texts = [
    "Python编程基础",
    "Java Web开发",
    "机器学习入门",
    "深度学习实战",
    "数据结构与算法"
]

response = client.embeddings.create(
    model="text-embedding-3-small",
    input=texts  # 最多支持2048个
)

embeddings = [item.embedding for item in response.data]
print(f"生成 {len(embeddings)} 个向量")
```

### 场景3：语义搜索

```python
import numpy as np

# 文档
documents = [
    "Python适合快速原型开发",
    "Java是企业级开发的首选",
    "机器学习用于数据分析",
    "深度学习是AI的核心技术",
    "算法是编程的基础"
]

# 获取文档向量
doc_response = client.embeddings.create(
    model="text-embedding-3-small",
    input=documents
)
doc_embeddings = [item.embedding for item in doc_response.data]

# 查询
query = "AI和机器学习有什么关系？"
query_response = client.embeddings.create(
    model="text-embedding-3-small",
    input=query
)
query_embedding = query_response.data[0].embedding

# 计算相似度
def cosine_similarity(a, b):
    return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))

results = []
for i, doc_emb in enumerate(doc_embeddings):
    similarity = cosine_similarity(query_embedding, doc_emb)
    results.append((i, documents[i], similarity))

# 排序
results.sort(key=lambda x: x[2], reverse=True)

print("搜索结果：")
for i, doc, score in results:
    print(f"  {score:.4f} - {doc}")
```

### 场景4：文档分类

```python
# 定义类别向量
categories = {
    "编程开发": ["Python", "Java", "C++", "编程", "代码", "开发"],
    "人工智能": ["AI", "机器学习", "深度学习", "神经网络", "模型"],
    "数据分析": ["数据", "分析", "统计", "可视化", "图表"]
}

# 获取类别中心向量
category_embeddings = {}
for category, keywords in categories.items():
    response = client.embeddings.create(
        model="text-embedding-3-small",
        input=" ".join(keywords)
    )
    category_embeddings[category] = response.data[0].embedding

# 分类新文档
def classify(text):
    response = client.embeddings.create(
        model="text-embedding-3-small",
        input=text
    )
    text_emb = response.data[0].embedding
    
    # 计算与各类别的相似度
    scores = {}
    for category, cat_emb in category_embeddings.items():
        scores[category] = cosine_similarity(text_emb, cat_emb)
    
    # 返回最高分类
    return max(scores, key=scores.get)

# 测试
text = "使用神经网络进行图像识别"
print(classify(text))  # 输出: 人工智能
```

---

## 三、维度缩减

```python
# text-embedding-3支持维度缩减
response = client.embeddings.create(
    model="text-embedding-3-small",
    input="文本内容",
    dimensions=256  # 缩减到256维
)
```

---

## 四、总结

OpenAI Embeddings是最方便使用的Embedding服务，适合快速原型和小型应用。

**适用场景**：
- 快速原型开发
- 小规模向量检索
- 语义相似度计算
- 文档分类

**注意**：
- 需要API Key和网络访问
- 有使用成本
- 国内访问可能不稳定

---

*下一步：中文Embedding模型BGE*
