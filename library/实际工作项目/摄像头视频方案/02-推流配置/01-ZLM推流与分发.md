# ZLM推流与分发配置

> 模块：推流配置
> 更新时间：2026-03-29

---

## 一、ZLM推流架构

```
                    ZLM流媒体服务器
                           │
    ┌──────────────────────┼──────────────────────┐
    │                      │                      │
    ▼                      ▼                      ▼
RTMP推流              RTSP拉流               HTTP API
(FFmpeg)                                    (控制)
    │                      │                      │
    └──────────────────────┤                      │
                           │                      │
         ┌─────────────────┼─────────────────┐     │
         │                 │                 │     │
         ▼                 ▼                 ▼     │
    ┌─────────┐      ┌─────────┐      ┌─────────┐  │
    │   HLS   │      │  RTMP   │      │ HTTP-FLV│  │
    │ 分片存储 │      │  转RTMP │      │  流分发  │  │
    └─────────┘      └─────────┘      └─────────┘  │
                           │                      │
                           ▼                      ▼
                    ┌─────────────┐         ┌───────────┐
                    │  WebBrowser │         │   FFplay  │
                    │  (HLS播放)  │         │  (FLV播放) │
                    └─────────────┘         └───────────┘
```

---

## 二、FFmpeg推流到ZLM

### 推流到RTMP

```bash
# 推送到ZLM的live应用
ffmpeg -re -i /path/to/video.mp4 \
  -c copy \
  -f flv rtmp://localhost/live/stream

# 推送到指定vhost
ffmpeg -re -i /path/to/video.mp4 \
  -c copy \
  -f flv rtmp://localhost:1935/live/stream?vhost=__defaultVhost__
```

### 拉取RTSP推RTMP

```bash
# 摄像头 -> ZLM (完整流程)
ffmpeg -rtsp_transport tcp \
  -i rtsp://camera/live \
  -c:v copy -c:a aac \
  -f flv rtmp://localhost/live/camera1

# 同时推送到多个目标
ffmpeg -rtsp_transport tcp \
  -i rtsp://camera/live \
  -c copy \
  -f flv rtmp://zlm1/live/stream \
  -c copy \
  -f flv rtmp://zlm2/live/stream
```

### 持续推流脚本

```bash
#!/bin/bash
# push_stream.sh

CAMERA_URL="rtsp://admin:admin@192.168.1.100:554/stream1"
ZLM_URL="rtmp://localhost/live/stream"

while true; do
    ffmpeg -rtsp_transport tcp \
      -i "${CAMERA_URL}" \
      -c:v copy -c:a aac \
      -f flv -reconnect 1 -reconnect_streamed 1 \
      "${ZLM_URL}"
    
    echo "连接断开，5秒后重连..."
    sleep 5
done
```

---

## 三、ZLM拉流播放

### 播放地址

```bash
# RTMP (Flash已淘汰)
rtmp://localhost/live/stream

# HTTP-FLV (推荐，延迟低)
http://localhost:8080/live/stream.flv

# HLS (兼容性好，延迟高)
http://localhost:8080/live/stream/hls.m3u8

# RTSP
rtsp://localhost/live/stream
```

### 播放器示例

```html
<!-- flv.js 播放HTTP-FLV -->
<!DOCTYPE html>
<html>
<head>
    <script src="https://cdn.jsdelivr.net/npm/flv.js@1.6.2/dist/flv.min.js"></script>
</head>
<body>
    <video id="video" controls width="640" height="480"></video>
    
    <script>
        if (flvjs.isSupported()) {
            var videoElement = document.getElementById('video');
            var flvPlayer = flvjs.createPlayer({
                type: 'flv',
                url: 'http://localhost:8080/live/stream.flv'
            });
            flvPlayer.attachMediaElement(videoElement);
            flvPlayer.load();
            flvPlayer.play();
        }
    </script>
</body>
</html>
```

```html
<!-- hls.js 播放HLS -->
<!DOCTYPE html>
<html>
<head>
    <script src="https://cdn.jsdelivr.net/npm/hls.js@1.4.12/dist/hls.min.js"></script>
</head>
<body>
    <video id="video" controls width="640" height="480"></video>
    
    <script>
        var video = document.getElementById('video');
        var hls = new Hls({
            enableWorker: true,
            lowLatencyMode: true
        });
        
        hls.loadSource('http://localhost:8080/live/stream/hls.m3u8');
        hls.attachMedia(video);
        hls.on(Hls.Events.MANIFEST_PARSED, function() {
            video.play();
        });
    </script>
</body>
</html>
```

---

## 四、WebRTC播放

```html
<!-- ZLM WebRTC播放 -->
<!DOCTYPE html>
<html>
<head>
    <script src="https://cdn.jsdelivr.net/npm/zlm-webrtc@latest/dist/webrtc.js"></script>
</head>
<body>
    <video id="video" autoplay playsinline></video>
    
    <script>
        const player = new ZLMRTC.Engine.Player();
        
        player.init({
            element: document.getElementById('video'),
            zlmsdpUrl: 'http://localhost:8080/index/api/webrtc?app=live&stream=stream',
            simuleCast: false
        });
        
        player.start();
    </script>
</body>
</html>
```

---

*下一步：回放实现*
