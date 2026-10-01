# GPU推理

> 模块：部署优化
> 更新时间：2026-03-29

---

## 一、CUDA加速

```python
import torch

class GPUInference:
    """GPU推理"""
    
    def __init__(self, model_path: str):
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        self.model = self._load_model(model_path)
        self.model.to(self.device)
    
    def generate(self, input_ids, **kwargs):
        with torch.no_grad():
            input_ids = input_ids.to(self.device)
            return self.model.generate(input_ids, **kwargs)
```

---

## 二、vLLM

```python
from vllm import LLM, SamplingParams

class vLLMInference:
    def __init__(self, model_path: str):
        self.llm = LLM(model=model_path, tensor_parallel_size=2)
    
    def generate(self, prompts: List[str], **kwargs):
        sampling_params = SamplingParams(**kwargs)
        outputs = self.llm.generate(prompts, sampling_params)
        return [o.outputs[0].text for o in outputs]
```

---

*下一步：分布式部署*
