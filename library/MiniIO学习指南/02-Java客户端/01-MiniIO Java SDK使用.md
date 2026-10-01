# MiniIO Java SDK使用

> 模块：Java客户端
> 更新时间：2026-04-06

---

## 一、环境配置

### 1.1 Maven依赖

```xml
<dependency>
    <groupId>io.minio</groupId>
    <artifactId>minio</artifactId>
    <version>8.5.9</version>
</dependency>
```

### 1.2 Gradle依赖

```groovy
implementation 'io.minio:minio:8.5.9'
```

### 1.3 配置文件

```yaml
minio:
  endpoint: http://localhost:9000
  accessKey: minioadmin
  secretKey: minioadmin123
  bucketName: my-bucket
  secure: false
```

---

## 二、客户端初始化

### 2.1 基本初始化

```java
import io.minio.MinioClient;

MinioClient minioClient = MinioClient.builder()
    .endpoint("http://localhost:9000")
    .credentials("minioadmin", "minioadmin123")
    .build();
```

### 2.2 HTTPS配置

```java
MinioClient minioClient = MinioClient.builder()
    .endpoint("https://minio.example.com")
    .credentials("accessKey", "secretKey")
    .secure(true)
    .build();
```

### 2.3 自定义HTTP配置

```java
OkHttpClient httpClient = new OkHttpClient.Builder()
    .connectTimeout(30, TimeUnit.SECONDS)
    .readTimeout(60, TimeUnit.SECONDS)
    .writeTimeout(60, TimeUnit.SECONDS)
    .build();

MinioClient minioClient = MinioClient.builder()
    .endpoint("http://localhost:9000")
    .credentials("minioadmin", "minioadmin123")
    .httpClient(httpClient)
    .build();
```

### 2.4 Spring Boot集成

```java
@Configuration
public class MinioConfig {

    @Value("${minio.endpoint}")
    private String endpoint;

    @Value("${minio.accessKey}")
    private String accessKey;

    @Value("${minio.secretKey}")
    private String secretKey;

    @Bean
    public MinioClient minioClient() {
        return MinioClient.builder()
            .endpoint(endpoint)
            .credentials(accessKey, secretKey)
            .build();
    }
}
```

---

## 三、Bucket操作

### 3.1 创建Bucket

```java
public void createBucket(String bucketName) throws Exception {
    boolean exists = minioClient.bucketExists(
        BucketExistsArgs.builder()
            .bucket(bucketName)
            .build()
    );
    
    if (!exists) {
        minioClient.makeBucket(
            MakeBucketArgs.builder()
                .bucket(bucketName)
                .build()
        );
    }
}
```

### 3.2 删除Bucket

```java
public void deleteBucket(String bucketName) throws Exception {
    minioClient.removeBucket(
        RemoveBucketArgs.builder()
            .bucket(bucketName)
            .build()
    );
}
```

### 3.3 列出所有Bucket

```java
public List<String> listBuckets() throws Exception {
    List<Bucket> buckets = minioClient.listBuckets();
    return buckets.stream()
        .map(Bucket::name)
        .collect(Collectors.toList());
}
```

### 3.4 设置Bucket策略

```java
public void setBucketPolicy(String bucketName) throws Exception {
    String policy = """
        {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {"AWS": "*"},
                    "Action": ["s3:GetObject"],
                    "Resource": ["arn:aws:s3:::%s/*"]
                }
            ]
        }
        """.formatted(bucketName);
    
    minioClient.setBucketPolicy(
        SetBucketPolicyArgs.builder()
            .bucket(bucketName)
            .config(policy)
            .build()
    );
}
```

### 3.5 设置生命周期

```java
public void setBucketLifecycle(String bucketName) throws Exception {
    LifecycleConfiguration config = new LifecycleConfiguration(
        List.of(
            new LifecycleRule(
                Status.ENABLED,
                new Filter(null, null, null, null),
                new Expiration(
                    null,
                    30,
                    null
                ),
                "delete-old-files",
                null,
                null,
                null,
                null
            )
        )
    );
    
    minioClient.setBucketLifecycle(
        SetBucketLifecycleArgs.builder()
            .bucket(bucketName)
            .config(config)
            .build()
    );
}
```

---

## 四、文件操作

### 4.1 上传文件

```java
public void uploadFile(String bucketName, String objectName, String filePath) throws Exception {
    minioClient.uploadObject(
        UploadObjectArgs.builder()
            .bucket(bucketName)
            .object(objectName)
            .filename(filePath)
            .build()
    );
}
```

### 4.2 上传输入流

```java
public void uploadStream(String bucketName, String objectName, InputStream stream, long size) throws Exception {
    minioClient.putObject(
        PutObjectArgs.builder()
            .bucket(bucketName)
            .object(objectName)
            .stream(stream, size, -1)
            .contentType("application/octet-stream")
            .build()
    );
}
```

### 4.3 上传字节数组

```java
public void uploadBytes(String bucketName, String objectName, byte[] data) throws Exception {
    try (ByteArrayInputStream stream = new ByteArrayInputStream(data)) {
        minioClient.putObject(
            PutObjectArgs.builder()
                .bucket(bucketName)
                .object(objectName)
                .stream(stream, data.length, -1)
                .build()
        );
    }
}
```

### 4.4 下载文件

```java
public void downloadFile(String bucketName, String objectName, String filePath) throws Exception {
    minioClient.downloadObject(
        DownloadObjectArgs.builder()
            .bucket(bucketName)
            .object(objectName)
            .filename(filePath)
            .build()
    );
}
```

### 4.5 获取输入流

```java
public InputStream getObjectStream(String bucketName, String objectName) throws Exception {
    return minioClient.getObject(
        GetObjectArgs.builder()
            .bucket(bucketName)
            .object(objectName)
            .build()
    );
}
```

### 4.6 删除文件

```java
public void deleteFile(String bucketName, String objectName) throws Exception {
    minioClient.removeObject(
        RemoveObjectArgs.builder()
            .bucket(bucketName)
            .object(objectName)
            .build()
    );
}
```

### 4.7 批量删除

```java
public void deleteFiles(String bucketName, List<String> objectNames) throws Exception {
    List<DeleteObject> objects = objectNames.stream()
        .map(DeleteObject::new)
        .collect(Collectors.toList());
    
    Iterable<Result<DeleteError>> results = minioClient.removeObjects(
        RemoveObjectsArgs.builder()
            .bucket(bucketName)
            .objects(objects)
            .build()
    );
    
    for (Result<DeleteError> result : results) {
        DeleteError error = result.get();
        System.err.println("删除失败: " + error.objectName());
    }
}
```

---

## 五、文件信息查询

### 5.1 检查文件是否存在

```java
public boolean objectExists(String bucketName, String objectName) {
    try {
        minioClient.statObject(
            StatObjectArgs.builder()
                .bucket(bucketName)
                .object(objectName)
                .build()
        );
        return true;
    } catch (Exception e) {
        return false;
    }
}
```

### 5.2 获取文件元数据

```java
public ObjectStat getObjectStat(String bucketName, String objectName) throws Exception {
    return minioClient.statObject(
        StatObjectArgs.builder()
            .bucket(bucketName)
            .object(objectName)
            .build()
    );
}
```

### 5.3 列出文件

```java
public List<String> listObjects(String bucketName) throws Exception {
    Iterable<Result<Item>> results = minioClient.listObjects(
        ListObjectsArgs.builder()
            .bucket(bucketName)
            .recursive(true)
            .build()
    );
    
    List<String> objects = new ArrayList<>();
    for (Result<Item> result : results) {
        objects.add(result.get().objectName());
    }
    return objects;
}
```

### 5.4 按前缀列出文件

```java
public List<String> listObjectsByPrefix(String bucketName, String prefix) throws Exception {
    Iterable<Result<Item>> results = minioClient.listObjects(
        ListObjectsArgs.builder()
            .bucket(bucketName)
            .prefix(prefix)
            .recursive(true)
            .build()
    );
    
    List<String> objects = new ArrayList<>();
    for (Result<Item> result : results) {
        objects.add(result.get().objectName());
    }
    return objects;
}
```

---

## 六、预签名URL

### 6.1 生成下载URL

```java
public String getPresignedDownloadUrl(String bucketName, String objectName) throws Exception {
    return minioClient.getPresignedObjectUrl(
        GetPresignedObjectUrlArgs.builder()
            .method(Method.GET)
            .bucket(bucketName)
            .object(objectName)
            .expiry(7, TimeUnit.DAYS)
            .build()
    );
}
```

### 6.2 生成上传URL

```java
public String getPresignedUploadUrl(String bucketName, String objectName) throws Exception {
    return minioClient.getPresignedObjectUrl(
        GetPresignedObjectUrlArgs.builder()
            .method(Method.PUT)
            .bucket(bucketName)
            .object(objectName)
            .expiry(1, TimeUnit.HOURS)
            .build()
    );
}
```

### 6.3 带参数的预签名URL

```java
public String getPresignedUrlWithParams(String bucketName, String objectName) throws Exception {
    Map<String, String> queryParams = new HashMap<>();
    queryParams.put("response-content-type", "application/json");
    queryParams.put("response-content-disposition", "attachment; filename=\"download.json\"");
    
    return minioClient.getPresignedObjectUrl(
        GetPresignedObjectUrlArgs.builder()
            .method(Method.GET)
            .bucket(bucketName)
            .object(objectName)
            .expiry(2, TimeUnit.HOURS)
            .extraQueryParams(queryParams)
            .build()
    );
}
```

---

## 七、文件复制

### 7.1 同Bucket复制

```java
public void copyObject(String bucketName, String sourceObject, String destObject) throws Exception {
    minioClient.copyObject(
        CopyObjectArgs.builder()
            .bucket(bucketName)
            .object(destObject)
            .source(
                CopySource.builder()
                    .bucket(bucketName)
                    .object(sourceObject)
                    .build()
            )
            .build()
    );
}
```

### 7.2 跨Bucket复制

```java
public void copyObjectBetweenBuckets(String sourceBucket, String sourceObject, 
                                       String destBucket, String destObject) throws Exception {
    minioClient.copyObject(
        CopyObjectArgs.builder()
            .bucket(destBucket)
            .object(destObject)
            .source(
                CopySource.builder()
                    .bucket(sourceBucket)
                    .object(sourceObject)
                    .build()
            )
            .build()
    );
}
```

---

## 八、异常处理

### 8.1 常见异常

```java
try {
    minioClient.getObject(...);
} catch (ErrorResponseException e) {
    ErrorResponse response = e.errorResponse();
    System.err.println("错误码: " + response.code());
    System.err.println("错误信息: " + response.message());
} catch (InsufficientDataException e) {
    System.err.println("数据不足: " + e.getMessage());
} catch (InternalException e) {
    System.err.println("内部错误: " + e.getMessage());
} catch (InvalidKeyException e) {
    System.err.println("无效密钥: " + e.getMessage());
} catch (IOException e) {
    System.err.println("IO错误: " + e.getMessage());
} catch (NoSuchAlgorithmException e) {
    System.err.println("算法不存在: " + e.getMessage());
} catch (ServerException e) {
    System.err.println("服务器错误: " + e.getMessage());
} catch (XmlParserException e) {
    System.err.println("XML解析错误: " + e.getMessage());
}
```

### 8.2 统一异常处理

```java
@RestControllerAdvice
public class MinioExceptionHandler {

    @ExceptionHandler(ErrorResponseException.class)
    public ResponseEntity<String> handleErrorResponse(ErrorResponseException e) {
        return ResponseEntity.status(e.errorResponse().code())
            .body(e.errorResponse().message());
    }

    @ExceptionHandler(InsufficientDataException.class)
    public ResponseEntity<String> handleInsufficientData(InsufficientDataException e) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
            .body("数据传输不完整");
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<String> handleException(Exception e) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
            .body("服务器内部错误: " + e.getMessage());
    }
}
```

---

*下一步：文件上传下载示例*
