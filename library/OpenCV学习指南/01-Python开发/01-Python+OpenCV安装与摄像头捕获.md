# Python+OpenCV安装与摄像头捕获

> 模块：Python开发
> 更新时间：2026-03-29

---

## 一、安装

### Windows

```bash
# 基础安装
pip install opencv-python
pip install opencv-contrib-python

# 带GUI支持（需要安装matplotlib）
pip install opencv-python matplotlib

# 仅核心功能（无GUI，更轻量）
pip install opencv-python-headless
```

### Linux

```bash
# apt安装
sudo apt install python3-opencv

# pip安装
pip3 install opencv-python
```

### 验证安装

```python
import cv2
print(cv2.__version__)  # 输出版本号
```

---

## 二、摄像头基础

### 捕获摄像头

```python
import cv2

# 打开摄像头（0=默认摄像头）
cap = cv2.VideoCapture(0)

# 设置分辨率
cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)

# 读取帧
ret, frame = cap.read()

if ret:
    cv2.imshow('Camera', frame)
    cv2.waitKey(0)

cap.release()
cv2.destroyAllWindows()
```

### 捕获并显示

```python
import cv2

cap = cv2.VideoCapture(0)

while True:
    ret, frame = cap.read()
    
    if not ret:
        print("无法获取画面")
        break
    
    # 水平翻转（镜像）
    frame = cv2.flip(frame, 1)
    
    cv2.imshow('Camera', frame)
    
    # 按q退出
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
```

---

## 三、录制视频

```python
import cv2

cap = cv2.VideoCapture(0)

# 设置分辨率
cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)

# 编码器
fourcc = cv2.VideoWriter_fourcc(*'XVID')
# fourcc = cv2.VideoWriter_fourcc(*'H264')  # 需要安装对应编码器
# fourcc = cv2.VideoWriter_fourcc(*'MJPG')  #  Motion-JPEG

out = cv2.VideoWriter('output.avi', fourcc, 30.0, (1280, 720))

while cap.isOpened():
    ret, frame = cap.read()
    
    if not ret:
        break
    
    out.write(frame)
    cv2.imshow('Recording', frame)
    
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
out.release()
cv2.destroyAllWindows()
```

---

## 四、RTSP流读取

```python
import cv2

# RTSP流地址
rtsp_url = "rtsp://admin:admin123@192.168.1.100:554/stream1"

# 尝试不同后端
cap = cv2.VideoCapture(rtsp_url, cv2.CAP_FFMPEG)

if not cap.isOpened():
    # 备用后端
    cap = cv2.VideoCapture(rtsp_url, cv2.CAP_RTSP)

while cap.isOpened():
    ret, frame = cap.read()
    
    if not ret:
        print("连接断开，尝试重连...")
        cap.release()
        cap = cv2.VideoCapture(rtsp_url, cv2.CAP_FFMPEG)
        continue
    
    cv2.imshow('RTSP Stream', frame)
    
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
```

---

## 五、常见问题

```python
# 问题1：摄像头打开失败
# 解决：检查摄像头索引
for i in range(5):
    cap = cv2.VideoCapture(i)
    if cap.isOpened():
        print(f"摄像头可用: {i}")
        cap.release()

# 问题2：中文路径问题
# 解决：使用numpy读取
import numpy as np
img_bytes = open('中文路径.jpg', 'rb').read()
img_array = np.frombuffer(img_bytes, dtype=np.uint8)
img = cv2.imdecode(img_array, cv2.IMREAD_COLOR)

# 问题3：性能问题
# 解决：降低分辨率，跳帧处理
cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
```

---

*下一步：图像处理基础*
