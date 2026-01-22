package com.ecat.integration.EcatCoreRuoyiIntegration;

import java.net.URLClassLoader;
import java.util.Map;
import com.ecat.core.Integration.IntegrationBase;
import com.ecat.core.Utils.DynamicConfig.ConfigDefinition;
import com.ecat.core.Utils.DynamicConfig.ConfigItem;
import com.ecat.core.Utils.DynamicConfig.ConfigItemBuilder;
import com.ecat.core.Utils.DynamicConfig.StringLengthValidator;

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
        if (ruoyiAdminJarPath != null && !ruoyiAdminJarPath.isEmpty()) {

            ruoyiJarApp = new RuoyiJarApp();

            try {
                URLClassLoader childClassLoader = ruoyiJarApp.start(
                        ruoyiAdminJarPath,
                        null,
                        new String[] {});
                this.loadOption.setChildClassLoader(childClassLoader);
                isRuoyiStarted = true;
                log.info("Loading Ruoyi admin jar from path: {}", ruoyiAdminJarPath);
            } catch (Exception e) {
                log.error("Failed to start RuoyiJarApp with jar path: " + ruoyiAdminJarPath, e);
            }

        } else {
            log.error("Ruoyi admin jar path is not set or is empty.");
            return;
        }

    }

    @Override
    public void onPause() {

    }

    @Override
    public void onRelease() {

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

}
