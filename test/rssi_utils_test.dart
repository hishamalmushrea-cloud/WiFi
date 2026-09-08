import 'package:flutter_test/flutter_test.dart';
import 'package:netcontrol/core/utils/rssi_utils.dart';

void main() {
  group('RssiUtils.isValidRssi', () {
    test('يقبل القيم المنطقية', () {
      expect(RssiUtils.isValidRssi(-42), isTrue);
      expect(RssiUtils.isValidRssi(-67), isTrue);
      expect(RssiUtils.isValidRssi(-95), isTrue);
    });

    test('يرفض القيم غير المنطقية (0 وINVALID وقيم القمم)', () {
      expect(RssiUtils.isValidRssi(0), isFalse);
      expect(RssiUtils.isValidRssi(-9999), isFalse); // WifiInfo.INVALID_RSSI
      expect(RssiUtils.isValidRssi(-101), isFalse);
      expect(RssiUtils.isValidRssi(-19), isFalse);
      expect(RssiUtils.isValidRssi(30), isFalse);
    });
  });

  group('RssiUtils.clampRssi', () {
    test('يحصر داخل المدى المعروض', () {
      expect(RssiUtils.clampRssi(-120), -95);
      expect(RssiUtils.clampRssi(-5), -30);
      expect(RssiUtils.clampRssi(-60), -60);
    });
  });

  group('RssiUtils.qualityOf', () {
    test('حدود التصنيف صحيحة', () {
      expect(RssiUtils.qualityOf(-40), RssiQuality.excellent);
      expect(RssiUtils.qualityOf(-50), RssiQuality.excellent);
      expect(RssiUtils.qualityOf(-51), RssiQuality.good);
      expect(RssiUtils.qualityOf(-60), RssiQuality.good);
      expect(RssiUtils.qualityOf(-61), RssiQuality.fair);
      expect(RssiUtils.qualityOf(-70), RssiQuality.fair);
      expect(RssiUtils.qualityOf(-71), RssiQuality.weak);
      expect(RssiUtils.qualityOf(-80), RssiQuality.weak);
      expect(RssiUtils.qualityOf(-81), RssiQuality.veryPoor);
      expect(RssiUtils.qualityOf(-95), RssiQuality.veryPoor);
    });
  });

  group('RssiUtils.heatOf', () {
    test('قيمة الحرارة بين 0 و1 ومتزايدة', () {
      final weak = RssiUtils.heatOf(-90);
      final strong = RssiUtils.heatOf(-45);
      expect(weak, inInclusiveRange(0, 1));
      expect(strong, inInclusiveRange(0, 1));
      expect(strong, greaterThan(weak));
    });
  });
}
