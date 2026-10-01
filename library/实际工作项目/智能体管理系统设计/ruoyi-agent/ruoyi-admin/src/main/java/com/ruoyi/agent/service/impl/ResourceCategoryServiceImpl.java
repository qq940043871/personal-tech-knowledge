package com.ruoyi.agent.service.impl;

import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import com.ruoyi.agent.domain.ResourceCategory;
import com.ruoyi.agent.mapper.ResourceCategoryMapper;
import com.ruoyi.agent.service.IResourceCategoryService;

/**
 * 资源分类Service业务层处理
 */
@Service
public class ResourceCategoryServiceImpl implements IResourceCategoryService
{
    @Autowired
    private ResourceCategoryMapper resourceCategoryMapper;

    @Override
    public List<ResourceCategory> selectResourceCategoryList(ResourceCategory resourceCategory)
    {
        return resourceCategoryMapper.selectResourceCategoryList(resourceCategory);
    }

    @Override
    public ResourceCategory selectResourceCategoryById(Long categoryId)
    {
        return resourceCategoryMapper.selectResourceCategoryById(categoryId);
    }

    @Override
    public List<ResourceCategory> selectResourceCategoryTree()
    {
        return resourceCategoryMapper.selectResourceCategoryTree();
    }

    @Override
    public int insertResourceCategory(ResourceCategory resourceCategory)
    {
        return resourceCategoryMapper.insertResourceCategory(resourceCategory);
    }

    @Override
    public int updateResourceCategory(ResourceCategory resourceCategory)
    {
        return resourceCategoryMapper.updateResourceCategory(resourceCategory);
    }

    @Override
    public int deleteResourceCategoryById(Long categoryId)
    {
        return resourceCategoryMapper.deleteResourceCategoryById(categoryId);
    }
}
