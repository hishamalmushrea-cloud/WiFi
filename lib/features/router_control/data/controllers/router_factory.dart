import 'package:dio/dio.dart';

import '../../../../core/domain/entities/router.dart';
import '../../../../core/utils/app_logger.dart';
import 'base_router_controller.dart';
import 'controllers_set_a.dart';
import 'controllers_set_b.dart';
import 'router_controller.dart';
import 'router_http_client.dart';

/// مصنع متحكمات الراوتر.
///
/// مسؤول عن:
///  - إنشاء المتحكم المناسب للماركة [createController].
///  - الاكتشاف التلقائي لنوع الراوتر من بصمة استجابته
///    (عنوان الصفحة/ترويسة Server) في [autoDetect].
class RouterFactory {
  RouterFactory(Dio dio) : _http = RouterHttpClient(dio);

  final RouterHttpClient _http;

  /// ينشئ متحكم الماركة المطلوبة (أو العام).
  RouterController createController(RouterBrand brand) {
    switch (brand) {
      case RouterBrand.tpLink:
        return TpLinkController(_http);
      case RouterBrand.dLink:
        return DLinkController(_http);
      case RouterBrand.huawei:
        return HuaweiController(_http);
      case RouterBrand.xiaomi:
        return XiaomiController(_http);
      case RouterBrand.cisco:
        return CiscoController(_http);
      case RouterBrand.asus:
        return AsusController(_http);
      case RouterBrand.netgear:
        return NetgearController(_http);
      case RouterBrand.zte:
        return ZteController(_http);
      case RouterBrand.tenda:
        return TendaController(_http);
      case RouterBrand.generic:
        return GenericController(_http);
    }
  }

  /// يكتشف الماركة من فحص الصفحة الرئيسية للراوتر.
  ///
  /// يعتمد على بصمات نصية في عنوان الصفحة/ترويسة `Server`
  /// التي تطبعها واجهات المصنّعين، وهي طريقة التخمين المعتمدة
  /// قبل تسجيل الدخول. الفشل يعيد [RouterBrand.generic].
  Future<RouterBrand> autoDetect(String ip) async {
    final base = ip.startsWith('http') ? ip : 'http://$ip';
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 6),
        validateStatus: (s) => s != null && s < 500,
      ));
      final res = await dio.get<dynamic>('$base/', options: Options(responseType: ResponseType.plain));
      final body = res.data?.toString().toLowerCase() ?? '';
      final server = res.headers.value('server')?.toLowerCase() ?? '';
      final haystack = '$body $server';

      final fingerprints = <List<dynamic>>[
        [RouterBrand.tpLink, ['tp-link', 'tplink']],
        [RouterBrand.dLink, ['d-link', 'dlink']],
        [RouterBrand.huawei, ['huawei', 'hg8', 'eg8']],
        [RouterBrand.xiaomi, ['xiaomi', 'miwifi', 'redmi']],
        [RouterBrand.cisco, ['cisco', 'linksys']],
        [RouterBrand.asus, ['asus', 'rt-']],
        [RouterBrand.netgear, ['netgear', 'nighthawk']],
        [RouterBrand.zte, ['zte', 'zxhn', 'f660']],
        [RouterBrand.tenda, ['tenda', 'tendawifi']],
      ];

      for (final entry in fingerprints) {
        final brand = entry[0] as RouterBrand;
        final markers = entry[1] as List<String>;
        if (markers.any(haystack.contains)) {
          AppLogger.info('اكتُشف الراوتر تلقائياً: ${brand.name}', tag: 'RouterFactory');
          return brand;
        }
      }
    } catch (e) {
      AppLogger.warning('تعذّر اكتشاف نوع الراوتر تلقائياً', error: e);
    }
    return RouterBrand.generic;
  }
}
