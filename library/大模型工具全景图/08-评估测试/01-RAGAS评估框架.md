# RAGAS评估框架

> 模块：评估测试
> 更新时间：2026-05-19

---

## 一、RAGAS框架介绍

```
RAGAS（Retrieval Augmented Generation Assessment）：
  - 专注RAG系统质量评估的开源框架
  - 无需人工标注即可评估RAG管道
  - 提供4个核心评估指标

核心指标：
  1. Faithfulness（忠实度）
     - 回答是否基于检索到的上下文
     - 检测幻觉（hallucination）

  2. Answer Relevance（答案相关性）
     - 回答是否与问题相关
     - 评估回答质量

  3. Context Precision（上下文精确度）
     - 检索到的上下文中相关部分的排名
     - 评估检索排序质量

  4. Context Recall（上下文召回率）
     - 是否检索到了回答问题所需的所有信息
     - 评估检索覆盖度
```

---

## 二、安装与快速上手

```python
# 安装
# pip install ragas

from ragas import evaluate
from ragas.metrics import (
    faithfulness,
    answer_relevancy,
    context_precision,
    context_recall,
)
from datasets import Dataset


def quick_evaluate():
    """快速评估示例"""
    # 准备评估数据
    eval_data = {
        "question": ["什么是RAG？"],
        "answer": ["RAG是检索增强生成，通过检索外部知识来增强大模型的回答质量。"],
        "contexts": [["RAG（Retrieval Augmented Generation）是一种结合检索和生成的技术，"
                      "通过从外部知识库检索相关文档，将其作为上下文输入给大模型，"
                      "从而提升回答的准确性和时效性。"]],
        "ground_truth": ["RAG是检索增强生成技术，通过检索外部知识库来增强大模型输出。"],
    }
    dataset = Dataset.from_dict(eval_data)

    # 执行评估
    result = evaluate(
        dataset=dataset,
        metrics=[faithfulness, answer_relevancy,
                 context_precision, context_recall],
    )

    print(result)
    # {'faithfulness': 1.0, 'answer_relevancy': 0.95,
    #  'context_precision': 1.0, 'context_recall': 0.9}
    return result
```

---

## 三、评估指标详解

```python
import numpy as np
from typing import List, Dict


class FaithfulnessEvaluator:
    """忠实度评估：检查回答是否基于上下文"""

    def __init__(self, llm):
        self.llm = llm

    async def evaluate(self, question: str, answer: str,
                       contexts: List[str]) -> float:
        context_text = "\n".join(contexts)

        # 让LLM判断回答中的每个声明是否有上下文支持
        prompt = f"""基于以下上下文，判断回答中的每个声明是否有依据。

上下文：
{context_text}

问题：{question}
回答：{answer}

请列出回答中的每个声明，并判断是否有上下文支持（是/否）。
格式：声明内容 | 支持/不支持"""

        result = await self.llm.generate(prompt)
        # 统计支持的声明比例
        supported = result.count("支持")
        total = result.count("支持") + result.count("不支持")
        return supported / total if total > 0 else 0.0


class AnswerRelevanceEvaluator:
    """答案相关性评估"""

    def __init__(self, llm, embedder):
        self.llm = llm
        self.embedder = embedder

    async def evaluate(self, question: str, answer: str) -> float:
        # 让LLM根据答案反向生成问题
        prompt = f"""根据以下回答，生成3个可能的问题：

回答：{answer}

问题1：
问题2：
问题3："""

        result = await self.llm.generate(prompt)
        generated_questions = [q.strip() for q in result.split("\n")
                               if q.strip().startswith("问题")]

        # 计算生成问题与原始问题的语义相似度
        orig_embedding = self.embedder.encode(question)
        similarities = []
        for gen_q in generated_questions:
            gen_embedding = self.embedder.encode(gen_q)
            sim = np.dot(orig_embedding, gen_embedding) / (
                np.linalg.norm(orig_embedding) * np.linalg.norm(gen_embedding)
            )
            similarities.append(sim)

        return float(np.mean(similarities))
```

---

## 四、与LangSmith Evals对比

```
RAGAS vs LangSmith Evals：
  ┌──────────────┬─────────────────┬─────────────────┐
  │ 维度          │ RAGAS           │ LangSmith Evals  │
  ├──────────────┼─────────────────┼─────────────────┤
  │ 专注领域      │ RAG系统专项评估  │ 通用LLM评估      │
  │ 指标类型      │ 4个RAG专用指标   │ 自定义指标       │
  │ 人工标注      │ 不需要（reference│ 可选            │
  │              │ free）          │                 │
  │ 集成方式      │ Python SDK      │ LangChain深度集成│
  │ 评估速度      │ 中等            │ 快（云端）       │
  │ 可视化        │ 基础            │ 完善的Dashboard  │
  │ 适用场景      │ RAG管道质量监控  │ 全链路LLM监控    │
  └──────────────┴─────────────────┴─────────────────┘

推荐：
  - 纯RAG系统评估 → RAGAS
  - LangChain生态 + 需要全面监控 → LangSmith
  - 两者结合使用效果最佳
```

---

*下一步：RAG系统实战*
