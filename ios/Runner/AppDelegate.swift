import Flutter
import UIKit

/**
 * نقطة دخول تطبيق iOS.
 *
 * القنوات الأصلية (Method Channels) تُسجَّل هنا في PHASE 11:
 *  - JailbreakDetectorChannel : فحص الجيلبريك بطرق متعددة
 *  - NetworkChannel           : فحص الشبكة عبر Network.framework
 *
 * نبقي الـ Delegate في أبسط صورة الآن حتى تعمل توليدات Flutter تلقائياً.
 */
@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller = window?.rootViewController as? FlutterViewController

        if let controller = controller {
            // تسجيل القنوات الأصلية سيُضاف هنا في PHASE 11.
            _ = controller
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
