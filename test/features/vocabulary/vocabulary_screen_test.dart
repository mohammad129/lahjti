import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/learning/data/repositories/local_learning_repository.dart';
import 'package:lahjti/features/learning/presentation/providers/learning_providers.dart';
import 'package:lahjti/features/vocabulary/presentation/screens/vocabulary_screen.dart';
import 'package:lahjti/l10n/app_localizations.dart';

void main() {
  Widget createWidgetUnderTest() {
    final repo = LocalLearningRepository();
    return ProviderScope(
      overrides: [learningRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('ar'), Locale('en')],
        locale: Locale('ar'),
        home: VocabularyScreen(),
      ),
    );
  }

  testWidgets(
    'VocabularyScreen Widget Tests 1. Renders daily goal and vocabulary items',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1000));
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify app bar title
      expect(find.text('المفردات'), findsOneWidget);

      // Verify daily goal header
      expect(find.text('الهدف اليومي للمفردات'), findsOneWidget);

      // Verify filter tabs
      expect(find.text('الكل'), findsWidgets);
      expect(find.text('قيد التعلم'), findsOneWidget);
      expect(find.text('متقنة'), findsOneWidget);

      // Verify floating action button
      expect(find.text('بدء التدريب الذكي'), findsOneWidget);
    },
  );
}
