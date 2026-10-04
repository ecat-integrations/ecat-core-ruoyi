package com.ecat.integration.EcatCoreRuoyiIntegration;

import org.springframework.boot.loader.LaunchedURLClassLoader;
import org.springframework.boot.loader.archive.JarFileArchive;

import com.ecat.core.Integration.IntegrationBase;

import org.springframework.boot.loader.archive.Archive;

import java.io.File;
import java.lang.reflect.Method;
import java.net.URL;
import java.net.URLClassLoader;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

/**
 * 使用 spring-boot-loader 的 LaunchedURLClassLoader 实现 fat jar 嵌套 jar 加载。成功
 * 
 * @author coffee
 */
public class RuoyiJarApp {

    private Class<?> mainClass;

    public URLClassLoader start(String fatJarPath, String mainClassName, String[] args) throws Exception {
        // 自动从 MANIFEST.MF 读取 Start-Class
        if (mainClassName == null || mainClassName.isEmpty()) {
            try (java.util.jar.JarFile jf = new java.util.jar.JarFile(fatJarPath)) {
                java.util.jar.Manifest manifest = jf.getManifest();
                if (manifest != null) {
                    String startClass = manifest.getMainAttributes().getValue("Start-Class");
                    if (startClass != null && !startClass.isEmpty()) {
                        mainClassName = startClass;
                    } else {
                        throw new IllegalArgumentException("未在 MANIFEST.MF 中找到 Start-Class 属性");
                    }
                } else {
                    throw new IllegalArgumentException("未找到 MANIFEST.MF");
                }
            }
        }

        try {
            // 构造 fat jar Archive，注意资源释放
            try (Archive archive = new JarFileArchive(new File(fatJarPath))) {
                return launch(archive, mainClassName, args);
            }
        } catch (Exception e) {
            throw new RuntimeException("启动ruoyi-admin失败: " + e.getMessage(), e);
        }
    }

    /**
     * 嵌读形态入口(D2'):admin 不是独立文件,而是桥接自身包内的嵌入载荷条目。
     * 机制=现行 spring-boot-loader 嵌套加载「只换根不换法」:根 Archive 换成桥接包,
     * 嵌套 admin Archive 经精确名滤器取得(结构性至多一条);Start-Class 从嵌套 admin
     * 的 manifest 读(桥接包自身 manifest 无 Start-Class,外层读法在嵌套形态下不适用)。
     *
     * @param bridgeJarPath 桥接自身 jar 物理路径(嵌读输入,零落盘零解压)
     * @param adminEntryName 载荷条目名(payload/ruoyi-admin-{v}.jar,精确名=版本门)
     * @throws IllegalStateException 桥接包内无该载荷条目(构建缺陷第二道门,防目录形态漂移)
     */
    public URLClassLoader startNested(String bridgeJarPath, String adminEntryName, String[] args) throws Exception {
        try (Archive bridgeArchive = new JarFileArchive(new File(bridgeJarPath))) {
            Iterator<Archive> nested = bridgeArchive.getNestedArchives(
                    entry -> entry.getName().equals(adminEntryName), entry -> true);
            if (!nested.hasNext()) {
                throw new IllegalStateException("桥接包内无嵌入载荷条目: " + adminEntryName
                        + "(构建缺陷:dependency-plugin copy/fileSet 两块缺失)");
            }
            try (Archive adminArchive = nested.next()) {
                java.util.jar.Manifest manifest = adminArchive.getManifest();
                if (manifest == null) {
                    throw new IllegalStateException("嵌套 admin 包无 MANIFEST: " + adminEntryName);
                }
                String startClass = manifest.getMainAttributes().getValue("Start-Class");
                if (startClass == null || startClass.isEmpty()) {
                    throw new IllegalStateException("嵌套 admin 包 MANIFEST 无 Start-Class: " + adminEntryName);
                }
                return launch(adminArchive, startClass, args);
            }
        }
    }

    /**
     * 两入口公共尾:收集滤器→LaunchedURLClassLoader→setContextClassLoader→loadClass→main invoke。
     * 与既有 start 的文件形态逻辑逐字同源(消除复制)。
     */
    private URLClassLoader launch(Archive adminArchive, String mainClassName, String[] args) throws Exception {
        // 收集所有嵌套 jar 和 classes 目录的 URL
        List<URL> urls = new ArrayList<>();
        for (Iterator<Archive> it = adminArchive.getNestedArchives(
                entry -> (entry.isDirectory() && entry.getName().equals("BOOT-INF/classes/")) || entry.getName().endsWith(".jar"),
                entry -> true); it.hasNext(); ) {
            Archive nested = it.next();
            urls.add(nested.getUrl());
        }

        LaunchedURLClassLoader classLoader = new LaunchedURLClassLoader(urls.toArray(new URL[0]), getClass().getClassLoader());

        Thread.currentThread().setContextClassLoader(classLoader);

        mainClass = classLoader.loadClass(mainClassName);
        mainClass.getMethod("main", String[].class).invoke(null, (Object) args);

        return classLoader;
    }

    public void loadJarAndVue(URLClassLoader targetClassLoader, IntegrationBase target) throws Exception {
        if (mainClass == null) {
            throw new IllegalStateException("请先调用 start 方法启动应用");
        }
         // 3. 反射调用RuoYiApplication的checkSpringBean方法，检查Bean是否存在
        Method checkBeanMethod = mainClass.getMethod("checkSpringBean", String.class);
        boolean beanExists = (boolean) checkBeanMethod.invoke(null, "ecatRuoyiAdapter");

        if (beanExists) {
            // 4. 反射调用getSpringBean方法，获取EcatRuoyiAdapter实例
            Method getBeanMethod = mainClass.getMethod("getSpringBean", String.class);
            Object adapterObj = getBeanMethod.invoke(null, "ecatRuoyiAdapter");

            // 5. 反射调用EcatRuoyiAdapter的loadJarAndVue方法
            if (adapterObj != null) {
                Class<?> adapterClass = adapterObj.getClass();
                Method loadMethod = adapterClass.getMethod("loadJarAndVue", URLClassLoader.class, IntegrationBase.class);
                loadMethod.invoke(adapterObj, targetClassLoader, target);
                System.out.println("反射调用loadJarAndVue成功");
            }
        } else {
            throw new RuntimeException("Spring容器中未找到名为ecatRuoyiAdapter的Bean");
        }
    }

    public static void main(String[] args) throws Exception {
        if (args.length < 2) {
            System.out.println("用法: java TestRuoyiJarDependencies <fat-jar-path> <main-class> [args...]");
            return;
        }
        String fatJarPath = args[0];
        String mainClassName = args[1];
        String[] appArgs = java.util.Arrays.copyOfRange(args, 2, args.length);
        new RuoyiJarApp().start(fatJarPath, mainClassName, appArgs);

        try {
            // 可以根据需要调整等待时间，或实现更复杂的存活检测机制
            while (true) {
                Thread.sleep(30000); // 每30秒检查一次
                // 这里可以添加应用存活检测逻辑
            }
        } catch (InterruptedException e) {
            System.out.println("应用被中断，准备退出...");
        }
    }

    public boolean checkSpringBean(String beanName) throws Exception {
        Method checkBeanMethod = mainClass.getMethod("checkSpringBean", String.class);
        boolean beanExists = (boolean) checkBeanMethod.invoke(null, "ecatRuoyiAdapter");
        return beanExists;
    }

    public <T> T getSpringBean(String beanName, Class<T> clazz) throws Exception {
        Method getBeanMethod = mainClass.getMethod("getSpringBean", String.class, Class.class);
        @SuppressWarnings("unchecked")
        T result = (T) getBeanMethod.invoke(
            null,           // 静态方法调用，实例参数为null
            beanName,       // 实际参数1：Bean名称
            clazz    // 实际参数2：Bean类型
        );

        return result;
    }

    public <T> T getSpringBean(Class<T> clazz) throws Exception {
        Method getBeanMethod = mainClass.getMethod("getSpringBean", Class.class);
        @SuppressWarnings("unchecked")
        T result = (T) getBeanMethod.invoke(
            null,           // 静态方法调用，实例参数为null
            clazz    // 实际参数1：Bean类型
        );

        return result;
    }
}
