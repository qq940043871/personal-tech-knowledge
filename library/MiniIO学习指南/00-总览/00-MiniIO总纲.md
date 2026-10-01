# MiniIO学习指南 - 总纲

> 更新时间：2026-03-29

---

## 📋 文档概述

MinIO是一个高性能的对象存储系统，兼容Amazon S3 API，适用于私有云和边缘计算场景。

---

## 🗂️ 文档结构

```
MiniIO学习指南/
├── 00-总览/
│   └── 00-MiniIO总纲.md
├── 01-快速入门/
│   └── 01-MiniIO安装与配置.md
├── 02-Java客户端/
│   ├── 01-MiniIO Java SDK使用.md
│   └── 02-文件上传下载示例.md
└── 03-运维配置/
    └── 01-MiniIO集群与运维.md
```

---

## 🎯 核心知识点

| 模块 | 内容 |
|------|------|
| 安装 | Docker/二进制/单机/集群 |
| 存储 | Bucket、Object、策略 |
| SDK | Java SDK、预签名URL |
| 运维 | 扩容、监控、备份 |

---

## ⚡ 快速命令

```bash
# Docker启动
docker run -p 9000:9000 -p 9001:9001 \
  -e "MINIO_ROOT_USER=minioadmin" \
  -e "MINIO_ROOT_PASSWORD=minioadmin" \
  minio/minio server /data --console-address ":9001"

# mc客户端
mc alias set myminio http://localhost:9000 minioadmin minioadmin
mc ls myminio/
```

---

## 📊 MinIO架构

```
┌─────────────────────────────────────────────────────┐
│                     MinIO Cluster                   │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐ │
│  │ Node 1  │  │ Node 2  │  │ Node 3  │  │ Node 4  │ │
│  │  Drive  │  │  Drive  │  │  Drive  │  │  Drive  │ │
│  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘ │
│       └────────────┼────────────┼────────────┘       │
│                    │            │                    │
│              ┌─────┴────────────┴─────┐              │
│              │   Erasure Coding      │              │
│              │   (纠删码存储)         │              │
│              └───────────────────────┘              │
└─────────────────────────────────────────────────────┘
```
