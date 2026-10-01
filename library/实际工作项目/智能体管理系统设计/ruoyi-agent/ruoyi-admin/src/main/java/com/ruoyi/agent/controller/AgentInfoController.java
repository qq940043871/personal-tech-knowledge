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
import com.ruoyi.agent.domain.AgentInfo;
import com.ruoyi.agent.service.IAgentInfoService;

/**
 * 智能体信息Controller
 */
@RestController
@RequestMapping("/agent/info")
public class AgentInfoController extends BaseController
{
    @Autowired
    private IAgentInfoService agentInfoService;

    /**
     * 查询智能体列表
     */
    @PreAuthorize("@ss.hasPermi('agent:info:list')")
    @GetMapping("/list")
    public TableDataInfo list(AgentInfo agentInfo)
    {
        startPage();
        List<AgentInfo> list = agentInfoService.selectAgentInfoList(agentInfo);
        return getDataTable(list);
    }

    /**
     * 获取智能体详细信息
     */
    @PreAuthorize("@ss.hasPermi('agent:info:query')")
    @GetMapping(value = "/{agentId}")
    public AjaxResult getInfo(@PathVariable("agentId") Long agentId)
    {
        return AjaxResult.success(agentInfoService.selectAgentInfoById(agentId));
    }

    /**
     * 新增智能体
     */
    @PreAuthorize("@ss.hasPermi('agent:info:add')")
    @Log(title = "智能体信息", businessType = BusinessType.INSERT)
    @PostMapping
    public AjaxResult add(@RequestBody AgentInfo agentInfo)
    {
        return toAjax(agentInfoService.insertAgentInfo(agentInfo));
    }

    /**
     * 修改智能体
     */
    @PreAuthorize("@ss.hasPermi('agent:info:edit')")
    @Log(title = "智能体信息", businessType = BusinessType.UPDATE)
    @PutMapping
    public AjaxResult edit(@RequestBody AgentInfo agentInfo)
    {
        return toAjax(agentInfoService.updateAgentInfo(agentInfo));
    }

    /**
     * 删除智能体
     */
    @PreAuthorize("@ss.hasPermi('agent:info:remove')")
    @Log(title = "智能体信息", businessType = BusinessType.DELETE)
    @DeleteMapping("/{agentIds}")
    public AjaxResult remove(@PathVariable Long[] agentIds)
    {
        return toAjax(agentInfoService.deleteAgentInfoByIds(agentIds));
    }
}
