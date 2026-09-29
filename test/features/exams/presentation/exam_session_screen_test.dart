import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/exams/domain/models/exam_models.dart';
import 'package:lahjti/features/exams/presentation/providers/exams_providers.dart';
import 'package:lahjti/features/exams/presentation/screens/exam_session_screen.dart';
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
        home: ExamSessionScreen(),
      ),
    );
  }

  testWidgets(
    'ExamSessionScreen renders active question, accepts selection, advances, and finishes',
    (WidgetTester tester) async {
      final repo = LocalLearningRepository();
      final container = ProviderContainer(
        overrides: [learningRepositoryProvider.overrideWithValue(repo)],
      );

      const exam = Exam(
        id: 'test_session_exam',
        titleArabic: 'اختبار تجريبي',
        titleEnglish: 'Test Exam',
        descriptionArabic: 'وصف الاختبار',
        descriptionEnglish: 'Exam description',
        targetLanguage: 'en',
        cefrLevel: CefrLevel.a1,
        type: ExamType.skillCheckpoint,
        sections: [
          ExamSection(
            id: 's_v',
            titleArabic: 'قسم المفردات',
            titleEnglish: 'Vocabulary',
            skill: LearningSkill.vocabulary,
            questions: [
              ExamQuestion(
                id: 'q1',
                sectionId: 's_v',
                type: ExamQuestionType.vocabularySelection,
                promptText: 'Water',
                promptSubtext: 'ما معنى هذه الكلمة؟',
                options: ['ماء', 'شاي', 'عصير'],
                correctOptionIndex: 0,
                points: 10,
              ),
              ExamQuestion(
                id: 'q2',
                sectionId: 's_v',
                type: ExamQuestionType.vocabularySelection,
                promptText: 'Book',
                promptSubtext: 'ما معنى هذه الكلمة؟',
                options: ['قلم', 'كتاب', 'دفتر'],
                correctOptionIndex: 1,
                points: 10,
              ),
            ],
          ),
        ],
      );

      // Start the attempt
      container
          .read(activeExamAttemptNotifierProvider.notifier)
          .startExam(exam);

      await tester.binding.setSurfaceSize(const Size(500, 1000));
      await tester.pumpWidget(createWidgetUnderTest(container));
      await tester.pumpAndSettle();

      // Verify question 1 prompt
      expect(find.text('Water'), findsOneWidget);
      expect(find.text('ماء'), findsOneWidget);
      expect(find.text('شاي'), findsOneWidget);

      // Select option "ماء"
      await tester.tap(find.text('ماء'));
      await tester.pumpAndSettle();

      // Advance to next question
      expect(find.text('التالي'), findsOneWidget);
      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();

      // Verify question 2 prompt
      expect(find.text('Book'), findsOneWidget);
      expect(find.text('كتاب'), findsOneWidget);

      // Select option "كتاب"
      await tester.tap(find.text('كتاب'));
      await tester.pumpAndSettle();

      // Verify last question submit button
      expect(find.text('إنهاء وتسليم'), findsOneWidget);
    },
  );
}
