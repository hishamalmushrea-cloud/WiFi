import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

/// حالة جلسة التقاط واحدة.
enum CaptureStatus { idle, running, unsupported, error }

/// يلفّ EventChannel الأصلي لتدفّق سطور الحزم.
///
/// على Android مع Root + tcpdump تصل سطور حقيقية لحظياً؛
/// وبدونها تتحوّل الحالة إلى [CaptureStatus.unsupported] فتعرض
/// الواجهة رسالة تدهور آمن بدل شاشة ميتة.
class PacketCaptureService {
  PacketCaptureService(this._channel);

  final EventChannel _channel;

  StreamSubscription<dynamic>? _sub;
  final _linesController = StreamController<String>.broadcast();
  final _statusController = StreamController<CaptureStatus>.broadcast();
  CaptureStatus _status = CaptureStatus.idle;

  Stream<String> get lines => _linesController.stream;
  Stream<CaptureStatus> get statusStream => _statusController.stream;
  CaptureStatus get status => _status;

  void _setStatus(CaptureStatus s) {
    _status = s;
    _statusController.add(s);
  }

  void start() {
    if (_status == CaptureStatus.running) return;
    _setStatus(CaptureStatus.running);

    _sub = _channel.receiveBroadcastStream().listen(
      (event) {
        _linesController.add(event.toString());
      },
      onError: (Object e) {
        final code = e is PlatformException ? e.code : '';
        if (code == 'NO_TCPDUMP') {
          _setStatus(CaptureStatus.unsupported);
          AppLogger.warning('tcpdump غير متوفر — التقاط الحزم غير ممكن',
              tag: 'PacketCapture');
        } else {
          _setStatus(CaptureStatus.error);
          AppLogger.error('فشل التقاط الحزم', error: e, tag: 'PacketCapture');
        }
      },
      onDone: () {
        if (_status == CaptureStatus.running) _setStatus(CaptureStatus.idle);
      },
    );
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _setStatus(CaptureStatus.idle);
  }

  void dispose() {
    _sub?.cancel();
    _linesController.close();
    _statusController.close();
  }
}

/// مزود الخدمة — كائن واحد طوال عمر التطبيق.
final packetCaptureServiceProvider = Provider<PacketCaptureService>((ref) {
  final service = PacketCaptureService(
    const EventChannel(AppConstants.channelPacketCapture),
  );
  ref.onDispose(service.dispose);
  return service;
});
