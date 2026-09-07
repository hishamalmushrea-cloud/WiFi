import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/app_logger.dart';

/// عميل HTTP مشترك لكل متحكمات الراوترات.
///
/// يدير:
///  - الجلسة (Cookie/Token) بعد تسجيل الدخول.
///  - شهادات TLS الموقّعة ذاتياً (شائعة في الراوترات المنزلية).
///  - تمييز فشل المصادقة (401/403/صفحة login) لرمي [RouterAuthException].
///
/// كل متحكم ماركة يحدّد المسارات فقط؛ هذا العميل يوحّد سلوك الطلبات.
class RouterHttpClient {
  RouterHttpClient(this._dio);

  final Dio _dio;

  String? _baseUrl;
  final Map<String, String> _cookies = {};

  /// بيانات الجلسة بعد الدخول (رمز/كوكي) تُضاف لكل الطلبات.
  String? sessionToken;

  void configure(String ip) {
    _baseUrl = ip.startsWith('http') ? ip : 'http://$ip';
    _dio.options.baseUrl = _baseUrl!;
    _dio.options.contentType = Headers.formUrlEncodedContentType;
    _cookies.clear();
    sessionToken = null;
  }

  String get baseUrl => _baseUrl ?? '';

  Map<String, String> get headers => {
        if (sessionToken != null) 'Authorization': 'Bearer $sessionToken',
        if (_cookies.isNotEmpty)
          'Cookie': _cookies.entries.map((e) => '${e.key}=${e.value}').join('; '),
      };

  /// يلتقط كوكيز الجلسة من رد الدخول لتستخدم في الطلبات التالية.
  void absorbCookies(Response<dynamic> response) {
    final raw = response.headers.map['set-cookie'];
    if (raw == null) return;
    for (final cookie in raw) {
      final pair = cookie.split(';').first;
      final eq = pair.indexOf('=');
      if (eq > 0) {
        _cookies[pair.substring(0, eq).trim()] = pair.substring(eq + 1).trim();
      }
    }
  }

  /// طلب GET مع كشف إعادة التوجيه لصفحة الدخول كفشل مصادقة.
  Future<Response<dynamic>> get(String path,
      {Map<String, dynamic>? query}) async {
    try {
      final res = await _dio.get<dynamic>(
        path,
        queryParameters: query,
        options: Options(headers: headers, followRedirects: false),
      );
      _absorbIfPresent(res);
      _ensureAuthenticated(res);
      return res;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// طلب POST (نماذج دخول/تغيير إعدادات).
  Future<Response<dynamic>> post(String path,
      {Map<String, dynamic>? body}) async {
    try {
      final res = await _dio.post<dynamic>(
        path,
        data: body ?? {},
        options: Options(headers: headers, followRedirects: false),
      );
      _absorbIfPresent(res);
      _ensureAuthenticated(res);
      return res;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  void _absorbIfPresent(Response<dynamic> res) {
    final raw = res.headers.map['set-cookie'];
    if (raw != null) absorbCookies(res);
  }

  /// بعض الراوترات تعيد 200 مع صفحة تسجيل دخول عند انتهاء الجلسة.
  void _ensureAuthenticated(Response<dynamic> res) {
    final body = res.data?.toString() ?? '';
    final lower = body.toLowerCase();
    if (res.statusCode == 401 ||
        res.statusCode == 403 ||
        lower.contains('login') && lower.contains('password') &&
            !lower.contains('loginpassword')) {
      throw const RouterAuthException();
    }
  }

  Never _handleDioError(DioException e) {
    if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
      throw const RouterAuthException();
    }
    AppLogger.warning('فشل اتصال الراوتر: ${e.message}', error: e);
    throw NetworkException('تعذّر الاتصال بالراوتر: ${e.message}');
  }
}
