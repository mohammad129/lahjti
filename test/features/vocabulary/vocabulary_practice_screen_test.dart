import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/learning/data/repositories/local_learning_repository.dart';
import 'package:lahjti/features/learning/domain/models/vocabulary_item.dart';
import 'package:lahjti/features/learning/presentation/providers/learning_providers.dart';
import 'package:lahjti/features/placement/domain/models/cefr_level.dart';
import 'package:lahjti/features/vocabulary/domain/models/vocabulary_practice_models.dart';
import 'package:lahjti/features/vocabulary/presentation/providers/vocabulary_providers.dart';
import 'package:lahjti/features/vocabulary/presentation/screens/vocabulary_practice_screen.dart';
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
        home: VocabularyPracticeScreen(),
      ),
    );
  }

  testWidgets(
    'VocabularyPracticeScreen Widget Tests 1. Renders active question and submits answer',
    (WidgetTester tester) async {
      final repo = LocalLearningRepository();
      final container = ProviderContainer(
        overrides: [learningRepositoryProvider.overrideWithValue(repo)],
      );

      final item = VocabularyItem(
        id: 'v_test_1',
        term: 'Coffee',
        translationArabic: 'قهوة',
        exampleSentence: 'I drink coffee.',
        exampleTranslationArabic: 'أنا أشرب القهوة.',
        difficulty: CefrLevel.a1,
        category: 'Food',
      );

      final question = PracticeQuestion(
        id: 'q1',
        mode: PracticeMode.recognizeMeaning,
        targetItem: item,
        promptText: 'Coffee',
        promptSubtext: 'ما معنى هذه الكلمة؟',
        options: const ['شاي', 'قهوة', 'ماء', 'عصير'],
        correctOptionIndex: 1,
        explanationArabic: 'الكلمة تعني قهوة',
        explanationEnglish: 'The word means coffee',
      );

      container
          .read(vocabularyPracticeNotifierProvider.notifier)
          .state = PracticeSessionState(questions: [question], currentIndex: 0);

      await tester.binding.setSurfaceSize(const Size(500, 1000));
      await tester.pumpWidget(createWidgetUnderTest(container));
      await tester.pumpAndSettle();

      // Verify question prompt
      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('قهوة'), findsOneWidget);

      // Tap the correct option "قهوة"
      await tester.tap(find.text('قهوة'));
      await tester.pumpAndSettle();

      // Verify submit button is enabled and tap it
      expect(find.text('تأكيد الإجابة'), findsOneWidget);
      await tester.tap(find.text('تأكيد الإجابة'));
      await tester.pumpAndSettle();

      // Verify feedback explanation card appears
      expect(find.text('إجابة ممتازة! 👏'), findsOneWidget);
      expect(find.text('الكلمة تعني قهوة'), findsOneWidget);

      // Tap next to view completion screen
      expect(find.text('عرض النتيجة 🎉'), findsOneWidget);
      await tester.tap(find.text('عرض النتيجة 🎉'));
      await tester.pumpAndSettle();

      // Verify completion screen
      expect(find.text('اكتمل التدريب بنجاح! 🎉'), findsOneWidget);
    },
  );
}
