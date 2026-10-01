# LangChain

> 模块：应用开发框架
> 更新时间：2026-03-29

---

## 一、框架介绍

LangChain是一个用于构建基于大语言模型应用的开发框架，由Harrison Chase创建于2022年。它提供了一套抽象和工具，帮助开发者快速构建LLM应用。

**官网**：[https://python.langchain.com](https://python.langchain.com)
**GitHub**：[https://github.com/langchain-ai/langchain](https://github.com/langchain-ai/langchain)

**核心价值**：
- 简化LLM应用开发
- 组件化和模块化设计
- 丰富的集成生态
- 支持多种LLM和工具

---

## 二、核心概念

### 1. Model I/O - 模型交互

```python
from langchain.chat_models import ChatOpenAI
from langchain.schema import HumanMessage, SystemMessage

# 初始化模型
llm = ChatOpenAI(
    model="gpt-4",
    temperature=0.7,
    openai_api_key="your-api-key"
)

# 简单对话
response = llm.invoke("用Python写一个快速排序")
print(response.content)

# 带系统提示的对话
chat = llm.invoke([
    SystemMessage(content="你是一个Python编程助手"),
    HumanMessage(content="解释一下闭包")
])
print(chat.content)
```

### 2. Prompt Template - 提示模板

```python
from langchain.prompts import ChatPromptTemplate

# 创建提示模板
template = ChatPromptTemplate.from_messages([
    ("system", "你是一个{language}编程专家"),
    ("human", "教我如何实现{feature}功能")
])

# 使用模板
prompt = template.invoke({
    "language": "Python",
    "feature": "装饰器"
})

response = llm.invoke(prompt)
print(response.content)

# 带示例的提示
from langchain.prompts import FewShotChatMessagePromptTemplate

examples = [
    {"input": "你好", "output": "你好！有什么可以帮助你的吗？"},
    {"input": "你是谁", "output": "我是一个AI助手。"}
]

example_prompt = ChatPromptTemplate.from_messages([
    ("human", "{input}"),
    ("ai", "{output}")
])

few_shot_prompt = FewShotChatMessagePromptTemplate(
    examples=examples,
    example_prompt=example_prompt
)
```

### 3. Chain - 链式调用

```python
from langchain.chains import LLMChain

# 创建链
chain = LLMChain(
    llm=llm,
    prompt=template
)

# 执行链
result = chain.invoke({
    "language": "Java",
    "feature": "单例模式"
})

print(result["text"])
```

---

## 三、实际业务应用场景

### 场景1：RAG问答系统

```python
from langchain.document_loaders import TextLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.embeddings import OpenAIEmbeddings
from langchain.vectorstores import Chroma
from langchain.chains import RetrievalQA

# 1. 加载文档
loader = TextLoader("document.txt")
documents = loader.load()

# 2. 文档分块
text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,
    chunk_overlap=200
)
chunks = text_splitter.split_documents(documents)

# 3. 创建向量存储
embeddings = OpenAIEmbeddings()
vectorstore = Chroma.from_documents(chunks, embeddings)

# 4. 创建检索QA链
qa_chain = RetrievalQA.from_chain_type(
    llm=llm,
    chain_type="stuff",
    retriever=vectorstore.as_retriever()
)

# 5. 问答
question = "这篇文章的主要内容是什么？"
result = qa_chain.invoke({"query": question})
print(result["result"])
```

### 场景2：多步骤Agent

```python
from langchain.agents import AgentExecutor, create_openai_functions_agent
from langchain.tools import Tool
from langchain import hub

# 定义工具
def search_wikipedia(query: str) -> str:
    """搜索维基百科"""
    # 实际项目中调用Wikipedia API
    return f"关于{query}的信息..."

tools = [
    Tool(
        name="Wikipedia",
        func=search_wikipedia,
        description="搜索维基百科获取信息"
    )
]

# 从Hub加载提示
prompt = hub.pull("hwchase17/openai-functions-agent")

# 创建Agent
agent = create_openai_functions_agent(llm, tools, prompt)

# 创建Agent执行器
agent_executor = AgentExecutor(
    agent=agent,
    tools=tools,
    verbose=True
)

# 执行
result = agent_executor.invoke({
    "input": "介绍一下Python语言的历史"
})
```

### 场景3：对话式Memory

```python
from langchain.memory import ConversationBufferMemory
from langchain.chains import ConversationChain

# 创建内存
memory = ConversationBufferMemory()

# 创建对话链
conversation = ConversationChain(
    llm=llm,
    memory=memory,
    verbose=True
)

# 对话
conversation.invoke("我叫张三")
conversation.invoke("我叫什么名字？")
# Agent会记住之前的对话

# 保存对话历史
history = memory.load_memory_variables({})
```

### 场景4：输出解析器

```python
from langchain.output_parsers import PydanticOutputParser
from pydantic import BaseModel, Field
from typing import List

# 定义输出格式
class Movie(BaseModel):
    title: str = Field(description="电影名称")
    year: int = Field(description="上映年份")
    rating: float = Field(description="评分")

class MovieList(BaseModel):
    movies: List[Movie] = Field(description="电影列表")

# 创建解析器
parser = PydanticOutputParser(pydantic_object=MovieList)

# 创建提示
prompt = PromptTemplate(
    template="列出三部经典科幻电影及其信息。\n{format_instructions}",
    input_variables=[],
    partial_variables={"format_instructions": parser.get_format_instructions()}
)

# 执行
chain = LLMChain(llm=llm, prompt=prompt)
result = chain.invoke({})

# 解析输出
parsed = parser.invoke(result["text"])
print(parsed.movies)
```

---

## 四、LangChain生态

### LangChain表达式语言（LCEL）

```python
from langchain.schema import StrOutputParser
from langchain.runnable import RunnablePassthrough

# 使用LCEL构建链
chain = (
    {"context": retrieval_chain, "question": RunnablePassthrough()}
    | prompt
    | llm
    | StrOutputParser()
)

# 流式输出
for chunk in chain.stream({"question": "什么是机器学习"}):
    print(chunk, end="", flush=True)
```

### LangSmith - 监控和调试

```python
# 设置LangSmith
import os
os.environ["LANGCHAIN_TRACING_V2"] = "true"
os.environ["LANGCHAIN_API_KEY"] = "your-api-key"
os.environ["LANGCHAIN_PROJECT"] = "my-project"

# 所有链调用都会自动追踪
# 可以在LangSmith平台上查看调用历史、成本、延迟等
```

---

## 五、总结

LangChain是大模型应用开发的首选框架，掌握它能快速构建各种LLM应用。

**学习要点**：
1. 理解Model I/O和Prompt Template
2. 掌握Chain的构建方式
3. 熟练使用LCEL表达式语言
4. 理解Agent和Tool的使用
5. 了解Memory和Callback机制

---

*下一步：LlamaIndex专注RAG*
