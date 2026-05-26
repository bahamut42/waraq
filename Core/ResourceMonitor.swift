import Combine
import Darwin
import Foundation

/// Lightweight CPU% and RAM (MB) reporter for the Waraq process.
/// Polls once per second when started.
@MainActor
final class ResourceMonitor: ObservableObject {
    static let shared = ResourceMonitor()

    @Published private(set) var cpuPercent: Double = 0
    @Published private(set) var memoryMB: Double = 0
    @Published private(set) var isRunning: Bool = false

    private var timer: Timer?

    func start() {
        guard !isRunning else { return }
        isRunning = true
        sample()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {
            [weak self] _ in
            Task { @MainActor [weak self] in
                self?.sample()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    private func sample() {
        memoryMB = Self.residentMemoryMB()
        cpuPercent = Self.processCPUPercent()
    }

    /// Resident memory of the current process in megabytes.
    static func residentMemoryMB() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(
            MemoryLayout<mach_task_basic_info>.size /
                MemoryLayout<integer_t>.size
        )
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        return Double(info.resident_size) / 1024.0 / 1024.0
    }

    /// Total CPU percent across all threads of the current process.
    /// 100.0 means one full core saturated. Multi-core means values
    /// over 100 are possible.
    static func processCPUPercent() -> Double {
        var threadList: thread_act_array_t?
        var threadCount: mach_msg_type_number_t = 0

        let result = task_threads(
            mach_task_self_, &threadList, &threadCount
        )
        guard result == KERN_SUCCESS, let threads = threadList else {
            return 0
        }

        defer {
            let size = vm_size_t(
                Int(threadCount) * MemoryLayout<thread_t>.size
            )
            vm_deallocate(
                mach_task_self_,
                vm_address_t(UInt(bitPattern: threadList)),
                size
            )
        }

        var totalUsage: Double = 0
        for i in 0..<Int(threadCount) {
            var threadInfo = thread_basic_info()
            var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)

            let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
                $0.withMemoryRebound(
                    to: integer_t.self,
                    capacity: Int(threadInfoCount)
                ) {
                    thread_info(
                        threads[i],
                        thread_flavor_t(THREAD_BASIC_INFO),
                        $0,
                        &threadInfoCount
                    )
                }
            }

            if infoResult == KERN_SUCCESS,
               (threadInfo.flags & TH_FLAGS_IDLE) == 0
            {
                totalUsage += Double(threadInfo.cpu_usage) /
                    Double(TH_USAGE_SCALE) * 100.0
            }
        }
        return totalUsage
    }
}
