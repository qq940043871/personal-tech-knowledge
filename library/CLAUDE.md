# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a personal knowledge base and technical documentation repository (`library/`, part of the `personal-tech-knowledge` workspace). It contains 943 Markdown files across 27 directories covering Java engineering, system architecture, AI/ML, and "build from scratch" tutorials. A Flask web app provides a browsable document viewer.

## Running the Document Viewer

```bash
pip install -r ../requirements.txt
python app.py
# Serves at http://localhost:5000 — browse all Markdown files via the web UI
```

Dependencies are pinned in the repo-root `requirements.txt` (Flask only).

**API Endpoints:**
- `GET /` — Serves the document viewer UI (`python.html`)
- `GET /api/files` — Returns JSON array of all Markdown files grouped by directory
- `GET /api/file?path=<relative_path>` — Returns JSON with `path` and `content` fields for a specific file. Paths are resolved and confined to this workspace; `../` traversal returns 404.

**HTML Files:**
- `python.html` — Markdown viewer served at `/` by Flask, uses marked.js for rendering
- `index.html` — Static viewer with left sidebar directory tree navigation; works without the Flask backend
- `build_tree.py` — Scans this directory and regenerates `tree.json` (the sidebar index consumed by `index.html`); run it after adding or removing documents
- `17年技术经验总结/09-技术知识库/index.html` + `md-viewer.html` — self-contained knowledge-base portal with its own renderer

Note: the three viewers above are independent implementations that do not share code. A change to rendering or navigation usually has to be applied to each one separately.

`index.html` does not hard-code the directory tree. On load it fetches `tree.json`, which `build_tree.py` generates from the actual files on disk, so the sidebar can never link to a deleted file. Only `.md` / `.markdown` / `.pptx` are indexed; source code, hidden directories, and top-level metadata files are skipped. The viewer renders three levels (category → subdirectory → sub-subdirectory); anything deeper is folded into a `parent/child` label.

## Development Notes

This is a **documentation-only repository** with no build system, test suite, or linter. The only runnable code is the Flask web viewer plus the `build_tree.py` index generator.

- All content is in Markdown — no compilation or transpilation needed
- Hidden directories (starting with `.`) are excluded from the document viewer
- `tree.json` is a generated artifact; `start.bat` regenerates it on every launch, or run `python library/build_tree.py` manually

## Repository Structure

**Knowledge base directories** follow a consistent numbering convention:
```
主题名/
├── 00-总览/          # Overview / index
├── 01-基础/          # Basics
├── 02-进阶/          # Advanced
└── 99-参考速查.md     # Quick reference cheat sheet
```

Key top-level directories:

| Category | Directories |
|----------|------------|
| Core engineering | `17年技术经验总结/`, `Java框架全景图/`, `Java避坑指南/` |
| Infrastructure | `Linux学习指南/`, `Nginx学习指南/`, `Redis学习指南/`, `Kafka学习指南/`, `Zookeeper学习指南/`, `MiniIO学习指南/` |
| AI / LLM | `大模型工具全景图/`, `AI常用类库指南/`, `手写大模型/`, `ClaudeCode学习指南/`, `Openclaw学习指南/` |
| Build-from-scratch series | `手写JVM/`, `手写Web容器/`, `手写操作系统/`, `手写数据库/`, `手写浏览器/`, `手写消息中间件/`, `手写游戏引擎/` |
| Real projects | `实际工作项目/` — contains `ruoyi-agent/` (AI Agent Management System) |
| Documentation system | `技术文档体系/` — writing guides, templates, and the Divio four-quadrant standard |

## Embedded Project: ruoyi-agent

Located at `实际工作项目/智能体管理系统设计/ruoyi-agent/`. A Spring Boot 3.x + Vue 3 application based on the RuoYi framework.

**Backend stack:** Spring Boot 3.x, MyBatis Plus 3.5.x, Sa-Token (auth), MySQL 8.0, Redis 6.0, MinIO

**Architecture layers:**
- `controller/` → REST API endpoints
- `service/` → Business logic
- `mapper/` → MyBatis Plus data access (XML mappings in `resources/mapper/`)
- `domain/entity/` → JPA/MyBatis entities

**Frontend:** Vue 3 + Vite + Element Plus at `ruoyi-ui/`
- `src/api/agent/` — API client modules
- `src/views/agent/` — Page components

**Database schema:** `sql/ruoyi_agent.sql`

## Documentation Standards

This repo follows the **Divio four-quadrant documentation system** (documented in `技术文档体系/DOC_SYSTEM.md`):
- **Tutorial** — learning-oriented, hands-on
- **How-to Guide** — task-oriented, solve specific problems
- **Reference** — information-oriented, lookup manual
- **Explanation** — understanding-oriented, background context

One document = one purpose. Don't mix types.

## Document Writing Conventions

- Chinese language for all knowledge base content
- Practical, direct style with code examples
- Structure: scenario → cause analysis → solution
- Second-person voice (你)
