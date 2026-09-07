import '../../database/app_database.dart';
import '../../domain/entities/router.dart';

/// تحويلات إعدادات الراوتر المخزّنة.
/// (كلمة المرور تبقى في الخزن الآمن ولا تمر عبر الجدول.)
class RouterMapper {
  const RouterMapper._();

  static RouterInfo toEntity(RouterSettingRow r) => RouterInfo(
        id: r.id,
        brand: _parseBrand(r.routerType),
        ip: r.ip,
        username: r.username,
        model: r.model,
        firmware: r.firmware,
        macAddress: r.macAddress,
        lastConnected: r.lastConnected,
        isActive: r.isActive,
      );

  static RouterSettingsCompanion toCompanion(RouterInfo r) =>
      RouterSettingsCompanion(
        id: r.id == null ? const Value.absent() : Value(r.id!),
        routerType: Value(r.brand.name),
        ip: Value(r.ip),
        username: Value(r.username),
        // حقل كلمة المرور في الجدول يبقى فارغاً؛ القيمة الحساسة
        // تُخزَّن مشفّرة في Secure Storage عبر مفتاح الراوتر.
        encryptedPassword: const Value(null),
        model: Value(r.model),
        firmware: Value(r.firmware),
        macAddress: Value(r.macAddress),
        lastConnected: Value(r.lastConnected),
        isActive: Value(r.isActive),
      );

  static RouterBrand _parseBrand(String raw) => RouterBrand.values
      .firstWhere((b) => b.name == raw, orElse: () => RouterBrand.generic);
}
