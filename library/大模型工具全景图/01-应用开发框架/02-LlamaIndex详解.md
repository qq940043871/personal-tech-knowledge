# LlamaIndex

> 模块：应用开发框架
> 更新时间：2026-03-29

---

## 一、框架介绍

LlamaIndex（formerly GPT Index）是专门为构建RAG（检索增强生成）系统而设计的框架，专注于知识检索和问答。

**官网**：[https://www.llamaindex.ai](https://www.llamaindex.ai)
**GitHub**：[https://github.com/run-llama/llama_index](https://github.com/run-llama/llama_index)

**核心特点**：
- 专注RAG场景
- 多种索引类型
- 更好的检索性能
- 简洁的API设计

---

## 二、核心概念

### 1. Document和Node

```python
from llama_index.core import Document, SimpleDirectoryReader

# 创建文档
doc = Document(
    text="这是一段关于Python的文本...",
    metadata={"source": "python_guide.txt", "chapter": 1}
)

# 从目录加载文档
reader = SimpleDirectoryReader("./data")
documents = reader.load_data()
```

### 2. Index - 索引

```python
from llama_index.core import VectorStoreIndex, SummaryIndex
from llama_index.core import Settings

# 配置
Settings.llm = OpenAI(model="gpt-4")
Settings.embed_model = OpenAIEmbeddings()

# 创建向量索引
index = VectorStoreIndex.from_documents(documents)

# 创建摘要索引
summary_index = SummaryIndex.from_documents(documents)
```

### 3. Query Engine - 查询引擎

```python
# 创建查询引擎
query_engine = index.as_query_engine(
    similarity_top_k=3,
    response_mode="compact"
)

# 查询
response = query_engine.query("Python有什么特点？")
print(response.response)

# 流式查询
response = query_engine.query("介绍一下Python")
for chunk in response.response_gen:
    print(chunk, end="", flush=True)
```

---

## 三、实际业务应用场景

### 场景1：PDF文档问答

```python
from llama_index.core import VectorStoreIndex
from llama_index.readers.file import PDFReader
from llama_index.core import SummaryIndex

# 1. 加载PDF
loader = PDFReader()
documents = loader.load_data(file="document.pdf")

# 2. 创建索引
index = VectorStoreIndex.from_documents(documents)

# 3. 创建查询引擎
query_engine = index.as_query_engine(
    similarity_top_k=5,
    response_mode="tree_summarize"
)

# 4. 问答
question = "这份文档的核心观点是什么？"
result = query_engine.query(question)
print(result)
```

### 场景2：多文档对比问答

```python
from llama_index.core import VectorStoreIndex, SummaryIndex
from llama_index.core.tools import QueryEngineTool

# 为每个文档创建索引
doc1_index = VectorStoreIndex.from_documents(doc1)
doc2_index = VectorStoreIndex.from_documents(doc2)

# 创建查询工具
tool1 = QueryEngineTool.from_defaults(
    query_engine=doc1_index.as_query_engine(),
    description="关于技术报告的信息"
)
tool2 = QueryEngineTool.from_defaults(
    query_engine=doc2_index.as_query_engine(),
    description="关于产品文档的信息"
)

# 使用Router选择工具
from llama_index.core.selectors import LLMSingleSelector

router = LLMSingleSelector.from_defaults()
query_engine = router.select(
    [tool1, tool2]
)
```

### 场景3：混合搜索

```python
from llama_index.core.retrievers import VectorIndexRetriever
from llama_index.core.retrievers import KeywordTableRetriever

# 向量检索器
vector_retriever = VectorIndexRetriever(
    index=index,
    similarity_top_k=5
)

# 关键词检索器
keyword_retriever = KeywordTableRetriever(index=index)

# 混合检索器
from llama_index.core.retrievers import QueryFusionRetriever

fusion_retriever = QueryFusionRetriever(
    retrievers=[vector_retriever, keyword_retriever],
    mode="reciprocal_rank"  # 或 "dist_based"
)

# 使用
nodes = fusion_retriever.retrieve("Python教程推荐")
```

### 场景4：自定义后处理

```python
from llama_index.core.postprocessor import SimilarityPostprocessor, KeywordNodePostprocessor

# 创建带后处理的查询引擎
query_engine = index.as_query_engine(
    similarity_top_k=10,  # 检索更多
    node_postprocessors=[
        SimilarityPostprocessor(similarity_cutoff=0.7),
        KeywordNodePostprocessor(
            exclude_keywords=["敏感词"],
            required_keywords=["Python"]
        )
    ]
)
```

---

## 四、与LangChain对比

| 特性 | LangChain | LlamaIndex |
|------|-----------|------------|
| 定位 | 通用LLM应用框架 | 专注RAG |
| API设计 | 更灵活 | 更简洁 |
| 文档质量 | 较复杂 | 清晰易懂 |
| 社区活跃度 | 更活跃 | 活跃 |
| 学习曲线 | 较陡 | 较平缓 |

**建议**：
- 简单RAG场景：用LlamaIndex
- 复杂Agent场景：用LangChain
- 可以两者结合使用

---

## 五、总结

LlamaIndex是构建RAG系统的最佳选择，学习曲线平缓，文档质量好。

**学习要点**：
1. 理解Document和Node的概念
2. 掌握各种Index类型
3. 熟练使用QueryEngine
4. 了解后处理器和检索器
5. 理解Router和Selector机制

---

*下一步：向量数据库Chroma*
