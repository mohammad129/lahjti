import '../../../onboarding/domain/models/experience_level.dart';
import '../models/cefr_level.dart';
import '../models/placement_evaluation.dart';
import '../models/placement_result.dart';
import '../models/placement_session.dart';

/// Configuration for the adaptive placement engine's stopping and difficulty calibration rules.
class PlacementEngineConfig {
  final int minQuestions;
  final int targetQuestions;
  final int maxQuestions;
  final int strongScoreThreshold;
  final int weakScoreThreshold;
  final double confidenceThreshold;

  const PlacementEngineConfig({
    this.minQuestions = 5,
    this.targetQuestions = 8,
    this.maxQuestions = 12,
    this.strongScoreThreshold = 75,
    this.weakScoreThreshold = 40,
    this.confidenceThreshold = 0.75,
  });
}

/// Adaptive Language Placement Engine that dynamically navigates student difficulty,
/// manages stopping criteria, and synthesizes the final [PlacementResult].
class PlacementEngine {
  final PlacementEngineConfig config;

  const PlacementEngine({this.config = const PlacementEngineConfig()});

  /// Maps the student's initial self-assessment to a safe starting difficulty.
  CefrLevel determineInitialDifficulty(ExperienceLevel selfAssessment) {
    switch (selfAssessment) {
      case ExperienceLevel.zero:
        return CefrLevel.preA1;
      case ExperienceLevel.basic:
        return CefrLevel.a1;
      case ExperienceLevel.intermediate:
        return CefrLevel.a2;
      case ExperienceLevel.conversational:
        return CefrLevel.b1;
      case ExperienceLevel.advanced:
        return CefrLevel.b2;
    }
  }

  /// Calculates the next appropriate difficulty based on recent performance and answer patterns.
  CefrLevel calculateNextDifficulty(
    PlacementSession session,
    PlacementEvaluation latestEvaluation,
  ) {
    final currentDiff = session.currentDifficulty;
    final evaluations = session.evaluations;

    // Check for extreme streaks in the last 2-3 answers
    if (evaluations.length >= 2) {
      final last2 = evaluations.sublist(evaluations.length - 2);
      final allStrong = last2.every(
        (e) => e.overallAverage >= config.strongScoreThreshold,
      );
      final allWeak = last2.every(
        (e) => e.overallAverage <= config.weakScoreThreshold,
      );

      if (allStrong) {
        return currentDiff.nextLevel;
      }
      if (allWeak) {
        return currentDiff.previousLevel;
      }
    }

    // Single evaluation guidance
    if (latestEvaluation.shouldIncreaseDifficulty ||
        latestEvaluation.overallAverage >= config.strongScoreThreshold) {
      return currentDiff.nextLevel;
    } else if (latestEvaluation.shouldDecreaseDifficulty ||
        latestEvaluation.overallAverage <= config.weakScoreThreshold) {
      return currentDiff.previousLevel;
    }

    return currentDiff;
  }

  /// Evaluates stopping criteria to determine whether the session should conclude.
  bool shouldStop(PlacementSession session) {
    final count = session.answers.length;

    // 1. Mandatory upper bound
    if (count >= config.maxQuestions) {
      return true;
    }

    // 2. Minimum questions check
    if (count < config.minQuestions) {
      return false;
    }

    // 3. True Beginner early stop check: If user skipped / failed 3 consecutive at PreA1
    if (session.currentDifficulty == CefrLevel.preA1 && count >= 4) {
      final recentAnswers = session.answers.sublist(count - 3);
      final allSkippedOrZero = recentAnswers.every((a) => a.skipped);
      if (allSkippedOrZero) {
        return true;
      }
    }

    // 4. Convergence check: If last 3 answers are consistent at the same difficulty with high confidence
    if (count >= config.targetQuestions) {
      return true;
    }

    if (count >= config.minQuestions + 1 && session.evaluations.length >= 3) {
      final last3 = session.evaluations.sublist(session.evaluations.length - 3);
      final avgScores = last3.map((e) => e.overallAverage).toList();
      final minScore = avgScores.reduce((a, b) => a < b ? a : b);
      final maxScore = avgScores.reduce((a, b) => a > b ? a : b);
      final scoreVariance = maxScore - minScore;

      final avgConfidence =
          last3.map((e) => e.confidence).reduce((a, b) => a + b) / 3;

      if (scoreVariance <= 15 && avgConfidence >= config.confidenceThreshold) {
        return true;
      }
    }

    return false;
  }

  /// Synthesizes all evaluations into the final holistic [PlacementResult].
  PlacementResult calculateFinalResult(PlacementSession session) {
    if (session.evaluations.isEmpty) {
      return PlacementResult(
        estimatedCefrLevel: session.currentDifficulty,
        overallScore: 50,
        comprehensionScore: 50,
        vocabularyScore: 50,
        grammarScore: 50,
        speakingScore: null,
        listeningScore: null,
        pronunciationScore: null, // Strictly null for text responses
        fluencyScore: 50,
        strengths: ['الرغبة في التعلم', 'الاستماع الجيد'],
        weaknesses: ['المفردات الأساسية', 'بناء الجمل'],
        recommendedStartingDifficulty: session.currentDifficulty,
        recommendedFocusAreas: ['الكلمات اليومية', 'التحيات والتعريف بالنفس'],
      );
    }

    final evals = session.evaluations;

    // Calculate averages
    final totalComprehension = evals
        .map((e) => e.comprehensionScore)
        .reduce((a, b) => a + b);
    final totalVocab = evals
        .map((e) => e.vocabularyScore)
        .reduce((a, b) => a + b);
    final totalGrammar = evals
        .map((e) => e.grammarScore)
        .reduce((a, b) => a + b);
    final totalFluency = evals
        .map((e) => e.fluencyScore)
        .reduce((a, b) => a + b);
    final totalSemantic = evals
        .map((e) => e.semanticScore)
        .reduce((a, b) => a + b);

    final n = evals.length;
    final avgComp = (totalComprehension / n).round();
    final avgVocab = (totalVocab / n).round();
    final avgGrammar = (totalGrammar / n).round();
    final avgFluency = (totalFluency / n).round();
    final avgSemantic = (totalSemantic / n).round();

    final overall =
        ((avgComp + avgVocab + avgGrammar + avgFluency + avgSemantic) / 5)
            .round();

    // Determine estimated CEFR level:
    // Blend final reached difficulty with overall performance
    final finalDiff = session.currentDifficulty;
    CefrLevel estimatedCefr = finalDiff;

    if (overall < 40 && finalDiff.rank > 0) {
      estimatedCefr = finalDiff.previousLevel;
    } else if (overall >= 80 && finalDiff.rank < CefrLevel.values.length - 1) {
      estimatedCefr = finalDiff;
    }

    // Build personalized strengths and focus areas
    final strengths = <String>[];
    final weaknesses = <String>[];
    final focusAreas = <String>[];

    if (avgComp >= avgGrammar && avgComp >= avgVocab) {
      strengths.add('سرعة الفهم والاستيعاب');
    } else {
      focusAreas.add('استيعاب النصوص والمحادثات السريعة');
    }

    if (avgVocab >= 60) {
      strengths.add('حصيلة كلمات جيدة');
    } else {
      weaknesses.add('المفردات التخصصية واليومية');
      focusAreas.add('توسيع بنك الكلمات النشطة');
    }

    if (avgGrammar >= 65) {
      strengths.add('سلامة التركيب اللغوي');
    } else {
      weaknesses.add('تصريف الأفعال وتراكيب الجمل');
      focusAreas.add('تراكيب الجمل الطبيعية بدون تعقيد');
    }

    if (strengths.isEmpty) {
      strengths.add('البداية الواثقة والالتزام بالتجربة');
    }
    if (weaknesses.isEmpty) {
      weaknesses.add('الطلاقة في المواقف العفوية');
    }
    if (focusAreas.isEmpty) {
      focusAreas.add('المحادثات التفاعلية المباشرة');
    }

    return PlacementResult(
      estimatedCefrLevel: estimatedCefr,
      overallScore: overall,
      comprehensionScore: avgComp,
      vocabularyScore: avgVocab,
      grammarScore: avgGrammar,
      speakingScore: null,
      listeningScore: null,
      pronunciationScore: null, // Strictly null - tested via text
      fluencyScore: avgFluency,
      strengths: strengths,
      weaknesses: weaknesses,
      recommendedStartingDifficulty: estimatedCefr,
      recommendedFocusAreas: focusAreas,
    );
  }
}
