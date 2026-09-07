import Flutter
import UIKit

/**
 * نقطة دخول تطبيق iOS.
 *
 * تسجّل الجسور الأصلية:
 *  - JailbreakDetector : كشف الجيلبريك بخمس طرق
 *  - IosNetworkChannel : معلومات الشبكة (ARP/مسح WiFi غير متاحين
 *    على iOS بدون جيلبريك فيُعاملان بتدهور آمن في Dart).
 */
@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller = window?.rootViewController as? FlutterViewController

        if let controller = controller {
            let registrar = self.registrar(forPlugin: "NetControlNative")!
            JailbreakDetector.register(with: registrar)
            IosNetworkChannel.register(with: registrar)
            _ = controller
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
