-- ruoyi-sys 域 V4.0.0 全量基线（空库单轨建库；存量库经 baseline 接管后本脚本跳过）。
-- 来源拆分：ruoyi/sql/public_no_shard.sql 的 ruoyi-sys 段整段原文提取
--   （gen_*/qrtz_*/sys_* 表 DDL + 系统种子 + 函数 find_in_set/substring_index + 视图 list_column/list_table）。
--   不提取：DROP 前缀语句（全新建库无需 drop）；注释态对象（2026-03-20 停用的 INHERITS 周分区 trigger）；
--   qrtz_* 运行时状态行（调度器实例注册/锁行/孤儿触发器，属运行时快照非系统种子，quartz 启动自建）。
--   sys_job 种子含 job_id 11~19 与 21~45 原文（导出时点实况）；其中 21~41 为旧 quartz 质控通道任务，
--   由 qcm 域 V4.0.1 存量清理脚本统一清除（桥仓时序保证 ruoyi-sys 域先于 qcm 域执行，删除后无再引入路径）。
-- 来源拆分与逐表对账由十二域基线生成器产出,对账矩阵与差集记录随交付验收材料提供。
-- 库：PG 主库 public schema。幂等性说明：纯 DDL+种子（无 IF NOT EXISTS），依赖 flyway 账本单次执行——
--   已应用行/基线行挡住重放；绕过账本的人工重跑会报对象已存在，此为预期防呆。

CREATE SEQUENCE "public"."gen_table_column_column_id_seq" 
INCREMENT 1
MINVALUE  1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

CREATE SEQUENCE "public"."gen_table_table_id_seq" 
INCREMENT 1
MINVALUE  1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

CREATE SEQUENCE "public"."sys_config_config_id_seq" 
INCREMENT 1
MINVALUE  1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

CREATE SEQUENCE "public"."sys_dept_dept_id_seq" 
INCREMENT 1
MINVALUE  1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

CREATE SEQUENCE "public"."sys_dict_data_dict_code_seq" 
INCREMENT 1
MINVALUE  1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

CREATE SEQUENCE "public"."sys_dict_type_dict_id_seq" 
INCREMENT 1
MINVALUE  1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

CREATE SEQUENCE "public"."sys_job_job_id_seq" 
INCREMENT 1
MINVALUE  1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

CREATE SEQUENCE "public"."sys_job_log_job_log_id_seq" 
INCREMENT 1
MINVALUE  1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

CREATE SEQUENCE "public"."sys_logininfor_info_id_seq" 
INCREMENT 1
MINVALUE  1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

CREATE SEQUENCE "public"."sys_menu_menu_id_seq" 
INCREMENT 1
MINVALUE  1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

CREATE SEQUENCE "public"."sys_notice_notice_id_seq" 
INCREMENT 1
MINVALUE  1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

CREATE SEQUENCE "public"."sys_oper_log_oper_id_seq" 
INCREMENT 1
MINVALUE  1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

CREATE SEQUENCE "public"."sys_post_post_id_seq" 
INCREMENT 1
MINVALUE  1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

CREATE SEQUENCE "public"."sys_role_role_id_seq" 
INCREMENT 1
MINVALUE  1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

CREATE SEQUENCE "public"."sys_user_user_id_seq" 
INCREMENT 1
MINVALUE  1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

CREATE TABLE "public"."gen_table" (
  "table_id" int8 NOT NULL DEFAULT nextval('gen_table_table_id_seq'::regclass),
  "table_name" varchar(200) COLLATE "pg_catalog"."default",
  "table_comment" varchar(500) COLLATE "pg_catalog"."default",
  "sub_table_name" varchar(64) COLLATE "pg_catalog"."default",
  "sub_table_fk_name" varchar(64) COLLATE "pg_catalog"."default",
  "class_name" varchar(100) COLLATE "pg_catalog"."default",
  "tpl_category" varchar(200) COLLATE "pg_catalog"."default",
  "tpl_web_type" varchar(30) COLLATE "pg_catalog"."default",
  "package_name" varchar(100) COLLATE "pg_catalog"."default",
  "module_name" varchar(30) COLLATE "pg_catalog"."default",
  "business_name" varchar(30) COLLATE "pg_catalog"."default",
  "function_name" varchar(50) COLLATE "pg_catalog"."default",
  "function_author" varchar(50) COLLATE "pg_catalog"."default",
  "gen_type" char(1) COLLATE "pg_catalog"."default",
  "gen_path" varchar(200) COLLATE "pg_catalog"."default",
  "options" varchar(1000) COLLATE "pg_catalog"."default",
  "create_by" varchar(64) COLLATE "pg_catalog"."default",
  "create_time" timestamp(6),
  "update_by" varchar(64) COLLATE "pg_catalog"."default",
  "update_time" timestamp(6),
  "remark" varchar(500) COLLATE "pg_catalog"."default"
)
;
COMMENT ON COLUMN "public"."gen_table"."table_id" IS '编号';
COMMENT ON COLUMN "public"."gen_table"."table_name" IS '表名称';
COMMENT ON COLUMN "public"."gen_table"."table_comment" IS '表描述';
COMMENT ON COLUMN "public"."gen_table"."sub_table_name" IS '关联子表的表名';
COMMENT ON COLUMN "public"."gen_table"."sub_table_fk_name" IS '子表关联的外键名';
COMMENT ON COLUMN "public"."gen_table"."class_name" IS '实体类名称';
COMMENT ON COLUMN "public"."gen_table"."tpl_category" IS '使用的模板（crud单表操作 tree树表操作）';
COMMENT ON COLUMN "public"."gen_table"."tpl_web_type" IS '前端模板类型（element-ui模版 element-plus模版）';
COMMENT ON COLUMN "public"."gen_table"."package_name" IS '生成包路径';
COMMENT ON COLUMN "public"."gen_table"."module_name" IS '生成模块名';
COMMENT ON COLUMN "public"."gen_table"."business_name" IS '生成业务名';
COMMENT ON COLUMN "public"."gen_table"."function_name" IS '生成功能名';
COMMENT ON COLUMN "public"."gen_table"."function_author" IS '生成功能作者';
COMMENT ON COLUMN "public"."gen_table"."gen_type" IS '生成代码方式（0zip压缩包 1自定义路径）';
COMMENT ON COLUMN "public"."gen_table"."gen_path" IS '生成路径（不填默认项目路径）';
COMMENT ON COLUMN "public"."gen_table"."options" IS '其它生成选项';
COMMENT ON COLUMN "public"."gen_table"."create_by" IS '创建者';
COMMENT ON COLUMN "public"."gen_table"."create_time" IS '创建时间';
COMMENT ON COLUMN "public"."gen_table"."update_by" IS '更新者';
COMMENT ON COLUMN "public"."gen_table"."update_time" IS '更新时间';
COMMENT ON COLUMN "public"."gen_table"."remark" IS '备注';
COMMENT ON TABLE "public"."gen_table" IS '代码生成业务表';

INSERT INTO "public"."gen_table" VALUES (6, 'sta_info', '设备管理', '', '', 'StaInfo', 'crud', 'element-ui', 'com.ruoyi.station', 'station', 'staInfo', '站点管理', 'dreamfalls', '0', NULL, '{"parentMenuId":1062}', 'admin', '2025-02-14 14:15:58.271971', NULL, '2025-02-14 14:35:00.401418', NULL);
INSERT INTO "public"."gen_table" VALUES (7, 'para_info', '参数管理', '', '', 'ParaInfo', 'crud', 'element-ui', 'com.ruoyi.station', 'station', 'paraInfo', '设备参数管理', 'dreamfalls', '0', NULL, '{"parentMenuId":1062}', 'admin', '2025-02-14 15:06:30.342815', NULL, '2025-02-14 16:06:38.269918', NULL);
INSERT INTO "public"."gen_table" VALUES (16, 'env_quality_control_records', '质控记录表', '', '', 'EnvQualityControlRecords', 'crud', 'element-plus', 'com.ecat.integration.EnvQualityControlManagerIntegration', 'quality_control', 'records', '质控记录', 'caohongbo', '0', NULL, '{"parentMenuId":1061}', 'admin', '2025-05-26 15:00:13.048164', NULL, '2025-05-28 14:55:52.300211', NULL);
INSERT INTO "public"."gen_table" VALUES (19, 'env_maintenance_records', '维护记录表', '', '', 'EnvMaintenanceRecords', 'crud', 'element-plus', 'com.ecat.integration.EnvMaintenanceManagerIntegration', 'maintenance', 'records', '维护记录', 'caohongbo', '0', NULL, '{"parentMenuId":1062}', 'admin', '2025-05-26 18:11:26.072269', NULL, '2025-05-28 16:34:42.364938', NULL);
INSERT INTO "public"."gen_table" VALUES (9, 'his_data', '历史数据', '', '', 'HisData', 'crud', 'element-ui', 'com.ruoyi.station', 'station', 'data', 'history', 'sms', NULL, NULL, '{"parentMenuId":1061}', 'admin', '2025-02-18 11:18:07.560103', NULL, '2025-02-18 16:05:51.201419', NULL);
INSERT INTO "public"."gen_table" VALUES (15, 'env_device_setting_records', '设备控制记录', '', '', 'EnvDeviceSettingRecords', 'crud', 'element-plus', 'com.ecat.integration.EnvDeviceManagerIntegration', 'device_setting', 'records', '设备控制记录', 'caohongbo', '0', NULL, '{"parentMenuId":1062}', 'admin', '2025-05-26 13:52:37.572308', NULL, '2025-05-28 17:16:25.946068', NULL);
INSERT INTO "public"."gen_table" VALUES (18, 'env_device_settings', '设备控制设置', '', '', 'EnvDeviceSettings', 'crud', 'element-plus', 'com.ecat.integration.EnvDeviceManagerIntegration', 'device_control_setting', 'settings', '设备控制设置', 'dreamfalls', '0', NULL, '{"parentMenuId":1061}', 'admin', '2025-05-26 17:44:06.741238', NULL, '2025-05-27 08:49:24.000301', '设备控制设置');
INSERT INTO "public"."gen_table" VALUES (20, 'env_patrol_records', '巡检记录表', '', '', 'EnvPatrolRecords', 'crud', 'element-plus', 'com.ecat.integration.EnvPatrolManagerIntegration', 'patrol', 'records', '巡检记录', 'caohongbo', '0', NULL, '{"parentMenuId":0}', 'admin', '2025-05-27 00:33:04.833457', NULL, '2025-05-27 14:12:44.11736', NULL);
INSERT INTO "public"."gen_table" VALUES (13, 'env_alarm_settings', '报警设置', '', '', 'EnvAlarmSettings', 'crud', 'element-plus', 'com.ecat.integration.EnvAlarmManagerIntegration', 'alarm_setting', 'settings', '报警设置', 'dreamfalls', '0', NULL, '{"parentMenuId":1061}', 'admin', '2025-05-26 11:07:24.593338', NULL, '2025-05-26 15:44:31.85283', NULL);
INSERT INTO "public"."gen_table" VALUES (10, 'tasks', '任务表', '', '', 'Tasks', 'crud', 'element-ui', 'com.ruoyi.station', 'task', 'tasks', '任务，用于存储任务相关信息', 'sms', '0', NULL, '{"parentMenuId":1061}', 'admin', '2025-02-24 13:11:03.07814', NULL, '2025-02-24 16:52:07.940855', NULL);
INSERT INTO "public"."gen_table" VALUES (8, 'env_data_manager_events', '事件表', '', '', 'Events', 'crud', 'element-ui', 'com.ecat.integration', 'event', 'events', '事件管理', 'dreamfalls', '0', NULL, '{"parentMenuId":1061}', 'admin', '2025-02-18 09:56:57.214503', NULL, '2025-05-16 15:07:13.56681', NULL);
INSERT INTO "public"."gen_table" VALUES (11, 'env_data_manager_alarms', '报警管理', '', '', 'Alarms', 'crud', 'element-plus', 'com.ecat.integration', 'alarm', 'alarms', '报警管理', 'dreamfalls', '0', NULL, '{"parentMenuId":1061}', 'admin', '2025-05-16 11:29:44.54617', NULL, '2025-05-16 15:07:26.69476', NULL);
INSERT INTO "public"."gen_table" VALUES (24, 'env_access_control_records', '门禁记录表', '', '', 'EnvAccessControlRecords', 'crud', 'element-plus', 'com.ecat.integration.EnvAccessControlIntegration', 'access_control', 'records', '门禁记录', 'caohongbo', '0', NULL, '{"parentMenuId":1062}', 'admin', '2025-05-28 23:32:21.524423', NULL, '2025-05-29 08:30:18.820887', NULL);
INSERT INTO "public"."gen_table" VALUES (23, 'env_material_records', '物资使用记录表', '', '', 'EnvMaterialRecords', 'crud', 'element-plus', 'com.ecat.integration.EnvMaterialRecordsIntegration', 'material', 'records', '物资使用记录', 'caohongbo', '0', NULL, '{"parentMenuId":1062}', 'admin', '2025-05-27 17:06:28.966257', NULL, '2025-05-30 09:21:41.811883', NULL);
INSERT INTO "public"."gen_table" VALUES (22, 'env_material_manager', '物资管理表', '', '', 'EnvMaterialManager', 'crud', 'element-plus', 'com.ecat.integration.EnvMaterialManagerIntegration', 'material', 'manager', '物资管理', 'caohongbo', '0', NULL, '{"parentMenuId":1062}', 'admin', '2025-05-27 17:06:28.966257', NULL, '2025-05-28 13:42:32.027258', NULL);
INSERT INTO "public"."gen_table" VALUES (25, 'realdata', '原始数据', '', '', 'Realdata', 'crud', 'element-plus', 'com.ecat.integration.EnvDataManagerIntegration', 'realdata', 'realdata', '原始数据', 'dreamfalls', '0', NULL, '{"parentMenuId":1061}', 'admin', '2025-06-13 14:14:21.10248', NULL, '2025-06-16 10:04:37.185004', NULL);

CREATE TABLE "public"."gen_table_column" (
  "column_id" int8 NOT NULL DEFAULT nextval('gen_table_column_column_id_seq'::regclass),
  "table_id" varchar(64) COLLATE "pg_catalog"."default",
  "column_name" varchar(200) COLLATE "pg_catalog"."default",
  "column_comment" varchar(500) COLLATE "pg_catalog"."default",
  "column_type" varchar(100) COLLATE "pg_catalog"."default",
  "java_type" varchar(500) COLLATE "pg_catalog"."default",
  "java_field" varchar(200) COLLATE "pg_catalog"."default",
  "is_pk" char(1) COLLATE "pg_catalog"."default",
  "is_increment" char(1) COLLATE "pg_catalog"."default",
  "is_required" char(1) COLLATE "pg_catalog"."default",
  "is_insert" char(1) COLLATE "pg_catalog"."default",
  "is_edit" char(1) COLLATE "pg_catalog"."default",
  "is_list" char(1) COLLATE "pg_catalog"."default",
  "is_query" char(1) COLLATE "pg_catalog"."default",
  "query_type" varchar(200) COLLATE "pg_catalog"."default",
  "html_type" varchar(200) COLLATE "pg_catalog"."default",
  "dict_type" varchar(200) COLLATE "pg_catalog"."default" DEFAULT ''::character varying,
  "sort" int4,
  "create_by" varchar(64) COLLATE "pg_catalog"."default",
  "create_time" timestamp(6),
  "update_by" varchar(64) COLLATE "pg_catalog"."default",
  "update_time" timestamp(6)
)
;
COMMENT ON COLUMN "public"."gen_table_column"."column_id" IS '编号';
COMMENT ON COLUMN "public"."gen_table_column"."table_id" IS '归属表编号';
COMMENT ON COLUMN "public"."gen_table_column"."column_name" IS '列名称';
COMMENT ON COLUMN "public"."gen_table_column"."column_comment" IS '列描述';
COMMENT ON COLUMN "public"."gen_table_column"."column_type" IS '列类型';
COMMENT ON COLUMN "public"."gen_table_column"."java_type" IS 'JAVA类型';
COMMENT ON COLUMN "public"."gen_table_column"."java_field" IS 'JAVA字段名';
COMMENT ON COLUMN "public"."gen_table_column"."is_pk" IS '是否主键（1是）';
COMMENT ON COLUMN "public"."gen_table_column"."is_increment" IS '是否自增（1是）';
COMMENT ON COLUMN "public"."gen_table_column"."is_required" IS '是否必填（1是）';
COMMENT ON COLUMN "public"."gen_table_column"."is_insert" IS '是否为插入字段（1是）';
COMMENT ON COLUMN "public"."gen_table_column"."is_edit" IS '是否编辑字段（1是）';
COMMENT ON COLUMN "public"."gen_table_column"."is_list" IS '是否列表字段（1是）';
COMMENT ON COLUMN "public"."gen_table_column"."is_query" IS '是否查询字段（1是）';
COMMENT ON COLUMN "public"."gen_table_column"."query_type" IS '查询方式（等于、不等于、大于、小于、范围）';
COMMENT ON COLUMN "public"."gen_table_column"."html_type" IS '显示类型（文本框、文本域、下拉框、复选框、单选框、日期控件）';
COMMENT ON COLUMN "public"."gen_table_column"."dict_type" IS '字典类型';
COMMENT ON COLUMN "public"."gen_table_column"."sort" IS '排序';
COMMENT ON COLUMN "public"."gen_table_column"."create_by" IS '创建者';
COMMENT ON COLUMN "public"."gen_table_column"."create_time" IS '创建时间';
COMMENT ON COLUMN "public"."gen_table_column"."update_by" IS '更新者';
COMMENT ON COLUMN "public"."gen_table_column"."update_time" IS '更新时间';
COMMENT ON TABLE "public"."gen_table_column" IS '代码生成业务表字段';

INSERT INTO "public"."gen_table_column" VALUES (69, '6', 'last_data_time', '最后数据时间', 'timestamp without time zone', 'String', 'lastDataTime', '0', '0', '0', '0', '0', '1', '0', 'EQ', 'datetime', '', 9, 'admin', '2025-02-14 14:15:58.271971', NULL, '2025-02-14 14:35:00.401418');
INSERT INTO "public"."gen_table_column" VALUES (72, '7', 'para_id', 'ID', 'integer', 'Long', 'paraId', '1', '0', '0', '0', NULL, NULL, NULL, 'EQ', 'input', '', 1, 'admin', '2025-02-14 15:06:30.342815', NULL, '2025-02-14 16:06:38.269918');
INSERT INTO "public"."gen_table_column" VALUES (73, '7', 'pa_name', '参数名称', 'character varying', 'String', 'paName', '0', '0', '1', '1', '1', '1', '1', 'LIKE', 'input', '', 2, 'admin', '2025-02-14 15:06:30.342815', NULL, '2025-02-14 16:06:38.269918');
INSERT INTO "public"."gen_table_column" VALUES (74, '7', 'pa_unit', '参数单位', 'character varying', 'String', 'paUnit', '0', '0', '0', '1', '1', '1', '0', 'EQ', 'input', '', 3, 'admin', '2025-02-14 15:06:30.342815', NULL, '2025-02-14 16:06:38.269918');
INSERT INTO "public"."gen_table_column" VALUES (75, '7', 'cmd', '参数指令', 'character varying', 'String', 'cmd', '0', '0', '0', '1', '1', '1', '0', 'EQ', 'input', '', 4, 'admin', '2025-02-14 15:06:30.342815', NULL, '2025-02-14 16:06:38.269918');
INSERT INTO "public"."gen_table_column" VALUES (76, '7', 'cmd_name', '指令名称', 'character varying', 'String', 'cmdName', '0', '0', '0', '1', '1', '1', '0', 'LIKE', 'input', '', 5, 'admin', '2025-02-14 15:06:30.342815', NULL, '2025-02-14 16:06:38.269918');
INSERT INTO "public"."gen_table_column" VALUES (77, '7', 'value_type', '数据类型', 'character varying', 'String', 'valueType', '0', '0', '0', '1', '1', '1', '0', 'EQ', 'select', 'sys_data_type', 6, 'admin', '2025-02-14 15:06:30.342815', NULL, '2025-02-14 16:06:38.269918');
INSERT INTO "public"."gen_table_column" VALUES (78, '7', 'pid', '参数英文标识', 'character varying', 'String', 'pid', '1', '0', '1', '1', '1', '1', '0', 'EQ', 'input', '', 7, 'admin', '2025-02-14 15:06:30.342815', NULL, '2025-02-14 16:06:38.269918');
INSERT INTO "public"."gen_table_column" VALUES (79, '7', 'pname', '参数中文标识', 'character varying', 'String', 'pname', '0', '0', '1', '1', '1', '1', '0', 'LIKE', 'input', '', 8, 'admin', '2025-02-14 15:06:30.342815', NULL, '2025-02-14 16:06:38.269918');
INSERT INTO "public"."gen_table_column" VALUES (80, '7', 'st_code', '设备编码', 'character varying', 'String', 'stCode', '1', '0', '1', '1', '1', '1', '0', 'EQ', 'select', '', 9, 'admin', '2025-02-14 15:06:30.342815', NULL, '2025-02-14 16:06:38.269918');
INSERT INTO "public"."gen_table_column" VALUES (81, '7', 'cmd_type', '指令类型', 'character varying', 'String', 'cmdType', '0', '0', '0', '1', '1', '1', '0', 'EQ', 'select', '', 10, 'admin', '2025-02-14 15:06:30.342815', NULL, '2025-02-14 16:06:38.269918');
INSERT INTO "public"."gen_table_column" VALUES (82, '7', 'orderby', '排序', 'integer', 'Long', 'orderby', '0', '0', '0', '1', '1', '1', '0', 'EQ', 'input', '', 11, 'admin', '2025-02-14 15:06:30.342815', NULL, '2025-02-14 16:06:38.269918');
INSERT INTO "public"."gen_table_column" VALUES (83, '7', 'create_time', '创建时间', 'timestamp without time zone', 'Date', 'createTime', '0', '0', '0', '0', NULL, NULL, NULL, 'EQ', NULL, '', 15, 'admin', '2025-02-14 15:06:30.342815', NULL, '2025-02-14 16:06:38.269918');
INSERT INTO "public"."gen_table_column" VALUES (70, '6', 'device_type', '设备类型', 'character varying', 'String', 'deviceType', '0', '0', '1', '1', '1', '1', '1', 'EQ', 'select', 'sys_device_type', 10, 'admin', '2025-02-14 14:15:58.271971', NULL, '2025-02-14 14:35:00.401418');
INSERT INTO "public"."gen_table_column" VALUES (71, '6', 'orderby', '设备排序', 'integer', 'Long', 'orderby', '0', '0', '1', '1', '1', '1', '0', 'EQ', 'input', '', 11, 'admin', '2025-02-14 14:15:58.271971', NULL, '2025-02-14 14:35:00.401418');
INSERT INTO "public"."gen_table_column" VALUES (84, '7', 'update_time', '更新时间', 'timestamp without time zone', 'Date', 'updateTime', '0', '0', '0', '0', '0', NULL, NULL, 'EQ', NULL, '', 17, 'admin', '2025-02-14 15:06:30.342815', NULL, '2025-02-14 16:06:38.269918');
INSERT INTO "public"."gen_table_column" VALUES (61, '6', 'sta_id', 'ID自增', 'integer', 'Long', 'staId', '1', '0', '0', '0', NULL, NULL, NULL, 'EQ', 'input', '', 1, 'admin', '2025-02-14 14:15:58.271971', NULL, '2025-02-14 14:35:00.401418');
INSERT INTO "public"."gen_table_column" VALUES (62, '6', 'sta_name', '设备名称', 'character varying', 'String', 'staName', '0', '0', '1', '1', '1', '1', '1', 'LIKE', 'input', '', 2, 'admin', '2025-02-14 14:15:58.271971', NULL, '2025-02-14 14:35:00.401418');
INSERT INTO "public"."gen_table_column" VALUES (63, '6', 'st_code', '设备编码', 'character varying', 'String', 'stCode', '0', '0', '1', '1', '1', '1', '1', 'EQ', 'input', '', 3, 'admin', '2025-02-14 14:15:58.271971', NULL, '2025-02-14 14:35:00.401418');
INSERT INTO "public"."gen_table_column" VALUES (64, '6', 'com', '设备COM口', 'character varying', 'String', 'com', '0', '0', '1', '1', '1', '1', '1', 'EQ', 'select', 'sys_device_com', 4, 'admin', '2025-02-14 14:15:58.271971', NULL, '2025-02-14 14:35:00.401418');
INSERT INTO "public"."gen_table_column" VALUES (65, '6', 'protocol_type', '协议类型', 'character varying', 'String', 'protocolType', '0', '0', '1', '1', '1', '1', '1', 'EQ', 'select', 'sys_device_pro', 5, 'admin', '2025-02-14 14:15:58.271971', NULL, '2025-02-14 14:35:00.401418');
INSERT INTO "public"."gen_table_column" VALUES (66, '6', 'st_number', '物理设备ID', 'character varying', 'String', 'stNumber', '0', '0', '1', '1', '1', '1', '0', 'EQ', 'input', '', 6, 'admin', '2025-02-14 14:15:58.271971', NULL, '2025-02-14 14:35:00.401418');
INSERT INTO "public"."gen_table_column" VALUES (67, '6', 'create_time', '创建时间', 'timestamp without time zone', 'String', 'createTime', '0', '0', '0', '0', NULL, '1', NULL, 'EQ', 'datetime', '', 7, 'admin', '2025-02-14 14:15:58.271971', NULL, '2025-02-14 14:35:00.401418');
INSERT INTO "public"."gen_table_column" VALUES (68, '6', 'update_time', '更新时间', 'timestamp without time zone', 'String', 'updateTime', '0', '0', '0', '0', '0', '1', NULL, 'EQ', 'datetime', '', 8, 'admin', '2025-02-14 14:15:58.271971', NULL, '2025-02-14 14:35:00.401418');
INSERT INTO "public"."gen_table_column" VALUES (88, '8', 'update_time', '更新时间', 'timestamp without time zone', 'String', 'updateTime', '0', '0', '0', '0', '0', '1', NULL, 'EQ', NULL, '', 4, 'admin', '2025-02-18 09:56:57.214503', NULL, '2025-05-16 15:07:13.56681');
INSERT INTO "public"."gen_table_column" VALUES (89, '8', 'end_time', '结束时间', 'timestamp without time zone', 'String', 'endTime', '0', '0', '0', '0', '0', '1', '0', 'LTE', NULL, '', 5, 'admin', '2025-02-18 09:56:57.214503', NULL, '2025-05-16 15:07:13.56681');
INSERT INTO "public"."gen_table_column" VALUES (90, '8', 'description', '事件描述', 'text', 'String', 'description', '0', '0', '0', '1', '1', '1', '1', 'EQ', 'textarea', '', 6, 'admin', '2025-02-18 09:56:57.214503', NULL, '2025-05-16 15:07:13.56681');
INSERT INTO "public"."gen_table_column" VALUES (91, '8', 'severity_level', '事件等级', 'character varying', 'String', 'severityLevel', '0', '0', '0', '1', '1', '1', '1', 'EQ', 'select', 'event_security', 7, 'admin', '2025-02-18 09:56:57.214503', NULL, '2025-05-16 15:07:13.56681');
INSERT INTO "public"."gen_table_column" VALUES (92, '8', 'status', '事件状态', 'character varying', 'String', 'status', '0', '0', '0', '1', '1', '1', '1', 'EQ', 'select', 'event_type', 8, 'admin', '2025-02-18 09:56:57.214503', NULL, '2025-05-16 15:07:13.56681');
INSERT INTO "public"."gen_table_column" VALUES (93, '8', 'created_by', '创建人', 'character varying', 'String', 'createdBy', '0', '0', '0', '0', '0', '1', '0', 'EQ', NULL, '', 9, 'admin', '2025-02-18 09:56:57.214503', NULL, '2025-05-16 15:07:13.56681');
INSERT INTO "public"."gen_table_column" VALUES (94, '8', 'updated_by', '更新人', 'character varying', 'String', 'updatedBy', '0', '0', '0', '0', '1', '1', '0', 'EQ', NULL, '', 10, 'admin', '2025-02-18 09:56:57.214503', NULL, '2025-05-16 15:07:13.56681');
INSERT INTO "public"."gen_table_column" VALUES (85, '8', 'event_id', '事件ID', 'integer', 'Long', 'eventId', '1', '1', '0', '0', NULL, NULL, NULL, 'EQ', 'input', '', 1, 'admin', '2025-02-18 09:56:57.214503', NULL, '2025-05-16 15:07:13.56681');
INSERT INTO "public"."gen_table_column" VALUES (86, '8', 'event_type', '事件类型', 'integer', 'Long', 'eventType', '0', '0', '1', '1', '1', '1', '1', 'EQ', 'select', 'event_type', 2, 'admin', '2025-02-18 09:56:57.214503', NULL, '2025-05-16 15:07:13.56681');
INSERT INTO "public"."gen_table_column" VALUES (87, '8', 'start_time', '事件开始时间', 'timestamp without time zone', 'String', 'startTime', '0', '0', '0', '0', '0', '1', '1', 'BETWEEN', 'datetime', '', 3, 'admin', '2025-02-18 09:56:57.214503', NULL, '2025-05-16 15:07:13.56681');
INSERT INTO "public"."gen_table_column" VALUES (214, '19', 'id', '记录ID', 'integer', 'Long', 'id', '1', '0', '0', '0', NULL, NULL, NULL, 'EQ', 'input', '', 1, 'admin', '2025-05-26 18:11:26.072269', NULL, '2025-05-28 16:34:42.364938');
INSERT INTO "public"."gen_table_column" VALUES (215, '19', 'maintenance_mode', '维护模式', 'character varying', 'String', 'maintenanceMode', '0', '0', '1', '1', '1', '1', '1', 'EQ', 'select', 'maintenance_mode', 2, 'admin', '2025-05-26 18:11:26.072269', NULL, '2025-05-28 16:34:42.364938');
INSERT INTO "public"."gen_table_column" VALUES (264, '23', 'id', '记录ID', 'integer', 'Long', 'id', '1', '0', '0', '0', NULL, NULL, NULL, 'EQ', 'input', '', 1, 'admin', '2025-05-27 17:06:28.966257', NULL, '2025-05-30 09:21:41.811883');
INSERT INTO "public"."gen_table_column" VALUES (265, '23', 'material_code', '物资编号', 'character varying', 'String', 'materialCode', '0', '0', '1', '1', '1', '1', '1', 'LIKE', 'input', '', 2, 'admin', '2025-05-27 17:06:28.966257', NULL, '2025-05-30 09:21:41.811883');
INSERT INTO "public"."gen_table_column" VALUES (266, '23', 'usage_time', '使用时间', 'timestamp without time zone', 'Date', 'usageTime', '0', '0', '1', '1', '1', '1', '1', 'BETWEEN', 'datetime', '', 3, 'admin', '2025-05-27 17:06:28.966257', NULL, '2025-05-30 09:21:41.811883');
INSERT INTO "public"."gen_table_column" VALUES (267, '23', 'usage_capacity', '使用量', 'numeric', 'String', 'usageCapacity', '0', '0', '0', '1', '1', '1', '0', 'EQ', NULL, '', 4, 'admin', '2025-05-27 17:06:28.966257', NULL, '2025-05-30 09:21:41.811883');
INSERT INTO "public"."gen_table_column" VALUES (268, '23', 'remarks', '使用备注', 'text', 'String', 'remarks', '0', '0', '0', '1', '1', '1', '0', 'EQ', 'textarea', '', 5, 'admin', '2025-05-27 17:06:28.966257', NULL, '2025-05-30 09:21:41.811883');
INSERT INTO "public"."gen_table_column" VALUES (269, '23', 'created_by', '创建人', 'character varying', 'String', 'createdBy', '0', '0', '1', '0', '0', '1', '0', 'EQ', NULL, '', 6, 'admin', '2025-05-27 17:06:28.966257', NULL, '2025-05-30 09:21:41.811883');
INSERT INTO "public"."gen_table_column" VALUES (270, '23', 'updated_by', '更新人', 'character varying', 'String', 'updatedBy', '0', '0', '1', '0', '0', '1', '1', 'LIKE', 'input', '', 7, 'admin', '2025-05-27 17:06:28.966257', NULL, '2025-05-30 09:21:41.811883');
INSERT INTO "public"."gen_table_column" VALUES (283, '24', 'created_by', '创建人', 'character varying', 'String', 'createdBy', '0', '0', '1', '0', '0', '1', '0', 'EQ', NULL, '', 11, 'admin', '2025-05-28 23:32:21.524423', NULL, '2025-05-29 08:30:18.820887');
INSERT INTO "public"."gen_table_column" VALUES (95, '8', 'sta_code', '设备编码', 'character varying', 'String', 'staCode', '0', '0', '1', '1', '1', '1', '1', 'EQ', 'select', '', 11, 'admin', '2025-02-18 09:56:57.214503', NULL, '2025-05-16 15:07:13.56681');
INSERT INTO "public"."gen_table_column" VALUES (284, '24', 'updated_by', '更新人', 'character varying', 'String', 'updatedBy', '0', '0', '1', '0', '0', '1', '0', 'EQ', NULL, '', 12, 'admin', '2025-05-28 23:32:21.524423', NULL, '2025-05-29 08:30:18.820887');
INSERT INTO "public"."gen_table_column" VALUES (222, '19', 'update_time', '更新时间', 'timestamp without time zone', 'Date', 'updateTime', '0', '0', '1', '0', '0', NULL, NULL, 'EQ', NULL, '', 9, 'admin', '2025-05-26 18:11:26.072269', NULL, '2025-05-28 16:34:42.364938');
INSERT INTO "public"."gen_table_column" VALUES (96, '9', 'id', 'id', 'bigint', 'Long', 'id', '1', '1', '0', '0', NULL, NULL, NULL, 'EQ', 'input', '', 1, 'admin', '2025-02-18 11:18:07.560103', NULL, '2025-02-18 16:05:51.201419');
INSERT INTO "public"."gen_table_column" VALUES (97, '9', 'station_id', '设备编码', 'character varying', 'String', 'stationId', '0', '0', '1', '1', '1', '1', '1', 'LIKE', 'select', '', 2, 'admin', '2025-02-18 11:18:07.560103', NULL, '2025-02-18 16:05:51.201419');
INSERT INTO "public"."gen_table_column" VALUES (98, '9', 'thing_id', '采集类型', 'character varying', 'String', 'thingId', '0', '0', '1', '1', '1', '1', '1', 'EQ', 'select', 'thing_type', 3, 'admin', '2025-02-18 11:18:07.560103', NULL, '2025-02-18 16:05:51.201419');
INSERT INTO "public"."gen_table_column" VALUES (99, '9', 'model_id', '参数', 'character varying', 'String', 'modelId', '0', '0', '1', '1', '1', '1', '1', 'EQ', 'select', '', 4, 'admin', '2025-02-18 11:18:07.560103', NULL, '2025-02-18 16:05:51.201419');
INSERT INTO "public"."gen_table_column" VALUES (100, '9', 'classify', '数据类型', 'character varying', 'String', 'classify', '0', '0', '0', '1', '1', '1', '1', 'EQ', 'select', 'data_type', 5, 'admin', '2025-02-18 11:18:07.560103', NULL, '2025-02-18 16:05:51.201419');
INSERT INTO "public"."gen_table_column" VALUES (101, '9', 'status', '数据状态', 'bigint', 'Long', 'status', '0', '0', '0', '1', '1', '1', '1', 'EQ', 'select', 'data_sign', 6, 'admin', '2025-02-18 11:18:07.560103', NULL, '2025-02-18 16:05:51.201419');
INSERT INTO "public"."gen_table_column" VALUES (285, '24', 'create_time', '创建时间', 'timestamp without time zone', 'String', 'createTime', '0', '0', '1', '0', NULL, NULL, NULL, 'EQ', NULL, '', 13, 'admin', '2025-05-28 23:32:21.524423', NULL, '2025-05-29 08:30:18.820887');
INSERT INTO "public"."gen_table_column" VALUES (110, '10', 'task_id', '任务ID', 'integer', 'Long', 'taskId', '1', '1', '0', '1', NULL, NULL, NULL, 'EQ', 'input', '', 1, 'admin', '2025-02-24 13:11:03.07814', NULL, '2025-02-24 16:52:07.940855');
INSERT INTO "public"."gen_table_column" VALUES (111, '10', 'task_name', '任务名称', 'character varying', 'String', 'taskName', '0', '0', '1', '1', '1', '1', '1', 'LIKE', 'input', '', 2, 'admin', '2025-02-24 13:11:03.07814', NULL, '2025-02-24 16:52:07.940855');
INSERT INTO "public"."gen_table_column" VALUES (112, '10', 'task_type', '任务类型', 'integer', 'Long', 'taskType', '0', '0', '1', '1', '1', '1', '1', 'EQ', 'select', 'task_type', 3, 'admin', '2025-02-24 13:11:03.07814', NULL, '2025-02-24 16:52:07.940855');
INSERT INTO "public"."gen_table_column" VALUES (113, '10', 'start_time', '任务开始时间', 'timestamp without time zone', 'Date', 'startTime', '0', '0', '0', '1', '1', '1', '1', 'EQ', 'datetime', '', 4, 'admin', '2025-02-24 13:11:03.07814', NULL, '2025-02-24 16:52:07.940855');
INSERT INTO "public"."gen_table_column" VALUES (114, '10', 'end_time', '任务结束时间', 'timestamp without time zone', 'Date', 'endTime', '0', '0', '0', '1', '1', '1', '1', 'EQ', 'datetime', '', 5, 'admin', '2025-02-24 13:11:03.07814', NULL, '2025-02-24 16:52:07.940855');
INSERT INTO "public"."gen_table_column" VALUES (115, '10', 'request_content', '任务内容', 'text', 'String', 'requestContent', '0', '0', '0', '1', '1', '1', '1', 'EQ', 'fileUpload', '', 6, 'admin', '2025-02-24 13:11:03.07814', NULL, '2025-02-24 16:52:07.940855');
INSERT INTO "public"."gen_table_column" VALUES (116, '10', 'task_status', '任务状态', 'character varying', 'String', 'taskStatus', '0', '0', '1', '1', '1', '1', '1', 'EQ', 'radio', 'task_status', 7, 'admin', '2025-02-24 13:11:03.07814', NULL, '2025-02-24 16:52:07.940855');
INSERT INTO "public"."gen_table_column" VALUES (117, '10', 'response_content', '返回内容', 'text', 'String', 'responseContent', '0', '0', '0', '1', '1', '1', '1', 'EQ', 'editor', '', 8, 'admin', '2025-02-24 13:11:03.07814', NULL, '2025-02-24 16:52:07.940855');
INSERT INTO "public"."gen_table_column" VALUES (118, '10', 'create_time', '任务创建时间', 'timestamp without time zone', 'Date', 'createTime', '0', '0', '0', '1', NULL, NULL, NULL, 'EQ', NULL, '', 9, 'admin', '2025-02-24 13:11:03.07814', NULL, '2025-02-24 16:52:07.940855');
INSERT INTO "public"."gen_table_column" VALUES (119, '10', 'update_time', '任务更新时间', 'timestamp without time zone', 'Date', 'updateTime', '0', '0', '0', '1', '1', NULL, NULL, 'EQ', NULL, '', 10, 'admin', '2025-02-24 13:11:03.07814', NULL, '2025-02-24 16:52:07.940855');
INSERT INTO "public"."gen_table_column" VALUES (286, '24', 'update_time', '更新时间', 'timestamp without time zone', 'String', 'updateTime', '0', '0', '1', '0', '0', NULL, NULL, 'EQ', NULL, '', 14, 'admin', '2025-05-28 23:32:21.524423', NULL, '2025-05-29 08:30:18.820887');
INSERT INTO "public"."gen_table_column" VALUES (271, '23', 'create_time', '创建时间', 'timestamp without time zone', 'Date', 'createTime', '0', '0', '1', '0', NULL, NULL, NULL, 'EQ', NULL, '', 8, 'admin', '2025-05-27 17:06:28.966257', NULL, '2025-05-30 09:21:41.811883');
INSERT INTO "public"."gen_table_column" VALUES (272, '23', 'update_time', '更新时间', 'timestamp without time zone', 'Date', 'updateTime', '0', '0', '1', '0', '0', NULL, NULL, 'EQ', NULL, '', 9, 'admin', '2025-05-27 17:06:28.966257', NULL, '2025-05-30 09:21:41.811883');
INSERT INTO "public"."gen_table_column" VALUES (102, '9', 'field', '参数', 'character varying', 'String', 'field', '0', '0', '1', '1', '1', '1', '0', 'EQ', 'input', '', 7, 'admin', '2025-02-18 11:18:07.560103', NULL, '2025-02-18 16:05:51.201419');
INSERT INTO "public"."gen_table_column" VALUES (103, '9', 'value', '值', 'numeric', 'Integer', 'value', '0', '0', '0', '1', '1', '1', '0', 'EQ', 'input', '', 8, 'admin', '2025-02-18 11:18:07.560103', NULL, '2025-02-18 16:05:51.201419');
INSERT INTO "public"."gen_table_column" VALUES (104, '9', 'values', '多值', 'text', 'String', 'values', '0', '0', '0', '1', '1', '1', '0', 'EQ', 'textarea', '', 9, 'admin', '2025-02-18 11:18:07.560103', NULL, '2025-02-18 16:05:51.201419');
INSERT INTO "public"."gen_table_column" VALUES (105, '9', 'total', '统计条数', 'bigint', 'Long', 'total', '0', '0', '0', '1', '1', '1', '0', 'EQ', 'input', '', 10, 'admin', '2025-02-18 11:18:07.560103', NULL, '2025-02-18 16:05:51.201419');
INSERT INTO "public"."gen_table_column" VALUES (106, '9', 'unit', '单位', 'character varying', 'String', 'unit', '0', '0', '0', '1', '1', '1', '0', 'EQ', 'input', '', 11, 'admin', '2025-02-18 11:18:07.560103', NULL, '2025-02-18 16:05:51.201419');
INSERT INTO "public"."gen_table_column" VALUES (107, '9', 'pick_time', '数据时间', 'timestamp with time zone', 'Date', 'pickTime', '0', '0', '1', '1', '1', '1', '1', 'BETWEEN', 'datetime', '', 12, 'admin', '2025-02-18 11:18:07.560103', NULL, '2025-02-18 16:05:51.201419');
INSERT INTO "public"."gen_table_column" VALUES (108, '9', 'created_at', '创建时间', 'timestamp with time zone', 'Date', 'createdAt', '0', '0', '0', '0', '0', '0', '0', 'EQ', NULL, '', 13, 'admin', '2025-02-18 11:18:07.560103', NULL, '2025-02-18 16:05:51.201419');
INSERT INTO "public"."gen_table_column" VALUES (109, '9', 'updated_at', '更新时间', 'timestamp with time zone', 'Date', 'updatedAt', '0', '0', '0', '0', '0', '0', '0', 'EQ', NULL, '', 14, 'admin', '2025-02-18 11:18:07.560103', NULL, '2025-02-18 16:05:51.201419');
INSERT INTO "public"."gen_table_column" VALUES (297, '25', 'tname', '监测点名称', 'text', 'String', 'tname', '0', '0', '0', '1', '1', '0', '0', 'LIKE', 'input', '', 11, 'admin', '2025-06-13 14:14:21.10248', NULL, '2025-06-16 10:04:37.185004');
INSERT INTO "public"."gen_table_column" VALUES (298, '25', 'pn', '参数名称', 'text', 'String', 'pn', '0', '0', '0', '1', '1', '1', '1', 'LIKE', 'input', '', 12, 'admin', '2025-06-13 14:14:21.10248', NULL, '2025-06-16 10:04:37.185004');
INSERT INTO "public"."gen_table_column" VALUES (299, '25', 'sname', '设备名称', 'text', 'String', 'sname', '0', '0', '0', '1', '1', '1', '1', 'LIKE', 'input', '', 13, 'admin', '2025-06-13 14:14:21.10248', NULL, '2025-06-16 10:04:37.185004');
INSERT INTO "public"."gen_table_column" VALUES (230, '20', 'create_time', '创建时间', 'timestamp without time zone', 'Date', 'createTime', '0', '0', '0', '0', NULL, NULL, NULL, 'EQ', NULL, '', 8, 'admin', '2025-05-27 00:33:04.833457', NULL, '2025-05-27 14:12:44.11736');
INSERT INTO "public"."gen_table_column" VALUES (231, '20', 'update_time', '更新时间', 'timestamp without time zone', 'Date', 'updateTime', '0', '0', '0', '0', '0', NULL, NULL, 'EQ', NULL, '', 9, 'admin', '2025-05-27 00:33:04.833457', NULL, '2025-05-27 14:12:44.11736');
INSERT INTO "public"."gen_table_column" VALUES (123, '11', 'alarm_id', '报警ID', 'integer', 'Long', 'alarmId', '0', '0', '0', '0', '0', '0', '0', 'EQ', 'input', '', 1, 'admin', '2025-05-16 11:29:44.54617', NULL, '2025-05-16 15:07:26.69476');
INSERT INTO "public"."gen_table_column" VALUES (124, '11', 'alarm_type', '报警类型', 'integer', 'Long', 'alarmType', '0', '0', '1', '1', '1', '1', '1', 'EQ', 'select', 'alarm_type', 2, 'admin', '2025-05-16 11:29:44.54617', NULL, '2025-05-16 15:07:26.69476');
INSERT INTO "public"."gen_table_column" VALUES (125, '11', 'start_time', '报警开始时间', 'timestamp without time zone', 'String', 'startTime', '0', '0', '0', '0', '0', '1', '1', 'BETWEEN', 'datetime', '', 3, 'admin', '2025-05-16 11:29:44.54617', NULL, '2025-05-16 15:07:26.69476');
INSERT INTO "public"."gen_table_column" VALUES (126, '11', 'update_time', '更新时间', 'timestamp without time zone', 'String', 'updateTime', '0', '0', '0', '0', '0', '1', NULL, 'EQ', NULL, '', 4, 'admin', '2025-05-16 11:29:44.54617', NULL, '2025-05-16 15:07:26.69476');
INSERT INTO "public"."gen_table_column" VALUES (127, '11', 'end_time', '结束时间', 'timestamp without time zone', 'String', 'endTime', '0', '0', '0', '0', '0', '1', '0', 'EQ', NULL, '', 5, 'admin', '2025-05-16 11:29:44.54617', NULL, '2025-05-16 15:07:26.69476');
INSERT INTO "public"."gen_table_column" VALUES (128, '11', 'description', '报警描述', 'text', 'String', 'description', '0', '0', '0', '1', '1', '1', '1', 'EQ', 'textarea', '', 6, 'admin', '2025-05-16 11:29:44.54617', NULL, '2025-05-16 15:07:26.69476');
INSERT INTO "public"."gen_table_column" VALUES (129, '11', 'severity_level', '报警等级', 'character varying', 'String', 'severityLevel', '0', '0', '0', '1', '1', '1', '1', 'EQ', 'select', 'alarm_security', 7, 'admin', '2025-05-16 11:29:44.54617', NULL, '2025-05-16 15:07:26.69476');
INSERT INTO "public"."gen_table_column" VALUES (130, '11', 'status', '报警状态', 'character varying', 'String', 'status', '0', '0', '0', '1', '1', '1', '1', 'EQ', 'select', 'alarm_status', 8, 'admin', '2025-05-16 11:29:44.54617', NULL, '2025-05-16 15:07:26.69476');
INSERT INTO "public"."gen_table_column" VALUES (131, '11', 'created_by', '创建人', 'character varying', 'String', 'createdBy', '0', '0', '0', '0', '0', '1', '0', 'EQ', NULL, '', 9, 'admin', '2025-05-16 11:29:44.54617', NULL, '2025-05-16 15:07:26.69476');
INSERT INTO "public"."gen_table_column" VALUES (132, '11', 'updated_by', '更新人', 'character varying', 'String', 'updatedBy', '0', '0', '0', '0', '1', '1', '0', 'EQ', NULL, '', 10, 'admin', '2025-05-16 11:29:44.54617', NULL, '2025-05-16 15:07:26.69476');
INSERT INTO "public"."gen_table_column" VALUES (120, '10', 'create_by', '任务创建人', 'character varying', 'String', 'createBy', '0', '0', '0', '1', NULL, NULL, NULL, 'EQ', NULL, '', 11, 'admin', '2025-02-24 13:11:03.07814', NULL, '2025-02-24 16:52:07.940855');
INSERT INTO "public"."gen_table_column" VALUES (121, '10', 'update_by', '任务修改人', 'character varying', 'String', 'updateBy', '0', '0', '0', '1', '1', NULL, NULL, 'EQ', NULL, '', 12, 'admin', '2025-02-24 13:11:03.07814', NULL, '2025-02-24 16:52:07.940855');
INSERT INTO "public"."gen_table_column" VALUES (122, '10', 'notes', '任务备注信息', 'text', 'String', 'notes', '0', '0', '0', '1', '1', '1', '1', 'EQ', 'textarea', '', 13, 'admin', '2025-02-24 13:11:03.07814', NULL, '2025-02-24 16:52:07.940855');
INSERT INTO "public"."gen_table_column" VALUES (133, '11', 'sta_code', '设备编码', 'character varying', 'String', 'staCode', '0', '0', '1', '1', '1', '1', '1', 'EQ', 'select', '', 11, 'admin', '2025-05-16 11:29:44.54617', NULL, '2025-05-16 15:07:26.69476');
INSERT INTO "public"."gen_table_column" VALUES (262, '22', 'create_time', '创建时间', 'timestamp without time zone', 'Date', 'createTime', '0', '0', '1', '0', NULL, NULL, NULL, 'EQ', NULL, '', 18, 'admin', '2025-05-27 17:06:28.966257', NULL, '2025-05-28 13:42:32.027258');
INSERT INTO "public"."gen_table_column" VALUES (263, '22', 'update_time', '更新时间', 'timestamp without time zone', 'Date', 'updateTime', '0', '0', '1', '0', '0', NULL, NULL, 'EQ', NULL, '', 19, 'admin', '2025-05-27 17:06:28.966257', NULL, '2025-05-28 13:42:32.027258');
INSERT INTO "public"."gen_table_column" VALUES (223, '20', 'id', '记录ID', 'integer', 'Long', 'id', '1', '0', '0', '0', NULL, NULL, NULL, 'EQ', 'input', '', 1, 'admin', '2025-05-27 00:33:04.833457', NULL, '2025-05-27 14:12:44.11736');
INSERT INTO "public"."gen_table_column" VALUES (224, '20', 'generation_time', '生成时间', 'timestamp without time zone', 'Date', 'generationTime', '0', '0', '1', '0', '0', '1', '1', 'BETWEEN', 'datetime', '', 2, 'admin', '2025-05-27 00:33:04.833457', NULL, '2025-05-27 14:12:44.11736');
INSERT INTO "public"."gen_table_column" VALUES (225, '20', 'patrol_type', '巡检类型', 'character varying', 'String', 'patrolType', '0', '0', '1', '1', '0', '1', '1', 'EQ', 'select', 'patrol_type', 3, 'admin', '2025-05-27 00:33:04.833457', NULL, '2025-05-27 14:12:44.11736');
INSERT INTO "public"."gen_table_column" VALUES (226, '20', 'patrol_notes', '巡检备注', 'text', 'String', 'patrolNotes', '0', '0', '0', '1', '1', '1', '1', 'EQ', 'textarea', '', 4, 'admin', '2025-05-27 00:33:04.833457', NULL, '2025-05-27 14:12:44.11736');
INSERT INTO "public"."gen_table_column" VALUES (227, '20', 'patrol_content', '巡检内容', 'text', 'String', 'patrolContent', '0', '0', '0', '1', '1', '1', '1', 'EQ', 'textarea', '', 5, 'admin', '2025-05-27 00:33:04.833457', NULL, '2025-05-27 14:12:44.11736');
INSERT INTO "public"."gen_table_column" VALUES (228, '20', 'created_by', '创建人', 'character varying', 'String', 'createdBy', '0', '0', '0', '1', '1', '1', '1', 'EQ', 'input', '', 6, 'admin', '2025-05-27 00:33:04.833457', NULL, '2025-05-27 14:12:44.11736');
INSERT INTO "public"."gen_table_column" VALUES (151, '13', 'id', '设置ID', 'integer', 'Long', 'id', '1', '0', '0', '0', NULL, '1', NULL, 'EQ', 'input', '', 1, 'admin', '2025-05-26 11:07:24.593338', NULL, '2025-05-26 15:44:31.85283');
INSERT INTO "public"."gen_table_column" VALUES (152, '13', 'alarm_type', '报警类型', 'character varying', 'String', 'alarmType', '0', '0', '1', '1', '1', '1', '1', 'EQ', 'select', 'env_alarm_type', 2, 'admin', '2025-05-26 11:07:24.593338', NULL, '2025-05-26 15:44:31.85283');
INSERT INTO "public"."gen_table_column" VALUES (229, '20', 'updated_by', '更新人', 'character varying', 'String', 'updatedBy', '0', '0', '0', '0', '0', '1', '1', 'EQ', NULL, '', 7, 'admin', '2025-05-27 00:33:04.833457', NULL, '2025-05-27 14:12:44.11736');
INSERT INTO "public"."gen_table_column" VALUES (153, '13', 'setting_content', '报警内容', 'text', 'String', 'settingContent', '0', '0', '1', '1', '1', '1', '1', 'EQ', 'textarea', '', 3, 'admin', '2025-05-26 11:07:24.593338', NULL, '2025-05-26 15:44:31.85283');
INSERT INTO "public"."gen_table_column" VALUES (154, '13', 'created_by', '创建人', 'character varying', 'String', 'createdBy', '0', '0', '1', '0', '0', '1', '0', 'EQ', NULL, '', 4, 'admin', '2025-05-26 11:07:24.593338', NULL, '2025-05-26 15:44:31.85283');
INSERT INTO "public"."gen_table_column" VALUES (155, '13', 'updated_by', '更新人', 'character varying', 'String', 'updatedBy', '0', '0', '1', '0', '0', '1', '0', 'EQ', NULL, '', 5, 'admin', '2025-05-26 11:07:24.593338', NULL, '2025-05-26 15:44:31.85283');
INSERT INTO "public"."gen_table_column" VALUES (156, '13', 'create_time', '创建时间', 'timestamp without time zone', 'Date', 'createTime', '0', '0', '1', '0', NULL, '1', NULL, 'EQ', NULL, '', 6, 'admin', '2025-05-26 11:07:24.593338', NULL, '2025-05-26 15:44:31.85283');
INSERT INTO "public"."gen_table_column" VALUES (157, '13', 'update_time', '更新时间', 'timestamp without time zone', 'Date', 'updateTime', '0', '0', '1', '0', '0', '1', NULL, 'EQ', NULL, '', 7, 'admin', '2025-05-26 11:07:24.593338', NULL, '2025-05-26 15:44:31.85283');
INSERT INTO "public"."gen_table_column" VALUES (287, '25', 'pick_time', '数据时间', 'timestamp with time zone', 'Date', 'pickTime', '0', '0', '0', '1', '1', '1', '1', 'BETWEEN', 'datetime', '', 1, 'admin', '2025-06-13 14:14:21.10248', NULL, '2025-06-16 10:04:37.185004');
INSERT INTO "public"."gen_table_column" VALUES (288, '25', 'tid', '监测点ID', 'text', 'String', 'tid', '0', '0', '0', '1', '1', '1', '0', 'EQ', 'input', '', 2, 'admin', '2025-06-13 14:14:21.10248', NULL, '2025-06-16 10:04:37.185004');
INSERT INTO "public"."gen_table_column" VALUES (289, '25', 'pid', '参数ID ', 'text', 'String', 'pid', '0', '0', '1', '1', '1', '1', '0', 'LIKE', 'input', '', 3, 'admin', '2025-06-13 14:14:21.10248', NULL, '2025-06-16 10:04:37.185004');
INSERT INTO "public"."gen_table_column" VALUES (290, '25', 'sid', '设备ID', 'text', 'String', 'sid', '0', '0', '1', '1', '1', '1', '0', 'LIKE', 'input', '', 4, 'admin', '2025-06-13 14:14:21.10248', NULL, '2025-06-16 10:04:37.185004');
INSERT INTO "public"."gen_table_column" VALUES (291, '25', 'mindex', '索引', 'bigint', 'Long', 'mindex', '0', '0', '0', '1', '1', '0', '0', 'EQ', 'input', '', 5, 'admin', '2025-06-13 14:14:21.10248', NULL, '2025-06-16 10:04:37.185004');
INSERT INTO "public"."gen_table_column" VALUES (292, '25', 'type', '数据类型', 'text', 'String', 'type', '0', '0', '1', '1', '1', '0', '0', 'EQ', 'select', 'env_realdata_data_type', 6, 'admin', '2025-06-13 14:14:21.10248', NULL, '2025-06-16 10:04:37.185004');
INSERT INTO "public"."gen_table_column" VALUES (293, '25', 'fv', '数字值', 'numeric', 'Double', 'fv', '0', '0', '0', '1', '1', '0', '0', 'EQ', 'input', '', 7, 'admin', '2025-06-13 14:14:21.10248', NULL, '2025-06-16 10:04:37.185004');
INSERT INTO "public"."gen_table_column" VALUES (294, '25', 'sv', '字符串值', 'text', 'String', 'sv', '0', '0', '0', '1', '1', '0', '0', 'EQ', 'input', '', 8, 'admin', '2025-06-13 14:14:21.10248', NULL, '2025-06-16 10:04:37.185004');
INSERT INTO "public"."gen_table_column" VALUES (295, '25', 'iv', '整型值', 'bigint', 'Long', 'iv', '0', '0', '0', '1', '1', '0', '0', 'EQ', 'input', '', 9, 'admin', '2025-06-13 14:14:21.10248', NULL, '2025-06-16 10:04:37.185004');
INSERT INTO "public"."gen_table_column" VALUES (296, '25', 'value', '数据值', 'text', 'String', 'value', '0', '0', '0', '1', '1', '0', '0', 'EQ', 'input', '', 10, 'admin', '2025-06-13 14:14:21.10248', NULL, '2025-06-16 10:04:37.185004');
INSERT INTO "public"."gen_table_column" VALUES (204, '18', 'id', '设置ID', 'integer', 'Long', 'id', '1', '0', '0', '0', NULL, '1', NULL, 'EQ', 'input', '', 1, 'admin', '2025-05-26 17:44:06.741238', NULL, '2025-05-27 08:49:24.000301');
INSERT INTO "public"."gen_table_column" VALUES (205, '18', 'device_name', '设备名称', 'character varying', 'String', 'deviceName', '0', '0', '1', '1', '1', '1', '1', 'LIKE', 'input', '', 2, 'admin', '2025-05-26 17:44:06.741238', NULL, '2025-05-27 08:49:24.000301');
INSERT INTO "public"."gen_table_column" VALUES (206, '18', 'device_type', '设备类型', 'character varying', 'String', 'deviceType', '0', '0', '1', '1', '1', '1', '1', 'EQ', 'select', 'env_device_manager_device_type', 3, 'admin', '2025-05-26 17:44:06.741238', NULL, '2025-05-27 08:49:24.000301');
INSERT INTO "public"."gen_table_column" VALUES (301, '25', 'unit_name', '显示单位', 'text', 'String', 'unitName', '0', '0', '0', '1', '1', '1', '0', 'LIKE', 'input', '', 15, 'admin', '2025-06-13 14:14:21.10248', NULL, '2025-06-16 10:04:37.185004');
INSERT INTO "public"."gen_table_column" VALUES (193, '13', 'sort', '排序', 'integer', 'Long', 'sort', '0', '0', '0', '1', '1', '1', '1', 'EQ', 'input', '', 8, NULL, '2025-05-26 15:43:16.924342', NULL, '2025-05-26 15:44:31.85283');
INSERT INTO "public"."gen_table_column" VALUES (176, '16', 'id', '记录ID', 'integer', 'Long', 'id', '1', '0', '0', '0', NULL, '0', NULL, 'EQ', 'input', '', 1, 'admin', '2025-05-26 15:00:13.048164', NULL, '2025-05-28 14:55:52.300211');
INSERT INTO "public"."gen_table_column" VALUES (177, '16', 'task_type', '任务类型', 'character varying', 'String', 'taskType', '0', '0', '1', '1', '1', '1', '1', 'EQ', 'select', 'quality_control_task_type', 2, 'admin', '2025-05-26 15:00:13.048164', NULL, '2025-05-28 14:55:52.300211');
INSERT INTO "public"."gen_table_column" VALUES (178, '16', 'quality_control_type', '质控类型', 'character varying', 'String', 'qualityControlType', '0', '0', '1', '1', '1', '1', '1', 'EQ', 'select', 'quality_control_type', 3, 'admin', '2025-05-26 15:00:13.048164', NULL, '2025-05-28 14:55:52.300211');
INSERT INTO "public"."gen_table_column" VALUES (179, '16', 'parameter', '质控参数', 'text', 'String', 'parameter', '0', '0', '1', '1', '1', '1', '0', 'EQ', 'select', 'quality_control_param', 4, 'admin', '2025-05-26 15:00:13.048164', NULL, '2025-05-28 14:55:52.300211');
INSERT INTO "public"."gen_table_column" VALUES (180, '16', 'start_time', '开始时间', 'timestamp without time zone', 'Date', 'startTime', '0', '0', '0', '1', '0', '1', '0', 'BETWEEN', NULL, '', 5, 'admin', '2025-05-26 15:00:13.048164', NULL, '2025-05-28 14:55:52.300211');
INSERT INTO "public"."gen_table_column" VALUES (181, '16', 'end_time', '结束时间', 'timestamp without time zone', 'Date', 'endTime', '0', '0', '0', '0', '0', '1', '0', 'BETWEEN', NULL, '', 6, 'admin', '2025-05-26 15:00:13.048164', NULL, '2025-05-28 14:55:52.300211');
INSERT INTO "public"."gen_table_column" VALUES (182, '16', 'standard_value', '标准值', 'numeric', 'Double', 'standardValue', '0', '0', '0', '1', '0', '1', '0', 'EQ', NULL, '', 7, 'admin', '2025-05-26 15:00:13.048164', NULL, '2025-05-28 14:55:52.300211');
INSERT INTO "public"."gen_table_column" VALUES (183, '16', 'monitoring_data', '监测数据', 'numeric', 'Double', 'monitoringData', '0', '0', '0', '1', '0', '1', '0', 'EQ', NULL, '', 8, 'admin', '2025-05-26 15:00:13.048164', NULL, '2025-05-28 14:55:52.300211');
INSERT INTO "public"."gen_table_column" VALUES (184, '16', 'calculated_value', '计算值', 'numeric', 'Double', 'calculatedValue', '0', '0', '0', '1', '0', '1', '0', 'EQ', NULL, '', 9, 'admin', '2025-05-26 15:00:13.048164', NULL, '2025-05-28 14:55:52.300211');
INSERT INTO "public"."gen_table_column" VALUES (185, '16', 'execution_status', '执行状态', 'integer', 'Long', 'executionStatus', '0', '0', '1', '0', '0', '1', '1', 'EQ', 'radio', 'quality_control_execution_status', 10, 'admin', '2025-05-26 15:00:13.048164', NULL, '2025-05-28 14:55:52.300211');
INSERT INTO "public"."gen_table_column" VALUES (186, '16', 'execution_log', '执行日志', 'text', 'String', 'executionLog', '0', '0', '0', '0', '0', '0', '0', 'EQ', 'textarea', '', 11, 'admin', '2025-05-26 15:00:13.048164', NULL, '2025-05-28 14:55:52.300211');
INSERT INTO "public"."gen_table_column" VALUES (187, '16', 'result_evaluation', '结果评价', 'text', 'String', 'resultEvaluation', '0', '0', '0', '0', '1', '1', '0', 'EQ', 'textarea', '', 12, 'admin', '2025-05-26 15:00:13.048164', NULL, '2025-05-28 14:55:52.300211');
INSERT INTO "public"."gen_table_column" VALUES (188, '16', 'quality_control_plan_id', '计划ID', 'integer', 'Long', 'qualityControlPlanId', '0', '0', '0', '0', '0', '0', '0', 'EQ', 'input', '', 13, 'admin', '2025-05-26 15:00:13.048164', NULL, '2025-05-28 14:55:52.300211');
INSERT INTO "public"."gen_table_column" VALUES (189, '16', 'created_by', '创建人', 'character varying', 'String', 'createdBy', '0', '0', '1', '0', '0', '0', '0', 'EQ', NULL, '', 14, 'admin', '2025-05-26 15:00:13.048164', NULL, '2025-05-28 14:55:52.300211');
INSERT INTO "public"."gen_table_column" VALUES (190, '16', 'updated_by', '更新人', 'character varying', 'String', 'updatedBy', '0', '0', '1', '0', '0', '0', '0', 'EQ', NULL, '', 15, 'admin', '2025-05-26 15:00:13.048164', NULL, '2025-05-28 14:55:52.300211');
INSERT INTO "public"."gen_table_column" VALUES (191, '16', 'create_time', '创建时间', 'timestamp without time zone', 'Date', 'createTime', '0', '0', '1', '0', NULL, '0', NULL, 'EQ', NULL, '', 16, 'admin', '2025-05-26 15:00:13.048164', NULL, '2025-05-28 14:55:52.300211');
INSERT INTO "public"."gen_table_column" VALUES (300, '25', 'display', '显示值', 'text', 'String', 'display', '0', '0', '0', '1', '1', '1', '0', 'EQ', 'input', '', 14, 'admin', '2025-06-13 14:14:21.10248', NULL, '2025-06-16 10:04:37.185004');
INSERT INTO "public"."gen_table_column" VALUES (192, '16', 'update_time', '更新时间', 'timestamp without time zone', 'Date', 'updateTime', '0', '0', '1', '0', '0', '0', NULL, 'EQ', NULL, '', 17, 'admin', '2025-05-26 15:00:13.048164', NULL, '2025-05-28 14:55:52.300211');
INSERT INTO "public"."gen_table_column" VALUES (216, '19', 'maintenance_type', '维护类型', 'character varying', 'String', 'maintenanceType', '0', '0', '1', '1', '1', '1', '0', 'EQ', 'select', 'maintenance_type', 3, 'admin', '2025-05-26 18:11:26.072269', NULL, '2025-05-28 16:34:42.364938');
INSERT INTO "public"."gen_table_column" VALUES (217, '19', 'maintenance_time', '维护时间', 'timestamp without time zone', 'Date', 'maintenanceTime', '0', '0', '1', '1', '1', '1', '1', 'BETWEEN', 'datetime', '', 4, 'admin', '2025-05-26 18:11:26.072269', NULL, '2025-05-28 16:34:42.364938');
INSERT INTO "public"."gen_table_column" VALUES (218, '19', 'maintenance_content', '维护内容', 'text', 'String', 'maintenanceContent', '0', '0', '1', '1', '1', '1', '0', 'EQ', 'textarea', '', 5, 'admin', '2025-05-26 18:11:26.072269', NULL, '2025-05-28 16:34:42.364938');
INSERT INTO "public"."gen_table_column" VALUES (219, '19', 'created_by', '创建人', 'character varying', 'String', 'createdBy', '0', '0', '1', '0', '0', '1', '0', 'EQ', NULL, '', 6, 'admin', '2025-05-26 18:11:26.072269', NULL, '2025-05-28 16:34:42.364938');
INSERT INTO "public"."gen_table_column" VALUES (220, '19', 'updated_by', '更新人', 'character varying', 'String', 'updatedBy', '0', '0', '1', '0', '0', '0', '0', 'EQ', NULL, '', 7, 'admin', '2025-05-26 18:11:26.072269', NULL, '2025-05-28 16:34:42.364938');
INSERT INTO "public"."gen_table_column" VALUES (221, '19', 'create_time', '创建时间', 'timestamp without time zone', 'Date', 'createTime', '0', '0', '1', '0', NULL, '0', NULL, 'EQ', NULL, '', 8, 'admin', '2025-05-26 18:11:26.072269', NULL, '2025-05-28 16:34:42.364938');
INSERT INTO "public"."gen_table_column" VALUES (167, '15', 'id', '记录ID', 'integer', 'Long', 'id', '1', '0', '0', '0', '0', '0', NULL, 'EQ', 'input', '', 1, 'admin', '2025-05-26 13:52:37.572308', NULL, '2025-05-28 17:16:25.946068');
INSERT INTO "public"."gen_table_column" VALUES (168, '15', 'device_setting_id', '设置ID', 'integer', 'Long', 'deviceSettingId', '0', '0', '1', '0', '0', '0', '1', 'EQ', 'input', '', 2, 'admin', '2025-05-26 13:52:37.572308', NULL, '2025-05-28 17:16:25.946068');
INSERT INTO "public"."gen_table_column" VALUES (169, '15', 'device_id', '设备ID', 'character varying', 'String', 'deviceId', '0', '0', '1', '0', '0', '1', '1', 'EQ', NULL, '', 3, 'admin', '2025-05-26 13:52:37.572308', NULL, '2025-05-28 17:16:25.946068');
INSERT INTO "public"."gen_table_column" VALUES (170, '15', 'device_setting_time', '设置时间', 'timestamp without time zone', 'Date', 'deviceSettingTime', '0', '0', '1', '0', '0', '1', '1', 'BETWEEN', 'datetime', '', 4, 'admin', '2025-05-26 13:52:37.572308', NULL, '2025-05-28 17:16:25.946068');
INSERT INTO "public"."gen_table_column" VALUES (171, '15', 'device_setting_content', '内容描述', 'text', 'String', 'deviceSettingContent', '0', '0', '0', '1', '1', '1', '1', 'EQ', 'textarea', '', 5, 'admin', '2025-05-26 13:52:37.572308', NULL, '2025-05-28 17:16:25.946068');
INSERT INTO "public"."gen_table_column" VALUES (172, '15', 'created_by', '创建者', 'character varying', 'String', 'createdBy', '0', '0', '0', '0', '0', '1', '1', 'EQ', NULL, '', 6, 'admin', '2025-05-26 13:52:37.572308', NULL, '2025-05-28 17:16:25.946068');
INSERT INTO "public"."gen_table_column" VALUES (173, '15', 'updated_by', '更新者', 'character varying', 'String', 'updatedBy', '0', '0', '0', '0', '0', '1', '1', 'EQ', NULL, '', 7, 'admin', '2025-05-26 13:52:37.572308', NULL, '2025-05-28 17:16:25.946068');
INSERT INTO "public"."gen_table_column" VALUES (174, '15', 'create_time', '创建时间', 'timestamp without time zone', 'Date', 'createTime', '0', '0', '0', '0', NULL, '1', NULL, 'EQ', NULL, '', 8, 'admin', '2025-05-26 13:52:37.572308', NULL, '2025-05-28 17:16:25.946068');
INSERT INTO "public"."gen_table_column" VALUES (175, '15', 'update_time', '更新时间', 'timestamp without time zone', 'Date', 'updateTime', '0', '0', '0', '0', '0', '1', NULL, 'EQ', NULL, '', 9, 'admin', '2025-05-26 13:52:37.572308', NULL, '2025-05-28 17:16:25.946068');
INSERT INTO "public"."gen_table_column" VALUES (250, '22', 'manufacturer', '生产厂家', 'character varying', 'String', 'manufacturer', '0', '0', '0', '1', '1', '1', '0', 'EQ', NULL, '', 6, 'admin', '2025-05-27 17:06:28.966257', NULL, '2025-05-28 13:42:32.027258');
INSERT INTO "public"."gen_table_column" VALUES (251, '22', 'production_date', '生产日期', 'date', 'Date', 'productionDate', '0', '0', '0', '1', '1', '1', '0', 'EQ', 'datetime', '', 7, 'admin', '2025-05-27 17:06:28.966257', NULL, '2025-05-28 13:42:32.027258');
INSERT INTO "public"."gen_table_column" VALUES (252, '22', 'expiry_date', '有效期', 'date', 'Date', 'expiryDate', '0', '0', '0', '1', '1', '1', '0', 'EQ', 'datetime', '', 8, 'admin', '2025-05-27 17:06:28.966257', NULL, '2025-05-28 13:42:32.027258');
INSERT INTO "public"."gen_table_column" VALUES (253, '22', 'warehousing_time', '入库时间', 'date', 'Date', 'warehousingTime', '0', '0', '1', '0', '1', '1', '1', 'BETWEEN', 'datetime', '', 9, 'admin', '2025-05-27 17:06:28.966257', NULL, '2025-05-28 13:42:32.027258');
INSERT INTO "public"."gen_table_column" VALUES (254, '22', 'material_capacity', '物资容量', 'numeric', 'Double', 'materialCapacity', '0', '0', '0', '1', '1', '1', '0', 'EQ', NULL, '', 10, 'admin', '2025-05-27 17:06:28.966257', NULL, '2025-05-28 13:42:32.027258');
INSERT INTO "public"."gen_table_column" VALUES (255, '22', 'material_capacity_unit', '物资容量单位', 'character varying', 'String', 'materialCapacityUnit', '0', '0', '0', '1', '1', '1', '0', 'EQ', NULL, '', 11, 'admin', '2025-05-27 17:06:28.966257', NULL, '2025-05-28 13:42:32.027258');
INSERT INTO "public"."gen_table_column" VALUES (256, '22', 'material_remain_capacity', '剩余物资容量', 'numeric', 'Double', 'materialRemainCapacity', '0', '0', '0', '1', '1', '1', '0', 'EQ', NULL, '', 12, 'admin', '2025-05-27 17:06:28.966257', NULL, '2025-05-28 13:42:32.027258');
INSERT INTO "public"."gen_table_column" VALUES (257, '22', 'material_status', '物资状态', 'integer', 'Long', 'materialStatus', '0', '0', '0', '0', '1', '1', '1', 'EQ', 'radio', '', 13, 'admin', '2025-05-27 17:06:28.966257', NULL, '2025-05-28 13:42:32.027258');
INSERT INTO "public"."gen_table_column" VALUES (258, '22', 'storage_location', '存放位置', 'character varying', 'String', 'storageLocation', '0', '0', '0', '1', '1', '1', '0', 'EQ', NULL, '', 14, 'admin', '2025-05-27 17:06:28.966257', NULL, '2025-05-28 13:42:32.027258');
INSERT INTO "public"."gen_table_column" VALUES (259, '22', 'remarks', '备注', 'text', 'String', 'remarks', '0', '0', '0', '1', '1', '1', '0', 'EQ', 'textarea', '', 15, 'admin', '2025-05-27 17:06:28.966257', NULL, '2025-05-28 13:42:32.027258');
INSERT INTO "public"."gen_table_column" VALUES (260, '22', 'created_by', '创建人', 'character varying', 'String', 'createdBy', '0', '0', '1', '0', '0', '0', '0', 'EQ', NULL, '', 16, 'admin', '2025-05-27 17:06:28.966257', NULL, '2025-05-28 13:42:32.027258');
INSERT INTO "public"."gen_table_column" VALUES (261, '22', 'updated_by', '更新人', 'character varying', 'String', 'updatedBy', '0', '0', '1', '0', '0', '0', '0', 'EQ', NULL, '', 17, 'admin', '2025-05-27 17:06:28.966257', NULL, '2025-05-28 13:42:32.027258');
INSERT INTO "public"."gen_table_column" VALUES (273, '24', 'id', '记录ID', 'integer', 'Long', 'id', '1', '0', '0', '0', NULL, NULL, NULL, 'EQ', 'input', '', 1, 'admin', '2025-05-28 23:32:21.524423', NULL, '2025-05-29 08:30:18.820887');
INSERT INTO "public"."gen_table_column" VALUES (207, '18', 'sort', '排序', 'integer', 'Long', 'sort', '0', '0', '0', '1', '1', '1', '0', 'EQ', 'input', '', 4, 'admin', '2025-05-26 17:44:06.741238', NULL, '2025-05-27 08:49:24.000301');
INSERT INTO "public"."gen_table_column" VALUES (208, '18', 'setting_content', '设置内容', 'text', 'String', 'settingContent', '0', '0', '0', '1', '1', '1', '0', 'EQ', 'textarea', '', 5, 'admin', '2025-05-26 17:44:06.741238', NULL, '2025-05-27 08:49:24.000301');
INSERT INTO "public"."gen_table_column" VALUES (209, '18', 'device_id', '设备编码', 'character varying', 'String', 'deviceId', '1', '0', '0', '1', '1', '1', '1', 'EQ', 'input', '', 6, 'admin', '2025-05-26 17:44:06.741238', NULL, '2025-05-27 08:49:24.000301');
INSERT INTO "public"."gen_table_column" VALUES (210, '18', 'created_by', '创建人', 'character varying', 'String', 'createdBy', '0', '0', '0', '0', '0', '1', '0', 'EQ', NULL, '', 7, 'admin', '2025-05-26 17:44:06.741238', NULL, '2025-05-27 08:49:24.000301');
INSERT INTO "public"."gen_table_column" VALUES (211, '18', 'updated_by', '更新人', 'character varying', 'String', 'updatedBy', '0', '0', '0', '0', '0', '1', '0', 'EQ', NULL, '', 8, 'admin', '2025-05-26 17:44:06.741238', NULL, '2025-05-27 08:49:24.000301');
INSERT INTO "public"."gen_table_column" VALUES (212, '18', 'create_time', '创建时间', 'timestamp without time zone', 'Date', 'createTime', '0', '0', '0', '0', NULL, '1', NULL, 'EQ', NULL, '', 9, 'admin', '2025-05-26 17:44:06.741238', NULL, '2025-05-27 08:49:24.000301');
INSERT INTO "public"."gen_table_column" VALUES (213, '18', 'update_time', '更新时间', 'timestamp without time zone', 'Date', 'updateTime', '0', '0', '0', '0', '0', '1', NULL, 'EQ', NULL, '', 10, 'admin', '2025-05-26 17:44:06.741238', NULL, '2025-05-27 08:49:24.000301');
INSERT INTO "public"."gen_table_column" VALUES (274, '24', 'device_name', '设备名称', 'character varying', 'String', 'deviceName', '0', '0', '0', '1', '1', '1', '1', 'LIKE', 'input', '', 2, 'admin', '2025-05-28 23:32:21.524423', NULL, '2025-05-29 08:30:18.820887');
INSERT INTO "public"."gen_table_column" VALUES (275, '24', 'device_ip', '设备IP地址', 'character varying', 'String', 'deviceIp', '0', '0', '0', '1', '1', '1', '0', 'EQ', 'input', '', 3, 'admin', '2025-05-28 23:32:21.524423', NULL, '2025-05-29 08:30:18.820887');
INSERT INTO "public"."gen_table_column" VALUES (276, '24', 'device_mac', '设备mac地址', 'character varying', 'String', 'deviceMac', '0', '0', '0', '1', '1', '1', '0', 'EQ', 'input', '', 4, 'admin', '2025-05-28 23:32:21.524423', NULL, '2025-05-29 08:30:18.820887');
INSERT INTO "public"."gen_table_column" VALUES (245, '22', 'id', '记录ID', 'integer', 'Long', 'id', '1', '0', '0', '0', NULL, NULL, NULL, 'EQ', 'input', '', 1, 'admin', '2025-05-27 17:06:28.966257', NULL, '2025-05-28 13:42:32.027258');
INSERT INTO "public"."gen_table_column" VALUES (246, '22', 'material_code', '物资编号', 'character varying', 'String', 'materialCode', '1', '0', '0', '1', '1', '1', '1', 'LIKE', 'input', '', 2, 'admin', '2025-05-27 17:06:28.966257', NULL, '2025-05-28 13:42:32.027258');
INSERT INTO "public"."gen_table_column" VALUES (247, '22', 'material_name', '物资名称', 'character varying', 'String', 'materialName', '0', '0', '1', '1', '1', '1', '1', 'LIKE', 'input', '', 3, 'admin', '2025-05-27 17:06:28.966257', NULL, '2025-05-28 13:42:32.027258');
INSERT INTO "public"."gen_table_column" VALUES (248, '22', 'material_type', '物资类型', 'character varying', 'String', 'materialType', '0', '0', '1', '1', '1', '1', '1', 'EQ', 'select', 'material_type', 4, 'admin', '2025-05-27 17:06:28.966257', NULL, '2025-05-28 13:42:32.027258');
INSERT INTO "public"."gen_table_column" VALUES (249, '22', 'specification', '规格型号', 'character varying', 'String', 'specification', '0', '0', '0', '1', '1', '1', '0', 'EQ', NULL, '', 5, 'admin', '2025-05-27 17:06:28.966257', NULL, '2025-05-28 13:42:32.027258');
INSERT INTO "public"."gen_table_column" VALUES (277, '24', 'employee_id', '工号', 'character varying', 'String', 'employeeId', '0', '0', '0', '0', '1', '1', '0', 'EQ', NULL, '', 5, 'admin', '2025-05-28 23:32:21.524423', NULL, '2025-05-29 08:30:18.820887');
INSERT INTO "public"."gen_table_column" VALUES (278, '24', 'employee_name', '名称', 'character varying', 'String', 'employeeName', '0', '0', '0', '1', '1', '1', '1', 'LIKE', 'input', '', 6, 'admin', '2025-05-28 23:32:21.524423', NULL, '2025-05-29 08:30:18.820887');
INSERT INTO "public"."gen_table_column" VALUES (279, '24', 'access_method', '打卡方式', 'character varying', 'String', 'accessMethod', '0', '0', '0', '1', '1', '1', '1', 'EQ', 'select', 'access_method', 7, 'admin', '2025-05-28 23:32:21.524423', NULL, '2025-05-29 08:30:18.820887');
INSERT INTO "public"."gen_table_column" VALUES (280, '24', 'setting_content', '门禁详情', 'text', 'String', 'settingContent', '0', '0', '0', '1', '1', '1', '0', 'EQ', 'textarea', '', 8, 'admin', '2025-05-28 23:32:21.524423', NULL, '2025-05-29 08:30:18.820887');
INSERT INTO "public"."gen_table_column" VALUES (281, '24', 'result_json', '门禁结果', 'text', 'String', 'resultJson', '0', '0', '0', '0', '0', '1', '1', 'EQ', 'textarea', '', 9, 'admin', '2025-05-28 23:32:21.524423', NULL, '2025-05-29 08:30:18.820887');
INSERT INTO "public"."gen_table_column" VALUES (282, '24', 'file_json', '文件内容', 'text', 'String', 'fileJson', '0', '0', '0', '0', '0', '1', '0', 'EQ', 'textarea', '', 10, 'admin', '2025-05-28 23:32:21.524423', NULL, '2025-05-29 08:30:18.820887');

CREATE TABLE "public"."qrtz_blob_triggers" (
  "sched_name" varchar(120) COLLATE "pg_catalog"."default" NOT NULL,
  "trigger_name" varchar(200) COLLATE "pg_catalog"."default" NOT NULL,
  "trigger_group" varchar(200) COLLATE "pg_catalog"."default" NOT NULL,
  "blob_data" bytea
)
;

CREATE TABLE "public"."qrtz_calendars" (
  "sched_name" varchar(120) COLLATE "pg_catalog"."default" NOT NULL,
  "calendar_name" varchar(200) COLLATE "pg_catalog"."default" NOT NULL,
  "calendar" bytea NOT NULL
)
;

CREATE TABLE "public"."qrtz_cron_triggers" (
  "sched_name" varchar(120) COLLATE "pg_catalog"."default" NOT NULL,
  "trigger_name" varchar(200) COLLATE "pg_catalog"."default" NOT NULL,
  "trigger_group" varchar(200) COLLATE "pg_catalog"."default" NOT NULL,
  "cron_expression" varchar(200) COLLATE "pg_catalog"."default" NOT NULL,
  "time_zone_id" varchar(80) COLLATE "pg_catalog"."default"
)
;

CREATE TABLE "public"."qrtz_fired_triggers" (
  "sched_name" varchar(120) COLLATE "pg_catalog"."default" NOT NULL,
  "entry_id" varchar(95) COLLATE "pg_catalog"."default" NOT NULL,
  "trigger_name" varchar(200) COLLATE "pg_catalog"."default" NOT NULL,
  "trigger_group" varchar(200) COLLATE "pg_catalog"."default" NOT NULL,
  "instance_name" varchar(200) COLLATE "pg_catalog"."default" NOT NULL,
  "fired_time" int8 NOT NULL,
  "sched_time" int8 NOT NULL,
  "priority" int4 NOT NULL,
  "state" varchar(16) COLLATE "pg_catalog"."default" NOT NULL,
  "job_name" varchar(200) COLLATE "pg_catalog"."default",
  "job_group" varchar(200) COLLATE "pg_catalog"."default",
  "is_nonconcurrent" varchar(20) COLLATE "pg_catalog"."default",
  "requests_recovery" varchar(20) COLLATE "pg_catalog"."default"
)
;

CREATE TABLE "public"."qrtz_job_details" (
  "sched_name" varchar(120) COLLATE "pg_catalog"."default" NOT NULL,
  "job_name" varchar(200) COLLATE "pg_catalog"."default" NOT NULL,
  "job_group" varchar(200) COLLATE "pg_catalog"."default" NOT NULL,
  "description" varchar(250) COLLATE "pg_catalog"."default",
  "job_class_name" varchar(250) COLLATE "pg_catalog"."default" NOT NULL,
  "is_durable" varchar(50) COLLATE "pg_catalog"."default" NOT NULL,
  "is_nonconcurrent" varchar(50) COLLATE "pg_catalog"."default" NOT NULL,
  "is_update_data" varchar(50) COLLATE "pg_catalog"."default" NOT NULL,
  "requests_recovery" varchar(50) COLLATE "pg_catalog"."default" NOT NULL,
  "job_data" bytea
)
;

CREATE TABLE "public"."qrtz_locks" (
  "sched_name" varchar(120) COLLATE "pg_catalog"."default" NOT NULL,
  "lock_name" varchar(40) COLLATE "pg_catalog"."default" NOT NULL
)
;

CREATE TABLE "public"."qrtz_paused_trigger_grps" (
  "sched_name" varchar(120) COLLATE "pg_catalog"."default" NOT NULL,
  "trigger_group" varchar(200) COLLATE "pg_catalog"."default" NOT NULL
)
;

CREATE TABLE "public"."qrtz_scheduler_state" (
  "sched_name" varchar(120) COLLATE "pg_catalog"."default" NOT NULL,
  "instance_name" varchar(200) COLLATE "pg_catalog"."default" NOT NULL,
  "last_checkin_time" int8 NOT NULL,
  "checkin_interval" int8 NOT NULL
)
;

CREATE TABLE "public"."qrtz_simple_triggers" (
  "sched_name" varchar(120) COLLATE "pg_catalog"."default" NOT NULL,
  "trigger_name" varchar(200) COLLATE "pg_catalog"."default" NOT NULL,
  "trigger_group" varchar(200) COLLATE "pg_catalog"."default" NOT NULL,
  "repeat_count" int8 NOT NULL,
  "repeat_interval" int8 NOT NULL,
  "times_triggered" int8 NOT NULL
)
;

CREATE TABLE "public"."qrtz_simprop_triggers" (
  "sched_name" varchar(120) COLLATE "pg_catalog"."default" NOT NULL,
  "trigger_name" varchar(200) COLLATE "pg_catalog"."default" NOT NULL,
  "trigger_group" varchar(200) COLLATE "pg_catalog"."default" NOT NULL,
  "str_prop_1" varchar(512) COLLATE "pg_catalog"."default",
  "str_prop_2" varchar(512) COLLATE "pg_catalog"."default",
  "str_prop_3" varchar(512) COLLATE "pg_catalog"."default",
  "int_prop_1" int4,
  "int_prop_2" int4,
  "long_prop_1" int8,
  "long_prop_2" int8,
  "dec_prop_1" numeric(13,4),
  "dec_prop_2" numeric(13,4),
  "bool_prop_1" varchar(2) COLLATE "pg_catalog"."default",
  "bool_prop_2" varchar(2) COLLATE "pg_catalog"."default"
)
;

CREATE TABLE "public"."qrtz_triggers" (
  "sched_name" varchar(120) COLLATE "pg_catalog"."default" NOT NULL,
  "trigger_name" varchar(200) COLLATE "pg_catalog"."default" NOT NULL,
  "trigger_group" varchar(200) COLLATE "pg_catalog"."default" NOT NULL,
  "job_name" varchar(200) COLLATE "pg_catalog"."default" NOT NULL,
  "job_group" varchar(200) COLLATE "pg_catalog"."default" NOT NULL,
  "description" varchar(250) COLLATE "pg_catalog"."default",
  "next_fire_time" int8,
  "prev_fire_time" int8,
  "priority" int4,
  "trigger_state" varchar(16) COLLATE "pg_catalog"."default" NOT NULL,
  "trigger_type" varchar(8) COLLATE "pg_catalog"."default" NOT NULL,
  "start_time" int8 NOT NULL,
  "end_time" int8,
  "calendar_name" varchar(200) COLLATE "pg_catalog"."default",
  "misfire_instr" int2,
  "job_data" bytea
)
;

CREATE TABLE "public"."sys_config" (
  "config_id" int8 NOT NULL DEFAULT nextval('sys_config_config_id_seq'::regclass),
  "config_name" varchar(100) COLLATE "pg_catalog"."default",
  "config_key" varchar(100) COLLATE "pg_catalog"."default",
  "config_value" varchar(500) COLLATE "pg_catalog"."default",
  "config_type" char(1) COLLATE "pg_catalog"."default",
  "create_by" varchar(64) COLLATE "pg_catalog"."default",
  "create_time" timestamp(6),
  "update_by" varchar(64) COLLATE "pg_catalog"."default",
  "update_time" timestamp(6),
  "remark" varchar(500) COLLATE "pg_catalog"."default"
)
;
COMMENT ON COLUMN "public"."sys_config"."config_id" IS '参数主键';
COMMENT ON COLUMN "public"."sys_config"."config_name" IS '参数名称';
COMMENT ON COLUMN "public"."sys_config"."config_key" IS '参数键名';
COMMENT ON COLUMN "public"."sys_config"."config_value" IS '参数键值';
COMMENT ON COLUMN "public"."sys_config"."config_type" IS '系统内置（Y是 N否）';
COMMENT ON COLUMN "public"."sys_config"."create_by" IS '创建者';
COMMENT ON COLUMN "public"."sys_config"."create_time" IS '创建时间';
COMMENT ON COLUMN "public"."sys_config"."update_by" IS '更新者';
COMMENT ON COLUMN "public"."sys_config"."update_time" IS '更新时间';
COMMENT ON COLUMN "public"."sys_config"."remark" IS '备注';
COMMENT ON TABLE "public"."sys_config" IS '参数配置表';

INSERT INTO "public"."sys_config" VALUES (1, '主框架页-默认皮肤样式名称', 'sys.index.skinName', 'skin-blue', 'Y', 'admin', '2021-05-26 18:56:31', 'admin', '2021-05-27 09:07:43.532263', '蓝色 skin-blue、绿色 skin-green、紫色 skin-purple、红色 skin-red、黄色 skin-yellow');
INSERT INTO "public"."sys_config" VALUES (2, '用户管理-账号初始密码', 'sys.user.initPassword', '123456', 'Y', 'admin', '2021-05-26 18:56:31', 'admin', '2021-05-27 10:15:52.394492', '初始化密码 123456');
INSERT INTO "public"."sys_config" VALUES (3, '主框架页-侧边栏主题', 'sys.index.sideTheme', 'theme-dark', 'Y', 'admin', '2021-05-26 18:56:31', 'admin', NULL, '深色主题theme-dark，浅色主题theme-light');
INSERT INTO "public"."sys_config" VALUES (4, '账号自助-验证码开关', 'sys.account.captchaEnabled', 'true', 'Y', 'admin', '2025-02-14 02:51:47.23521', 'admin', NULL, '是否开启验证码功能（true开启，false关闭）');
INSERT INTO "public"."sys_config" VALUES (5, '账号自助-是否开启用户注册功能', 'sys.account.registerUser', 'false', 'Y', 'admin', '2025-02-14 02:51:47.274963', 'admin', NULL, '是否开启注册用户功能（true开启，false关闭）');
INSERT INTO "public"."sys_config" VALUES (6, 'Web端-默认首页路由', 'ecat.web.home', '', 'N', 'admin', current_timestamp, 'admin', NULL, '登录后默认打开的页面路由；留空回退内置首页 /index。如 /ecat-integrations/integration-env-air-device-manager/air-device-manager/index/monitor_home');

CREATE TABLE "public"."sys_dept" (
  "dept_id" int8 NOT NULL DEFAULT nextval('sys_dept_dept_id_seq'::regclass),
  "parent_id" int8 DEFAULT 0,
  "ancestors" varchar(50) COLLATE "pg_catalog"."default",
  "dept_name" varchar(30) COLLATE "pg_catalog"."default",
  "order_num" int4,
  "leader" varchar(20) COLLATE "pg_catalog"."default",
  "phone" varchar(11) COLLATE "pg_catalog"."default",
  "email" varchar(50) COLLATE "pg_catalog"."default",
  "status" char(1) COLLATE "pg_catalog"."default",
  "del_flag" char(1) COLLATE "pg_catalog"."default" DEFAULT 0,
  "create_by" varchar(64) COLLATE "pg_catalog"."default",
  "create_time" timestamp(6),
  "update_by" varchar(64) COLLATE "pg_catalog"."default",
  "update_time" timestamp(6)
)
;
COMMENT ON COLUMN "public"."sys_dept"."dept_id" IS '部门id';
COMMENT ON COLUMN "public"."sys_dept"."parent_id" IS '父部门id';
COMMENT ON COLUMN "public"."sys_dept"."ancestors" IS '祖级列表';
COMMENT ON COLUMN "public"."sys_dept"."dept_name" IS '部门名称';
COMMENT ON COLUMN "public"."sys_dept"."order_num" IS '显示顺序';
COMMENT ON COLUMN "public"."sys_dept"."leader" IS '负责人';
COMMENT ON COLUMN "public"."sys_dept"."phone" IS '联系电话';
COMMENT ON COLUMN "public"."sys_dept"."email" IS '邮箱';
COMMENT ON COLUMN "public"."sys_dept"."status" IS '部门状态（0正常 1停用）';
COMMENT ON COLUMN "public"."sys_dept"."del_flag" IS '删除标志（0代表存在 2代表删除）';
COMMENT ON COLUMN "public"."sys_dept"."create_by" IS '创建者';
COMMENT ON COLUMN "public"."sys_dept"."create_time" IS '创建时间';
COMMENT ON COLUMN "public"."sys_dept"."update_by" IS '更新者';
COMMENT ON COLUMN "public"."sys_dept"."update_time" IS '更新时间';
COMMENT ON TABLE "public"."sys_dept" IS '部门表';

INSERT INTO "public"."sys_dept" VALUES (102, 100, '0,100', '石家庄分公司', 2, '猫头鹰', '15888888888', 'ry@qq.com', '0', '0', 'admin', '2021-05-26 18:56:27', '', NULL);
INSERT INTO "public"."sys_dept" VALUES (104, 101, '0,100,101', '市场部门', 2, '猫头鹰', '15888888888', 'ry@qq.com', '0', '0', 'admin', '2021-05-26 18:56:27', '', NULL);
INSERT INTO "public"."sys_dept" VALUES (105, 101, '0,100,101', '测试部门', 3, '猫头鹰', '15888888888', 'ry@qq.com', '0', '0', 'admin', '2021-05-26 18:56:27', '', NULL);
INSERT INTO "public"."sys_dept" VALUES (106, 101, '0,100,101', '财务部门', 4, '猫头鹰', '15888888888', 'ry@qq.com', '0', '0', 'admin', '2021-05-26 18:56:28', '', NULL);
INSERT INTO "public"."sys_dept" VALUES (107, 101, '0,100,101', '运维部门', 5, '猫头鹰', '15888888888', 'ry@qq.com', '0', '0', 'admin', '2021-05-26 18:56:28', '', NULL);
INSERT INTO "public"."sys_dept" VALUES (108, 102, '0,100,102', '市场部门', 1, '猫头鹰', '15888888888', 'ry@qq.com', '0', '0', 'admin', '2021-05-26 18:56:28', '', NULL);
INSERT INTO "public"."sys_dept" VALUES (109, 102, '0,100,102', '财务部门', 2, '猫头鹰', '15888888888', 'ry@qq.com', '0', '0', 'admin', '2021-05-26 18:56:28', '', NULL);
INSERT INTO "public"."sys_dept" VALUES (103, 101, '0,100,101', '研发部门', 1, '猫头鹰', '15888888888', 'ry@qq.com', '0', '0', 'admin', '2021-05-26 18:56:27', 'admin', '2021-05-27 09:05:25.083296');
INSERT INTO "public"."sys_dept" VALUES (101, 100, '0,100', '河北总公司', 1, '猫头鹰', '15888888888', 'ry@qq.com', '0', '0', 'admin', '2021-05-26 18:56:27', 'admin', '2021-05-27 09:05:25.091901');
INSERT INTO "public"."sys_dept" VALUES (100, 0, '0', '赛默森科技', 0, '赛默森', '15888888888', 'sms@qq.com', '0', '0', 'admin', '2021-05-26 18:56:27', 'admin', '2025-03-07 14:33:25.539159');

CREATE TABLE "public"."sys_dict_data" (
  "dict_code" int8 NOT NULL DEFAULT nextval('sys_dict_data_dict_code_seq'::regclass),
  "dict_sort" int4,
  "dict_label" varchar(100) COLLATE "pg_catalog"."default",
  "dict_value" varchar(100) COLLATE "pg_catalog"."default",
  "dict_type" varchar(100) COLLATE "pg_catalog"."default",
  "css_class" varchar(100) COLLATE "pg_catalog"."default",
  "list_class" varchar(100) COLLATE "pg_catalog"."default",
  "is_default" char(1) COLLATE "pg_catalog"."default",
  "status" char(1) COLLATE "pg_catalog"."default",
  "create_by" varchar(64) COLLATE "pg_catalog"."default",
  "create_time" timestamp(6),
  "update_by" varchar(64) COLLATE "pg_catalog"."default",
  "update_time" timestamp(6),
  "remark" varchar(500) COLLATE "pg_catalog"."default"
)
;
COMMENT ON COLUMN "public"."sys_dict_data"."dict_code" IS '字典编码';
COMMENT ON COLUMN "public"."sys_dict_data"."dict_sort" IS '字典排序';
COMMENT ON COLUMN "public"."sys_dict_data"."dict_label" IS '字典标签';
COMMENT ON COLUMN "public"."sys_dict_data"."dict_value" IS '字典键值';
COMMENT ON COLUMN "public"."sys_dict_data"."dict_type" IS '字典类型';
COMMENT ON COLUMN "public"."sys_dict_data"."css_class" IS '样式属性（其他样式扩展）';
COMMENT ON COLUMN "public"."sys_dict_data"."list_class" IS '表格回显样式';
COMMENT ON COLUMN "public"."sys_dict_data"."is_default" IS '是否默认（Y是 N否）';
COMMENT ON COLUMN "public"."sys_dict_data"."status" IS '状态（0正常 1停用）';
COMMENT ON COLUMN "public"."sys_dict_data"."create_by" IS '创建者';
COMMENT ON COLUMN "public"."sys_dict_data"."create_time" IS '创建时间';
COMMENT ON COLUMN "public"."sys_dict_data"."update_by" IS '更新者';
COMMENT ON COLUMN "public"."sys_dict_data"."update_time" IS '更新时间';
COMMENT ON COLUMN "public"."sys_dict_data"."remark" IS '备注';
COMMENT ON TABLE "public"."sys_dict_data" IS '字典数据表';

INSERT INTO "public"."sys_dict_data" VALUES (1, 1, '男', '0', 'sys_user_sex', '', '', 'Y', '0', 'admin', '2025-02-14 02:51:49.035039', '', NULL, '性别男');
INSERT INTO "public"."sys_dict_data" VALUES (2, 2, '女', '1', 'sys_user_sex', '', '', 'N', '0', 'admin', '2025-02-14 02:51:49.074975', '', NULL, '性别女');
INSERT INTO "public"."sys_dict_data" VALUES (3, 3, '未知', '2', 'sys_user_sex', '', '', 'N', '0', 'admin', '2025-02-14 02:51:49.115008', '', NULL, '性别未知');
INSERT INTO "public"."sys_dict_data" VALUES (4, 1, '显示', '0', 'sys_show_hide', '', 'primary', 'Y', '0', 'admin', '2025-02-14 02:51:49.154987', '', NULL, '显示菜单');
INSERT INTO "public"."sys_dict_data" VALUES (5, 2, '隐藏', '1', 'sys_show_hide', '', 'danger', 'N', '0', 'admin', '2025-02-14 02:51:49.195106', '', NULL, '隐藏菜单');
INSERT INTO "public"."sys_dict_data" VALUES (6, 1, '正常', '0', 'sys_normal_disable', '', 'primary', 'Y', '0', 'admin', '2025-02-14 02:51:49.235052', '', NULL, '正常状态');
INSERT INTO "public"."sys_dict_data" VALUES (7, 2, '停用', '1', 'sys_normal_disable', '', 'danger', 'N', '0', 'admin', '2025-02-14 02:51:49.275068', '', NULL, '停用状态');
INSERT INTO "public"."sys_dict_data" VALUES (8, 1, '正常', '0', 'sys_job_status', '', 'primary', 'Y', '0', 'admin', '2025-02-14 02:51:49.295032', '', NULL, '正常状态');
INSERT INTO "public"."sys_dict_data" VALUES (9, 2, '暂停', '1', 'sys_job_status', '', 'danger', 'N', '0', 'admin', '2025-02-14 02:51:49.335383', '', NULL, '停用状态');
INSERT INTO "public"."sys_dict_data" VALUES (12, 1, '是', 'Y', 'sys_yes_no', '', 'primary', 'Y', '0', 'admin', '2025-02-14 02:51:49.455638', '', NULL, '系统默认是');
INSERT INTO "public"."sys_dict_data" VALUES (13, 2, '否', 'N', 'sys_yes_no', '', 'danger', 'N', '0', 'admin', '2025-02-14 02:51:49.495057', '', NULL, '系统默认否');
INSERT INTO "public"."sys_dict_data" VALUES (14, 1, '通知', '1', 'sys_notice_type', '', 'warning', 'Y', '0', 'admin', '2025-02-14 02:51:49.53504', '', NULL, '通知');
INSERT INTO "public"."sys_dict_data" VALUES (15, 2, '公告', '2', 'sys_notice_type', '', 'success', 'N', '0', 'admin', '2025-02-14 02:51:49.575082', '', NULL, '公告');
INSERT INTO "public"."sys_dict_data" VALUES (16, 1, '正常', '0', 'sys_notice_status', '', 'primary', 'Y', '0', 'admin', '2025-02-14 02:51:49.614936', '', NULL, '正常状态');
INSERT INTO "public"."sys_dict_data" VALUES (17, 2, '关闭', '1', 'sys_notice_status', '', 'danger', 'N', '0', 'admin', '2025-02-14 02:51:49.654977', '', NULL, '关闭状态');
INSERT INTO "public"."sys_dict_data" VALUES (18, 1, '新增', '1', 'sys_oper_type', '', 'info', 'N', '0', 'admin', '2025-02-14 02:51:49.695066', '', NULL, '新增操作');
INSERT INTO "public"."sys_dict_data" VALUES (19, 2, '修改', '2', 'sys_oper_type', '', 'info', 'N', '0', 'admin', '2025-02-14 02:51:49.735099', '', NULL, '修改操作');
INSERT INTO "public"."sys_dict_data" VALUES (20, 3, '删除', '3', 'sys_oper_type', '', 'danger', 'N', '0', 'admin', '2025-02-14 02:51:49.775112', '', NULL, '删除操作');
INSERT INTO "public"."sys_dict_data" VALUES (21, 4, '授权', '4', 'sys_oper_type', '', 'primary', 'N', '0', 'admin', '2025-02-14 02:51:49.814982', '', NULL, '授权操作');
INSERT INTO "public"."sys_dict_data" VALUES (22, 5, '导出', '5', 'sys_oper_type', '', 'warning', 'N', '0', 'admin', '2025-02-14 02:51:49.854954', '', NULL, '导出操作');
INSERT INTO "public"."sys_dict_data" VALUES (23, 6, '导入', '6', 'sys_oper_type', '', 'warning', 'N', '0', 'admin', '2025-02-14 02:51:49.894998', '', NULL, '导入操作');
INSERT INTO "public"."sys_dict_data" VALUES (24, 7, '强退', '7', 'sys_oper_type', '', 'danger', 'N', '0', 'admin', '2025-02-14 02:51:49.934925', '', NULL, '强退操作');
INSERT INTO "public"."sys_dict_data" VALUES (25, 8, '生成代码', '8', 'sys_oper_type', '', 'warning', 'N', '0', 'admin', '2025-02-14 02:51:49.97508', '', NULL, '生成操作');
INSERT INTO "public"."sys_dict_data" VALUES (26, 9, '清空数据', '9', 'sys_oper_type', '', 'danger', 'N', '0', 'admin', '2025-02-14 02:51:50.014975', '', NULL, '清空操作');
INSERT INTO "public"."sys_dict_data" VALUES (27, 1, '成功', '0', 'sys_common_status', '', 'primary', 'N', '0', 'admin', '2025-02-14 02:51:50.055038', '', NULL, '正常状态');
INSERT INTO "public"."sys_dict_data" VALUES (28, 2, '失败', '1', 'sys_common_status', '', 'danger', 'N', '0', 'admin', '2025-02-14 02:51:50.094784', '', NULL, '停用状态');
INSERT INTO "public"."sys_dict_data" VALUES (29, 0, '智慧数采#1', 'IntelligentDataCollection', 'sys_tid', NULL, 'default', NULL, '0', 'admin', '2025-02-14 11:28:33.096474', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (31, 0, '浮点数', 'float', 'sys_data_type', NULL, 'default', NULL, '0', 'admin', '2025-02-14 11:30:53.384984', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (32, 1, '字符串', 'string', 'sys_data_type', NULL, 'default', NULL, '0', 'admin', '2025-02-14 11:31:04.853931', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (30, 0, '智慧数采#1', '智慧数采#1', 'sys_tid_name', NULL, 'default', NULL, '0', 'admin', '2025-02-14 11:29:41.192463', 'admin', '2025-02-14 11:31:23.900957', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (33, 0, 'COM1', 'COM1', 'sys_device_com', NULL, 'default', NULL, '0', 'admin', '2025-02-14 13:31:00.559976', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (34, 1, 'COM2', 'COM2', 'sys_device_com', NULL, 'default', NULL, '0', 'admin', '2025-02-14 13:31:06.704006', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (35, 3, 'COM3', 'COM3', 'sys_device_com', NULL, 'default', NULL, '0', 'admin', '2025-02-14 13:31:15.189404', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (36, 4, 'COM4', 'COM4', 'sys_device_com', NULL, 'default', NULL, '0', 'admin', '2025-02-14 13:31:21.653649', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (37, 5, 'COM5', 'COM5', 'sys_device_com', NULL, 'default', NULL, '0', 'admin', '2025-02-14 13:31:27.798961', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (38, 6, 'COM6', 'COM6', 'sys_device_com', NULL, 'default', NULL, '0', 'admin', '2025-02-14 13:31:39.060904', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (39, 7, 'COM7', 'COM7', 'sys_device_com', NULL, 'default', NULL, '0', 'admin', '2025-02-14 13:31:45.82049', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (40, 8, 'COM8', 'COM8', 'sys_device_com', NULL, 'default', NULL, '0', 'admin', '2025-02-14 13:31:58.722149', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (41, 9, 'COM9', 'COM9', 'sys_device_com', NULL, 'default', NULL, '0', 'admin', '2025-02-14 13:32:05.071043', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (42, 10, 'COM10', 'COM10', 'sys_device_com', NULL, 'default', NULL, '0', 'admin', '2025-02-14 13:32:12.546154', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (43, 0, 'MOUBUS', 'MOUBUS', 'sys_device_pro', NULL, 'default', NULL, '0', 'admin', '2025-02-14 13:35:59.051577', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (44, 1, 'MOUBUS-TCP', 'MODBUSTCP', 'sys_device_pro', NULL, 'default', NULL, '0', 'admin', '2025-02-14 13:36:15.742045', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (45, 2, 'CLINK', 'CLINK', 'sys_device_pro', NULL, 'default', NULL, '0', 'admin', '2025-02-14 13:36:21.681483', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (46, 0, '先河', 'xianhe', 'sys_device_type', NULL, 'default', NULL, '0', 'admin', '2025-02-14 13:39:13.507121', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (47, 1, '热电', 'redian', 'sys_device_type', NULL, 'default', NULL, '0', 'admin', '2025-02-14 13:39:21.289707', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (53, 0, '智能采集    ', 'IntelligentDataCollection ', 'thing_type', NULL, 'default', NULL, '0', 'admin', '2025-02-18 11:41:11.555552', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (59, 0, '导出', '1', 'task_type', NULL, 'default', NULL, '0', 'admin', '2025-02-24 13:53:00.336544', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (60, 1, '导入', '2', 'task_type', NULL, 'default', NULL, '0', 'admin', '2025-02-24 13:54:10.499903', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (61, 0, '等待', 'pending', 'task_status', NULL, 'default', NULL, '0', 'admin', '2025-02-24 14:20:36.145797', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (63, 2, '成功', 'completed', 'task_status', NULL, 'default', NULL, '0', 'admin', '2025-02-24 14:25:22.565434', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (62, 1, '进行中', 'processing', 'task_status', NULL, 'default', NULL, '0', 'admin', '2025-02-24 14:23:39.974646', 'admin', '2025-03-04 11:11:51.826286', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (57, 1, '数据有效', '1', 'data_sign', NULL, 'default', NULL, '0', 'admin', '2025-02-18 13:48:37.695332', 'admin', '2025-06-25 15:26:56.821661', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (48, 0, '进行中', '0', 'event_status', NULL, 'default', NULL, '0', 'admin', '2025-02-18 10:38:59.882603', 'admin', '2025-06-10 11:11:25.135639', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (50, 0, '普通', '0', 'event_security', NULL, 'default', NULL, '0', 'admin', '2025-02-18 10:42:10.310314', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (51, 1, '重要', '1', 'event_security', NULL, 'default', NULL, '0', 'admin', '2025-02-18 10:42:24.758055', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (52, 2, '紧急', '2', 'event_security', NULL, 'default', NULL, '0', 'admin', '2025-02-18 10:42:56.15506', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (64, 0, '温度高', '1', 'event_type', NULL, 'default', NULL, '0', 'admin', '2025-05-15 15:45:44.150987', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (65, 0, '门禁打开', '2', 'event_type', NULL, 'default', NULL, '0', 'admin', '2025-05-15 15:46:00.023575', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (72, 0, '设备间温度异常', '1', 'env_alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-05-26 11:14:11.767225', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (73, 2, '设备间湿度异常', '2', 'env_alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-05-26 11:14:31.955028', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (49, 1, '结束', '1', 'event_status', NULL, 'default', NULL, '0', 'admin', '2025-02-18 10:41:41.340735', 'admin', '2025-06-10 11:11:34.697908', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (69, 0, '零点核查', '0', 'quality_control_type', NULL, 'default', NULL, '0', 'admin', '2025-05-26 11:13:34.698961', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (70, 2, '线性核查', '2', 'quality_control_type', NULL, 'default', NULL, '0', 'admin', '2025-05-26 11:13:52.165704', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (71, 1, '跨度校准', '1', 'quality_control_type', NULL, 'default', NULL, '0', 'admin', '2025-05-26 11:14:10.132452', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (67, 0, '计划触发', '0', 'quality_control_task_type', NULL, 'default', NULL, '0', 'admin', '2025-05-26 11:10:30.583954', 'admin', '2026-09-15 14:55:00', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (66, 1, '手动触发', '1', 'quality_control_task_type', NULL, 'default', NULL, '0', 'admin', '2025-05-26 11:09:44.965132', 'admin', '2026-09-15 14:55:00', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (68, 2, '现场任务', '2', 'quality_control_task_type', NULL, 'default', NULL, '0', 'admin', '2025-05-26 11:10:47.169554', 'admin', '2025-08-04 16:55:02.265462', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (251, 3, '远程平台触发', '3', 'quality_control_task_type', NULL, 'warning', NULL, '0', 'admin', '2026-09-15 14:55:00', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (74, 3, '设备间漏水', '3', 'env_alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-05-26 11:14:41.820906', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (75, 4, '供电电源异常波动', '4', 'env_alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-05-26 11:14:50.685013', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (76, 5, '稳压电源异常波动', '5', 'env_alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-05-26 11:14:59.995441', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (77, 6, '电流异常波动', '6', 'env_alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-05-26 11:15:09.021601', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (78, 7, '有毒有害物质泄露报警', '7', 'env_alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-05-26 11:15:16.820676', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (79, 8, '标准气体泄漏', '8', 'env_alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-05-26 11:15:24.301417', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (80, 9, '标准气体更换', '9', 'env_alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-05-26 11:15:32.027893', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (81, 10, '颗粒物纸带更换', '10', 'env_alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-05-26 11:15:40.413341', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (82, 11, '采样总管流速异常', '11', 'env_alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-05-26 11:15:46.739274', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (83, 12, '采样总管温度异常', '12', 'env_alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-05-26 11:15:53.263968', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (84, 13, '支管冷凝水预警', '13', 'env_alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-05-26 11:16:00.277096', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (85, 14, '监测设备报警', '14', 'env_alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-05-26 11:16:06.872528', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (86, 15, '断电和恢复报警', '15', 'env_alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-05-26 11:16:13.098379', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (87, 16, '消防报警', '16', 'env_alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-05-26 11:16:21.239054', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (88, 17, '异常进入报警', '17', 'env_alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-05-26 11:16:27.974483', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (89, 18, '干扰报警', '18', 'env_alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-05-26 11:16:34.752069', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (92, 2, '成功', '2', 'quality_control_execution_status', NULL, 'success', NULL, '0', 'admin', '2025-05-26 15:17:06.31282', 'admin', '2025-06-20 00:18:06.834949', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (94, 0, 'SO2', '1', 'quality_control_param', NULL, 'default', NULL, '0', 'admin', '2025-05-26 16:37:27.535872', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (98, 4, 'PM10', '5', 'quality_control_param', NULL, 'default', NULL, '0', 'admin', '2025-05-26 16:38:33.291337', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (99, 5, 'PM2.5', '6', 'quality_control_param', NULL, 'default', NULL, '0', 'admin', '2025-05-26 16:38:50.184871', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (95, 1, 'NOx', '2', 'quality_control_param', NULL, 'default', NULL, '0', 'admin', '2025-05-26 16:37:35.948963', 'admin', '2025-06-20 01:34:18.199537', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (102, 0, '空调设备', '0', 'env_device_manager_device_type', NULL, 'default', NULL, '0', 'admin', '2025-05-26 18:06:45.194356', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (103, 1, '开关设备', '1', 'env_device_manager_device_type', NULL, 'default', NULL, '0', 'admin', '2025-05-26 18:06:56.017125', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (104, 0, 'SO2滤膜管理', '1', 'maintenance_mode', NULL, 'default', NULL, '0', 'admin', '2025-05-26 18:13:15.69763', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (105, 1, 'NO2滤膜管理', '2', 'maintenance_mode', NULL, 'default', NULL, '0', 'admin', '2025-05-26 18:13:48.925126', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (106, 2, 'O3滤膜管理', '3', 'maintenance_mode', NULL, 'default', NULL, '0', 'admin', '2025-05-26 18:14:01.38454', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (107, 3, 'CO滤膜管理', '4', 'maintenance_mode', NULL, 'default', NULL, '0', 'admin', '2025-05-26 18:14:09.9849', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (108, 4, 'PM10切割器管理', '5', 'maintenance_mode', NULL, 'default', NULL, '0', 'admin', '2025-05-26 18:14:19.918036', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (109, 5, 'PM2.5切割器管理', '6', 'maintenance_mode', NULL, 'default', NULL, '0', 'admin', '2025-05-26 18:14:39.28783', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (110, 0, '空气检测子站巡检', '1', 'patrol_type', NULL, 'default', NULL, '0', 'admin', '2025-05-27 00:54:37.454371', 'admin', '2025-05-27 00:54:57.12447', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (111, 2, '门禁设备', '2', 'env_device_manager_device_type', NULL, 'default', NULL, '0', 'admin', '2025-05-27 09:12:40.288281', 'admin', '2025-05-27 09:12:48.868392', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (113, 4, '巡检任务', 'Patrol', 'sys_job_group', NULL, 'primary', NULL, '0', 'admin', '2025-05-27 13:47:31.197995', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (114, 5, '维护任务', 'Maintenance', 'sys_job_group', NULL, 'primary', NULL, '0', 'admin', '2025-05-27 13:48:40.098734', 'admin', '2025-07-10 14:23:42.901771', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (10, 1, '自定义', 'DEFAULT', 'sys_job_group', '', 'info', 'Y', '0', 'admin', '2025-02-14 02:51:49.375243', 'admin', '2025-05-27 14:13:48.800001', '默认分组');
INSERT INTO "public"."sys_dict_data" VALUES (115, 0, 'CO钢瓶气', '1', 'material_type', NULL, 'default', NULL, '0', 'admin', '2025-05-27 17:16:54.483273', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (116, 1, 'SO2钢瓶气', '2', 'material_type', NULL, 'default', NULL, '0', 'admin', '2025-05-27 17:17:16.810759', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (117, 2, 'NOx钢瓶气', '3', 'material_type', NULL, 'default', NULL, '0', 'admin', '2025-05-27 17:17:34.729256', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (121, 1, '刷卡', '2', 'access_method', NULL, 'default', NULL, '0', 'admin', '2025-05-29 00:34:46.841076', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (122, 3, '人脸', '4', 'access_method', NULL, 'default', NULL, '0', 'admin', '2025-05-29 00:36:09.739235', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (120, 2, '指纹', '3', 'access_method', NULL, 'default', NULL, '0', 'admin', '2025-05-29 00:34:25.932947', 'admin', '2025-05-29 00:36:30.519377', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (123, 0, '密码', '1', 'access_method', NULL, 'default', NULL, '0', 'admin', '2025-05-29 00:36:45.177667', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (118, 3, 'PM10纸带', '4', 'material_type', NULL, 'default', NULL, '0', 'admin', '2025-05-27 17:21:32.981206', 'admin', '2025-05-30 09:06:37.789065', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (119, 4, 'PM2.5纸带', '5', 'material_type', NULL, 'default', NULL, '0', 'admin', '2025-05-27 17:21:42.278688', 'admin', '2025-05-30 09:06:47.010958', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (128, 1, '警告', '1', 'alarm_security', NULL, 'default', NULL, '0', 'admin', '2025-06-01 16:49:51.825062', 'admin', '2025-06-05 08:53:11.220561', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (129, 2, '严重', '2', 'alarm_security', NULL, 'default', NULL, '0', 'admin', '2025-06-01 16:50:01.135368', 'admin', '2025-06-05 08:53:14.557168', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (112, 3, '质控任务', 'QualityControl', 'sys_job_group', NULL, 'success', NULL, '0', 'admin', '2025-05-27 13:45:31.862539', 'admin', '2025-07-10 14:22:41.781235', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (130, 0, '待处理', '0', 'alarm_status', NULL, 'warning', NULL, '0', 'admin', '2025-06-01 16:53:32.011631', 'admin', '2025-06-25 18:25:51.737995', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (131, 1, '已解决', '1', 'alarm_status', NULL, 'success', NULL, '0', 'admin', '2025-06-01 16:53:46.069448', 'admin', '2025-06-25 18:25:56.146295', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (127, 0, '普通', '0', 'alarm_security', NULL, 'default', NULL, '0', 'admin', '2025-06-01 16:49:40.781906', 'admin', '2025-06-05 08:55:38.199511', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (124, 0, '设备间温度异常', '1', 'alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-06-01 16:47:25.63594', 'admin', '2025-06-07 11:29:33.414797', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (125, 1, '设备间湿度异常', '2', 'alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-06-01 16:47:40.071343', 'admin', '2025-06-07 11:30:20.771489', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (126, 2, '设备间漏水', '3', 'alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-06-01 16:48:09.783602', 'admin', '2025-06-07 11:30:30.959278', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (134, 40, '供电电源异常波动', '4', 'alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-06-07 11:30:48.569093', 'admin', '2025-06-07 11:30:54.740125', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (135, 50, '稳压电源异常波动', '5', 'alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-06-07 11:31:08.473505', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (136, 60, '电流异常波动', '6', 'alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-06-07 11:31:23.262158', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (137, 80, '标准气体泄漏', '8', 'alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-06-07 11:31:55.655304', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (138, 90, '标准气体更换', '9', 'alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-06-07 11:32:28.363251', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (139, 100, '颗粒物纸带更换', '10', 'alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-06-07 11:32:43.828883', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (140, 110, '采样总管流速异常', '11', 'alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-06-07 11:33:00.794534', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (141, 120, '采样总管温度异常', '12', 'alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-06-07 11:33:15.723963', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (142, 130, '支管冷凝水预警', '13', 'alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-06-07 11:33:29.600934', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (143, 140, '监测设备报警', '14', 'alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-06-07 11:33:54.028317', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (144, 150, '断电和恢复报警', '15', 'alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-06-07 11:34:06.98217', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (93, 3, '失败', '3', 'quality_control_execution_status', NULL, 'danger', NULL, '0', 'admin', '2025-05-26 15:18:16.734112', 'admin', '2025-06-20 00:18:13.169187', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (96, 3, 'CO', '4', 'quality_control_param', NULL, 'default', NULL, '0', 'admin', '2025-05-26 16:38:03.219959', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (97, 2, 'O3', '3', 'quality_control_param', NULL, 'default', NULL, '0', 'admin', '2025-05-26 16:38:19.342376', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (100, 1, '手动', '1', 'maintenance_type', NULL, 'default', NULL, '0', 'admin', '2025-05-26 17:28:38.228859', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (101, 0, '自动', '0', 'maintenance_type', NULL, 'default', NULL, '0', 'admin', '2025-05-26 17:28:48.27327', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (145, 160, '消防报警', '16', 'alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-06-07 11:34:24.45256', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (146, 170, '异常进入报警', '17', 'alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-06-07 11:34:38.948851', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (147, 180, '干扰报警', '18', 'alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-06-07 11:34:51.69625', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (148, 190, '物资更新异常', '19', 'alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-06-12 14:24:10.968335', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (149, 200, '设备通讯异常', '20', 'alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-06-12 14:26:18.710301', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (150, 210, '总管冷凝水预警', '21', 'alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-06-12 14:26:31.890252', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (151, 0, '浮点数类型', 'float', 'env_realdata_data_type', NULL, 'default', NULL, '0', 'admin', '2025-06-13 14:43:43.613567', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (152, 1, '字符串类型', 'string', 'env_realdata_data_type', NULL, 'default', NULL, '0', 'admin', '2025-06-13 14:44:02.735329', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (153, 3, '整数类型', 'int', 'env_realdata_data_type', NULL, 'default', NULL, '0', 'admin', '2025-06-13 14:44:15.62426', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (90, 0, '等待中', '0', 'quality_control_execution_status', NULL, 'default', NULL, '0', 'admin', '2025-05-26 15:16:05.047366', 'admin', '2025-06-20 00:17:46.209776', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (91, 1, '执行中', '1', 'quality_control_execution_status', NULL, 'primary', NULL, '0', 'admin', '2025-05-26 15:16:20.231195', 'admin', '2025-06-20 00:18:00.712607', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (154, 4, '采样管温度', '4', 'env_device_manager_device_type', NULL, 'default', NULL, '0', 'admin', '2025-06-23 09:21:25.137794', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (155, 5, '开关设备2', '5', 'env_device_manager_device_type', NULL, 'default', NULL, '0', 'admin', '2025-06-23 09:21:43.748065', 'admin', '2025-06-23 09:47:53.636442', '反向设备0开1关');
INSERT INTO "public"."sys_dict_data" VALUES (156, 0, '未设置', '-1', 'data_sign', NULL, 'default', NULL, '0', 'admin', '2025-06-25 15:28:53.179515', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (157, 6, '零点控制', '6', 'env_device_manager_device_type', NULL, 'default', NULL, '0', 'admin', '2025-06-30 11:33:51.92276', 'admin', '2025-06-30 11:42:01.829046', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (167, 10, '报警修改', '10', 'sys_oper_type', NULL, 'danger', NULL, '0', 'admin', '2025-07-08 10:29:16.257902', 'admin', '2025-07-08 10:29:54.187003', '报警信息设置');
INSERT INTO "public"."sys_dict_data" VALUES (168, 11, '设备控制', '11', 'sys_oper_type', NULL, 'danger', NULL, '0', 'admin', '2025-07-08 10:29:30.013134', 'admin', '2025-07-08 10:30:04.218294', '设备控制设置');
INSERT INTO "public"."sys_dict_data" VALUES (169, 3, '精密度检查', '3', 'quality_control_type', NULL, 'default', NULL, '0', 'admin', '2025-07-08 18:50:58.55686', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (170, 4, '准确度校准', '4', 'quality_control_type', NULL, 'default', NULL, '0', 'admin', '2025-07-08 18:51:12.308369', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (171, 5, '转换率检查', '5', 'quality_control_type', NULL, 'default', NULL, '0', 'admin', '2025-07-08 18:51:23.711976', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (172, 6, '非标跨度检查', '6', 'quality_control_type', NULL, 'default', NULL, '0', 'admin', '2025-07-08 18:52:14.92281', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (173, 220, '门禁报警', '22', 'alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-07-09 20:13:31.058674', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (174, 2, '人工核查', 'ManualCheck', 'sys_job_group', NULL, 'success', NULL, '0', 'admin', '2025-07-10 14:16:30.473593', 'admin', '2025-07-10 14:22:26.717563', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (175, 6, '聚合数据', 'aggregationDataTask', 'sys_job_group', NULL, 'warning', NULL, '0', 'admin', '2025-08-20 15:44:11.313712', 'admin', '2025-08-20 16:13:07.164842', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (176, 7, '创建分表', 'CreatePartitionTablesTask', 'sys_job_group', NULL, 'warning', NULL, '0', 'admin', '2025-08-20 15:44:44.595713', 'admin', '2025-08-20 16:57:36.539949', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (177, 201, 'zkteco门禁设备', '201', 'env_device_manager_device_type', NULL, 'default', NULL, '0', 'admin', '2025-08-21 14:17:31.822285', 'admin', '2025-08-21 14:17:40.182145', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (178, 301, '纵横通-空调设备', '301', 'env_device_manager_device_type', NULL, 'default', NULL, '0', 'admin', '2025-08-21 14:22:32.62381', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (179, 100, '其他', '100', 'material_type', NULL, 'default', NULL, '0', 'admin', '2025-08-22 14:24:28.477577', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (201, 0, 'sms-空调设备', '0', 'env_device_manager_device_type', NULL, 'default', NULL, '0', 'admin', '2025-05-26 18:06:45.194356', 'admin', '2025-10-17 15:19:07.531812', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (202, 1, 'sms-开关设备', '1', 'env_device_manager_device_type', NULL, 'default', NULL, '0', 'admin', '2025-05-26 18:06:56.017125', 'admin', '2025-10-17 15:19:12.972497', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (203, 4, 'sms-采样管温度', '4', 'env_device_manager_device_type', NULL, 'default', NULL, '0', 'admin', '2025-06-23 09:21:25.137794', 'admin', '2025-10-17 15:19:20.156347', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (204, 5, 'sms-开关设备2', '5', 'env_device_manager_device_type', NULL, 'default', NULL, '0', 'admin', '2025-06-23 09:21:43.748065', 'admin', '2025-10-17 15:19:24.10574', '反向设备0开1关');
INSERT INTO "public"."sys_dict_data" VALUES (205, 6, 'sms-零点控制', '6', 'env_device_manager_device_type', NULL, 'default', NULL, '0', 'admin', '2025-06-30 11:33:51.92276', 'admin', '2025-10-17 15:19:28.561715', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (206, 1000, '空调设备', '1000', 'env_device_manager_device_type', NULL, 'default', NULL, '0', 'admin', '2025-10-17 15:19:54.394466', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (207, 1001, '开关设备', '1001', 'env_device_manager_device_type', NULL, 'default', NULL, '0', 'admin', '2025-10-17 15:20:17.709423', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (208, 1002, '门禁设备', '1002', 'env_device_manager_device_type', NULL, 'default', NULL, '0', 'admin', '2025-10-17 15:20:28.291668', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (209, 1003, '无状态开关', '1003', 'env_device_manager_device_type', NULL, 'default', NULL, '0', 'admin', '2025-10-17 15:20:42.400752', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (210, 1004, '数值设备', '1004', 'env_device_manager_device_type', NULL, 'default', NULL, '0', 'admin', '2025-10-17 15:20:57.227037', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (211, 1000, '多参数阈值报警', '1000', 'env_alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-10-20 17:46:09.815128', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (212, 1010, '超出范围报警', '1010', 'env_alarm_type', NULL, 'default', NULL, '0', 'admin', '2025-10-20 17:46:43.035593', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (213, 2, '一小时数据', 'hour', 'data_type', NULL, 'default', NULL, '0', 'admin', '2025-10-25 14:37:16.194211', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (214, 1, '五分钟数据', 'minute', 'data_type', NULL, 'default', NULL, '0', 'admin', '2025-02-18 11:45:24.89278', 'admin', '2025-10-25 14:37:22.977364', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (215, 0, '一分钟数据', '1minute', 'data_type', NULL, 'default', NULL, '0', 'admin', '2025-10-25 14:37:40.164877', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (216, 8, '数据推送', 'ExecuteSiChuanHj212RuleTask', 'sys_job_group', NULL, 'primary', NULL, '0', 'admin', '2025-10-28 16:44:02.920978', 'admin', '2025-10-28 16:44:12.409992', NULL);
INSERT INTO "public"."sys_dict_data" VALUES (221, 102, '传感器报警', '102', 'data_sign', NULL, 'default', NULL, '0', 'admin', '2025-11-07 16:41:13.963538', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (222, 103, '统计数据不足', '103', 'data_sign', NULL, 'default', NULL, '0', 'admin', '2025-11-07 16:41:24.008637', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (223, 104, '维护', '104', 'data_sign', NULL, 'default', NULL, '0', 'admin', '2025-11-07 16:41:31.609241', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (224, 105, '运行不良', '105', 'data_sign', NULL, 'default', NULL, '0', 'admin', '2025-11-07 16:41:38.208359', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (225, 106, '等待数据恢复', '106', 'data_sign', NULL, 'default', NULL, '0', 'admin', '2025-11-07 16:41:45.459223', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (226, 107, '校准 (质控)', '107', 'data_sign', NULL, 'default', NULL, '0', 'admin', '2025-11-07 16:41:53.359884', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (227, 108, '数据突变', '108', 'data_sign', NULL, 'default', NULL, '0', 'admin', '2025-11-07 16:42:01.016819', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (228, 109, '数据不变', '109', 'data_sign', NULL, 'default', NULL, '0', 'admin', '2025-11-07 16:42:07.228441', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (229, 110, '超上限', '110', 'data_sign', NULL, 'default', NULL, '0', 'admin', '2025-11-07 16:42:15.187918', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (230, 111, '超下限', '111', 'data_sign', NULL, 'default', NULL, '0', 'admin', '2025-11-07 16:42:21.319352', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (231, 112, '零点检查', '112', 'data_sign', NULL, 'default', NULL, '0', 'admin', '2025-11-07 16:42:28.310478', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (232, 113, '跨度检查', '113', 'data_sign', NULL, 'default', NULL, '0', 'admin', '2025-11-07 16:42:34.737025', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (233, 114, '准确度检查', '114', 'data_sign', NULL, 'default', NULL, '0', 'admin', '2025-11-07 16:42:41.217036', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (234, 115, '零点校准', '115', 'data_sign', NULL, 'default', NULL, '0', 'admin', '2025-11-07 16:42:48.379127', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (235, 116, '跨度校准', '116', 'data_sign', NULL, 'default', NULL, '0', 'admin', '2025-11-07 16:42:54.847377', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (236, 117, '流量检查', '117', 'data_sign', NULL, 'default', NULL, '0', 'admin', '2025-11-07 16:43:01.558612', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (237, 118, '质量检查', '118', 'data_sign', NULL, 'default', NULL, '0', 'admin', '2025-11-07 16:43:12.637005', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (238, 119, '检定零点漂移', '119', 'data_sign', NULL, 'default', NULL, '0', 'admin', '2025-11-07 16:43:21.788244', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (239, 120, '检定跨度漂移', '120', 'data_sign', NULL, 'default', NULL, '0', 'admin', '2025-11-07 16:43:28.036696', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (240, 121, '检定跨度重现性', '121', 'data_sign', NULL, 'default', NULL, '0', 'admin', '2025-11-07 16:43:34.129175', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (241, 122, '检定多点跨度(线性)', '122', 'data_sign', NULL, 'default', NULL, '0', 'admin', '2025-11-07 16:43:42.137651', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (242, 123, '精密度检查', '123', 'data_sign', NULL, 'default', NULL, '0', 'admin', '2025-11-07 16:43:42.137651', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (247, 124, '温度压力校准', '124', 'data_sign', NULL, 'default', NULL, '0', 'admin', '2025-11-07 16:43:42.137651', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (248, 125, '维修更换设备', '125', 'data_sign', NULL, 'default', NULL, '0', 'admin', '2025-11-07 16:43:53.947877', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (244, 9999, '其他状态', '9999', 'data_sign', NULL, 'default', NULL, '0', 'admin', '2025-11-07 16:43:53.947877', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (245, 3, '日数据', 'day', 'data_type', NULL, 'default', NULL, '0', 'admin', '2025-12-24 12:00:00.194211', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (246, 5, '中止中', '4', 'quality_control_execution_status', NULL, 'warning', NULL, '0', 'admin', '2025-12-31 14:47:14.123191', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (249, 230, '洁净度报警', '23', 'alarm_type', NULL, 'default', NULL, '0', 'Admin7s9k2G5', '2026-06-05 14:36:06.9299', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_data" VALUES (250, 9, '设备控制', 'DeviceAttributeControl', 'sys_job_group', NULL, 'danger', NULL, '0', 'Admin7s9k2G5', '2026-08-05 15:39:54.321697', 'Admin7s9k2G5', '2026-08-05 15:43:55.22284', NULL);

CREATE TABLE "public"."sys_dict_type" (
  "dict_id" int8 NOT NULL DEFAULT nextval('sys_dict_type_dict_id_seq'::regclass),
  "dict_name" varchar(100) COLLATE "pg_catalog"."default",
  "dict_type" varchar(100) COLLATE "pg_catalog"."default",
  "status" char(1) COLLATE "pg_catalog"."default",
  "create_by" varchar(64) COLLATE "pg_catalog"."default",
  "create_time" timestamp(6),
  "update_by" varchar(64) COLLATE "pg_catalog"."default",
  "update_time" timestamp(6),
  "remark" varchar(500) COLLATE "pg_catalog"."default"
)
;
COMMENT ON COLUMN "public"."sys_dict_type"."dict_id" IS '字典主键';
COMMENT ON COLUMN "public"."sys_dict_type"."dict_name" IS '字典名称';
COMMENT ON COLUMN "public"."sys_dict_type"."dict_type" IS '字典类型';
COMMENT ON COLUMN "public"."sys_dict_type"."status" IS '状态（0正常 1停用）';
COMMENT ON COLUMN "public"."sys_dict_type"."create_by" IS '创建者';
COMMENT ON COLUMN "public"."sys_dict_type"."create_time" IS '创建时间';
COMMENT ON COLUMN "public"."sys_dict_type"."update_by" IS '更新者';
COMMENT ON COLUMN "public"."sys_dict_type"."update_time" IS '更新时间';
COMMENT ON COLUMN "public"."sys_dict_type"."remark" IS '备注';
COMMENT ON TABLE "public"."sys_dict_type" IS '字典类型表';

INSERT INTO "public"."sys_dict_type" VALUES (2, '菜单状态', 'sys_show_hide', '0', 'admin', '2021-05-26 18:56:30', '', NULL, '菜单状态列表');
INSERT INTO "public"."sys_dict_type" VALUES (3, '系统开关', 'sys_normal_disable', '0', 'admin', '2021-05-26 18:56:30', '', NULL, '系统开关列表');
INSERT INTO "public"."sys_dict_type" VALUES (4, '任务状态', 'sys_job_status', '0', 'admin', '2021-05-26 18:56:30', '', NULL, '任务状态列表');
INSERT INTO "public"."sys_dict_type" VALUES (5, '任务分组', 'sys_job_group', '0', 'admin', '2021-05-26 18:56:30', '', NULL, '任务分组列表');
INSERT INTO "public"."sys_dict_type" VALUES (6, '系统是否', 'sys_yes_no', '0', 'admin', '2021-05-26 18:56:30', '', NULL, '系统是否列表');
INSERT INTO "public"."sys_dict_type" VALUES (7, '通知类型', 'sys_notice_type', '0', 'admin', '2021-05-26 18:56:30', '', NULL, '通知类型列表');
INSERT INTO "public"."sys_dict_type" VALUES (8, '通知状态', 'sys_notice_status', '0', 'admin', '2021-05-26 18:56:30', '', NULL, '通知状态列表');
INSERT INTO "public"."sys_dict_type" VALUES (9, '操作类型', 'sys_oper_type', '0', 'admin', '2021-05-26 18:56:30', '', NULL, '操作类型列表');
INSERT INTO "public"."sys_dict_type" VALUES (10, '系统状态', 'sys_common_status', '0', 'admin', '2021-05-26 18:56:30', '', NULL, '登录状态列表');
INSERT INTO "public"."sys_dict_type" VALUES (1, '用户性别', 'sys_user_sex', '0', 'admin', '2021-05-26 18:56:30', 'admin', '2021-05-27 10:07:12.015926', '用户性别列表');
INSERT INTO "public"."sys_dict_type" VALUES (11, '系统标识', 'sys_tid', '0', 'admin', '2025-02-14 11:28:03.162922', 'admin', '2025-02-14 11:29:08.143238', NULL);
INSERT INTO "public"."sys_dict_type" VALUES (12, '系统标识名称', 'sys_tid_name', '0', 'admin', '2025-02-14 11:29:26.583566', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_type" VALUES (13, '站房数据类型', 'sys_data_type', '0', 'admin', '2025-02-14 11:30:34.583798', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_type" VALUES (14, 'COM口', 'sys_device_com', '0', 'admin', '2025-02-14 13:30:42.575637', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_type" VALUES (15, '设备协议', 'sys_device_pro', '0', 'admin', '2025-02-14 13:35:49.12917', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_type" VALUES (16, '设备类型', 'sys_device_type', '0', 'admin', '2025-02-14 13:38:49.587065', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_type" VALUES (19, '采集类型', 'thing_type', '0', 'admin', '2025-02-18 11:38:46.341722', NULL, NULL, '采集类型');
INSERT INTO "public"."sys_dict_type" VALUES (20, '数据类型', 'data_type', '0', 'admin', '2025-02-18 11:44:53.281228', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_type" VALUES (21, '数据标识', 'data_sign', '0', 'admin', '2025-02-18 13:48:12.679261', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_type" VALUES (22, '任务类型', 'task_type', '0', 'admin', '2025-02-24 13:51:03.928634', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_type" VALUES (23, '上传任务状态', 'task_status', '0', 'admin', '2025-02-24 14:13:08.210154', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_type" VALUES (17, '事件状态', 'event_status', '0', 'admin', '2025-02-18 10:37:44.954497', 'admin', '2025-05-12 11:44:06.497462', NULL);
INSERT INTO "public"."sys_dict_type" VALUES (18, '事件安全', 'event_security', '0', 'admin', '2025-02-18 10:38:34.201997', 'admin', '2025-05-12 11:44:11.46665', NULL);
INSERT INTO "public"."sys_dict_type" VALUES (24, '事件类型', 'event_type', '0', 'admin', '2025-05-12 11:44:52.952691', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_type" VALUES (25, '报警状态', 'alarm_status', '0', 'admin', '2025-05-16 11:48:11.138956', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_type" VALUES (26, '报警等级', 'alarm_security', '0', 'admin', '2025-05-16 11:48:30.598662', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_type" VALUES (27, '报警类型', 'alarm_type', '0', 'admin', '2025-05-16 11:48:48.834328', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_type" VALUES (28, '质控任务类型', 'quality_control_task_type', '0', 'admin', '2025-05-26 11:07:53.395891', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_type" VALUES (29, '质控类型', 'quality_control_type', '0', 'admin', '2025-05-26 11:12:55.826363', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_type" VALUES (30, '报警管理-报警类型', 'env_alarm_type', '0', 'admin', '2025-05-26 11:13:41.077072', 'admin', '2025-05-26 11:13:55.286256', NULL);
INSERT INTO "public"."sys_dict_type" VALUES (31, '质控执行状态', 'quality_control_execution_status', '0', 'admin', '2025-05-26 15:15:02.800829', 'admin', '2025-05-26 15:15:34.284175', NULL);
INSERT INTO "public"."sys_dict_type" VALUES (32, '质控参数', 'quality_control_param', '0', 'admin', '2025-05-26 16:36:54.362425', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_type" VALUES (33, '维护类型', 'maintenance_type', '0', 'admin', '2025-05-26 17:28:20.419693', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_type" VALUES (34, '设备控制类型', 'env_device_manager_device_type', '0', 'admin', '2025-05-26 17:54:36.201053', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_type" VALUES (35, '维护模式', 'maintenance_mode', '0', 'admin', '2025-05-26 18:12:44.276977', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_type" VALUES (36, '巡检类型', 'patrol_type', '0', 'admin', '2025-05-27 00:54:03.223609', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_type" VALUES (37, '物资类型', 'material_type', '0', 'admin', '2025-05-27 17:08:48.146628', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_type" VALUES (38, '打卡方式', 'access_method', '0', 'admin', '2025-05-29 00:33:03.268122', NULL, NULL, NULL);
INSERT INTO "public"."sys_dict_type" VALUES (39, '原始数据类型', 'env_realdata_data_type', '0', 'admin', '2025-06-13 14:42:57.287575', NULL, NULL, NULL);

CREATE TABLE "public"."sys_job" (
  "job_id" int8 NOT NULL DEFAULT nextval('sys_job_job_id_seq'::regclass),
  "job_name" varchar(64) COLLATE "pg_catalog"."default" NOT NULL,
  "job_group" varchar(64) COLLATE "pg_catalog"."default" NOT NULL,
  "invoke_target" varchar(500) COLLATE "pg_catalog"."default" NOT NULL,
  "cron_expression" varchar(255) COLLATE "pg_catalog"."default",
  "misfire_policy" varchar(20) COLLATE "pg_catalog"."default",
  "concurrent" char(1) COLLATE "pg_catalog"."default",
  "status" char(1) COLLATE "pg_catalog"."default",
  "create_by" varchar(64) COLLATE "pg_catalog"."default",
  "create_time" timestamp(6),
  "update_by" varchar(64) COLLATE "pg_catalog"."default",
  "update_time" timestamp(6),
  "remark" varchar(500) COLLATE "pg_catalog"."default"
)
;
COMMENT ON COLUMN "public"."sys_job"."job_id" IS '任务ID';
COMMENT ON COLUMN "public"."sys_job"."job_name" IS '任务名称';
COMMENT ON COLUMN "public"."sys_job"."job_group" IS '任务组名';
COMMENT ON COLUMN "public"."sys_job"."invoke_target" IS '调用目标字符串';
COMMENT ON COLUMN "public"."sys_job"."cron_expression" IS 'cron执行表达式';
COMMENT ON COLUMN "public"."sys_job"."misfire_policy" IS '计划执行错误策略（1立即执行 2执行一次 3放弃执行）';
COMMENT ON COLUMN "public"."sys_job"."concurrent" IS '是否并发执行（0允许 1禁止）';
COMMENT ON COLUMN "public"."sys_job"."status" IS '状态（0正常 1暂停）';
COMMENT ON COLUMN "public"."sys_job"."create_by" IS '创建者';
COMMENT ON COLUMN "public"."sys_job"."create_time" IS '创建时间';
COMMENT ON COLUMN "public"."sys_job"."update_by" IS '更新者';
COMMENT ON COLUMN "public"."sys_job"."update_time" IS '更新时间';
COMMENT ON COLUMN "public"."sys_job"."remark" IS '备注信息';
COMMENT ON TABLE "public"."sys_job" IS '定时任务调度表';

INSERT INTO "public"."sys_job" (
    job_id, job_name, job_group, invoke_target, cron_expression, 
    misfire_policy, concurrent, status, create_by, create_time, 
    update_by, update_time, remark
) VALUES 
(11, '实时表分表', 'CreatePartitionTablesTask', 'CreatePartitionTablesTask.run(''realdata'',-2,2)', '0 0 0 * * ?', 1, 1, 1, 'admin', '2025/9/18 10:30', NULL, '2025/9/18 10:31', NULL),
(12, '历史表分表', 'CreatePartitionTablesTask', 'CreatePartitionTablesTask.run(''his_data'',-2,2)', '0 0 0 * * ?', 1, 1, 1, 'admin', '2025/9/18 10:30', NULL, '2025/9/18 10:31', NULL),
(13, '维护换膜', 'Maintenance', 'maintenanceTask.run(''no2_filter'')', '0 0 9 ? * 3', 1, 1, 1, 'admin', '2025/9/18 10:19', NULL, '2025/9/18 10:26', NULL),
(14, '每日子站巡检', 'Patrol', 'patrolTask.run(''substation_patrol'')', '0 10 0 * * ?', 1, 1, 0, 'admin', '2025/9/18 10:17', NULL, '2025/9/18 10:31', NULL),
(15, '质控报告定时自动生成', 'DEFAULT', 'qualityControlGenReportTask.run('''','''')', '0 5 0 * * ?', 1, 1, 0, 'admin', '2025/9/18 10:17', NULL, '2025/9/18 10:31', NULL),
(16, '一分钟数据聚合', 'aggregationDataTask', 'aggregationDataTask.run(''1minute'', '''', '''', false, 1, ''*'', ''*'')', '2 0/1 * * * ?', '3', '1', '0', 'admin', '2025-10-20 15:00:00', 'admin', '2025-10-25 15:00:00', NULL),
(17, '五分钟数据聚合', 'aggregationDataTask', 'aggregationDataTask.run(''minute'', '''', '''', false, 5, ''*'', ''*'')', '5 0/5 * * * ?', '3', '1', '0', 'admin', '2025-09-18 15:00:00', 'admin', '2025-10-25 15:00:54', NULL),
(18, '小时数据聚合', 'aggregationDataTask', 'aggregationDataTask.run(''hour'', '''', '''', false, 60, ''*'', ''*'')', '10 0 * * * ?', '3', '1', '0', 'admin', '2025-10-17 15:00:00', 'admin', '2025-10-25 15:00:00', NULL),
(19, '日数据聚合', 'aggregationDataTask', 'aggregationDataTask.run(''day'', '''', '''', false, 1440, ''*'', ''*'')', '20 0 0 * * ?', '3', '1', '0', 'admin', '2025-12-17 15:00:00', 'admin', '2025-12-20 15:00:00', NULL),
(21, '零点检查-SO2', 'QualityControl', 'qualityControlTask.run(''SO2'',''zero_check'',''0'')', '0 0 3 * * ?', '1', '1', '1', 'admin', '2025-12-05 14:33:16', 'admin', '2025-12-05 14:33:16', NULL),
(22, '零点核查-NO2', 'QualityControl', 'qualityControlTask.run(''NO2'',''zero_check'',''0'')', '0 0 6 * * ?', '3', '1', '1', 'admin', '2025-12-05 10:55:14.844781', 'admin', '2025-12-05 10:57:11', NULL),
(23, '零点核查-O3', 'QualityControl', 'qualityControlTask.run(''O3'',''zero_check'',''0'')', '0 0 4 * * ?', '3', '1', '1', 'admin', '2025-12-05 10:46:13.236297', 'admin', '2025-12-05 10:57:39', NULL),
(24, '零点核查-CO', 'QualityControl', 'qualityControlTask.run(''CO'',''zero_check'',''0'')', '0 0 5 * * ?', '1', '1', '1', 'admin', '2025-12-05 10:54:45.252143', 'admin', '2025-12-05 14:30:25', NULL),
(25, '跨度核查-NO2', 'QualityControl', 'qualityControlTask.run(''NO2'',''span_check'',''0.4'')', '0 30 6 * * ?', '3', '1', '1', 'admin', '2025-12-03 17:10:59.987549', 'admin', '2025-12-05 11:20:24', NULL),
(26, '跨度核查-CO', 'QualityControl', 'qualityControlTask.run(''CO'',''span_check'',''40'')', '0 30 5 * * ?', '3', '1', '1', 'admin', '2025-12-03 17:10:37.283367', 'admin', '2025-12-05 11:20:40', NULL),
(27, '跨度核查-SO2', 'QualityControl', 'qualityControlTask.run(''SO2'',''span_check'',''0.4'')', '0 30 3 * * ?', '3', '1', '1', 'admin', '2025-12-03 17:09:48.549555', 'admin', '2025-12-05 11:20:51', NULL),
(28, '跨度核查-O3', 'QualityControl', 'qualityControlTask.run(''O3'',''span_check'',''0.4'')', '0 30 4 * * ?', '3', '1', '1', 'admin', '2025-12-03 14:56:45.13104', 'admin', '2025-12-05 11:21:03', NULL),
(29, '线性核查-SO2', 'QualityControl', 'qualityControlTask.run(''SO2'',''multi_check'',''1'')', '0 0 0 * * ?', '3', '1', '1', 'admin', '2025-12-05 10:55:52.856741', 'admin', '2025-12-05 10:56:29', NULL),
(30, '线性核查-NO2', 'QualityControl', 'qualityControlTask.run(''NO2'',''multi_check'',''1'')', '0 0 0 * * ?', '3', '1', '1', 'admin', '2025-12-05 11:02:59', 'admin', '2025-12-05 11:02:59', NULL),
(31, '线性核查-O3', 'QualityControl', 'qualityControlTask.run(''O3'',''multi_check'',''1'')', '0 0 0 * * ?', '3', '1', '1', 'admin', '2025-12-05 11:01:39', 'admin', '2025-12-05 11:01:39', NULL),
(32, '线性核查-CO', 'QualityControl', 'qualityControlTask.run(''CO'',''multi_check'',''1'')', '0 0 0 * * ?', '3', '1', '1', 'admin', '2025-12-05 11:02:10', 'admin', '2025-12-05 11:02:10', NULL),
(33, '精密度核查-NO2', 'QualityControl', 'qualityControlTask.run(''NO2'',''precision_check'',''1'')', '0 0 0 * * ?', '3', '1', '1', 'admin', '2025-12-05 10:42:07', 'admin', '2025-12-05 10:58:02', NULL),
(34, '精密度核查-CO', 'QualityControl', 'qualityControlTask.run(''CO'',''precision_check'',''1'')', '0 0 0 * * ?', '3', '1', '1', 'admin', '2025-12-05 10:41:23', 'admin', '2025-12-05 10:58:11', NULL),
(35, '精密度核查-O3', 'QualityControl', 'qualityControlTask.run(''O3'',''precision_check'',''1'')', '0 0 0 * * ?', '3', '1', '1', 'admin', '2025-12-05 10:40:52', 'admin', '2025-12-05 10:58:21', NULL),
(36, '精密度核查-SO2', 'QualityControl', 'qualityControlTask.run(''SO2'',''precision_check'',''1'')', '0 0 0 * * ?', '3', '1', '1', 'admin', '2025-12-05 10:40:06', 'admin', '2025-12-05 10:58:30', NULL),
(37, '准确度审核-SO2 ', 'QualityControl', 'qualityControlTask.run(''SO2'',''accuracy_check'',''1'')', '0 0 0 * * ?', '3', '1', '1', 'admin', '2025-12-05 11:11:51', 'admin', '2025-12-05 11:11:51', NULL),
(38, '准确度审核-O3', 'QualityControl', 'qualityControlTask.run(''O3'',''accuracy_check'',''1'')', '0 0 0 * * ?', '3', '1', '1', 'admin', '2025-12-05 11:12:20', 'admin', '2025-12-05 11:12:20', NULL),
(39, '准确度审核-CO', 'QualityControl', 'qualityControlTask.run(''CO'',''accuracy_check'',''1'')', '0 0 0 * * ?', '3', '1', '1', 'admin', '2025-12-05 11:12:55', 'admin', '2025-12-05 11:12:55', NULL),
(40, '准确度审核-NO2', 'QualityControl', 'qualityControlTask.run(''NO2'',''accuracy_check'',''1'')', '0 0 0 * * ?', '3', '1', '1', 'admin', '2025-12-05 11:13:29', 'admin', '2025-12-05 11:13:29', NULL),
(41, '转换效率检查-NOx', 'QualityControl', 'qualityControlTask.run(''NO2'',''conversion_check'',''1'')', '0 0 0 * * ?', '3', '1', '1', 'admin', '2025-12-05 11:16:27', 'admin', '2025-12-05 13:11:46', NULL),
(42, '人工核查-NO2', 'ManualCheck', 'qualityControlCustomTask.run(''NO2'', ''180'', ''3'', ''20'', ''0.400'', ''跨度检查'')', '0 0 4 * * ?', '3', '1', '1', 'admin', '2025-11-26 11:53:00', 'admin', '2025-12-05 11:21:24', NULL),
(43, '人工核查-CO', 'ManualCheck', 'qualityControlCustomTask.run(''CO'', ''180'', ''3'', ''20'', ''40.000'', ''跨度检查'')', '0 0 1 * * ?', '3', '1', '1', 'admin', '2025-11-26 11:40:45', 'admin', '2025-12-05 11:21:34', NULL),
(44, '人工核查-O3', 'ManualCheck', 'qualityControlCustomTask.run(''O3'', ''180'', ''3'', ''20'', ''0.400'', ''跨度检查'')', '0 0 2 * * ?', '3', '1', '1', 'admin', '2025-11-25 16:37:44', 'admin', '2025-12-05 11:21:44', NULL),
(45, '人工核查-SO2', 'ManualCheck', 'qualityControlCustomTask.run(''SO2'', ''180'', ''1'', ''10'', ''0.400'', ''跨度检查'')', '0 0 0 * * ?', '3', '1', '1', 'admin', '2025-11-25 16:34:55', 'admin', '2025-12-05 11:21:54', NULL);

CREATE TABLE "public"."sys_job_log" (
  "job_log_id" int8 NOT NULL DEFAULT nextval('sys_job_log_job_log_id_seq'::regclass),
  "job_name" varchar(64) COLLATE "pg_catalog"."default" NOT NULL,
  "job_group" varchar(64) COLLATE "pg_catalog"."default" NOT NULL,
  "invoke_target" varchar(500) COLLATE "pg_catalog"."default" NOT NULL,
  "job_message" varchar(500) COLLATE "pg_catalog"."default",
  "status" char(1) COLLATE "pg_catalog"."default",
  "exception_info" varchar(2000) COLLATE "pg_catalog"."default",
  "create_time" timestamp(6)
)
;
COMMENT ON COLUMN "public"."sys_job_log"."job_log_id" IS '任务日志ID';
COMMENT ON COLUMN "public"."sys_job_log"."job_name" IS '任务名称';
COMMENT ON COLUMN "public"."sys_job_log"."job_group" IS '任务组名';
COMMENT ON COLUMN "public"."sys_job_log"."invoke_target" IS '调用目标字符串';
COMMENT ON COLUMN "public"."sys_job_log"."job_message" IS '日志信息';
COMMENT ON COLUMN "public"."sys_job_log"."status" IS '执行状态（0正常 1失败）';
COMMENT ON COLUMN "public"."sys_job_log"."exception_info" IS '异常信息';
COMMENT ON COLUMN "public"."sys_job_log"."create_time" IS '创建时间';
COMMENT ON TABLE "public"."sys_job_log" IS '定时任务调度日志表';

CREATE TABLE "public"."sys_logininfor" (
  "info_id" int8 NOT NULL DEFAULT nextval('sys_logininfor_info_id_seq'::regclass),
  "user_name" varchar(50) COLLATE "pg_catalog"."default",
  "ipaddr" varchar(128) COLLATE "pg_catalog"."default",
  "login_location" varchar(255) COLLATE "pg_catalog"."default",
  "browser" varchar(50) COLLATE "pg_catalog"."default",
  "os" varchar(50) COLLATE "pg_catalog"."default",
  "status" char(1) COLLATE "pg_catalog"."default",
  "msg" varchar(255) COLLATE "pg_catalog"."default",
  "login_time" timestamp(6)
)
;
COMMENT ON COLUMN "public"."sys_logininfor"."info_id" IS '访问ID';
COMMENT ON COLUMN "public"."sys_logininfor"."user_name" IS '用户账号';
COMMENT ON COLUMN "public"."sys_logininfor"."ipaddr" IS '登录IP地址';
COMMENT ON COLUMN "public"."sys_logininfor"."login_location" IS '登录地点';
COMMENT ON COLUMN "public"."sys_logininfor"."browser" IS '浏览器类型';
COMMENT ON COLUMN "public"."sys_logininfor"."os" IS '操作系统';
COMMENT ON COLUMN "public"."sys_logininfor"."status" IS '登录状态（0成功 1失败）';
COMMENT ON COLUMN "public"."sys_logininfor"."msg" IS '提示消息';
COMMENT ON COLUMN "public"."sys_logininfor"."login_time" IS '访问时间';
COMMENT ON TABLE "public"."sys_logininfor" IS '系统访问记录';

CREATE TABLE "public"."sys_menu" (
  "menu_id" int8 NOT NULL DEFAULT nextval('sys_menu_menu_id_seq'::regclass),
  "menu_name" varchar(50) COLLATE "pg_catalog"."default" NOT NULL,
  "parent_id" int8 DEFAULT 0,
  "order_num" int4,
  "path" varchar(200) COLLATE "pg_catalog"."default",
  "component" varchar(255) COLLATE "pg_catalog"."default",
  "query" varchar(255) COLLATE "pg_catalog"."default",
  "route_name" varchar(50) COLLATE "pg_catalog"."default" DEFAULT ''::character varying,
  "is_frame" int4,
  "is_cache" int4 DEFAULT 0,
  "menu_type" char(1) COLLATE "pg_catalog"."default",
  "visible" char(1) COLLATE "pg_catalog"."default",
  "status" int2,
  "perms" varchar(100) COLLATE "pg_catalog"."default",
  "icon" varchar(100) COLLATE "pg_catalog"."default",
  "create_by" varchar(64) COLLATE "pg_catalog"."default",
  "create_time" timestamp(6),
  "update_by" varchar(64) COLLATE "pg_catalog"."default",
  "update_time" timestamp(6),
  "remark" varchar(500) COLLATE "pg_catalog"."default"
)
;
COMMENT ON COLUMN "public"."sys_menu"."menu_id" IS '菜单ID';
COMMENT ON COLUMN "public"."sys_menu"."menu_name" IS '菜单名称';
COMMENT ON COLUMN "public"."sys_menu"."parent_id" IS '父菜单ID';
COMMENT ON COLUMN "public"."sys_menu"."order_num" IS '显示顺序';
COMMENT ON COLUMN "public"."sys_menu"."path" IS '路由地址';
COMMENT ON COLUMN "public"."sys_menu"."component" IS '组件路径';
COMMENT ON COLUMN "public"."sys_menu"."query" IS '路由参数';
COMMENT ON COLUMN "public"."sys_menu"."route_name" IS '路由名称';
COMMENT ON COLUMN "public"."sys_menu"."is_frame" IS '是否为外链（0是 1否）';
COMMENT ON COLUMN "public"."sys_menu"."is_cache" IS '是否缓存（0缓存 1不缓存）';
COMMENT ON COLUMN "public"."sys_menu"."menu_type" IS '菜单类型（M目录 C菜单 F按钮）';
COMMENT ON COLUMN "public"."sys_menu"."visible" IS '菜单状态（0显示 1隐藏）';
COMMENT ON COLUMN "public"."sys_menu"."status" IS '菜单状态（0正常 1停用）';
COMMENT ON COLUMN "public"."sys_menu"."perms" IS '权限标识';
COMMENT ON COLUMN "public"."sys_menu"."icon" IS '菜单图标';
COMMENT ON COLUMN "public"."sys_menu"."create_by" IS '创建者';
COMMENT ON COLUMN "public"."sys_menu"."create_time" IS '创建时间';
COMMENT ON COLUMN "public"."sys_menu"."update_by" IS '更新者';
COMMENT ON COLUMN "public"."sys_menu"."update_time" IS '更新时间';
COMMENT ON COLUMN "public"."sys_menu"."remark" IS '备注';
COMMENT ON TABLE "public"."sys_menu" IS '菜单权限表';

INSERT INTO "public"."sys_menu" VALUES (1, '系统管理', 0, 99, 'system', NULL, '', '', 1, 0, 'M', '0', 0, '', 'system', 'admin', '2025-02-14 02:51:53.524904', 'Admin7s9k2G5', '2026-09-01 14:25:48.687674', '系统管理目录');
INSERT INTO "public"."sys_menu" VALUES (2, '系统监控', 0, 97, 'monitor', NULL, '', '', 1, 0, 'M', '1', 0, '', 'monitor', 'admin', '2025-02-14 02:51:53.564887', 'Admin7s9k2G5', '2026-09-01 14:25:39.709309', '系统监控目录');
INSERT INTO "public"."sys_menu" VALUES (3, '系统工具', 0, 98, 'tool', NULL, '', '', 1, 0, 'M', '1', 0, '', 'tool', 'admin', '2025-02-14 02:51:53.605457', 'Admin7s9k2G5', '2026-09-01 14:24:08.898048', '系统工具目录');
INSERT INTO "public"."sys_menu" VALUES (100, '用户管理', 1, 1, 'user', 'system/user/index', '', '', 1, 0, 'C', '0', 0, 'system:user:list', 'user', 'admin', '2025-02-14 02:51:53.684767', '', NULL, '用户管理菜单');
INSERT INTO "public"."sys_menu" VALUES (101, '角色管理', 1, 2, 'role', 'system/role/index', '', '', 1, 0, 'C', '0', 0, 'system:role:list', 'peoples', 'admin', '2025-02-14 02:51:53.725169', '', NULL, '角色管理菜单');
INSERT INTO "public"."sys_menu" VALUES (102, '菜单管理', 1, 3, 'menu', 'system/menu/index', '', '', 1, 0, 'C', '0', 0, 'system:menu:list', 'tree-table', 'admin', '2025-02-14 02:51:53.764913', '', NULL, '菜单管理菜单');
INSERT INTO "public"."sys_menu" VALUES (103, '部门管理', 1, 4, 'dept', 'system/dept/index', '', '', 1, 0, 'C', '0', 0, 'system:dept:list', 'tree', 'admin', '2025-02-14 02:51:53.804968', '', NULL, '部门管理菜单');
INSERT INTO "public"."sys_menu" VALUES (104, '岗位管理', 1, 5, 'post', 'system/post/index', '', '', 1, 0, 'C', '0', 0, 'system:post:list', 'post', 'admin', '2025-02-14 02:51:53.844733', '', NULL, '岗位管理菜单');
INSERT INTO "public"."sys_menu" VALUES (105, '字典管理', 1, 6, 'dict', 'system/dict/index', '', '', 1, 0, 'C', '1', 0, 'system:dict:list', 'dict', 'admin', '2025-02-14 02:51:53.884929', '', '2026-09-01 03:29:50.59531', '字典管理菜单');
INSERT INTO "public"."sys_menu" VALUES (106, '参数设置', 1, 7, 'config', 'system/config/index', '', '', 1, 0, 'C', '1', 0, 'system:config:list', 'edit', 'admin', '2025-02-14 02:51:53.924742', '', '2026-09-01 03:29:50.59531', '参数设置菜单');
INSERT INTO "public"."sys_menu" VALUES (107, '通知公告', 1, 8, 'notice', 'system/notice/index', '', '', 1, 0, 'C', '0', 0, 'system:notice:list', 'message', 'admin', '2025-02-14 02:51:53.964899', '', NULL, '通知公告菜单');
INSERT INTO "public"."sys_menu" VALUES (108, '日志管理', 1, 9, 'log', '', '', '', 1, 0, 'M', '0', 0, '', 'log', 'admin', '2025-02-14 02:51:54.004842', '', NULL, '日志管理菜单');
INSERT INTO "public"."sys_menu" VALUES (109, '在线用户', 2, 1, 'online', 'monitor/online/index', '', '', 1, 0, 'C', '0', 0, 'monitor:online:list', 'online', 'admin', '2025-02-14 02:51:54.045083', '', NULL, '在线用户菜单');
INSERT INTO "public"."sys_menu" VALUES (110, '任务管理', 2072, 2, 'job', 'monitor/job/index', '', '', 1, 0, 'C', '0', 0, 'monitor:job:list', 'job', 'admin', '2025-02-14 02:51:54.084977', 'admin', '2025-05-27 13:41:22.357679', '定时任务菜单');
INSERT INTO "public"."sys_menu" VALUES (111, '数据监控', 2, 3, 'druid', 'monitor/druid/index', '', '', 1, 0, 'C', '0', 0, 'monitor:druid:list', 'druid', 'admin', '2025-02-14 02:51:54.124893', '', NULL, '数据监控菜单');
INSERT INTO "public"."sys_menu" VALUES (112, '服务监控', 2, 4, 'server', 'monitor/server/index', '', '', 1, 0, 'C', '0', 0, 'monitor:server:list', 'server', 'admin', '2025-02-14 02:51:54.164947', '', NULL, '服务监控菜单');
INSERT INTO "public"."sys_menu" VALUES (113, '缓存监控', 2, 5, 'cache', 'monitor/cache/index', '', '', 1, 0, 'C', '0', 0, 'monitor:cache:list', 'redis', 'admin', '2025-02-14 02:51:54.204911', '', NULL, '缓存监控菜单');
INSERT INTO "public"."sys_menu" VALUES (114, '缓存列表', 2, 6, 'cacheList', 'monitor/cache/list', '', '', 1, 0, 'C', '0', 0, 'monitor:cache:list', 'redis-list', 'admin', '2025-02-14 02:51:54.244865', '', NULL, '缓存列表菜单');
INSERT INTO "public"."sys_menu" VALUES (115, '表单构建', 3, 1, 'build', 'tool/build/index', '', '', 1, 0, 'C', '0', 0, 'tool:build:list', 'build', 'admin', '2025-02-14 02:51:54.284917', '', NULL, '表单构建菜单');
INSERT INTO "public"."sys_menu" VALUES (116, '代码生成', 3, 2, 'gen', 'tool/gen/index', '', '', 1, 0, 'C', '0', 0, 'tool:gen:list', 'code', 'admin', '2025-02-14 02:51:54.324914', '', NULL, '代码生成菜单');
INSERT INTO "public"."sys_menu" VALUES (117, '系统接口', 3, 3, 'swagger', 'tool/swagger/index', '', '', 1, 0, 'C', '0', 0, 'tool:swagger:list', 'swagger', 'admin', '2025-02-14 02:51:54.365003', '', NULL, '系统接口菜单');
INSERT INTO "public"."sys_menu" VALUES (500, '操作日志', 108, 1, 'operlog', 'monitor/operlog/index', '', '', 1, 0, 'C', '0', 0, 'monitor:operlog:list', 'form', 'admin', '2025-02-14 02:51:54.404905', 'admin', '2026-09-01 03:29:50.59531', '操作日志菜单');
INSERT INTO "public"."sys_menu" VALUES (501, '登录日志', 108, 2, 'logininfor', 'monitor/logininfor/index', '', '', 1, 0, 'C', '0', 0, 'monitor:logininfor:list', 'logininfor', 'admin', '2025-02-14 02:51:54.444661', '', NULL, '登录日志菜单');
INSERT INTO "public"."sys_menu" VALUES (1000, '用户查询', 100, 1, '', '', '', '', 1, 0, 'F', '0', 0, 'system:user:query', '#', 'admin', '2025-02-14 02:51:54.485146', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1001, '用户新增', 100, 2, '', '', '', '', 1, 0, 'F', '0', 0, 'system:user:add', '#', 'admin', '2025-02-14 02:51:54.524926', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1002, '用户修改', 100, 3, '', '', '', '', 1, 0, 'F', '0', 0, 'system:user:edit', '#', 'admin', '2025-02-14 02:51:54.564866', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1003, '用户删除', 100, 4, '', '', '', '', 1, 0, 'F', '0', 0, 'system:user:remove', '#', 'admin', '2025-02-14 02:51:54.604834', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1004, '用户导出', 100, 5, '', '', '', '', 1, 0, 'F', '0', 0, 'system:user:export', '#', 'admin', '2025-02-14 02:51:54.645563', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1005, '用户导入', 100, 6, '', '', '', '', 1, 0, 'F', '0', 0, 'system:user:import', '#', 'admin', '2025-02-14 02:51:54.684938', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1006, '重置密码', 100, 7, '', '', '', '', 1, 0, 'F', '0', 0, 'system:user:resetPwd', '#', 'admin', '2025-02-14 02:51:54.724966', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1007, '角色查询', 101, 1, '', '', '', '', 1, 0, 'F', '0', 0, 'system:role:query', '#', 'admin', '2025-02-14 02:51:54.744818', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1008, '角色新增', 101, 2, '', '', '', '', 1, 0, 'F', '0', 0, 'system:role:add', '#', 'admin', '2025-02-14 02:51:54.764731', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1009, '角色修改', 101, 3, '', '', '', '', 1, 0, 'F', '0', 0, 'system:role:edit', '#', 'admin', '2025-02-14 02:51:54.804704', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1010, '角色删除', 101, 4, '', '', '', '', 1, 0, 'F', '0', 0, 'system:role:remove', '#', 'admin', '2025-02-14 02:51:54.824673', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1011, '角色导出', 101, 5, '', '', '', '', 1, 0, 'F', '0', 0, 'system:role:export', '#', 'admin', '2025-02-14 02:51:54.865002', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1012, '菜单查询', 102, 1, '', '', '', '', 1, 0, 'F', '0', 0, 'system:menu:query', '#', 'admin', '2025-02-14 02:51:54.904626', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1013, '菜单新增', 102, 2, '', '', '', '', 1, 0, 'F', '0', 0, 'system:menu:add', '#', 'admin', '2025-02-14 02:51:54.944896', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1014, '菜单修改', 102, 3, '', '', '', '', 1, 0, 'F', '0', 0, 'system:menu:edit', '#', 'admin', '2025-02-14 02:51:54.984865', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1015, '菜单删除', 102, 4, '', '', '', '', 1, 0, 'F', '0', 0, 'system:menu:remove', '#', 'admin', '2025-02-14 02:51:55.024884', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1016, '部门查询', 103, 1, '', '', '', '', 1, 0, 'F', '0', 0, 'system:dept:query', '#', 'admin', '2025-02-14 02:51:55.064788', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1017, '部门新增', 103, 2, '', '', '', '', 1, 0, 'F', '0', 0, 'system:dept:add', '#', 'admin', '2025-02-14 02:51:55.104913', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1018, '部门修改', 103, 3, '', '', '', '', 1, 0, 'F', '0', 0, 'system:dept:edit', '#', 'admin', '2025-02-14 02:51:55.146693', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1019, '部门删除', 103, 4, '', '', '', '', 1, 0, 'F', '0', 0, 'system:dept:remove', '#', 'admin', '2025-02-14 02:51:55.184842', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1020, '岗位查询', 104, 1, '', '', '', '', 1, 0, 'F', '0', 0, 'system:post:query', '#', 'admin', '2025-02-14 02:51:55.224649', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1021, '岗位新增', 104, 2, '', '', '', '', 1, 0, 'F', '0', 0, 'system:post:add', '#', 'admin', '2025-02-14 02:51:55.264918', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1022, '岗位修改', 104, 3, '', '', '', '', 1, 0, 'F', '0', 0, 'system:post:edit', '#', 'admin', '2025-02-14 02:51:55.30683', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1023, '岗位删除', 104, 4, '', '', '', '', 1, 0, 'F', '0', 0, 'system:post:remove', '#', 'admin', '2025-02-14 02:51:55.344995', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1024, '岗位导出', 104, 5, '', '', '', '', 1, 0, 'F', '0', 0, 'system:post:export', '#', 'admin', '2025-02-14 02:51:55.38491', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1025, '字典查询', 105, 1, '#', '', '', '', 1, 0, 'F', '0', 0, 'system:dict:query', '#', 'admin', '2025-02-14 02:51:55.424858', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1026, '字典新增', 105, 2, '#', '', '', '', 1, 0, 'F', '0', 0, 'system:dict:add', '#', 'admin', '2025-02-14 02:51:55.464848', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1027, '字典修改', 105, 3, '#', '', '', '', 1, 0, 'F', '0', 0, 'system:dict:edit', '#', 'admin', '2025-02-14 02:51:55.504884', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1028, '字典删除', 105, 4, '#', '', '', '', 1, 0, 'F', '0', 0, 'system:dict:remove', '#', 'admin', '2025-02-14 02:51:55.544838', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1029, '字典导出', 105, 5, '#', '', '', '', 1, 0, 'F', '0', 0, 'system:dict:export', '#', 'admin', '2025-02-14 02:51:55.584884', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1030, '参数查询', 106, 1, '#', '', '', '', 1, 0, 'F', '0', 0, 'system:config:query', '#', 'admin', '2025-02-14 02:51:55.624728', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1031, '参数新增', 106, 2, '#', '', '', '', 1, 0, 'F', '0', 0, 'system:config:add', '#', 'admin', '2025-02-14 02:51:55.664801', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1032, '参数修改', 106, 3, '#', '', '', '', 1, 0, 'F', '0', 0, 'system:config:edit', '#', 'admin', '2025-02-14 02:51:55.704846', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1033, '参数删除', 106, 4, '#', '', '', '', 1, 0, 'F', '0', 0, 'system:config:remove', '#', 'admin', '2025-02-14 02:51:55.744877', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1034, '参数导出', 106, 5, '#', '', '', '', 1, 0, 'F', '0', 0, 'system:config:export', '#', 'admin', '2025-02-14 02:51:55.784832', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1035, '公告查询', 107, 1, '#', '', '', '', 1, 0, 'F', '0', 0, 'system:notice:query', '#', 'admin', '2025-02-14 02:51:55.824863', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1036, '公告新增', 107, 2, '#', '', '', '', 1, 0, 'F', '0', 0, 'system:notice:add', '#', 'admin', '2025-02-14 02:51:55.864648', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1037, '公告修改', 107, 3, '#', '', '', '', 1, 0, 'F', '0', 0, 'system:notice:edit', '#', 'admin', '2025-02-14 02:51:55.904953', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1038, '公告删除', 107, 4, '#', '', '', '', 1, 0, 'F', '0', 0, 'system:notice:remove', '#', 'admin', '2025-02-14 02:51:55.944873', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1039, '操作查询', 500, 1, '#', '', '', '', 1, 0, 'F', '0', 0, 'monitor:operlog:query', '#', 'admin', '2025-02-14 02:51:55.984883', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1040, '操作删除', 500, 2, '#', '', '', '', 1, 0, 'F', '0', 0, 'monitor:operlog:remove', '#', 'admin', '2025-02-14 02:51:56.024872', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1041, '日志导出', 500, 3, '#', '', '', '', 1, 0, 'F', '0', 0, 'monitor:operlog:export', '#', 'admin', '2025-02-14 02:51:56.064878', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1042, '登录查询', 501, 1, '#', '', '', '', 1, 0, 'F', '0', 0, 'monitor:logininfor:query', '#', 'admin', '2025-02-14 02:51:56.104939', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1043, '登录删除', 501, 2, '#', '', '', '', 1, 0, 'F', '0', 0, 'monitor:logininfor:remove', '#', 'admin', '2025-02-14 02:51:56.144879', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1044, '日志导出', 501, 3, '#', '', '', '', 1, 0, 'F', '0', 0, 'monitor:logininfor:export', '#', 'admin', '2025-02-14 02:51:56.184868', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1045, '账户解锁', 501, 4, '#', '', '', '', 1, 0, 'F', '0', 0, 'monitor:logininfor:unlock', '#', 'admin', '2025-02-14 02:51:56.224894', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1046, '在线查询', 109, 1, '#', '', '', '', 1, 0, 'F', '0', 0, 'monitor:online:query', '#', 'admin', '2025-02-14 02:51:56.264886', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1047, '批量强退', 109, 2, '#', '', '', '', 1, 0, 'F', '0', 0, 'monitor:online:batchLogout', '#', 'admin', '2025-02-14 02:51:56.304858', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1048, '单条强退', 109, 3, '#', '', '', '', 1, 0, 'F', '0', 0, 'monitor:online:forceLogout', '#', 'admin', '2025-02-14 02:51:56.344666', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1049, '任务查询', 110, 1, '#', '', '', '', 1, 0, 'F', '0', 0, 'monitor:job:query', '#', 'admin', '2025-02-14 02:51:56.38487', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1050, '任务新增', 110, 2, '#', '', '', '', 1, 0, 'F', '0', 0, 'monitor:job:add', '#', 'admin', '2025-02-14 02:51:56.424837', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1051, '任务修改', 110, 3, '#', '', '', '', 1, 0, 'F', '0', 0, 'monitor:job:edit', '#', 'admin', '2025-02-14 02:51:56.464885', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1052, '任务删除', 110, 4, '#', '', '', '', 1, 0, 'F', '0', 0, 'monitor:job:remove', '#', 'admin', '2025-02-14 02:51:56.504945', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1053, '状态修改', 110, 5, '#', '', '', '', 1, 0, 'F', '0', 0, 'monitor:job:changeStatus', '#', 'admin', '2025-02-14 02:51:56.544612', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1054, '任务导出', 110, 6, '#', '', '', '', 1, 0, 'F', '0', 0, 'monitor:job:export', '#', 'admin', '2025-02-14 02:51:56.584876', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1055, '生成查询', 116, 1, '#', '', '', '', 1, 0, 'F', '0', 0, 'tool:gen:query', '#', 'admin', '2025-02-14 02:51:56.627857', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1056, '生成修改', 116, 2, '#', '', '', '', 1, 0, 'F', '0', 0, 'tool:gen:edit', '#', 'admin', '2025-02-14 02:51:56.664794', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1057, '生成删除', 116, 3, '#', '', '', '', 1, 0, 'F', '0', 0, 'tool:gen:remove', '#', 'admin', '2025-02-14 02:51:56.704888', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1058, '导入代码', 116, 4, '#', '', '', '', 1, 0, 'F', '0', 0, 'tool:gen:import', '#', 'admin', '2025-02-14 02:51:56.744963', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1059, '预览代码', 116, 5, '#', '', '', '', 1, 0, 'F', '0', 0, 'tool:gen:preview', '#', 'admin', '2025-02-14 02:51:56.785135', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1060, '生成代码', 116, 6, '#', '', '', '', 1, 0, 'F', '0', 0, 'tool:gen:code', '#', 'admin', '2025-02-14 02:51:56.824824', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1061, '数据管理', 0, 95, 'data', NULL, NULL, '', 1, 0, 'M', '1', 0, NULL, 'list', 'admin', '2025-02-14 11:43:24.468634', 'Admin7s9k2G5', '2026-09-01 14:34:42.80695', NULL);
INSERT INTO "public"."sys_menu" VALUES (1062, '设备管理', 0, 94, 'device', NULL, NULL, '', 1, 0, 'M', '1', 0, NULL, 'international', 'admin', '2025-02-14 13:34:22.73074', 'Admin7s9k2G5', '2026-09-01 14:30:39.830622', NULL);
INSERT INTO "public"."sys_menu" VALUES (1063, '设备管理', 1062, 1, 'staInfo', 'station/staInfo/index', NULL, '', 1, 0, 'C', '0', 1, 'station:staInfo:list', '#', 'admin', '2025-02-14 05:44:24.255505', '', NULL, '站点管理菜单');
INSERT INTO "public"."sys_menu" VALUES (1064, '设备参数管理', 1062, 1, 'paraInfo', 'station/paraInfo/index', NULL, '', 1, 0, 'C', '0', 1, 'station:paraInfo:list', '#', 'admin', '2025-02-14 07:53:54.23964', '', NULL, '设备参数管理菜单');
INSERT INTO "public"."sys_menu" VALUES (1066, '数据查询', 1061, 1, 'data', 'station/data/index', NULL, '', 1, 0, 'C', '1', 1, 'station:data:list', 'cascader', 'admin', '2025-02-18 14:40:09.07481', 'admin', '2025-03-07 14:42:44.712388', NULL);
INSERT INTO "public"."sys_menu" VALUES (1069, '数据导入导出', 1061, 5, 'task', 'station/tasks/index', NULL, '', 1, 0, 'C', '0', 1, 'task:tasks:list', 'clipboard', 'admin', '2025-02-24 16:03:36.196166', 'admin', '2025-03-05 14:20:17.375332', NULL);
INSERT INTO "public"."sys_menu" VALUES (1070, '任务查询', 1069, 1, '#', '', NULL, '', 1, 0, 'F', '0', 0, 'task:tasks:query', '#', 'admin', '2025-03-10 09:32:01.776105', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1071, '任务新增', 1069, 2, '#', '', NULL, '', 1, 0, 'F', '0', 0, 'task:tasks:add', '#', 'admin', '2025-03-10 09:32:01.808538', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1072, '任务修改', 1069, 3, '#', '', NULL, '', 1, 0, 'F', '0', 0, 'task:tasks:edit', '#', 'admin', '2025-03-10 09:32:01.839387', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1073, '任务删除', 1069, 4, '#', '', NULL, '', 1, 0, 'F', '0', 0, 'task:tasks:remove', '#', 'admin', '2025-03-10 09:32:01.858534', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1074, '任务导出', 1069, 5, '#', '', NULL, '', 1, 0, 'F', '0', 0, 'task:tasks:export', '#', 'admin', '2025-03-10 09:32:01.88911', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1075, '站点查询', 1063, 1, '#', '', NULL, '', 1, 0, 'F', '0', 0, 'station:staInfo:query', '#', 'admin', '2025-03-10 09:32:01.908674', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1076, '站点新增', 1063, 2, '#', '', NULL, '', 1, 0, 'F', '0', 0, 'station:staInfo:add', '#', 'admin', '2025-03-10 09:32:01.928123', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1077, '站点修改', 1063, 3, '#', '', NULL, '', 1, 0, 'F', '0', 0, 'station:staInfo:edit', '#', 'admin', '2025-03-10 09:32:01.959117', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1078, '站点删除', 1063, 4, '#', '', NULL, '', 1, 0, 'F', '0', 0, 'station:staInfo:remove', '#', 'admin', '2025-03-10 09:32:01.989084', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1079, '站点导出', 1063, 5, '#', '', NULL, '', 1, 0, 'F', '0', 0, 'station:staInfo:export', '#', 'admin', '2025-03-10 09:32:02.008488', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1080, '设备参数查询', 1064, 1, '#', '', NULL, '', 1, 0, 'F', '0', 0, 'station:paraInfo:query', '#', 'admin', '2025-03-10 09:32:02.02963', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1081, '设备参数新增', 1064, 2, '#', '', NULL, '', 1, 0, 'F', '0', 0, 'station:paraInfo:add', '#', 'admin', '2025-03-10 09:32:02.052896', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1082, '设备参数修改', 1064, 3, '#', '', NULL, '', 1, 0, 'F', '0', 0, 'station:paraInfo:edit', '#', 'admin', '2025-03-10 09:32:02.070851', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1083, '设备参数删除', 1064, 4, '#', '', NULL, '', 1, 0, 'F', '0', 0, 'station:paraInfo:remove', '#', 'admin', '2025-03-10 09:32:02.089934', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1084, '设备参数导出', 1064, 5, '#', '', NULL, '', 1, 0, 'F', '0', 0, 'station:paraInfo:export', '#', 'admin', '2025-03-10 09:32:02.109927', '', NULL, '');
INSERT INTO "public"."sys_menu" VALUES (1092, '查询', 2159, 1, '#', '', NULL, '', 1, 0, 'F', '0', 0, 'station:data:query', '#', 'admin', '2025-03-10 17:06:59.848621', 'ecat-sync', '2026-09-01 04:14:57.917685', 'ecat-sync:integration-env-data-manager/data-manager/hisdata:station:data:query');
INSERT INTO "public"."sys_menu" VALUES (1093, '新增', 2159, 2, '#', '', NULL, '', 1, 0, 'F', '0', 0, 'station:data:add', '#', 'admin', '2025-03-10 17:06:59.869611', 'ecat-sync', '2026-09-01 04:14:57.917685', 'ecat-sync:integration-env-data-manager/data-manager/hisdata:station:data:add');
INSERT INTO "public"."sys_menu" VALUES (1094, '修改', 2159, 3, '#', '', NULL, '', 1, 0, 'F', '0', 0, 'station:data:edit', '#', 'admin', '2025-03-10 17:06:59.898378', 'ecat-sync', '2026-09-01 04:14:57.917685', 'ecat-sync:integration-env-data-manager/data-manager/hisdata:station:data:edit');
INSERT INTO "public"."sys_menu" VALUES (1095, '删除', 2159, 4, '#', '', NULL, '', 1, 0, 'F', '0', 0, 'station:data:remove', '#', 'admin', '2025-03-10 17:06:59.919112', 'ecat-sync', '2026-09-01 04:14:57.917685', 'ecat-sync:integration-env-data-manager/data-manager/hisdata:station:data:remove');
INSERT INTO "public"."sys_menu" VALUES (1096, '导出', 2159, 5, '#', '', NULL, '', 1, 0, 'F', '0', 0, 'station:data:export', '#', 'admin', '2025-03-10 17:06:59.948616', 'ecat-sync', '2026-09-01 04:14:57.917685', 'ecat-sync:integration-env-data-manager/data-manager/hisdata:station:data:export');
INSERT INTO "public"."sys_menu" VALUES (2031, '物资管理', 0, 15, 'ecat-material-manager', NULL, NULL, '', 1, 0, 'M', '0', 0, '', 'dict', 'ecat-sync', '2026-09-01 00:01:05.575421', 'Admin7s9k2G5', '2026-09-01 14:29:19.798344', 'ecat-sync:integration-env-material-manager/material-manager/index');
INSERT INTO "public"."sys_menu" VALUES (2032, '物资管理', 2031, 0, 'material_cards', NULL, NULL, '', 1, 0, 'C', '0', 0, 'material:manager:list', 'post', 'ecat-sync', '2026-09-01 00:01:05.575421', NULL, '2026-09-01 04:15:00.975743', 'ecat-sync:integration-env-material-manager/material-manager/material_management_cards');
INSERT INTO "public"."sys_menu" VALUES (2035, '修改', 2033, 0, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'material:manager:edit', '#', 'ecat-sync', '2026-09-01 00:01:05.575421', 'ecat-sync', '2026-09-01 04:15:00.975743', 'ecat-sync:integration-env-material-manager/material-manager/material_management:material:manager:edit');
INSERT INTO "public"."sys_menu" VALUES (2033, '物资信息管理', 2031, 1, 'material_manager', NULL, NULL, '', 1, 0, 'C', '0', 0, 'material:manager:list', 'post', 'ecat-sync', '2026-09-01 00:01:05.575421', NULL, '2026-09-01 04:15:00.975743', 'ecat-sync:integration-env-material-manager/material-manager/material_management');
INSERT INTO "public"."sys_menu" VALUES (2036, '查询', 2033, 0, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'material:manager:query', '#', 'ecat-sync', '2026-09-01 00:01:05.575421', NULL, '2026-09-01 04:15:00.975743', 'ecat-sync:integration-env-material-manager/material-manager/material_management:material:manager:query');
INSERT INTO "public"."sys_menu" VALUES (2037, '新增', 2033, 1, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'material:manager:add', '#', 'ecat-sync', '2026-09-01 00:01:05.575421', NULL, '2026-09-01 04:15:00.975743', 'ecat-sync:integration-env-material-manager/material-manager/material_management:material:manager:add');
INSERT INTO "public"."sys_menu" VALUES (2038, '删除', 2033, 3, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'material:manager:remove', '#', 'ecat-sync', '2026-09-01 00:01:05.575421', NULL, '2026-09-01 04:15:00.975743', 'ecat-sync:integration-env-material-manager/material-manager/material_management:material:manager:remove');
INSERT INTO "public"."sys_menu" VALUES (2039, '导出', 2033, 4, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'material:manager:export', '#', 'ecat-sync', '2026-09-01 00:01:05.575421', NULL, '2026-09-01 04:15:00.975743', 'ecat-sync:integration-env-material-manager/material-manager/material_management:material:manager:export');
INSERT INTO "public"."sys_menu" VALUES (2034, '物资使用记录', 2031, 2, 'material_records', NULL, NULL, '', 1, 0, 'C', '0', 0, 'material:records:list', 'nested', 'ecat-sync', '2026-09-01 00:01:05.575421', NULL, '2026-09-01 04:15:00.975743', 'ecat-sync:integration-env-material-manager/material-manager/material_records');
INSERT INTO "public"."sys_menu" VALUES (2040, '查询', 2034, 0, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'material:records:query', '#', 'ecat-sync', '2026-09-01 00:01:05.575421', NULL, '2026-09-01 04:15:00.975743', 'ecat-sync:integration-env-material-manager/material-manager/material_records:material:records:query');
INSERT INTO "public"."sys_menu" VALUES (2041, '新增', 2034, 1, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'material:records:add', '#', 'ecat-sync', '2026-09-01 00:01:05.575421', NULL, '2026-09-01 04:15:00.975743', 'ecat-sync:integration-env-material-manager/material-manager/material_records:material:records:add');
INSERT INTO "public"."sys_menu" VALUES (2042, '修改', 2034, 2, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'material:records:edit', '#', 'ecat-sync', '2026-09-01 00:01:05.575421', NULL, '2026-09-01 04:15:00.975743', 'ecat-sync:integration-env-material-manager/material-manager/material_records:material:records:edit');
INSERT INTO "public"."sys_menu" VALUES (2043, '删除', 2034, 3, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'material:records:remove', '#', 'ecat-sync', '2026-09-01 00:01:05.575421', NULL, '2026-09-01 04:15:00.975743', 'ecat-sync:integration-env-material-manager/material-manager/material_records:material:records:remove');
INSERT INTO "public"."sys_menu" VALUES (2044, '导出', 2034, 4, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'material:records:export', '#', 'ecat-sync', '2026-09-01 00:01:05.575421', NULL, '2026-09-01 04:15:00.975743', 'ecat-sync:integration-env-material-manager/material-manager/material_records:material:records:export');
INSERT INTO "public"."sys_menu" VALUES (2045, '设备管理', 0, 13, 'ecat-device-manager', NULL, NULL, '', 1, 0, 'M', '0', 0, '', 'redis-list', 'ecat-sync', '2026-09-01 02:12:32.978579', 'Admin7s9k2G5', '2026-09-01 14:34:21.67161', 'ecat-sync:integration-env-device-manager/device-manager/index');
INSERT INTO "public"."sys_menu" VALUES (2046, '设备控制', 2045, 0, 'device_control', NULL, NULL, '', 1, 0, 'C', '0', 0, 'device:device_info:list', 'switch', 'ecat-sync', '2026-09-01 02:12:32.978579', NULL, '2026-09-01 04:14:58.3403', 'ecat-sync:integration-env-device-manager/device-manager/device_control');
INSERT INTO "public"."sys_menu" VALUES (2048, '查询设备', 2046, 0, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'device:device_info:query', '#', 'ecat-sync', '2026-09-01 02:12:32.978579', NULL, '2026-09-01 04:14:58.3403', 'ecat-sync:integration-env-device-manager/device-manager/device_control:device:device_info:query');
INSERT INTO "public"."sys_menu" VALUES (2049, '设置列表', 2046, 1, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'device_control_setting:settings:list', '#', 'ecat-sync', '2026-09-01 02:12:32.978579', NULL, '2026-09-01 04:14:58.3403', 'ecat-sync:integration-env-device-manager/device-manager/device_control:device_control_setting:settings:list');
INSERT INTO "public"."sys_menu" VALUES (2050, '新增设置', 2046, 2, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'device_control_setting:settings:add', '#', 'ecat-sync', '2026-09-01 02:12:32.978579', NULL, '2026-09-01 04:14:58.3403', 'ecat-sync:integration-env-device-manager/device-manager/device_control:device_control_setting:settings:add');
INSERT INTO "public"."sys_menu" VALUES (2051, '修改设置', 2046, 3, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'device_control_setting:settings:edit', '#', 'ecat-sync', '2026-09-01 02:12:32.978579', NULL, '2026-09-01 04:14:58.3403', 'ecat-sync:integration-env-device-manager/device-manager/device_control:device_control_setting:settings:edit');
INSERT INTO "public"."sys_menu" VALUES (2052, '删除设置', 2046, 4, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'device_control_setting:settings:remove', '#', 'ecat-sync', '2026-09-01 02:12:32.978579', NULL, '2026-09-01 04:14:58.3403', 'ecat-sync:integration-env-device-manager/device-manager/device_control:device_control_setting:settings:remove');
INSERT INTO "public"."sys_menu" VALUES (2053, '导出设置', 2046, 5, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'device_control_setting:settings:export', '#', 'ecat-sync', '2026-09-01 02:12:32.978579', NULL, '2026-09-01 04:14:58.3403', 'ecat-sync:integration-env-device-manager/device-manager/device_control:device_control_setting:settings:export');
INSERT INTO "public"."sys_menu" VALUES (2047, '设备控制记录', 2045, 1, 'device_setting_records', NULL, NULL, '', 1, 0, 'C', '0', 0, 'device_setting:records:list', 'server', 'ecat-sync', '2026-09-01 02:12:32.978579', NULL, '2026-09-01 04:14:58.3403', 'ecat-sync:integration-env-device-manager/device-manager/device_setting_records');
INSERT INTO "public"."sys_menu" VALUES (2054, '查询', 2047, 0, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'device_setting:records:query', '#', 'ecat-sync', '2026-09-01 02:12:32.978579', NULL, '2026-09-01 04:14:58.3403', 'ecat-sync:integration-env-device-manager/device-manager/device_setting_records:device_setting:records:query');
INSERT INTO "public"."sys_menu" VALUES (2055, '新增', 2047, 1, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'device_setting:records:add', '#', 'ecat-sync', '2026-09-01 02:12:32.978579', NULL, '2026-09-01 04:14:58.3403', 'ecat-sync:integration-env-device-manager/device-manager/device_setting_records:device_setting:records:add');
INSERT INTO "public"."sys_menu" VALUES (2056, '修改', 2047, 2, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'device_setting:records:edit', '#', 'ecat-sync', '2026-09-01 02:12:32.978579', NULL, '2026-09-01 04:14:58.3403', 'ecat-sync:integration-env-device-manager/device-manager/device_setting_records:device_setting:records:edit');
INSERT INTO "public"."sys_menu" VALUES (2057, '删除', 2047, 3, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'device_setting:records:remove', '#', 'ecat-sync', '2026-09-01 02:12:32.978579', NULL, '2026-09-01 04:14:58.3403', 'ecat-sync:integration-env-device-manager/device-manager/device_setting_records:device_setting:records:remove');
INSERT INTO "public"."sys_menu" VALUES (2058, '导出', 2047, 4, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'device_setting:records:export', '#', 'ecat-sync', '2026-09-01 02:12:32.978579', NULL, '2026-09-01 04:14:58.3403', 'ecat-sync:integration-env-device-manager/device-manager/device_setting_records:device_setting:records:export');
INSERT INTO "public"."sys_menu" VALUES (2059, '门禁查询', 0, 19, 'ecat-access-control', NULL, NULL, '', 1, 0, 'M', '0', 0, '', 'row', 'ecat-sync', '2026-09-01 02:12:33.701971', 'Admin7s9k2G5', '2026-09-01 14:29:40.820378', 'ecat-sync:integration-env-access-control/access-control/index');
INSERT INTO "public"."sys_menu" VALUES (2060, '门禁记录', 2059, 0, 'access_control_records', NULL, NULL, '', 1, 0, 'C', '0', 0, 'access_control:records:list', 'logininfor', 'ecat-sync', '2026-09-01 02:12:33.701971', NULL, '2026-09-01 04:14:58.52236', 'ecat-sync:integration-env-access-control/access-control/access_control_records');
INSERT INTO "public"."sys_menu" VALUES (2061, '查询', 2060, 0, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'access_control:records:query', '#', 'ecat-sync', '2026-09-01 02:12:33.701971', NULL, '2026-09-01 04:14:58.52236', 'ecat-sync:integration-env-access-control/access-control/access_control_records:access_control:records:query');
INSERT INTO "public"."sys_menu" VALUES (2062, '新增', 2060, 1, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'access_control:records:add', '#', 'ecat-sync', '2026-09-01 02:12:33.701971', NULL, '2026-09-01 04:14:58.52236', 'ecat-sync:integration-env-access-control/access-control/access_control_records:access_control:records:add');
INSERT INTO "public"."sys_menu" VALUES (2063, '修改', 2060, 2, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'access_control:records:edit', '#', 'ecat-sync', '2026-09-01 02:12:33.701971', NULL, '2026-09-01 04:14:58.52236', 'ecat-sync:integration-env-access-control/access-control/access_control_records:access_control:records:edit');
INSERT INTO "public"."sys_menu" VALUES (2064, '删除', 2060, 3, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'access_control:records:remove', '#', 'ecat-sync', '2026-09-01 02:12:33.701971', NULL, '2026-09-01 04:14:58.52236', 'ecat-sync:integration-env-access-control/access-control/access_control_records:access_control:records:remove');
INSERT INTO "public"."sys_menu" VALUES (2065, '导出', 2060, 4, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'access_control:records:export', '#', 'ecat-sync', '2026-09-01 02:12:33.701971', NULL, '2026-09-01 04:14:58.52236', 'ecat-sync:integration-env-access-control/access-control/access_control_records:access_control:records:export');
INSERT INTO "public"."sys_menu" VALUES (2066, '数据比对', 0, 22, 'ecat-compare-manager', NULL, NULL, '', 1, 0, 'M', '1', 0, '', 'chart', 'ecat-sync', '2026-09-01 02:12:33.907931', 'Admin7s9k2G5', '2026-09-01 14:33:57.76261', 'ecat-sync:integration-env-compare-manager/compare-manager/index');
INSERT INTO "public"."sys_menu" VALUES (2067, '比对首页', 2066, 0, 'compare_home', NULL, NULL, '', 1, 0, 'C', '0', 0, 'compare:data:list', 'monitor', 'ecat-sync', '2026-09-01 02:12:33.907931', NULL, '2026-09-01 04:14:58.606483', 'ecat-sync:integration-env-compare-manager/compare-manager/compare_home');
INSERT INTO "public"."sys_menu" VALUES (2068, '数据查询', 2066, 1, 'compare_query', NULL, NULL, '', 1, 0, 'C', '0', 0, 'compare:data:list', 'search', 'ecat-sync', '2026-09-01 02:12:33.907931', NULL, '2026-09-01 04:14:58.606483', 'ecat-sync:integration-env-compare-manager/compare-manager/compare_query');
INSERT INTO "public"."sys_menu" VALUES (2069, '导出', 2068, 0, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'compare:data:export', '#', 'ecat-sync', '2026-09-01 02:12:33.907931', NULL, '2026-09-01 04:14:58.606483', 'ecat-sync:integration-env-compare-manager/compare-manager/compare_query:compare:data:export');
INSERT INTO "public"."sys_menu" VALUES (2074, '报警管理', 0, 20, 'ecat-alarm-manager', NULL, NULL, '', 1, 0, 'M', '0', 0, '', 'radio', 'ecat-sync', '2026-09-01 02:12:35.456043', 'Admin7s9k2G5', '2026-09-01 14:32:58.287503', 'ecat-sync:integration-env-alarm-manager/alarm-manager/index');
INSERT INTO "public"."sys_menu" VALUES (2075, '报警记录', 2074, 0, 'alarmdata', NULL, NULL, '', 1, 0, 'C', '0', 0, 'alarm:alarms:list', 'list', 'ecat-sync', '2026-09-01 02:12:35.456043', NULL, '2026-09-01 04:14:59.872003', 'ecat-sync:integration-env-alarm-manager/alarm-manager/alarmdata');
INSERT INTO "public"."sys_menu" VALUES (2077, '查询', 2075, 0, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'alarm:alarms:query', '#', 'ecat-sync', '2026-09-01 02:12:35.456043', NULL, '2026-09-01 04:14:59.872003', 'ecat-sync:integration-env-alarm-manager/alarm-manager/alarmdata:alarm:alarms:query');
INSERT INTO "public"."sys_menu" VALUES (2078, '新增', 2075, 1, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'alarm:alarms:add', '#', 'ecat-sync', '2026-09-01 02:12:35.456043', NULL, '2026-09-01 04:14:59.872003', 'ecat-sync:integration-env-alarm-manager/alarm-manager/alarmdata:alarm:alarms:add');
INSERT INTO "public"."sys_menu" VALUES (2079, '修改', 2075, 2, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'alarm:alarms:edit', '#', 'ecat-sync', '2026-09-01 02:12:35.456043', NULL, '2026-09-01 04:14:59.872003', 'ecat-sync:integration-env-alarm-manager/alarm-manager/alarmdata:alarm:alarms:edit');
INSERT INTO "public"."sys_menu" VALUES (2080, '删除', 2075, 3, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'alarm:alarms:remove', '#', 'ecat-sync', '2026-09-01 02:12:35.456043', NULL, '2026-09-01 04:14:59.872003', 'ecat-sync:integration-env-alarm-manager/alarm-manager/alarmdata:alarm:alarms:remove');
INSERT INTO "public"."sys_menu" VALUES (2081, '导出', 2075, 4, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'alarm:alarms:export', '#', 'ecat-sync', '2026-09-01 02:12:35.456043', NULL, '2026-09-01 04:14:59.872003', 'ecat-sync:integration-env-alarm-manager/alarm-manager/alarmdata:alarm:alarms:export');
INSERT INTO "public"."sys_menu" VALUES (2076, '报警设置', 2074, 1, 'alarm_settings', NULL, NULL, '', 1, 0, 'C', '0', 0, 'alarm_setting:settings:list', 'edit', 'ecat-sync', '2026-09-01 02:12:35.456043', NULL, '2026-09-01 04:14:59.872003', 'ecat-sync:integration-env-alarm-manager/alarm-manager/alarm');
INSERT INTO "public"."sys_menu" VALUES (2082, '查询', 2076, 0, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'alarm_setting:settings:query', '#', 'ecat-sync', '2026-09-01 02:12:35.456043', NULL, '2026-09-01 04:14:59.872003', 'ecat-sync:integration-env-alarm-manager/alarm-manager/alarm:alarm_setting:settings:query');
INSERT INTO "public"."sys_menu" VALUES (2083, '新增', 2076, 1, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'alarm_setting:settings:add', '#', 'ecat-sync', '2026-09-01 02:12:35.456043', NULL, '2026-09-01 04:14:59.872003', 'ecat-sync:integration-env-alarm-manager/alarm-manager/alarm:alarm_setting:settings:add');
INSERT INTO "public"."sys_menu" VALUES (2084, '修改', 2076, 2, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'alarm_setting:settings:edit', '#', 'ecat-sync', '2026-09-01 02:12:35.456043', NULL, '2026-09-01 04:14:59.872003', 'ecat-sync:integration-env-alarm-manager/alarm-manager/alarm:alarm_setting:settings:edit');
INSERT INTO "public"."sys_menu" VALUES (2085, '删除', 2076, 3, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'alarm_setting:settings:remove', '#', 'ecat-sync', '2026-09-01 02:12:35.456043', NULL, '2026-09-01 04:14:59.872003', 'ecat-sync:integration-env-alarm-manager/alarm-manager/alarm:alarm_setting:settings:remove');
INSERT INTO "public"."sys_menu" VALUES (2086, '导出', 2076, 4, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'alarm_setting:settings:export', '#', 'ecat-sync', '2026-09-01 02:12:35.456043', NULL, '2026-09-01 04:14:59.872003', 'ecat-sync:integration-env-alarm-manager/alarm-manager/alarm:alarm_setting:settings:export');
INSERT INTO "public"."sys_menu" VALUES (2072, '任务管理', 0, 16, 'taskjob', NULL, NULL, '', 1, 0, 'M', '0', 0, NULL, 'job', 'admin', '2025-05-27 13:40:08.94874', 'Admin7s9k2G5', '2026-09-01 14:31:18.28145', NULL);
INSERT INTO "public"."sys_menu" VALUES (2073, '日志管理', 0, 96, 'log', NULL, NULL, '', 1, 0, 'M', '1', 0, NULL, 'log', 'admin', '2025-05-28 15:59:23.086081', 'Admin7s9k2G5', '2026-09-01 14:30:56.976039', NULL);
INSERT INTO "public"."sys_menu" VALUES (2093, '空气数据查询', 0, 12, 'ecat-air-data-query', NULL, NULL, '', 1, 0, 'M', '1', 0, '', 'monitor', 'ecat-sync', '2026-09-01 00:01:04.541438', 'Admin7s9k2G5', '2026-09-01 14:33:52.333033', 'ecat-sync:integration-env-air-data-query/air-data-query/index');
INSERT INTO "public"."sys_menu" VALUES (2094, '单参数查询', 2093, 0, 'single_param', NULL, NULL, '', 1, 0, 'C', '0', 0, 'airdataquery:single:list', 'chart', 'ecat-sync', '2026-09-01 00:01:04.541438', NULL, '2026-09-01 04:15:00.158631', 'ecat-sync:integration-env-air-data-query/air-data-query/single_param');
INSERT INTO "public"."sys_menu" VALUES (2095, '多参数查询', 2093, 1, 'multi_param', NULL, NULL, '', 1, 0, 'C', '0', 0, 'airdataquery:multiparam:list', 'table', 'ecat-sync', '2026-09-01 00:01:04.541438', NULL, '2026-09-01 04:15:00.158631', 'ecat-sync:integration-env-air-data-query/air-data-query/multi_param');
INSERT INTO "public"."sys_menu" VALUES (2096, '巡检查询', 0, 18, 'ecat-patrol-manager', NULL, NULL, '', 1, 0, 'M', '0', 0, '', 'eye-open', 'ecat-sync', '2026-09-01 00:01:04.697595', 'Admin7s9k2G5', '2026-09-01 14:32:52.48652', 'ecat-sync:integration-env-patrol-manager/patrol-manager/index');
INSERT INTO "public"."sys_menu" VALUES (2097, '巡检记录', 2096, 0, 'patrol_records', NULL, NULL, '', 1, 0, 'C', '0', 0, 'patrol:records:list', 'log', 'ecat-sync', '2026-09-01 00:01:04.697595', NULL, '2026-09-01 04:15:00.318519', 'ecat-sync:integration-env-patrol-manager/patrol-manager/patrol_records');
INSERT INTO "public"."sys_menu" VALUES (2098, '查询', 2097, 0, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'patrol:records:query', '#', 'ecat-sync', '2026-09-01 00:01:04.697595', NULL, '2026-09-01 04:15:00.318519', 'ecat-sync:integration-env-patrol-manager/patrol-manager/patrol_records:patrol:records:query');
INSERT INTO "public"."sys_menu" VALUES (2099, '新增', 2097, 1, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'patrol:records:add', '#', 'ecat-sync', '2026-09-01 00:01:04.697595', NULL, '2026-09-01 04:15:00.318519', 'ecat-sync:integration-env-patrol-manager/patrol-manager/patrol_records:patrol:records:add');
INSERT INTO "public"."sys_menu" VALUES (2100, '修改', 2097, 2, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'patrol:records:edit', '#', 'ecat-sync', '2026-09-01 00:01:04.697595', NULL, '2026-09-01 04:15:00.318519', 'ecat-sync:integration-env-patrol-manager/patrol-manager/patrol_records:patrol:records:edit');
INSERT INTO "public"."sys_menu" VALUES (2101, '删除', 2097, 3, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'patrol:records:remove', '#', 'ecat-sync', '2026-09-01 00:01:04.697595', NULL, '2026-09-01 04:15:00.318519', 'ecat-sync:integration-env-patrol-manager/patrol-manager/patrol_records:patrol:records:remove');
INSERT INTO "public"."sys_menu" VALUES (2102, '导出', 2097, 4, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'patrol:records:export', '#', 'ecat-sync', '2026-09-01 00:01:04.697595', NULL, '2026-09-01 04:15:00.318519', 'ecat-sync:integration-env-patrol-manager/patrol-manager/patrol_records:patrol:records:export');
INSERT INTO "public"."sys_menu" VALUES (2103, '巡检数据', 2097, 5, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'patrol:detail:data', '#', 'ecat-sync', '2026-09-01 00:01:04.697595', NULL, '2026-09-01 04:15:00.318519', 'ecat-sync:integration-env-patrol-manager/patrol-manager/patrol_records:patrol:detail:data');
INSERT INTO "public"."sys_menu" VALUES (2104, '巡检报警', 2097, 6, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'patrol:detail:alarm', '#', 'ecat-sync', '2026-09-01 00:01:04.697595', NULL, '2026-09-01 04:15:00.318519', 'ecat-sync:integration-env-patrol-manager/patrol-manager/patrol_records:patrol:detail:alarm');
INSERT INTO "public"."sys_menu" VALUES (2105, '巡检报告', 2096, 1, 'patrol_report', NULL, NULL, '', 1, 0, 'C', '0', 0, 'patrol:report:form', 'pdf', 'ecat-sync', '2026-09-01 00:01:04.697595', NULL, '2026-09-01 04:15:00.318519', 'ecat-sync:integration-env-patrol-manager/patrol-manager/patrol_report');
INSERT INTO "public"."sys_menu" VALUES (2106, '维护管理', 0, 14, 'ecat-maintenance-manager', NULL, NULL, '', 1, 0, 'M', '0', 0, '', 'skill', 'ecat-sync', '2026-09-01 00:01:04.850032', 'Admin7s9k2G5', '2026-09-01 14:28:06.398257', 'ecat-sync:integration-env-maintenance-manager/maintenance-manager/index');
INSERT INTO "public"."sys_menu" VALUES (2107, '维护设置', 2106, 0, 'maintenance_settings', NULL, NULL, '', 1, 0, 'C', '0', 0, 'maintenance:setting:query', 'education', 'ecat-sync', '2026-09-01 00:01:04.850032', NULL, '2026-09-01 04:15:00.462828', 'ecat-sync:integration-env-maintenance-manager/maintenance-manager/maintenance_settings');
INSERT INTO "public"."sys_menu" VALUES (2108, '修改设置', 2107, 0, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'maintenance:setting:change', '#', 'ecat-sync', '2026-09-01 00:01:04.850032', NULL, '2026-09-01 04:15:00.462828', 'ecat-sync:integration-env-maintenance-manager/maintenance-manager/maintenance_settings:maintenance:setting:change');
INSERT INTO "public"."sys_menu" VALUES (2109, '维护记录', 2106, 1, 'maintenance_records', NULL, NULL, '', 1, 0, 'C', '0', 0, 'maintenance:records:list', 'list', 'ecat-sync', '2026-09-01 00:01:04.850032', NULL, '2026-09-01 04:15:00.462828', 'ecat-sync:integration-env-maintenance-manager/maintenance-manager/maintenance_records');
INSERT INTO "public"."sys_menu" VALUES (2110, '查询', 2109, 0, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'maintenance:records:query', '#', 'ecat-sync', '2026-09-01 00:01:04.850032', NULL, '2026-09-01 04:15:00.462828', 'ecat-sync:integration-env-maintenance-manager/maintenance-manager/maintenance_records:maintenance:records:query');
INSERT INTO "public"."sys_menu" VALUES (2111, '新增', 2109, 1, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'maintenance:records:add', '#', 'ecat-sync', '2026-09-01 00:01:04.850032', NULL, '2026-09-01 04:15:00.462828', 'ecat-sync:integration-env-maintenance-manager/maintenance-manager/maintenance_records:maintenance:records:add');
INSERT INTO "public"."sys_menu" VALUES (2112, '修改', 2109, 2, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'maintenance:records:edit', '#', 'ecat-sync', '2026-09-01 00:01:04.850032', NULL, '2026-09-01 04:15:00.462828', 'ecat-sync:integration-env-maintenance-manager/maintenance-manager/maintenance_records:maintenance:records:edit');
INSERT INTO "public"."sys_menu" VALUES (2113, '删除', 2109, 3, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'maintenance:records:remove', '#', 'ecat-sync', '2026-09-01 00:01:04.850032', NULL, '2026-09-01 04:15:00.462828', 'ecat-sync:integration-env-maintenance-manager/maintenance-manager/maintenance_records:maintenance:records:remove');
INSERT INTO "public"."sys_menu" VALUES (2114, '导出', 2109, 4, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'maintenance:records:export', '#', 'ecat-sync', '2026-09-01 00:01:04.850032', NULL, '2026-09-01 04:15:00.462828', 'ecat-sync:integration-env-maintenance-manager/maintenance-manager/maintenance_records:maintenance:records:export');
INSERT INTO "public"."sys_menu" VALUES (2115, '全域智控视图', 0, 21, 'ecat-diagram-manager', NULL, NULL, '', 1, 0, 'M', '1', 0, '', 'component', 'ecat-sync', '2026-09-01 00:01:05.08798', 'Admin7s9k2G5', '2026-09-01 14:29:30.728963', 'ecat-sync:integration-env-diagram/diagram-manager/index');
INSERT INTO "public"."sys_menu" VALUES (2116, '全域智控视图', 2115, 0, 'diagram_manager', NULL, NULL, '', 1, 1, 'C', '0', 0, 'diagram:device:list', 'education', 'ecat-sync', '2026-09-01 00:01:05.08798', NULL, '2026-09-01 04:15:00.660761', 'ecat-sync:integration-env-diagram/diagram-manager/diagram_manager');
INSERT INTO "public"."sys_menu" VALUES (2117, '写值', 2116, 0, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'diagram:device:edit', '#', 'ecat-sync', '2026-09-01 00:01:05.08798', NULL, '2026-09-01 04:15:00.660761', 'ecat-sync:integration-env-diagram/diagram-manager/diagram_manager:diagram:device:edit');
INSERT INTO "public"."sys_menu" VALUES (2118, '智控视图编辑', 2115, 1, 'diagram_edit', NULL, NULL, '', 1, 1, 'C', '1', 0, 'diagram:device:edit', 'list', 'ecat-sync', '2026-09-01 00:01:05.08798', NULL, '2026-09-01 04:15:00.660761', 'ecat-sync:integration-env-diagram/diagram-manager/diagram_edit');
INSERT INTO "public"."sys_menu" VALUES (2119, '智控视图预览', 2115, 2, 'diagram_view', NULL, NULL, '', 1, 1, 'C', '1', 0, 'diagram:device:list', 'view', 'ecat-sync', '2026-09-01 00:01:05.08798', NULL, '2026-09-01 04:15:00.660761', 'ecat-sync:integration-env-diagram/diagram-manager/diagram_view');
INSERT INTO "public"."sys_menu" VALUES (2120, '智控视图预览(嵌入式)', 2115, 1, 'diagram_view_full', NULL, NULL, '', 1, 1, 'C', '1', 0, 'diagram:device:list', 'view', 'ecat-sync', '2026-09-01 00:01:05.08798', NULL, '2026-09-01 04:15:00.660761', 'ecat-sync:integration-env-diagram/diagram-manager/diagram_view_full');
INSERT INTO "public"."sys_menu" VALUES (2121, '质控查询', 0, 17, 'ecat-quality-control-manager', NULL, NULL, '', 1, 0, 'M', '0', 0, '', 'education', 'ecat-sync', '2026-09-01 00:01:05.340916', 'Admin7s9k2G5', '2026-09-01 14:32:34.017878', 'ecat-sync:integration-env-quality-control-manager/quality-control-manager/index');
INSERT INTO "public"."sys_menu" VALUES (2122, '质控记录', 2121, 0, 'quality_control_records', NULL, NULL, '', 1, 0, 'C', '1', 0, 'quality_control:records:list', 'excel', 'ecat-sync', '2026-09-01 00:01:05.340916', NULL, '2026-09-01 04:15:00.813855', 'ecat-sync:integration-env-quality-control-manager/quality-control-manager/quality_control_records');
INSERT INTO "public"."sys_menu" VALUES (2123, '查询', 2122, 0, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'quality_control:records:query', '#', 'ecat-sync', '2026-09-01 00:01:05.340916', NULL, '2026-09-01 04:15:00.813855', 'ecat-sync:integration-env-quality-control-manager/quality-control-manager/quality_control_records:quality_control:records:query');
INSERT INTO "public"."sys_menu" VALUES (2124, '保存钢瓶气', 2137, 1, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'quality_control:records:add', '#', 'ecat-sync', '2026-09-01 00:01:05.340916', 'ecat-sync', '2026-09-01 04:15:00.813855', 'ecat-sync:integration-env-quality-control-manager/quality-control-manager/gas_setting:quality_control:records:add');
INSERT INTO "public"."sys_menu" VALUES (2125, '修改', 2122, 2, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'quality_control:records:edit', '#', 'ecat-sync', '2026-09-01 00:01:05.340916', NULL, '2026-09-01 04:15:00.813855', 'ecat-sync:integration-env-quality-control-manager/quality-control-manager/quality_control_records:quality_control:records:edit');
INSERT INTO "public"."sys_menu" VALUES (2126, '停止', 2122, 3, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'quality_control:records:stop', '#', 'ecat-sync', '2026-09-01 00:01:05.340916', NULL, '2026-09-01 04:15:00.813855', 'ecat-sync:integration-env-quality-control-manager/quality-control-manager/quality_control_records:quality_control:records:stop');
INSERT INTO "public"."sys_menu" VALUES (2127, '删除', 2122, 4, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'quality_control:records:remove', '#', 'ecat-sync', '2026-09-01 00:01:05.340916', NULL, '2026-09-01 04:15:00.813855', 'ecat-sync:integration-env-quality-control-manager/quality-control-manager/quality_control_records:quality_control:records:remove');
INSERT INTO "public"."sys_menu" VALUES (2128, '导出', 2122, 5, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'quality_control:records:export', '#', 'ecat-sync', '2026-09-01 00:01:05.340916', NULL, '2026-09-01 04:15:00.813855', 'ecat-sync:integration-env-quality-control-manager/quality-control-manager/quality_control_records:quality_control:records:export');
INSERT INTO "public"."sys_menu" VALUES (2129, '质控报告', 2121, 1, 'quality_control_report', NULL, NULL, '', 1, 0, 'C', '0', 0, 'quality_control:report:list', 'pdf', 'ecat-sync', '2026-09-01 00:01:05.340916', NULL, '2026-09-01 04:15:00.813855', 'ecat-sync:integration-env-quality-control-manager/quality-control-manager/quality_control_report');
INSERT INTO "public"."sys_menu" VALUES (2130, '查询', 2129, 0, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'quality_control:report:query', '#', 'ecat-sync', '2026-09-01 00:01:05.340916', NULL, '2026-09-01 04:15:00.813855', 'ecat-sync:integration-env-quality-control-manager/quality-control-manager/quality_control_report:quality_control:report:query');
INSERT INTO "public"."sys_menu" VALUES (2131, '新增', 2129, 1, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'quality_control:report:add', '#', 'ecat-sync', '2026-09-01 00:01:05.340916', NULL, '2026-09-01 04:15:00.813855', 'ecat-sync:integration-env-quality-control-manager/quality-control-manager/quality_control_report:quality_control:report:add');
INSERT INTO "public"."sys_menu" VALUES (2132, '修改', 2129, 2, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'quality_control:report:edit', '#', 'ecat-sync', '2026-09-01 00:01:05.340916', NULL, '2026-09-01 04:15:00.813855', 'ecat-sync:integration-env-quality-control-manager/quality-control-manager/quality_control_report:quality_control:report:edit');
INSERT INTO "public"."sys_menu" VALUES (2133, '删除', 2129, 3, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'quality_control:report:remove', '#', 'ecat-sync', '2026-09-01 00:01:05.340916', NULL, '2026-09-01 04:15:00.813855', 'ecat-sync:integration-env-quality-control-manager/quality-control-manager/quality_control_report:quality_control:report:remove');
INSERT INTO "public"."sys_menu" VALUES (2134, '导出', 2129, 4, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'quality_control:report:export', '#', 'ecat-sync', '2026-09-01 00:01:05.340916', NULL, '2026-09-01 04:15:00.813855', 'ecat-sync:integration-env-quality-control-manager/quality-control-manager/quality_control_report:quality_control:report:export');
INSERT INTO "public"."sys_menu" VALUES (2135, '人工核查', 2121, 2, 'quality_control_custom_audit_span_check', NULL, NULL, '', 1, 0, 'C', '0', 0, 'quality_control:custom:audit_span_check', 'example', 'ecat-sync', '2026-09-01 00:01:05.340916', NULL, '2026-09-01 04:15:00.813855', 'ecat-sync:integration-env-quality-control-manager/quality-control-manager/quality_control_custom_audit_span_check');
INSERT INTO "public"."sys_menu" VALUES (2136, '执行空闲检查', 2135, 0, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'quality_control:custom:is_executor_free', '#', 'ecat-sync', '2026-09-01 00:01:05.340916', NULL, '2026-09-01 04:15:00.813855', 'ecat-sync:integration-env-quality-control-manager/quality-control-manager/quality_control_custom_audit_span_check:quality_control:custom:is_executor_free');
INSERT INTO "public"."sys_menu" VALUES (2137, '钢瓶气设置', 2121, 3, 'gas_setting', NULL, NULL, '', 1, 0, 'C', '0', 0, 'quality_control:records:list', 'edit', 'ecat-sync', '2026-09-01 00:01:05.340916', NULL, '2026-09-01 04:15:00.813855', 'ecat-sync:integration-env-quality-control-manager/quality-control-manager/gas_setting');
INSERT INTO "public"."sys_menu" VALUES (2152, '数据查询', 0, 11, 'ecat-data-manager', NULL, NULL, '', 1, 0, 'M', '0', 0, '', 'monitor', 'ecat-sync', '2026-09-01 02:12:32.263221', 'Admin7s9k2G5', '2026-09-01 14:34:04.075998', 'ecat-sync:integration-env-data-manager/data-manager/index');
INSERT INTO "public"."sys_menu" VALUES (2153, '原始数据', 2152, 0, 'realdata', NULL, NULL, '', 1, 0, 'C', '0', 0, 'realdata:realdata:list', 'online', 'ecat-sync', '2026-09-01 02:12:32.263221', NULL, '2026-09-01 04:14:57.917685', 'ecat-sync:integration-env-data-manager/data-manager/realdata');
INSERT INTO "public"."sys_menu" VALUES (2154, '查询', 2153, 0, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'realdata:realdata:query', '#', 'ecat-sync', '2026-09-01 02:12:32.263221', NULL, '2026-09-01 04:14:57.917685', 'ecat-sync:integration-env-data-manager/data-manager/realdata:realdata:realdata:query');
INSERT INTO "public"."sys_menu" VALUES (2155, '新增', 2153, 1, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'realdata:realdata:add', '#', 'ecat-sync', '2026-09-01 02:12:32.263221', NULL, '2026-09-01 04:14:57.917685', 'ecat-sync:integration-env-data-manager/data-manager/realdata:realdata:realdata:add');
INSERT INTO "public"."sys_menu" VALUES (2156, '修改', 2153, 2, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'realdata:realdata:edit', '#', 'ecat-sync', '2026-09-01 02:12:32.263221', NULL, '2026-09-01 04:14:57.917685', 'ecat-sync:integration-env-data-manager/data-manager/realdata:realdata:realdata:edit');
INSERT INTO "public"."sys_menu" VALUES (2157, '删除', 2153, 3, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'realdata:realdata:remove', '#', 'ecat-sync', '2026-09-01 02:12:32.263221', NULL, '2026-09-01 04:14:57.917685', 'ecat-sync:integration-env-data-manager/data-manager/realdata:realdata:realdata:remove');
INSERT INTO "public"."sys_menu" VALUES (2158, '导出', 2153, 4, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'realdata:realdata:export', '#', 'ecat-sync', '2026-09-01 02:12:32.263221', NULL, '2026-09-01 04:14:57.917685', 'ecat-sync:integration-env-data-manager/data-manager/realdata:realdata:realdata:export');
INSERT INTO "public"."sys_menu" VALUES (2159, '历史数据', 2152, 1, 'hisdata', NULL, NULL, '', 1, 0, 'C', '0', 0, 'station:data:list', 'chart', 'ecat-sync', '2026-09-01 02:12:32.263221', NULL, '2026-09-01 04:14:57.917685', 'ecat-sync:integration-env-data-manager/data-manager/hisdata');
INSERT INTO "public"."sys_menu" VALUES (2160, '趋势对比', 2152, 2, 'multi_param_data', NULL, NULL, '', 1, 0, 'C', '0', 0, 'station:data:list', 'druid', 'ecat-sync', '2026-09-01 02:12:32.263221', NULL, '2026-09-01 04:14:57.917685', 'ecat-sync:integration-env-data-manager/data-manager/multi_param_data');
INSERT INTO "public"."sys_menu" VALUES (2161, '备份还原', 1, 10, 'backup', 'system/backup/index', NULL, 'Backup', 1, 0, 'C', '0', 0, 'system:backup:list', 'zip', 'admin', current_timestamp, '', NULL, '备份还原引导入口（默认仅管理员）');
INSERT INTO "public"."sys_menu" VALUES (2162, '打开守护工具', 2161, 1, NULL, NULL, NULL, '', 1, 0, 'F', '0', 0, 'system:backup:open', '#', 'admin', current_timestamp, '', NULL, '打开守护工具的备份还原页');

CREATE TABLE "public"."sys_notice" (
  "notice_id" int8 NOT NULL DEFAULT nextval('sys_notice_notice_id_seq'::regclass),
  "notice_title" varchar(50) COLLATE "pg_catalog"."default" NOT NULL,
  "notice_type" char(1) COLLATE "pg_catalog"."default" NOT NULL,
  "notice_content" text COLLATE "pg_catalog"."default",
  "status" char(1) COLLATE "pg_catalog"."default",
  "create_by" varchar(64) COLLATE "pg_catalog"."default",
  "create_time" timestamp(6),
  "update_by" varchar(64) COLLATE "pg_catalog"."default",
  "update_time" timestamp(6),
  "remark" varchar(255) COLLATE "pg_catalog"."default"
)
;
COMMENT ON COLUMN "public"."sys_notice"."notice_id" IS '公告ID';
COMMENT ON COLUMN "public"."sys_notice"."notice_title" IS '公告标题';
COMMENT ON COLUMN "public"."sys_notice"."notice_type" IS '公告类型（1通知 2公告）';
COMMENT ON COLUMN "public"."sys_notice"."notice_content" IS '公告内容';
COMMENT ON COLUMN "public"."sys_notice"."status" IS '公告状态（0正常 1关闭）';
COMMENT ON COLUMN "public"."sys_notice"."create_by" IS '创建者';
COMMENT ON COLUMN "public"."sys_notice"."create_time" IS '创建时间';
COMMENT ON COLUMN "public"."sys_notice"."update_by" IS '更新者';
COMMENT ON COLUMN "public"."sys_notice"."update_time" IS '更新时间';
COMMENT ON COLUMN "public"."sys_notice"."remark" IS '备注';
COMMENT ON TABLE "public"."sys_notice" IS '通知公告表';

INSERT INTO "public"."sys_notice" VALUES (2, '维护通知：2018-07-01 Ecat系统凌晨维护', '1', '\xe7bbb4e68aa4e58685e5aeb9', '0', 'admin', '2021-05-26 18:56:31', '', NULL, '管理员');
INSERT INTO "public"."sys_notice" VALUES (1, '温馨提醒：2018-07-01 Ecat新版本发布啦', '2', '\', '0', 'admin', '2021-05-26 18:56:31', 'admin', '2021-05-27 09:08:41.403262', '管理员');

CREATE TABLE "public"."sys_oper_log" (
  "oper_id" int8 NOT NULL DEFAULT nextval('sys_oper_log_oper_id_seq'::regclass),
  "title" varchar(50) COLLATE "pg_catalog"."default",
  "business_type" int4,
  "method" varchar(255) COLLATE "pg_catalog"."default",
  "request_method" varchar(10) COLLATE "pg_catalog"."default",
  "operator_type" int4,
  "oper_name" varchar(50) COLLATE "pg_catalog"."default",
  "dept_name" varchar(50) COLLATE "pg_catalog"."default",
  "oper_url" varchar(255) COLLATE "pg_catalog"."default",
  "oper_ip" varchar(128) COLLATE "pg_catalog"."default",
  "oper_location" varchar(255) COLLATE "pg_catalog"."default",
  "oper_param" varchar(2000) COLLATE "pg_catalog"."default",
  "json_result" varchar(2000) COLLATE "pg_catalog"."default",
  "status" int4,
  "error_msg" varchar(2000) COLLATE "pg_catalog"."default",
  "oper_time" timestamp(6),
  "cost_time" int8 DEFAULT 0
)
;
COMMENT ON COLUMN "public"."sys_oper_log"."oper_id" IS '日志主键';
COMMENT ON COLUMN "public"."sys_oper_log"."title" IS '模块标题';
COMMENT ON COLUMN "public"."sys_oper_log"."business_type" IS '业务类型（0其它 1新增 2修改 3删除）';
COMMENT ON COLUMN "public"."sys_oper_log"."method" IS '方法名称';
COMMENT ON COLUMN "public"."sys_oper_log"."request_method" IS '请求方式';
COMMENT ON COLUMN "public"."sys_oper_log"."operator_type" IS '操作类别（0其它 1后台用户 2手机端用户）';
COMMENT ON COLUMN "public"."sys_oper_log"."oper_name" IS '操作人员';
COMMENT ON COLUMN "public"."sys_oper_log"."dept_name" IS '部门名称';
COMMENT ON COLUMN "public"."sys_oper_log"."oper_url" IS '请求URL';
COMMENT ON COLUMN "public"."sys_oper_log"."oper_ip" IS '主机地址';
COMMENT ON COLUMN "public"."sys_oper_log"."oper_location" IS '操作地点';
COMMENT ON COLUMN "public"."sys_oper_log"."oper_param" IS '请求参数';
COMMENT ON COLUMN "public"."sys_oper_log"."json_result" IS '返回参数';
COMMENT ON COLUMN "public"."sys_oper_log"."status" IS '操作状态（0正常 1异常）';
COMMENT ON COLUMN "public"."sys_oper_log"."error_msg" IS '错误消息';
COMMENT ON COLUMN "public"."sys_oper_log"."oper_time" IS '操作时间';
COMMENT ON TABLE "public"."sys_oper_log" IS '操作日志记录';

INSERT INTO "public"."sys_oper_log" VALUES (3142, '任务管理', 3, 'com.ruoyi.quartz.controller.SysJobController.remove()', 'DELETE', 1, 'admin', '研发部门', '/monitor/job/47,46,45,43,42,41,40,39,38,37', '127.0.0.1', '内网IP', '[47,46,45,43,42,41,40,39,38,37]', '{"msg":"操作成功","code":200}', 0, NULL, '2025-09-18 10:38:06.750137', 529);
INSERT INTO "public"."sys_oper_log" VALUES (3143, '任务管理', 3, 'com.ruoyi.quartz.controller.SysJobController.remove()', 'DELETE', 1, 'admin', '研发部门', '/monitor/job/36,35,34,33,31,30,29,28,27,26', '127.0.0.1', '内网IP', '[36,35,34,33,31,30,29,28,27,26]', '{"msg":"操作成功","code":200}', 0, NULL, '2025-09-18 10:38:10.073191', 479);
INSERT INTO "public"."sys_oper_log" VALUES (3144, '任务管理', 3, 'com.ruoyi.quartz.controller.SysJobController.remove()', 'DELETE', 1, 'admin', '研发部门', '/monitor/job/25,24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6', '127.0.0.1', '内网IP', '[25,24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6]', '{"msg":"操作成功","code":200}', 0, NULL, '2025-09-18 10:38:15.634593', 929);

CREATE TABLE "public"."sys_post" (
  "post_id" int8 NOT NULL DEFAULT nextval('sys_post_post_id_seq'::regclass),
  "post_code" varchar(64) COLLATE "pg_catalog"."default" NOT NULL,
  "post_name" varchar(50) COLLATE "pg_catalog"."default" NOT NULL,
  "post_sort" int4 NOT NULL,
  "status" char(1) COLLATE "pg_catalog"."default" NOT NULL,
  "create_by" varchar(64) COLLATE "pg_catalog"."default",
  "create_time" timestamp(6),
  "update_by" varchar(64) COLLATE "pg_catalog"."default",
  "update_time" timestamp(6),
  "remark" varchar(500) COLLATE "pg_catalog"."default"
)
;
COMMENT ON COLUMN "public"."sys_post"."post_id" IS '岗位ID';
COMMENT ON COLUMN "public"."sys_post"."post_code" IS '岗位编码';
COMMENT ON COLUMN "public"."sys_post"."post_name" IS '岗位名称';
COMMENT ON COLUMN "public"."sys_post"."post_sort" IS '显示顺序';
COMMENT ON COLUMN "public"."sys_post"."status" IS '状态（0正常 1停用）';
COMMENT ON COLUMN "public"."sys_post"."create_by" IS '创建者';
COMMENT ON COLUMN "public"."sys_post"."create_time" IS '创建时间';
COMMENT ON COLUMN "public"."sys_post"."update_by" IS '更新者';
COMMENT ON COLUMN "public"."sys_post"."update_time" IS '更新时间';
COMMENT ON COLUMN "public"."sys_post"."remark" IS '备注';
COMMENT ON TABLE "public"."sys_post" IS '岗位信息表';

INSERT INTO "public"."sys_post" VALUES (2, 'se', '项目经理', 2, '0', 'admin', '2021-05-26 18:56:28', '', NULL, '');
INSERT INTO "public"."sys_post" VALUES (3, 'hr', '人力资源', 3, '0', 'admin', '2021-05-26 18:56:28', '', NULL, '');
INSERT INTO "public"."sys_post" VALUES (4, 'user', '普通员工', 4, '0', 'admin', '2021-05-26 18:56:28', '', NULL, '');
INSERT INTO "public"."sys_post" VALUES (1, 'ceo', '董事长', 1, '0', 'admin', '2021-05-26 18:56:28', 'admin', '2021-05-27 09:07:17.160973', '');

CREATE TABLE "public"."sys_role" (
  "role_id" int8 NOT NULL DEFAULT nextval('sys_role_role_id_seq'::regclass),
  "role_name" varchar(30) COLLATE "pg_catalog"."default" NOT NULL,
  "role_key" varchar(100) COLLATE "pg_catalog"."default" NOT NULL,
  "role_sort" int4 NOT NULL,
  "data_scope" char(1) COLLATE "pg_catalog"."default",
  "menu_check_strictly" bool,
  "dept_check_strictly" bool,
  "status" char(1) COLLATE "pg_catalog"."default" NOT NULL,
  "del_flag" char(1) COLLATE "pg_catalog"."default" DEFAULT 0,
  "create_by" varchar(64) COLLATE "pg_catalog"."default",
  "create_time" timestamp(6),
  "update_by" varchar(64) COLLATE "pg_catalog"."default",
  "update_time" timestamp(6),
  "remark" varchar(500) COLLATE "pg_catalog"."default"
)
;
COMMENT ON COLUMN "public"."sys_role"."role_id" IS '角色ID';
COMMENT ON COLUMN "public"."sys_role"."role_name" IS '角色名称';
COMMENT ON COLUMN "public"."sys_role"."role_key" IS '角色权限字符串';
COMMENT ON COLUMN "public"."sys_role"."role_sort" IS '显示顺序';
COMMENT ON COLUMN "public"."sys_role"."data_scope" IS '数据范围（1：全部数据权限 2：自定数据权限 3：本部门数据权限 4：本部门及以下数据权限）';
COMMENT ON COLUMN "public"."sys_role"."menu_check_strictly" IS '菜单树选择项是否关联显示';
COMMENT ON COLUMN "public"."sys_role"."dept_check_strictly" IS '部门树选择项是否关联显示';
COMMENT ON COLUMN "public"."sys_role"."status" IS '角色状态（0正常 1停用）';
COMMENT ON COLUMN "public"."sys_role"."del_flag" IS '删除标志（0代表存在 2代表删除）';
COMMENT ON COLUMN "public"."sys_role"."create_by" IS '创建者';
COMMENT ON COLUMN "public"."sys_role"."create_time" IS '创建时间';
COMMENT ON COLUMN "public"."sys_role"."update_by" IS '更新者';
COMMENT ON COLUMN "public"."sys_role"."update_time" IS '更新时间';
COMMENT ON COLUMN "public"."sys_role"."remark" IS '备注';
COMMENT ON TABLE "public"."sys_role" IS '角色信息表';

INSERT INTO "public"."sys_role" VALUES (1, '超级管理员', 'admin', 1, '1', 't', 't', '0', '0', 'admin', '2021-05-26 18:56:28', '', NULL, '超级管理员');
INSERT INTO "public"."sys_role" VALUES (2, '普通角色', 'common', 2, '2', 'f', 'f', '0', '0', 'admin', '2021-05-26 18:56:28', 'admin', '2025-03-10 17:12:49.701523', '普通角色');

CREATE TABLE "public"."sys_role_dept" (
  "role_id" int8 NOT NULL,
  "dept_id" int8 NOT NULL
)
;
COMMENT ON COLUMN "public"."sys_role_dept"."role_id" IS '角色ID';
COMMENT ON COLUMN "public"."sys_role_dept"."dept_id" IS '部门ID';
COMMENT ON TABLE "public"."sys_role_dept" IS '角色和部门关联表';

INSERT INTO "public"."sys_role_dept" VALUES (2, 100);
INSERT INTO "public"."sys_role_dept" VALUES (2, 101);
INSERT INTO "public"."sys_role_dept" VALUES (2, 105);

CREATE TABLE "public"."sys_role_menu" (
  "role_id" int8 NOT NULL,
  "menu_id" int8 NOT NULL
)
;
COMMENT ON COLUMN "public"."sys_role_menu"."role_id" IS '角色ID';
COMMENT ON COLUMN "public"."sys_role_menu"."menu_id" IS '菜单ID';
COMMENT ON TABLE "public"."sys_role_menu" IS '角色和菜单关联表';

INSERT INTO "public"."sys_role_menu" VALUES (2, 501);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1042);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1043);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1044);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1045);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2);
INSERT INTO "public"."sys_role_menu" VALUES (2, 109);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1046);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1047);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1048);
INSERT INTO "public"."sys_role_menu" VALUES (2, 110);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1049);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1050);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1062);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1052);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1053);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1054);
INSERT INTO "public"."sys_role_menu" VALUES (2, 111);
INSERT INTO "public"."sys_role_menu" VALUES (2, 112);
INSERT INTO "public"."sys_role_menu" VALUES (2, 113);
INSERT INTO "public"."sys_role_menu" VALUES (2, 114);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1055);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1056);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1057);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1058);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1059);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1060);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1051);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1063);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1075);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1076);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1077);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1078);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1079);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1064);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1080);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1081);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1084);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1061);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1066);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1092);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1093);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1094);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1095);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1096);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1069);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1070);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1071);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1074);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1);
INSERT INTO "public"."sys_role_menu" VALUES (2, 100);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1001);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1002);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1003);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1004);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1005);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1006);
INSERT INTO "public"."sys_role_menu" VALUES (2, 101);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1007);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1008);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1009);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1010);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1011);
INSERT INTO "public"."sys_role_menu" VALUES (2, 102);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1012);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1013);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1014);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1015);
INSERT INTO "public"."sys_role_menu" VALUES (2, 103);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1016);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1017);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1018);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1019);
INSERT INTO "public"."sys_role_menu" VALUES (2, 104);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1020);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1021);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1022);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1023);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1024);
INSERT INTO "public"."sys_role_menu" VALUES (2, 105);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1025);
INSERT INTO "public"."sys_role_menu" VALUES (2, 106);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1030);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1031);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1032);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1033);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1034);
INSERT INTO "public"."sys_role_menu" VALUES (2, 107);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1035);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1036);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1037);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1038);
INSERT INTO "public"."sys_role_menu" VALUES (2, 108);
INSERT INTO "public"."sys_role_menu" VALUES (2, 500);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1039);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1040);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1041);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2031);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2032);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2033);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2034);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2035);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2036);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2037);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2038);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2039);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2040);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2041);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2042);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2043);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2044);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2045);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2046);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2047);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2048);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2049);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2050);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2051);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2052);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2053);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2054);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2055);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2056);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2057);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2058);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2059);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2060);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2061);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2062);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2063);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2064);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2065);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2066);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2067);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2068);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2069);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2074);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2075);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2076);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2077);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2078);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2079);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2080);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2081);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2082);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2083);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2084);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2085);
INSERT INTO "public"."sys_role_menu" VALUES (2, 2086);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1072);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1073);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1082);
INSERT INTO "public"."sys_role_menu" VALUES (2, 1083);
INSERT INTO "public"."sys_role_menu" VALUES (1, 1061);
INSERT INTO "public"."sys_role_menu" VALUES (1, 1062);
INSERT INTO "public"."sys_role_menu" VALUES (1, 1063);
INSERT INTO "public"."sys_role_menu" VALUES (1, 1064);
INSERT INTO "public"."sys_role_menu" VALUES (1, 1066);
INSERT INTO "public"."sys_role_menu" VALUES (1, 1069);
INSERT INTO "public"."sys_role_menu" VALUES (1, 1070);
INSERT INTO "public"."sys_role_menu" VALUES (1, 1071);
INSERT INTO "public"."sys_role_menu" VALUES (1, 1072);
INSERT INTO "public"."sys_role_menu" VALUES (1, 1073);
INSERT INTO "public"."sys_role_menu" VALUES (1, 1074);
INSERT INTO "public"."sys_role_menu" VALUES (1, 1075);
INSERT INTO "public"."sys_role_menu" VALUES (1, 1076);
INSERT INTO "public"."sys_role_menu" VALUES (1, 1077);
INSERT INTO "public"."sys_role_menu" VALUES (1, 1078);
INSERT INTO "public"."sys_role_menu" VALUES (1, 1079);
INSERT INTO "public"."sys_role_menu" VALUES (1, 1080);
INSERT INTO "public"."sys_role_menu" VALUES (1, 1081);
INSERT INTO "public"."sys_role_menu" VALUES (1, 1082);
INSERT INTO "public"."sys_role_menu" VALUES (1, 1083);
INSERT INTO "public"."sys_role_menu" VALUES (1, 1084);
INSERT INTO "public"."sys_role_menu" VALUES (1, 1092);
INSERT INTO "public"."sys_role_menu" VALUES (1, 1093);
INSERT INTO "public"."sys_role_menu" VALUES (1, 1094);
INSERT INTO "public"."sys_role_menu" VALUES (1, 1095);
INSERT INTO "public"."sys_role_menu" VALUES (1, 1096);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2031);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2032);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2033);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2034);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2035);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2036);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2037);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2038);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2039);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2040);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2041);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2042);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2043);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2044);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2045);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2046);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2047);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2048);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2049);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2050);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2051);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2052);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2053);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2054);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2055);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2056);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2057);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2058);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2059);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2060);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2061);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2062);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2063);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2064);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2065);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2066);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2067);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2068);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2069);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2074);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2075);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2076);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2077);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2078);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2079);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2080);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2081);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2082);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2083);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2084);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2085);
INSERT INTO "public"."sys_role_menu" VALUES (1, 2086);

CREATE TABLE "public"."sys_user" (
  "user_id" int8 NOT NULL DEFAULT nextval('sys_user_user_id_seq'::regclass),
  "dept_id" int8,
  "user_name" varchar(30) COLLATE "pg_catalog"."default" NOT NULL,
  "nick_name" varchar(30) COLLATE "pg_catalog"."default" NOT NULL,
  "user_type" varchar(2) COLLATE "pg_catalog"."default",
  "email" varchar(50) COLLATE "pg_catalog"."default",
  "phonenumber" varchar(11) COLLATE "pg_catalog"."default",
  "sex" char(1) COLLATE "pg_catalog"."default",
  "avatar" varchar(100) COLLATE "pg_catalog"."default",
  "password" varchar(100) COLLATE "pg_catalog"."default",
  "status" char(1) COLLATE "pg_catalog"."default",
  "del_flag" char(1) COLLATE "pg_catalog"."default" DEFAULT '0'::bpchar,
  "login_ip" varchar(128) COLLATE "pg_catalog"."default",
  "login_date" timestamp(6),
  "create_by" varchar(64) COLLATE "pg_catalog"."default",
  "create_time" timestamp(6),
  "update_by" varchar(64) COLLATE "pg_catalog"."default",
  "update_time" timestamp(6),
  "remark" varchar(500) COLLATE "pg_catalog"."default"
)
;
COMMENT ON COLUMN "public"."sys_user"."user_id" IS '用户ID';
COMMENT ON COLUMN "public"."sys_user"."dept_id" IS '部门ID';
COMMENT ON COLUMN "public"."sys_user"."user_name" IS '用户账号';
COMMENT ON COLUMN "public"."sys_user"."nick_name" IS '用户昵称';
COMMENT ON COLUMN "public"."sys_user"."user_type" IS '用户类型（00系统用户）';
COMMENT ON COLUMN "public"."sys_user"."email" IS '用户邮箱';
COMMENT ON COLUMN "public"."sys_user"."phonenumber" IS '手机号码';
COMMENT ON COLUMN "public"."sys_user"."sex" IS '用户性别（0男 1女 2未知）';
COMMENT ON COLUMN "public"."sys_user"."avatar" IS '头像地址';
COMMENT ON COLUMN "public"."sys_user"."password" IS '密码';
COMMENT ON COLUMN "public"."sys_user"."status" IS '帐号状态（0正常 1停用）';
COMMENT ON COLUMN "public"."sys_user"."del_flag" IS '删除标志（0代表存在 2代表删除）';
COMMENT ON COLUMN "public"."sys_user"."login_ip" IS '最后登录IP';
COMMENT ON COLUMN "public"."sys_user"."login_date" IS '最后登录时间';
COMMENT ON COLUMN "public"."sys_user"."create_by" IS '创建者';
COMMENT ON COLUMN "public"."sys_user"."create_time" IS '创建时间';
COMMENT ON COLUMN "public"."sys_user"."update_by" IS '更新者';
COMMENT ON COLUMN "public"."sys_user"."update_time" IS '更新时间';
COMMENT ON COLUMN "public"."sys_user"."remark" IS '备注';
COMMENT ON TABLE "public"."sys_user" IS '用户信息表';

INSERT INTO "public"."sys_user" VALUES (1, 103, 'Admin7s9k2G5', '管理员', '00', 'dreamfalls@163.com', '15888888888', '1', '', '$2a$10$dh.jyHikJr4YM0cvSThm4Orn1dnZlcEkXtKxolgBf1DZxd0JTKmm2', '0', '0', '127.0.0.1', '2025-09-18 10:02:36.896', 'admin', '2021-05-26 18:56:28', '', '2025-09-18 10:02:35.219592', '管理员');

CREATE TABLE "public"."sys_user_post" (
  "user_id" int8 NOT NULL,
  "post_id" int8 NOT NULL
)
;
COMMENT ON COLUMN "public"."sys_user_post"."user_id" IS '用户ID';
COMMENT ON COLUMN "public"."sys_user_post"."post_id" IS '岗位ID';
COMMENT ON TABLE "public"."sys_user_post" IS '用户与岗位关联表';

INSERT INTO "public"."sys_user_post" VALUES (1, 1);
INSERT INTO "public"."sys_user_post" VALUES (2, 2);

CREATE TABLE "public"."sys_user_role" (
  "user_id" int8 NOT NULL,
  "role_id" int8 NOT NULL
)
;
COMMENT ON COLUMN "public"."sys_user_role"."user_id" IS '用户ID';
COMMENT ON COLUMN "public"."sys_user_role"."role_id" IS '角色ID';
COMMENT ON TABLE "public"."sys_user_role" IS '用户和角色关联表';

INSERT INTO "public"."sys_user_role" VALUES (1, 1);
INSERT INTO "public"."sys_user_role" VALUES (2, 2);
INSERT INTO "public"."sys_user_role" VALUES (3, 2);

CREATE OR REPLACE FUNCTION "public"."find_in_set"(int8, varchar)
  RETURNS "pg_catalog"."bool" AS $BODY$
DECLARE
    STR ALIAS FOR $1;
    STRS ALIAS FOR $2;
    POS INTEGER;
    STATUS BOOLEAN;
BEGIN
    SELECT POSITION( ','||STR||',' IN ','||STRS||',') INTO POS;
    IF POS > 0 THEN
        STATUS = TRUE;
    ELSE
        STATUS = FALSE;
    END IF;
    RETURN STATUS;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION "public"."substring_index"(varchar, varchar, int4)
  RETURNS "pg_catalog"."varchar" AS $BODY$
DECLARE
tokens varchar[];
length integer ;
indexnum integer;
BEGIN
tokens := pg_catalog.string_to_array($1, $2);
length := pg_catalog.array_upper(tokens, 1);
indexnum := length - ($3 * -1) + 1;
IF $3 >= 0 THEN
RETURN pg_catalog.array_to_string(tokens[1:$3], $2);
ELSE
RETURN pg_catalog.array_to_string(tokens[indexnum:length], $2);
END IF;
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE STRICT
  COST 100;

CREATE VIEW "public"."list_column" AS  SELECT c.relname AS table_name,
    a.attname AS column_name,
    d.description AS column_comment,
        CASE
            WHEN a.attnotnull AND con.conname IS NULL THEN 1
            ELSE 0
        END AS is_required,
        CASE
            WHEN con.conname IS NOT NULL THEN 1
            ELSE 0
        END AS is_pk,
    a.attnum AS sort,
        CASE
            WHEN "position"(pg_get_expr(ad.adbin, ad.adrelid), ((c.relname::text || '_'::text) || a.attname::text) || '_seq'::text) > 0 THEN 1
            ELSE 0
        END AS is_increment,
    btrim(
        CASE
            WHEN t.typelem <> 0::oid AND t.typlen = '-1'::integer THEN 'ARRAY'::text
            ELSE
            CASE
                WHEN t.typtype = 'd'::"char" THEN format_type(t.typbasetype, NULL::integer)
                ELSE format_type(a.atttypid, NULL::integer)
            END
        END, '"'::text) AS column_type
   FROM pg_attribute a
     JOIN (pg_class c
     JOIN pg_namespace n ON c.relnamespace = n.oid) ON a.attrelid = c.oid
     LEFT JOIN pg_description d ON d.objoid = c.oid AND a.attnum = d.objsubid
     LEFT JOIN pg_constraint con ON con.conrelid = c.oid AND (a.attnum = ANY (con.conkey))
     LEFT JOIN pg_attrdef ad ON a.attrelid = ad.adrelid AND a.attnum = ad.adnum
     LEFT JOIN pg_type t ON a.atttypid = t.oid
  WHERE (c.relkind = ANY (ARRAY['r'::"char", 'p'::"char"])) AND a.attnum > 0 AND n.nspname = 'public'::name AND NOT a.attisdropped
  ORDER BY c.relname, a.attnum;

CREATE VIEW "public"."list_table" AS  SELECT c.relname AS table_name,
    obj_description(c.oid) AS table_comment,
    CURRENT_TIMESTAMP AS create_time,
    CURRENT_TIMESTAMP AS update_time
   FROM pg_class c
     LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE (c.relkind = ANY (ARRAY['r'::"char", 'p'::"char"])) AND c.relname !~~ 'spatial_%'::text AND n.nspname = 'public'::name AND n.nspname <> ''::name;

ALTER SEQUENCE "public"."gen_table_column_column_id_seq"
OWNED BY "public"."gen_table_column"."column_id";
SELECT setval('"public"."gen_table_column_column_id_seq"', 301, true);

ALTER SEQUENCE "public"."gen_table_table_id_seq"
OWNED BY "public"."gen_table"."table_id";
SELECT setval('"public"."gen_table_table_id_seq"', 25, true);

ALTER SEQUENCE "public"."sys_config_config_id_seq"
OWNED BY "public"."sys_config"."config_id";
SELECT setval('"public"."sys_config_config_id_seq"',
              (SELECT COALESCE(MAX(config_id), 1) FROM "public"."sys_config"), true);

ALTER SEQUENCE "public"."sys_dept_dept_id_seq"
OWNED BY "public"."sys_dept"."dept_id";
SELECT setval('"public"."sys_dept_dept_id_seq"', 110, false);

ALTER SEQUENCE "public"."sys_dict_data_dict_code_seq"
OWNED BY "public"."sys_dict_data"."dict_code";
SELECT setval('"public"."sys_dict_data_dict_code_seq"', 300, true);

ALTER SEQUENCE "public"."sys_dict_type_dict_id_seq"
OWNED BY "public"."sys_dict_type"."dict_id";
SELECT setval('"public"."sys_dict_type_dict_id_seq"', 39, true);

ALTER SEQUENCE "public"."sys_job_job_id_seq"
OWNED BY "public"."sys_job"."job_id";
SELECT setval('"public"."sys_job_job_id_seq"', 60, true);

ALTER SEQUENCE "public"."sys_job_log_job_log_id_seq"
OWNED BY "public"."sys_job_log"."job_log_id";
SELECT setval('"public"."sys_job_log_job_log_id_seq"', 12604, true);

ALTER SEQUENCE "public"."sys_logininfor_info_id_seq"
OWNED BY "public"."sys_logininfor"."info_id";
SELECT setval('"public"."sys_logininfor_info_id_seq"', 635, true);

ALTER SEQUENCE "public"."sys_menu_menu_id_seq"
OWNED BY "public"."sys_menu"."menu_id";
SELECT setval('"public"."sys_menu_menu_id_seq"',
              (SELECT COALESCE(MAX(menu_id), 1) FROM "public"."sys_menu"), true);

ALTER SEQUENCE "public"."sys_notice_notice_id_seq"
OWNED BY "public"."sys_notice"."notice_id";
SELECT setval('"public"."sys_notice_notice_id_seq"', 3, false);

ALTER SEQUENCE "public"."sys_oper_log_oper_id_seq"
OWNED BY "public"."sys_oper_log"."oper_id";
SELECT setval('"public"."sys_oper_log_oper_id_seq"', 3144, true);

ALTER SEQUENCE "public"."sys_post_post_id_seq"
OWNED BY "public"."sys_post"."post_id";
SELECT setval('"public"."sys_post_post_id_seq"', 5, false);

ALTER SEQUENCE "public"."sys_role_role_id_seq"
OWNED BY "public"."sys_role"."role_id";
SELECT setval('"public"."sys_role_role_id_seq"', 3, false);

ALTER SEQUENCE "public"."sys_user_user_id_seq"
OWNED BY "public"."sys_user"."user_id";
SELECT setval('"public"."sys_user_user_id_seq"', 3, true);

ALTER TABLE "public"."gen_table" ADD CONSTRAINT "gen_table_pkey" PRIMARY KEY ("table_id");

ALTER TABLE "public"."gen_table_column" ADD CONSTRAINT "gen_table_column_pkey" PRIMARY KEY ("column_id");

ALTER TABLE "public"."qrtz_blob_triggers" ADD CONSTRAINT "QRTZ_BLOB_TRIGGERS_pkey" PRIMARY KEY ("sched_name", "trigger_name", "trigger_group");

ALTER TABLE "public"."qrtz_calendars" ADD CONSTRAINT "QRTZ_CALENDARS_pkey" PRIMARY KEY ("sched_name", "calendar_name");

ALTER TABLE "public"."qrtz_cron_triggers" ADD CONSTRAINT "QRTZ_CRON_TRIGGERS_pkey" PRIMARY KEY ("sched_name", "trigger_name", "trigger_group");

ALTER TABLE "public"."qrtz_fired_triggers" ADD CONSTRAINT "QRTZ_FIRED_TRIGGERS_pkey" PRIMARY KEY ("sched_name", "entry_id");

ALTER TABLE "public"."qrtz_job_details" ADD CONSTRAINT "QRTZ_JOB_DETAILS_pkey" PRIMARY KEY ("sched_name", "job_name", "job_group");

ALTER TABLE "public"."qrtz_locks" ADD CONSTRAINT "QRTZ_LOCKS_pkey" PRIMARY KEY ("sched_name", "lock_name");

ALTER TABLE "public"."qrtz_paused_trigger_grps" ADD CONSTRAINT "QRTZ_PAUSED_TRIGGER_GRPS_pkey" PRIMARY KEY ("sched_name", "trigger_group");

ALTER TABLE "public"."qrtz_scheduler_state" ADD CONSTRAINT "QRTZ_SCHEDULER_STATE_pkey" PRIMARY KEY ("sched_name", "instance_name");

ALTER TABLE "public"."qrtz_simple_triggers" ADD CONSTRAINT "QRTZ_SIMPLE_TRIGGERS_pkey" PRIMARY KEY ("sched_name", "trigger_name", "trigger_group");

ALTER TABLE "public"."qrtz_simprop_triggers" ADD CONSTRAINT "QRTZ_SIMPROP_TRIGGERS_pkey" PRIMARY KEY ("sched_name", "trigger_name", "trigger_group");

CREATE INDEX "sched_name" ON "public"."qrtz_triggers" USING btree (
  "sched_name" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST,
  "job_name" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST,
  "job_group" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

ALTER TABLE "public"."qrtz_triggers" ADD CONSTRAINT "QRTZ_TRIGGERS_pkey" PRIMARY KEY ("sched_name", "trigger_name", "trigger_group");

ALTER TABLE "public"."sys_config" ADD CONSTRAINT "sys_config_pkey" PRIMARY KEY ("config_id");

ALTER TABLE "public"."sys_dept" ADD CONSTRAINT "sys_dept_pkey" PRIMARY KEY ("dept_id");

ALTER TABLE "public"."sys_dict_data" ADD CONSTRAINT "sys_dict_data_pkey" PRIMARY KEY ("dict_code");

CREATE INDEX "dict_type" ON "public"."sys_dict_type" USING btree (
  "dict_type" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

ALTER TABLE "public"."sys_dict_type" ADD CONSTRAINT "sys_dict_type_pkey" PRIMARY KEY ("dict_id");

ALTER TABLE "public"."sys_job" ADD CONSTRAINT "sys_job_pkey" PRIMARY KEY ("job_id", "job_name", "job_group");

ALTER TABLE "public"."sys_job_log" ADD CONSTRAINT "sys_job_log_pkey" PRIMARY KEY ("job_log_id");

ALTER TABLE "public"."sys_logininfor" ADD CONSTRAINT "sys_logininfor_pkey" PRIMARY KEY ("info_id");

ALTER TABLE "public"."sys_menu" ADD CONSTRAINT "sys_menu_pkey" PRIMARY KEY ("menu_id");

ALTER TABLE "public"."sys_notice" ADD CONSTRAINT "sys_notice_pkey" PRIMARY KEY ("notice_id");

ALTER TABLE "public"."sys_oper_log" ADD CONSTRAINT "sys_oper_log_pkey" PRIMARY KEY ("oper_id");

ALTER TABLE "public"."sys_post" ADD CONSTRAINT "sys_post_pkey" PRIMARY KEY ("post_id");

ALTER TABLE "public"."sys_role" ADD CONSTRAINT "sys_role_pkey" PRIMARY KEY ("role_id");

ALTER TABLE "public"."sys_role_dept" ADD CONSTRAINT "sys_role_dept_pkey" PRIMARY KEY ("role_id", "dept_id");

ALTER TABLE "public"."sys_role_menu" ADD CONSTRAINT "sys_role_menu_pkey" PRIMARY KEY ("role_id", "menu_id");

ALTER TABLE "public"."sys_user" ADD CONSTRAINT "sys_user_pkey" PRIMARY KEY ("user_id");

ALTER TABLE "public"."sys_user_post" ADD CONSTRAINT "sys_user_post_pkey" PRIMARY KEY ("user_id", "post_id");

ALTER TABLE "public"."sys_user_role" ADD CONSTRAINT "sys_user_role_pkey" PRIMARY KEY ("user_id", "role_id");

ALTER TABLE "public"."qrtz_blob_triggers" ADD CONSTRAINT "QRTZ_BLOB_TRIGGERS_ibfk_1" FOREIGN KEY ("sched_name", "trigger_name", "trigger_group") REFERENCES "public"."qrtz_triggers" ("sched_name", "trigger_name", "trigger_group") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "public"."qrtz_cron_triggers" ADD CONSTRAINT "QRTZ_CRON_TRIGGERS_ibfk_1" FOREIGN KEY ("sched_name", "trigger_name", "trigger_group") REFERENCES "public"."qrtz_triggers" ("sched_name", "trigger_name", "trigger_group") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "public"."qrtz_simple_triggers" ADD CONSTRAINT "QRTZ_SIMPLE_TRIGGERS_ibfk_1" FOREIGN KEY ("sched_name", "trigger_name", "trigger_group") REFERENCES "public"."qrtz_triggers" ("sched_name", "trigger_name", "trigger_group") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "public"."qrtz_simprop_triggers" ADD CONSTRAINT "QRTZ_SIMPROP_TRIGGERS_ibfk_1" FOREIGN KEY ("sched_name", "trigger_name", "trigger_group") REFERENCES "public"."qrtz_triggers" ("sched_name", "trigger_name", "trigger_group") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "public"."qrtz_triggers" ADD CONSTRAINT "QRTZ_TRIGGERS_ibfk_1" FOREIGN KEY ("sched_name", "job_name", "job_group") REFERENCES "public"."qrtz_job_details" ("sched_name", "job_name", "job_group") ON DELETE NO ACTION ON UPDATE NO ACTION;
