# Elasticsearch

> 模块：搜索引擎
> 更新时间：2026-03-29

---

## 一、框架介绍

Elasticsearch是一个基于Lucene的分布式全文搜索引擎，提供RESTful API，支持海量数据存储和全文检索。它是ELK（Elasticsearch、Logstash、Kibana）日志分析系统的核心组件。

**官网**：[https://www.elastic.co/elasticsearch](https://www.elastic.co/elasticsearch)

**核心特点**：
- 全文检索
- 分布式架构
- 实时索引
- RESTful API
- 聚合分析

---

## 二、核心概念

```
Elasticsearch概念：
  - Index（索引）：相当于数据库
  - Document（文档）：相当于表记录
  - Type（类型）：已废弃（原相当于表）
  - Mapping（映射）：相当于表结构
  
  与MySQL对比：
  MySQL → Database → Table → Row → Column
  ES    → Index    → (无)   → Doc  → Field
```

---

## 三、实际业务应用场景

### 场景1：商品搜索

```java
// 1. 定义文档实体
@Data
@Document(indexName = "products")
public class ProductDocument {
    
    @Id
    private String id;
    
    @Field(type = FieldType.Text, analyzer = "ik_max_word")
    private String name;
    
    @Field(type = FieldType.Text, analyzer = "ik_max_word")
    private String description;
    
    @Field(type = FieldType.Keyword)
    private String category;
    
    @Field(type = FieldType.Keyword)
    private String brand;
    
    @Field(type = FieldType.Double)
    private Double price;
    
    @Field(type = FieldType.Integer)
    private Integer stock;
    
    @Field(type = FieldType.Date)
    private LocalDateTime createTime;
}

// 2. Repository接口
@Repository
public interface ProductSearchRepository extends ElasticsearchRepository<ProductDocument, String> {
    
    List<ProductDocument> findByNameContaining(String name);
    
    List<ProductDocument> findByCategoryAndPriceBetween(String category, 
        Double minPrice, Double maxPrice);
}

// 3. 搜索服务
@Service
public class ProductSearchService {
    
    @Autowired
    private ProductSearchRepository searchRepository;
    
    @Autowired
    private ElasticsearchOperations elasticsearchOperations;
    
    // 添加商品到索引
    public void indexProduct(Product product) {
        ProductDocument doc = convertToDocument(product);
        searchRepository.save(doc);
    }
    
    // 全文搜索
    public List<ProductDocument> search(String keyword) {
        Query query = new StringQuery("{\"match\":{\"name\":\"" + keyword + "\"}}");
        return elasticsearchOperations.search(query, ProductDocument.class)
            .getSearchHits()
            .stream()
            .map(SearchHit::getContent)
            .collect(Collectors.toList());
    }
    
    // 复杂搜索
    public SearchPage<ProductDocument> complexSearch(ProductSearchQuery query) {
        NativeQuery.Builder queryBuilder = NativeQuery.builder();
        
        // 关键词搜索
        if (StringUtils.hasText(query.getKeyword())) {
            queryBuilder.withQuery(q -> q
                .multiMatch(m -> m
                    .query(query.getKeyword())
                    .fields("name^2", "description")
                )
            );
        }
        
        // 分类过滤
        if (StringUtils.hasText(query.getCategory())) {
            queryBuilder.withFilter(f -> f
                .term(t -> t.field("category").value(query.getCategory()))
            );
        }
        
        // 价格区间
        if (query.getMinPrice() != null || query.getMaxPrice() != null) {
            queryBuilder.withFilter(f -> f
                .range(r -> {
                    RangeQueryBuilder range = r.field("price");
                    if (query.getMinPrice() != null) {
                        range.gte(query.getMinPrice());
                    }
                    if (query.getMaxPrice() != null) {
                        range.lte(query.getMaxPrice());
                    }
                    return range;
                })
            );
        }
        
        // 排序
        if ("price".equals(query.getSortField())) {
            queryBuilder.withSort(s -> s
                .field(f -> f.field("price")
                    .order(query.isAsc() ? SortOrder.Asc : SortOrder.Desc))
            );
        }
        
        // 分页
        queryBuilder.withPageable(PageRequest.of(
            query.getPage() - 1, query.getSize()));
        
        return elasticsearchOperations.searchForPage(
            queryBuilder.build(), ProductDocument.class);
    }
}
```

### 场景2：全文搜索+高亮

```java
public List<SearchResult> searchWithHighlight(String keyword, int page, int size) {
    NativeQuery query = NativeQuery.builder()
        .withQuery(q -> q
            .multiMatch(m -> m
                .query(keyword)
                .fields("title^3", "content")
            )
        )
        .withHighlightQuery(new HighlightQuery(
            new TextQueryStringHighlightBuilder()
                .setPreTags("<em>")
                .setPostTags("</em>")
                .setFields(
                    new HighlightField("title"),
                    new HighlightField("content")
                ),
            null
        ))
        .withPageable(PageRequest.of(page, size))
        .build();
    
    SearchHits<Article> hits = elasticsearchOperations.search(
        query, Article.class);
    
    return hits.getSearchHits().stream()
        .map(hit -> {
            SearchResult result = new SearchResult();
            result.setArticle(hit.getContent());
            result.setHighlights(hit.getHighlightFields());
            return result;
        })
        .collect(Collectors.toList());
}
```

### 场景3：聚合分析

```java
public Map<String, Long> aggregateByCategory() {
    NativeQuery query = NativeQuery.builder()
        .withQuery(q -> q.matchAll(m -> m))
        .withAggregation("category_agg", 
            a -> a.terms(t -> t.field("category").size(100)))
        .build();
    
    SearchHits<ProductDocument> hits = 
        elasticsearchOperations.search(query, ProductDocument.class);
    
    Map<String, Long> result = new HashMap<>();
    StringTermsAggContainer aggregation = 
        hits.getAggregations().get("category_agg");
    
    aggregation.forEachBucket(bucket -> 
        result.put(bucket.getKey().toString(), bucket.getDocCount()));
    
    return result;
}

// 价格统计
public PriceStats getPriceStats(String category) {
    NativeQuery query = NativeQuery.builder()
        .withQuery(q -> q.term(t -> t.field("category").value(category)))
        .withAggregation("price_stats",
            a -> a.stats(s -> s.field("price")))
        .build();
    
    SearchHits<ProductDocument> hits = 
        elasticsearchOperations.search(query, ProductDocument.class);
    
    Stats stats = hits.getAggregations().get("price_stats");
    
    return new PriceStats(stats.getMin(), stats.getMax(), 
        stats.getAvg(), stats.getSum(), stats.getCount());
}
```

---

## 四、Spring Boot整合

```yaml
spring:
  elasticsearch:
    uris: http://localhost:9200
    username: elastic
    password: password
```

---

## 五、总结

Elasticsearch是实现全文搜索的首选方案，配合Spring Data Elasticsearch可以快速集成。

**学习要点**：
1. 理解倒排索引原理
2. 掌握Mapping设计
3. 熟练使用各种查询
4. 理解聚合分析
5. 了解分片和副本机制

---

*下一步：Docker容器化*
