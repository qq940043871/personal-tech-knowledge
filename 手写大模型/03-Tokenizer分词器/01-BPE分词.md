# BPE分词

> 模块：Tokenizer分词器
> 更新时间：2026-03-29

---

## 一、BPE算法原理

```
BPE（Byte Pair Encoding）：
  - 最常用的子词分词算法
  - GPT系列、LLaMA均采用
  - 核心思想：从字符开始，迭代合并最高频的相邻对

分词流程：
  1. 初始词表 = 所有单字符 + 特殊token
  2. 统计语料中相邻token对的频率
  3. 合并最高频的token对为新token
  4. 重复步骤2-3，直到词表达到目标大小
```

---

## 二、BPE训练实现

```python
from collections import Counter, defaultdict
from typing import List, Dict, Tuple


class BPETrainer:
    """BPE分词器训练器"""

    def __init__(self, vocab_size: int = 32000):
        self.vocab_size = vocab_size
        self.merges: List[Tuple[str, str]] = []
        self.vocab: Dict[str, int] = {}

    def train(self, corpus: List[str]):
        """训练BPE分词器"""
        # 1. 初始化：将文本拆分为字符序列
        word_freqs = Counter()
        for text in corpus:
            words = text.strip().split()
            for word in words:
                # 每个字符用空格分隔，末尾加</w>标记词边界
                char_seq = " ".join(list(word)) + " </w>"
                word_freqs[char_seq] += 1

        # 2. 统计初始字符，构建基础词表
        base_chars = set()
        for word in word_freqs:
            for char in word.split():
                base_chars.add(char)
        self.vocab = {char: idx for idx, char in enumerate(sorted(base_chars))}

        # 3. 迭代合并
        num_merges = self.vocab_size - len(self.vocab)
        for i in range(num_merges):
            # 统计相邻对频率
            pairs = self._count_pairs(word_freqs)
            if not pairs:
                break

            # 选择最高频的pair
            best_pair = max(pairs, key=pairs.get)
            self.merges.append(best_pair)

            # 合并该pair
            word_freqs = self._merge_pair(best_pair, word_freqs)

            # 添加到词表
            new_token = best_pair[0] + best_pair[1]
            self.vocab[new_token] = len(self.vocab)

    def _count_pairs(self, word_freqs: Counter) -> Dict[Tuple[str, str], int]:
        """统计所有相邻token对的频率"""
        pairs = defaultdict(int)
        for word, freq in word_freqs.items():
            symbols = word.split()
            for i in range(len(symbols) - 1):
                pairs[(symbols[i], symbols[i + 1])] += freq
        return pairs

    def _merge_pair(self, pair: Tuple[str, str],
                    word_freqs: Counter) -> Counter:
        """合并指定的token对"""
        new_freqs = Counter()
        merged = pair[0] + pair[1]

        for word, freq in word_freqs.items():
            symbols = word.split()
            new_symbols = []
            i = 0
            while i < len(symbols):
                if (i < len(symbols) - 1
                        and symbols[i] == pair[0]
                        and symbols[i + 1] == pair[1]):
                    new_symbols.append(merged)
                    i += 2
                else:
                    new_symbols.append(symbols[i])
                    i += 1
            new_freqs[" ".join(new_symbols)] = freq

        return new_freqs
```

---

## 三、BPE分词器使用

```python
class BPETokenizer:
    """BPE分词器"""

    def __init__(self, vocab: Dict[str, int],
                 merges: List[Tuple[str, str]]):
        self.vocab = vocab
        self.merges = merges
        self.inv_vocab = {v: k for k, v in vocab.items()}

    def encode(self, text: str) -> List[int]:
        """将文本编码为token ID序列"""
        tokens = []
        words = text.strip().split()

        for word in words:
            # 拆分为字符
            symbols = list(word) + ["</w>"]

            # 按训练顺序应用合并规则
            for merge in self.merges:
                i = 0
                while i < len(symbols) - 1:
                    if symbols[i] == merge[0] and symbols[i + 1] == merge[1]:
                        symbols[i] = merge[0] + merge[1]
                        del symbols[i + 1]
                    else:
                        i += 1

            # 转换为ID
            for symbol in symbols:
                tokens.append(self.vocab.get(symbol, self.vocab["<unk>"]))

        return tokens

    def decode(self, token_ids: List[int]) -> str:
        """将token ID序列解码为文本"""
        tokens = [self.inv_vocab.get(tid, "<unk>") for tid in token_ids]
        text = "".join(tokens)
        text = text.replace("</w>", " ").strip()
        return text
```

---

*下一步：词表管理*
