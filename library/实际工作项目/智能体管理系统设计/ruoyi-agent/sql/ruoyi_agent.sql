-- ----------------------------
-- 智能体管理和数字资源管理系统 - 数据库初始化脚本
-- ----------------------------

-- ----------------------------
-- 1. 智能体信息表
-- ----------------------------
DROP TABLE IF EXISTS `agent_info`;
CREATE TABLE `agent_info` (
    `agent_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '智能体ID',
    `agent_name` varchar(100) NOT NULL COMMENT '智能体名称',
    `agent_type` varchar(20) DEFAULT 'chat' COMMENT '类型：chat/text2img/code/embedding/agent',
    `description` varchar(500) DEFAULT NULL COMMENT '描述',
    `avatar_url` varchar(500) DEFAULT NULL COMMENT '头像URL',
    `model_name` varchar(100) DEFAULT NULL COMMENT '关联模型名称',
    `system_prompt` text COMMENT '系统提示词',
    `temperature` decimal(3,2) DEFAULT 0.70 COMMENT '温度参数',
    `max_tokens` int(11) DEFAULT 4096 COMMENT '最大token数',
    `status` char(1) DEFAULT '0' COMMENT '状态：0正常 1停用',
    `is_public` char(1) DEFAULT '1' COMMENT '是否公开：0私有 1公开',
    `create_by` varchar(64) DEFAULT '' COMMENT '创建者',
    `create_time` datetime DEFAULT NULL COMMENT '创建时间',
    `update_by` varchar(64) DEFAULT '' COMMENT '更新者',
    `update_time` datetime DEFAULT NULL COMMENT '更新时间',
    `remark` varchar(500) DEFAULT NULL COMMENT '备注',
    `del_flag` char(1) DEFAULT '0' COMMENT '删除标志',
    PRIMARY KEY (`agent_id`),
    KEY `idx_agent_name` (`agent_name`),
    KEY `idx_agent_type` (`agent_type`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='智能体信息表';

-- ----------------------------
-- 2. 智能体配置表
-- ----------------------------
DROP TABLE IF EXISTS `agent_config`;
CREATE TABLE `agent_config` (
    `config_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '配置ID',
    `agent_id` bigint(20) NOT NULL COMMENT '智能体ID',
    `config_key` varchar(100) NOT NULL COMMENT '配置键',
    `config_value` text COMMENT '配置值',
    `config_type` varchar(20) DEFAULT 'string' COMMENT '类型：string/number/json/array',
    `config_desc` varchar(200) DEFAULT NULL COMMENT '配置描述',
    `create_time` datetime DEFAULT NULL COMMENT '创建时间',
    `update_time` datetime DEFAULT NULL COMMENT '更新时间',
    PRIMARY KEY (`config_id`),
    UNIQUE KEY `uk_agent_config` (`agent_id`,`config_key`),
    KEY `idx_agent_id` (`agent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='智能体配置表';

-- ----------------------------
-- 3. 数字资源表
-- ----------------------------
DROP TABLE IF EXISTS `digital_resource`;
CREATE TABLE `digital_resource` (
    `resource_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '资源ID',
    `resource_name` varchar(200) NOT NULL COMMENT '资源名称',
    `resource_type` varchar(20) NOT NULL COMMENT '类型：image/video/audio/document/code/model/other',
    `category_id` bigint(20) DEFAULT NULL COMMENT '分类ID',
    `file_url` varchar(500) DEFAULT NULL COMMENT '文件存储URL',
    `file_path` varchar(500) DEFAULT NULL COMMENT '文件路径',
    `file_size` bigint(20) DEFAULT 0 COMMENT '文件大小(字节)',
    `file_format` varchar(50) DEFAULT NULL COMMENT '格式：jpg/mp4/mp3/pdf/zip等',
    `thumbnail_url` varchar(500) DEFAULT NULL COMMENT '缩略图URL',
    `width` int(11) DEFAULT NULL COMMENT '宽度',
    `height` int(11) DEFAULT NULL COMMENT '高度',
    `duration` decimal(10,2) DEFAULT NULL COMMENT '时长(秒)',
    `tags` varchar(500) DEFAULT NULL COMMENT '标签',
    `description` text COMMENT '资源描述',
    `metadata_json` text COMMENT '元数据(JSON)',
    `status` char(1) DEFAULT '0' COMMENT '状态：0正常 1禁用',
    `create_by` varchar(64) DEFAULT '' COMMENT '创建者',
    `create_time` datetime DEFAULT NULL COMMENT '创建时间',
    `update_by` varchar(64) DEFAULT '' COMMENT '更新者',
    `update_time` datetime DEFAULT NULL COMMENT '更新时间',
    `remark` varchar(500) DEFAULT NULL COMMENT '备注',
    `del_flag` char(1) DEFAULT '0' COMMENT '删除标志',
    PRIMARY KEY (`resource_id`),
    KEY `idx_resource_name` (`resource_name`),
    KEY `idx_resource_type` (`resource_type`),
    KEY `idx_category_id` (`category_id`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='数字资源表';

-- ----------------------------
-- 4. 资源分类表
-- ----------------------------
DROP TABLE IF EXISTS `resource_category`;
CREATE TABLE `resource_category` (
    `category_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '分类ID',
    `category_name` varchar(100) NOT NULL COMMENT '分类名称',
    `parent_id` bigint(20) DEFAULT 0 COMMENT '父分类ID',
    `category_icon` varchar(200) DEFAULT NULL COMMENT '分类图标',
    `sort_order` int(11) DEFAULT 0 COMMENT '排序',
    `status` char(1) DEFAULT '0' COMMENT '状态',
    `create_by` varchar(64) DEFAULT '' COMMENT '创建者',
    `create_time` datetime DEFAULT NULL COMMENT '创建时间',
    `update_by` varchar(64) DEFAULT '' COMMENT '更新者',
    `update_time` datetime DEFAULT NULL COMMENT '更新时间',
    `remark` varchar(500) DEFAULT NULL COMMENT '备注',
    `del_flag` char(1) DEFAULT '0' COMMENT '删除标志',
    PRIMARY KEY (`category_id`),
    KEY `idx_parent_id` (`parent_id`),
    KEY `idx_sort_order` (`sort_order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='资源分类表';

-- ----------------------------
-- 5. 智能体-资源关联表
-- ----------------------------
DROP TABLE IF EXISTS `agent_resource`;
CREATE TABLE `agent_resource` (
    `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'ID',
    `agent_id` bigint(20) NOT NULL COMMENT '智能体ID',
    `resource_id` bigint(20) NOT NULL COMMENT '资源ID',
    `resource_role` varchar(20) DEFAULT 'knowledge' COMMENT '角色：knowledge/avatar/tool/template/output',
    `sort_order` int(11) DEFAULT 0 COMMENT '排序',
    `create_time` datetime DEFAULT NULL COMMENT '创建时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_agent_resource` (`agent_id`,`resource_id`),
    KEY `idx_agent_id` (`agent_id`),
    KEY `idx_resource_id` (`resource_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='智能体-资源关联表';

-- ----------------------------
-- 6. 使用日志表
-- ----------------------------
DROP TABLE IF EXISTS `agent_usage_log`;
CREATE TABLE `agent_usage_log` (
    `log_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '日志ID',
    `agent_id` bigint(20) NOT NULL COMMENT '智能体ID',
    `user_id` bigint(20) DEFAULT NULL COMMENT '用户ID',
    `input_text` text COMMENT '输入内容',
    `output_text` text COMMENT '输出内容',
    `tokens_used` int(11) DEFAULT 0 COMMENT '消耗token数',
    `duration_ms` int(11) DEFAULT 0 COMMENT '耗时(毫秒)',
    `status` varchar(20) DEFAULT 'success' COMMENT '状态：success/failed/timeout',
    `error_msg` varchar(500) DEFAULT NULL COMMENT '错误信息',
    `create_time` datetime DEFAULT NULL COMMENT '创建时间',
    PRIMARY KEY (`log_id`),
    KEY `idx_agent_id` (`agent_id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='使用日志表';

-- ----------------------------
-- 初始化菜单数据
-- ----------------------------

-- 一级菜单：智能体管理
INSERT INTO `sys_menu` (`menu_id`, `menu_name`, `parent_id`, `order_num`, `path`, `component`, `is_frame`, `is_cache`, `menu_type`, `visible`, `status`, `perms`, `icon`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) 
VALUES (2000, '智能体管理', 0, 10, 'agent', NULL, 1, 0, 'M', '0', '0', NULL, 'robot', 'admin', NOW(), '', NULL, '智能体管理和数字资源管理菜单');

-- 二级菜单：智能体列表
INSERT INTO `sys_menu` (`menu_id`, `menu_name`, `parent_id`, `order_num`, `path`, `component`, `is_frame`, `is_cache`, `menu_type`, `visible`, `status`, `perms`, `icon`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) 
VALUES (2001, '智能体列表', 2000, 1, 'info', 'agent/info/index', 1, 0, 'C', '0', '0', 'agent:info:list', 'user', 'admin', NOW(), '', NULL, '智能体列表菜单');

-- 智能体按钮权限
INSERT INTO `sys_menu` (`menu_id`, `menu_name`, `parent_id`, `order_num`, `path`, `component`, `is_frame`, `is_cache`, `menu_type`, `visible`, `status`, `perms`, `icon`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) 
VALUES (2002, '智能体查询', 2001, 1, '', NULL, 1, 0, 'F', '0', '0', 'agent:info:query', '#', 'admin', NOW(), '', NULL, '');
INSERT INTO `sys_menu` (`menu_id`, `menu_name`, `parent_id`, `order_num`, `path`, `component`, `is_frame`, `is_cache`, `menu_type`, `visible`, `status`, `perms`, `icon`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) 
VALUES (2003, '智能体新增', 2001, 2, '', NULL, 1, 0, 'F', '0', '0', 'agent:info:add', '#', 'admin', NOW(), '', NULL, '');
INSERT INTO `sys_menu` (`menu_id`, `menu_name`, `parent_id`, `order_num`, `path`, `component`, `is_frame`, `is_cache`, `menu_type`, `visible`, `status`, `perms`, `icon`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) 
VALUES (2004, '智能体修改', 2001, 3, '', NULL, 1, 0, 'F', '0', '0', 'agent:info:edit', '#', 'admin', NOW(), '', NULL, '');
INSERT INTO `sys_menu` (`menu_id`, `menu_name`, `parent_id`, `order_num`, `path`, `component`, `is_frame`, `is_cache`, `menu_type`, `visible`, `status`, `perms`, `icon`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) 
VALUES (2005, '智能体删除', 2001, 4, '', NULL, 1, 0, 'F', '0', '0', 'agent:info:remove', '#', 'admin', NOW(), '', NULL, '');

-- 二级菜单：数字资源
INSERT INTO `sys_menu` (`menu_id`, `menu_name`, `parent_id`, `order_num`, `path`, `component`, `is_frame`, `is_cache`, `menu_type`, `visible`, `status`, `perms`, `icon`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) 
VALUES (2006, '数字资源', 2000, 2, 'resource', 'agent/resource/index', 1, 0, 'C', '0', '0', 'agent:resource:list', 'upload', 'admin', NOW(), '', NULL, '数字资源菜单');

-- 数字资源按钮权限
INSERT INTO `sys_menu` (`menu_id`, `menu_name`, `parent_id`, `order_num`, `path`, `component`, `is_frame`, `is_cache`, `menu_type`, `visible`, `status`, `perms`, `icon`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) 
VALUES (2007, '资源查询', 2006, 1, '', NULL, 1, 0, 'F', '0', '0', 'agent:resource:query', '#', 'admin', NOW(), '', NULL, '');
INSERT INTO `sys_menu` (`menu_id`, `menu_name`, `parent_id`, `order_num`, `path`, `component`, `is_frame`, `is_cache`, `menu_type`, `visible`, `status`, `perms`, `icon`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) 
VALUES (2008, '资源新增', 2006, 2, '', NULL, 1, 0, 'F', '0', '0', 'agent:resource:add', '#', 'admin', NOW(), '', NULL, '');
INSERT INTO `sys_menu` (`menu_id`, `menu_name`, `parent_id`, `order_num`, `path`, `component`, `is_frame`, `is_cache`, `menu_type`, `visible`, `status`, `perms`, `icon`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) 
VALUES (2009, '资源修改', 2006, 3, '', NULL, 1, 0, 'F', '0', '0', 'agent:resource:edit', '#', 'admin', NOW(), '', NULL, '');
INSERT INTO `sys_menu` (`menu_id`, `menu_name`, `parent_id`, `order_num`, `path`, `component`, `is_frame`, `is_cache`, `menu_type`, `visible`, `status`, `perms`, `icon`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) 
VALUES (2010, '资源删除', 2006, 4, '', NULL, 1, 0, 'F', '0', '0', 'agent:resource:remove', '#', 'admin', NOW(), '', NULL, '');

-- 二级菜单：资源分类
INSERT INTO `sys_menu` (`menu_id`, `menu_name`, `parent_id`, `order_num`, `path`, `component`, `is_frame`, `is_cache`, `menu_type`, `visible`, `status`, `perms`, `icon`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) 
VALUES (2011, '资源分类', 2000, 3, 'category', 'agent/category/index', 1, 0, 'C', '0', '0', 'agent:category:list', 'tree', 'admin', NOW(), '', NULL, '资源分类菜单');

-- 资源分类按钮权限
INSERT INTO `sys_menu` (`menu_id`, `menu_name`, `parent_id`, `order_num`, `path`, `component`, `is_frame`, `is_cache`, `menu_type`, `visible`, `status`, `perms`, `icon`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) 
VALUES (2012, '分类查询', 2011, 1, '', NULL, 1, 0, 'F', '0', '0', 'agent:category:query', '#', 'admin', NOW(), '', NULL, '');
INSERT INTO `sys_menu` (`menu_id`, `menu_name`, `parent_id`, `order_num`, `path`, `component`, `is_frame`, `is_cache`, `menu_type`, `visible`, `status`, `perms`, `icon`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) 
VALUES (2013, '分类新增', 2011, 2, '', NULL, 1, 0, 'F', '0', '0', 'agent:category:add', '#', 'admin', NOW(), '', NULL, '');
INSERT INTO `sys_menu` (`menu_id`, `menu_name`, `parent_id`, `order_num`, `path`, `component`, `is_frame`, `is_cache`, `menu_type`, `visible`, `status`, `perms`, `icon`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) 
VALUES (2014, '分类修改', 2011, 3, '', NULL, 1, 0, 'F', '0', '0', 'agent:category:edit', '#', 'admin', NOW(), '', NULL, '');
INSERT INTO `sys_menu` (`menu_id`, `menu_name`, `parent_id`, `order_num`, `path`, `component`, `is_frame`, `is_cache`, `menu_type`, `visible`, `status`, `perms`, `icon`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) 
VALUES (2015, '分类删除', 2011, 4, '', NULL, 1, 0, 'F', '0', '0', 'agent:category:remove', '#', 'admin', NOW(), '', NULL, '');

-- 二级菜单：使用日志
INSERT INTO `sys_menu` (`menu_id`, `menu_name`, `parent_id`, `order_num`, `path`, `component`, `is_frame`, `is_cache`, `menu_type`, `visible`, `status`, `perms`, `icon`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) 
VALUES (2016, '使用日志', 2000, 4, 'log', 'agent/log/index', 1, 0, 'C', '0', '0', 'agent:log:list', 'log', 'admin', NOW(), '', NULL, '使用日志菜单');

-- 使用日志按钮权限
INSERT INTO `sys_menu` (`menu_id`, `menu_name`, `parent_id`, `order_num`, `path`, `component`, `is_frame`, `is_cache`, `menu_type`, `visible`, `status`, `perms`, `icon`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) 
VALUES (2017, '日志查询', 2016, 1, '', NULL, 1, 0, 'F', '0', '0', 'agent:log:query', '#', 'admin', NOW(), '', NULL, '');
INSERT INTO `sys_menu` (`menu_id`, `menu_name`, `parent_id`, `order_num`, `path`, `component`, `is_frame`, `is_cache`, `menu_type`, `visible`, `status`, `perms`, `icon`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) 
VALUES (2018, '日志统计', 2016, 2, '', NULL, 1, 0, 'F', '0', '0', 'agent:log:stats', '#', 'admin', NOW(), '', NULL, '');

-- 初始化数据字典
INSERT INTO `sys_dict_type` (`dict_id`, `dict_name`, `dict_type`, `status`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) 
VALUES (200, '智能体类型', 'agent_type', '0', 'admin', NOW(), '', NULL, '智能体类型字典');
INSERT INTO `sys_dict_data` (`dict_code`, `dict_sort`, `dict_label`, `dict_value`, `dict_type`, `css_class`, `list_class`, `is_default`, `status`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) 
VALUES (2001, 1, '对话', 'chat', 'agent_type', '', 'primary', 'Y', '0', 'admin', NOW(), '', NULL, '');
INSERT INTO `sys_dict_data` (`dict_code`, `dict_sort`, `dict_label`, `dict_value`, `dict_type`, `css_class`, `list_class`, `is_default`, `status`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) 
VALUES (2002, 2, '文生图', 'text2img', 'agent_type', '', 'success', 'N', '0', 'admin', NOW(), '', NULL, '');
INSERT INTO `sys_dict_data` (`dict_code`, `dict_sort`, `dict_label`, `dict_value`, `dict_type`, `css_class`, `list_class`, `is_default`, `status`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) 
VALUES (2003, 3, '代码', 'code', 'agent_type', '', 'warning', 'N', '0', 'admin', NOW(), '', NULL, '');
INSERT INTO `sys_dict_data` (`dict_code`, `dict_sort`, `dict_label`, `dict_value`, `dict_type`, `css_class`, `list_class`, `is_default`, `status`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) 
VALUES (2004, 4, '嵌入', 'embedding', 'agent_type', '', 'info', 'N', '0', 'admin', NOW(), '', NULL, '');
INSERT INTO `sys_dict_data` (`dict_code`, `dict_sort`, `dict_label`, `dict_value`, `dict_type`, `css_class`, `list_class`, `is_default`, `status`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) 
VALUES (2005, 5, '智能体', 'agent', 'agent_type', '', 'danger', 'N', '0', 'admin', NOW(), '', NULL, '');

INSERT INTO `sys_dict_type` (`dict_id`, `dict_name`, `dict_type`, `status`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) 
VALUES (201, '资源类型', 'resource_type', '0', 'admin', NOW(), '', NULL, '数字资源类型字典');
INSERT INTO `sys_dict_data` (`dict_code`, `dict_sort`, `dict_label`, `dict_value`, `dict_type`, `css_class`, `list_class`, `is_default`, `status`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) 
VALUES (2011, 1, '图片', 'image', 'resource_type', '', 'primary', 'N', '0', 'admin', NOW(), '', NULL, '');
INSERT INTO `sys_dict_data` (`dict_code`, `dict_sort`, `dict_label`, `dict_value`, `dict_type`, `css_class`, `list_class`, `is_default`, `status`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) 
VALUES (2012, 2, '视频', 'video', 'resource_type', '', 'success', 'N', '0', 'admin', NOW(), '', NULL, '');
INSERT INTO `sys_dict_data` (`dict_code`, `dict_sort`, `dict_label`, `dict_value`, `dict_type`, `css_class`, `list_class`, `is_default`, `status`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) 
VALUES (2013, 3, '音频', 'audio', 'resource_type', '', 'warning', 'N', '0', 'admin', NOW(), '', NULL, '');
INSERT INTO `sys_dict_data` (`dict_code`, `dict_sort`, `dict_label`, `dict_value`, `dict_type`, `css_class`, `list_class`, `is_default`, `status`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) 
VALUES (2014, 4, '文档', 'document', 'resource_type', '', 'info', 'N', '0', 'admin', NOW(), '', NULL, '');
INSERT INTO `sys_dict_data` (`dict_code`, `dict_sort`, `dict_label`, `dict_value`, `dict_type`, `css_class`, `list_class`, `is_default`, `status`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) 
VALUES (2015, 5, '代码', 'code', 'resource_type', '', '', 'N', '0', 'admin', NOW(), '', NULL, '');
INSERT INTO `sys_dict_data` (`dict_code`, `dict_sort`, `dict_label`, `dict_value`, `dict_type`, `css_class`, `list_class`, `is_default`, `status`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) 
VALUES (2016, 6, '模型', 'model', 'resource_type', '', 'danger', 'N', '0', 'admin', NOW(), '', NULL, '');
INSERT INTO `sys_dict_data` (`dict_code`, `dict_sort`, `dict_label`, `dict_value`, `dict_type`, `css_class`, `list_class`, `is_default`, `status`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) 
VALUES (2017, 7, '其他', 'other', 'resource_type', '', '', 'N', '0', 'admin', NOW(), '', NULL, '');
