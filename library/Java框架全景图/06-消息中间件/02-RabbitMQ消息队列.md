# RabbitMQ

> 模块：消息中间件
> 更新时间：2026-03-29

---

## 一、框架介绍

RabbitMQ是实现了AMQP协议的消息中间件，支持消息队列、路由、事务等功能。它是Java企业级应用中使用最广泛的消息队列之一。

**官网**：[https://www.rabbitmq.com](https://www.rabbitmq.com)

**核心概念**：
- **Producer**：消息生产者
- **Consumer**：消息消费者
- **Exchange**：交换机，路由消息
- **Queue**：队列，存储消息
- **Binding**：绑定，连接交换机和队列

---

## 二、Exchange类型

```
Exchange类型：
  1. Direct - 精确匹配路由键
  2. Fanout - 广播到所有队列
  3. Topic - 支持通配符匹配
  4. Headers - 根据消息头匹配
```

---

## 三、实际业务应用场景

### 场景1：异步订单处理

```java
// 1. 配置队列和交换机
@Configuration
public class RabbitMQConfig {
    
    public static final String ORDER_EXCHANGE = "order.exchange";
    public static final String ORDER_QUEUE = "order.queue";
    public static final String ORDER_ROUTING_KEY = "order.create";
    
    @Bean
    public DirectExchange orderExchange() {
        return new DirectExchange(ORDER_EXCHANGE);
    }
    
    @Bean
    public Queue orderQueue() {
        return QueueBuilder.durable(ORDER_QUEUE).build();
    }
    
    @Bean
    public Binding orderBinding(Queue orderQueue, DirectExchange orderExchange) {
        return BindingBuilder.bind(orderQueue)
            .to(orderExchange)
            .with(ORDER_ROUTING_KEY);
    }
}

// 2. 发送消息
@Service
public class OrderService {
    
    @Autowired
    private RabbitTemplate rabbitTemplate;
    
    public void createOrder(Order order) {
        // 保存订单
        orderMapper.insert(order);
        
        // 发送消息通知其他服务
        rabbitTemplate.convertAndSend(
            RabbitMQConfig.ORDER_EXCHANGE,
            RabbitMQConfig.ORDER_ROUTING_KEY,
            order
        );
    }
}

// 3. 消费消息
@Component
public class OrderConsumer {
    
    @Autowired
    private ProductService productService;
    
    @RabbitListener(queues = RabbitMQConfig.ORDER_QUEUE)
    public void handleOrderMessage(Order order) {
        // 扣减库存
        productService.deductStock(order.getProductId(), order.getQuantity());
        
        // 发送通知
        notificationService.sendOrderNotice(order);
    }
}
```

### 场景2：邮件发送

```java
// 1. 配置邮件队列
public static final String EMAIL_EXCHANGE = "email.exchange";
public static final String EMAIL_QUEUE = "email.queue";
public static final String EMAIL_ROUTING_KEY = "email.send";

// 2. 发送邮件请求
@Service
public class NotificationService {
    
    @Autowired
    private RabbitTemplate rabbitTemplate;
    
    public void sendEmail(String to, String subject, String content) {
        EmailMessage email = new EmailMessage(to, subject, content);
        
        // 发送消息到邮件队列
        rabbitTemplate.convertAndSend(
            RabbitMQConfig.EMAIL_EXCHANGE,
            RabbitMQConfig.EMAIL_ROUTING_KEY,
            email
        );
    }
}

// 3. 消费并发送邮件
@Component
public class EmailConsumer {
    
    @RabbitListener(queues = RabbitMQConfig.EMAIL_QUEUE)
    public void handleEmail(EmailMessage email) {
        // 实际发送邮件
        emailService.send(email.getTo(), email.getSubject(), email.getContent());
    }
}
```

### 场景3：Topic交换机-日志收集

```java
// 配置Topic交换机
@Bean
public TopicExchange logExchange() {
    return new TopicExchange("log.exchange");
}

@Bean
public Queue errorLogQueue() {
    return QueueBuilder.durable("log.error.queue").build();
}

@Bean
public Queue infoLogQueue() {
    return QueueBuilder.durable("log.info.queue").build();
}

@Bean
public Binding errorBinding(Queue errorLogQueue, TopicExchange logExchange) {
    // 匹配 error.* 的路由键
    return BindingBuilder.bind(errorLogQueue)
        .to(logExchange)
        .with("log.error.*");
}

@Bean
public Binding infoBinding(Queue infoLogQueue, TopicExchange logExchange) {
    // 匹配 info.* 和 warn.* 的路由键
    return BindingBuilder.bind(infoLogQueue)
        .to(logExchange)
        .with("log.{info,warn}");
}

// 发送日志
@Service
public class LogService {
    
    @Autowired
    private RabbitTemplate rabbitTemplate;
    
    public void logError(String module, String message) {
        rabbitTemplate.convertAndSend("log.exchange", 
            "log.error." + module, message);
    }
    
    public void logInfo(String module, String message) {
        rabbitTemplate.convertAndSend("log.exchange", 
            "log.info." + module, message);
    }
}
```

---

## 四、消息确认与补偿

```java
@Configuration
public class RabbitMQConfig {
    
    @Bean
    public RabbitTemplate rabbitTemplate(ConnectionFactory factory) {
        RabbitTemplate template = new RabbitTemplate(factory);
        
        // 确认模式
        template.setConfirmCallback((correlationData, ack, cause) -> {
            if (!ack) {
                // 消息发送失败，进行补偿
                System.out.println("消息发送失败: " + cause);
            }
        });
        
        // 返回模式
        template.setReturnsCallback(returned -> {
            System.out.println("消息未路由到队列: " + returned.getMessage());
        });
        
        return template;
    }
}

// 消费端确认
@Bean
public SimpleRabbitListenerContainerFactory rabbitListenerContainerFactory(
        ConnectionFactory factory) {
    SimpleRabbitListenerContainerFactory factory = new SimpleRabbitListenerContainerFactory();
    factory.setConnectionFactory(factory);
    factory.setAcknowledgeMode(AcknowledgeMode.MANUAL); // 手动确认
    return factory;
}

@RabbitListener(queues = RabbitMQConfig.ORDER_QUEUE)
public void handleOrder(Order order, Channel channel, 
                        @Header(AmqpHeaders.DELIVERY_TAG) long tag) {
    try {
        // 业务处理
        processOrder(order);
        
        // 手动确认
        channel.basicAck(tag, false);
    } catch (Exception e) {
        // 处理失败，拒绝并重新入队
        channel.basicNack(tag, false, true);
    }
}
```

---

## 五、总结

RabbitMQ是企业级应用消息队列的首选，Spring Boot的Spring AMQP让集成变得非常简单。

**学习要点**：
1. 理解AMQP协议和Exchange类型
2. 掌握消息发送和消费模式
3. 熟练使用Topic交换机
4. 理解消息确认机制
5. 了解死信队列和延迟队列

---

*下一步：Spring Security安全框架*
