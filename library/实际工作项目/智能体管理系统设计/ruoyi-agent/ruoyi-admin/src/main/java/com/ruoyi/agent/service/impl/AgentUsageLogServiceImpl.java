package com.ruoyi.agent.service.impl;

import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import com.ruoyi.agent.domain.AgentUsageLog;
import com.ruoyi.agent.mapper.AgentUsageLogMapper;
import com.ruoyi.agent.service.IAgentUsageLogService;

/**
 * 使用日志Service业务层处理
 */
@Service
public class AgentUsageLogServiceImpl implements IAgentUsageLogService
{
    @Autowired
    private AgentUsageLogMapper agentUsageLogMapper;

    @Override
    public List<AgentUsageLog> selectAgentUsageLogList(AgentUsageLog agentUsageLog)
    {
        return agentUsageLogMapper.selectAgentUsageLogList(agentUsageLog);
    }

    @Override
    public AgentUsageLog selectAgentUsageLogById(Long logId)
    {
        return agentUsageLogMapper.selectAgentUsageLogById(logId);
    }

    @Override
    public int insertAgentUsageLog(AgentUsageLog agentUsageLog)
    {
        return agentUsageLogMapper.insertAgentUsageLog(agentUsageLog);
    }

    @Override
    public Map<String, Object> selectLogStats()
    {
        return agentUsageLogMapper.selectLogStats();
    }
}
