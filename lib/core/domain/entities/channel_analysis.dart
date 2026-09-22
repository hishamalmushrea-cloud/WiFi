import 'package:freezed_annotation/freezed_annotation.dart';

import 'access_point.dart';

part 'channel_analysis.freezed.dart';

/// تقييم ازدحام قناة واحدة.
@freezed
class ChannelRating with _$ChannelRating {
  const ChannelRating._();

  const factory ChannelRating({
    required int channel,
    required WifiBand band,
    @Default(0) int accessPointCount,
    int? noiseDbm,
    @Default(0) int interferenceScore,
    @Default(3) int rating, // 1 (مزدحم) → 5 (نظيف)
    @Default([]) List<String> recommendedAccessPoints,
    required DateTime analyzedAt,
  }) = _ChannelRating;

  /// القناة المثالية هي الأعلى تقييماً بأقل تداخل.
  bool get isRecommended => rating >= 4;
}

/// توصية أفضل قناة لنطاق معيّن نتيجة التحليل.
@freezed
class ChannelRecommendation with _$ChannelRecommendation {
  const factory ChannelRecommendation({
    required WifiBand band,
    required int bestChannel,
    required int rating,
    required String reason,
  }) = _ChannelRecommendation;
}

/// نتيجة تحليل قنوات نطاق كامل — تستهلكها رسوم القنوات.
@freezed
class WifiAnalysisResult with _$WifiAnalysisResult {
  const factory WifiAnalysisResult({
    required List<AccessPoint> accessPoints,
    required List<ChannelRating> channelRatings,
    required List<ChannelRecommendation> recommendations,
    required DateTime generatedAt,
  }) = _WifiAnalysisResult;
}
