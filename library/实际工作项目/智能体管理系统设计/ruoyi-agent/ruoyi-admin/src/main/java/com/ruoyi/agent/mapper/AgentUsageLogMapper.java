package com.ruoyi.agent.mapper;

import java.util.List;
import java.util.Map;
import com.ruoyi.agent.domain.AgentUsageLog;

/**
 * 使用日志Mapper接口
 */
public interface AgentUsageLogMapper
{
    public List<AgentUsageLog> selectAgentUsageLogList(AgentUsageLog agentUsageLog);
    public AgentUsageLog selectAgentUsageLogById(Long logId);
    public int insertAgentUsageLog(AgentUsageLog agentUsageLog);
    public Map<String, Object> selectLogStats();
}
