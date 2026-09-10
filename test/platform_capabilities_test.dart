import 'package:flutter_test/flutter_test.dart';
import 'package:netcontrol/core/domain/entities/platform_capabilities.dart';

void main() {
  group('PlatformCapabilities كتالوج القدرات', () {
    test('لا يحوي عناصر فارغة', () {
      for (final c in PlatformCapabilities.all) {
        expect(c.title.trim().isNotEmpty, isTrue,
            reason: 'عنوان فارغ في إحدى القدرات');
        expect(c.description.trim().isNotEmpty, isTrue,
            reason: 'وصف فارغ لِـ ${c.title}');
      }
    });

    test('كل قدرة تحدد مستوى Android وiOS', () {
      // نتحقق أن المستويين داخل قيم التعداد المعروفة (وليس مجرد نوع
      // ثابت وقت الترجمة — فذلك دائماً صحيح ولا يختبر شيئاً).
      expect(
        PlatformCapabilities.all.every((c) =>
            SupportLevel.values.contains(c.android) &&
            SupportLevel.values.contains(c.ios)),
        isTrue,
      );
    });

    test('القدرات المقيّدة على iOS تذكر سبب القيد', () {
      for (final c in PlatformCapabilities.all.where((c) => c.isLimitedOnIos)) {
        expect(c.iosNote, isNotNull,
            reason: '${c.title} مقيّدة على iOS دون توضيح السبب');
        expect(c.iosNote!.trim().isNotEmpty, isTrue);
      }
    });

    test('levelFor ترجع مستوى المنصة الصحيح', () {
      const cap = PlatformCapabilities.all.first;
      expect(PlatformCapabilities.levelFor(cap, isIOS: false), cap.android);
      expect(PlatformCapabilities.levelFor(cap, isIOS: true), cap.ios);
    });

    test('sortedForDisplay تضع المقيّد أولاً دون فقدان عناصر', () {
      final sorted = PlatformCapabilities.sortedForDisplay;
      expect(sorted.length, PlatformCapabilities.all.length);
      final firstLimitedIndex = sorted.indexWhere((c) => c.isLimitedOnIos);
      final lastFullIndex =
          sorted.lastIndexWhere((c) => !c.isLimitedOnIos);
      expect(firstLimitedIndex, greaterThanOrEqualTo(0));
      expect(lastFullIndex, greaterThan(firstLimitedIndex));
    });
  });
}
