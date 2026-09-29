import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/learning/data/repositories/local_learning_repository.dart';
import 'package:lahjti/features/learning/presentation/providers/learning_providers.dart';
import 'package:lahjti/features/onboarding/domain/models/age_group.dart';
import 'package:lahjti/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:lahjti/features/progress/presentation/screens/progress_screen.dart';
import 'package:lahjti/l10n/app_localizations.dart';

void main() {
  Widget createWidgetUnderTest({
    Locale locale = const Locale('ar'),
    AgeGroup ageGroup = AgeGroup.age19_25,
  }) {
    final repo = LocalLearningRepository();
    return ProviderScope(
      overrides: [
        learningRepositoryProvider.overrideWithValue(repo),
        onboardingProvider.overrideWith((ref) {
          final notifier = OnboardingNotifier();
          notifier.selectAgeGroup(ageGroup);
          return notifier;
        }),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ar'), Locale('en')],
        locale: locale,
        home: const ProgressScreen(),
      ),
    );
  }

  group('ProgressScreen Widget & UI Tests', () {
    testWidgets('1. Renders complete progress dashboard in Arabic (RTL)', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(500, 1200));
      await tester.pumpWidget(
        createWidgetUnderTest(locale: const Locale('ar')),
      );
      await tester.pumpAndSettle();

      // App bar title
      expect(find.text('التقدم والإنجازات'), findsOneWidget);

      // Level Header
      expect(find.textContaining('المستوى'), findsWidgets);

      // Streak and Total XP capsules
      expect(find.text('أيام الالتزام'), findsOneWidget);
      expect(find.text('مجموع النقاط'), findsOneWidget);

      // Daily Goal card
      expect(find.text('الهدف اليومي'), findsOneWidget);
      expect(find.text('ابدأ النشاط الموصى به'), findsOneWidget);

      // Skills Breakdown section
      expect(find.text('مستوى المهارات'), findsOneWidget);

      // 3-Month Roadmap
      expect(find.text('رحلة الـ 3 أشهر'), findsOneWidget);

      // Achievements section
      expect(find.text('الإنجازات والأوسمة'), findsOneWidget);
    });

    testWidgets('2. Renders complete progress dashboard in English (LTR)', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(500, 1200));
      await tester.pumpWidget(
        createWidgetUnderTest(locale: const Locale('en')),
      );
      await tester.pumpAndSettle();

      // App bar title
      expect(find.text('Progress & Achievements'), findsOneWidget);

      // Metric labels
      expect(find.text('Daily Streak'), findsOneWidget);
      expect(find.text('Total XP'), findsOneWidget);
      expect(find.text('Daily Goal'), findsOneWidget);
      expect(find.text('Skills Breakdown'), findsOneWidget);
      expect(find.text('3-Month Learning Roadmap'), findsOneWidget);
      expect(find.text('Achievements & Badges'), findsOneWidget);
    });

    testWidgets('3. Tapping an achievement card opens details bottom sheet', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(500, 1200));
      await tester.pumpWidget(
        createWidgetUnderTest(locale: const Locale('ar')),
      );
      await tester.pumpAndSettle();

      // Scroll and tap on first achievement badge
      final firstAchievement = find.text('الخطوة الأولى 🚀');
      expect(firstAchievement, findsWidgets);

      await tester.ensureVisible(firstAchievement.first);
      await tester.pumpAndSettle();

      await tester.tap(firstAchievement.first);
      await tester.pumpAndSettle();

      // Verify bottom sheet modal opened
      expect(
        find.text('أكملت أول درس تعليمي تفاعلي في رحلتك.'),
        findsOneWidget,
      );
    });
  });
}
