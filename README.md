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
