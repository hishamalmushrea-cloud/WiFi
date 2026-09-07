import '../../errors/result.dart';
import '../entities/wardriving.dart';

/// عقد مسح الطريق (Wardriving) وبيانات GPS/البلوتوث.
abstract class WardrivingRepository {
  /// بدء جلسة تسجيل: يقرأ الموقع ونقاط الوصول دورياً.
  Stream<List<WardrivingPoint>> startSession();

  Future<Result<void>> stopSession();

  Future<Result<void>> savePoints(List<WardrivingPoint> points);

  Stream<List<WardrivingPoint>> watchPoints();

  Future<Result<WardrivingStats>> getStatistics();

  /// رفع النقاط غير المرفوعة إلى WiGLE (إن توفّر مفتاح API).
  Future<Result<int>> uploadToWigle(String apiToken);

  /// فحص بلوتوث/BLE المحيط.
  Future<Result<List<BluetoothDeviceData>>> scanBluetooth({Duration duration});

  /// تصدير كل النقاط إلى ملف CSV يُعاد مساره.
  Future<Result<String>> exportCsv();
}
