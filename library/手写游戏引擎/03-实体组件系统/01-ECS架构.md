# ECS架构

> 模块：实体组件系统
> 更新时间：2026-03-29

---

## 一、ECS概述

```
ECS三要素：
  1. Entity（实体）
     - 唯一ID
     - 无数据，只有组件容器
     
  2. Component（组件）
     - 数据容器
     - 无逻辑
     
  3. System（系统）
     - 处理逻辑
     - 操作特定组件组合

优势：
  - 数据局部性好，缓存友好
  - 组合优于继承
  - 并行处理简单
```

---

## 二、C++实现

```cpp
// 实体：只是一个ID
using Entity = uint32_t;
const Entity INVALID_ENTITY = 0;

// 组件基类
struct IComponent {
    virtual ~IComponent() = default;
    static ComponentType getStaticType() { return -1; }
};

// 实体管理器
class EntityManager {
private:
    std::vector<Entity> entities;
    std::queue<Entity> available;
    size_t entityCount = 0;
    
public:
    Entity create() {
        if (!available.empty()) {
            Entity e = available.front();
            available.pop();
            return e;
        }
        return ++entityCount;
    }
    
    void destroy(Entity e) {
        available.push(e);
    }
};

// 组件数组（稀疏集）
template<typename T>
class ComponentArray {
private:
    std::unordered_map<Entity, T> components;
    
public:
    void insert(Entity e, const T& component) {
        components[e] = component;
    }
    
    void remove(Entity e) {
        components.erase(e);
    }
    
    T* get(Entity e) {
        auto it = components.find(e);
        return it != components.end() ? &it->second : nullptr;
    }
    
    bool has(Entity e) {
        return components.find(e) != components.end();
    }
};
```

---

## 三、World管理器

```cpp
class ECSWorld {
private:
    EntityManager entityManager;
    
    // 所有组件数组
    ComponentArray<TransformComponent> transforms;
    ComponentArray<RenderComponent> renders;
    ComponentArray<RigidBodyComponent> rigidBodies;
    ComponentArray<ColliderComponent> colliders;
    
    // 系统列表
    std::vector<ISystem*> systems;
    
public:
    // 实体操作
    Entity createEntity() {
        return entityManager.create();
    }
    
    void destroyEntity(Entity e) {
        entityManager.destroy(e);
        transforms.remove(e);
        renders.remove(e);
        rigidBodies.remove(e);
        colliders.remove(e);
    }
    
    // 组件操作
    template<typename T>
    T* addComponent(Entity e, const T& component) {
        auto& arr = getComponentArray<T>();
        arr.insert(e, component);
        return &arr.get(e);
    }
    
    template<typename T>
    T* getComponent(Entity e) {
        return getComponentArray<T>().get(e);
    }
    
    // 系统更新
    void update(double dt) {
        for (auto* system : systems) {
            system->update(this, dt);
        }
    }
};
```

---

*下一步：实体管理*
