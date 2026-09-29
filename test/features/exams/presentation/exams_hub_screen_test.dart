import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/exams/presentation/screens/exams_hub_screen.dart';
import 'package:lahjti/features/learning/data/repositories/local_learning_repository.dart';
import 'package:lahjti/features/learning/presentation/providers/learning_providers.dart';
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
        home: ExamsHubScreen(),
      ),
    );
  }

  testWidgets(
    'ExamsHubScreen renders header, milestone exams, and history sections',
    (WidgetTester tester) async {
      final repo = LocalLearningRepository();
      final container = ProviderContainer(
        overrides: [learningRepositoryProvider.overrideWithValue(repo)],
      );

      await tester.binding.setSurfaceSize(const Size(500, 1200));
      await tester.pumpWidget(createWidgetUnderTest(container));
      await tester.pumpAndSettle();

      // Verify Header and Section Title
      expect(
        find.text('اختبارات المعالم الشهرية (Milestones)'),
        findsOneWidget,
      );

      // Verify Milestone cards are present
      expect(find.text('اختبار الشهر الأول: إتقان الأساسيات'), findsOneWidget);

      // Verify Start button is present
      expect(find.text('بدء الاختبار'), findsWidgets);

      // Verify History title
      expect(find.text('سجل نتائج التقييم السابقة'), findsOneWidget);
    },
  );
}
