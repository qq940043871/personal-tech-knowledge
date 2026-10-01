# CoT思维链

> 模块：Prompt工程
> 更新时间：2026-03-29

---

## 一、Chain-of-Thought原理

```
CoT（Chain-of-Thought）：
  - 让模型在给出答案前展示推理过程
  - 显著提升复杂推理任务的准确率
  - 2022年Google Brain提出

核心思想：
  传统Prompt：问题 → 答案
  CoT Prompt：问题 → 推理步骤1 → 推理步骤2 → ... → 答案

适用场景：
  - 数学推理
  - 逻辑推理
  - 多步骤问题
  - 常识推理
```

---

## 二、Zero-shot CoT

```python
class ZeroShotCoT:
    """零样本思维链：直接添加"让我们一步步思考"触发推理"""

    def __init__(self, llm):
        self.llm = llm

    async def solve(self, question: str) -> str:
        prompt = f"""{question}

让我们一步步思考："""

        reasoning = await self.llm.generate(prompt)
        return reasoning


# 使用示例
# 问题：一个商店有15个苹果，卖掉了8个，又进了12个，现在有多少？
# 模型输出：
# 让我们一步步思考：
# 1. 商店最初有15个苹果
# 2. 卖掉了8个：15 - 8 = 7个
# 3. 又进了12个：7 + 12 = 19个
# 答案：现在有19个苹果
```

---

## 三、Few-shot CoT

```python
class FewShotCoT:
    """少样本思维链：提供带推理过程的示例"""

    def __init__(self, llm):
        self.llm = llm

    async def solve(self, question: str, examples: list = None) -> str:
        if examples is None:
            examples = self._default_examples()

        # 构建few-shot prompt
        prompt_parts = []
        for ex in examples:
            prompt_parts.append(f"问题：{ex['question']}")
            prompt_parts.append(f"推理过程：{ex['reasoning']}")
            prompt_parts.append(f"答案：{ex['answer']}")
            prompt_parts.append("")

        prompt_parts.append(f"问题：{question}")
        prompt_parts.append("推理过程：")

        prompt = "\n".join(prompt_parts)
        return await self.llm.generate(prompt)

    def _default_examples(self) -> list:
        return [
            {
                "question": "小明有5个苹果，给了小红2个，又买了3个，现在有几个？",
                "reasoning": "小明最初有5个苹果，给了小红2个后剩5-2=3个，又买了3个后有3+3=6个。",
                "answer": "6个",
            },
            {
                "question": "一辆火车每小时60公里，行驶了2.5小时，走了多远？",
                "reasoning": "距离=速度×时间，60×2.5=150公里。",
                "answer": "150公里",
            },
        ]
```

---

## 四、Self-Consistency

```python
from collections import Counter


class SelfConsistencyCoT:
    """自一致性CoT：多次采样取多数票"""

    def __init__(self, llm, n_samples: int = 5):
        self.llm = llm
        self.n_samples = n_samples

    async def solve(self, question: str) -> str:
        # 多次采样推理路径
        answers = []
        for _ in range(self.n_samples):
            prompt = f"""{question}

让我们一步步思考："""
            response = await self.llm.generate(prompt)
            # 提取最终答案
            answer = self._extract_answer(response)
            answers.append(answer)

        # 多数票投票
        vote = Counter(answers)
        best_answer = vote.most_common(1)[0][0]
        return best_answer

    def _extract_answer(self, response: str) -> str:
        """从推理过程中提取最终答案"""
        # 简化实现：取最后一行作为答案
        lines = response.strip().split("\n")
        for line in reversed(lines):
            line = line.strip()
            if line and not line.startswith("推理") and not line.startswith("步骤"):
                return line
        return response.strip().split("\n")[-1]
```

---

*下一步：System-Prompt*
