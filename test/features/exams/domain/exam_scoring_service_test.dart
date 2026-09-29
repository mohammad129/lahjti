import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/exams/domain/models/exam_models.dart';
import 'package:lahjti/features/exams/domain/services/exam_generator.dart';
import 'package:lahjti/features/exams/domain/services/exam_scoring_service.dart';
import 'package:lahjti/features/learning/domain/models/learning_skill.dart';
import 'package:lahjti/features/onboarding/domain/models/age_group.dart';
import 'package:lahjti/features/placement/domain/models/cefr_level.dart';

void main() {
  group('ExamScoringService Tests', () {
    const generator = ExamGenerator();
    const scoringService = ExamScoringService();

    final testExam = generator.generateMonth1MilestoneExam(
      targetLanguage: 'en',
      cefrLevel: CefrLevel.a1,
      ageGroup: AgeGroup.age19_25,
    );

    test('1. Perfect score returns 100%, passes exam, and sets strengths', () {
      final answers = <String, ExamAnswer>{};
      for (final section in testExam.sections) {
        for (final q in section.questions) {
          answers[q.id] = ExamAnswer(
            questionId: q.id,
            selectedOptionIndex: q.correctOptionIndex,
            spokenText: q.targetSpokenPhrase ?? 'Good morning',
          );
        }
      }

      final result = scoringService.evaluateAttempt(
        exam: testExam,
        answers: answers,
        attemptId: 'att_1',
      );

      expect(result.overallScore, 100);
      expect(result.isPassing, isTrue);
      expect(result.isDistinction, isTrue);
      expect(result.strengthsArabic.isNotEmpty, isTrue);
      expect(result.areasForImprovementArabic.isEmpty, isTrue);
      expect(result.estimatedCefrLevel, CefrLevel.a2);
    });

    test(
      '2. Unanswered/skipped questions score 0 and highlight improvement areas',
      () {
        final answers = <String, ExamAnswer>{};
        // User only answers 1 question
        final firstQ = testExam.sections.first.questions.first;
        answers[firstQ.id] = ExamAnswer(
          questionId: firstQ.id,
          selectedOptionIndex: firstQ.correctOptionIndex,
        );

        final result = scoringService.evaluateAttempt(
          exam: testExam,
          answers: answers,
          attemptId: 'att_2',
        );

        expect(result.overallScore, lessThan(60));
        expect(result.isPassing, isFalse);
        expect(result.areasForImprovementArabic.isNotEmpty, isTrue);
        expect(result.estimatedCefrLevel, CefrLevel.a1);
      },
    );

    test('3. Generates targeted recommendations based on skill weaknesses', () {
      final answers = <String, ExamAnswer>{};
      for (final section in testExam.sections) {
        for (final q in section.questions) {
          // Wrong on speaking, correct on others
          final isSpeaking =
              q.type == ExamQuestionType.speakingProduction ||
              section.skill == LearningSkill.speaking;
          answers[q.id] = ExamAnswer(
            questionId: q.id,
            selectedOptionIndex: isSpeaking ? 99 : q.correctOptionIndex,
            spokenText: isSpeaking ? 'wrong phrase' : q.targetSpokenPhrase,
          );
        }
      }

      final result = scoringService.evaluateAttempt(
        exam: testExam,
        answers: answers,
        attemptId: 'att_3',
      );

      expect(result.recommendations.isNotEmpty, isTrue);
      expect(
        result.recommendations.any(
          (r) => r.skill == LearningSkill.speaking || r.targetRoute == '/tutor',
        ),
        isTrue,
      );
    });

    test('4. Does not jump CEFR levels arbitrarily without solid evidence', () {
      final answers = <String, ExamAnswer>{};
      for (final section in testExam.sections) {
        for (final q in section.questions) {
          answers[q.id] = ExamAnswer(
            questionId: q.id,
            selectedOptionIndex: q.correctOptionIndex,
            spokenText: q.targetSpokenPhrase ?? 'Good morning',
          );
        }
      }

      // Starting at A1 with a perfect A1 exam advances to A2
      final resultA1 = scoringService.evaluateAttempt(
        exam: testExam,
        answers: answers,
        attemptId: 'att_cefr',
      );
      expect(resultA1.estimatedCefrLevel, CefrLevel.a2);
    });
  });
}
