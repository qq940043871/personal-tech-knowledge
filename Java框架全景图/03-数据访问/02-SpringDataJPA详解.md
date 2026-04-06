# Spring Data JPA

> 模块：数据访问框架
> 更新时间：2026-03-29

---

## 一、框架介绍

Spring Data JPA是Spring Data系列的一部分，对JPA（Java Persistence API）进行了封装，提供 Repository 抽象层。

**核心特性**：
- 自动生成CRUD方法
- 自动实现分页和排序
- 自定义查询方法命名规则
- 支持@Query自定义SQL

---

## 二、实际业务应用场景

### 场景1：Repository定义

```java
// 1. 定义Repository
public interface UserRepository extends JpaRepository<User, Long> {
    
    // 方法命名查询 - 自动实现
    Optional<User> findByUsername(String username);
    
    List<User> findByEmailContaining(String email);
    
    List<User> findByAgeBetween(Integer minAge, Integer maxAge);
    
    @Query("SELECT u FROM User u WHERE u.status = :status ORDER BY u.createTime DESC")
    List<User> findByStatus(@Param("status") Integer status);
    
    @Query(value = "SELECT * FROM t_user WHERE age > :age LIMIT :limit", 
           nativeQuery = true)
    List<User> findByAgeLimit(@Param("age") Integer age, @Param("limit") Integer limit);
}

// 2. 分页查询
@Service
public class UserService {
    
    @Autowired
    private UserRepository userRepository;
    
    public Page<User> getUserPage(Integer page, Integer size, String keyword) {
        Pageable pageable = PageRequest.of(page - 1, size, 
            Sort.by(Sort.Direction.DESC, "createTime"));
        
        if (StringUtils.hasText(keyword)) {
            return userRepository.findByEmailContaining(keyword, pageable);
        }
        
        return userRepository.findAll(pageable);
    }
}
```

### 场景2：复杂查询Specification

```java
public Specification<User> buildSpecification(UserQuery query) {
    return (root, criteriaQuery, criteriaBuilder) -> {
        List<Predicate> predicates = new ArrayList<>();
        
        if (StringUtils.hasText(query.getName())) {
            predicates.add(criteriaBuilder.like(root.get("name"), 
                "%" + query.getName() + "%"));
        }
        
        if (query.getMinAge() != null) {
            predicates.add(criteriaBuilder.ge(root.get("age"), query.getMinAge()));
        }
        
        if (query.getStatus() != null) {
            predicates.add(criteriaBuilder.equal(root.get("status"), query.getStatus()));
        }
        
        return criteriaBuilder.and(predicates.toArray(new Predicate[0]));
    };
}

public List<User> searchUsers(UserQuery query) {
    Specification<User> spec = buildSpecification(query);
    return userRepository.findAll(spec);
}
```

---

## 三、总结

Spring Data JPA适合快速开发，但MyBatis在复杂业务场景下更灵活。

---

*下一步：Hibernate ORM*
