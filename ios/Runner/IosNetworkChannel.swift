import Flutter
import Darwin
import UIKit

/// جسر معلومات الشبكة على iOS.
///
/// قيود المنصة (تُعامَل في Dart بتدهور آمن):
///  - مسح شبكات WiFi المحيطة غير متاح لواجهة عامة (Apple تتيح فقط
///    الشبكة الحالية عبر NEHotspotNetwork)؛ نُرجع خطأ UNSUPPORTED
///    فيعود المستودع للنتائج المحفوظة.
///  - جدول ARP غير قابل للقراءة على جهاز بدون جيلبريك؛ نُرجع خريطة
///    فارغة فيكتفي الماسح بالـ ping.
///  - البوابة تُستنتج من عنوان en0 والقناع (أول عنوان في /24 عادةً)،
///    لأن قراءة جدول التوجيه تتطلب امتيازات غير متاحة في الـ Sandbox.
class IosNetworkChannel: NSObject, FlutterPlugin {

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.netcontrol.app/network",
            binaryMessenger: registrar.messenger()
        )
        let instance = IosNetworkChannel()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getNetworkInfo":
            result(getNetworkInfo())
        case "getArpTable":
            result([String: String]()) // غير متاح بدون جيلبريك.
        case "scanWifi":
            result(FlutterError(
                code: "UNSUPPORTED",
                message: "لا يتيح iOS مسح شبكات WiFi المحيطة للتطبيقات العادية.",
                details: nil
            ))
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// يقرأ عنوان IPv4 والقناع لواجهة en0 (واجهة WiFi عادةً).
    private func getNetworkInfo() -> [String: Any?] {
        var address: String?
        var netmask: String?

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else {
            return ["gateway": nil, "subnet": nil]
        }
        defer { freeifaddrs(ifaddr) }

        var ptr = first
        while true {
            let interface = ptr.pointee
            let flags = Int32(interface.ifa_flags)
            let up = (flags & IFF_UP) == IFF_UP
            let loopback = (flags & IFF_LOOPBACK) == IFF_LOOPBACK

            if up && !loopback,
               let addr = interface.ifa_addr,
               addr.pointee.sa_family == UInt8(AF_INET),
               String(cString: interface.ifa_name) == "en0" {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if getnameinfo(
                    interface.ifa_addr,
                    socklen_t(interface.ifa_addr.pointee.sa_len),
                    &hostname, socklen_t(hostname.count),
                    nil, 0, NI_NUMERICHOST
                ) == 0 {
                    address = String(cString: hostname)
                }
                if let netmaskPtr = interface.ifa_netmask {
                    var net = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(
                        netmaskPtr,
                        socklen_t(netmaskPtr.pointee.sa_len),
                        &net, socklen_t(net.count),
                        nil, 0, NI_NUMERICHOST
                    ) == 0 {
                        netmask = String(cString: net)
                    }
                }
            }
            guard let next = interface.ifa_next else { break }
            ptr = next
        }

        // تقدير معياري: البوابة غالباً أول عنوان في الشبكة المنزلية (x.x.x.1).
        var gateway: String?
        if let address {
            let parts = address.split(separator: ".").map(String.init)
            if parts.count == 4 {
                gateway = "\(parts[0]).\(parts[1]).\(parts[2]).1"
            }
        }

        return ["gateway": gateway, "subnet": netmask]
    }
}
