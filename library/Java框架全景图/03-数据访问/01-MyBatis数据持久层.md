# MyBatis

> 模块：数据访问框架
> 更新时间：2026-03-29

---

## 一、框架介绍

MyBatis是优秀的持久层框架，它消除了几乎所有的JDBC代码和手动设置参数以及获取结果集的工作。MyBatis通过XML或注解配置SQL语句，将它们与业务代码分离。

**官网**：[https://mybatis.org](https://mybatis.org)
**GitHub**：[https://github.com/mybatis/mybatis-3](https://github.com/mybatis/mybatis-3)

**核心优势**：
- SQL与Java代码分离
- 可维护性强
- 支持动态SQL
- 支持XML和注解两种配置方式
- 性能优秀

---

## 二、快速开始

### 1. Maven依赖

```xml
<dependencies>
    <dependency>
        <groupId>org.mybatis.spring.boot</groupId>
        <artifactId>mybatis-spring-boot-starter</artifactId>
        <version>3.0.3</version>
    </dependency>
    
    <dependency>
        <groupId>com.mysql</groupId>
        <artifactId>mysql-connector-j</artifactId>
    </dependency>
</dependencies>
```

### 2. 配置

```yaml
mybatis:
  mapper-locations: classpath:mapper/*.xml
  type-aliases-package: com.example.entity
  configuration:
    map-underscore-to-camel-case: true
    log-impl: org.apache.ibatis.logging.stdout.StdOutImpl
```

### 3. 实体类

```java
@Data
@TableName("t_user")
public class User {
    private Long id;
    private String name;
    private Integer age;
    private String email;
    private LocalDateTime createTime;
}
```

---

## 三、实际业务应用场景

### 场景1：基础CRUD操作

**Mapper接口**：
```java
@Mapper
public interface UserMapper {
    
    @Select("SELECT * FROM t_user WHERE id = #{id}")
    User getById(Long id);
    
    @Select("SELECT * FROM t_user WHERE name = #{name}")
    List<User> getByName(String name);
    
    @Insert("INSERT INTO t_user(name, age, email) VALUES(#{name}, #{age}, #{email})")
    @Options(useGeneratedKeys = true, keyProperty = "id")
    int insert(User user);
    
    @Update("UPDATE t_user SET name=#{name}, age=#{age}, email=#{email} WHERE id=#{id}")
    int update(User user);
    
    @Delete("DELETE FROM t_user WHERE id = #{id}")
    int delete(Long id);
}
```

### 场景2：复杂查询（XML配置）

**XML映射文件**：
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN"
    "http://mybatis.org/dtd/mybatis-3-mapper.dtd">

<mapper namespace="com.example.mapper.UserMapper">
    
    <resultMap id="BaseResultMap" type="User">
        <id column="id" property="id"/>
        <result column="name" property="name"/>
        <result column="age" property="age"/>
        <result column="email" property="email"/>
        <result column="create_time" property="createTime"/>
    </resultMap>
    
    <!-- 动态SQL - 条件查询 -->
    <select id="searchUsers" resultMap="BaseResultMap">
        SELECT * FROM t_user
        <where>
            <if test="name != null and name != ''">
                AND name LIKE CONCAT('%', #{name}, '%')
            </if>
            <if test="minAge != null">
                AND age &gt;= #{minAge}
            </if>
            <if test="maxAge != null">
                AND age &lt;= #{maxAge}
            </if>
            <if test="email != null">
                AND email = #{email}
            </if>
        </where>
        ORDER BY create_time DESC
    </select>
    
    <!-- 分页查询 -->
    <select id="pageQuery" resultMap="BaseResultMap">
        SELECT * FROM t_user
        <where>
            <if test="name != null">
                AND name LIKE CONCAT('%', #{name}, '%')
            </if>
        </where>
        ORDER BY id DESC
        LIMIT #{offset}, #{pageSize}
    </select>
    
    <!-- 批量插入 -->
    <insert id="batchInsert" useGeneratedKeys="true" keyProperty="id">
        INSERT INTO t_user(name, age, email) VALUES
        <foreach collection="list" item="item" separator=",">
            (#{item.name}, #{item.age}, #{item.email})
        </foreach>
    </insert>
    
    <!-- 批量更新 -->
    <update id="batchUpdate">
        <foreach collection="list" item="item">
            UPDATE t_user SET 
                name = #{item.name},
                age = #{item.age}
            WHERE id = #{item.id};
        </foreach>
    </update>
    
    <!-- 一对一关联查询 -->
    <resultMap id="OrderDetailMap" type="Order">
        <id column="id" property="id"/>
        <result column="user_id" property="userId"/>
        <result column="total_amount" property="totalAmount"/>
        <association property="user" javaType="User">
            <id column="user_id" property="id"/>
            <result column="user_name" property="name"/>
            <result column="user_email" property="email"/>
        </association>
    </resultMap>
    
    <select id="getOrderDetail" resultMap="OrderDetailMap">
        SELECT o.id, o.user_id, o.total_amount,
               u.name as user_name, u.email as user_email
        FROM t_order o
        LEFT JOIN t_user u ON o.user_id = u.id
        WHERE o.id = #{orderId}
    </select>
    
    <!-- 一对多关联查询 -->
    <resultMap id="UserOrdersMap" type="User">
        <id column="id" property="id"/>
        <result column="name" property="name"/>
        <collection property="orders" ofType="Order">
            <id column="order_id" property="id"/>
            <result column="total_amount" property="totalAmount"/>
        </collection>
    </resultMap>
    
    <select id="getUserWithOrders" resultMap="UserOrdersMap">
        SELECT u.id, u.name, o.id as order_id, o.total_amount
        FROM t_user u
        LEFT JOIN t_order o ON u.id = o.user_id
        WHERE u.id = #{userId}
    </select>
</mapper>
```

### 场景3：动态SQL实战

```java
// 动态更新
@Update("<script>" +
       "UPDATE t_user SET " +
       "<if test='name != null'>name = #{name},</if>" +
       "<if test='age != null'>age = #{age},</if>" +
       "<if test='email != null'>email = #{email},</if>" +
       "update_time = NOW() " +
       "WHERE id = #{id}" +
       "</script>")
int dynamicUpdate(User user);

// 条件查询
List<User> searchUsers(UserSearchQuery query);

// 多条件组合查询
@Select("<script>" +
       "SELECT * FROM t_user " +
       "<where>" +
       "  <choose>" +
       "    <when test='type == 1'>AND age &gt;= 18</when>" +
       "    <when test='type == 2'>AND age &lt; 18</when>" +
       "    <otherwise>1=1</otherwise>" +
       "  </choose>" +
       "  <if test='keyword != null'>AND (name LIKE CONCAT('%', #{keyword}, '%') OR email LIKE CONCAT('%', #{keyword}, '%'))</if>" +
       "</where>" +
       "</script>")
List<User> complexSearch(@Param("type") Integer type, 
                         @Param("keyword") String keyword);
```

---

## 四、MyBatis-Plus增强

MyBatis-Plus是MyBatis的增强工具，提供了更便捷的CRUD操作。

```java
// 引入依赖
<dependency>
    <groupId>com.baomidou</groupId>
    <artifactId>mybatis-plus-spring-boot3-starter</artifactId>
    <version>3.5.5</version>
</dependency>
```

```java
// Mapper继承BaseMapper，无需编写基础CRUD
@Mapper
public interface UserMapper extends BaseMapper<User> {
    // 自动获得：insert, delete, update, selectById等方法
}

// Service继承IService
public interface UserService extends IService<User> {
}

@Service
public class UserServiceImpl extends ServiceImpl<UserMapper, User> 
    implements UserService {
    // 自动获得大量CRUD方法
}

// 分页查询
@Autowired
private UserMapper userMapper;

public IPage<User> getUserPage(Integer pageNum, Integer pageSize) {
    return userMapper.selectPage(
        new Page<>(pageNum, pageSize),
        new LambdaQueryWrapper<User>()
            .like(User::getName, keyword)
            .ge(User::getAge, minAge)
            .orderByDesc(User::getCreateTime)
    );
}

// 逻辑删除
@Bean
public MybatisPlusInterceptor mybatisPlusInterceptor() {
    MybatisPlusInterceptor interceptor = new MybatisPlusInterceptor();
    interceptor.addInnerInterceptor(new LogicalDeleteInnerInterceptor());
    return interceptor;
}
```

---

## 五、总结

MyBatis是Java数据访问层最流行的框架，配合MyBatis-Plus使用可以极大提升开发效率。

**学习要点**：
1. 掌握SQL映射文件的编写
2. 熟练使用动态SQL
3. 理解ResultMap关联查询
4. 掌握MyBatis-Plus的CRUD操作
5. 了解分页插件和逻辑删除

---

*下一步：Redis缓存框架*
