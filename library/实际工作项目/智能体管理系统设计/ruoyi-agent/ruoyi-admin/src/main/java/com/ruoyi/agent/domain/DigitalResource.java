package com.ruoyi.agent.domain;

import java.math.BigDecimal;
import java.util.Date;
import com.ruoyi.common.annotation.Excel;
import com.ruoyi.common.core.domain.BaseEntity;

/**
 * 数字资源对象 digital_resource
 */
public class DigitalResource extends BaseEntity
{
    private static final long serialVersionUID = 1L;

    /** 资源ID */
    private Long resourceId;

    /** 资源名称 */
    @Excel(name = "资源名称")
    private String resourceName;

    /** 类型：image/video/audio/document/code/model/other */
    @Excel(name = "类型", readConverterExp = "image=图片,video=视频,audio=音频,document=文档,code=代码,model=模型,other=其他")
    private String resourceType;

    /** 分类ID */
    private Long categoryId;

    /** 文件存储URL */
    private String fileUrl;

    /** 文件路径 */
    private String filePath;

    /** 文件大小(字节) */
    @Excel(name = "文件大小")
    private Long fileSize;

    /** 格式：jpg/mp4/mp3/pdf/zip等 */
    @Excel(name = "格式")
    private String fileFormat;

    /** 缩略图URL */
    private String thumbnailUrl;

    /** 宽度 */
    private Integer width;

    /** 高度 */
    private Integer height;

    /** 时长(秒) */
    private BigDecimal duration;

    /** 标签 */
    private String tags;

    /** 资源描述 */
    private String description;

    /** 元数据(JSON) */
    private String metadataJson;

    /** 状态：0正常 1禁用 */
    @Excel(name = "状态", readConverterExp = "0=正常,1=禁用")
    private String status;

    /** 删除标志 */
    private String delFlag;

    public Long getResourceId() { return resourceId; }
    public void setResourceId(Long resourceId) { this.resourceId = resourceId; }
    public String getResourceName() { return resourceName; }
    public void setResourceName(String resourceName) { this.resourceName = resourceName; }
    public String getResourceType() { return resourceType; }
    public void setResourceType(String resourceType) { this.resourceType = resourceType; }
    public Long getCategoryId() { return categoryId; }
    public void setCategoryId(Long categoryId) { this.categoryId = categoryId; }
    public String getFileUrl() { return fileUrl; }
    public void setFileUrl(String fileUrl) { this.fileUrl = fileUrl; }
    public String getFilePath() { return filePath; }
    public void setFilePath(String filePath) { this.filePath = filePath; }
    public Long getFileSize() { return fileSize; }
    public void setFileSize(Long fileSize) { this.fileSize = fileSize; }
    public String getFileFormat() { return fileFormat; }
    public void setFileFormat(String fileFormat) { this.fileFormat = fileFormat; }
    public String getThumbnailUrl() { return thumbnailUrl; }
    public void setThumbnailUrl(String thumbnailUrl) { this.thumbnailUrl = thumbnailUrl; }
    public Integer getWidth() { return width; }
    public void setWidth(Integer width) { this.width = width; }
    public Integer getHeight() { return height; }
    public void setHeight(Integer height) { this.height = height; }
    public BigDecimal getDuration() { return duration; }
    public void setDuration(BigDecimal duration) { this.duration = duration; }
    public String getTags() { return tags; }
    public void setTags(String tags) { this.tags = tags; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getMetadataJson() { return metadataJson; }
    public void setMetadataJson(String metadataJson) { this.metadataJson = metadataJson; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getDelFlag() { return delFlag; }
    public void setDelFlag(String delFlag) { this.delFlag = delFlag; }
}
