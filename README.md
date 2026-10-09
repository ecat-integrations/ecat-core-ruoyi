# 组件作用
+ ecat-core微服务架构的模块集成，为core提供集成ruoyi-admin能力
+ 异步加载ruoyi-admin打包方式的加载程序，可加载ruoyi-admin.jar
+ 所有使用若依框架的ecat-integrations的依赖组件
+ 平台数据库托管方与域迁移代理(T-5-9 定稿,实施后生效):持有全平台唯一 PG 连接;租户集成经 loadJarAndVue 注册时**先迁后装**——扫租户 jar 的 db/migration-<域名>/ 目录,两态迁移(无账本建表全量/有账本补刀)成功后才装载其后端,失败=该租户不装载
+ ruoyi-sys 域=第一个租户:ruoyi Spring 就绪后走同一迁移通道(db/migration-ruoyi-sys/),不再单写自迁移代码

# 依赖
依赖 springboot 框架的 spring-boot-loader
依赖 com.ecat 的 integration-ecat-db-migration(迁移引擎，provided，运行期经 trunk 共享类加载层获得)

# 使用介绍
+ 需要使用的集成中添加ecat-config.yml
```
dependencies:
  - artifactId: integration-ecat-core-ruoyi
```

+ 增加配置文件：EcatCoreRuoyiIntegration.yml并确保jar路径正确

## 子集成如何接入数据库迁移(dbm)

> 对应 T-5-9 设计定稿(2026-10-08),实施落地后生效;完整说明与排错见 ecat-db-migration 仓 `docs/使用手册.md`。

**寄居租户(表放平台共享库,env 系集成的标准形态)要做的只有一件事:把脚本放进约定目录。**零 Java 代码、零 pom 依赖、零配置声明:

```
你的集成仓/
└─ src/main/resources/db/migration-<你的域名>/
   └─ V4.0.0__init.sql          ← 你的全部交付物
```

自动发生的时序(无需你参与):你的集成 onStart 首段照常调用 `loadJarAndVue(classLoader, this)` 注册 → 本宿主在方法体首先扫描你的 jar 发现脚本目录 → 把你的表建好/补好 → 然后才装载你的后端。**先迁后装**,迁移失败你的集成起不来(不带病运行)。

日常演进:改结构=加一份新 `V<更高版本>__<描述>.sql`,下次启动自动补刀;已入账的旧脚本禁改动(checksum 拦截)。
铁律:域名 `^[a-z][a-z0-9-]*$`、一 jar 恰一域、目录名=域名逐字符一致。

## 协议声明
1. 核心依赖：本插件基于 **ECAT Core**（Apache License 2.0）开发，Core 项目地址：https://github.com/ecat-project/ecat-core。
2. 插件自身：本插件的源代码采用 [Apache License 2.0] 授权。
3. 合规说明：使用本插件需遵守 ECAT Core 的 Apache 2.0 协议规则，若复用 ECAT Core 代码片段，需保留原版权声明。

### 许可证获取
- ECAT Core 完整许可证：https://github.com/ecat-project/ecat-core/blob/main/LICENSE
- 本插件许可证：./LICENSE

