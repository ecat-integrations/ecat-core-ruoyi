package com.ecat.integration.EcatCoreRuoyiIntegration;

import lombok.Value;

/**
 * ruoyi-admin 定位结果值对象(进程内瞬态,无持久化)。
 * 两形态互斥:USER_FILE=用户指定路径(文件形态,走 RuoyiJarApp.start);
 * NESTED_ENTRY=自身包嵌入载荷(嵌读形态,走 RuoyiJarApp.startNested)。
 * 形态外字段为 null=「该形态不适用」,非缺失语义;强类型禁字符串复合编码。
 */
@Value
class AdminLocation {

    enum Mode {
        /** 用户指定路径(admin jar 为独立文件)。 */
        USER_FILE,
        /** 桥接自身包内嵌入载荷(嵌套条目精确名)。 */
        NESTED_ENTRY
    }

    Mode mode;
    /** USER_FILE 形态:admin jar 绝对路径。 */
    String filePath;
    /** NESTED_ENTRY 形态:桥接自身 jar 绝对路径(嵌读输入)。 */
    String bridgeJarPath;
    /** NESTED_ENTRY 形态:载荷条目名(自带版本,精确名=版本门)。 */
    String adminEntryName;

    static AdminLocation userFile(String filePath) {
        return new AdminLocation(Mode.USER_FILE, filePath, null, null);
    }

    static AdminLocation nestedEntry(String bridgeJarPath, String adminEntryName) {
        return new AdminLocation(Mode.NESTED_ENTRY, null, bridgeJarPath, adminEntryName);
    }

    String describe() {
        if (mode == Mode.USER_FILE) {
            return "USER_FILE file=" + filePath;
        }
        return "NESTED_ENTRY bridge=" + bridgeJarPath + " entry=" + adminEntryName;
    }
}
