import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/exams/domain/models/exam_models.dart';
import 'package:lahjti/features/exams/presentation/providers/exams_providers.dart';
import 'package:lahjti/features/learning/data/repositories/local_learning_repository.dart';
import 'package:lahjti/features/learning/presentation/providers/learning_providers.dart';
import 'package:lahjti/features/placement/domain/models/cefr_level.dart';

void main() {
  group('Exams Providers Tests', () {
    late LocalLearningRepository repo;
    late ProviderContainer container;

    setUp(() {
      repo = LocalLearningRepository();
      container = ProviderContainer(
        overrides: [learningRepositoryProvider.overrideWithValue(repo)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
      '1. availableExamsProvider returns list of milestone and checkpoint exams',
      () {
        final exams = container.read(availableExamsProvider);
        expect(exams.isNotEmpty, isTrue);
        expect(exams.any((e) => e.type == ExamType.monthlyMilestone), isTrue);
        expect(exams.any((e) => e.type == ExamType.skillCheckpoint), isTrue);
      },
    );

    test(
      '2. examHistoryProvider returns empty initially then includes saved exam',
      () async {
        final initialHistory = await container.read(examHistoryProvider.future);
        expect(initialHistory.isEmpty, isTrue);

        final dummyResult = ExamResult(
          id: 'res_test_1',
          examId: 'exam_month_1',
          examTitleArabic: 'اختبار الشهر الأول',
          examTitleEnglish: 'Month 1 Exam',
          overallScore: 90,
          estimatedCefrLevel: CefrLevel.a2,
          skillScores: const [],
          answeredCount: 5,
          skippedCount: 0,
          correctCount: 5,
          totalQuestions: 5,
          strengthsArabic: const ['المفردات'],
          areasForImprovementArabic: const [],
          recommendations: const [],
          completedAt: DateTime.now(),
        );

        await repo.saveExamResult('usr_active', dummyResult);

        final updatedHistory = await container.refresh(
          examHistoryProvider.future,
        );
        expect(updatedHistory.length, 1);
        expect(updatedHistory.first.overallScore, 90);
      },
    );

    test(
      '3. activeExamAttemptNotifierProvider executes entire exam lifecycle and persists result',
      () async {
        final exams = container.read(availableExamsProvider);
        final exam = exams.first;

        final notifier = container.read(
          activeExamAttemptNotifierProvider.notifier,
        );
        notifier.startExam(exam);

        var state = container.read(activeExamAttemptNotifierProvider);
        expect(state, isNotNull);
        expect(state!.currentQuestionIndex, 0);

        // Answer questions by selecting option or recording spoken answer
        for (final section in exam.sections) {
          for (final question in section.questions) {
            if (question.type == ExamQuestionType.speakingProduction) {
              notifier.recordSpokenAnswer(
                question.targetSpokenPhrase ?? 'Good morning',
              );
            } else {
              notifier.selectOption(question.correctOptionIndex);
            }
            notifier.nextQuestion();
          }
        }

        // Submit exam
        final result = await notifier.submitExam();
        expect(result, isNotNull);
        expect(result!.overallScore, greaterThan(0));

        // Verify saved in history
        final history = await container.read(examHistoryProvider.future);
        expect(history.isNotEmpty, isTrue);
        expect(history.any((r) => r.examId == exam.id), isTrue);
      },
    );
  });
}
