package com.ruoyi.agent.service;

import java.util.List;
import com.ruoyi.agent.domain.DigitalResource;

/**
 * 数字资源Service接口
 */
public interface IDigitalResourceService
{
    public List<DigitalResource> selectDigitalResourceList(DigitalResource digitalResource);
    public DigitalResource selectDigitalResourceById(Long resourceId);
    public int insertDigitalResource(DigitalResource digitalResource);
    public int updateDigitalResource(DigitalResource digitalResource);
    public int deleteDigitalResourceByIds(Long[] resourceIds);
    public int deleteDigitalResourceById(Long resourceId);
}
