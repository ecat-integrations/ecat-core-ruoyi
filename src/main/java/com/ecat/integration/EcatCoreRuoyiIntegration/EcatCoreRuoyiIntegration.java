package com.ecat.integration.EcatCoreRuoyiIntegration;

import java.net.URLClassLoader;
import java.util.Collections;
import java.util.Map;

import javax.sql.DataSource;

import com.ecat.core.Integration.IntegrationBase;
import com.ecat.core.Log.ClassLoaderCoordinateFilter;
import com.ecat.core.Utils.DynamicConfig.ConfigDefinition;
import com.ecat.core.Utils.DynamicConfig.ConfigItem;
import com.ecat.core.Utils.DynamicConfig.ConfigItemBuilder;
import com.ecat.core.Utils.DynamicConfig.StringLengthValidator;
import com.ecat.integration.EcatDbMigration.DbMigrationFacade;

/**
 * EcatCoreRuoyiIntegration is a custom integration solution for integrating
 * ECAT with the Ruoyi framework.
 * 
 * @author coffee
 */

public class EcatCoreRuoyiIntegration extends IntegrationBase {

    private boolean isRuoyiStarted = false;
    private RuoyiJarApp ruoyiJarApp;
    private Map<String, Object> integrationConfig;

    // 配置检查相关
    private ConfigDefinition settingsConfigDefinition;
    private String ruoyiAdminJarPath;

    /** ruoyi-sys 域标识(与 ecat-config.yml 的 db.domain 及脚本目录 migration-ruoyi-sys 同名)。 */
    static final String DB_DOMAIN = "ruoyi-sys";

    /** Flyway 脚本扫描位(字面量,不做拼接)。 */
    static final String DB_LOCATION = "classpath:db/migration-ruoyi-sys";

    // 校验settings配置定义
    public ConfigDefinition getSettingsConfigDefinition() {
        if (settingsConfigDefinition == null) {
            settingsConfigDefinition = new ConfigDefinition();
            StringLengthValidator stringValidator = new StringLengthValidator(1, 255);
            ConfigItemBuilder builder = new ConfigItemBuilder()
                    .add(new ConfigItem<>("ruoyi_admin_jar_path", String.class, true, null, stringValidator));
            settingsConfigDefinition.define(builder);
        }
        return settingsConfigDefinition;
    }

    @Override
    public void onInit() {
        log.info("EcatCoreRuoyiIntegration initializing...");
        // 加载配置
        settingsConfigDefinition = getSettingsConfigDefinition();
        integrationConfig = integrationManager.loadConfig(this.getName());
        @SuppressWarnings("unchecked")
        Map<String, Object> settings = (Map<String, Object>) integrationConfig.get("settings");
        if (settings != null) {
            boolean valid = settingsConfigDefinition.validateConfig(settings);
            if (!valid) {
                Map<ConfigItem<?>, String> invalidItems = settingsConfigDefinition.getInvalidConfigItems();
                for (Map.Entry<ConfigItem<?>, String> entry : invalidItems.entrySet()) {
                    log.error("EcatCoreRuoyiIntegration 配置项: {} 错误信息: {}", entry.getKey().getKey(), entry.getValue());
                }
            } else {
                ruoyiAdminJarPath = (String) settings.get("ruoyi_admin_jar_path");
            }
        }
    }

    @Override
    public void onStart() {
        log.info("EcatCoreRuoyiIntegration started");

        // 注册 ruoyi 及其依赖的包名前缀
        // 这样 ruoyi-admin.jar 内部的所有日志都会路由到 ruoyi 集成
        String ruoyiCoordinate = "com.ecat:integration-ecat-core-ruoyi";
        ClassLoaderCoordinateFilter.registerPackagePrefix("com.ruoyi", ruoyiCoordinate);
        ClassLoaderCoordinateFilter.registerPackagePrefix("org.springframework", ruoyiCoordinate);
        ClassLoaderCoordinateFilter.registerPackagePrefix("org.mybatis", ruoyiCoordinate);
        ClassLoaderCoordinateFilter.registerPackagePrefix("com.alibaba.druid", ruoyiCoordinate);

        if (ruoyiAdminJarPath != null && !ruoyiAdminJarPath.isEmpty()) {

            ruoyiJarApp = new RuoyiJarApp();

            URLClassLoader childClassLoader = null;
            try {
                childClassLoader = ruoyiJarApp.start(ruoyiAdminJarPath, null, new String[] {});
            } catch (Exception e) {
                log.error("Failed to start RuoyiJarApp with jar path: " + ruoyiAdminJarPath, e);
            }

            if (childClassLoader == null) {
                // start 失败为既有行为:仅记日志不上抛;此时 Spring 未起,DataSource 不存在,迁移无从执行。
                // 叶子装载路径经 loadJarAndVue 的 IllegalStateException 显式失败——与改动前「落到方法尾」观感等价
                return;
            }

            // 旗标先行:runRuoyiSysMigration 经 getSpringBean 反射桥取 DataSource,
            // 守卫要求桥已就绪(isRuoyiStarted);类加载器注册仍后置——迁移成功才向叶子开放。
            isRuoyiStarted = true;

            // 执行点:ruoyi Spring 就绪后、叶子可装载前,ruoyi-sys 域按账本补齐库结构。
            // 迁移成功才注册 childClassLoader;失败=异常沿 if 块直抛出 onStart,由启动期守卫包装为
            // 「onStart 失败」触发 failure/enable 回滚——叶子装载根本不发生。
            runRuoyiSysMigration();

            this.loadOption.setChildClassLoader(childClassLoader);
            log.info("Loading Ruoyi admin jar from path: {}", ruoyiAdminJarPath);

        } else {
            log.error("Ruoyi admin jar path is not set or is empty.");
            return;
        }

    }

    @Override
    public void onPause() {

    }

    @Override
    protected void onReleaseImpl() {

    }

    public void loadJarAndVue(URLClassLoader targetClassLoader, IntegrationBase target) throws Exception {
        if (isRuoyiStarted && ruoyiJarApp != null) {
            ruoyiJarApp.loadJarAndVue(targetClassLoader, target);
        } else {
            throw new IllegalStateException("EcatCoreRuoyiIntegration integration is not started yet.");
        }
        // this.loadJar(targetClassLoader);
        // this.loadVue(targetClassLoader, target);
    }

    public boolean checkSpringBean(String beanName) {
        try {
            if (isRuoyiStarted && ruoyiJarApp != null) {
                return ruoyiJarApp.checkSpringBean(beanName);
            } else {
                log.error("ruoyiJarApp is not initialized.");
            }
        } catch (Exception e) {
            log.error("Error getting Spring bean: " + beanName, e);
        }
        return false;
    }

    public <T> T getSpringBean(String beanName, Class<T> clazz) {
        try {
            if (isRuoyiStarted && ruoyiJarApp != null) {
                return ruoyiJarApp.getSpringBean(beanName, clazz);
            } else {
                log.error("ruoyiJarApp is not initialized.");
            }
        } catch (Exception e) {
            log.error("Error getting Spring bean: " + beanName, e);
        }
        return null;
    }

    public <T> T getSpringBean(Class<T> requiredType) {
        try {
            if (isRuoyiStarted && ruoyiJarApp != null) {
                return ruoyiJarApp.getSpringBean(requiredType);
            } else {
                log.error("ruoyiJarApp is not initialized.");
            }
        } catch (Exception e) {
            log.error("Error getting Spring bean: " + requiredType.getName(), e);
        }
        return null;
    }

    /**
     * ruoyi-sys 域启动期自迁移,两态接线:有账本表直接 migrate(照账本补刀,幂等);
     * 无账本表先 baseline("0") 建账再 migrate(空库放行全量;0<4.0.0,V4.0.0 不被挡)。
     * 未接管存量库在 migrate 处撞已存在表显式报错(「该域未接管」信号)——禁静默兜底。
     * 失败=明确异常上抛,调用方不得装载叶子(结构不明不装载)。
     * 资源扫描类加载器由门面经 resourceAnchor(本类字面量)取得——桥仓脚本在桥 jar 内,
     * 唯此加载器可见;TCCL 由引擎侧禁用,调用方零线程状态操作。
     */
    void runRuoyiSysMigration() {
        DataSource ds = getSpringBean(DataSource.class);
        if (ds == null) {
            throw new IllegalStateException(
                    "ruoyi Spring 容器未提供 DataSource Bean,ruoyi-sys 域迁移中止,叶子不装载");
        }
        if (DbMigrationFacade.hasHistoryTable(DB_DOMAIN, ds)) {
            DbMigrationFacade.migrate(DB_DOMAIN, ds,
                    Collections.singletonList(DB_LOCATION), EcatCoreRuoyiIntegration.class);
        } else {
            DbMigrationFacade.baseline(DB_DOMAIN, ds, "0");
            DbMigrationFacade.migrate(DB_DOMAIN, ds,
                    Collections.singletonList(DB_LOCATION), EcatCoreRuoyiIntegration.class);
        }
        log.info("ruoyi-sys 域迁移完成");
    }

}
