import '../../../placement/domain/models/cefr_level.dart';
import '../../../learning/domain/models/learning_skill.dart';
import '../models/exam_models.dart';

/// Service responsible for scoring exam attempts, calculating skill breakdowns,
/// and producing pedagogical recommendations.
class ExamScoringService {
  const ExamScoringService();

  /// Evaluates an exam attempt and generates an [ExamResult].
  ExamResult evaluateAttempt({
    required Exam exam,
    required Map<String, ExamAnswer> answers,
    required String attemptId,
  }) {
    int totalPointsPossible = 0;
    int totalPointsEarned = 0;
    int correctCount = 0;
    int answeredCount = 0;
    int skippedCount = 0;

    // Track points per skill
    final Map<LearningSkill, int> skillPointsEarned = {};
    final Map<LearningSkill, int> skillPointsPossible = {};

    for (final section in exam.sections) {
      final skill = section.skill;
      skillPointsEarned.putIfAbsent(skill, () => 0);
      skillPointsPossible.putIfAbsent(skill, () => 0);

      for (final question in section.questions) {
        final points = question.points;
        totalPointsPossible += points;
        skillPointsPossible[skill] = skillPointsPossible[skill]! + points;

        final answer = answers[question.id];
        if (answer == null || answer.isSkipped) {
          skippedCount++;
          continue;
        }

        answeredCount++;
        final isCorrect = question.isCorrectAnswer(
          answer.selectedOptionIndex,
          answer.spokenText,
        );

        if (isCorrect) {
          correctCount++;
          totalPointsEarned += points;
          skillPointsEarned[skill] = skillPointsEarned[skill]! + points;
        }
      }
    }

    // Normalized overall score 0-100
    final overallScore =
        totalPointsPossible > 0
            ? ((totalPointsEarned / totalPointsPossible) * 100).round().clamp(
              0,
              100,
            )
            : 0;

    // Build skill scores
    final skillScores = <ExamSkillScore>[];
    final strengths = <String>[];
    final areasForImprovement = <String>[];
    final recommendations = <ExamRecommendation>[];

    skillPointsPossible.forEach((skill, possible) {
      if (possible > 0) {
        final earned = skillPointsEarned[skill] ?? 0;
        final percentage = ((earned / possible) * 100).round().clamp(0, 100);

        final skillScore = ExamSkillScore(
          skill: skill,
          scorePercentage: percentage,
          pointsEarned: earned,
          pointsPossible: possible,
        );
        skillScores.add(skillScore);

        if (skillScore.isStrength) {
          strengths.add('إتقان ممتاز في مهارة ${skill.nameArabic}');
        } else if (skillScore.needsPractice) {
          areasForImprovement.add('تحتاج لتعزيز مهارة ${skill.nameArabic}');
          recommendations.add(_generateRecommendationForSkill(skill));
        }
      }
    });

    // Default recommendation if learner mastered all
    if (recommendations.isEmpty) {
      recommendations.add(
        const ExamRecommendation(
          skill: LearningSkill.speaking,
          titleArabic: 'محادثة حرة متقدمة مع المعلم الذكي',
          titleEnglish: 'Advanced Conversation Practice',
          rationaleArabic: 'أداء ممتاز في جميع المهارات! واصل التحدث بطلاقة.',
          rationaleEnglish:
              'Outstanding performance! Keep practicing speaking.',
          targetRoute: '/tutor',
        ),
      );
    }

    // Projected CEFR level
    final estimatedCefr = _determineProjectedCefr(exam.cefrLevel, overallScore);

    return ExamResult(
      id: attemptId,
      examId: exam.id,
      examTitleArabic: exam.titleArabic,
      examTitleEnglish: exam.titleEnglish,
      overallScore: overallScore,
      estimatedCefrLevel: estimatedCefr,
      skillScores: skillScores,
      answeredCount: answeredCount,
      skippedCount: skippedCount,
      correctCount: correctCount,
      totalQuestions: exam.totalQuestions,
      strengthsArabic:
          strengths.isNotEmpty ? strengths : ['بداية جيدة ومحاولة موفقة'],
      areasForImprovementArabic: areasForImprovement,
      recommendations: recommendations,
      completedAt: DateTime.now(),
    );
  }

  CefrLevel _determineProjectedCefr(CefrLevel currentLevel, int overallScore) {
    if (overallScore >= 85) {
      return currentLevel.nextLevel;
    }
    return currentLevel;
  }

  ExamRecommendation _generateRecommendationForSkill(LearningSkill skill) {
    switch (skill) {
      case LearningSkill.vocabulary:
        return const ExamRecommendation(
          skill: LearningSkill.vocabulary,
          titleArabic: 'مراجعة المفردات والتكرار المتباعد',
          titleEnglish: 'Vocabulary Spaced Review',
          rationaleArabic:
              'تدرب على تثبيت الكلمات الجديدة والمترادفات الشائعة.',
          rationaleEnglish: 'Practice reviewing new words and collocations.',
          targetRoute: '/vocabulary',
        );
      case LearningSkill.grammar:
        return const ExamRecommendation(
          skill: LearningSkill.grammar,
          titleArabic: 'تدريبات القواعد وتراكيب الجمل',
          titleEnglish: 'Grammar & Sentence Building',
          rationaleArabic: 'راجع القواعد والأزمنة عبر الدروس التفاعلية.',
          rationaleEnglish: 'Reinforce tenses and grammar patterns.',
          targetRoute: '/learning',
        );
      case LearningSkill.speaking:
      case LearningSkill.pronunciation:
      case LearningSkill.fluency:
        return const ExamRecommendation(
          skill: LearningSkill.speaking,
          titleArabic: 'جلسة محادثة ونطق مع عباس/دنيا',
          titleEnglish: 'Speaking Session with AI Tutor',
          rationaleArabic:
              'تطبيق صوتي مباشر للتركيز على مخارج الحروف والطلاقة.',
          rationaleEnglish:
              'Live spoken practice to build pronunciation & fluency.',
          targetRoute: '/tutor',
        );
      case LearningSkill.listening:
      case LearningSkill.comprehension:
      case LearningSkill.reading:
        return const ExamRecommendation(
          skill: LearningSkill.listening,
          titleArabic: 'تمارين الاستماع والفهم السياقي',
          titleEnglish: 'Listening & Context Practice',
          rationaleArabic: 'استمع إلى مقاطع حوارية وركز على الكلمات المفتاحية.',
          rationaleEnglish:
              'Listen to short audio dialogues and spot key words.',
          targetRoute: '/learning',
        );
    }
  }
}
