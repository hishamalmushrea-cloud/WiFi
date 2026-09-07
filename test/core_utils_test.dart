import 'package:flutter_test/flutter_test.dart';
import 'package:netcontrol/core/utils/crypto_utils.dart';
import 'package:netcontrol/core/utils/format_utils.dart';
import 'package:netcontrol/core/utils/ip_utils.dart';
import 'package:netcontrol/core/utils/mac_utils.dart';
import 'package:netcontrol/core/utils/port_utils.dart';

void main() {
  group('IpUtils', () {
    test('تحويل عنوان إلى قيمة والعكس', () {
      expect(IpUtils.fromInt(IpUtils.toInt('192.168.1.10')!), '192.168.1.10');
      expect(IpUtils.isValid('10.0.0.1'), isTrue);
      expect(IpUtils.isValid('999.0.0.1'), isFalse);
      expect(IpUtils.isValid('1.2.3'), isFalse);
    });

    test('حساب الشبكة والبث لـ /24', () {
      expect(IpUtils.networkAddress('192.168.1.50', 24), '192.168.1.0');
      expect(IpUtils.broadcastAddress('192.168.1.50', 24), '192.168.1.255');
      final range = IpUtils.hostRange('192.168.1.50', 24);
      expect(range.first, '192.168.1.1');
      expect(range.last, '192.168.1.254');
      expect(range.count, 254);
    });

    test('قناع الشبكة من البادئة', () {
      expect(IpUtils.subnetMask(24), '255.255.255.0');
      expect(IpUtils.subnetMask(16), '255.255.0.0');
    });

    test('تعداد المضيفين يحترم الحد', () {
      final hosts = IpUtils.enumerateHosts('192.168.1.0', 24, limit: 10);
      expect(hosts.length, 10);
      expect(hosts.first, '192.168.1.0');
    });

    test('كشف العناوين الخاصة', () {
      expect(IpUtils.isPrivate('192.168.0.1'), isTrue);
      expect(IpUtils.isPrivate('10.5.5.5'), isTrue);
      expect(IpUtils.isPrivate('172.16.0.1'), isTrue);
      expect(IpUtils.isPrivate('8.8.8.8'), isFalse);
    });
  });

  group('MacUtils', () {
    test('استخراج OUI وتنسيق العرض', () {
      expect(MacUtils.oui('a4:83:e7:11:22:33'), 'A483E7');
      expect(MacUtils.pretty('a483e7112233'), 'A4:83:E7:11:22:33');
    });

    test('رفض العناوين غير الصالحة', () {
      expect(MacUtils.normalize('ZZZZ'), isNull);
      expect(MacUtils.normalize('a4:83'), isNull);
    });

    test('كشف العنوان العشوائي (local administered)', () {
      // البت 0x02 في أول بايت = محلي/عشوائي
      expect(MacUtils.isLocallyAdministered('02:00:00:00:00:01'), isTrue);
      expect(MacUtils.isLocallyAdministered('00:1A:2B:3C:4D:5E'), isFalse);
    });
  });

  group('PortUtils', () {
    test('تحليل النطاقات النصية', () {
      expect(PortUtils.parseRange('80,443'), [80, 443]);
      expect(PortUtils.parseRange('8000-8002'), [8000, 8001, 8002]);
      expect(PortUtils.parseRange('22, 80-81'), [22, 80, 81]);
    });

    test('حدود المنافذ الصالحة', () {
      expect(PortUtils.isValid(0), isFalse);
      expect(PortUtils.isValid(443), isTrue);
      expect(PortUtils.isValid(70000), isFalse);
    });

    test('معرفة الخدمة الشائعة', () {
      expect(PortUtils.serviceName(22), 'SSH');
      expect(PortUtils.serviceName(80), 'HTTP');
      expect(PortUtils.serviceName(9999), isNull);
    });
  });

  group('FormatUtils', () {
    test('تحويل dBm إلى نسبة وتصنيف', () {
      expect(FormatUtils.rssiToPercent(-40), 100);
      expect(FormatUtils.rssiToPercent(-100), 0);
      expect(FormatUtils.signalLabel(-45), 'ممتازة');
      expect(FormatUtils.signalLabel(-85), 'ضعيفة جداً');
    });

    test('تنسيق أحجام البيانات', () {
      expect(FormatUtils.dataSize(0), '0 B');
      expect(FormatUtils.dataSize(1024), '1.0 KB');
      expect(FormatUtils.dataSize(1024 * 1024), '1.0 MB');
    });
  });

  group('CryptoUtils', () {
    test('تشفير وفك التشفير متعاكسان', () {
      const secret = 'كلمة_مرور_الراوتر#123';
      const pass = 'عبارة_المرور_الرئيسية';
      final encrypted = CryptoUtils.encryptText(secret, pass);
      expect(encrypted, isNot(contains(secret)));
      expect(CryptoUtils.decryptText(encrypted, pass), secret);
    });

    test('فك التشفير بعبارة خاطئة يفشل', () {
      final encrypted = CryptoUtils.encryptText('سر', 'الصحيحة');
      expect(() => CryptoUtils.decryptText(encrypted, 'الخاطئة'), throwsException);
    });

    test('مفاتيح عشوائية مختلفة في كل مرة', () {
      final k1 = CryptoUtils.generateDatabaseKey();
      final k2 = CryptoUtils.generateDatabaseKey();
      expect(k1, isNot(k2));
    });
  });
}
