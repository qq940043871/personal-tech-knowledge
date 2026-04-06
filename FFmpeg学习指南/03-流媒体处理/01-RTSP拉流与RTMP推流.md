# RTSP拉流与RTMP推流

> 模块：流媒体处理
> 更新时间：2026-04-06

---

## 一、RTSP拉流基础

### 1.1 RTSP协议概述

```
RTSP (Real Time Streaming Protocol)
├── 实时流控制协议
├── 支持暂停、播放、快进
├── 常用于IP摄像头
└── 默认端口: 554
```

### 1.2 常见摄像头RTSP地址

```bash
# 海康威视
rtsp://username:password@ip:554/Streaming/Channels/101

# 大华
rtsp://username:password@ip:554/cam/realmonitor?channel=1&subtype=0

# 宇视
rtsp://username:password@ip:554/video1

# 通用格式
rtsp://username:password@ip:port/path
```

### 1.3 基本拉流命令

```bash
ffmpeg -i rtsp://admin:123456@192.168.1.100:554/stream1 -c copy output.mp4

ffmpeg -rtsp_transport tcp -i rtsp://camera/live -c copy output.mp4

ffmpeg -rtsp_transport udp -i rtsp://camera/live -c copy output.mp4
```

---

## 二、RTSP拉流优化

### 2.1 降低延迟

```bash
ffmpeg -rtsp_transport tcp \
  -i rtsp://camera/live \
  -fflags nobuffer \
  -flags low_delay \
  -strict experimental \
  -acodec aac \
  -vcodec libx264 \
  -preset ultrafast \
  -tune zerolatency \
  -f mpegts udp://127.0.0.1:8888
```

### 2.2 断线重连

```bash
#!/bin/bash
while true; do
    ffmpeg -rtsp_transport tcp \
        -i rtsp://camera/live \
        -c copy \
        -f flv rtmp://server/live/stream
    
    echo "Connection lost, reconnecting in 5 seconds..."
    sleep 5
done
```

### 2.3 拉流参数详解

| 参数 | 说明 |
|------|------|
| `-rtsp_transport tcp` | 使用TCP传输，更稳定 |
| `-rtsp_transport udp` | 使用UDP传输，延迟更低 |
| `-stimeout 5000000` | 连接超时5秒（微秒） |
| `-max_delay 500000` | 最大延迟500ms |
| `-fflags nobuffer` | 禁用缓冲 |
| `-flags low_delay` | 低延迟模式 |

---

## 三、RTMP推流

### 3.1 RTMP协议概述

```
RTMP (Real-Time Messaging Protocol)
├── Adobe开发的流媒体协议
├── 基于TCP
├── 延迟1-3秒
└── 默认端口: 1935
```

### 3.2 基本推流命令

```bash
ffmpeg -re -i input.mp4 -c copy -f flv rtmp://server/live/stream

ffmpeg -re -i input.mp4 \
  -c:v libx264 -preset fast -b:v 2000k \
  -c:a aac -b:a 128k \
  -f flv rtmp://server/live/stream

ffmpeg -re -stream_loop -1 -i input.mp4 -c copy -f flv rtmp://server/live/stream
```

### 3.3 推流参数详解

| 参数 | 说明 |
|------|------|
| `-re` | 按原始帧率读取（直播必需） |
| `-stream_loop -1` | 无限循环输入 |
| `-c copy` | 直接复制流，不转码 |
| `-f flv` | 输出FLV格式 |
| `-g 60` | 关键帧间隔（影响延迟） |
| `-preset ultrafast` | 编码速度最快 |

---

## 四、摄像头录制方案

### 4.1 持续录制

```bash
ffmpeg -i rtsp://camera/live \
  -c:v libx264 -preset ultrafast \
  -c:a aac \
  -f segment \
  -segment_time 3600 \
  -segment_format mkv \
  -strftime 1 \
  "/recordings/%Y%m%d_%H%M%S.mkv"
```

### 4.2 分段录制

```bash
ffmpeg -i rtsp://camera/live \
  -c copy \
  -f segment \
  -segment_time 300 \
  -segment_format mp4 \
  -reset_timestamps 1 \
  -strftime 1 \
  "/recordings/cam1_%Y%m%d_%H%M%S.mp4"
```

### 4.3 录制脚本

```bash
#!/bin/bash
# camera_record.sh

CAMERA_URL="rtsp://admin:admin123@192.168.1.100:554/stream1"
OUTPUT_DIR="/recordings"
DATE=$(date +%Y%m%d)

mkdir -p "$OUTPUT_DIR/$DATE"

ffmpeg -rtsp_transport tcp \
  -i "$CAMERA_URL" \
  -c:v libx264 -preset ultrafast -crf 23 \
  -c:a aac \
  -f segment \
  -segment_time 600 \
  -segment_format mkv \
  -strftime 1 \
  "$OUTPUT_DIR/$DATE/cam_%Y%m%d_%H%M%S.mkv"
```

---

## 五、转推流方案

### 5.1 RTSP转RTMP

```bash
ffmpeg -rtsp_transport tcp \
  -i rtsp://camera/live \
  -c:v libx264 -preset ultrafast -g 60 \
  -c:a aac -b:a 128k \
  -f flv rtmp://server/live/stream
```

### 5.2 多目标推流

```bash
ffmpeg -re -i input.mp4 \
  -c:v libx264 -preset fast -b:v 2000k \
  -c:a aac -b:a 128k \
  -f flv rtmp://server1/live/stream \
  -f flv rtmp://server2/live/stream
```

### 5.3 推流到多个平台

```bash
#!/bin/bash
INPUT="rtsp://camera/live"

ffmpeg -rtsp_transport tcp -i "$INPUT" \
  -c:v libx264 -preset fast -b:v 2500k \
  -c:a aac -b:a 128k \
  -f flv "rtmp://live-push.example.com/live/stream1" \
  -c:v libx264 -preset fast -b:v 1500k \
  -c:a aac -b:a 96k \
  -f flv "rtmp://backup.example.com/live/stream2"
```

---

## 六、HLS输出

### 6.1 生成HLS流

```bash
ffmpeg -i rtsp://camera/live \
  -c:v libx264 -preset fast \
  -c:a aac \
  -f hls \
  -hls_time 2 \
  -hls_list_size 5 \
  -hls_flags delete_segments \
  -hls_segment_filename "/hls/segment_%03d.ts" \
  /hls/playlist.m3u8
```

### 6.2 HLS参数说明

| 参数 | 说明 |
|------|------|
| `-hls_time 2` | 每个分片2秒 |
| `-hls_list_size 5` | 播放列表保留5个分片 |
| `-hls_flags delete_segments` | 自动删除旧分片 |
| `-hls_segment_filename` | 分片命名规则 |
| `-hls_allow_cache 1` | 允许缓存 |

### 6.3 多码率HLS

```bash
ffmpeg -i input.mp4 \
  -c:v libx264 -b:v 4000k -s 1920x1080 -preset fast \
  -c:v libx264 -b:v 2000k -s 1280x720 -preset fast \
  -c:v libx264 -b:v 800k -s 640x360 -preset fast \
  -c:a aac -b:a 128k \
  -var_stream_map "v:0,a:0 v:1,a:0 v:2,a:0" \
  -master_pl_name master.m3u8 \
  -f hls -hls_time 4 -hls_list_size 0 \
  -hls_segment_filename "v%v/segment_%03d.ts" \
  "v%v/playlist.m3u8"
```

---

## 七、SRT低延迟传输

### 7.1 SRT推流

```bash
ffmpeg -re -i input.mp4 \
  -c copy \
  -f mpegts "srt://server:9000?mode=caller&latency=100"
```

### 7.2 SRT拉流

```bash
ffmpeg -i "srt://server:9000?mode=listener&latency=100" \
  -c copy output.mp4
```

### 7.3 SRT参数说明

| 参数 | 说明 |
|------|------|
| `mode=caller` | 推流模式 |
| `mode=listener` | 拉流模式 |
| `latency=100` | 延迟100ms |
| `passphrase=xxx` | 加密密码 |

---

## 八、完整实战脚本

### 8.1 摄像头监控录制系统

```bash
#!/bin/bash
# camera_monitor.sh

CAMERAS=(
  "rtsp://admin:pass@192.168.1.101:554/stream1|cam1"
  "rtsp://admin:pass@192.168.1.102:554/stream1|cam2"
  "rtsp://admin:pass@192.168.1.103:554/stream1|cam3"
)

OUTPUT_DIR="/recordings"
DATE=$(date +%Y%m%d)

for camera in "${CAMERAS[@]}"; do
  IFS='|' read -r url name <<< "$camera"
  
  mkdir -p "$OUTPUT_DIR/$DATE/$name"
  
  ffmpeg -rtsp_transport tcp \
    -i "$url" \
    -c:v libx264 -preset ultrafast -crf 23 \
    -c:a aac \
    -f segment \
    -segment_time 300 \
    -segment_format mkv \
    -strftime 1 \
    "$OUTPUT_DIR/$DATE/$name/%H%M%S.mkv" \
    > /var/log/camera_$name.log 2>&1 &
  
  echo "Started recording $name"
done
```

### 8.2 断线重连推流脚本

```bash
#!/bin/bash
# reconnect_push.sh

SOURCE="rtsp://camera/live"
TARGET="rtmp://server/live/stream"

while true; do
  echo "Starting stream at $(date)"
  
  ffmpeg -rtsp_transport tcp \
    -i "$SOURCE" \
    -c:v libx264 -preset ultrafast -g 60 \
    -c:a aac \
    -f flv "$TARGET"
  
  EXIT_CODE=$?
  echo "Stream ended with code $EXIT_CODE at $(date)"
  
  if [ $EXIT_CODE -ne 0 ]; then
    echo "Reconnecting in 5 seconds..."
    sleep 5
  else
    echo "Normal exit, stopping."
    break
  fi
done
```

### 8.3 定时录制脚本

```bash
#!/bin/bash
# scheduled_record.sh

CAMERA="rtsp://camera/live"
OUTPUT_DIR="/recordings"
DURATION=3600

start_time=$(date +%s)
end_time=$((start_time + DURATION))

ffmpeg -rtsp_transport tcp \
  -i "$CAMERA" \
  -c:v libx264 -preset ultrafast \
  -c:a aac \
  -t $DURATION \
  -strftime 1 \
  "$OUTPUT_DIR/recording_%Y%m%d_%H%M%S.mp4"
```

---

## 九、常见问题排查

### 9.1 连接超时

```bash
ffmpeg -rtsp_transport tcp -stimeout 10000000 -i rtsp://camera/live ...
```

### 9.2 画面卡顿

```bash
ffmpeg -rtsp_transport tcp -buffer_size 1024000 -i rtsp://camera/live ...
```

### 9.3 音视频不同步

```bash
ffmpeg -i rtsp://camera/live -vsync cfr -c copy output.mp4
```

### 9.4 推流中断

```bash
ffmpeg -reconnect 1 -reconnect_streamed 1 -reconnect_delay_max 5 -i ...
```

---

*文档完成*
