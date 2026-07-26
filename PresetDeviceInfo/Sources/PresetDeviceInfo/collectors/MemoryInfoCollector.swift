import Foundation

struct MemoryInfo {
    /** 系统报告的物理内存总量，单位为 byte。 */
    let device_memory: DeviceInfoEntry
}

/**
 * Foundation 报告的设备物理内存原始只读结果，单位为 byte。
 *
 * `MemoryInfo.device_memory` 直接读取 `ProcessInfo.processInfo.physicalMemory`，不换算为 KB、MB 或 GB。
 *
 * - 声明：不需要权限。
 * - 弹窗：不触发。
 * - PII：否，但设备内存容量可作为设备指纹的一部分。
 * - 实际使用：真机上表示系统报告的物理内存；Simulator 可能反映宿主 Mac 的内存环境，
 *   不能代表所选 iPhone 模拟型号的实际内存。
 *
 * 已评估但不采集：
 * - `os_proc_available_memory`：当前进程可用内存，不是设备总内存。
 * - `task_info` / `resident_size`：当前 App 的内存占用，不是设备总内存。
 * - Mach VM statistics：当前系统内存状态快照，不是面向本字段的物理内存总量读取接口。
 * - 设备型号到内存容量的映射表：属于推算，不是系统原始读取值。
 * - 面向消费者标称的系统内存：iOS 没有对应的公开读取接口，因此不定义该字段。
 */
final class MemoryInfoCollector {
    func collect() -> MemoryInfo {
        MemoryInfo(
            device_memory: DeviceInfoEntry(
                key: "device_memory",
                value: readDeviceMemory(),
                label: "Device Memory"
            )
        )
    }

    private func readDeviceMemory() -> String {
        String(ProcessInfo.processInfo.physicalMemory)
    }
}
