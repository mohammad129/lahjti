import 'package:flutter/foundation.dart';

/// Immutable model representing structured AI evaluation of a student's answer.
@immutable
class PlacementEvaluation {
  final int semanticScore;
  final int grammarScore;
  final int vocabularyScore;
  final int comprehensionScore;
  final int fluencyScore;

  /// Nullable: strictly null when evaluating typed text responses.
  final int? pronunciationScore;
  final double confidence; // 0.0 to 1.0
  final List<String> detectedErrors;
  final String? correctedAnswer;
  final String explanationArabic;
  final bool wasUnderstandable;
  final bool shouldIncreaseDifficulty;
  final bool shouldDecreaseDifficulty;

  const PlacementEvaluation({
    required this.semanticScore,
    required this.grammarScore,
    required this.vocabularyScore,
    required this.comprehensionScore,
    required this.fluencyScore,
    this.pronunciationScore,
    required this.confidence,
    this.detectedErrors = const [],
    this.correctedAnswer,
    required this.explanationArabic,
    required this.wasUnderstandable,
    required this.shouldIncreaseDifficulty,
    required this.shouldDecreaseDifficulty,
  });

  /// Overall composite score (0 to 100)
  double get overallAverage {
    final scores = [
      semanticScore,
      grammarScore,
      vocabularyScore,
      comprehensionScore,
      fluencyScore,
    ];
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  factory PlacementEvaluation.fromJson(Map<String, dynamic> json) {
    final recommendation =
        json['difficultyRecommendation'] as String? ?? 'same';
    return PlacementEvaluation(
      semanticScore: (json['semanticScore'] as num?)?.toInt() ?? 0,
      grammarScore: (json['grammarScore'] as num?)?.toInt() ?? 0,
      vocabularyScore: (json['vocabularyScore'] as num?)?.toInt() ?? 0,
      comprehensionScore: (json['comprehensionScore'] as num?)?.toInt() ?? 0,
      fluencyScore: (json['fluencyScore'] as num?)?.toInt() ?? 0,
      pronunciationScore: (json['pronunciationScore'] as num?)?.toInt(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.8,
      detectedErrors:
          (json['detectedErrors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      correctedAnswer: json['correctedAnswer'] as String?,
      explanationArabic: json['explanationArabic'] as String? ?? '',
      wasUnderstandable: json['wasUnderstandable'] as bool? ?? true,
      shouldIncreaseDifficulty: recommendation == 'increase',
      shouldDecreaseDifficulty: recommendation == 'decrease',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'semanticScore': semanticScore,
      'grammarScore': grammarScore,
      'vocabularyScore': vocabularyScore,
      'comprehensionScore': comprehensionScore,
      'fluencyScore': fluencyScore,
      'pronunciationScore': pronunciationScore,
      'confidence': confidence,
      'detectedErrors': detectedErrors,
      'correctedAnswer': correctedAnswer,
      'explanationArabic': explanationArabic,
      'wasUnderstandable': wasUnderstandable,
      'difficultyRecommendation':
          shouldIncreaseDifficulty
              ? 'increase'
              : (shouldDecreaseDifficulty ? 'decrease' : 'same'),
    };
  }
}
