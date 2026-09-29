import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lahjti/core/theme/app_theme.dart';
import 'package:lahjti/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:lahjti/features/school/domain/models/school_role.dart';
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
        GoRoute(
          path: '/teacher/classes/:classId',
          builder:
              (context, state) => Scaffold(
                body: Center(
                  child: Text(
                    'Class Details ${state.pathParameters['classId']}',
                  ),
                ),
              ),
        ),
        GoRoute(
          path: '/welcome',
          builder:
              (context, state) =>
                  const Scaffold(body: Center(child: Text('Welcome Page'))),
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

  group('TeacherHomeScreen (Dashboard) Widget Tests', () {
    testWidgets(
      '1. Displays teacher profile data, real overview cards, and class list in Arabic',
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

        // Header
        expect(find.text('لوحة المعلم'), findsOneWidget);
        expect(find.text('مرحباً بك أستاذ طارق عبد الله'), findsOneWidget);
        expect(find.text('أكاديمية الرواد'), findsOneWidget);
        expect(find.text('📚 اللغة الإنجليزية والمحادثة'), findsOneWidget);

        // 4 Metric Overview Cards
        expect(find.text('إجمالي الطلاب'), findsOneWidget);
        expect(find.text('النشطون اليوم'), findsOneWidget);
        expect(find.text('أنجزوا مهام اليوم'), findsOneWidget);
        expect(find.text('متوسط التقدم'), findsOneWidget);

        // My Classes Section
        expect(find.text('صفوفي الدراسية'), findsOneWidget);
        expect(find.text('الصف السادس - أ'), findsOneWidget);
        expect(find.text('الصف السابع - ب'), findsOneWidget);

        // Privacy Notice
        expect(find.byIcon(Icons.privacy_tip_rounded), findsOneWidget);
      },
    );

    testWidgets('2. Tapping a class navigates to Class Details Screen', (
      WidgetTester tester,
    ) async {
      setMobileScreenSize(tester);
      final container = ProviderContainer();

      await tester.pumpWidget(createTeacherHomeWidget(container: container));
      await tester.pumpAndSettle();

      final classCard = find.text('الصف السادس - أ');
      expect(classCard, findsOneWidget);
      await tester.tap(classCard);
      await tester.pumpAndSettle();

      expect(find.text('Class Details cls_grade6_a'), findsOneWidget);
    });

    testWidgets('3. Displays in English LTR correctly', (
      WidgetTester tester,
    ) async {
      setMobileScreenSize(tester);
      final container = ProviderContainer();
      final notifier = container.read(onboardingProvider.notifier);
      notifier.selectSchoolRole(SchoolRole.teacher);
      notifier.setSchoolDetails(
        schoolCode: 'SCH-1001',
        schoolName: 'Al Rowad School',
      );
      notifier.setTeacherDetails(
        fullName: 'Tariq',
        subject: 'English',
        gradesTaught: ['Grade 6'],
      );

      await tester.pumpWidget(
        createTeacherHomeWidget(
          locale: const Locale('en'),
          container: container,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Teacher Dashboard'), findsOneWidget);
      expect(find.text('Welcome, Teacher Tariq'), findsOneWidget);
      expect(find.text('Total Students'), findsOneWidget);
      expect(find.text('My Classes'), findsOneWidget);
    });
  });
}
