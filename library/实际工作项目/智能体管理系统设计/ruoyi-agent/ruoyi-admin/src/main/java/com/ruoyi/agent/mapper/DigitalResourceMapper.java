package com.ruoyi.agent.mapper;

import java.util.List;
import com.ruoyi.agent.domain.DigitalResource;

/**
 * 数字资源Mapper接口
 */
public interface DigitalResourceMapper
{
    public List<DigitalResource> selectDigitalResourceList(DigitalResource digitalResource);
    public DigitalResource selectDigitalResourceById(Long resourceId);
    public int insertDigitalResource(DigitalResource digitalResource);
    public int updateDigitalResource(DigitalResource digitalResource);
    public int deleteDigitalResourceByIds(Long[] resourceIds);
    public int deleteDigitalResourceById(Long resourceId);
}
