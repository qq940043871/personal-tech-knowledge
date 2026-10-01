package com.ruoyi.agent.mapper;

import java.util.List;
import com.ruoyi.agent.domain.ResourceCategory;

/**
 * 资源分类Mapper接口
 */
public interface ResourceCategoryMapper
{
    public List<ResourceCategory> selectResourceCategoryList(ResourceCategory resourceCategory);
    public ResourceCategory selectResourceCategoryById(Long categoryId);
    public List<ResourceCategory> selectResourceCategoryTree();
    public int insertResourceCategory(ResourceCategory resourceCategory);
    public int updateResourceCategory(ResourceCategory resourceCategory);
    public int deleteResourceCategoryById(Long categoryId);
}
