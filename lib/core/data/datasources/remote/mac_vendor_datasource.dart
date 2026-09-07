import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/app_constants.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/mac_utils.dart';
import 'dio_client.dart';

/// مصدر بيانات مصنّع الأجهزة من OUI عبر api.macvendors.com.
///
/// يُستخدم عند اكتشاف جهاز جديد لإثراء اسم المصنّع. النتيجة
/// تُخزَّن محلياً بعد أول جلب فلا نستهلك الـ API بلا داعٍ.
class MacVendorRemoteDataSource {
  MacVendorRemoteDataSource(this._dio);
  final Dio _dio;

  Future<String?> lookup(String mac) async {
    final oui = MacUtils.oui(mac);
    if (oui == null) return null;

    try {
      final response = await _dio.get<String>(
        '${AppConstants.macVendorApiUrl}$oui',
      );

      // الخدمة تُرجع 404 نصياً عند جهل المصنّع.
      if (response.statusCode == 200 &&
          response.data != null &&
          response.data!.trim().isNotEmpty &&
          response.data!.trim().toUpperCase() != 'NOT FOUND') {
        return response.data!.trim();
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      AppLogger.warning('فشل جلب مصنّع MAC', error: e);
      // لا نُفشل الفحص بسبب خدمة جانبية — نعيد null بهدوء.
      return null;
    } catch (e) {
      AppLogger.warning('استثناء غير متوقع في مصنّع MAC', error: e);
      return null;
    }
  }
}

final macVendorRemoteDataSourceProvider =
    Provider<MacVendorRemoteDataSource>(
  (ref) => MacVendorRemoteDataSource(ref.watch(dioProvider)),
);
