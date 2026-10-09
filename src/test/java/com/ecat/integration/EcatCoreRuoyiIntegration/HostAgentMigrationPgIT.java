package com.ecat.integration.EcatCoreRuoyiIntegration;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.spy;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintWriter;
import java.lang.reflect.Field;
import java.net.URL;
import java.net.URLClassLoader;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.SQLFeatureNotSupportedException;
import java.sql.Statement;
import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.jar.JarEntry;
import java.util.jar.JarOutputStream;
import java.util.logging.Logger;

import javax.sql.DataSource;

import org.junit.Assume;
import org.junit.ClassRule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;

import com.ecat.core.Integration.IntegrationBase;
import com.ecat.integration.EcatDbMigration.DbMigrationFacade;
import com.ecat.integration.EcatDbMigration.dto.HistoryRow;

/**
 * 宿主代理迁移真库 IT(T-5-9 §5 先迁后装):伪租户 jar(带 db/migration-&lt;测试域&gt;/V4.0.0__init.sql
 * 建表脚本)的哑租户对象 → 宿主 loadJarAndVue → 断言表已在测试 PG、账本两态指纹齐、且
 * 「迁移先于装载」(装载替身被调的瞬间表必须已存在=可观测序);无目录租户直接装载零迁移;
 * target==this 自守卫不经租户路径。
 *
 * <p>三重门控(同 DbMigrationFacadePgIT 形态):-Decat.e2e=true 且 PG 环境变量齐
 * (PGHOST/PGPORT/PGDATABASE/PGUSER)且 test classpath 有 postgresql 驱动,三条件齐才执行,
 * 默认(mvn test)恒跳过。用例各自建独立 schema(用例间零共享),用毕 DROP CASCADE。</p>
 *
 * <p>哑租户经 child-first 加载器从 fixture jar 装载(父链=test classpath 供 IntegrationBase
 * 等超类;先查自身 jar 防父加载器的 test-classes 目录副本抢先返回目录形态类),其
 * protectionDomain 代码源即 fixture jar 本体,与生产「租户类在租户 jar 内」同构。</p>
 */
public class HostAgentMigrationPgIT {

    /** fixture jar 落盘目录(规则收尾整树清理)。 */
    @ClassRule
    public static final TemporaryFolder WORK = new TemporaryFolder();

    /** 哑租户(带域):仅作 target 载体,零业务成员。 */
    public static class DomainTenant extends IntegrationBase {

        @Override
        public void onInit() {
        }

        @Override
        public void onStart() {
        }

        @Override
        public void onPause() {
        }
    }

    /** 哑租户(无目录):模拟纯协议集成/冻结族。 */
    public static class NoDomainTenant extends IntegrationBase {

        @Override
        public void onInit() {
        }

        @Override
        public void onStart() {
        }

        @Override
        public void onPause() {
        }
    }

    @Test
    public void tenantWithDomain_migratedBeforeLoad_twoStateLedgerFingerprint() throws Exception {
        assumePgReady();
        String schema = "ruoyi_it_" + UUID.randomUUID().toString().replace("-", "");
        Map<String, String> entries = Collections.singletonMap(
                "db/migration-pghostit/V4.0.0__init.sql",
                "CREATE TABLE pghostit_items (id INTEGER PRIMARY KEY);");
        TenantJarRef ref = openTenantJar(WORK.getRoot(), "pghostit-tenant.jar", DomainTenant.class, entries);
        try (Connection bootstrap = bootstrapConnection();
                Statement stmt = bootstrap.createStatement()) {
            stmt.execute("CREATE SCHEMA " + schema);
            try {
                DataSource ds = dataSource(schema);
                HostFixture fixture = hostWithReadyBridge(ds,
                        Collections.singletonList("pghostit_items"));

                assertFalse("前置:迁移前表必须缺(证明迁移确由本调用发生)",
                        DbMigrationFacade.missingTables(ds,
                                Collections.singletonList("pghostit_items")).isEmpty());

                fixture.integration.loadJarAndVue(mock(URLClassLoader.class), ref.tenant());

                assertTrue("装载替身应被调(租户已装载)", fixture.loaded);
                assertTrue("表应在库(V4.0.0 已生效)",
                        DbMigrationFacade.missingTables(ds,
                                Collections.singletonList("pghostit_items")).isEmpty());
                List<HistoryRow> rows = fullHistory("pghostit", ds, ref.tenant().getClass());
                assertEquals("空库两态账本恰 2 行(BASELINE@0+SUCCESS@4.0.0),实际=" + summarize(rows),
                        2, rows.size());
                assertEquals("BASELINE", rowWithVersion(rows, "0").getState());
                assertEquals("SUCCESS", rowWithVersion(rows, "4.0.0").getState());
            } finally {
                stmt.execute("DROP SCHEMA " + schema + " CASCADE");
            }
        } finally {
            ref.close();
        }
    }

    @Test
    public void tenantWithoutDomain_loadsWithoutAnyMigration() throws Exception {
        assumePgReady();
        String schema = "ruoyi_it_" + UUID.randomUUID().toString().replace("-", "");
        TenantJarRef ref = openTenantJar(WORK.getRoot(), "nodomain-tenant.jar",
                NoDomainTenant.class, Collections.<String, String>emptyMap());
        try (Connection bootstrap = bootstrapConnection();
                Statement stmt = bootstrap.createStatement()) {
            stmt.execute("CREATE SCHEMA " + schema);
            try {
                DataSource ds = dataSource(schema);
                HostFixture fixture = hostWithReadyBridge(ds, Collections.<String>emptyList());

                fixture.integration.loadJarAndVue(mock(URLClassLoader.class), ref.tenant());

                assertTrue("无目录租户应直接装载", fixture.loaded);
                assertEquals("无目录租户零迁移:库内不得出现任何域账本表", 0, historyTableCount(schema));
            } finally {
                stmt.execute("DROP SCHEMA " + schema + " CASCADE");
            }
        } finally {
            ref.close();
        }
    }

    @Test
    public void selfTarget_bypassesTenantMigrationPath() throws Exception {
        assumePgReady();
        String schema = "ruoyi_it_" + UUID.randomUUID().toString().replace("-", "");
        try (Connection bootstrap = bootstrapConnection();
                Statement stmt = bootstrap.createStatement()) {
            stmt.execute("CREATE SCHEMA " + schema);
            try {
                DataSource ds = dataSource(schema);
                HostFixture fixture = hostWithReadyBridge(ds, Collections.<String>emptyList());

                fixture.integration.loadJarAndVue(mock(URLClassLoader.class), fixture.integration);

                assertTrue("自守卫下自身对象照常走装载面", fixture.loaded);
                assertEquals("自守卫零迁移:宿主自身不得经租户路径扫出域(防同锚双跑)",
                        0, historyTableCount(schema));
            } finally {
                stmt.execute("DROP SCHEMA " + schema + " CASCADE");
            }
        }
    }

    // ---------- 宿主装配(桥就绪运行态注入 + 装载替身观测) ----------

    /** 桥就绪宿主与其装载替身的成对持有:loaded=装载动作已发生旗标。 */
    private static final class HostFixture {

        private final EcatCoreRuoyiIntegration integration;
        private boolean loaded;

        private HostFixture(EcatCoreRuoyiIntegration integration) {
            this.integration = integration;
        }
    }

    /**
     * 造桥就绪宿主:spy 定向桩 getSpringBean(DataSource) 返回真库 DS;ruoyiJarApp 替身的
     * loadJarAndVue 在「被调瞬间」断言探针表已存在(先迁后装=可观测序)并置 loaded 旗标。
     * probeTables 传空清单=不做表断言(无目录租户/自守卫用例)。
     */
    private HostFixture hostWithReadyBridge(DataSource ds, List<String> probeTables) throws Exception {
        final DataSource liveDs = ds;
        final List<String> probes = probeTables;
        final HostFixture fixture = new HostFixture(integrationSpy(ds));
        RuoyiJarApp app = mock(RuoyiJarApp.class);
        doAnswer(invocation -> {
            if (!probes.isEmpty()) {
                assertTrue("装载瞬间表必须已存在(先迁后装),缺失表="
                                + DbMigrationFacade.missingTables(liveDs, probes),
                        DbMigrationFacade.missingTables(liveDs, probes).isEmpty());
            }
            fixture.loaded = true;
            return null;
        }).when(app).loadJarAndVue(any(URLClassLoader.class), any(IntegrationBase.class));
        setField(fixture.integration, "isRuoyiStarted", true);
        setField(fixture.integration, "ruoyiJarApp", app);
        return fixture;
    }

    private EcatCoreRuoyiIntegration integrationSpy(DataSource ds) {
        EcatCoreRuoyiIntegration integration = spy(new EcatCoreRuoyiIntegration());
        doReturn(ds).when(integration).getSpringBean(DataSource.class);
        return integration;
    }

    // ---------- fixture jar(child-first 加载器) ----------

    /** fixture jar 与其哑租户成对持有:close 归还加载器句柄(迁移场景须保持 open 至扫描完毕)。 */
    private static final class TenantJarRef {

        private final URLClassLoader loader;
        private final IntegrationBase tenant;

        private TenantJarRef(URLClassLoader loader, IntegrationBase tenant) {
            this.loader = loader;
            this.tenant = tenant;
        }

        IntegrationBase tenant() {
            return tenant;
        }

        void close() throws IOException {
            loader.close();
        }
    }

    private TenantJarRef openTenantJar(File dir, String jarName, Class<? extends IntegrationBase> tenantClass,
            Map<String, String> entries) throws IOException {
        File jarFile = new File(dir, jarName);
        try (JarOutputStream out = new JarOutputStream(new FileOutputStream(jarFile))) {
            writeEntry(out, classEntryPath(tenantClass), classBytes(tenantClass));
            for (Map.Entry<String, String> entry : entries.entrySet()) {
                writeEntry(out, entry.getKey(), entry.getValue().getBytes(StandardCharsets.UTF_8));
            }
        }
        final ClassLoader testParent = HostAgentMigrationPgIT.class.getClassLoader();
        URLClassLoader loader = new URLClassLoader(new URL[]{jarFile.toURI().toURL()}, null) {
            @Override
            protected Class<?> loadClass(String name, boolean resolve) throws ClassNotFoundException {
                // child-first:先查自身 fixture jar(租户类代码源=jar 本体),父链只兜超类依赖;
                // 直用父链会命中 test-classes 目录副本,破坏「租户类在租户 jar 内」同构前提
                synchronized (getClassLoadingLock(name)) {
                    Class<?> c = findLoadedClass(name);
                    if (c == null) {
                        try {
                            c = findClass(name);
                        } catch (ClassNotFoundException e) {
                            c = testParent.loadClass(name);
                        }
                    }
                    if (resolve) {
                        resolveClass(c);
                    }
                    return c;
                }
            }
        };
        try {
            Class<?> tenantRuntimeClass = Class.forName(tenantClass.getName(), false, loader);
            IntegrationBase tenant = (IntegrationBase) tenantRuntimeClass.getDeclaredConstructor().newInstance();
            return new TenantJarRef(loader, tenant);
        } catch (ReflectiveOperationException e) {
            loader.close();
            throw new IllegalStateException("fixture jar 内哑租户装载失败: " + jarFile, e);
        }
    }

    private static String classEntryPath(Class<?> type) {
        return type.getName().replace('.', '/') + ".class";
    }

    private static byte[] classBytes(Class<?> type) throws IOException {
        try (InputStream in = type.getResourceAsStream("/" + classEntryPath(type))) {
            if (in == null) {
                throw new IllegalStateException("测试 classpath 找不到哑租户编译产物: " + classEntryPath(type));
            }
            ByteArrayOutputStream buffer = new ByteArrayOutputStream();
            byte[] chunk = new byte[4096];
            int read;
            while ((read = in.read(chunk)) >= 0) {
                buffer.write(chunk, 0, read);
            }
            return buffer.toByteArray();
        }
    }

    private static void writeEntry(JarOutputStream out, String path, byte[] bytes) throws IOException {
        out.putNextEntry(new JarEntry(path));
        out.write(bytes);
        out.closeEntry();
    }

    private static void setField(Object target, String fieldName, Object value)
            throws IllegalAccessException, NoSuchFieldException {
        Field field = EcatCoreRuoyiIntegration.class.getDeclaredField(fieldName);
        field.setAccessible(true);
        field.set(target, value);
    }

    // ---------- 三重门控与 PG 基建(同 DbMigrationFacadePgIT 形态) ----------

    private static void assumePgReady() {
        Assume.assumeTrue("未开启 e2e 门(-Decat.e2e=true 才执行真库 IT),默认跳过",
                "true".equals(System.getProperty("ecat.e2e")));
        Assume.assumeTrue("PG 连接环境变量未齐(PGHOST/PGPORT/PGDATABASE/PGUSER),跳过",
                env("PGHOST") != null && env("PGPORT") != null
                        && env("PGDATABASE") != null && env("PGUSER") != null);
        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
            Assume.assumeTrue("test classpath 无 postgresql JDBC 驱动,跳过", false);
        }
    }

    private static String env(String name) {
        String value = System.getenv(name);
        return value == null || value.isEmpty() ? null : value;
    }

    private static Connection bootstrapConnection() throws SQLException {
        return DriverManager.getConnection(
                "jdbc:postgresql://" + env("PGHOST") + ":" + env("PGPORT") + "/" + env("PGDATABASE"),
                env("PGUSER"), System.getenv("PGPASSWORD"));
    }

    private static DataSource dataSource(String schema) {
        final String url = "jdbc:postgresql://" + env("PGHOST") + ":" + env("PGPORT") + "/" + env("PGDATABASE")
                + "?currentSchema=" + schema;
        final String user = env("PGUSER");
        final String password = System.getenv("PGPASSWORD");
        return new DataSource() {
            @Override
            public Connection getConnection() throws SQLException {
                return DriverManager.getConnection(url, user, password);
            }

            @Override
            public Connection getConnection(String username, String pwd) throws SQLException {
                return DriverManager.getConnection(url, username, pwd);
            }

            @Override
            public <T> T unwrap(Class<T> iface) throws SQLException {
                throw new SQLException("不支持 unwrap");
            }

            @Override
            public boolean isWrapperFor(Class<?> iface) {
                return false;
            }

            @Override
            public PrintWriter getLogWriter() {
                return null;
            }

            @Override
            public void setLogWriter(PrintWriter out) {
            }

            @Override
            public void setLoginTimeout(int seconds) {
                DriverManager.setLoginTimeout(seconds);
            }

            @Override
            public int getLoginTimeout() {
                return DriverManager.getLoginTimeout();
            }

            @Override
            public Logger getParentLogger() throws SQLFeatureNotSupportedException {
                throw new SQLFeatureNotSupportedException("无 java.util.logging 父 logger");
            }
        };
    }

    /** 数本 schema 内全部域账本表(flyway_schema_history%):零迁移=0。 */
    private int historyTableCount(String schema) throws SQLException {
        Set<String> names = new LinkedHashSet<>();
        try (Connection connection = bootstrapConnection();
                PreparedStatement ps = connection.prepareStatement(
                        "SELECT table_name FROM information_schema.tables "
                                + "WHERE table_schema=? AND table_name LIKE 'flyway\\_schema\\_history%'")) {
            ps.setString(1, schema);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    names.add(rs.getString(1));
                }
            }
        }
        return names.size();
    }

    private List<HistoryRow> fullHistory(String domain, DataSource ds, Class<?> anchor) {
        return DbMigrationFacade.history(domain, ds,
                Collections.singletonList("classpath:db/migration-" + domain), anchor);
    }

    private HistoryRow rowWithVersion(List<HistoryRow> rows, String version) {
        for (HistoryRow row : rows) {
            if (version.equals(row.getVersion())) {
                return row;
            }
        }
        throw new AssertionError("期望存在 version=" + version + " 的行,实际行集=" + summarize(rows));
    }

    private String summarize(List<HistoryRow> rows) {
        StringBuilder sb = new StringBuilder("[");
        for (HistoryRow row : rows) {
            sb.append(row.getState()).append(':').append(row.getVersion())
                    .append("(rank=").append(row.getInstalledRank()).append(") ");
        }
        return sb.append("]").toString();
    }
}
