import '../../../core/domain/entities/access_point.dart';
import '../../../core/domain/entities/channel_analysis.dart';

/// محرّك تحليل قنوات الواي فاي والتداخل.
///
/// منطق خالص (بلا I/O) فيُختبر بسهولة ويُستخدم من المستودع:
///  - يحوّل تردد MHz إلى رقم قناة ونطاق.
///  - يحسب ازدحام كل قناة مع الأخذ في الحسبان اتساع القناة
///    (40/80/160) الذي يجعل AP واحداً يشغل عدة قنوات مجاورة.
///  - يقترح أفضل قناة (الأقل تداخلاً).
class WifiChannelAnalyzer {
  const WifiChannelAnalyzer._();

  /// يحسب رقم القناة من تردد MHz للنطاق 2.4 و 5.
  static int? channelForFrequency(int freqMhz) {
    // 2.4 GHz: القناة 1 عند 2412، كل قناة +5 MHz.
    // القناة 14 (اليابان فقط) استثناء: تقفز 12MHz فوق القناة 13
    // (2472+12=2484) وليس +5 — فالمعادلة العامة تعطي 15 خطأً.
    if (freqMhz == 2484) return 14;
    if (freqMhz >= 2412 && freqMhz <= 2472) {
      return (freqMhz - 2412) ~/ 5 + 1;
    }
    // 5 GHz: القناة 36 عند 5180، كل قناة +5 MHz.
    if (freqMhz >= 5180 && freqMhz <= 5900) {
      return (freqMhz - 5000) ~/ 5;
    }
    // 6 GHz: القناة 1 عند 5955.
    if (freqMhz >= 5955 && freqMhz <= 7125) {
      return (freqMhz - 5950) ~/ 5;
    }
    return null;
  }

  /// قائمة القنوات الأساسية المتاحة للتحليل حسب النطاق.
  static List<int> channelsForBand(WifiBand band) => switch (band) {
        WifiBand.ghz24 => [1, 6, 11], // القنوات غير المتداخلة
        WifiBand.ghz5 => [
            36, 40, 44, 48, 52, 56, 60, 64,
            100, 104, 108, 112, 116, 149, 153, 157, 161, 165,
          ],
        WifiBand.ghz6 => List.generate(59, (i) => i * 4 + 1),
      };

  /// يحلّل نقاط الوصول وينتج تقييم القنوات والتوصيات.
  static WifiAnalysisResult analyze(List<AccessPoint> aps) {
    final bands = [WifiBand.ghz24, WifiBand.ghz5, WifiBand.ghz6];
    final ratings = <ChannelRating>[];
    final recommendations = <ChannelRecommendation>[];
    final now = DateTime.now();

    for (final band in bands) {
      final bandAps = aps.where((a) => a.band == band).toList();
      if (bandAps.isEmpty) continue;

      final channels = channelsForBand(band);
      // قوة الإشارة المجمّعة على كل قناة (يشغلها كل AP قريب).
      final occupancy = <int, List<AccessPoint>>{};
      for (final c in channels) {
        occupancy[c] = [];
      }

      for (final ap in bandAps) {
        // القنوات التي يشغلها AP واحد حسب اتساق قناته.
        for (final c in _coveredChannels(ap, channels)) {
          occupancy[c]?.add(ap);
        }
      }

      ChannelRating? best;
      for (final c in channels) {
        final occupants = occupancy[c] ?? [];
        // كلما زاد عدد المشتركين وقويت إشارتهم، ارتفع التداخل.
        final interference = occupants.fold<int>(
          0,
          (sum, ap) => sum + (ap.signalPercent ~/ 20),
        );
        // تقييم من 5 (نظيف) إلى 1 (مزدحم).
        final rating = (5 - interference).clamp(1, 5);
        final channelRating = ChannelRating(
          channel: c,
          band: band,
          accessPointCount: occupants.length,
          interferenceScore: interference,
          rating: rating,
          recommendedAccessPoints: occupants
              .map((a) => a.displaySsid)
              .take(3)
              .toList(),
          analyzedAt: now,
        );
        ratings.add(channelRating);

        if (best == null || channelRating.rating > best.rating ||
            (channelRating.rating == best.rating &&
                channelRating.accessPointCount < best.accessPointCount)) {
          best = channelRating;
        }
      }

      if (best != null) {
        recommendations.add(ChannelRecommendation(
          band: band,
          bestChannel: best.channel,
          rating: best.rating,
          reason: _recommendationReason(band, best),
        ));
      }
    }

    return WifiAnalysisResult(
      accessPoints: aps,
      channelRatings: ratings,
      recommendations: recommendations,
      generatedAt: now,
    );
  }

  /// القنوات التي يشغلها AP مع مراعاة اتساع النطاق.
  ///
  /// قوائم القنوات (‎[1,6,11] و[36,40,...] وi*4+1) كلها بخطوة قناة
  /// كاملة 20MHz — فالامتداد يُقاس بخانات 20MHz لا 5MHz: قناة 20MHz
  /// تشغل خانة واحدة، و40MHz خانتين، وهكذا. (قبل هذا التصحيح كان
  /// span = width~/5 يجعل AP بعرض 20MHz يغطي [1,6,11] كلها!)
  static List<int> _coveredChannels(AccessPoint ap, List<int> bandChannels) {
    final width = ap.channelWidthMhz ?? 20;
    final span = (width ~/ 20).clamp(1, bandChannels.length);
    final idx = bandChannels.indexOf(ap.channel);
    if (idx == -1) return [ap.channel];
    final start = (idx - span ~/ 2).clamp(0, bandChannels.length - 1);
    final end = (start + span).clamp(1, bandChannels.length);
    return bandChannels.sublist(start, end);
  }

  static String _recommendationReason(WifiBand band, ChannelRating best) {
    final bandLabel = switch (band) {
      WifiBand.ghz24 => '2.4 جيجاهرتز',
      WifiBand.ghz5 => '5 جيجاهرتز',
      WifiBand.ghz6 => '6 جيجاهرتز',
    };
    if (best.accessPointCount == 0) {
      return 'قناة ${best.channel} على نطاق $bandLabel خالية من الشبكات المجاورة.';
    }
    return 'قناة ${best.channel} على نطاق $bandLabel الأقل ازدحاماً '
        '(${best.accessPointCount} شبكة مجاورة).';
  }
}
