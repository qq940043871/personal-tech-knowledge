package com.ruoyi.agent.controller;

import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.agent.domain.ResourceCategory;
import com.ruoyi.agent.service.IResourceCategoryService;

/**
 * 资源分类Controller
 */
@RestController
@RequestMapping("/agent/category")
public class ResourceCategoryController extends BaseController
{
    @Autowired
    private IResourceCategoryService resourceCategoryService;

    @PreAuthorize("@ss.hasPermi('agent:category:list')")
    @GetMapping("/list")
    public TableDataInfo list(ResourceCategory resourceCategory)
    {
        startPage();
        List<ResourceCategory> list = resourceCategoryService.selectResourceCategoryList(resourceCategory);
        return getDataTable(list);
    }

    @PreAuthorize("@ss.hasPermi('agent:category:list')")
    @GetMapping("/tree")
    public AjaxResult tree()
    {
        List<ResourceCategory> list = resourceCategoryService.selectResourceCategoryTree();
        return AjaxResult.success(list);
    }

    @PreAuthorize("@ss.hasPermi('agent:category:query')")
    @GetMapping(value = "/{categoryId}")
    public AjaxResult getInfo(@PathVariable("categoryId") Long categoryId)
    {
        return AjaxResult.success(resourceCategoryService.selectResourceCategoryById(categoryId));
    }

    @PreAuthorize("@ss.hasPermi('agent:category:add')")
    @Log(title = "资源分类", businessType = BusinessType.INSERT)
    @PostMapping
    public AjaxResult add(@RequestBody ResourceCategory resourceCategory)
    {
        return toAjax(resourceCategoryService.insertResourceCategory(resourceCategory));
    }

    @PreAuthorize("@ss.hasPermi('agent:category:edit')")
    @Log(title = "资源分类", businessType = BusinessType.UPDATE)
    @PutMapping
    public AjaxResult edit(@RequestBody ResourceCategory resourceCategory)
    {
        return toAjax(resourceCategoryService.updateResourceCategory(resourceCategory));
    }

    @PreAuthorize("@ss.hasPermi('agent:category:remove')")
    @Log(title = "资源分类", businessType = BusinessType.DELETE)
    @DeleteMapping("/{categoryId}")
    public AjaxResult remove(@PathVariable Long categoryId)
    {
        return toAjax(resourceCategoryService.deleteResourceCategoryById(categoryId));
    }
}
