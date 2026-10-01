# Nginx学习指南 - 总纲

> 作者：AI助手
> 更新日期：2026-03-29
> 版本：v1.0

---

## 📋 文档概述

Nginx是高性能HTTP服务器和反向代理服务器，同时也是IMAP/POP3/SMTP代理服务器。本文档将帮助你全面掌握Nginx的核心配置。

---

## 🗂️ 文档结构

```
Nginx学习指南/
│
├── 00-总览/
│   └── 00-Nginx总纲.md               ← 本文档
│
├── 01-基础配置/
│   ├── 01-Nginx安装与基本命令.md      ← 安装、启停命令
│   ├── 02-核心配置结构.md            ← nginx.conf结构
│   ├── 03-常用指令详解.md            ← listen、server_name等
│   └── 04-location匹配规则.md        ← 路径匹配优先级
│
├── 02-反向代理/
│   ├── 01-反向代理基础.md            ← proxy_pass配置
│   ├── 02-proxy_pass细节.md          ← 路径重写、协议头
│   └── 03-正向代理配置.md            ← 正向代理
│
├── 03-负载均衡/
│   ├── 01-负载均衡配置.md            ← upstream配置
│   ├── 02-负载均衡算法.md            ← 轮询、权重、IP哈希等
│   └── 03-健康检查配置.md            ← upstream心跳
│
├── 04-安全配置/
│   ├── 01-HTTPS配置.md              ← SSL证书配置
│   ├── 02-HSTS与安全头.md            ← 安全响应头
│   ├── 03-访问限制.md               ← IP黑白名单、限流
│   └── 04-HTTP2配置.md              ← HTTP/2配置
│
├── 05-跨域与缓存/
│   ├── 01-跨域配置CORS.md           ← 跨域资源共享
│   ├── 02-浏览器缓存配置.md         ← expires、etag
│   └── 03-代理缓存配置.md           ← proxy_cache
│
├── 06-高可用与优化/
│   ├── 01-Nginx+Keepalived.md       ← 主备高可用
│   ├── 02-性能优化配置.md           ← worker、连接数
│   └── 03-日志配置.md              ← access_log、error_log
│
└── 07-实战配置/
    ├── 01-前后端分离配置.md         ← SPA应用配置
    ├── 02-微服务网关配置.md         ← 多服务代理
    ├── 03-防盗链配置.md             ← 防止资源盗用
    └── 04-常用配置模板.md           ← 完整配置模板
```

---

## 🎯 核心知识点

| 分类 | 核心内容 |
|------|---------|
| **基础** | 安装、命令、配置结构、location |
| **反向代理** | proxy_pass、协议头、路径重写 |
| **负载均衡** | upstream、调度算法、健康检查 |
| **安全** | HTTPS、SSL、访问限制、安全头 |
| **跨域** | CORS、JSONP、 OPTIONS请求 |
| **缓存** | 浏览器缓存、代理缓存、CDN |
| **高可用** | Keepalived、性能优化 |

---

## 📊 应用场景

```
                    ┌─────────────────┐
                    │     Nginx       │
                    │  (反向代理/Gateway) │
                    └────────┬────────┘
                             │
         ┌─────────────────┼─────────────────┐
         │                 │                 │
         ▼                 ▼                 ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│  API Server │  │  API Server │  │  API Server │
│    Node1    │  │    Node2    │  │    Node3    │
└─────────────┘  └─────────────┘  └─────────────┘

典型场景：
1. Web服务器：静态资源托管
2. 反向代理：隐藏后端服务
3. 负载均衡：多服务器分发请求
4. API网关：统一入口、认证、限流
5. SSL终端：HTTPS加密卸载
```

---

## ⚡ 快速配置模板

```nginx
# 最简反向代理配置
server {
    listen 80;
    server_name example.com;
    
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

# 完整HTTPS反向代理
server {
    listen 443 ssl http2;
    server_name example.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

*下一步：Nginx安装与基本命令*
