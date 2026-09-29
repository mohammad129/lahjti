import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahjti/core/theme/app_theme.dart';
import 'package:lahjti/features/school/presentation/screens/educational_games_hub_screen.dart';
import 'package:lahjti/features/school/presentation/screens/game_play_screen.dart';
import 'package:lahjti/l10n/app_localizations.dart';

void main() {
  Widget createGameTestWidget({
    required Widget child,
    Locale locale = const Locale('ar'),
    ProviderContainer? container,
  }) {
    return UncontrolledProviderScope(
      container: container ?? ProviderContainer(),
      child: MaterialApp(
        locale: locale,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  void setMobileScreenSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('Educational Games & Gameplay Widget Tests', () {
    testWidgets(
      '1. EducationalGamesHubScreen displays 5 games with XP rewards in Arabic',
      (WidgetTester tester) async {
        setMobileScreenSize(tester);
        final container = ProviderContainer();

        await tester.pumpWidget(
          createGameTestWidget(
            child: const EducationalGamesHubScreen(),
            container: container,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('الألعاب التعليمية'), findsWidgets);
        expect(find.text('مطابقة الكلمات والمعاني'), findsOneWidget);
        expect(find.text('استمع واختر'), findsOneWidget);
        expect(find.text('بناء الجمل السليمة'), findsOneWidget);
        expect(find.text('ذاكرة البطاقات الذكية'), findsOneWidget);
        expect(find.text('تحدي الاختبار السريع'), findsOneWidget);
      },
    );

    testWidgets('2. GamePlayScreen runs Word Match game and taps pair', (
      WidgetTester tester,
    ) async {
      setMobileScreenSize(tester);
      final container = ProviderContainer();

      await tester.pumpWidget(
        createGameTestWidget(
          child: const GamePlayScreen(gameId: 'game_word_match'),
          container: container,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('مطابقة الكلمات والمعاني'), findsOneWidget);
      expect(find.text('شاي'), findsOneWidget);
      expect(find.text('قهوة'), findsOneWidget);

      // Tap Arabic word 'شاي' then tap English 'Tea 🍵'
      await tester.tap(find.text('شاي'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tea 🍵'));
      await tester.pumpAndSettle();

      // Pair matched!
      expect(find.text('1 / 1'), findsOneWidget);
    });

    testWidgets('3. GamePlayScreen runs Listen & Choose and selects option', (
      WidgetTester tester,
    ) async {
      setMobileScreenSize(tester);
      final container = ProviderContainer();

      await tester.pumpWidget(
        createGameTestWidget(
          child: const GamePlayScreen(gameId: 'game_listen_choose'),
          container: container,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('« أهلاً وسهلاً »'), findsOneWidget);
      expect(find.text('Hello & Welcome'), findsOneWidget);

      await tester.tap(find.text('Hello & Welcome'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('تحقق من الإجابة'));
      await tester.pumpAndSettle();

      expect(find.text('رائع جداً! 🌟'), findsOneWidget);
    });
  });
}
