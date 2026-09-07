import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';
import '../utils/app_logger.dart';
import '../utils/crypto_utils.dart';

/// تخزين آمن للقيم الحساسة (مفاتيح التشفير، كلمات مرور الراوتر).
///
/// السبب: نعتمد على Keychain/Keystore على مستوى النظام (عبر
/// flutter_secure_storage) بدل SharedPreferences العادي، لأن قاعدة
/// البيانات المشفرة وبيانات دخول الراوترات لا يجب أن تُكتب في
/// مخازن قابلة للقراءة بصلاحيات عادية على جهاز مروّت.
abstract class SecureStorageService {
  /// مفتاح SQLCipher: يُولّد مرة واحدة ويُعاد استخدامه بعدها.
  /// بدون هذا المفتاح تتعذّر قراءة قاعدة البيانات حتى بنسخة منها.
  Future<String> getOrCreateDatabaseKey();

  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);

  /// كلمة مرور الراوتر تُخزّن مُشفّرة (AES) تحت معرّف الراوتر.
  Future<void> saveRouterSecret(int routerId, String encryptedPayload);
  Future<String?> readRouterSecret(int routerId);
  Future<void> deleteRouterSecret(int routerId);
}

class SecureStorageServiceImpl implements SecureStorageService {
  SecureStorageServiceImpl([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              // نطلب عدم النسخ الاحتياطي السحابي للمفاتيح
              // حتى لا تتسرب بيانات الاعتماد عبر نسخ الجهاز.
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
                synchronizable: false,
              ),
            );

  final FlutterSecureStorage _storage;

  @override
  Future<String> getOrCreateDatabaseKey() async {
    final existing = await _storage.read(key: AppConstants.keyDbCipherKey);
    if (existing != null && existing.isNotEmpty) return existing;

    // مفتاح خام 32 بايت بصيغة hex لاستخدامه مع SQLCipher
    // (PRAGMA key = "x'...'") — أقوى من تمرير عبارة نصية.
    final key = CryptoUtils.generateDatabaseKeyHex();
    await _storage.write(key: AppConstants.keyDbCipherKey, value: key);
    AppLogger.info('تم توليد مفتاح تشفير جديد لقاعدة البيانات', tag: 'SecureStorage');
    return key;
  }

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> saveRouterSecret(int routerId, String encryptedPayload) =>
      _storage.write(
        key: '${AppConstants.keyRouterCredsPrefix}$routerId',
        value: encryptedPayload,
      );

  @override
  Future<String?> readRouterSecret(int routerId) =>
      _storage.read(key: '${AppConstants.keyRouterCredsPrefix}$routerId');

  @override
  Future<void> deleteRouterSecret(int routerId) =>
      _storage.delete(key: '${AppConstants.keyRouterCredsPrefix}$routerId');
}

final secureStorageServiceProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageServiceImpl(),
);
