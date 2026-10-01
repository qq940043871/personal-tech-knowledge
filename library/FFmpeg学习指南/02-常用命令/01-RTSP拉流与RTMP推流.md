# RTSP拉流与RTMP推流

> 模块：流媒体处理
> 更新时间：2026-03-29

---

## 一、RTSP拉流

### 基本语法

```bash
# 从RTSP摄像头拉流
ffmpeg -i rtsp://username:password@camera_ip:554/stream1 -c copy output.mp4

# 常见RTSP URL格式
# 海康威视: rtsp://user:pass@ip:554/Streaming/Channels/101
# 大华: rtsp://user:pass@ip:554/cam/realmonitor?channel=1&subtype=0
```

### RTSP参数优化

```bash
# 降低延迟
ffmpeg -rtsp_transport tcp \
  -i rtsp://camera/live \
  -fflags nobuffer \
  -flags low_delay \
  -tune zerolatency \
  -f mpegts udp://127.0.0.1:8888

# 拉流并保存
ffmpeg -i rtsp://camera/live \
  -c:v libx264 -preset ultrafast \
  -c:a aac \
  -f flv rtmp://server/live/stream
```

---

## 二、RTMP推流

### 推送到Nginx-RTMP

```bash
# 简单推流
ffmpeg -re -i input.mp4 -c copy -f flv rtmp://server/live/stream

# 推流并转码
ffmpeg -re -i input.mp4 \
  -c:v libx264 -preset fast -b:v 2000k \
  -c:a aac -b:a 128k \
  -f flv rtmp://server/live/stream

# 循环推流（直播场景）
ffmpeg -re -stream_loop -1 -i input.mp4 \
  -c copy -f flv rtmp://server/live/stream
```

### 推流参数说明

```bash
-re              # 按视频原始帧率推流（直播必需）
-stream_loop -1  # 无限循环输入
-c copy          # 直接复制流，不转码（低CPU）
-b:v             # 视频码率
-b:a             # 音频码率
-g               # 关键帧间隔（影响延迟）
```

---

## 三、摄像头录制

### 持续录制

```bash
# 录制到文件（带时间戳）
ffmpeg -i rtsp://camera/live \
  -c:v libx264 -preset ultrafast \
  -f segment \
  -segment_time 3600 \
  -segment_format mkv \
  -strftime 1 \
  "/recordings/%Y%m%d_%H%M%S.mkv"
```

### 分段录制

```bash
# 每小时一个文件
ffmpeg -i rtsp://camera/live \
  -c copy \
  -f hls \
  -hls_time 3600 \
  -hls_list_size 0 \
  -hls_segment_filename "/recordings/segment_%Y%m%d%H%04d.ts" \
  /recordings/playlist.m3u8
```

---

## 四、推拉流完整脚本

### 摄像头拉流录制

```bash
#!/bin/bash
# record.sh - 摄像头录制脚本

CAMERA_URL="rtsp://admin:admin123@192.168.1.100:554/stream1"
OUTPUT_DIR="/recordings"
DATE=$(date +%Y%m%d)
TIME=$(date +%Y%m%d_%H%M%S)

mkdir -p "$OUTPUT_DIR/$DATE"

ffmpeg -rtsp_transport tcp \
  -i "$CAMERA_URL" \
  -c:v libx264 -preset ultrafast \
  -c:a aac \
  -f segment \
  -segment_time 300 \
  -segment_format mkv \
  -strftime 1 \
  "$OUTPUT_DIR/$DATE/${TIME}_%H%M%S.mkv"
```

### 推流到多个目标

```bash
#!/bin/bash
# multi_push.sh - 同时推流到多个目标

INPUT="rtsp://camera/live"
FFMPEG="/usr/local/bin/ffmpeg"

# 推流目标列表
RTMP_SERVERS=(
  "rtmp://live.example.com/live/stream"
  "rtmp://backup.example.com/live/stream"
)

$FFMPEG -rtsp_transport tcp -i "$INPUT" \
  -c:v copy -c:a aac -f flv \
  -threads 4 -preset ultrafast \
  "${RTMP_SERVERS[@]/#/-f flv rtmp://}" \
  rtmp://default/live/stream
```

---

## 五、常用推流地址格式

```bash
# 标准RTMP
rtmp://server:1935/live/stream

# 带应用名
rtmp://server:1935/app/stream_key

# SRT协议（低延迟）
srt://server:9000?latency=100

# HLS输出
-f hls -hls_time 2 -hls_list_size 0 /path/to/playlist.m3u8
```

---

*文档完成*
