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
import com.ruoyi.agent.domain.DigitalResource;
import com.ruoyi.agent.service.IDigitalResourceService;

/**
 * 数字资源Controller
 */
@RestController
@RequestMapping("/agent/resource")
public class DigitalResourceController extends BaseController
{
    @Autowired
    private IDigitalResourceService digitalResourceService;

    @PreAuthorize("@ss.hasPermi('agent:resource:list')")
    @GetMapping("/list")
    public TableDataInfo list(DigitalResource digitalResource)
    {
        startPage();
        List<DigitalResource> list = digitalResourceService.selectDigitalResourceList(digitalResource);
        return getDataTable(list);
    }

    @PreAuthorize("@ss.hasPermi('agent:resource:query')")
    @GetMapping(value = "/{resourceId}")
    public AjaxResult getInfo(@PathVariable("resourceId") Long resourceId)
    {
        return AjaxResult.success(digitalResourceService.selectDigitalResourceById(resourceId));
    }

    @PreAuthorize("@ss.hasPermi('agent:resource:add')")
    @Log(title = "数字资源", businessType = BusinessType.INSERT)
    @PostMapping
    public AjaxResult add(@RequestBody DigitalResource digitalResource)
    {
        return toAjax(digitalResourceService.insertDigitalResource(digitalResource));
    }

    @PreAuthorize("@ss.hasPermi('agent:resource:edit')")
    @Log(title = "数字资源", businessType = BusinessType.UPDATE)
    @PutMapping
    public AjaxResult edit(@RequestBody DigitalResource digitalResource)
    {
        return toAjax(digitalResourceService.updateDigitalResource(digitalResource));
    }

    @PreAuthorize("@ss.hasPermi('agent:resource:remove')")
    @Log(title = "数字资源", businessType = BusinessType.DELETE)
    @DeleteMapping("/{resourceIds}")
    public AjaxResult remove(@PathVariable Long[] resourceIds)
    {
        return toAjax(digitalResourceService.deleteDigitalResourceByIds(resourceIds));
    }
}
