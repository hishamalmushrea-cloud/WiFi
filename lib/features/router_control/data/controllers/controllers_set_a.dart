import '../../../../core/domain/entities/router.dart';
import 'base_router_controller.dart';
import 'router_http_client.dart';

/// متحكمات الماركات — النصف الأول (1–5).
///
/// المسارات مأخوذة من واجهات الويب الشائعة لكل مصنّع؛ تُضبط
/// كافتراضات وتتجاوزها الماركة عند اختلاف الجيل/الإصدار. منطق
/// الطلب والتفسير مشترك في [BaseRouterController].

class TpLinkController extends BaseRouterController {
  TpLinkController(super.http);
  @override
  RouterBrand get brand => RouterBrand.tpLink;
  @override
  RouterEndpoints get endpoints => const RouterEndpoints(
        loginPath: '/cgi/login',
        infoPath: '/cgi/model',
        statsPath: '/cgi/status',
        clientsPath: '/cgi/clients',
        blockPath: '/cgi/access_control',
        wifiPath: '/cgi/wifi',
        guestPath: '/cgi/guest',
        portForwardPath: '/cgi/virtual_server',
        macFilterPath: '/cgi/mac_filter',
        rebootPath: '/cgi/reboot',
        factoryResetPath: '/cgi/reset',
      );
}

class DLinkController extends BaseRouterController {
  DLinkController(super.http);
  @override
  RouterBrand get brand => RouterBrand.dLink;
  @override
  RouterEndpoints get endpoints => const RouterEndpoints(
        loginPath: '/login.cgi',
        infoPath: '/device_info.cgi',
        statsPath: '/status.cgi',
        clientsPath: '/clients.cgi',
        blockPath: '/access_control.cgi',
        wifiPath: '/wireless.cgi',
        guestPath: '/guest.cgi',
        portForwardPath: '/port_forward.cgi',
        macFilterPath: '/mac_filter.cgi',
        rebootPath: '/reboot.cgi',
        factoryResetPath: '/factory_reset.cgi',
      );
}

class HuaweiController extends BaseRouterController {
  HuaweiController(super.http);
  @override
  RouterBrand get brand => RouterBrand.huawei;
  @override
  RouterEndpoints get endpoints => const RouterEndpoints(
        loginPath: '/api/system/user_login',
        infoPath: '/api/system/deviceinfo',
        statsPath: '/api/system/traffic',
        clientsPath: '/api/ntwk/clients',
        blockPath: '/api/ntwk/access',
        wifiPath: '/api/ntwk/wlan',
        guestPath: '/api/ntwk/guest',
        portForwardPath: '/api/ntwk/portforward',
        macFilterPath: '/api/ntwk/macfilter',
        rebootPath: '/api/system/reboot',
        factoryResetPath: '/api/system/factory_reset',
      );
}

class XiaomiController extends BaseRouterController {
  XiaomiController(super.http);
  @override
  RouterBrand get brand => RouterBrand.xiaomi;
  @override
  String get passwordField => 'password';
  @override
  RouterEndpoints get endpoints => const RouterEndpoints(
        loginPath: '/cgi-bin/luci/api/xqsystem/login',
        infoPath: '/cgi-bin/luci/api/misystem/topo_graph',
        statsPath: '/cgi-bin/luci/api/misystem/status',
        clientsPath: '/cgi-bin/luci/api/misystem/devicelist',
        blockPath: '/cgi-bin/luci/api/xqsystem/set_device_info',
        wifiPath: '/cgi-bin/luci/api/xqnetwork/wifi_detail',
        guestPath: '/cgi-bin/luci/api/xqnetwork/guest_wifi',
        portForwardPath: '/cgi-bin/luci/api/xqnetwork/portfwd',
        macFilterPath: '/cgi-bin/luci/api/xqnetwork/macfilter',
        rebootPath: '/cgi-bin/luci/api/xqsystem/reboot',
        factoryResetPath: '/cgi-bin/luci/api/xqsystem/fac_reset',
      );
}

class CiscoController extends BaseRouterController {
  CiscoController(super.http);
  @override
  RouterBrand get brand => RouterBrand.cisco;
  @override
  String get usernameField => 'user';
  @override
  RouterEndpoints get endpoints => const RouterEndpoints(
        loginPath: '/login.html',
        infoPath: '/cgi-bin/config.exp',
        statsPath: '/cgi-bin/stats',
        clientsPath: '/cgi-bin/clients',
        blockPath: '/cgi-bin/access_restrictions',
        wifiPath: '/goform/wlan',
        guestPath: '/goform/guest',
        portForwardPath: '/goform/portforward',
        macFilterPath: '/goform/macfilter',
        rebootPath: '/goform/reboot',
        factoryResetPath: '/goform/factory_defaults',
      );
}
