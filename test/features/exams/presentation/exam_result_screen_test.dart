import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/exams/domain/models/exam_models.dart';
import 'package:lahjti/features/exams/presentation/providers/exams_providers.dart';
import 'package:lahjti/features/exams/presentation/screens/exam_result_screen.dart';
import 'package:lahjti/features/learning/data/repositories/local_learning_repository.dart';
import 'package:lahjti/features/learning/domain/models/learning_skill.dart';
import 'package:lahjti/features/learning/presentation/providers/learning_providers.dart';
import 'package:lahjti/features/placement/domain/models/cefr_level.dart';
import 'package:lahjti/l10n/app_localizations.dart';

void main() {
  Widget createWidgetUnderTest(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('ar'), Locale('en')],
        locale: Locale('ar'),
        home: ExamResultScreen(),
      ),
    );
  }

  testWidgets(
    'ExamResultScreen renders score, skill breakdown, recommendations, and actions',
    (WidgetTester tester) async {
      final repo = LocalLearningRepository();
      final container = ProviderContainer(
        overrides: [learningRepositoryProvider.overrideWithValue(repo)],
      );

      final dummyResult = ExamResult(
        id: 'res_test_100',
        examId: 'exam_month_1',
        examTitleArabic: 'اختبار الشهر الأول: إتقان الأساسيات',
        examTitleEnglish: 'Month 1 Milestone Exam',
        overallScore: 85,
        estimatedCefrLevel: CefrLevel.a2,
        skillScores: const [
          ExamSkillScore(
            skill: LearningSkill.vocabulary,
            scorePercentage: 100,
            pointsEarned: 20,
            pointsPossible: 20,
          ),
          ExamSkillScore(
            skill: LearningSkill.grammar,
            scorePercentage: 90,
            pointsEarned: 18,
            pointsPossible: 20,
          ),
          ExamSkillScore(
            skill: LearningSkill.reading,
            scorePercentage: 85,
            pointsEarned: 17,
            pointsPossible: 20,
          ),
          ExamSkillScore(
            skill: LearningSkill.listening,
            scorePercentage: 75,
            pointsEarned: 15,
            pointsPossible: 20,
          ),
          ExamSkillScore(
            skill: LearningSkill.speaking,
            scorePercentage: 75,
            pointsEarned: 15,
            pointsPossible: 20,
          ),
        ],
        answeredCount: 5,
        skippedCount: 0,
        correctCount: 5,
        totalQuestions: 5,
        strengthsArabic: const ['إتقان ممتاز في مهارة المفردات والكلمات'],
        areasForImprovementArabic: const ['تحتاج لتعزيز مهارة الاستماع والفهم'],
        recommendations: const [
          ExamRecommendation(
            skill: LearningSkill.speaking,
            titleArabic: 'جلسة محادثة ونطق مع المعلم الذكي',
            titleEnglish: 'Speaking Session with AI Tutor',
            rationaleArabic:
                'تطبيق صوتي مباشر للتركيز على مخارج الحروف والطلاقة.',
            rationaleEnglish: 'Live spoken practice.',
            targetRoute: '/tutor',
          ),
        ],
        completedAt: DateTime.now(),
      );

      container.read(selectedExamResultProvider.notifier).state = dummyResult;

      await tester.binding.setSurfaceSize(const Size(500, 1500));
      await tester.pumpWidget(createWidgetUnderTest(container));
      await tester.pumpAndSettle();

      // Verify overall score and header
      expect(find.text('85%'), findsOneWidget);
      expect(find.text('أداء رائع وناجح! 🎉'), findsOneWidget);
      expect(find.text('اختبار الشهر الأول: إتقان الأساسيات'), findsOneWidget);

      // Verify skill breakdown section
      expect(find.text('تحليل المهارات الست'), findsOneWidget);

      // Verify strengths & improvement areas
      expect(find.text('نقاط القوة والإتقان:'), findsOneWidget);
      expect(
        find.text('• إتقان ممتاز في مهارة المفردات والكلمات'),
        findsOneWidget,
      );
      expect(find.text('مجالات تحتاج لمزيد من الممارسة:'), findsOneWidget);
      expect(find.text('• تحتاج لتعزيز مهارة الاستماع والفهم'), findsOneWidget);

      // Verify recommendations and action buttons
      expect(find.text('التوصيات التعليمية الذكية'), findsOneWidget);
      expect(find.text('جلسة محادثة ونطق مع المعلم الذكي'), findsOneWidget);
      expect(find.text('العودة لمركز الاختبارات'), findsOneWidget);
    },
  );
}
