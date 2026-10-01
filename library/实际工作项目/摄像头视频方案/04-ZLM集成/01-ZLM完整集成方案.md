# ZLM完整集成方案

> 模块：ZLM集成
> 更新时间：2026-03-29

---

## 一、完整架构

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           用户终端                                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐                │
│  │ Web浏览器 │  │ 移动APP  │  │ 桌面客户端│  │  微信小程序 │                │
│  │ flv.js   │  │  SDK    │  │   SDK   │  │   插件    │                │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘                │
└───────┼──────────────┼──────────────┼──────────────┼─────────────────────┘
        │ HTTP-FLV    │ RTMP        │ RTSP       │ HLS
        └──────────────┴─────────────┴─────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          ZLM流媒体服务器                                  │
│  ┌─────────────────────────────────────────────────────────────────────┐│
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐   ││
│  │  │  RTSP   │  │  RTMP   │  │  HLS    │  │ HTTP-FLV│  │ WebRTC  │   ││
│  │  │ Server  │  │ Server  │  │ Muxer   │  │ Server  │  │ Server  │   ││
│  │  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘   ││
│  └───────┼────────────┼────────────┼────────────┼────────────┼─────────┘│
│          └────────────┴─────┬──────┴────────────┴────────────┘          │
│                             │                                            │
│                      ┌──────┴──────┐                                     │
│                      │   媒体路由   │                                     │
│                      │  MediaRoute │                                     │
│                      └──────┬──────┘                                     │
│                             │                                            │
│  ┌──────────────────────────┼──────────────────────────────────────────┐│
│  │                    录制管理                                           ││
│  │   MP4分片录制 ──────────────────────────▶  本地存储/MinIO           ││
│  └──────────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────────┘
                              │
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   摄像头1     │     │   摄像头2     │     │   NVR设备    │
│   RTSP拉流   │     │   RTSP拉流   │     │   RTSP拉流   │
└──────────────┘     └──────────────┘     └──────────────┘
```

---

## 二、快速部署脚本

### 一键部署

```bash
#!/bin/bash
# deploy_camera.sh

set -e

echo "=== 摄像头视频系统部署 ==="

# 1. 创建网络
docker network create camera_net || true

# 2. 启动MinIO
echo "启动MinIO..."
docker run -d \
  --name minio \
  --network camera_net \
  -p 9000:9000 -p 9001:9001 \
  -e MINIO_ROOT_USER=minioadmin \
  -e MINIO_ROOT_PASSWORD=minioadmin \
  -v /data/minio:/data \
  minio/minio server /data

# 3. 启动ZLM
echo "启动ZLM..."
docker run -d \
  --name zlm \
  --network camera_net \
  -p 1935:1935 -p 8080:80 -p 8554:554 \
  -p 9000:9000 -p 10000:10000/udp \
  -v /data/zlm:/data \
  panhome/zlmediakit:latest

# 4. 安装mc客户端
curl -O https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc && sudo mv mc /usr/local/bin/

# 5. 配置MinIO别名
mc alias set myminio http://localhost:9000 minioadmin minioadmin
mc mb myminio/recordings --ignore-existing

echo "=== 部署完成 ==="
echo "MinIO Console: http://localhost:9001"
echo "ZLM HTTP API: http://localhost:9000"
echo "默认密钥: 035c73f7-186a-4a1e-8e25-8e3d3d5e5e5e"
```

---

## 三、完整Python SDK

```python
import requests
import time
from minio import Minio
from datetime import datetime, timedelta

class CameraVideoSystem:
    """摄像头视频系统"""
    
    def __init__(self, zlm_url="http://localhost:9000", 
                 minio_endpoint="localhost:9000",
                 minio_access="minioadmin",
                 minio_secret="minioadmin123"):
        self.zlm_url = zlm_url
        self.secret = "035c73f7-186a-4a1e-8e25-8e3d3d5e5e5e"
        
        # MinIO客户端
        self.minio = Minio(
            minio_endpoint,
            access_key=minio_access,
            secret_key=minio_secret,
            secure=False
        )
        self.bucket = "recordings"
        self._ensure_bucket()
        
    def _ensure_bucket(self):
        if not self.minio.bucket_exists(self.bucket):
            self.minio.make_bucket(self.bucket)
            
    # ========== ZLM API ==========
    
    def start_push(self, camera_id, rtsp_url, zlm_stream):
        """开始推流"""
        import subprocess
        
        cmd = [
            'ffmpeg',
            '-rtsp_transport', 'tcp',
            '-i', rtsp_url,
            '-c:v', 'copy', '-c:a', 'aac',
            '-f', 'flv',
            '-reconnect', '1', '-reconnect_streamed', '1',
            f'rtmp://{self.zlm_url.replace("http://","")}/live/{zlm_stream}'
        ]
        
        return subprocess.Popen(cmd)
    
    def start_record(self, app="live", stream="stream"):
        """开始录制"""
        url = f"{self.zlm_url}/index/api/startRecord"
        params = {
            "secret": self.secret,
            "vhost": "__defaultVhost__",
            "app": app,
            "stream": stream,
            "MP4": True
        }
        resp = requests.post(url, params=params)
        return resp.json()
    
    def stop_record(self, app="live", stream="stream"):
        """停止录制"""
        url = f"{self.zlm_url}/index/api/stopRecord"
        params = {"secret": self.secret, "app": app, "stream": stream}
        return requests.post(url, params=params).json()
    
    def get_online_streams(self):
        """获取在线流"""
        url = f"{self.zlm_url}/index/api/getMediaList"
        resp = requests.get(url, params={"secret": self.secret})
        return resp.json()
    
    def get_play_url(self, app="live", stream="stream", proto="hls"):
        """获取播放地址"""
        host = self.zlm_url.replace("http://", "")
        
        if proto == "rtmp":
            return f"rtmp://{host}/live/{stream}"
        elif proto == "hls":
            return f"http://{host}/live/{stream}/hls.m3u8"
        elif proto == "flv":
            return f"http://{host}/live/{stream}.flv"
        elif proto == "rtsp":
            return f"rtsp://{host}/live/{stream}"
        
    # ========== MinIO API ==========
    
    def upload_recording(self, file_path):
        """上传录制文件"""
        date = datetime.now().strftime("%Y/%m/%d")
        filename = f"{date}/{datetime.now().strftime('%H%M%S')}.mp4"
        
        self.minio.fput_object(self.bucket, filename, file_path)
        return filename
    
    def get_playback_url(self, object_name, hours=24):
        """获取回放URL"""
        return self.minio.get_presigned_url(
            "GET", self.bucket, object_name,
            expires=timedelta(hours=hours)
        )
    
    def list_recordings(self, date=None):
        """列出录制文件"""
        prefix = f"{date or datetime.now().strftime('%Y/%m/%d')}/"
        objects = self.minio.list_objects(self.bucket, prefix=prefix)
        return [obj.object_name for obj in objects]

# ========== 使用示例 ==========

if __name__ == "__main__":
    system = CameraVideoSystem()
    
    # 1. 获取在线流
    streams = system.get_online_streams()
    print("在线流:", streams)
    
    # 2. 获取播放地址
    hls_url = system.get_play_url(stream="camera1", proto="hls")
    print(f"HLS播放: {hls_url}")
    
    flv_url = system.get_play_url(stream="camera1", proto="flv")
    print(f"HTTP-FLV播放: {flv_url}")
    
    # 3. 录制控制
    system.start_record(app="live", stream="camera1")
    print("开始录制...")
    
    # 4. 列出录像
    recordings = system.list_recordings()
    print(f"录像列表: {recordings}")
    
    # 5. 获取回放URL
    if recordings:
        url = system.get_playback_url(recordings[0])
        print(f"