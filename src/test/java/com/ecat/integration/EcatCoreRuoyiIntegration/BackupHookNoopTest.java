package com.ecat.integration.EcatCoreRuoyiIntegration;

import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoMoreInteractions;

import java.lang.reflect.Field;

import org.junit.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.ArgumentMatchers;

import com.ecat.core.Integration.IntegrationBase;
import com.ecat.core.Upgrade.BackupHook;
import com.ecat.core.Utils.Log;

/**
 * BackupHook 空跑模式单测:两钩子被调即各打一行含动作名+空跑标记+时间戳字段的日志、
 * 正常返回,且可观测面只有这一行日志(零数据副本零外部命令=日志之外零交互)。
 * 日志断言用注入 mock Log 替身,不走 logback 附加器——绕开限频滤器使断言随机漏报的风险。
 */
public class BackupHookNoopTest {

    @Test
    public void backupLogsOneLineWithActionAndTimestampAndDoesNothingElse() {
        EcatCoreRuoyiIntegration integration = new EcatCoreRuoyiIntegration();
        Log log = mock(Log.class);
        replaceLog(integration, log);

        integration.backup();

        ArgumentCaptor<String> message = ArgumentCaptor.forClass(String.class);
        verify(log).info(message.capture(), ArgumentMatchers.<Object>any());
        assertNoopLine(message.getValue(), "backup");
        verifyNoMoreInteractions(log);
    }

    @Test
    public void restoreLogsOneLineWithActionAndTimestampAndDoesNothingElse() {
        EcatCoreRuoyiIntegration integration = new EcatCoreRuoyiIntegration();
        Log log = mock(Log.class);
        replaceLog(integration, log);

        integration.restore();

        ArgumentCaptor<String> message = ArgumentCaptor.forClass(String.class);
        verify(log).info(message.capture(), ArgumentMatchers.<Object>any());
        assertNoopLine(message.getValue(), "restore");
        verifyNoMoreInteractions(log);
    }

    @Test
    public void hostImplementsBackupHookForWindowDispatch() {
        // 升级窗程序按 instanceof BackupHook 派发:实现关系缺席=宿主被静默跳过,必须锁死
        assertTrue("宿主必须实现 BackupHook(升级窗程序派发面)",
                new EcatCoreRuoyiIntegration() instanceof BackupHook);
    }

    /** 反射替换父类 log 字段:日志观测缝,非生产语义。 */
    private static void replaceLog(EcatCoreRuoyiIntegration integration, Log mockLog) {
        try {
            Field field = IntegrationBase.class.getDeclaredField("log");
            field.setAccessible(true);
            field.set(integration, mockLog);
        } catch (ReflectiveOperationException e) {
            throw new IllegalStateException("测试反射注入 log 字段失败", e);
        }
    }

    private static void assertNoopLine(String line, String action) {
        assertTrue(action + " 日志应含动作名/空跑标记/时间戳字段,实际: " + line,
                line.contains(action) && line.contains("空跑") && line.contains("ts="));
    }
}
