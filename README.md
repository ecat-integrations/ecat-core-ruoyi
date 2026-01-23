# 组件作用
+ ecat-core微服务架构的模块集成，为core提供集成ruoyi-admin能力
+ 异步加载ruoyi-admin打包方式的加载程序，可加载ruoyi-admin.jar
+ 所有使用若依框架的ecat-integrations的依赖组件

# 依赖
依赖 springboot 框架的 spring-boot-loader

# 使用介绍
+ 需要使用的集成中添加ecat-config.yml
```
dependencies:
  - artifactId: integration-ecat-core-ruoyi
```

+ 增加配置文件：EcatCoreRuoyiIntegration.yml并确保jar路径正确

## 协议声明
1. 核心依赖：本插件基于 **ECAT Core**（Apache License 2.0）开发，Core 项目地址：https://github.com/ecat-project/ecat-core。
2. 插件自身：本插件的源代码采用 [Apache License 2.0] 授权。
3. 合规说明：使用本插件需遵守 ECAT Core 的 Apache 2.0 协议规则，若复用 ECAT Core 代码片段，需保留原版权声明。

### 许可证获取
- ECAT Core 完整许可证：https://github.com/ecat-project/ecat-core/blob/main/LICENSE
- 本插件许可证：./LICENSE

