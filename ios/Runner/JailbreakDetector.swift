import Flutter
import MachO
import UIKit

/// جسر كشف الجيلبريك (Jailbreak) على iOS.
///
/// يجمع عدة مؤشرات — فحص واحد غير موثوق على iOS لأن الجيلبريك
/// الحديث (rootless مثل Dopamine/palera1n) يخفي نفسه:
///  1. تطبيقات الجيلبريك المثبتة (Cydia/Sileo/Zebra) عبر canOpenURL.
///  2. ملفات ومسارات النظام الخاصة بالجيلبريك (بما فيها /var/jb للـ rootless).
///  3. المكتبات المحمّلة في العملية (Substrate/libhooker/ElleKit).
///  4. محاولة الكتابة خارج صندوق الرمل (Sandbox).
///  5. إنشاء رابط رمزي في /private (ممنوع على النظام السليم).
class JailbreakDetector: NSObject, FlutterPlugin {

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.netcontrol.app/root_check",
            binaryMessenger: registrar.messenger()
        )
        let instance = JailbreakDetector()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "detect":
            result(detect())
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func detect() -> [String: Any] {
        var evidence: [String] = []
        var methods: [String] = []

        if checkJailbreakUrls() {
            evidence.append("تطبيق إدارة جيلبريك موجود (Cydia/Sileo/Zebra)")
            methods.append("jb_url")
        }
        if checkJailbreakFiles() {
            evidence.append("ملفات الجيلبريك موجودة في النظام")
            methods.append("jb_files")
        }
        if checkSuspiciousDylibs() {
            evidence.append("مكتبات حقن محمّلة (Substrate/libhooker/ElleKit)")
            methods.append("dylibs")
        }
        if checkSandboxWrite() {
            evidence.append("الكتابة خارج Sandbox نجحت")
            methods.append("sandbox_escape")
        }
        if checkSymlink() {
            evidence.append("إنشاء رابط رمزي في /private نجح")
            methods.append("symlink")
        }

        return [
            "isRooted": !methods.isEmpty,
            "methods": methods,
            "evidence": evidence,
        ]
    }

    /// 1) بروتوكولات تطبيقات الجيلبريك (يلزمها LSApplicationQueriesSchemes).
    private func checkJailbreakUrls() -> Bool {
        let schemes = ["cydia", "sileo", "zbra", "filza", "undecimus"]
        return schemes.contains { scheme in
            guard let url = URL(string: "\(scheme)://package/com.example") else {
                return false
            }
            return UIApplication.shared.canOpenURL(url)
        }
    }

    /// 2) مسارات الجيلبريك التقليدية و rootless (/var/jb).
    private func checkJailbreakFiles() -> Bool {
        let paths = [
            "/Applications/Cydia.app",
            "/Applications/Sileo.app",
            "/Applications/Zebra.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/bin/sh",
            "/usr/sbin/sshd",
            "/usr/bin/ssh",
            "/etc/apt",
            "/private/var/lib/apt",
            "/private/var/lib/cydia",
            "/private/var/stash",
            "/usr/libexec/sftp-server",
            "/usr/lib/TweakInject",
            "/var/jb",                       // الجيلبريك rootless
            "/var/jb/usr/bin",
            "/var/jb/etc/apt",
            "/var/LIY",
        ]
        return paths.contains { FileManager.default.fileExists(atPath: $0) }
    }

    /// 3) مكتبات الحقن المحمّلة في الذاكرة.
    private func checkSuspiciousDylibs() -> Bool {
        let suspicious = [
            "MobileSubstrate", "SubstrateLoader", "substrate",
            "libhooker", "libsubstrate", "TweakInject",
            "ellekit", "libellekit", "CydiaSubstrate",
        ]
        let count = _dyld_image_count()
        for i in 0..<count {
            guard let name = _dyld_get_image_name(i) else { continue }
            let image = String(cString: name)
            if suspicious.contains(where: { image.lowercased().contains($0.lowercased()) }) {
                return true
            }
        }
        return false
    }

    /// 4) محاولة الكتابة في نظام الملفات خارج الـ Sandbox.
    private func checkSandboxWrite() -> Bool {
        let probe = "/private/netcontrol_jb_probe.txt"
        do {
            try "jailbreak".write(
                toFile: probe,
                atomically: true,
                encoding: .utf8
            )
            try? FileManager.default.removeItem(atPath: probe)
            return true
        } catch {
            return false
        }
    }

    /// 5) إنشاء رابط رمزي في /private (يُرفض على النظام السليم).
    private func checkSymlink() -> Bool {
        let link = "/private/netcontrol_jb_link"
        do {
            try? FileManager.default.removeItem(atPath: link)
            try FileManager.default.createSymbolicLink(
                atPath: link,
                withDestinationPath: "/etc/hosts"
            )
            try? FileManager.default.removeItem(atPath: link)
            return true
        } catch {
            return false
        }
    }
}
