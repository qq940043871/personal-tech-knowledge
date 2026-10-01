# MiniIO安装与配置

> 模块：快速入门
> 更新时间：2026-03-29

---

## 一、MinIO简介

### 特点

```
S3兼容 │ 高性能 │ 纠删码 │ K8S原生 │ MIT开源
```

- **S3兼容**：100%兼容Amazon S3 API
- **高性能**：单节点可达数GB/s读写
- **纠删码**：数据冗余存储，自动修复
- **K8S友好**：支持Helm、Operator部署

---

## 二、安装部署

### 1. Docker单节点

```bash
# 运行MinIO
docker run -d \
  --name minio \
  -p 9000:9000 \
  -p 9001:9001 \
  -e "MINIO_ROOT_USER=minioadmin" \
  -e "MINIO_ROOT_PASSWORD=minioadmin" \
  -v /data/minio:/data \
  minio/minio server /data --console-address ":9001"

# 访问
# API: http://localhost:9000
# Console: http://localhost:9001
```

### 2. Docker Compose

```yaml
# docker-compose.yml
version: '3.8'
services:
  minio:
    image: minio/minio:latest
    container_name: minio
    ports:
      - "9000:9000"
      - "9001:9001"
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin123
    volumes:
      - ./data:/data
    command: server /data --console-address ":9001"
    restart: unless-stopped
```

### 3. 二进制安装

```bash
# 下载
wget https://dl.min.io/server/minio/release/linux-amd64/minio
chmod +x minio

# 启动
MINIO_ROOT_USER=minioadmin \
MINIO_ROOT_PASSWORD=minioadmin123 \
./minio server /data --console-address ":9001"
```

---

## 三、MinIO Client (mc)

### 安装mc

```bash
# Linux/macOS
curl -O https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc
sudo mv mc /usr/local/bin/

# Windows: 下载exe文件并添加到PATH
```

### 常用命令

```bash
# 配置别名
mc alias set myminio http://localhost:9000 minioadmin minioadmin123

# 查看所有bucket
mc ls myminio/

# 创建bucket
mc mb myminio/my-bucket

# 上传文件
mc cp /path/to/file myminio/my-bucket/

# 下载文件
mc cp myminio/my-bucket/file /local/path/

# 设置访问策略（公开读取）
mc anonymous set download myminio/my-bucket

# 查看bucket使用情况
mc du myminio/my-bucket

# 统计信息
mc admin info myminio
```

---

## 四、Java客户端使用

### Maven依赖

```xml
<dependency>
    <groupId>io.minio</groupId>
    <artifactId>minio</artifactId>
    <version>8.5.7</version>
</dependency>
```

### 文件上传

```java
import io.minio.*;
import io.minio.http.Mode;
import java.io.*;

public class MinioUploadDemo {
    public static void main(String[] args) throws Exception {
        // 创建客户端
        MinioClient minioClient = MinioClient.builder()
            .endpoint("http://localhost:9000")
            .credentials("minioadmin", "minioadmin123")
            .build();
        
        // 判断bucket是否存在
        boolean found = minioClient.bucketExists(
            BucketExistsArgs.builder().bucket("my-bucket").build());
        if (!found) {
            // 创建bucket
            minioClient.makeBucket(
                MakeBucketArgs.builder().bucket("my-bucket").build());
        }
        
        // 上传文件
        minioClient.uploadObject(
            UploadObjectArgs.builder()
                .bucket("my-bucket")
                .object("photo.jpg")
                .fileName("/path/to/photo.jpg")
                .contentType("image/jpeg")
                .build());
        
        System.out.println("上传成功");
        
        // 获取文件URL（7天有效）
        String url = minioClient.getPresignedObjectUrl(
            GetPresignedObjectUrlArgs.builder()
                .bucket("my-bucket")
                .object("photo.jpg")
                .expiry(7, java.util.concurrent.TimeUnit.DAYS)
                .build());
        System.out.println("访问URL: " + url);
    }
}
```

### 文件下载

```java
// 下载到本地文件
minioClient.downloadObject(
    DownloadObjectArgs.builder()
        .bucket("my-bucket")
        .object("photo.jpg")
        .fileName("/path/to/save.jpg")
        .build());

// 下载到输入流
try (InputStream stream = minioClient.getObject(
        GetObjectArgs.builder()
            .bucket("my-bucket")
            .object("photo.jpg")
            .build())) {
    // 处理流
    byte[] data = stream.readAllBytes();
}
```

### 删除文件

```java
// 删除单个文件
minioClient.removeObject(
    RemoveObjectArgs.builder()
        .bucket("my-bucket")
        .object("photo.jpg")
        .build());

// 删除多个文件
Iterable<Result<DeleteError>> results = minioClient.removeObjects(
    RemoveObjectsArgs.builder()
        .bucket("my-bucket")
        .objects(Arrays.asList("a.jpg", "b.jpg"))
        .build());
```

---

*文档完成*
