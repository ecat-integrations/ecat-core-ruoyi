package com.ecat.integration.EcatCoreRuoyiIntegration;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.jar.JarOutputStream;
import java.util.jar.Manifest;

import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;

/**
 * 嵌读入口机制单测(设计 §7.2 T8+T9):startNested 构建缺陷第二道门+二层嵌套类加载机制锚。
 * 夹具逐层组装:外层 jar 载荷条目 STORED→迷你 fat jar(BOOT-INF/classes+BOOT-INF/lib,
 * lib 条目 STORED)——STORED 写法本身即「Deflated 嵌套条目不可随机访问」的回归锚。
 * 全内存零 sleep 零 mock:纯 JDK+spring-boot-loader(桥接 lib 既有)。
 */
public class RuoyiJarAppNestedTest {

    private static final String APP_STUB = "NestedAppStub";
    private static final String LIB_STUB = "NestedLibStub";
    private static final String APP_SOURCE = "public class NestedAppStub {\n"
            + "    public static void main(String[] args) {\n"
            + "    }\n"
            + "}\n";
    private static final String LIB_SOURCE = "public class NestedLibStub {\n"
            + "    public static void main(String[] args) {\n"
            + "    }\n"
            + "}\n";
    private static final String PAYLOAD_ENTRY = "payload/ruoyi-admin-9.9.9-test.jar";

    @Rule
    public TemporaryFolder tmp = new TemporaryFolder();

    /** T8:startNested 对零命中条目 → ISE(嵌读入口第二道构建缺陷门)。 */
    @Test
    public void t8_startNested_missingEntry_throws() throws Exception {
        Path outer = outerFixtureWithPayload(PAYLOAD_ENTRY);
        try {
            new RuoyiJarApp().startNested(outer.toAbsolutePath().toString(),
                    "payload/ruoyi-admin-not-exist.jar", new String[0]);
            fail("应抛 IllegalStateException");
        } catch (IllegalStateException e) {
            assertTrue(e.getMessage().contains("无嵌入载荷条目"));
        }
    }

    /** T9(核心机制锚):外层 jar 内嵌 STORED 迷你 fat jar(BOOT-INF/classes 一类+
     *  BOOT-INF/lib 一迷你 jar 一类),经 startNested 同款路径加载两类。 */
    @Test
    public void t9_startNested_twoLevelClassLoading() throws Exception {
        Path dir = tmp.getRoot().toPath();
        byte[] appStub = RuoyiAdminResolverTest.compileStub(APP_STUB, APP_SOURCE, dir);
        byte[] libStub = RuoyiAdminResolverTest.compileStub(LIB_STUB, LIB_SOURCE, dir);

        byte[] innerLib = RuoyiAdminResolverTest.miniJar(LIB_STUB + ".class", libStub, false);
        byte[] miniFat = miniFatJar(appStub, innerLib);
        Path outer = outerFixture(PAYLOAD_ENTRY, miniFat);

        RuoyiJarApp app = new RuoyiJarApp();
        ClassLoader loader = app.startNested(outer.toAbsolutePath().toString(),
                PAYLOAD_ENTRY, new String[0]);

        Class<?> appClass = loader.loadClass(APP_STUB);
        Class<?> libClass = loader.loadClass(LIB_STUB);
        assertNotNull(appClass);
        assertNotNull(libClass);
        assertEquals(loader, appClass.getClassLoader());
        assertEquals(loader, libClass.getClassLoader());

        // CodeSource=嵌套 URL(jar:file:外层!/payload/...!/BOOT-INF/... 三层链)
        String appLocation = appClass.getProtectionDomain().getCodeSource().getLocation().toString();
        String libLocation = libClass.getProtectionDomain().getCodeSource().getLocation().toString();
        assertTrue("AppStub CodeSource 应为嵌套 URL: " + appLocation,
                appLocation.startsWith("jar:file:") && appLocation.contains(PAYLOAD_ENTRY));
        assertTrue("LibStub CodeSource 应为嵌套 URL: " + libLocation,
                libLocation.startsWith("jar:file:") && libLocation.contains("BOOT-INF/lib/libstub.jar"));
    }

    /** 迷你 fat jar:MANIFEST(Start-Class)+BOOT-INF/classes 目录+散类+BOOT-INF/lib jar(STORED)。 */
    static byte[] miniFatJar(byte[] appStubBytes, byte[] libJarBytes) throws Exception {
        Manifest manifest = new Manifest();
        manifest.getMainAttributes().putValue("Manifest-Version", "1.0");
        manifest.getMainAttributes().putValue("Start-Class", APP_STUB);
        ByteArrayOutputStream manifestBytes = new ByteArrayOutputStream();
        manifest.write(manifestBytes);

        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        try (JarOutputStream out = new JarOutputStream(bos)) {
            RuoyiAdminResolverTest.putEntry(out, "META-INF/MANIFEST.MF",
                    manifestBytes.toByteArray(), false);
            RuoyiAdminResolverTest.putEntry(out, "BOOT-INF/classes/", new byte[0], false);
            RuoyiAdminResolverTest.putEntry(out, "BOOT-INF/classes/" + APP_STUB + ".class",
                    appStubBytes, false);
            RuoyiAdminResolverTest.putEntry(out, "BOOT-INF/lib/libstub.jar", libJarBytes, true);
        }
        return bos.toByteArray();
    }

    private Path outerFixtureWithPayload(String payloadEntry) throws Exception {
        byte[] payload = RuoyiAdminResolverTest.miniJar("placeholder", "placeholder".getBytes("UTF-8"), false);
        return outerFixture(payloadEntry, payload);
    }

    /** 外层桥接夹具:载荷条目 STORED(嵌套随机访问硬前提)。 */
    private Path outerFixture(String payloadEntry, byte[] payloadBytes) throws Exception {
        Path outer = new File(tmp.getRoot(), "bridge-fixture.jar").toPath();
        try (JarOutputStream out = new JarOutputStream(new FileOutputStream(outer.toFile()))) {
            RuoyiAdminResolverTest.putEntry(out, payloadEntry, payloadBytes, true);
        }
        if (!Files.exists(outer)) {
            throw new IllegalStateException("外层夹具未生成: " + outer);
        }
        return outer;
    }
}
