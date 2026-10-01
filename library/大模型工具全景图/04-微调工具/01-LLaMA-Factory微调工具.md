# LLaMA-Factory微调工具

> 模块：微调工具
> 更新时间：2026-03-29

---

## 一、框架介绍

LLaMA-Factory是一个一站式大模型微调平台，支持多种模型的LoRA、QLoRA等高效微调方法。

**官网**：[https://github.com/hiyouga/LLaMA-Factory](https://github.com/hiyouga/LLaMA-Factory)
**GitHub**：[https://github.com/hiyouga/LLaMA-Factory](https://github.com/hiyouga/LLaMA-Factory)

**核心特点**：
- 支持多种模型（Llama、LLaMA、Qwen、Bloom等）
- 支持多种微调方法（LoRA、QLoRA、Full-tuning）
- Web界面操作
- 命令行工具
- 预置训练模板

---

## 二、快速开始

### 1. 安装

```bash
git clone https://github.com/hiyouga/LLaMA-Factory.git
cd LLaMA-Factory
pip install -e .
```

### 2. 准备数据

```json
// data/training_data.json
{
  "instruction": "将以下中文翻译成英文",
  "input": "今天天气真好",
  "output": "The weather is nice today."
}

// 数据格式2：对话格式
{
  "conversations": [
    {"from": "human", "value": "什么是Python？"},
    {"from": "gpt", "value": "Python是一种高级编程语言..."}
  ]
}
```

### 3. Web界面微调

```bash
# 启动Web界面
llamafactory-cli webchat

# 访问 http://localhost:7860
# 选择模型、配置参数、开始训练
```

### 4. 命令行微调

```bash
llamafactory-cli train \
    --stage sft \
    --model_name_or_path meta-llama/Llama-3-8b-Instruct \
    --dataset alpaca_gpt4_zh \
    --template llama3 \
    --finetuning_type lora \
    --lora_target q_proj,v_proj \
    --output_dir ./output/llama3_lora \
    --per_device_train_batch_size 4 \
    --gradient_accumulation_steps 4 \
    --lr_scheduler_type cosine \
    --learning_rate 5e-5 \
    --num_train_epochs 3 \
    --fp16
```

---

## 三、微调方法详解

### 1. LoRA微调

```yaml
# lora_config.yaml
finetuning_type: lora
lora_alpha: 16
lora_dropout: 0.05
lora_target: all  # 或指定层: [q_proj, k_proj, v_proj, o_proj]
```

### 2. QLoRA微调（量化+LoRA）

```bash
# QLoRA适合显存有限的场景
llamafactory-cli train \
    --stage sft \
    --model_name_or_path meta-llama/Llama-3-8b-Instruct \
    --dataset alpaca_gpt4_zh \
    --template llama3 \
    --finetuning_type lora \
    --quantization_bit 4 \
    --q_lora \
    --output_dir ./output/llama3_qlora
```

### 3. 全参数微调

```bash
# 全参数微调需要更多显存
llamafactory-cli train \
    --stage sft \
    --model_name_or_path meta-llama/Llama-3-8b-Instruct \
    --dataset alpaca_gpt4_zh \
    --template llama3 \
    --finetuning_type full \
    --output_dir ./output/llama3_full \
    --per_device_train_batch_size 1 \
    --gradient_accumulation_steps 16
```

---

## 四、训练数据配置

```json
// dataset_info.json
{
  "my_dataset": {
    "file_name": "my_data.json",
    "formatting": "sharegpt",
    "columns": {
      "messages": "conversations",
      "system": "system",
      "tools": "tools"
    }
  }
}
```

```bash
# 使用自定义数据集
llamafactory-cli train \
    --dataset my_dataset \
    --dataset_dir ./data
```

---

## 五、模型推理

```bash
# 导出LoRA权重
llamafactory-cli export \
    --model_name_or_path meta-llama/Llama-3-8b-Instruct \
    --adapter_name_or_path ./output/llama3_lora \
    --template llama3 \
    --finetuning_type lora

# Web聊天
llamafactory-cli webchat \
    --model_name_or_path meta-llama/Llama-3-8b-Instruct \
    --adapter_name_or_path ./output/llama3_lora

# 命令行推理
llamafactory-cli inference \
    --model_name_or_path meta-llama/Llama-3-8b-Instruct \
    --adapter_name_or_path ./output/llama3_lora \
    --template llama3 \
    --fuseright: 写一首关于春天的诗
```

---

## 六、常见问题

### 显存不足？

```bash
# 使用QLoRA
--quantization_bit 4 --q_lora

# 减小batch_size
--per_device_train_batch_size 2

# 使用更小的模型
--model_name_or_path meta-llama/Llama-3-8b-Instruct
```

### 训练效果不好？

```bash
# 调整学习率
--learning_rate 1e-4  # 通常1e-4到1e-5

# 增加训练轮数
--num_train_epochs 5

# 调整LoRA alpha
--lora_alpha 32
```

---

## 七、总结

LLaMA-Factory是中文开源社区最活跃的微调工具，Web界面友好，适合快速实验。

**学习要点**：
1. 理解LoRA和QLoRA原理
2. 掌握数据准备格式
3. 熟练使用Web界面
4. 理解训练参数调优
5. 掌握模型导出和推理

---

*下一步：LangSmith评估平台*
