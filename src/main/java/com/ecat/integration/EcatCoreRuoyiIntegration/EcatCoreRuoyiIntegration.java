package com.ecat.integration.EcatCoreRuoyiIntegration;

import java.net.URLClassLoader;
import java.time.LocalDateTime;
import java.util.Map;

import javax.sql.DataSource;

import com.ecat.core.Integration.IntegrationBase;
import com.ecat.core.Log.ClassLoaderCoordinateFilter;
import com.ecat.core.Upgrade.BackupHook;
import com.ecat.core.Utils.DynamicConfig.ConfigDefinition;
import com.ecat.core.Utils.DynamicConfig.ConfigItem;
import com.ecat.core.Utils.DynamicConfig.ConfigItemBuilder;
import com.ecat.core.Utils.DynamicConfig.StringLengthValidator;
import com.ecat.integration.EcatDbMigration.DbMigrationFacade;

/**
 * EcatCoreRuoyiIntegration is a custom integration solution for integrating
 * ECAT with the Ruoyi framework.
 *
 * <p>宿主集成双职责:①db 代理——租户注册即发现(扫租户 jar 约定目录),先迁后装,
 * 失败=租户不装载;自身域 ruoyi-sys 同走入口②(第一个租户)。②备份参与者——实现
 * {@link BackupHook},本轮空跑模式,升级窗程序的派发/账本/日志面真实。</p>
 *
 * @author coffee
 */

public class EcatCoreRuoyiIntegration extends IntegrationBase implements BackupHook {

    private boolean isRuoyiStarted = false;
    private RuoyiJarApp ruoyiJarApp;
    private AdminLocation adminLocation;
    private Map<String, Object> integrationConfig;

    // 配置检查相关
    private ConfigDefinition settingsConfigDefinition;
    private String ruoyiAdminJarPath;

    // 校验settings配置定义
    public ConfigDefinition getSettingsConfigDefinition() {
        if (settingsConfigDefinition == null) {
            settingsConfigDefinition = new ConfigDefinition();
            StringLengthValidator stringValidator = new StringLengthValidator(1, 255);
            ConfigItemBuilder builder = new ConfigItemBuilder()
                    .add(new ConfigItem<>("ruoyi_admin_jar_path", String.class, false, null, stringValidator));
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

        // 定位挂 onInit=失败显形路径:异常沿 loadSingleIntegration 上抛记 failure,不被 onStart 既有 catch 吞。
        // 路径未指定(null/校验拒绝/键缺失,三态语义统一=未指定)走自身包嵌入载荷嵌读定位(D2');
        // 启动零网络零写盘。定位必须置于 settings 判空块之外——无配置实例的空机场景同样要定位。
        adminLocation = RuoyiAdminResolver.resolve(getClass(),
                ruoyiAdminJarPath, RuoyiAdminResolver.readBridgeVersion(getClass()));
        log.info("ruoyi-admin 定位完成: {}", adminLocation.describe());
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

        if (adminLocation != null) {

            ruoyiJarApp = new RuoyiJarApp();

            URLClassLoader childClassLoader = null;
            try {
                // 按定位形态分路:USER_FILE=现行文件形态;NESTED_ENTRY=嵌读直启(包内条目,零落盘)。
                if (adminLocation.getMode() == AdminLocation.Mode.USER_FILE) {
                    childClassLoader = ruoyiJarApp.start(adminLocation.getFilePath(), null, new String[] {});
                } else {
                    childClassLoader = ruoyiJarApp.startNested(adminLocation.getBridgeJarPath(),
                            adminLocation.getAdminEntryName(), new String[] {});
                }
            } catch (Exception e) {
                log.error("Failed to start RuoyiJarApp: {}", adminLocation.describe(), e);
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
            log.info("Loading Ruoyi admin jar: {}", adminLocation.describe());

        }

    }

    @Override
    public void onPause() {

    }

    @Override
    protected void onReleaseImpl() {

    }

    /**
     * 租户装载唯一入口,兼宿主代理迁移挂点:租户 onStart 首段调用本方法——方法体先做
     * 代理迁移(注册即发现:扫租户 jar 约定目录),成功后才委托
     * {@link RuoyiJarApp#loadJarAndVue} 装载租户后端。「先迁后装」=与旧接线
     * (租户 onStart 内先迁后装)时序逐位等价;迁移失败=异常原样上抛,租户不装载
     * (结构不明不装载)。
     *
     * @param targetClassLoader 租户 jar 加载器(装载动作入参)
     * @param target            租户集成对象(其类所在 jar 即约定目录扫描锚)
     */
    public void loadJarAndVue(URLClassLoader targetClassLoader, IntegrationBase target) throws Exception {
        migrateTenantDomainBeforeLoad(target);
        if (isRuoyiStarted && ruoyiJarApp != null) {
            ruoyiJarApp.loadJarAndVue(targetClassLoader, target);
        } else {
            throw new IllegalStateException("EcatCoreRuoyiIntegration integration is not started yet.");
        }
    }

    /**
     * 租户域代理迁移(先迁后装,方法体首执行):扫租户 jar 约定目录 db/migration-&lt;域名&gt;——
     * 无目录(纯协议集成/冻结族)=非迁移用户,直接放行装载;有目录=dbm 入口②两态迁移,
     * 表就绪先于租户后端装载。DS 获取与自身域执行点同源(ruoyi Spring 容器反射桥),
     * 桥未就绪或容器缺 Bean 时显式失败——禁 null 容忍静默放行。
     *
     * <p>target==this 自守卫:宿主自身域 ruoyi-sys 是第一个租户,但走 onStart 内
     * {@link #runRuoyiSysMigration} 执行点(Spring 就绪后),不经本租户路径——防同锚
     * 双跑,也防宿主自身被误当租户扫(本类不载于自身产物 jar,约定目录扫描对它无意义)。</p>
     */
    private void migrateTenantDomainBeforeLoad(IntegrationBase target) {
        if (target == this) {
            return;
        }
        String domain = DbMigrationFacade.findMigrationDomain(target.getClass());
        if (domain == null) {
            log.info("租户 jar 无迁移约定目录,跳过迁移直接装载: tenant={}", target.getClass().getName());
            return;
        }
        DataSource ds = getSpringBean(DataSource.class);
        if (ds == null) {
            throw new IllegalStateException(
                    "ruoyi Spring 容器未提供 DataSource Bean,租户域 " + domain + " 迁移中止,租户不装载");
        }
        DbMigrationFacade.migrateDomain(target.getClass(), ds);
        log.info("租户域迁移完成(先迁后装): domain={}, tenant={}", domain, target.getClass().getName());
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
     * ruoyi-sys 域启动期自迁移执行点(原位原时机:Spring 就绪后、叶子可装载前)。
     * 宿主自身域=第一个租户,同走 dbm 入口② {@link DbMigrationFacade#migrateDomain},
     * 锚=本类字面量——桥仓脚本在桥 jar 内唯此加载器可见,两态策略(有账本 migrate
     * 补刀/无账本 baseline("0") 建账再 migrate 全量)已内聚进 dbm 单点,本类不再持有
     * 两态接线。失败=明确异常上抛,调用方不得装载叶子(结构不明不装载);TCCL 由
     * 引擎侧禁用,调用方零线程状态操作。
     */
    void runRuoyiSysMigration() {
        DataSource ds = getSpringBean(DataSource.class);
        if (ds == null) {
            throw new IllegalStateException(
                    "ruoyi Spring 容器未提供 DataSource Bean,ruoyi-sys 域迁移中止,叶子不装载");
        }
        DbMigrationFacade.migrateDomain(EcatCoreRuoyiIntegration.class, ds);
        log.info("ruoyi-sys 域迁移完成");
    }

    /**
     * 备份钩子·空跑模式(2026-10-08 裁定本轮不真备份):升级窗程序的派发、账本、日志面
     * 全真实,本实现零数据副本零外部命令,正常返回不参与窗口成败。真实形态=全库
     * pg_dump 已定稿待启用——启用时只改 {@link #backup()}/{@link #restore()} 两方法体,
     * 窗协议与派发面不动。
     */
    @Override
    public void backup() {
        log.info("[BackupHook] backup 空跑完成: 零数据副本零外部命令, ts={}", LocalDateTime.now());
    }

    @Override
    public void restore() {
        log.info("[BackupHook] restore 空跑完成: 零数据副本零外部命令, ts={}", LocalDateTime.now());
    }

}
