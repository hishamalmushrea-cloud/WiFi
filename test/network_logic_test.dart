import 'package:flutter_test/flutter_test.dart';
import 'package:netcontrol/core/domain/entities/access_point.dart';
import 'package:netcontrol/core/errors/result.dart';
import 'package:netcontrol/core/errors/failures.dart';
import 'package:netcontrol/features/wifi_analysis/data/wifi_channel_analyzer.dart';

/// اختبارات P12 للمنطق الخالص الذي يعمل دون منصة (لا MethodChannel):
///  - تحويل تردد WiFi إلى رقم قناة قياسي.
///  - تحليل ازدحام القنوات واختيار الأنظف.
///  - سلوك Result (نجاح/فشل) والبيانات المشتقة.
void main() {
  group('WifiChannelAnalyzer.channelForFrequency', () {
    test('نطاق 2.4GHz: 2412→قناة 1 و2437→6 و2462→11 و2484→14', () {
      expect(WifiChannelAnalyzer.channelForFrequency(2412), 1);
      expect(WifiChannelAnalyzer.channelForFrequency(2437), 6);
      expect(WifiChannelAnalyzer.channelForFrequency(2462), 11);
      expect(WifiChannelAnalyzer.channelForFrequency(2484), 14);
    });

    test('نطاق 5GHz: 5180→36 و5825→165', () {
      expect(WifiChannelAnalyzer.channelForFrequency(5180), 36);
      expect(WifiChannelAnalyzer.channelForFrequency(5825), 165);
    });

    test('نطاق 6GHz: 5955→قناة 1', () {
      expect(WifiChannelAnalyzer.channelForFrequency(5955), 1);
    });

    test('تردد غير معروف يُرجع null', () {
      expect(WifiChannelAnalyzer.channelForFrequency(900), isNull);
    });
  });

  group('WifiChannelAnalyzer.analyze', () {
    AccessPoint ap({
      required String bssid,
      required int rssi,
      required int frequency,
    }) =>
        AccessPoint(
          bssid: bssid,
          ssid: bssid,
          rssi: rssi,
          channel: WifiChannelAnalyzer.channelForFrequency(frequency) ?? 0,
          frequencyMhz: frequency,
          band: WifiBand.ghz24,
          lastSeen: DateTime(2026),
        );

    test('يزدحم القناة 6 بشبكات قوية فيوصي بقناة أنظف', () {
      final aps = [
        ap(bssid: 'AA:BB:CC:00:00:01', rssi: -45, frequency: 2437), // 6
        ap(bssid: 'AA:BB:CC:00:00:02', rssi: -50, frequency: 2437), // 6
        ap(bssid: 'AA:BB:CC:00:00:03', rssi: -48, frequency: 2437), // 6
        ap(bssid: 'AA:BB:CC:00:00:04', rssi: -70, frequency: 2412), // 1
      ];

      final result = WifiChannelAnalyzer.analyze(aps);

      final rec24 = result.recommendations
          .where((r) => r.band == WifiBand.ghz24)
          .toList();
      expect(rec24, isNotEmpty);

      // القناة الموصى بها ليست المزدحمة (6).
      expect(rec24.first.bestChannel, isNot(6));

      // تقييم (1..5، الأعلى أنظف) للقناة 6 أقل منه للقناة 1.
      final ratings = result.channelRatings
          .where((r) => r.band == WifiBand.ghz24)
          .toList();
      final rating6 = ratings.firstWhere((r) => r.channel == 6);
      final rating1 = ratings.firstWhere((r) => r.channel == 1);
      expect(rating6.rating, lessThan(rating1.rating));
    });

    test('قائمة فارغة لا تسبب أعطالاً', () {
      final result = WifiChannelAnalyzer.analyze(const []);
      expect(result.channelRatings, isEmpty);
      expect(result.recommendations, isEmpty);
    });
  });

  group('Result', () {
    test('النجاح يحمل البيانات و dataOrNull يُرجعها', () {
      const Result<int> r = Success(42);
      expect(r.isSuccess, isTrue);
      expect(r.dataOrNull, 42);
      expect(r.failureOrNull, isNull);

      late int captured;
      r.when(
        onSuccess: (v) => captured = v,
        onFailure: (_) => fail('لا يجب أن يُستدعى onFailure'),
      );
      expect(captured, 42);
    });

    test('الفشل يحمل Failure و dataOrNull يعطي null', () {
      const failure = NetworkFailure('لا يوجد اتصال');
      final Result<int> r = FailureResult<int>(failure);
      expect(r.isSuccess, isFalse);
      expect(r.dataOrNull, isNull);
      expect(r.failureOrNull?.message, 'لا يوجد اتصال');

      late Failure captured;
      r.when(
        onSuccess: (_) => fail('لا يجب أن يُستدعى onSuccess'),
        onFailure: (f) => captured = f,
      );
      expect(captured.message, 'لا يوجد اتصال');
    });
  });
}
