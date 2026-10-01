# [模块名称] API 参考文档

> **版本**：v1.0  
> **Base URL**：`https://api.your-domain.com/v1`  
> **认证方式**：Bearer Token（在 `Authorization` 请求头中传入）  
> **数据格式**：请求体和响应体均为 JSON，`Content-Type: application/json`

---

## 目录

- [认证说明](#认证说明)
- [通用响应格式](#通用响应格式)
- [错误码参考](#错误码参考)
- [接口列表](#接口列表)
  - [创建 XXX](#POST-/xxx)
  - [查询 XXX 列表](#GET-/xxx)
  - [查询 XXX 详情](#GET-/xxx/:id)
  - [更新 XXX](#PUT-/xxx/:id)
  - [删除 XXX](#DELETE-/xxx/:id)

---

## 认证说明

所有接口均需在请求头中携带有效 Token：

```http
Authorization: Bearer <your_access_token>
```

Token 通过登录接口获取，有效期 24 小时。过期后需重新登录获取新 Token。

> ⚠️ **注意**：Token 不要泄露给他人，不要存储在前端代码或 Git 仓库中。

---

## 通用响应格式

所有接口统一返回以下结构：

```json
{
  "code": 200,
  "msg": "操作成功",
  "data": { ... }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | Integer | 业务状态码，200 表示成功 |
| `msg` | String | 描述信息 |
| `data` | Object/Array/null | 业务数据，失败时为 null |

---

## 错误码参考

| 状态码 | 业务码 | 说明 | 处理建议 |
|--------|--------|------|---------|
| 200 | 200 | 成功 | — |
| 400 | 400 | 请求参数错误 | 检查 `msg` 字段了解具体缺失的参数 |
| 401 | 401 | 未认证 / Token 失效 | 重新登录，获取新 Token |
| 403 | 403 | 无权限 | 联系管理员分配对应权限 |
| 404 | 404 | 资源不存在 | 检查 ID 是否正确 |
| 429 | 429 | 请求过于频繁 | 稍后重试，默认限流 100次/分钟 |
| 500 | 500 | 服务器内部错误 | 记录 `requestId` 后联系运维排查 |

---

## 接口列表

---

### POST /xxx

**创建 XXX**

创建一个新的 XXX 对象。创建成功后，系统将自动分配唯一 ID 并返回完整对象信息。

**请求参数**

| 参数名 | 位置 | 类型 | 必选 | 说明 |
|--------|------|------|------|------|
| `name` | Body | String | 是 | 名称，长度 2-50 字符 |
| `description` | Body | String | 否 | 描述，最长 500 字符 |
| `type` | Body | String | 是 | 类型，可选值：`typeA` / `typeB` |
| `config` | Body | Object | 否 | 扩展配置，见 [Config 对象说明](#config-对象说明) |

**请求示例**

```http
POST /api/v1/xxx
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
Content-Type: application/json

{
  "name": "我的第一个对象",
  "description": "这是一段描述",
  "type": "typeA",
  "config": {
    "timeout": 30,
    "retries": 3
  }
}
```

**成功响应** `HTTP 200`

```json
{
  "code": 200,
  "msg": "创建成功",
  "data": {
    "id": "xxx_abc123",
    "name": "我的第一个对象",
    "description": "这是一段描述",
    "type": "typeA",
    "status": "active",
    "createTime": "2026-04-22T10:30:00+08:00",
    "updateTime": "2026-04-22T10:30:00+08:00"
  }
}
```

**错误响应示例**

```json
// 参数缺失（400）
{
  "code": 400,
  "msg": "name 不能为空",
  "data": null
}

// 名称重复（400）
{
  "code": 400,
  "msg": "name 已存在，请使用其他名称",
  "data": null
}
```

---

### GET /xxx

**查询 XXX 列表**

分页查询当前用户有权访问的 XXX 列表，支持按名称模糊搜索和状态筛选。

**请求参数**

| 参数名 | 位置 | 类型 | 必选 | 默认值 | 说明 |
|--------|------|------|------|--------|------|
| `pageNum` | Query | Integer | 否 | 1 | 页码，从 1 开始 |
| `pageSize` | Query | Integer | 否 | 20 | 每页数量，范围 1-100 |
| `name` | Query | String | 否 | — | 名称模糊搜索 |
| `status` | Query | String | 否 | — | 状态筛选：`active` / `inactive` |

**请求示例**

```http
GET /api/v1/xxx?pageNum=1&pageSize=10&name=测试
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```

**成功响应** `HTTP 200`

```json
{
  "code": 200,
  "msg": "查询成功",
  "data": {
    "total": 42,
    "pageNum": 1,
    "pageSize": 10,
    "list": [
      {
        "id": "xxx_abc123",
        "name": "测试对象 A",
        "type": "typeA",
        "status": "active",
        "createTime": "2026-04-22T10:30:00+08:00"
      }
    ]
  }
}
```

---

### GET /xxx/:id

**查询 XXX 详情**

根据 ID 查询单个 XXX 的完整信息。

**路径参数**

| 参数名 | 类型 | 必选 | 说明 |
|--------|------|------|------|
| `id` | String | 是 | XXX 的唯一 ID |

**请求示例**

```http
GET /api/v1/xxx/xxx_abc123
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```

**成功响应** `HTTP 200`

```json
{
  "code": 200,
  "msg": "查询成功",
  "data": {
    "id": "xxx_abc123",
    "name": "测试对象 A",
    "description": "这是描述",
    "type": "typeA",
    "status": "active",
    "config": {
      "timeout": 30,
      "retries": 3
    },
    "createTime": "2026-04-22T10:30:00+08:00",
    "updateTime": "2026-04-22T10:30:00+08:00"
  }
}
```

**错误响应**

```json
// 不存在（404）
{
  "code": 404,
  "msg": "资源不存在",
  "data": null
}
```

---

### PUT /xxx/:id

**更新 XXX**

更新指定 XXX 的信息。只传入需要修改的字段，未传入的字段保持不变。

**路径参数**

| 参数名 | 类型 | 必选 | 说明 |
|--------|------|------|------|
| `id` | String | 是 | XXX 的唯一 ID |

**请求参数**

| 参数名 | 位置 | 类型 | 必选 | 说明 |
|--------|------|------|------|------|
| `name` | Body | String | 否 | 新名称 |
| `description` | Body | String | 否 | 新描述 |
| `status` | Body | String | 否 | 新状态：`active` / `inactive` |

**请求示例**

```http
PUT /api/v1/xxx/xxx_abc123
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
Content-Type: application/json

{
  "name": "更新后的名称",
  "status": "inactive"
}
```

**成功响应** `HTTP 200`

```json
{
  "code": 200,
  "msg": "更新成功",
  "data": {
    "id": "xxx_abc123",
    "name": "更新后的名称",
    "status": "inactive",
    "updateTime": "2026-04-22T11:00:00+08:00"
  }
}
```

---

### DELETE /xxx/:id

**删除 XXX**

删除指定 XXX。该操作为**逻辑删除**，数据不会从数据库中物理删除，但将无法通过 API 访问。

> ⚠️ **注意**：删除后不可恢复。如需临时禁用，建议使用更新接口将 `status` 改为 `inactive`。

**路径参数**

| 参数名 | 类型 | 必选 | 说明 |
|--------|------|------|------|
| `id` | String | 是 | XXX 的唯一 ID |

**请求示例**

```http
DELETE /api/v1/xxx/xxx_abc123
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```

**成功响应** `HTTP 200`

```json
{
  "code": 200,
  "msg": "删除成功",
  "data": null
}
```

---

## 附录

### Config 对象说明

创建/更新时可传入的 `config` 扩展配置字段：

| 字段名 | 类型 | 必选 | 默认值 | 说明 |
|--------|------|------|--------|------|
| `timeout` | Integer | 否 | 30 | 超时时间（秒），范围 5-300 |
| `retries` | Integer | 否 | 3 | 失败重试次数，范围 0-5 |
| `callback` | String | 否 | — | 回调 URL，需为合法 HTTPS 地址 |

### 速率限制

| 接口类型 | 限制 |
|---------|------|
| 查询类（GET） | 200 次/分钟 |
| 写入类（POST/PUT/DELETE） | 60 次/分钟 |

超出限制返回 HTTP 429，响应头中包含：
- `X-RateLimit-Limit`：限制次数
- `X-RateLimit-Remaining`：剩余次数
- `X-RateLimit-Reset`：重置时间（Unix 时间戳）
