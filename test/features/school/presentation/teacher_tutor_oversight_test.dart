import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lahjti/core/theme/app_theme.dart';
import 'package:lahjti/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:lahjti/features/school/domain/models/school_role.dart';
import 'package:lahjti/features/school/presentation/providers/school_providers.dart';
import 'package:lahjti/features/school/presentation/screens/teacher_home_screen.dart';
import 'package:lahjti/l10n/app_localizations.dart';

void main() {
  Widget createTeacherHomeWidget({
    Locale locale = const Locale('ar'),
    ProviderContainer? container,
  }) {
    final router = GoRouter(
      initialLocation: '/teacher/home',
      routes: [
        GoRoute(
          path: '/teacher/home',
          builder: (context, state) => const TeacherHomeScreen(),
        ),
      ],
    );

    return UncontrolledProviderScope(
      container: container ?? ProviderContainer(),
      child: MaterialApp.router(
        locale: locale,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
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

  group('TeacherHomeScreen - AI English Tutor Oversight Dashboard Tests', () {
    testWidgets(
      '1. Switches to AI Tutor tab and renders 4 KPI metric cards, common grammar alerts, and 4-session pills',
      (WidgetTester tester) async {
        setMobileScreenSize(tester);
        final container = ProviderContainer();
        final notifier = container.read(onboardingProvider.notifier);
        notifier.selectSchoolRole(SchoolRole.teacher);
        notifier.setSchoolDetails(
          schoolCode: 'SCH-1001',
          schoolName: 'أكاديمية الرواد',
        );
        notifier.setTeacherDetails(
          fullName: 'طارق عبد الله',
          subject: 'اللغة الإنجليزية والمحادثة',
          gradesTaught: ['الصف السادس', 'الصف السابع'],
        );

        await tester.pumpWidget(createTeacherHomeWidget(container: container));
        await tester.pumpAndSettle();

        // 1. Verify default tab is Overview
        expect(find.text('📊 نظرة عامة والصفوف'), findsOneWidget);
        final tutorTabBtn = find.text('🤖 تدريب الذكاء الاصطناعي (4 جلسات)');
        expect(tutorTabBtn, findsOneWidget);

        // 2. Tap to switch to AI Tutor Oversight Tab
        await tester.tap(tutorTabBtn);
        await tester.pumpAndSettle();

        // 3. Verify Hero Banner
        expect(find.text('متابعة المحادثة الإنجليزية اليومية'), findsOneWidget);
        expect(find.text('المدرب الذكي: عباس ودنيا'), findsOneWidget);
        expect(
          find.text('الحد اليومي: 4 جلسات مرنة وساعة كاملة (60 دقيقة) لكل طالب'),
          findsOneWidget,
        );

        // 4. Verify 4 Tutor KPI Metric Cards
        expect(find.text('المتدربون اليوم'), findsOneWidget);
        expect(find.text('إجمالي وقت المحادثة'), findsOneWidget);
        expect(find.text('أتموا الحصص (4/4)'), findsOneWidget);
        expect(find.text('متوسط طلاقة الإنجليزية'), findsOneWidget);

        // 5. Verify Common Grammar Alerts Box
        expect(
          find.text('نقاط لغوية تحتاج تعزيزاً في الحصة القادمة'),
          findsOneWidget,
        );
        expect(
          find.textContaining('أزمنة الماضي البسيط (Past Simple)'),
          findsOneWidget,
        );

        // 6. Verify Students Roster with 4-Session Tracking
        expect(find.text('سامي عبد الله عواد'), findsOneWidget);
        expect(find.text('ليلى طارق خليل'), findsOneWidget);
        expect(find.text('يوسف رائد المصري'), findsOneWidget);
        expect(find.text('نور الدين الخطيب'), findsOneWidget);

        // Layla achieved 4/4 daily goal
        expect(find.text('أكمل الهدف اليومي (4/4) 🎯'), findsOneWidget);
      },
    );

    testWidgets('2. Filters students by classroom chip', (
      WidgetTester tester,
    ) async {
      setMobileScreenSize(tester);
      final container = ProviderContainer();
      container.read(teacherActiveTabProvider.notifier).state = 1;

      await tester.pumpWidget(createTeacherHomeWidget(container: container));
      await tester.pumpAndSettle();

      // Ensure All Classes shows both Grade 6 and Grade 7 students
      expect(find.text('سامي عبد الله عواد'), findsOneWidget);
      expect(find.text('نور الدين الخطيب'), findsOneWidget);

      // Tap on Grade 7 - B chip
      final grade7Chip = find.widgetWithText(FilterChip, 'الصف السابع - ب');
      expect(grade7Chip, findsOneWidget);
      await tester.ensureVisible(grade7Chip);
      await tester.tap(grade7Chip);
      await tester.pumpAndSettle();

      // Only Grade 7 student (Nour) should be displayed
      expect(find.text('نور الدين الخطيب'), findsOneWidget);
      expect(find.text('سامي عبد الله عواد'), findsNothing);

      // Tap "All Classes" to reset
      final allClassesChip = find.widgetWithText(FilterChip, '🏫 كل الصفوف');
      expect(allClassesChip, findsOneWidget);
      await tester.ensureVisible(allClassesChip);
      await tester.tap(allClassesChip);
      await tester.pumpAndSettle();

      // Both should be visible again
      expect(find.text('سامي عبد الله عواد'), findsOneWidget);
      expect(find.text('نور الدين الخطيب'), findsOneWidget);
    });

    testWidgets('3. Tapping a student opens detailed 4-session modal with topics & recommendations', (
      WidgetTester tester,
    ) async {
      setMobileScreenSize(tester);
      final container = ProviderContainer();
      container.read(teacherActiveTabProvider.notifier).state = 1;

      await tester.pumpWidget(createTeacherHomeWidget(container: container));
      await tester.pumpAndSettle();

      // Tap on Sami's card
      final samiCard = find.text('سامي عبد الله عواد');
      expect(samiCard, findsOneWidget);
      await tester.tap(samiCard);
      await tester.pumpAndSettle();

      // Verify Modal Content
      expect(find.text('تفاصيل الحصص الأربع لليوم'), findsOneWidget);
      expect(find.text('وقت المحادثة'), findsOneWidget);
      expect(find.text('الجلسات المكتملة'), findsOneWidget);

      // Verify Topics & Tutor Names
      expect(find.text('روتين الصباح والعادات اليومية'), findsOneWidget);
      expect(find.text('المواد المفضلة في المدرسة'), findsOneWidget);
      expect(find.text('طلب وجبة الغداء باللغة الإنجليزية'), findsOneWidget);
      expect(find.text('المدرب: عباس'), findsNWidgets(2));
      expect(find.text('المدرب: دنيا'), findsOneWidget);

      // Verify Pedagogical Recommendation
      expect(find.text('توصية المدرب الذكي للمعلم'), findsOneWidget);
      expect(
        find.textContaining('يحتاج تدريب إضافي على نطق الحروف المركبة'),
        findsOneWidget,
      );

      // Verify Privacy Notice inside modal
      expect(
        find.text(
          'التسجيلات الصوتية ومحادثات الذكاء الاصطناعي مشفرة ومحمية لحفظ خصوصية الطالب.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('4. Displays AI English Tutor tab correctly in English LTR', (
      WidgetTester tester,
    ) async {
      setMobileScreenSize(tester);
      final container = ProviderContainer();
      container.read(teacherActiveTabProvider.notifier).state = 1;

      await tester.pumpWidget(
        createTeacherHomeWidget(
          locale: const Locale('en'),
          container: container,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('🤖 AI Tutor (4 Sessions)'), findsOneWidget);
      expect(find.text('Daily English AI Tutor Tracking'), findsOneWidget);
      expect(find.text('AI Tutors: Abbas & Dunya'), findsOneWidget);
      expect(find.text('Practiced Today'), findsOneWidget);
      expect(find.text('Total Spoken Time'), findsOneWidget);
      expect(find.text('Completed 4/4 Sessions'), findsOneWidget);
      expect(find.text('Avg Fluency Score'), findsOneWidget);
      expect(find.text('🏫 All Classes'), findsOneWidget);
    });
  });
}
