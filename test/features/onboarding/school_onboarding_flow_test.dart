import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lahjti/core/theme/app_theme.dart';
import 'package:lahjti/features/onboarding/presentation/onboarding_screen.dart';
import 'package:lahjti/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:lahjti/features/onboarding/presentation/steps/school_code_verification_step.dart';
import 'package:lahjti/features/onboarding/presentation/steps/school_student_info_step.dart';
import 'package:lahjti/features/onboarding/presentation/steps/teacher_setup_step.dart';
import 'package:lahjti/features/onboarding/presentation/steps/completion_step.dart';
import 'package:lahjti/features/school/domain/models/school_role.dart';
import 'package:lahjti/core/widgets/buttons/primary_button.dart';
import 'package:lahjti/l10n/app_localizations.dart';

void main() {
  Widget createSchoolOnboardingWidget({
    Locale locale = const Locale('ar'),
    ProviderContainer? container,
  }) {
    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/home',
          builder:
              (context, state) => const Scaffold(
                body: Center(child: Text('Learner Home Page')),
              ),
        ),
        GoRoute(
          path: '/teacher/home',
          builder:
              (context, state) =>
                  const Scaffold(body: Center(child: Text('Teacher Hub Page'))),
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

  group('School Onboarding Flow Widget Tests', () {
    testWidgets(
      '1. Teacher flow: Code verification -> Teacher profile setup -> Routes to Teacher Hub',
      (WidgetTester tester) async {
        setMobileScreenSize(tester);
        final container = ProviderContainer();
        container
            .read(onboardingProvider.notifier)
            .selectSchoolRole(SchoolRole.teacher);

        await tester.pumpWidget(
          createSchoolOnboardingWidget(container: container),
        );
        await tester.pumpAndSettle();

        // Step 0: School Code Verification
        expect(find.byType(SchoolCodeVerificationStep), findsOneWidget);

        // Verify button disabled or invalid code
        await tester.enterText(find.byType(TextFormField).first, 'INVALID-999');
        await tester.tap(find.text('تحقق من الرمز'));
        await tester.pumpAndSettle();

        expect(find.text('رمز المدرسة غير صحيح أو غير مفعل ❌'), findsOneWidget);

        // Enter valid seeded code
        await tester.enterText(find.byType(TextFormField).first, 'SCH-1001');
        await tester.tap(find.text('تحقق من الرمز'));
        await tester.pumpAndSettle();

        expect(find.text('تم التحقق من المدرسة بنجاح ✅'), findsOneWidget);
        expect(find.text('أكاديمية عمان الدولية'), findsOneWidget);

        // Tap Continue -> advances to Step 1 (Teacher Setup)
        final continueBtn = find.widgetWithText(PrimaryButton, 'متابعة');
        expect(continueBtn, findsOneWidget);
        await tester.tap(continueBtn);
        await tester.pumpAndSettle();

        expect(find.byType(TeacherSetupStep), findsOneWidget);
        expect(find.text('بيانات المعلم'), findsOneWidget);

        // Fill teacher profile
        await tester.enterText(
          find.byType(TextFormField).at(0),
          'أحمد الأستاذ',
        );
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'اللغة الإنجليزية',
        );
        await tester.enterText(
          find.byType(TextFormField).at(2),
          'الصف السابع, الصف الثامن',
        );
        await tester.pumpAndSettle();

        // Tap Continue -> advances to Completion (Step 2)
        await tester.tap(find.widgetWithText(PrimaryButton, 'متابعة'));
        await tester.pumpAndSettle();

        expect(find.byType(CompletionStep), findsOneWidget);

        // Tap "خلينا نبدأ" -> routes directly to Teacher Hub (/teacher/home)
        await tester.tap(find.text('خلينا نبدأ'));
        await tester.pumpAndSettle();

        expect(find.text('Teacher Hub Page'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Student flow: Code verification -> Student class info setup -> Learner flow',
      (WidgetTester tester) async {
        setMobileScreenSize(tester);
        final container = ProviderContainer();
        container
            .read(onboardingProvider.notifier)
            .selectSchoolRole(SchoolRole.student);

        await tester.pumpWidget(
          createSchoolOnboardingWidget(container: container),
        );
        await tester.pumpAndSettle();

        // Step 0: School Code Verification
        expect(find.byType(SchoolCodeVerificationStep), findsOneWidget);

        // Enter valid code
        await tester.enterText(
          find.byType(TextFormField).first,
          'LAH-EDU-2026',
        );
        await tester.tap(find.text('تحقق من الرمز'));
        await tester.pumpAndSettle();

        expect(find.text('مدارس لهجتي النموذجية'), findsOneWidget);

        // Tap Continue -> Step 1 (Student Info Step)
        await tester.tap(find.widgetWithText(PrimaryButton, 'متابعة'));
        await tester.pumpAndSettle();

        expect(find.byType(SchoolStudentInfoStep), findsOneWidget);
        expect(find.text('بيانات الصف الدراسي'), findsOneWidget);

        // Fill grade and section
        await tester.enterText(find.byType(TextFormField).at(0), 'الصف العاشر');
        await tester.enterText(find.byType(TextFormField).at(1), 'شعبة أ');
        await tester.pumpAndSettle();

        // Tap Continue -> Step 2 (Target Language Selection)
        await tester.tap(find.widgetWithText(PrimaryButton, 'متابعة'));
        await tester.pumpAndSettle();

        expect(find.text('شو اللغة اللي بدك تتعلمها؟'), findsOneWidget);
      },
    );

    testWidgets('3. English Localization for School Steps', (
      WidgetTester tester,
    ) async {
      setMobileScreenSize(tester);
      final container = ProviderContainer();
      container
          .read(onboardingProvider.notifier)
          .selectSchoolRole(SchoolRole.teacher);

      await tester.pumpWidget(
        createSchoolOnboardingWidget(
          locale: const Locale('en'),
          container: container,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SchoolCodeVerificationStep), findsOneWidget);
      expect(find.text('Verify Code'), findsOneWidget);
    });
  });
}
