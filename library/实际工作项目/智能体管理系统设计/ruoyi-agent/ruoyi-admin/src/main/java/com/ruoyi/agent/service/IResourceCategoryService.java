package com.ruoyi.agent.service;

import java.util.List;
import com.ruoyi.agent.domain.ResourceCategory;

/**
 * 资源分类Service接口
 */
public interface IResourceCategoryService
{
    public List<ResourceCategory> selectResourceCategoryList(ResourceCategory resourceCategory);
    public ResourceCategory selectResourceCategoryById(Long categoryId);
    public List<ResourceCategory> selectResourceCategoryTree();
    public int insertResourceCategory(ResourceCategory resourceCategory);
    public int updateResourceCategory(ResourceCategory resourceCategory);
    public int deleteResourceCategoryById(Long categoryId);
}
