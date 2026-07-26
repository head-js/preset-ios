/**
 * 一条已采集的设备信息。
 */
public struct DeviceInfoEntry: Equatable {
    /** 稳定、机器可读的 snake_case 字段标识。 */
    public let key: String

    /** 原始字段值；不可读取时为空字符串。 */
    public let value: String

    /** 面向使用方展示的字段名称。 */
    public let label: String

    public init(key: String, value: String, label: String) {
        self.key = key
        self.value = value
        self.label = label
    }
}
