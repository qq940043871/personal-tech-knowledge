# Ollama本地推理

> 模块：部署推理
> 更新时间：2026-03-29

---

## 一、框架介绍

Ollama是本地运行大语言模型的工具，让你无需云服务即可在本地运行各种开源模型。

**官网**：[https://ollama.ai](https://ollama.ai)
**GitHub**：[https://github.com/ollama/ollama](https://github.com/ollama/ollama)

**核心特点**：
- 一键运行模型
- 支持多种开源模型
- 跨平台支持
- 简洁API
- 资源高效利用

---

## 二、快速开始

### 1. 安装

```bash
# macOS/Linux
curl -fsSL https://ollama.ai/install.sh | sh

# Windows（通过WSL或Docker）
docker pull ollama/ollama

# 验证安装
ollama --version
```

### 2. 运行模型

```bash
# 拉取并运行模型
ollama run llama3

# 其他可用模型
ollama run mistral        # 7B模型
ollama run mixtral        # 8x7B MoE
ollama run codellama      # 代码模型
ollama run phi            # 微软小模型
ollama run gemma          # Google模型
ollama run qwen           # 阿里模型
ollama run deepseek-llm   # 深度求索模型

# 指定参数
ollama run llama3:latest "解释什么是机器学习" --verbose
```

### 3. API使用

```python
import ollama

# 简单对话
response = ollama.chat(
    model='llama3',
    messages=[
        {'role': 'user', 'content': '用Python写一个快排'}
    ]
)
print(response['message']['content'])

# 流式输出
stream = ollama.chat(
    model='llama3',
    messages=[{'role': 'user', 'content': '写一首诗'}],
    stream=True
)
for chunk in stream:
    print(chunk['message']['content'], end='', flush=True)
```

---

## 三、实际业务应用场景

### 场景1：本地RAG系统

```python
import ollama
from langchain_community.embeddings import OllamaEmbeddings
from langchain_community.llms import Ollama
from langchain.chains import RetrievalQA

# 使用Ollama模型
llm = Ollama(model="llama3")

# 使用Ollama Embedding
embeddings = OllamaEmbeddings(model="nomic-embed-text")

# 创建向量存储
from langchain_community.vectorstores import Chroma

vectorstore = Chroma(
    embedding_function=embeddings,
    persist_directory="./chroma_db"
)

# RAG问答
qa = RetrievalQA.from_chain_type(
    llm=llm,
    chain_type="stuff",
    retriever=vectorstore.as_retriever()
)

result = qa.invoke("什么是Python？")
print(result["result"])
```

### 场景2：中文模型使用

```bash
# 拉取中文模型
ollama pull qwen:7b
ollama pull deepseek-coder:6.7b
ollama pull yi:6b

# 运行中文模型
ollama run qwen:7b "写一段关于春天的散文"
```

### 场景3：自定义模型

```bash
# 导入GGUF格式模型
ollama create my-model -f ./Modelfile

# Modelfile示例
FROM ./llama3-8b.Q4_K_M.gguf
PARAMETER temperature 0.7
PARAMETER top_p 0