# FFmpeg学习指南 - 总纲

> 更新时间：2026-03-29

---

## 📋 文档概述

FFmpeg是强大的音视频处理工具，支持转码、推流、拉流、录制等操作。

---

## 🗂️ 文档结构

```
FFmpeg学习指南/
├── 00-总览/
│   └── 00-FFmpeg总纲.md
├── 01-安装与基础/
│   └── 01-FFmpeg安装与核心概念.md
├── 02-常用命令/
│   ├── 01-视频转码与格式转换.md
│   └── 02-音频处理命令.md
└── 03-流媒体处理/
    └── 01-RTSP拉流与RTMP推流.md
```

---

## ⚡ 快速命令

```bash
# 查看视频信息
ffmpeg -i input.mp4

# 格式转换
ffmpeg -i input.avi output.mp4

# 推流到RTMP服务器
ffmpeg -i input.mp4 -c copy -f flv rtmp://server/live/stream

# 拉取RTSP流
ffmpeg -i rtsp://camera/live -c copy output.mp4

# 录制屏幕
ffmpeg -f x11grab -i :0.0 output.mp4
```

---

## 📊 FFmpeg处理流程

```
┌────────┐   ┌────────────┐   ┌────────┐
│ Input  │──▶│   Decode   │──▶│ Filter │
│ File   │   │            │   │        │
└────────┘   └────────────┘   └────┬───┘
                                   │
┌────────┐   ┌────────────┐   ┌────▼───┐
│ Output │◀──│   Encode   │◀──│ Output │
│ File   │   │            │   │ Stream │
└────────┘   └────────────┘   └────────┘
```
