package com.ruoyi.agent.service;

import java.util.List;
import com.ruoyi.agent.domain.AgentInfo;

/**
 * 智能体信息Service接口
 */
public interface IAgentInfoService
{
    public List<AgentInfo> selectAgentInfoList(AgentInfo agentInfo);
    public AgentInfo selectAgentInfoById(Long agentId);
    public int insertAgentInfo(AgentInfo agentInfo);
    public int updateAgentInfo(AgentInfo agentInfo);
    public int deleteAgentInfoByIds(Long[] agentIds);
    public int deleteAgentInfoById(Long agentId);
}
