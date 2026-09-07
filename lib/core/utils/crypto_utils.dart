import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// أدوات التشفير (AES-GCM مع اشتقاق مفتاح PBKDF2).
///
/// السبب: كلمات مرور الراوترات وملفات النسخ الاحتياطي بيانات
/// حساسة يجب ألا تُخزَّن نصاً صريحاً. AES-GCM يوفّر تشفيراً
/// ومصادقة (لا يمكن العبث بالبيانات دون اكتشاف)، و PBKDF2
/// يحوّل عبارة مرور المستخدم إلى مفتاح قوي مع salt عشوائي.
class CryptoUtils {
  CryptoUtils._();

  static const int _iterations = 100000;
  static const int _saltLength = 16;
  static const int _ivLength = 12; // الحجم الموصى به لـ GCM
  static const int _keyLength = 32; // AES-256
  static const int _tagBits = 128;

  /// مولّد أرقام عشوائية آمن (Fortuna) مُغذّى من عشوائية النظام.
  static FortunaRandom _cipherRandom() {
    final fortuna = FortunaRandom();
    final seedSource = Random.secure();
    final seed = Uint8List.fromList(
      List.generate(32, (_) => seedSource.nextInt(256)),
    );
    fortuna.seed(KeyParameter(seed));
    return fortuna;
  }

  /// بايتات عشوائية آمنة (للـ salt والـ IV ومفاتيح قاعدة البيانات).
  static Uint8List randomBytes(int length) =>
      _cipherRandom().nextBytes(length);

  /// مفتاح عشوائي قابل للتخزين في Secure Storage (مفتاح SQLCipher).
  static String generateDatabaseKey() => base64.encode(randomBytes(_keyLength));

  /// يشتق مفتاح AES-256 من عبارة مرور + salt عبر PBKDF2/SHA-256.
  static KeyParameter _deriveKey(String passphrase, Uint8List salt) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    derivator.init(Pbkdf2Parameters(salt, _iterations, _keyLength));
    final key = derivator.process(Uint8List.fromList(utf8.encode(passphrase)));
    return KeyParameter(key);
  }

  /// يشفر نصاً ويعيد حمولة Base64: salt ‖ iv ‖ ciphertext+tag.
  /// تُستخدم لكلمات مرور الراوتر والنسخ الاحتياطية المشفرة.
  static String encryptText(String plaintext, String passphrase) {
    final salt = randomBytes(_saltLength);
    final iv = randomBytes(_ivLength);
    final keyParam = _deriveKey(passphrase, salt);

    final cipher = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(keyParam, _tagBits, iv, Uint8List(0)));

    final cipherText = cipher.process(Uint8List.fromList(utf8.encode(plaintext)));

    return base64.encode([...salt, ...iv, ...cipherText]);
  }

  /// يفك تشفير الحمولة الناتجة من [encryptText].
  /// يرمي StateError إن كانت العبارة خاطئة أو البيانات معبّثة
  /// (فشل مصادقة GCM) فيلتقطها المستدعي ويعرض رسالة مناسبة.
  static String decryptText(String payload, String passphrase) {
    final bytes = base64.decode(payload);
    if (bytes.length <= _saltLength + _ivLength) {
      throw StateError('حمولة التشفير تالفة');
    }

    final salt = bytes.sublist(0, _saltLength);
    final iv = bytes.sublist(_saltLength, _saltLength + _ivLength);
    final cipherText = bytes.sublist(_saltLength + _ivLength);
    final keyParam = _deriveKey(passphrase, salt);

    final decipher = GCMBlockCipher(AESEngine())
      ..init(false, AEADParameters(keyParam, _tagBits, iv, Uint8List(0)));

    final plainText = decipher.process(cipherText);
    return utf8.decode(plainText);
  }

  /// بصمة SHA-256 مختصرة لمعرّف ثابت لا يكشف القيمة الأصلية
  /// (مثلاً لربط إعدادات بجهاز دون تخزين معرّفه الحساس).
  static String shortFingerprint(String input) {
    final digest = SHA256Digest();
    final hash = digest.process(Uint8List.fromList(utf8.encode(input)));
    return base64Url.encode(hash).substring(0, 16);
  }
}
