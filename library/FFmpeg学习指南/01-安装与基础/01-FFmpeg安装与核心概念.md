# FFmpeg安装与核心概念

> 模块：安装与基础
> 更新时间：2026-03-29

---

## 一、FFmpeg概述

### 组件

```
ffmpeg      # 命令行工具，转码推流
ffplay     # 播放器
ffprobe    # 媒体信息查看
```

---

## 二、安装

### Windows

```bash
# 方法1: scoop
scoop install ffmpeg

# 方法2: choco
choco install ffmpeg

# 方法3: 下载编译好的包
# https://www.gyan.dev/ffmpeg/builds/
# 解压后添加到PATH
```

### Linux

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install ffmpeg

# CentOS/RHEL
sudo yum install epel-release
sudo yum install ffmpeg

# 或编译安装（最新版本）
wget https://ffmpeg.org/releases/ffmpeg-6.0.tar.gz
tar xzf ffmpeg-6.0.tar.gz
cd ffmpeg-6.0
./configure --prefix=/usr/local/ffmpeg
make && make install
```

### macOS

```bash
brew install ffmpeg
```

---

## 三、核心概念

### 封装格式(Container)
```
MP4 │ MKV │ AVI │ FLV │ MOV │ TS
```

### 视频编码(Codec)
```
H.264/AVC │ H.265/HEVC │ VP8 │ VP9 │ AV1
```

### 音频编码
```
AAC │ MP3 │ OPUS │ FLAC │ PCM
```

### 常用参数

```bash
# 输入输出
-i              # 输入文件
-f              # 强制格式

# 视频参数
-c:v            # 视频编码器 (copy表示不转码)
-s              # 分辨率 (如1920x1080)
-r              # 帧率 (如30)
-b:v            # 视频码率
-pixel_format   # 像素格式 (yuv420p)

# 音频参数
-c:a            # 音频编码器
-b:a            # 音频码率
-ar             # 采样率 (如44100)
-ac             # 声道数

# 其他
-y              # 自动覆盖输出文件
-v quiet        # 减少日志输出
-progress url   # 输出进度到文件
```

---

## 四、常用命令

### 查看媒体信息

```bash
# 查看完整信息
ffprobe -v quiet -print_format json -show_format -show_streams input.mp4

# 简化输出
ffprobe input.mp4

# 查看视频流信息
ffprobe -v error -show_entries stream=codec_name,width,height,bit_rate input.mp4
```

### 格式转换

```bash
# AVI转MP4
ffmpeg -i input.avi output.mp4

# 指定编码器
ffmpeg -i input.mp4 -c:v libx265 -c:a aac output.mp4

# 保持原编码（快速转换）
ffmpeg -i input.mov -c copy output.mp4

# 转换为FLV（推流常用）
ffmpeg -i input.mp4 -c copy -f flv output.flv
```

### 视频处理

```bash
# 调整分辨率
ffmpeg -i input.mp4 -vf "scale=1280:720" output.mp4

# 裁剪视频
ffmpeg -i input.mp4 -vf "crop=1920:1080:0:0" output.mp4

# 视频截图
ffmpeg -i input.mp4 -ss 00:00:10 -frames:v 1 output.jpg

# 提取GIF
ffmpeg -i input.mp4 -ss 00:00:05 -t 3 -vf "fps=10,scale=480:-1" output.gif

# 视频拼接
ffmpeg -f concat -safe 0 -i filelist.txt -c copy output.mp4
```

### 音频处理

```bash
# 提取音频
ffmpeg -i input.mp4 -vn -c:a copy output.aac

# 转换音频格式
ffmpeg -i input.mp3 -c:a libopus -b:a 128k output.opus

# 调整音量
ffmpeg -i input.mp4 -af "volume=2.0" output.mp4

# 音频混合
ffmpeg -i video.mp4 -i audio.mp3 -c:v copy -c:a aac output.mp4
```

---

*下一步：流媒体处理*
