# OpenCV学习指南 - 总纲

> 更新时间：2026-03-29

---

## 📋 文档概述

OpenCV是开源计算机视觉库，支持图像处理、特征检测、人脸识别、摄像头捕获等。

---

## 🗂️ 文档结构

```
OpenCV学习指南/
├── 00-总览/
│   └── 00-OpenCV总纲.md
├── 01-Python开发/
│   ├── 01-Python+OpenCV安装.md
│   └── 02-图像基础操作.md
├── 02-核心功能/
│   ├── 01-图像处理基础.md
│   └── 02-特征检测与匹配.md
└── 03-摄像头与视频/
    ├── 01-摄像头捕获与显示.md
    └── 02-视频录制与处理.md
```

---

## ⚡ 快速代码

```python
import cv2

# 读取图片
img = cv2.imread('image.jpg')

# 调用摄像头
cap = cv2.VideoCapture(0)

# 显示窗口
cv2.imshow('Window', img)
cv2.waitKey(0)

# 写入视频
out = cv2.VideoWriter('output.avi', fourcc, 30, (640,480))
```

---

## 📊 OpenCV模块

```
core      # 核心数据结构
imgproc   # 图像处理
video     # 视频分析
calib3d   # 相机校准
features2d # 特征检测
objdetect # 目标检测
highgui   # GUI显示
```
