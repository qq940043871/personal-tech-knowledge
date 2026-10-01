# RabbitMQ 从零理解 - 架构师学习笔记

> 定位:原理层图文,与《17年技术经验总结/07-消息中间件/02-RabbitMQ实战》(Spring Boot 集成与生产案例)互补。

## 一、AMQP 全链路:一条消息走过的路

```
生产者 ──publish──▶ Exchange ──routing──▶ Queue(s) ──push──▶ 消费者
              (绑定 Binding: routing key 匹配规则)
```

RabbitMQ 与 Kafka 最大的差异在这一步:**Exchange 路由**。生产者不直接发队列,而是发给交换机,由绑定规则决定进哪些队列——这是它"路由灵活"的根源。

## 二、四种 Exchange,一张图记住

```
① Direct(直连)      routing key 精确匹配
   ──[order.paid]──▶ Exchange ──key=order.paid──▶ 队列1

② Topic(主题)       通配符匹配:* 一段、# 多段
   ──[order.paid.vip]──▶ Exchange ──key=order.#──▶ 队列1
                                   ──key=*.paid.*──▶ 队列2

③ Fanout(广播)      忽略 routing key,复制到所有绑定队列
   ──▶ Exchange ──▶ 队列1 / 队列2 / 队列3 (各一份)

④ Headers(头匹配)   按消息头属性匹配,少用
```

记忆:**Direct 点对点、Topic 带规则订阅、Fanout 全员广播**。业务事件驱动系统常用 Topic。

## 三、消息会丢在哪?三个环节与对策

```
① 生产者 → Broker     ② Broker 内部          ③ Broker → 消费者
   publisher confirm      队列/消息持久化          basicAck 手动确认
   (异步确认回调)          (durable + delivery_mode=2)
   失败:重试 / 落库补偿     集群:镜像/仲裁队列副本     失败:nack 重回队列 / 死信
```

| 环节 | 不开的后果 | 开启方式 |
|---|---|---|
| confirm | Broker 收到前丢失无感知 | `publisher-confirm-type: correlated` |
| 持久化 | Broker 重启消息全丢 | 交换机/队列 `durable`,消息 `delivery_mode=2` |
| 手动 ack | 消费者崩了消息已丢 | `acknowledge-mode: manual`,处理完再 ack |

要点:**三者是链路关系,缺一环链路就不可靠**;开 confirm 后生产者是异步回调,不要用同步等待方式硬扛吞吐。

## 四、死信队列与延迟队列

死信(消息变成 DLX 的三种情况):

```
① 消费端 nack/reject 且 requeue=false
② 消息 TTL 过期
③ 队列达到最大长度,最早的被挤出
```

```
业务队列 ──死信──▶ DLX(死信交换机) ──▶ 死信队列 ──▶ 人工/补偿消费者
```

**用 TTL + 死信实现延迟队列**(RabbitMQ 原生不支持延迟):

```
生产者 ──▶ 延迟队列(TTL=30min, 无消费者) ──过期──▶ DLX ──▶ 真实消费队列
```

坑:队列头部阻塞——同队列里 10min 的消息会挡住 5min 的;大量分级延迟需用 `rabbitmq_delayed_message_exchange` 插件。

## 五、集群:普通集群、镜像队列与仲裁队列

| 模式 | 数据分布 | 缺点 |
|---|---|---|
| 普通集群 | 元数据共享,消息只在本节点 | 节点挂了,其上的消息不可用 |
| 镜像队列(经典) | leader-follower 同步复制 | 同步开销大, Erlang 集群脑裂风险 |
| **仲裁队列(Quorum,推荐)** | 基于 Raft 多数派 | 3.8+ 才有,资源占用略高 |

理解 Quorum:写入需多数节点确认才返回——用吞吐换强可用,与 Kafka 的 ISR 思想同源。

## 六、与 Kafka 的心智模型差异

```
RabbitMQ:推模型,消息是"包裹",消费掉就没了,Exchange 负责分拣
Kafka  :拉模型,消息是"日志",消费完还在(可回溯),分区负责并行
```

由此派生:RabbitMQ 适合复杂路由 + 及时处理的业务链路;Kafka 适合大吞吐 + 多消费方各自回放的数据流。

## 延伸阅读:实战经验笔记

- [RabbitMQ 实战(Spring Boot 集成/常见问题)](../../../07-消息中间件/02-RabbitMQ实战.md)
- [消息可靠性与顺序性](../../../07-消息中间件/04-消息可靠性与顺序性.md)
