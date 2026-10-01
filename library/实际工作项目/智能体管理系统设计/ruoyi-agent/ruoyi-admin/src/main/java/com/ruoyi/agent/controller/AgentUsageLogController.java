package com.ruoyi.agent.controller;

import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.agent.domain.AgentUsageLog;
import com.ruoyi.agent.service.IAgentUsageLogService;

/**
 * 使用日志Controller
 */
@RestController
@RequestMapping("/agent/log")
public class AgentUsageLogController extends BaseController
{
    @Autowired
    private IAgentUsageLogService agentUsageLogService;

    @PreAuthorize("@ss.hasPermi('agent:log:list')")
    @GetMapping("/list")
    public TableDataInfo list(AgentUsageLog agentUsageLog)
    {
        startPage();
        List<AgentUsageLog> list = agentUsageLogService.selectAgentUsageLogList(agentUsageLog);
        return getDataTable(list);
    }

    @PreAuthorize("@ss.hasPermi('agent:log:query')")
    @GetMapping(value = "/{logId}")
    public AjaxResult getInfo(@PathVariable("logId") Long logId)
    {
        return AjaxResult.success(agentUsageLogService.selectAgentUsageLogById(logId));
    }

    @PreAuthorize("@ss.hasPermi('agent:log:stats')")
    @GetMapping("/stats")
    public AjaxResult stats()
    {
        Map<String, Object> stats = agentUsageLogService.selectLogStats();
        return AjaxResult.success(stats);
    }
}
