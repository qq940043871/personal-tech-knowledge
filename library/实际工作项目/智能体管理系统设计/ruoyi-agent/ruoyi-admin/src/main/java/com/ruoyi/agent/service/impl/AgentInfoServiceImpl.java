package com.ruoyi.agent.service.impl;

import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import com.ruoyi.agent.domain.AgentInfo;
import com.ruoyi.agent.mapper.AgentInfoMapper;
import com.ruoyi.agent.service.IAgentInfoService;

/**
 * 智能体信息Service业务层处理
 */
@Service
public class AgentInfoServiceImpl implements IAgentInfoService
{
    @Autowired
    private AgentInfoMapper agentInfoMapper;

    @Override
    public List<AgentInfo> selectAgentInfoList(AgentInfo agentInfo)
    {
        return agentInfoMapper.selectAgentInfoList(agentInfo);
    }

    @Override
    public AgentInfo selectAgentInfoById(Long agentId)
    {
        return agentInfoMapper.selectAgentInfoById(agentId);
    }

    @Override
    public int insertAgentInfo(AgentInfo agentInfo)
    {
        return agentInfoMapper.insertAgentInfo(agentInfo);
    }

    @Override
    public int updateAgentInfo(AgentInfo agentInfo)
    {
        return agentInfoMapper.updateAgentInfo(agentInfo);
    }

    @Override
    public int deleteAgentInfoByIds(Long[] agentIds)
    {
        return agentInfoMapper.deleteAgentInfoByIds(agentIds);
    }

    @Override
    public int deleteAgentInfoById(Long agentId)
    {
        return agentInfoMapper.deleteAgentInfoById(agentId);
    }
}
