# NLP常用类库

> 模块：自然语言处理
> 更新时间：2026-03-29

---

## 一、核心概念

### NLP处理流程

```
文本 → 分词 → 清洗 → 向量化 → 模型 → 输出

分词：中文(结巴/Jieba) / 英文(Space/Spacy)
向量化：TF-IDF / Word2Vec / BERT Embedding
模型：RNN / LSTM / Transformer
```

---

## 二、常用类库

### 1. Transformers (Hugging Face)

**特点**：预训练模型最全，支持10000+模型

```bash
pip install transformers torch
```

```python
from transformers import AutoTokenizer, AutoModelForSequenceClassification
import torch

# 加载预训练模型(BERT情感分类)
model_name = 'bert-base-chinese'
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForSequenceClassification.from_pretrained(
    model_name, num_labels=2)

# 文本分类
text = "这个电影太好看了！"
inputs = tokenizer(text, return_tensors='pt', padding=True, truncation=True)

with torch.no_grad():
    outputs = model(**inputs)
    predictions = torch.nn.functional.softmax(outputs.logits, dim=-1)
    print(f"预测: {predictions}")

# 情感分析Pipeline(简化API)
from transformers import pipeline

classifier = pipeline('sentiment-analysis')
result = classifier("这部电影太棒了！")
print(result)  # [{'label': 'POSITIVE', 'score': 0.99}]
```

### 2. Jieba分词

**特点**：中文分词，支持自定义词典

```bash
pip install jieba
```

```python
import jieba

text = "我爱自然语言处理技术"

# 精确模式
words = jieba.cut(text)
print("/".join(words))
# 输出: 我/爱/自然语言/处理/技术

# 全模式(所有可能的词)
words = jieba.cut(text, cut_all=True)
print("/".join(words))
# 输出: 我/爱/自然/语言/自然语言/言/处理/技术

# 搜索引擎模式
words = jieba.cut_for_search(text)
print("/".join(words))
# 输出: 我/爱/自然/语言/自然语言/处理/技术

# 词性标注
import jieba.posseg as pseg
words = pseg.cut(text)
for word, flag in words:
    print(f"{word}: {flag}")
# 输出: 我:r / 爱:v / 自然语言 nz / 处理 v / 技术 n

# 添加自定义词典
jieba.add_word("自然语言处理")

# 关键词提取
import jieba.analyse
keywords = jieba.analyse.extract_tags(text, topK=5, withWeight=True)
print(keywords)
```

### 3. spaCy

**特点**：工业级NLP，支持多语言

```bash
pip install spacy
python -m spacy download zh_core_web_sm
```

```python
import spacy

# 加载中文模型
nlp = spacy.load('zh_core_web_sm')

# 文本处理
doc = nlp("微软公司成立于1975年，总部位于美国雷德蒙德。")

# 分词
print("分词:", [token.text for token in doc])

# 词性标注
print("词性:", [(token.text, token.pos_) for token in doc])

# 命名实体识别
print("实体:", [(ent.text, ent.label_) for ent in doc.ents])
# 输出: [('微软公司', 'ORG'), ('1975年', 'DATE'), ('美国雷德蒙德', 'GPE')]

# 依存分析
for token in doc:
    print(f"{token.text} <- {token.dep_} -> {token.head.text}")

# 句子分割
for sent in doc.sents:
    print("句子:", sent.text)
```

### 4. TextBlob

**特点**：简单易用，适合快速原型

```bash
pip install textblob
```

```python
from textblob import TextBlob

text = "Natural language processing is amazing!"

blob = TextBlob(text)

# 分词
print("单词:", blob.words)

# 词性标注
print("词性:", blob.tags)

# 名词短语
print("名词短语:", blob.noun_phrases)

# 情感分析
print("情感:", blob.sentiment)
# 输出: Sentiment(polarity=0.6, subjectivity=0.9)
# polarity: -1(消极) ~ 1(积极)
# subjectivity: 0(客观) ~ 1(主观)

# 拼写检查
b = TextBlob("I havv goood speling!")
print("修正:", str(b.correct()))

# 翻译
spanish = blob.translate(to='es')
print("西班牙语:", spanish)
```

---

## 三、文本分类完整示例

```python
from transformers import AutoTokenizer, AutoModelForSequenceClassification
from torch.utils.data import DataLoader, Dataset
import torch

# 数据集类
class TextDataset(Dataset):
    def __init__(self, texts, labels, tokenizer, max_len=128):
        self.texts = texts
        self.labels = labels
        self.tokenizer = tokenizer
        self.max_len = max_len
    
    def __len__(self):
        return len(self.texts)
    
    def __getitem__(self, idx):
        encoding = self.tokenizer(
            self.texts[idx],
            max_length=self.max_len,
            padding='max_length',
            truncation=True,
            return_tensors='pt'
        )
        return {
            'input_ids': encoding['input_ids'].squeeze(),
            'attention_mask': encoding['attention_mask'].squeeze(),
            'label': torch.tensor(self.labels[idx])
        }

# 数据
texts = ["这部电影很棒", "服务太差了", "性价比很高", "质量不满意"]
labels = [1, 0, 1, 0]  # 1正面 0负面

# 初始化
tokenizer = AutoTokenizer.from_pretrained('bert-base-chinese')
model = AutoModelForSequenceClassification.from_pretrained(
    'bert-base-chinese', num_labels=2)

dataset = TextDataset(texts, labels, tokenizer)
loader = DataLoader(dataset, batch_size=2)

# 训练
optimizer = torch.optim.AdamW(model.parameters(), lr=2e-5)

for epoch in range(3):
    model.train()
    total_loss = 0
    for batch in loader:
        optimizer.zero_grad()
        outputs = model(
            input_ids=batch['input_ids'],
            attention_mask=batch['attention_mask'],
            labels=batch['label']
        )
        loss = outputs.loss
        loss.backward()
        optimizer.step()
        total_loss += loss.item()
    print(f"Epoch {epoch+1}, Loss: {total_loss/len(loader):.4f}")

# 预测
model.eval()
test_text = "这个产品太棒了"
inputs = tokenizer(test_text, return_tensors='pt', padding=True)
outputs = model(**inputs)
pred = torch.argmax(outputs.logits, dim=1)
print(f"预测: {'正面' if pred.item() == 1 else '负面'}")
```

---

*下一步：语音识别类库*
