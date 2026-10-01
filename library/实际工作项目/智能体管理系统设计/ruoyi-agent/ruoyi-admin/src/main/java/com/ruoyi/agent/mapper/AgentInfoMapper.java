package com.ruoyi.agent.mapper;

import java.util.List;
import com.ruoyi.agent.domain.AgentInfo;

/**
 * 智能体信息Mapper接口
 */
public interface AgentInfoMapper
{
    /**
     * 查询智能体信息列表
     */
    public List<AgentInfo> selectAgentInfoList(AgentInfo agentInfo);

    /**
     * 根据ID查询智能体信息
     */
    public AgentInfo selectAgentInfoById(Long agentId);

    /**
     * 新增智能体信息
     */
    public int insertAgentInfo(AgentInfo agentInfo);

    /**
     * 修改智能体信息
     */
    public int updateAgentInfo(AgentInfo agentInfo);

    /**
     * 批量删除智能体信息
     */
    public int deleteAgentInfoByIds(Long[] agentIds);

    /**
     * 根据ID删除智能体信息
     */
    public int deleteAgentInfoById(Long agentId);
}
