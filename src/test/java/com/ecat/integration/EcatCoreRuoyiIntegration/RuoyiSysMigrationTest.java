package com.ecat.integration.EcatCoreRuoyiIntegration;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertSame;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.ArgumentMatchers.same;
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
import java.util.Collections;
import java.util.List;

import javax.sql.DataSource;

import org.junit.Test;
import org.mockito.MockedConstruction;
import org.mockito.MockedStatic;
import org.mockito.Mockito;

import com.ecat.core.Integration.IntegrationLoadOption;
import com.ecat.integration.EcatDbMigration.DbMigrationException;
import com.ecat.integration.EcatDbMigration.DbMigrationFacade;

/**
 * ruoyi-sys 域执行点接线单测,两层覆盖:
 * 一、onStart 级(守卫真实走,不桩化 getSpringBean)——RuoyiJarApp(外部进程面)以
 * mockConstruction 替身,锁死迁移期反射桥守卫真实放行、迁移先于叶子类加载器注册、
 * 桥就绪但容器缺 DataSource Bean 时显式拒绝;
 * 二、包私有直调级(非守卫路径)——getSpringBean 经 spy 定向桩(桥就绪为前提),
 * 覆盖两态分支路由、调用参数锚定、门面失败穿透;resourceAnchor 资源可见性为纯静态断言。
 * 全模拟零 IO,门面静态调用经 mockStatic 打桩,测试缝=包私有 runRuoyiSysMigration。
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

    @Test
    public void onStartMigrationExecutesWithGuardOpenAndRegistersAfter() {
        EcatCoreRuoyiIntegration integration = new EcatCoreRuoyiIntegration();
        DataSource ds = mock(DataSource.class);
        URLClassLoader fakeChildClassLoader = mock(URLClassLoader.class);
        IntegrationLoadOption loadOption = mock(IntegrationLoadOption.class);
        setPrivateField(integration, "ruoyiAdminJarPath", "/fake/ruoyi-admin.jar");
        setPrivateField(integration, "loadOption", loadOption);

        try (MockedConstruction<RuoyiJarApp> bridge = Mockito.mockConstruction(RuoyiJarApp.class,
                (app, context) -> {
                    // start 第二参与生产同形传 null,匹配用 isNull(anyString 不匹配 null)
                    when(app.start(anyString(), isNull(), any(String[].class)))
                            .thenReturn(fakeChildClassLoader);
                    when(app.getSpringBean(DataSource.class)).thenReturn(ds);
                });
                MockedStatic<DbMigrationFacade> facade = Mockito.mockStatic(DbMigrationFacade.class)) {
            facade.when(() -> DbMigrationFacade.hasHistoryTable("ruoyi-sys", ds)).thenReturn(true);
            integration.onStart();
            facade.verify(() -> DbMigrationFacade.migrate("ruoyi-sys", ds,
                    Collections.singletonList("classpath:db/migration-ruoyi-sys"),
                    EcatCoreRuoyiIntegration.class));
        }
        verify(loadOption).setChildClassLoader(fakeChildClassLoader);
    }

    @Test
    public void onStartRejectsWhenLiveContainerLacksDataSourceBean() {
        EcatCoreRuoyiIntegration integration = new EcatCoreRuoyiIntegration();
        URLClassLoader fakeChildClassLoader = mock(URLClassLoader.class);
        IntegrationLoadOption loadOption = mock(IntegrationLoadOption.class);
        setPrivateField(integration, "ruoyiAdminJarPath", "/fake/ruoyi-admin.jar");
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
        DbMigrationException boom = DbMigrationException.of("ruoyi-sys", "migrate",
                new RuntimeException("checksum mismatch for V4.0.0__init.sql"));
        try (MockedStatic<DbMigrationFacade> facade = Mockito.mockStatic(DbMigrationFacade.class)) {
            facade.when(() -> DbMigrationFacade.hasHistoryTable("ruoyi-sys", ds)).thenReturn(true);
            facade.when(() -> DbMigrationFacade.migrate("ruoyi-sys", ds,
                    Collections.singletonList("classpath:db/migration-ruoyi-sys"),
                    EcatCoreRuoyiIntegration.class)).thenThrow(boom);
            try {
                integration.runRuoyiSysMigration();
                fail("迁移失败必须沿执行点原样上抛");
            } catch (DbMigrationException e) {
                assertSame("引擎异常须原样穿透,禁包裹或改写", boom, e);
            }
        }
    }

    @Test
    public void migrateCalledWithExactParamsWhenHistoryTableExists() {
        DataSource ds = mock(DataSource.class);
        EcatCoreRuoyiIntegration integration = integrationReturning(ds);
        List<String> calls = new ArrayList<>();
        try (MockedStatic<DbMigrationFacade> facade = Mockito.mockStatic(DbMigrationFacade.class)) {
            facade.when(() -> DbMigrationFacade.hasHistoryTable("ruoyi-sys", ds)).thenReturn(true);
            facade.when(() -> DbMigrationFacade.baseline(anyString(), any(DataSource.class), anyString()))
                    .thenAnswer(invocation -> {
                        calls.add("baseline");
                        return null;
                    });
            facade.when(() -> DbMigrationFacade.migrate(anyString(), any(DataSource.class), anyList(),
                    any(Class.class))).thenAnswer(invocation -> {
                        calls.add("migrate");
                        return null;
                    });
            integration.runRuoyiSysMigration();
            facade.verify(() -> DbMigrationFacade.migrate("ruoyi-sys", ds,
                    Collections.singletonList("classpath:db/migration-ruoyi-sys"),
                    EcatCoreRuoyiIntegration.class));
        }
        assertFalse("有账本分支禁 baseline 调用(防双盖标)", calls.contains("baseline"));
    }

    @Test
    public void routesToBaselineThenMigrateWhenNoHistoryTable() {
        DataSource ds = mock(DataSource.class);
        EcatCoreRuoyiIntegration integration = integrationReturning(ds);
        List<String> calls = new ArrayList<>();
        List<String> baselineVersions = new ArrayList<>();
        try (MockedStatic<DbMigrationFacade> facade = Mockito.mockStatic(DbMigrationFacade.class)) {
            facade.when(() -> DbMigrationFacade.hasHistoryTable(eq("ruoyi-sys"), same(ds)))
                    .thenAnswer(invocation -> {
                        calls.add("hasHistoryTable");
                        return false;
                    });
            facade.when(() -> DbMigrationFacade.baseline(anyString(), any(DataSource.class), anyString()))
                    .thenAnswer(invocation -> {
                        calls.add("baseline");
                        baselineVersions.add(invocation.getArgument(2));
                        return null;
                    });
            facade.when(() -> DbMigrationFacade.migrate(anyString(), any(DataSource.class), anyList(),
                    any(Class.class))).thenAnswer(invocation -> {
                        calls.add("migrate");
                        return null;
                    });
            integration.runRuoyiSysMigration();
        }
        assertEquals("无账本须先 baseline(\"0\") 建账再 migrate,顺序与形态固定",
                Arrays.asList("hasHistoryTable", "baseline", "migrate"), calls);
        assertEquals("baseline 盖标版本字面量固定 \"0\"(0<4.0.0,V4.0.0 不被挡)",
                Collections.singletonList("0"), baselineVersions);
    }

    @Test
    public void migrationScriptVisibleFromAnchorClassLoader() {
        assertNotNull("V4.0.0__init.sql 须在 anchor 类加载器可见面(与门面资源扫描同判定面)",
                EcatCoreRuoyiIntegration.class.getClassLoader()
                        .getResource("db/migration-ruoyi-sys/V4.0.0__init.sql"));
    }
}
