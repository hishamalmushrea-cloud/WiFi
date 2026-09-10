import 'dart:convert';

import '../../../../core/domain/entities/router.dart';
import '../../../../core/utils/app_logger.dart';
import 'router_controller.dart';
import 'router_http_client.dart';

/// نقاط نهاية واجهة الراوتر لكل ماركة.
///
/// كل ماركة تملأ هذه المسارات (تختلف بين واجهات المصنّعين)،
/// بينما يوفّر [BaseRouterController] منطق الطلب والتفسير المشترك.
class RouterEndpoints {
  const RouterEndpoints({
    this.loginPath = '/',
    this.infoPath,
    this.statsPath,
    this.clientsPath,
    this.blockPath,
    this.wifiPath,
    this.guestPath,
    this.portForwardPath,
    this.macFilterPath,
    this.rebootPath,
    this.factoryResetPath,
  });

  final String loginPath;
  final String? infoPath;
  final String? statsPath;
  final String? clientsPath;
  final String? blockPath;
  final String? wifiPath;
  final String? guestPath;
  final String? portForwardPath;
  final String? macFilterPath;
  final String? rebootPath;
  final String? factoryResetPath;
}

/// منطق مشترك لكل متحكمات الراوتر.
///
/// الماركات تورّث هذا الصنف وتضبط [endpoints] وأسماء حقول النماذج
/// فقط؛ العمليات تُنفَّذ بطلبات JSON/نماذج قياسية. عندما لا تدعم
/// واجهة الماركة مساراً ما، يعيد التنفيذ الافتراضي قيمة آمنة
/// (قائمة فارغة/نجاح وهمي) ويسجّل ذلك، فينحدر السلوك بأمان.
abstract class BaseRouterController implements RouterController {
  BaseRouterController(this._http);

  final RouterHttpClient _http;

  /// جلسة الدخول الحالية (تُستخدم في مسارات بعض الماركات).
  String? sessionId;

  RouterEndpoints get endpoints;

  /// حقول نموذج الدخول (تختلف تسمياتها بين المصنّعين).
  String get usernameField => 'username';
  String get passwordField => 'password';

  @override
  Future<bool> login({
    required String ip,
    required String username,
    required String password,
  }) async {
    _http.configure(ip);
    try {
      final res = await _http.post(
        endpoints.loginPath,
        body: {
          usernameField: username,
          passwordField: password,
        },
      );
      sessionId = _http.sessionToken;
      // نعتبر الدخول ناجحاً إن لم يُرمَ استثناء مصادقة.
      return res.statusCode != null &&
          res.statusCode! < 400;
    } catch (e) {
      AppLogger.warning('فشل دخول الراوتر ($brand)', error: e);
      return false;
    }
  }

  // ── أدوات قراءة JSON المشتركة ──────────────────────────────
  Future<Map<String, dynamic>?> _readJson(String? path) async {
    if (path == null) return null;
    final res = await _http.get(path);
    if (res.data is Map<String, dynamic>) return res.data as Map<String, dynamic>;
    try {
      return jsonDecode(res.data.toString()) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<RouterInfo> getInfo() async {
    final json = await _readJson(endpoints.infoPath);
    return RouterInfo(
      brand: brand,
      ip: _http.baseUrl.replaceAll(RegExp(r'https?://'), ''),
      model: json?['model'] as String?,
      firmware: json?['firmware'] as String? ?? json?['fw'] as String?,
      macAddress: json?['mac'] as String? ?? json?['macAddress'] as String?,
      isActive: true,
    );
  }

  @override
  Future<RouterTrafficStats> getTrafficStats() async {
    final json = await _readJson(endpoints.statsPath);
    if (json == null) return const RouterTrafficStats();
    return RouterTrafficStats(
      connectedClients: (json['clients'] as num?)?.toInt() ?? 0,
      totalUploadKbps: (json['upload'] as num?)?.toInt() ?? 0,
      totalDownloadKbps: (json['download'] as num?)?.toInt() ?? 0,
      uptimeSeconds: (json['uptime'] as num?)?.toInt() ?? 0,
      cpuUsage: (json['cpu'] as num?)?.toDouble(),
      memoryUsage: (json['mem'] as num?)?.toDouble(),
    );
  }

  @override
  Future<List<RouterClient>> getConnectedClients() async {
    if (endpoints.clientsPath == null) return const [];
    final res = await _http.get(endpoints.clientsPath!);
    List<dynamic> raw = const [];
    try {
      final decoded = jsonDecode(res.data.toString());
      raw = (decoded is Map ? decoded['clients'] : decoded) as List? ?? const [];
    } catch (_) {
      return const [];
    }
    return raw
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => RouterClient(
              mac: (e['mac'] ?? e['macAddress'] ?? '').toString(),
              ip: (e['ip'] ?? e['ipAddress'] ?? '').toString(),
              name: e['name']?.toString(),
              upSpeedKbps: (e['upload'] as num?)?.toInt() ?? 0,
              downSpeedKbps: (e['download'] as num?)?.toInt() ?? 0,
            ))
        .where((c) => c.mac.isNotEmpty)
        .toList();
  }

  @override
  Future<bool> blockDevice(String mac) => _postAction(endpoints.blockPath, {'mac': mac, 'block': '1'});

  @override
  Future<bool> unblockDevice(String mac) =>
      _postAction(endpoints.blockPath, {'mac': mac, 'block': '0'});

  @override
  Future<bool> setDeviceSpeedLimit(String mac, int kbps) =>
      _postAction(endpoints.blockPath, {'mac': mac, 'limit': kbps.toString()});

  @override
  Future<RouterWifiSettings> getWifiSettings() async {
    final json = await _readJson(endpoints.wifiPath);
    if (json == null) return const RouterWifiSettings(ssid: '', password: '');
    return RouterWifiSettings(
      ssid: json['ssid'] as String? ?? '',
      password: json['password'] as String? ?? json['key'] as String? ?? '',
      channel: (json['channel'] as num?)?.toInt() ?? 6,
      security: json['security'] as String? ?? 'WPA2PSK',
      isEnabled: json['enabled'] as bool? ?? true,
      isHidden: json['hidden'] as bool? ?? false,
      channelWidth: (json['bandwidth'] as num?)?.toInt() ?? 20,
    );
  }

  @override
  Future<bool> setWifiSettings(RouterWifiSettings s) =>
      _postAction(endpoints.wifiPath, {
        'ssid': s.ssid,
        'password': s.password,
        'channel': s.channel.toString(),
        'security': s.security,
        'enabled': s.isEnabled ? '1' : '0',
        'hidden': s.isHidden ? '1' : '0',
        'bandwidth': s.channelWidth.toString(),
      });

  @override
  Future<GuestNetwork> getGuestNetwork() async {
    final json = await _readJson(endpoints.guestPath);
    if (json == null) return const GuestNetwork(ssid: '', password: '');
    return GuestNetwork(
      ssid: json['ssid'] as String? ?? '',
      password: json['password'] as String? ?? '',
      isEnabled: json['enabled'] as bool? ?? false,
      speedLimitKbps: (json['limit'] as num?)?.toInt() ?? 10240,
      isolateClients: json['isolate'] as bool? ?? true,
    );
  }

  @override
  Future<bool> setGuestNetwork(GuestNetwork n) =>
      _postAction(endpoints.guestPath, {
        'ssid': n.ssid,
        'password': n.password,
        'enabled': n.isEnabled ? '1' : '0',
        'limit': n.speedLimitKbps.toString(),
      });

  @override
  Future<List<PortForwardRule>> getPortForwardRules() async {
    if (endpoints.portForwardPath == null) return const [];
    final res = await _http.get(endpoints.portForwardPath!);
    try {
      final decoded = jsonDecode(res.data.toString());
      final raw = (decoded is Map ? decoded['rules'] : decoded) as List? ?? const [];
      return raw
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => PortForwardRule(
                id: e['id']?.toString(),
                name: e['name'] as String? ?? '',
                externalPort: (e['extPort'] as num?)?.toInt() ?? 0,
                internalPort: (e['intPort'] as num?)?.toInt() ?? 0,
                internalIp: e['ip'] as String? ?? '',
                protocol: e['protocol'] as String? ?? 'TCP',
                enabled: e['enabled'] as bool? ?? true,
              ))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<bool> addPortForwardRule(PortForwardRule rule) =>
      _postAction(endpoints.portForwardPath, {
        'name': rule.name,
        'extPort': rule.externalPort.toString(),
        'intPort': rule.internalPort.toString(),
        'ip': rule.internalIp,
        'protocol': rule.protocol,
      });

  @override
  Future<bool> removePortForwardRule(String id) =>
      _postAction(endpoints.portForwardPath, {'delete': id});

  @override
  Future<List<MacFilterEntry>> getMacFilter() async {
    if (endpoints.macFilterPath == null) return const [];
    final res = await _http.get(endpoints.macFilterPath!);
    try {
      final decoded = jsonDecode(res.data.toString());
      final raw = (decoded is Map ? decoded['filters'] : decoded) as List? ?? const [];
      return raw
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => MacFilterEntry(
                mac: e['mac'] as String? ?? '',
                name: e['name'] as String?,
                isAllowed: e['allow'] as bool? ?? true,
              ))
          .where((f) => f.mac.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<bool> setMacFilter(List<MacFilterEntry> entries) =>
      _postAction(endpoints.macFilterPath, {
        'filters': jsonEncode(entries
            .map((e) => {'mac': e.mac, 'name': e.name, 'allow': e.isAllowed})
            .toList()),
      });

  @override
  Future<bool> reboot() => _postAction(endpoints.rebootPath, {'action': 'reboot'});

  @override
  Future<bool> factoryReset() =>
      _postAction(endpoints.factoryResetPath, {'action': 'reset'});

  /// ينفّذ فعلاً POST ويُرجع نجاحاً بأمان حتى غياب المسار.
  Future<bool> _postAction(String? path, Map<String, dynamic> body) async {
    if (path == null) {
      AppLogger.info('المسار $path غير مدعوم لهذه الماركة ($brand)');
      return false;
    }
    try {
      final res = await _http.post(path, body: body);
      return res.statusCode != null && res.statusCode! < 400;
    } catch (e) {
      AppLogger.warning('فشل إجراء على الراوتر ($brand)', error: e);
      return false;
    }
  }
}
