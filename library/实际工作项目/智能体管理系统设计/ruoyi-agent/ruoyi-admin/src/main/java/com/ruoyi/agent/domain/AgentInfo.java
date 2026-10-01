package com.ruoyi.agent.domain;

import java.math.BigDecimal;
import java.util.Date;
import com.fasterxml.jackson.annotation.JsonFormat;
import org.apache.commons.lang3.builder.ToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;
import com.ruoyi.common.annotation.Excel;
import com.ruoyi.common.core.domain.BaseEntity;

/**
 * 智能体信息对象 agent_info
 *
 * @author ruoyi
 */
public class AgentInfo extends BaseEntity
{
    private static final long serialVersionUID = 1L;

    /** 智能体ID */
    private Long agentId;

    /** 智能体名称 */
    @Excel(name = "智能体名称")
    private String agentName;

    /** 类型：chat/text2img/code/embedding/agent */
    @Excel(name = "类型", readConverterExp = "chat=对话,text2img=文生图,code=代码,embedding=嵌入,agent=智能体")
    private String agentType;

    /** 描述 */
    @Excel(name = "描述")
    private String description;

    /** 头像URL */
    @Excel(name = "头像URL")
    private String avatarUrl;

    /** 关联模型名称 */
    @Excel(name = "关联模型")
    private String modelName;

    /** 系统提示词 */
    private String systemPrompt;

    /** 温度参数 */
    @Excel(name = "温度")
    private BigDecimal temperature;

    /** 最大token数 */
    @Excel(name = "最大Token数")
    private Integer maxTokens;

    /** 状态：0正常 1停用 */
    @Excel(name = "状态", readConverterExp = "0=正常,1=停用")
    private String status;

    /** 是否公开：0私有 1公开 */
    @Excel(name = "是否公开", readConverterExp = "0=私有,1=公开")
    private String isPublic;

    /** 删除标志 */
    private String delFlag;

    public Long getAgentId() { return agentId; }
    public void setAgentId(Long agentId) { this.agentId = agentId; }
    public String getAgentName() { return agentName; }
    public void setAgentName(String agentName) { this.agentName = agentName; }
    public String getAgentType() { return agentType; }
    public void setAgentType(String agentType) { this.agentType = agentType; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getAvatarUrl() { return avatarUrl; }
    public void setAvatarUrl(String avatarUrl) { this.avatarUrl = avatarUrl; }
    public String getModelName() { return modelName; }
    public void setModelName(String modelName) { this.modelName = modelName; }
    public String getSystemPrompt() { return systemPrompt; }
    public void setSystemPrompt(String systemPrompt) { this.systemPrompt = systemPrompt; }
    public BigDecimal getTemperature() { return temperature; }
    public void setTemperature(BigDecimal temperature) { this.temperature = temperature; }
    public Integer getMaxTokens() { return maxTokens; }
    public void setMaxTokens(Integer maxTokens) { this.maxTokens = maxTokens; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getIsPublic() { return isPublic; }
    public void setIsPublic(String isPublic) { this.isPublic = isPublic; }
    public String getDelFlag() { return delFlag; }
    public void setDelFlag(String delFlag) { this.delFlag = delFlag; }

    @Override
    public String toString() {
        return new ToStringBuilder(this, ToStringStyle.MULTI_LINE_STYLE)
            .append("agentId", getAgentId())
            .append("agentName", getAgentName())
            .append("agentType", getAgentType())
            .append("description", getDescription())
            .append("modelName", getModelName())
            .append("status", getStatus())
            .toString();
    }
}
