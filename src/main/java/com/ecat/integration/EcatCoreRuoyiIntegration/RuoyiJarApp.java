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

        try{
            // 1. 构造 fat jar Archive，注意资源释放
            try (Archive archive = new JarFileArchive(new File(fatJarPath))) {
                // 2. 收集所有嵌套 jar 和 classes 目录的 URL
                List<URL> urls = new ArrayList<>();
                for (Iterator<Archive> it = archive.getNestedArchives(
                        entry -> (entry.isDirectory() && entry.getName().equals("BOOT-INF/classes/")) || entry.getName().endsWith(".jar"),
                        entry -> true); it.hasNext(); ) {
                    Archive nested = it.next();
                    urls.add(nested.getUrl());
                }

                // 3. 构造 LaunchedURLClassLoader
                LaunchedURLClassLoader classLoader = new LaunchedURLClassLoader(urls.toArray(new URL[0]), getClass().getClassLoader());

                Thread.currentThread().setContextClassLoader(classLoader);

                // 4. 加载并启动主类
                mainClass = classLoader.loadClass(mainClassName);
                mainClass.getMethod("main", String[].class).invoke(null, (Object) args);

                return classLoader;
            }
        } catch (Exception e) {
            throw new RuntimeException("启动ruoyi-admin失败: " + e.getMessage(), e);
        }
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
