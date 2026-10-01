# 09-技术知识库

架构师知识库站点（原 `hello_my_profile`）。

- 入口：`index.html`
- Markdown：`md-viewer.html?file=pages/...`
- 主题归属：**架构学习笔记 + 工作经历叙事**

## 结构

```text
09-技术知识库/
├── index.html          # 侧栏导航 + iframe
├── md-viewer.html
├── pages/
│   ├── 00_overview/    # 规范、模板、学习路径
│   ├── 01_hardware/ … 05_system_architect/
│   ├── 06_ai/          # 导读 + 桩页（链接 ai-study）
│   └── work-experience/  # 已迁出 → personal-investment-notes/resume/pages/work-experience/
└── assets/ css/
```

## 边界

- AI 课程与大模型刷题 → `ai-study/`  
- 面试真题与八股 → `interview-kit/banks/`（含 face-exp）  
- 本库 `06_ai` 只保留导读与链接桩页
