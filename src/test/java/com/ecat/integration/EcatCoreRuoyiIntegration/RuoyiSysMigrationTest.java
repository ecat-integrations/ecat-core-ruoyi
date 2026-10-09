package com.ecat.integration.EcatCoreRuoyiIntegration;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertSame;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.ArgumentMatchers.same;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.lang.reflect.Field;
import java.net.URLClassLoader;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import javax.sql.DataSource;

import org.junit.Test;
import org.mockito.MockedConstruction;
import org.mockito.MockedStatic;
import org.mockito.Mockito;

import com.ecat.core.Integration.IntegrationBase;
import com.ecat.core.Integration.IntegrationLoadOption;
import com.ecat.integration.EcatDbMigration.DbMigrationException;
import com.ecat.integration.EcatDbMigration.DbMigrationFacade;

/**
 * 迁移接线单测,两层覆盖:
 * 一、onStart 级(守卫真实走,不桩化 getSpringBean)——RuoyiJarApp(外部进程面)以
 * mockConstruction 替身,锁死迁移期反射桥守卫真实放行、迁移先于叶子类加载器注册、
 * 桥就绪但容器缺 DataSource Bean 时显式拒绝;
 * 二、包私有直调级——自身域执行点 runRuoyiSysMigration(入口②单调用形态,两态已内聚
 * 进 dbm 单点,由 dbm 仓测试锁定)与租户路径 loadJarAndVue(先迁后装、自守卫、失败
 * 穿透、缺 Bean 显式拒绝);resourceAnchor 资源可见性为纯静态断言。
 * 全模拟零 IO,门面静态调用经 mockStatic 打桩,测试缝=包私有 runRuoyiSysMigration
 * 与公开 loadJarAndVue。
 */
public class RuoyiSysMigrationTest {

    /**
     * 非守卫路径反射桥桩:getSpringBean(DataSource) 定向返回桩 DataSource,
     * 不触真实 Spring 容器,也不经过 onStart 的旗标/守卫时序(该时序由 onStart 级用例锁死)。
     */
    private EcatCoreRuoyiIntegration integrationReturning(DataSource ds) {
        EcatCoreRuoyiIntegration integration = spy(new EcatCoreRuoyiIntegration());
        doReturn(ds).when(integration).getSpringBean(DataSource.class);
        return integration;
    }

    /** 注入桥就绪运行态(isRuoyiStarted 旗标 + ruoyiJarApp 替身),供租户路径直调。 */
    private RuoyiJarApp readyBridge(EcatCoreRuoyiIntegration integration) {
        RuoyiJarApp app = mock(RuoyiJarApp.class);
        setPrivateField(integration, "isRuoyiStarted", true);
        setPrivateField(integration, "ruoyiJarApp", app);
        return app;
    }

    /** 反射注入私有字段(含父类声明字段,如 loadOption):测试缝,非生产语义。 */
    private static void setPrivateField(Object target, String fieldName, Object value) {
        Class<?> type = target.getClass();
        while (type != null) {
            try {
                Field field = type.getDeclaredField(fieldName);
                field.setAccessible(true);
                field.set(target, value);
                return;
            } catch (NoSuchFieldException e) {
                type = type.getSuperclass();
            } catch (IllegalAccessException e) {
                throw new IllegalStateException("测试反射注入失败: " + fieldName, e);
            }
        }
        throw new IllegalStateException("测试反射注入失败,字段不存在: " + fieldName);
    }

    /** 测试用哑租户:仅作 target 载体;门面静态调用已打桩,类代码源不参与断言。 */
    static class DummyTenant extends IntegrationBase {

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
    public void onStartMigrationExecutesWithGuardOpenAndRegistersAfter() {
        EcatCoreRuoyiIntegration integration = new EcatCoreRuoyiIntegration();
        DataSource ds = mock(DataSource.class);
        URLClassLoader fakeChildClassLoader = mock(URLClassLoader.class);
        IntegrationLoadOption loadOption = mock(IntegrationLoadOption.class);
        // T-1-10 起 onStart 条件源=定位结果(非配置路径原值);USER_FILE 形态下 start 调用形不变
        setPrivateField(integration, "adminLocation", AdminLocation.userFile("/fake/ruoyi-admin.jar"));
        setPrivateField(integration, "loadOption", loadOption);

        try (MockedConstruction<RuoyiJarApp> bridge = Mockito.mockConstruction(RuoyiJarApp.class,
                (app, context) -> {
                    // start 第二参与生产同形传 null,匹配用 isNull(anyString 不匹配 null)
                    when(app.start(anyString(), isNull(), any(String[].class)))
                            .thenReturn(fakeChildClassLoader);
                    when(app.getSpringBean(DataSource.class)).thenReturn(ds);
                });
                MockedStatic<DbMigrationFacade> facade = Mockito.mockStatic(DbMigrationFacade.class)) {
            integration.onStart();
            facade.verify(() -> DbMigrationFacade.migrateDomain(EcatCoreRuoyiIntegration.class, ds));
        }
        verify(loadOption).setChildClassLoader(fakeChildClassLoader);
    }

    @Test
    public void onStartRejectsWhenLiveContainerLacksDataSourceBean() {
        EcatCoreRuoyiIntegration integration = new EcatCoreRuoyiIntegration();
        URLClassLoader fakeChildClassLoader = mock(URLClassLoader.class);
        IntegrationLoadOption loadOption = mock(IntegrationLoadOption.class);
        // T-1-10 起 onStart 条件源=定位结果(非配置路径原值);USER_FILE 形态下 start 调用形不变
        setPrivateField(integration, "adminLocation", AdminLocation.userFile("/fake/ruoyi-admin.jar"));
        setPrivateField(integration, "loadOption", loadOption);

        try (MockedConstruction<RuoyiJarApp> bridge = Mockito.mockConstruction(RuoyiJarApp.class,
                (app, context) -> when(app.start(anyString(), isNull(), any(String[].class)))
                        .thenReturn(fakeChildClassLoader));
                MockedStatic<DbMigrationFacade> facade = Mockito.mockStatic(DbMigrationFacade.class)) {
            try {
                integration.onStart();
                fail("桥就绪但容器未提供 DataSource Bean 时 onStart 必须显式失败");
            } catch (IllegalStateException e) {
                assertTrue("消息应含 DataSource Bean 语境,实际: " + e.getMessage(),
                        e.getMessage().contains("DataSource Bean"));
                assertTrue("消息应含域名 ruoyi-sys,实际: " + e.getMessage(),
                        e.getMessage().contains("ruoyi-sys"));
            }
        }
        verify(loadOption, never()).setChildClassLoader(any(URLClassLoader.class));
    }

    @Test
    public void dataSourceMissingRejectsWithExplicitException() {
        // 直调缝·非守卫放行路径:全新实例=桥未启动,守卫关闭取不到 DataSource——
        // 锁「未就绪态必须显式拒绝,禁 null 容忍静默返回」;「桥就绪但容器缺 Bean」语境
        // 由 onStart 级用例经真实守卫覆盖(onStartRejectsWhenLiveContainerLacksDataSourceBean)
        EcatCoreRuoyiIntegration integration = new EcatCoreRuoyiIntegration();
        try {
            integration.runRuoyiSysMigration();
            fail("DataSource 缺失时 runRuoyiSysMigration 应抛 IllegalStateException");
        } catch (IllegalStateException e) {
            assertTrue("消息应含 DataSource Bean 语境,实际: " + e.getMessage(),
                    e.getMessage().contains("DataSource Bean"));
            assertTrue("消息应含域名 ruoyi-sys,实际: " + e.getMessage(),
                    e.getMessage().contains("ruoyi-sys"));
        }
    }

    @Test
    public void facadeExceptionPassesThroughUnwrapped() {
        DataSource ds = mock(DataSource.class);
        EcatCoreRuoyiIntegration integration = integrationReturning(ds);
        DbMigrationException boom = DbMigrationException.of("ruoyi-sys", "migrateDomain",
                new RuntimeException("checksum mismatch for V4.0.0__init.sql"));
        try (MockedStatic<DbMigrationFacade> facade = Mockito.mockStatic(DbMigrationFacade.class)) {
            facade.when(() -> DbMigrationFacade.migrateDomain(EcatCoreRuoyiIntegration.class, ds))
                    .thenThrow(boom);
            try {
                integration.runRuoyiSysMigration();
                fail("迁移失败必须沿执行点原样上抛");
            } catch (DbMigrationException e) {
                assertSame("引擎异常须原样穿透,禁包裹或改写", boom, e);
            }
        }
    }

    @Test
    public void migrateDomainCalledWithExactAnchorAndDataSource() {
        DataSource ds = mock(DataSource.class);
        EcatCoreRuoyiIntegration integration = integrationReturning(ds);
        try (MockedStatic<DbMigrationFacade> facade = Mockito.mockStatic(DbMigrationFacade.class)) {
            integration.runRuoyiSysMigration();
            facade.verify(() -> DbMigrationFacade.migrateDomain(EcatCoreRuoyiIntegration.class, ds));
            // 两态已内聚进 dbm 单点:宿主侧禁止残留旧原语接线(hasHistoryTable/baseline/migrate)
            facade.verify(() -> DbMigrationFacade.migrate(anyString(), any(DataSource.class),
                    any(List.class), any(Class.class)), never());
            facade.verify(() -> DbMigrationFacade.baseline(anyString(), any(DataSource.class),
                    anyString()), never());
            facade.verify(() -> DbMigrationFacade.hasHistoryTable(anyString(), any(DataSource.class)),
                    never());
        }
    }

    @Test
    public void selfTargetSkipsTenantMigrationPath() throws Exception {
        EcatCoreRuoyiIntegration integration = spy(new EcatCoreRuoyiIntegration());
        RuoyiJarApp app = readyBridge(integration);
        try (MockedStatic<DbMigrationFacade> facade = Mockito.mockStatic(DbMigrationFacade.class)) {
            integration.loadJarAndVue(mock(URLClassLoader.class), integration);
            facade.verifyNoInteractions();
        }
        verify(app).loadJarAndVue(any(URLClassLoader.class), same(integration));
    }

    @Test
    public void tenantWithoutMigrationDirectoryLoadsDirectly() throws Exception {
        EcatCoreRuoyiIntegration integration = integrationReturning(mock(DataSource.class));
        RuoyiJarApp app = readyBridge(integration);
        IntegrationBase tenant = new DummyTenant();
        try (MockedStatic<DbMigrationFacade> facade = Mockito.mockStatic(DbMigrationFacade.class)) {
            facade.when(() -> DbMigrationFacade.findMigrationDomain(DummyTenant.class)).thenReturn(null);
            integration.loadJarAndVue(mock(URLClassLoader.class), tenant);
            facade.verify(() -> DbMigrationFacade.migrateDomain(any(Class.class), any(DataSource.class)),
                    never());
        }
        verify(app).loadJarAndVue(any(URLClassLoader.class), same(tenant));
    }

    @Test
    public void tenantWithDomainMigratesBeforeLoad() throws Exception {
        EcatCoreRuoyiIntegration integration = integrationReturning(mock(DataSource.class));
        RuoyiJarApp app = readyBridge(integration);
        IntegrationBase tenant = new DummyTenant();
        List<String> order = new ArrayList<>();
        try (MockedStatic<DbMigrationFacade> facade = Mockito.mockStatic(DbMigrationFacade.class)) {
            facade.when(() -> DbMigrationFacade.findMigrationDomain(DummyTenant.class)).thenReturn("alarm-x");
            facade.when(() -> DbMigrationFacade.migrateDomain(any(Class.class), any(DataSource.class)))
                    .thenAnswer(invocation -> {
                        order.add("migrateDomain");
                        return null;
                    });
            doAnswer(invocation -> {
                order.add("load");
                return null;
            }).when(app).loadJarAndVue(any(URLClassLoader.class), same(tenant));
            integration.loadJarAndVue(mock(URLClassLoader.class), tenant);
        }
        assertEquals("先迁后装:迁移完成才发生租户装载动作", Arrays.asList("migrateDomain", "load"), order);
        verify(app).loadJarAndVue(any(URLClassLoader.class), same(tenant));
    }

    @Test
    public void tenantMigrationFailureBlocksLoadAndPropagatesRaw() throws Exception {
        EcatCoreRuoyiIntegration integration = integrationReturning(mock(DataSource.class));
        RuoyiJarApp app = readyBridge(integration);
        IntegrationBase tenant = new DummyTenant();
        DbMigrationException boom = DbMigrationException.of("alarm-x", "migrateDomain",
                new RuntimeException("V script boom"));
        try (MockedStatic<DbMigrationFacade> facade = Mockito.mockStatic(DbMigrationFacade.class)) {
            facade.when(() -> DbMigrationFacade.findMigrationDomain(DummyTenant.class)).thenReturn("alarm-x");
            facade.when(() -> DbMigrationFacade.migrateDomain(any(Class.class), any(DataSource.class)))
                    .thenThrow(boom);
            try {
                integration.loadJarAndVue(mock(URLClassLoader.class), tenant);
                fail("租户迁移失败必须原样上抛,租户不装载");
            } catch (DbMigrationException e) {
                assertSame("引擎异常须原样穿透,禁包裹或改写", boom, e);
            }
        }
        verify(app, never()).loadJarAndVue(any(URLClassLoader.class), any(IntegrationBase.class));
    }

    @Test
    public void tenantPathWithoutDataSourceBeanRejectsExplicitly() throws Exception {
        EcatCoreRuoyiIntegration integration = integrationReturning(null);
        RuoyiJarApp app = readyBridge(integration);
        IntegrationBase tenant = new DummyTenant();
        try (MockedStatic<DbMigrationFacade> facade = Mockito.mockStatic(DbMigrationFacade.class)) {
            facade.when(() -> DbMigrationFacade.findMigrationDomain(DummyTenant.class)).thenReturn("alarm-x");
            try {
                integration.loadJarAndVue(mock(URLClassLoader.class), tenant);
                fail("容器缺 DataSource Bean 时租户迁移必须显式失败,租户不装载");
            } catch (IllegalStateException e) {
                assertTrue("消息应含 DataSource Bean 语境,实际: " + e.getMessage(),
                        e.getMessage().contains("DataSource Bean"));
                assertTrue("消息应含租户域 alarm-x,实际: " + e.getMessage(),
                        e.getMessage().contains("alarm-x"));
            }
            facade.verify(() -> DbMigrationFacade.migrateDomain(any(Class.class), any(DataSource.class)),
                    never());
        }
        verify(app, never()).loadJarAndVue(any(URLClassLoader.class), any(IntegrationBase.class));
    }

    @Test
    public void migrationScriptVisibleFromAnchorClassLoader() {
        assertNotNull("V4.0.0__init.sql 须在 anchor 类加载器可见面(与门面资源扫描同判定面)",
                EcatCoreRuoyiIntegration.class.getClassLoader()
                        .getResource("db/migration-ruoyi-sys/V4.0.0__init.sql"));
    }
}
