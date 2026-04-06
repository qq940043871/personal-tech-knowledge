# Label Studio数据标注

> 模块：数据处理
> 更新时间：2026-03-29

---

## 一、框架介绍

Label Studio是一个开源的数据标注平台，支持多种数据类型（文本、图像、音频、视频等）。

**官网**：[https://labelstudio.io](https://labelstudio.io)
**GitHub**：[https://github.com/HumanSignal/label-studio](https://github.com/HumanSignal/label-studio)

**核心特点**：
- 多数据类型支持
- 灵活的标注配置
- 团队协作
- 机器学习集成
- 多种导出格式

---

## 二、快速开始

### 1. 安装

```bash
# pip安装
pip install label-studio

# 启动
label-studio

# 访问 http://localhost:8080
# 首次访问需要创建账号
```

### 2. Docker部署

```bash
docker run -d \
  -p 8080:8080 \
  -v $(pwd)/label_studio_data:/label-studio/data \
  heartexlabs/label-studio:latest
```

---

## 三、文本标注配置

### 1. 情感分类

```xml
<!-- labeling_config.xml -->
<View>
  <Text name="text" value="$text"/>
  
  <Choices name="sentiment" toName="text">
    <Choice value="正面"/>
    <Choice value="中性"/>
    <Choice value="负面"/>
  </Choices>
  
  <劝able name="meta" value="$meta"/>
</View>
```

### 2. 命名实体识别

```xml
<Text name="text" value="$text"/>

<Labels name="entities" toName="text">
  <Label value="人名"/>
  <Label value="地名"/>
  <Label value="机构"/>
  <Label value="时间"/>
</Labels>
```

### 3. 文本相似度

```xml
<View>
  <Text name="text1" value="$text1"/>
  <Text name="text2" value="$text2"/>
  
  <Number name="similarity" toName="text1,text2"
          min="0" max="1" step="0.1"/>
</View>
```

### 4. 问答标注

```xml
<View>
  <Header>请根据上下文回答问题</Header>
  <Text name="context" value="$context"/>
  <Text name="question" value="$question"/>
  <TextArea name="answer" toName="context" 
            showSublabels="true"/>
</View>
```

---

## 四、Python SDK使用

```python
from label_studio_sdk import Client

# 连接
ls = Client(
    url="http://localhost:8080",
    api_key="your-api-key"
)

# 获取项目
project = ls.get_project(1)

# 导入数据
project.import_data([
    {"text": "这是一个好产品", "id": 1},
    {"text": "质量一般", "id": 2},
    {"text": "非常好用", "id": 3},
])

# 导出数据
export_url = project.export_formats()
print(export_url)

# 获取标注结果
tasks = project.get_tasks()
for task in tasks:
    print(task["data"], task["annotations"])
```

---

## 五、API导入数据

```python
import requests

# 导入JSON格式数据
data = {
    "data": [
        {"text": "样本文本1", "source": "微博"},
        {"text": "样本文本2", "source": "知乎"},
        {"text": "样本文本3", "source": "小红书"}
    ]
}

response = requests.post(
    "http://localhost:8080/api/projects/1/import",
    json=data,
    headers={"Authorization": "Token your-api-key"}
)

print(response.json())
```

---

## 六、导出格式

```python
# 导出为JSON
project.export(export_type="JSON")

# 导出为CSV
project.export(export_type="CSV")

# 导出为CODEC
project.export(export_type="CODEC")
```

---

## 七、机器学习集成

```yaml
# .labelstudiorc 配置文件
{
  "ml_backend": {
    "url": "http://localhost:9090",
    "project": 1,
    "model_version": "v1"
  }
}
```

```python
# 自定义ML后端
from label_studio_ml.model import LabelStudioMLBase

class MyModel(LabelStudioMLBase):
    def predict(self, tasks, **kwargs):
        predictions = []
        for task in tasks:
            text = task["data"]["text"]
            # 调用你的模型
            sentiment = my_model.predict(text)
            predictions.append({
                "result": [{
                    "from_name": "sentiment",
                    "to_name": "text",
                    "type": "choices",
                    "choices": [sentiment]
                }]
            })
        return predictions
```

---

## 八、总结

Label Studio是企业级数据标注的首选工具，支持复杂标注任务和团队协作。

**适用场景**：
- 训练数据标注
- 模型评估数据标注
- 团队协作标注
- 半自动化标注

---

*下一步：LangChain核心概念*
