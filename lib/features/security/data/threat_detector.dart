import '../../../core/domain/entities/access_point.dart';
import '../../../core/domain/entities/device.dart';
import '../../../core/domain/entities/security.dart';

/// محرك كشف التهديدات اللاسلكية (بدون Root).
///
/// يعمل على بيانات نقاط الوصول المتاحة للمستخدم العادي ويبحث عن
/// أنماط هجوم معروفة:
///  - Evil Twin: نفس اسم الشبكة (SSID) على أكثر من BSSID بإشارة
///    أعلى وتشفير أضعف — خداع شائع لجذب الضحايا.
///  - شبكة مفتوحة تحمل اسماً مقلداً لشبكة مشفّرة.
///  - WPS مفعّل أو تشفير ضعيف (WEP/WPA).
///  - جهاز دخيل: MAC عشوائي (مُعنون محلياً) لم يُصنَّف كمعروف.
///
/// كشف الهجمات النشطة (deauth/pineap/karma) يحتاج التقاط حزم
/// (Root) ويُضاف في PHASE 11.
class ThreatDetector {
  const ThreatDetector._();

  static List<SecurityAlert> analyze({
    required List<AccessPoint> accessPoints,
    required List<Device> devices,
    String? homeSsid,
    DateTime? now,
  }) {
    final time = now ?? DateTime.now();
    final alerts = <SecurityAlert>[];

    // ── 1) تجميع نقاط الوصول حسب الاسم (SSID) ──
    final bySsid = <String, List<AccessPoint>>{};
    for (final ap in accessPoints) {
      if (ap.isHiddenNetwork) continue;
      final key = ap.ssid!.trim().toLowerCase();
      bySsid.putIfAbsent(key, () => []).add(ap);
    }

    // ── 2) كشف Evil Twin: نفس الاسم، BSSID مختلف، خصائص متضاربة ──
    for (final entry in bySsid.entries) {
      final aps = entry.value;
      if (aps.length < 2) continue;

      // ترتيب حسب قوة الإشارة: الأقوى قد يكون الطُعم.
      aps.sort((a, b) => b.rssi.compareTo(a.rssi));
      final strongest = aps.first;
      final others = aps.skip(1).toList();

      final hasOpen = aps.any((a) => a.security == WifiSecurity.open);
      final hasSecure = aps.any((a) =>
          a.security == WifiSecurity.wpa2 || a.security == WifiSecurity.wpa3);
      final strongestIsOpen = strongest.security == WifiSecurity.open;

      // حالة الخطر: نسخة مفتوحة من شبكة مشفّرة، أو النسخة الأقوى
      // أضعف تشفيراً من البقية.
      if ((hasOpen && hasSecure) ||
          (strongestIsOpen && others.isNotEmpty)) {
        alerts.add(SecurityAlert(
          type: SecurityAlertType.evilTwin,
          severity: ThreatSeverity.high,
          title: 'شبكة توأم خبيثة محتملة: ${strongest.ssid}',
          description:
              'ظهرت عدة نقاط بنفس الاسم، إحداها مفتوحة أو بتشفير أضعف وإشارة أقوى. '
              'قد تكون نقطة اتصال خبيثة تنتحل اسم شبكتك لاعتراض البيانات.',
          sourceMac: strongest.bssid,
          details: 'عدد النقاط بنفس الاسم: ${aps.length}',
          timestamp: time,
        ));
      }
    }

    // ── 3) شبكات مفتوحة عامة (خطر منخفض للتنبيه) ──
    for (final ap in accessPoints) {
      if (!ap.isHiddenNetwork && ap.security == WifiSecurity.open) {
        // نتجاهل الشبكات المفتوحة التي لا تقلد أحداً (مقاهٍ مثلاً)،
        // ننبّه فقط إن طابقت اسم شبكتنا.
        if (homeSsid != null &&
            ap.ssid?.trim().toLowerCase() == homeSsid.trim().toLowerCase()) {
          alerts.add(SecurityAlert(
            type: SecurityAlertType.openNetwork,
            severity: ThreatSeverity.critical,
            title: 'شبكتك تُبث بدون تشفير!',
            description:
                'نقطة وصول تحمل اسم شبكتك وهي مفتوحة بدون كلمة مرور، '
                'أو أن إعدادات الراوتر تغيّرت. تحقق فوراً.',
            sourceMac: ap.bssid,
            timestamp: time,
          ));
        }
      }
    }

    // ── 4) تشفير ضعيف (WEP/WPA) أو WPS ──
    for (final ap in accessPoints) {
      final caps = (ap.capabilities ?? '').toUpperCase();
      if (ap.security == WifiSecurity.wep) {
        alerts.add(SecurityAlert(
          type: SecurityAlertType.weakEncryption,
          severity: ThreatSeverity.medium,
          title: 'تشفير WEP ضعيف: ${ap.displaySsid}',
          description: 'WEP يمكن كسره في دقائق. الترقية إلى WPA2/WPA3 ضرورية.',
          sourceMac: ap.bssid,
          timestamp: time,
        ));
      }
      if (caps.contains('WPS')) {
        alerts.add(SecurityAlert(
          type: SecurityAlertType.wpsVulnerability,
          severity: ThreatSeverity.medium,
          title: 'WPS مفعّل: ${ap.displaySsid}',
          description:
              'زر WPS يحوي ثغرات معروفة (هجمات PIN). يُنصح بتعطيله من الراوتر.',
          sourceMac: ap.bssid,
          timestamp: time,
        ));
      }
    }

    // ── 5) جهاز دخيل محتمل: MAC عشوائي وغير معروف ──
    for (final device in devices) {
      if (!device.isOnline) continue;
      if (device.isKnown || device.isFavorite) continue;
      // MAC عشوائي (local-administered) مع اتصال حديث نسبياً.
      if (device.isRandomMac) {
        alerts.add(SecurityAlert(
          type: SecurityAlertType.intruder,
          severity: ThreatSeverity.low,
          title: 'جهاز بعنوان MAC عشوائي على الشبكة',
          description:
              '${device.displayName} (${device.ip}) يستخدم عنواناً عشوائياً، '
              'وهو سلوك شائع للزوار ولكنه قد يُستخدم لإخفاء الهوية.',
          sourceIp: device.ip,
          sourceMac: device.mac,
          timestamp: time,
        ));
      }
    }

    return alerts;
  }
}
