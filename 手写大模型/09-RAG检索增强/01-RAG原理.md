# RAG原理

> 模块：RAG检索增强
> 更新时间：2026-03-29

---

## 一、RAG架构

```
RAG（Retrieval-Augmented Generation）：
  1. 检索：从知识库检索相关内容
  2. 增强：将检索结果加入Prompt
  3. 生成：LLM基于增强的上下文生成

优势：
  - 知识可更新
  - 减少幻觉
  - 可追溯可解释
```

---

## 二、实现

```python
class RAGPipeline:
    """RAG流水线"""
    
    def __init__(self, embedder: Embedder, 
                 vector_store: VectorStore,
                 llm: LLM):
        self.embedder = embedder
        self.vector_store = vector_store
        self.llm = llm
    
    async def query(self, question: str, top_k: int = 5) -> str:
        # 1. 嵌入问题
        query_embedding = await self.embedder.embed(question)
        
        # 2. 检索相关文档
        docs = await self.vector_store.search(query_embedding, top_k)
        
        # 3. 构建上下文
        context = "\n\n".join([doc.content for doc in docs])
        
        # 4. 构建提示词
        prompt = f"""基于以下上下文回答问题。如果上下文中没有相关信息，请说明。

上下文：
{context}

问题：{question}

回答："""
        
        # 5. 生成回答
        response = await self.llm.generate(prompt)
        return response
```

---

*下一步：文档切分*
