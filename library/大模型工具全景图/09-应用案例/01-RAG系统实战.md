# RAG系统实战

> 模块：应用案例
> 更新时间：2026-03-29

---

## 一、RAG系统简介

RAG（Retrieval-Augmented Generation，检索增强生成）是一种结合知识检索和LLM生成的架构，让模型能够基于外部知识回答问题。

**核心价值**：
- 解决模型知识过时问题
- 减少幻觉
- 支持实时知识
- 可追溯可解释

---

## 二、系统架构

```
RAG系统流程：
┌─────────────┐
│   用户问题   │
└──────┬──────┘
       ▼
┌─────────────┐
│  问题改写    │  ← Query Rewrite
└──────┬──────┘
       ▼
┌─────────────┐
│  向量检索    │  ← Retrieval
│  (Embedding) │
└──────┬──────┘
       ▼
┌─────────────┐
│  重排序     │  ← Rerank
└──────┬──────┘
       ▼
┌─────────────┐
│  上下文构建  │  ← Context Building
└──────┬──────┘
       ▼
┌─────────────┐
│  LLM生成   │  ← Generation
└──────┬──────┘
       ▼
┌─────────────┐
│   最终答案   │
└─────────────┘
```

---

## 三、实际业务应用场景

### 场景1：基础RAG实现

```python
from langchain.document_loaders import TextLoader, PDFLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.embeddings import OpenAIEmbeddings
from langchain.vectorstores import Chroma
from langchain.chat_models import ChatOpenAI
from langchain.chains import RetrievalQA

# 1. 加载文档
loader = PDFLoader("document.pdf")
documents = loader.load()

# 2. 文档分块
text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,
    chunk_overlap=200,
    separators=["\n\n", "\n", "。", "！", "？"]
)
chunks = text_splitter.split_documents(documents)

# 3. 创建向量存储
embeddings = OpenAIEmbeddings()
vectorstore = Chroma.from_documents(
    documents=chunks,
    embedding=embeddings,
    persist_directory="./vector_db"
)

# 4. 创建检索器
retriever = vectorstore.as_retriever(
    search_type="similarity",
    search_kwargs={"k": 5}
)

# 5. 创建LLM
llm = ChatOpenAI(model="gpt-4", temperature=0)

# 6. 创建QA链
qa_chain = RetrievalQA.from_chain_type(
    llm=llm,
    chain_type="stuff",
    retriever=retriever,
    return_source_documents=True
)

# 7. 问答
result = qa_chain({"query": "文档的主要内容是什么？"})
print(result["result"])
```

### 场景2：高级RAG - 查询改写

```python
from langchain.chat_models import ChatOpenAI
from langchain.prompts import ChatPromptTemplate

# 查询改写
rewrite_prompt = ChatPromptTemplate.from_messages([
    ("system", "你是一个查询改写专家。将用户问题改写成更适合检索的形式。"),
    ("human", "原问题：{question}\n\n改写后的问题：")
])

rewrite_llm = ChatOpenAI(model="gpt-3.5-turbo", temperature=0.3)
rewrite_chain = rewrite_prompt | rewrite_llm

# 改写问题
rewritten = rewrite_chain.invoke({"question": "Python能干啥"})
print(rewritten)

# 使用改写后的问题检索
docs = vectorstore.similarity_search(rewritten, k=5)
```

### 场景3：多向量检索

```python
# 父文档检索器 - 平衡精确度和上下文
from langchain.retrievers import ParentDocumentRetriever

# 大块文档（用于最终上下文）
parent_splitter = RecursiveCharacterTextSplitter(chunk_size=2000)

# 小块文档（用于检索）
child_splitter = RecursiveCharacterTextSplitter(chunk_size=500)

# 父文档检索器
retriever = ParentDocumentRetriever(
    vectorstore=vectorstore,
    docstore=SimpleDocumentStore(),
    child_splitter=child_splitter,
    parent_splitter=parent_splitter,
    search_kwargs={"k": 5}
)

# 检索时会返回包含小块的大块文档
docs = retriever.get_relevant_documents("关于Python的问题")
```

### 场景4：重排序

```python
from sentence_transformers import CrossEncoder

# 交叉编码器重排序
reranker = CrossEncoder('cross-encoder/msmarco-MiniLM-L-6-v2')

def rerank_documents(query, documents, top_k=3):
    # 创建query-document对
    pairs = [(query, doc.page_content) for doc in documents]
    
    # 交叉编码器打分
    scores = reranker.predict(pairs)
    
    # 按分数排序
    scored_docs = list(zip(documents, scores))
    scored_docs.sort(key=lambda x: x[1], reverse=True)
    
    return [doc for doc, _ in scored_docs[:top_k]]

# 使用重排序
initial_docs = vectorstore.similarity_search(query, k=20)
final_docs = rerank_documents(query, initial_docs, top_k=5)
```

### 场景5：混合搜索

```python
# BM25 + 向量搜索融合
from langchain.retrievers import BM25Retriever

# BM25检索器
bm25_retriever = BM25Retriever.from_documents(chunks)

# 向量检索器
vector_retriever = vectorstore.as_retriever(search_kwargs={"k": 10})

# 融合检索
from langchain.retrievers import EnsembleRetriever

ensemble_retriever = EnsembleRetriever(
    retrievers=[bm25_retriever, vector_retriever],
    weights=[0.3, 0.7]  # BM25权重0.3，向量权重0.7
)

# 使用
docs = ensemble_retriever.get_relevant_documents(query)
```

---

## 四、生产级RAG架构

```python
class ProductionRAG:
    def __init__(self):
        # 文档处理
        self.loader = PDFLoader
        self.splitter = RecursiveCharacterTextSplitter
        
        # Embedding
        self.embedding = OpenAIEmbeddings
        
        # 向量存储
        self.vectorstore = Milvus
        
        # LLM
        self.llm = ChatOpenAI(model="gpt-4")
        
        # 后处理器
        self.postprocessor = SimilarityPostprocessor
    
    def retrieve(self, query):
        # 1. 查询改写
        rewritten_query = self.rewrite_query(query)
        
        # 2. 向量检索
        docs = self.vectorstore.similarity_search(rewritten_query)
        
        # 3. 重排序
        reranked = self.rerank(query, docs)
        
        # 4. 后处理
        filtered = self.postprocessor.process(reranked)
        
        return filtered
    
    def generate(self, query, context):
        # 构建提示
        prompt = self.build_prompt(query, context)
        
        # 生成
        response = self.llm.invoke(prompt)
        
        return response
    
    def run(self, query):
        # 检索
        context = self.retrieve(query)
        
        # 生成
        response = self.generate(query, context)
        
        return {
            "answer": response,
            "sources": [doc.metadata for doc in context]
        }
```

---

## 五、RAG评估指标

```python
from ragas import evaluate
from ragas.metrics import (
    faithfulness,
    answer_relevancy,
    context_precision,
    context_recall
)

# 评估RAG系统
result = evaluate(
    dataset=eval_dataset,
    metrics=[
        faithfulness,
        answer_relevancy,
        context_precision,
        context_recall
    ]
)

print(result)
```

---

## 六、总结

RAG是大模型应用的核心架构，生产级RAG需要考虑查询改写、重排序、混合搜索等多个环节。

**学习要点**：
1. 理解RAG核心流程
2. 掌握文档分块策略
3. 熟练使用向量检索
4. 了解重排序技术
5. 掌握评估方法

---

*文档完成！*
