import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahjti/core/theme/app_theme.dart';
import 'package:lahjti/features/school/presentation/screens/student_school_home_screen.dart';
import 'package:lahjti/l10n/app_localizations.dart';

void main() {
  Widget createStudentHomeTestWidget({
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
        home: const StudentSchoolHomeScreen(),
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

  group('StudentSchoolHomeScreen Widget Tests', () {
    testWidgets(
      '1. Displays personalized greeting, mission card, tasks, and quick hubs in Arabic',
      (WidgetTester tester) async {
        setMobileScreenSize(tester);
        final container = ProviderContainer();

        await tester.pumpWidget(
          createStudentHomeTestWidget(
            locale: const Locale('ar'),
            container: container,
          ),
        );
        await tester.pumpAndSettle();

        // Header Greeting
        expect(find.text('مرحباً يا سامي 👋'), findsOneWidget);
        expect(find.textContaining('مدرسة النور'), findsOneWidget);

        // Daily Mission Card
        expect(find.text('مهمتك اليوم'), findsOneWidget);
        expect(find.text('أكمل 3 أنشطة لتحصل على 50 XP'), findsOneWidget);
        expect(find.textContaining('XP ⭐'), findsOneWidget);

        // Daily Tasks Section
        expect(find.text('مهام اليوم'), findsOneWidget);
        expect(find.text('ماذا أفعل اليوم؟'), findsOneWidget);
        expect(find.text('درس اليوم: في المقهى والمطعم'), findsOneWidget);

        // Quick Hubs
        expect(find.text('متابعة الدروس'), findsOneWidget);
        expect(find.text('مراجعة المفردات'), findsOneWidget);
        expect(find.text('ألعاب تعليمية'), findsOneWidget);
        expect(find.text('تحدث مع عباس ودنيا'), findsOneWidget);

        // Safety Notice
        expect(find.byIcon(Icons.shield_rounded), findsOneWidget);
      },
    );

    testWidgets('2. Displays properly in English LTR mode', (
      WidgetTester tester,
    ) async {
      setMobileScreenSize(tester);
      final container = ProviderContainer();

      await tester.pumpWidget(
        createStudentHomeTestWidget(
          locale: const Locale('en'),
          container: container,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello Sami 👋'), findsOneWidget);
      expect(find.text('Today\'s Mission'), findsOneWidget);
      expect(find.text('Today\'s Tasks'), findsOneWidget);
      expect(find.text('What to do today?'), findsOneWidget);
      expect(find.text('Continue Lessons'), findsOneWidget);
      expect(find.text('Educational Games'), findsOneWidget);
    });
  });
}
