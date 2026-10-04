package com.ecat.integration.EcatCoreRuoyiIntegration;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.net.URLClassLoader;
import java.net.URLDecoder;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.HashMap;
import java.util.Map;
import java.util.jar.JarOutputStream;
import java.util.zip.CRC32;
import java.util.zip.ZipEntry;

import javax.tools.JavaCompiler;
import javax.tools.ToolProvider;

import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;

/**
 * 定位决策表单测族(设计 §7.2 T0~T7+T10+T11):全内存零 sleep 零 mock,
 * 夹具=测试内 JarOutputStream 造 jar。嵌套夹具载荷条目必须 STORED——
 * Deflated 嵌套条目不可随机访问,夹具写法本身就是 Stored 前提的回归锚。
 */
public class RuoyiAdminResolverTest {

    private static final String STUB_NAME = "BridgeAnchorStub";
    private static final String STUB_SOURCE = "public class BridgeAnchorStub {\n"
            + "    public static void main(String[] args) {\n"
            + "    }\n"
            + "}\n";
    private static final String POM_PROPS_ENTRY = "META-INF/maven/com.ecat/ruoyi-admin/pom.properties";
    private static final String PAYLOAD_ENTRY = "payload/ruoyi-admin-4.0.0-test.jar";

    @Rule
    public TemporaryFolder tmp = new TemporaryFolder();

    /** T0:无 manifest 版本的类(test-classes 目录加载,包无 Implementation-Version)→ ISE。 */
    @Test
    public void t0_readBridgeVersion_missingManifestVersion_throws() {
        try {
            RuoyiAdminResolver.readBridgeVersion(RuoyiAdminResolverTest.class);
            fail("应抛 IllegalStateException");
        } catch (IllegalStateException e) {
            assertTrue(e.getMessage().contains("Implementation-Version"));
        }
    }

    /** T1:D1 用户路径=版本 X 的 jar,桥接版本 X → USER_FILE 该路径。 */
    @Test
    public void t1_userPath_matchingVersion_returnsUserFile() throws Exception {
        Path adminJar = adminJarWithVersion("X");
        AdminLocation loc = RuoyiAdminResolver.resolve(RuoyiAdminResolverTest.class,
                adminJar.toString(), "X");
        assertEquals(AdminLocation.Mode.USER_FILE, loc.getMode());
        assertEquals(adminJar.toAbsolutePath().toString(), loc.getFilePath());
    }

    /** T2:D1 用户路径文件不存在 → ISE 含路径,不回退嵌读(负向)。 */
    @Test
    public void t2_userPath_notExists_throwsWithoutFallback() {
        Path missing = tmp.getRoot().toPath().resolve("no-such-admin.jar");
        try {
            RuoyiAdminResolver.resolve(RuoyiAdminResolverTest.class, missing.toString(), "X");
            fail("应抛 IllegalStateException");
        } catch (IllegalStateException e) {
            assertTrue(e.getMessage().contains(missing.toString()));
            assertTrue(e.getMessage().contains("不回退嵌读"));
        }
    }

    /** T3:D1 用户路径=版本 Y 的 jar → ISE 含两版本+来源标签(串包门负向:门有牙)。 */
    @Test
    public void t3_userPath_versionMismatch_throws() throws Exception {
        Path adminJar = adminJarWithVersion("Y");
        try {
            RuoyiAdminResolver.resolve(RuoyiAdminResolverTest.class, adminJar.toString(), "X");
            fail("应抛 IllegalStateException");
        } catch (IllegalStateException e) {
            assertTrue(e.getMessage().contains("用户指定路径"));
            assertTrue(e.getMessage().contains("X"));
            assertTrue(e.getMessage().contains("Y"));
        }
    }

    /** T4:D1 用户路径=无 pom.properties 的 jar → ISE 含「非标准构建产物」。 */
    @Test
    public void t4_userPath_missingPomProps_throws() throws Exception {
        Path adminJar = tmp.newFile("bare-admin.jar").toPath();
        try (JarOutputStream out = new JarOutputStream(new FileOutputStream(adminJar.toFile()))) {
            putEntry(out, "Dummy.class", STUB_SOURCE.getBytes("UTF-8"), false);
        }
        try {
            RuoyiAdminResolver.resolve(RuoyiAdminResolverTest.class, adminJar.toString(), "X");
            fail("应抛 IllegalStateException");
        } catch (IllegalStateException e) {
            assertTrue(e.getMessage().contains("非标准构建产物"));
        }
    }

    /** T5:D2' 未指定+桥接 jar 夹具含正确版本名载荷条目(file: 形态)→ NESTED_ENTRY+精确条目名。 */
    @Test
    public void t5_nestedLocation_fileCodeSource_returnsNestedEntry() throws Exception {
        Path fixture = bridgeFixture(PAYLOAD_ENTRY, tmp.getRoot().toPath());
        Class<?> stub = loadStubFromFileUrl(fixture);
        try {
            AdminLocation loc = RuoyiAdminResolver.resolve(stub, null, "4.0.0-test");
            assertEquals(AdminLocation.Mode.NESTED_ENTRY, loc.getMode());
            assertEquals(fixture.toAbsolutePath().toString(), loc.getBridgeJarPath());
            assertEquals(PAYLOAD_ENTRY, loc.getAdminEntryName());
        } finally {
            closeLoader(stub);
        }
    }

    /** T5b:D2'② 生产形态回归锚——jar: 协议 CodeSource(镜像 LoadJarUtils addURL 形态)。
     *  替身类只在夹具 jar 内(编译进临时目录,不在测试 classpath),父加载器不可命中。 */
    @Test
    public void t5b_nestedLocation_jarCodeSource_decodesPhysicalPath() throws Exception {
        Path dir = tmp.newFolder("锚 点夹具").toPath();
        Path fixture = bridgeFixture(PAYLOAD_ENTRY, dir);
        URLClassLoader loader = new URLClassLoader(new URL[0], getClass().getClassLoader());
        java.lang.reflect.Method addURL = URLClassLoader.class.getDeclaredMethod("addURL", URL.class);
        addURL.setAccessible(true);
        addURL.invoke(loader, new URL("jar:file:" + fixture.toAbsolutePath() + "!/"));
        Class<?> stub = loader.loadClass(STUB_NAME);
        try {
            AdminLocation loc = RuoyiAdminResolver.resolve(stub, null, "4.0.0-test");
            assertEquals(AdminLocation.Mode.NESTED_ENTRY, loc.getMode());
            assertEquals(URLDecoder.decode(fixture.toAbsolutePath().toString(), "UTF-8"),
                    loc.getBridgeJarPath());
        } finally {
            loader.close();
        }
    }

    /** T6:D2' 未指定+夹具条目名版本错(仅 payload/ruoyi-admin-{Y}.jar)→ ISE 含「构建缺陷」
     *  (精确名 miss=版本门拦截负向)。 */
    @Test
    public void t6_nestedLocation_wrongVersionEntry_throws() throws Exception {
        Path fixture = bridgeFixture("payload/ruoyi-admin-9.9.9.jar", tmp.getRoot().toPath());
        Class<?> stub = loadStubFromFileUrl(fixture);
        try {
            RuoyiAdminResolver.resolve(stub, null, "4.0.0-test");
            fail("应抛 IllegalStateException");
        } catch (IllegalStateException e) {
            assertTrue(e.getMessage().contains("构建缺陷"));
            assertTrue(e.getMessage().contains("payload/ruoyi-admin-4.0.0-test.jar"));
        }
    }

    /** T7:D2' anchor 用 test-classes 目录类(非 jar 载体)+未指定路径 → ISE 提示配用户路径(负向)。 */
    @Test
    public void t7_directoryCodeSource_devMode_throwsWithHint() {
        try {
            RuoyiAdminResolver.resolve(RuoyiAdminResolverTest.class, null, "X");
            fail("应抛 IllegalStateException");
        } catch (IllegalStateException e) {
            assertTrue(e.getMessage().contains("ruoyi_admin_jar_path"));
        }
    }

    /** T10:resolve 返回后测试目录零新增文件、既有文件字节不变(零写盘不变量回归锚)。 */
    @Test
    public void t10_resolve_writesNothing() throws Exception {
        Path fixture = bridgeFixture(PAYLOAD_ENTRY, tmp.getRoot().toPath());
        Map<String, String> before = snapshot(tmp.getRoot().toPath());
        Class<?> stub = loadStubFromFileUrl(fixture);
        try {
            RuoyiAdminResolver.resolve(stub, null, "4.0.0-test");
        } finally {
            closeLoader(stub);
        }
        assertEquals(before, snapshot(tmp.getRoot().toPath()));
    }

    /** T11:resolve 返回后桥接 jar 夹具文件字节不变(嵌读只读不写,负向)。 */
    @Test
    public void t11_resolve_doesNotTouchFixture() throws Exception {
        Path fixture = bridgeFixture(PAYLOAD_ENTRY, tmp.getRoot().toPath());
        byte[] before = Files.readAllBytes(fixture);
        Class<?> stub = loadStubFromFileUrl(fixture);
        try {
            RuoyiAdminResolver.resolve(stub, null, "4.0.0-test");
        } finally {
            closeLoader(stub);
        }
        assertTrue(java.util.Arrays.equals(before, Files.readAllBytes(fixture)));
    }

    // ---------- 夹具与辅助 ----------

    /** 版本 X/Y 的 admin 件(含 pom.properties+哑类条目)。 */
    private Path adminJarWithVersion(String version) throws IOException {
        Path jar = tmp.newFile("admin-" + version + ".jar").toPath();
        try (JarOutputStream out = new JarOutputStream(new FileOutputStream(jar.toFile()))) {
            putEntry(out, POM_PROPS_ENTRY,
                    ("version=" + version + "\n").getBytes("UTF-8"), false);
            putEntry(out, "Dummy.class", STUB_SOURCE.getBytes("UTF-8"), false);
        }
        return jar;
    }

    /** 桥接 jar 夹具:替身类在根 + 载荷条目(STORED,载荷=一层迷你 jar 字节)。 */
    private Path bridgeFixture(String payloadEntryName, Path dir) throws IOException {
        byte[] stubBytes = compileStub(STUB_NAME, STUB_SOURCE, dir);
        byte[] payload = miniJar("placeholder-entry", "placeholder".getBytes("UTF-8"), false);
        Path fixture = dir.resolve("bridge-fixture.jar");
        try (JarOutputStream out = new JarOutputStream(new FileOutputStream(fixture.toFile()))) {
            putEntry(out, STUB_NAME + ".class", stubBytes, false);
            putEntry(out, payloadEntryName, payload, true);
        }
        return fixture;
    }

    /** 替身类经 file: URL 加载器从夹具装出(父加载器无此类,不产生双亲委派污染)。 */
    private Class<?> loadStubFromFileUrl(Path fixture) throws Exception {
        URLClassLoader loader = new URLClassLoader(
                new URL[] { fixture.toUri().toURL() }, getClass().getClassLoader());
        return loader.loadClass(STUB_NAME);
    }

    private void closeLoader(Class<?> loaded) throws Exception {
        ClassLoader loader = loaded.getClassLoader();
        if (loader instanceof URLClassLoader) {
            ((URLClassLoader) loader).close();
        }
    }

    /** 测试桩编译(替身类绝不进测试 classpath,落临时目录)。 */
    static byte[] compileStub(String className, String source, Path dir) throws IOException {
        JavaCompiler compiler = ToolProvider.getSystemJavaCompiler();
        if (compiler == null) {
            throw new IllegalStateException("测试环境无系统 JavaCompiler(须 JDK 运行单测)");
        }
        Path src = dir.resolve(className + ".java");
        Files.write(src, source.getBytes("UTF-8"));
        int rc = compiler.run(null, null, null, "-d", dir.toString(), src.toString());
        if (rc != 0) {
            throw new IllegalStateException("测试桩编译失败: " + className);
        }
        return Files.readAllBytes(dir.resolve(className + ".class"));
    }

    /** 写 jar 条目;stored=true 时 setMethod+size+CRC(JarOutputStream 对 STORED 的硬要求)。 */
    static void putEntry(JarOutputStream out, String name, byte[] bytes, boolean stored)
            throws IOException {
        ZipEntry entry = new ZipEntry(name);
        if (stored) {
            CRC32 crc = new CRC32();
            crc.update(bytes);
            entry.setMethod(ZipEntry.STORED);
            entry.setSize(bytes.length);
            entry.setCrc(crc.getValue());
        }
        out.putNextEntry(entry);
        out.write(bytes);
        out.closeEntry();
    }

    /** 迷你 jar 字节(可含 STORED 条目,供嵌套夹具逐层组装)。 */
    static byte[] miniJar(String entryName, byte[] entryBytes, boolean stored) throws IOException {
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        try (JarOutputStream out = new JarOutputStream(bos)) {
            putEntry(out, entryName, entryBytes, stored);
        }
        return bos.toByteArray();
    }

    static String sha256(byte[] bytes) throws Exception {
        byte[] digest = MessageDigest.getInstance("SHA-256").digest(bytes);
        StringBuilder sb = new StringBuilder();
        for (byte b : digest) {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    }

    /** 目录快照:相对路径→内容 sha256(零写盘断言用)。 */
    private static Map<String, String> snapshot(Path dir) throws Exception {
        Map<String, String> files = new HashMap<>();
        Files.walk(dir).filter(Files::isRegularFile).forEach(p -> {
            try {
                files.put(dir.relativize(p).toString(), sha256(Files.readAllBytes(p)));
            } catch (Exception e) {
                throw new IllegalStateException("快照读取失败: " + p, e);
            }
        });
        return files;
    }
}
