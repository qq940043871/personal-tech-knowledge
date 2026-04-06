package com.ruoyi.agent.service.impl;

import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import com.ruoyi.agent.domain.DigitalResource;
import com.ruoyi.agent.mapper.DigitalResourceMapper;
import com.ruoyi.agent.service.IDigitalResourceService;

/**
 * 数字资源Service业务层处理
 */
@Service
public class DigitalResourceServiceImpl implements IDigitalResourceService
{
    @Autowired
    private DigitalResourceMapper digitalResourceMapper;

    @Override
    public List<DigitalResource> selectDigitalResourceList(DigitalResource digitalResource)
    {
        return digitalResourceMapper.selectDigitalResourceList(digitalResource);
    }

    @Override
    public DigitalResource selectDigitalResourceById(Long resourceId)
    {
        return digitalResourceMapper.selectDigitalResourceById(resourceId);
    }

    @Override
    public int insertDigitalResource(DigitalResource digitalResource)
    {
        return digitalResourceMapper.insertDigitalResource(digitalResource);
    }

    @Override
    public int updateDigitalResource(DigitalResource digitalResource)
    {
        return digitalResourceMapper.updateDigitalResource(digitalResource);
    }

    @Override
    public int deleteDigitalResourceByIds(Long[] resourceIds)
    {
        return digitalResourceMapper.deleteDigitalResourceByIds(resourceIds);
    }

    @Override
    public int deleteDigitalResourceById(Long resourceId)
    {
        return digitalResourceMapper.deleteDigitalResourceById(resourceId);
    }
}
