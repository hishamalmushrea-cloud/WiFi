import 'package:flutter_test/flutter_test.dart';
import 'package:netcontrol/features/heatmap/data/signal_sampler.dart';

void main() {
  group('defaultModeForPlatform', () {
    test('Android: القياس التلقائي افتراضياً', () {
      expect(defaultModeForPlatform(isIOS: false),
          SignalSourceMode.auto);
    });

    test('iOS: الإدخال اليدوي افتراضياً (لا واجهة RSSI عامة)', () {
      expect(defaultModeForPlatform(isIOS: true),
          SignalSourceMode.manual);
    });
  });

  group('SignalSourceMode', () {
    test('الأنماط الثلاثة موجودة', () {
      expect(SignalSourceMode.values.length, 3);
      expect(SignalSourceMode.values,
          containsAll([SignalSourceMode.auto, SignalSourceMode.manual, SignalSourceMode.demo]));
    });
  });
}
