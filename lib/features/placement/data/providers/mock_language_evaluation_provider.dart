import 'package:lahjti/core/errors/exceptions.dart';
import '../../../onboarding/domain/models/age_group.dart';
import '../../../onboarding/domain/models/learning_goal.dart';
import '../../../onboarding/domain/models/native_language.dart';
import '../../../onboarding/domain/models/supported_language.dart';
import '../../domain/models/placement_answer.dart';
import '../../domain/models/placement_evaluation.dart';
import '../../domain/models/placement_question.dart';
import '../../domain/providers/language_evaluation_provider.dart';

/// Mock / Development evaluation provider returning deterministic structured AI evaluation.
///
/// NOTE: This is for architectural verification only. Does not connect to external LLMs.
class MockLanguageEvaluationProvider implements LanguageEvaluationProvider {
  final bool shouldSimulateNetworkDelay;

  const MockLanguageEvaluationProvider({
    this.shouldSimulateNetworkDelay = true,
  });

  @override
  Future<PlacementEvaluation> evaluate({
    required SupportedLanguage targetLanguage,
    required NativeLanguage nativeLanguage,
    required AgeGroup ageGroup,
    required LearningGoal learningGoal,
    required PlacementQuestion question,
    required PlacementAnswer answer,
  }) async {
    if (shouldSimulateNetworkDelay) {
      await Future.delayed(const Duration(milliseconds: 250));
    }

    // Support intentional error simulation for failure/retry tests
    if (answer.userResponse == '__SIMULATE_ERROR__') {
      throw const ServerException(
        message: 'Simulated evaluation engine timeout',
      );
    }

    // 1. Skipped / "I don't know" response
    if (answer.skipped || answer.userResponse.trim().isEmpty) {
      return const PlacementEvaluation(
        semanticScore: 10,
        grammarScore: 10,
        vocabularyScore: 10,
        comprehensionScore: 20,
        fluencyScore: 10,
        pronunciationScore: null, // Strictly null for text simulation
        confidence: 0.95,
        detectedErrors: ['لم تتم المحاولة'],
        explanationArabic: 'عادي جدًا. هاي بتساعدني أعرف من وين نبدأ.',
        wasUnderstandable: false,
        shouldIncreaseDifficulty: false,
        shouldDecreaseDifficulty: true,
      );
    }

    final text = answer.userResponse.trim();
    final wordCount = text.split(RegExp(r'\s+')).length;

    // 2. Strong / Comprehensive answer (multiple words or clear sentence)
    if (wordCount >= 3 || text.length >= 10) {
      return PlacementEvaluation(
        semanticScore: 90,
        grammarScore: 85,
        vocabularyScore: 88,
        comprehensionScore: 92,
        fluencyScore: 86,
        pronunciationScore: null, // Strictly null for text simulation
        confidence: 0.9,
        detectedErrors: const [],
        correctedAnswer: text,
        explanationArabic: 'ممتاز 👏 نرفعها شوي.',
        wasUnderstandable: true,
        shouldIncreaseDifficulty: true,
        shouldDecreaseDifficulty: false,
      );
    }

    // 3. Moderate / Basic answer (1-2 words)
    if (wordCount >= 1 && text.length >= 3) {
      return PlacementEvaluation(
        semanticScore: 65,
        grammarScore: 60,
        vocabularyScore: 70,
        comprehensionScore: 70,
        fluencyScore: 60,
        pronunciationScore: null, // Strictly null for text simulation
        confidence: 0.8,
        detectedErrors: const ['إجابة مقتضبة'],
        correctedAnswer: text,
        explanationArabic: 'قريب جدًا. فهمت عليك، بس في شغلة صغيرة.',
        wasUnderstandable: true,
        shouldIncreaseDifficulty: false,
        shouldDecreaseDifficulty: false,
      );
    }

    // 4. Very weak / Incomplete answer
    return const PlacementEvaluation(
      semanticScore: 30,
      grammarScore: 25,
      vocabularyScore: 30,
      comprehensionScore: 35,
      fluencyScore: 20,
      pronunciationScore: null, // Strictly null for text simulation
      confidence: 0.75,
      detectedErrors: ['كلمة غير مكتملة أو غير دقيقة'],
      explanationArabic: 'ولا يهمك، خلينا نجرب إشي أبسط.',
      wasUnderstandable: false,
      shouldIncreaseDifficulty: false,
      shouldDecreaseDifficulty: true,
    );
  }
}
