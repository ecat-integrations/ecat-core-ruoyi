package com.ecat.integration.EcatCoreRuoyiIntegration;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.net.URL;
import java.net.URLDecoder;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Properties;
import java.util.jar.JarEntry;
import java.util.jar.JarFile;

/**
 * ruoyi-admin 定位唯一载体(D46 嵌读形态):用户指定路径优先(文件形态,D1 全量校验);
 * 未指定走自身 jar 嵌入载荷定位(嵌套形态,条目名精确命中=版本门)。
 * 结构性零网络(不持有/不引用任何下载客户端类型)零写盘(全程无文件写入调用)——
 * 启动期消费的都是已构建事实(嵌入载荷),两零由编译面保证,非纪律约束。
 * 工具类形态:全 static+私有构造器;所有异常=IllegalStateException,无吞、无 null 返回。
 */
public final class RuoyiAdminResolver {

    static final String ADMIN_GROUP_ID = "com.ecat";
    static final String ADMIN_ARTIFACT_ID = "ruoyi-admin";
    /** admin 侧版本校验材料(maven-jar-plugin addMavenDescriptor 默认产物,repackage 后保留在 jar 根)。 */
    static final String ADMIN_POM_PROPS_ENTRY = "META-INF/maven/com.ecat/ruoyi-admin/pom.properties";
    /** 嵌入载荷条目名(带版本,构建期 ${project.version} 生成;精确名命中即版本一致)。 */
    static final String PAYLOAD_ENTRY_FORMAT = "payload/ruoyi-admin-%s.jar";

    private RuoyiAdminResolver() {
    }

    /**
     * ruoyi-admin 定位唯一入口:用户指定路径优先(文件形态);未指定走自身 jar 嵌入载荷嵌读(嵌套形态)。
     * D1 全量三重校验(存在+材料可读+版本一致);D2' 版本门=条目名精确命中
     * (构建期同 pom 绑定,不二次校验)。任何失败抛 IllegalStateException,fail-closed 无降级,
     * 用户路径分支不回退嵌读(用户错就是用户错)。
     *
     * @param anchor            桥接类字面量(自身 jar 定位锚)
     * @param userSpecifiedPath settings.ruoyi_admin_jar_path 原值(null/空串=未指定)
     * @param bridgeVersion     桥接自身版本(readBridgeVersion 产物,一对一基准)
     * @return AdminLocation(USER_FILE 文件路径 / NESTED_ENTRY 自身 jar 路径+条目名)
     * @throws IllegalStateException 用户路径不存在/版本不一致/自身包无载荷条目/开发态无载体
     */
    public static AdminLocation resolve(Class<?> anchor, String userSpecifiedPath, String bridgeVersion) {
        if (userSpecifiedPath != null && !userSpecifiedPath.isEmpty()) {
            Path jar = Paths.get(userSpecifiedPath);
            verifyJar(jar, bridgeVersion, "用户指定路径");
            return AdminLocation.userFile(jar.toAbsolutePath().toString());
        }

        String selfJarPath = locateSelfJar(anchor);
        String entryName = String.format(PAYLOAD_ENTRY_FORMAT, bridgeVersion);
        try (JarFile selfJar = new JarFile(selfJarPath)) {
            JarEntry payload = selfJar.getJarEntry(entryName);
            if (payload == null) {
                throw new IllegalStateException("自身 jar 无嵌入载荷=构建缺陷:桥接包内查无条目 " + entryName
                        + "(dependency-plugin copy/fileSet 两块缺失),jar=" + selfJarPath);
            }
        } catch (IOException e) {
            throw new IllegalStateException("自身 jar 无法读取: " + selfJarPath, e);
        }
        return AdminLocation.nestedEntry(Paths.get(selfJarPath).toAbsolutePath().toString(), entryName);
    }

    /**
     * 桥接自身版本唯一读取口(单一来源):类所载 jar manifest 的 Implementation-Version
     * (pom 构建期注入,运行时读取,无第二处版本字面量)。
     *
     * @throws IllegalStateException manifest 缺 Implementation-Version(=打包配置缺失,构建流程缺陷显形)
     */
    static String readBridgeVersion(Class<?> anchor) {
        String version = anchor.getPackage().getImplementationVersion();
        if (version == null) {
            throw new IllegalStateException("桥接版本不可得:manifest 无 Implementation-Version"
                    + "(assembly 需注入 Implementation-Version=${project.version})");
        }
        return version;
    }

    /**
     * admin jar 版本校验(防串包门):读 jar 根 pom.properties 的 version 键,与基准严格相等。
     * 仅 D1(用户指定路径,来源不受控)使用;嵌套分支版本门=条目名,不走本方法。
     *
     * @throws IllegalStateException 文件不存在/非 zip/pom.properties 缺失或无 version 键/版本不一致
     */
    static void verifyJar(Path jar, String expectedVer, String sourceLabel) {
        if (!Files.exists(jar)) {
            throw new IllegalStateException(sourceLabel + " admin jar 不存在: " + jar + "(不回退嵌读)");
        }
        String actual;
        try (JarFile jarFile = new JarFile(jar.toFile())) {
            JarEntry propsEntry = jarFile.getJarEntry(ADMIN_POM_PROPS_ENTRY);
            if (propsEntry == null) {
                throw new IllegalStateException("admin jar 缺 " + ADMIN_POM_PROPS_ENTRY
                        + ",疑似非标准构建产物: " + jar);
            }
            Properties props = new Properties();
            try (InputStream in = jarFile.getInputStream(propsEntry)) {
                props.load(in);
            }
            actual = props.getProperty("version");
            if (actual == null) {
                throw new IllegalStateException("admin jar pom.properties 无 version 键: " + jar);
            }
        } catch (IOException e) {
            throw new IllegalStateException("admin jar 读取失败: " + jar, e);
        }
        if (!expectedVer.equals(actual)) {
            throw new IllegalStateException("admin 版本与桥接不一致(版本一对一):来源=" + sourceLabel
                    + " 期望=" + expectedVer + " 实际=" + actual + ",jar=" + jar);
        }
    }

    /**
     * 自身 jar 物理路径定位(三分支判据):①file: 协议且指向 jar 文件→直接用之;
     * ②jar: 协议(生产形态,core 经 LoadJarUtils 以 jar: URL addURL 装载集成)→解出物理路径;
     * ③其余(file: 指向目录/其他协议)=开发态(IDE classes 目录运行),无嵌入载荷可读。
     * ②解出路径的存在性由「类刚从该 jar 加载出来」的装载事实保证,不加二次文件校验。
     */
    private static String locateSelfJar(Class<?> anchor) {
        URL location = anchor.getProtectionDomain().getCodeSource().getLocation();
        if ("file".equals(location.getProtocol())) {
            try {
                File file = new File(location.toURI());
                if (file.isFile()) {
                    return file.getAbsolutePath();
                }
            } catch (java.net.URISyntaxException e) {
                throw new IllegalStateException("自身代码源 file: URL 无法转路径: " + location, e);
            }
            throw devModeException(location);
        }
        if ("jar".equals(location.getProtocol())) {
            return extractJarFilePath(location.toString());
        }
        throw devModeException(location);
    }

    /**
     * jar: URL 解物理路径(约 3 行,桥接仓自实现,禁跨仓 import JarTools——跨仓 import=
     * 桥接 pom 新增 compile 依赖触发 yml 声明规则):剥 jar: 前缀、剥 file: 前缀、
     * 第一个 !/ 截断、URLDecoder.decode(与 ecat-adapter-ruoyi JarTools.extractJarFilePath 同法)。
     */
    private static String extractJarFilePath(String jarUrl) {
        String path = jarUrl.substring("jar:".length());
        if (path.startsWith("file:")) {
            path = path.substring("file:".length());
        }
        int bangSlash = path.indexOf("!/");
        if (bangSlash >= 0) {
            path = path.substring(0, bangSlash);
        }
        try {
            return URLDecoder.decode(path, "UTF-8");
        } catch (UnsupportedEncodingException e) {
            throw new IllegalStateException("UTF-8 解码不可用(运行环境异常)", e);
        }
    }

    private static IllegalStateException devModeException(Object location) {
        return new IllegalStateException("开发态无嵌入载荷可读(代码源=" + location
                + "):配置 ruoyi_admin_jar_path 指向本地 admin 件(存量实例即此用法)");
    }
}
