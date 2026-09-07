import '../../../../core/domain/entities/router.dart';
import 'base_router_controller.dart';

/// متحكمات الماركات — النصف الثاني (6–10 + العام).

class AsusController extends BaseRouterController {
  AsusController(super.http);
  @override
  RouterBrand get brand => RouterBrand.asus;
  @override
  String get usernameField => 'login_username';
  @override
  String get passwordField => 'login_passwd';
  @override
  RouterEndpoints get endpoints => const RouterEndpoints(
        loginPath: '/login.cgi',
        infoPath: '/status_overview.asp',
        statsPath: '/status_overview.asp',
        clientsPath: '/update_clients.asp',
        blockPath: '/Main_AdmSchedule.asp',
        wifiPath: '/Advanced_Wireless_Content.asp',
        guestPath: '/Advanced_WGuestNetwork.asp',
        portForwardPath: '/VirtualServer.asp',
        macFilterPath: '/Advanced_MACFilter.asp',
        rebootPath: '/reboot.cgi',
        factoryResetPath: '/factory_reset.cgi',
      );
}

class NetgearController extends BaseRouterController {
  NetgearController(super.http);
  @override
  RouterBrand get brand => RouterBrand.netgear;
  @override
  String get usernameField => 'uname';
  @override
  String get passwordField => 'passwd';
  @override
  RouterEndpoints get endpoints => const RouterEndpoints(
        loginPath: '/login.cgi',
        infoPath: '/model_info.htm',
        statsPath: '/traffic.htm',
        clientsPath: '/DEV_device.htm',
        blockPath: '/access_control.htm',
        wifiPath: '/WLG_wireless.htm',
        guestPath: '/guest_net.htm',
        portForwardPath: '/port_forwarding.htm',
        macFilterPath: '/access_mac.htm',
        rebootPath: '/reboot.cgi',
        factoryResetPath: '/erase_cfg.cgi',
      );
}

class ZteController extends BaseRouterController {
  ZteController(super.http);
  @override
  RouterBrand get brand => RouterBrand.zte;
  @override
  String get usernameField => 'Username';
  @override
  String get passwordField => 'Password';
  @override
  RouterEndpoints get endpoints => const RouterEndpoints(
        loginPath: '/',
        infoPath: '/cgi-bin/get_page?model',
        statsPath: '/cgi-bin/get_page?status',
        clientsPath: '/cgi-bin/get_page?clients',
        blockPath: '/cgi-bin/access',
        wifiPath: '/cgi-bin/wlan_basic',
        guestPath: '/cgi-bin/guest',
        portForwardPath: '/cgi-bin/virtual_server',
        macFilterPath: '/cgi-bin/mac_filter',
        rebootPath: '/cgi-bin/reboot',
        factoryResetPath: '/cgi-bin/factory_reset',
      );
}

class TendaController extends BaseRouterController {
  TendaController(super.http);
  @override
  RouterBrand get brand => RouterBrand.tenda;
  @override
  String get passwordField => 'password';
  @override
  RouterEndpoints get endpoints => const RouterEndpoints(
        // دخول تيندا يعتمد كلمة المرور فقط (بدون اسم مستخدم).
        loginPath: '/login/Auth',
        infoPath: '/cgi-bin/DashBoard',
        statsPath: '/cgi-bin/getSysStatus',
        clientsPath: '/cgi-bin/getConnectList',
        blockPath: '/cgi-bin/accessControl',
        wifiPath: '/cgi-bin/wifiBasic',
        guestPath: '/cgi-bin/guestNet',
        portForwardPath: '/cgi-bin/virtualServer',
        macFilterPath: '/cgi-bin/macFilter',
        rebootPath: '/cgi-bin/reboot',
        factoryResetPath: '/cgi-bin/factoryReset',
      );

  @override
  Future<bool> login({
    required String ip,
    required String username,
    required String password,
  }) {
    // تيندا لا تستخدم اسم المستخدم؛ نمرّره فارغاً للنموذج.
    return super.login(ip: ip, username: '', password: password);
  }
}

/// متحكم عام (fallback) — يجرّب مسارات شائعة ويتعامل بأفضل جهد.
class GenericController extends BaseRouterController {
  GenericController(super.http);
  @override
  RouterBrand get brand => RouterBrand.generic;
  @override
  RouterEndpoints get endpoints => const RouterEndpoints(
        loginPath: '/',
        infoPath: '/api/system/info',
        statsPath: '/api/status',
        clientsPath: '/api/clients',
        blockPath: '/api/access_control',
        wifiPath: '/api/wifi',
        guestPath: '/api/guest',
        portForwardPath: '/api/port_forward',
        macFilterPath: '/api/mac_filter',
        rebootPath: '/api/reboot',
        factoryResetPath: '/api/factory_reset',
      );
}
