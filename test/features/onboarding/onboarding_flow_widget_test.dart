import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lahjti/core/theme/app_theme.dart';
import 'package:lahjti/features/onboarding/presentation/onboarding_screen.dart';
import 'package:lahjti/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:lahjti/features/onboarding/presentation/steps/target_language_step.dart';
import 'package:lahjti/features/onboarding/presentation/steps/age_group_step.dart';
import 'package:lahjti/features/onboarding/presentation/steps/native_language_step.dart';
import 'package:lahjti/features/onboarding/presentation/steps/learning_goal_step.dart';
import 'package:lahjti/features/onboarding/presentation/steps/experience_level_step.dart';
import 'package:lahjti/features/onboarding/presentation/steps/account_registration_step.dart';
import 'package:lahjti/features/onboarding/presentation/steps/tutor_selection_step.dart';
import 'package:lahjti/features/onboarding/presentation/steps/completion_step.dart';
import 'package:lahjti/core/widgets/buttons/primary_button.dart';
import 'package:lahjti/l10n/app_localizations.dart';

void main() {
  Widget createOnboardingWidget({
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
              (context, state) =>
                  const Scaffold(body: Center(child: Text('Home Page'))),
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

  group('Onboarding Flow Full Widget Tests', () {
    testWidgets(
      '1. Step 1: Language selection and continue button enable/disable',
      (WidgetTester tester) async {
        setMobileScreenSize(tester);
        final container = ProviderContainer();
        await tester.pumpWidget(createOnboardingWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.byType(TargetLanguageStep), findsOneWidget);
        expect(find.text('شو اللغة اللي بدك تتعلمها؟'), findsOneWidget);

        // Select English
        final englishOption = find.text('الإنجليزية');
        expect(englishOption, findsOneWidget);
        await tester.tap(englishOption);
        await tester.pumpAndSettle();

        // Tap Continue CTA
        final continueButton = find.byType(PrimaryButton);
        await tester.tap(continueButton);
        await tester.pumpAndSettle();

        // Verify advanced to AgeGroupStep
        expect(find.byType(AgeGroupStep), findsOneWidget);
        expect(find.text('كم عمرك؟'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Step 2 & 3: Age & Native Language selection and back navigation',
      (WidgetTester tester) async {
        setMobileScreenSize(tester);
        final container = ProviderContainer();
        container.read(onboardingProvider.notifier).goToStep(1);

        await tester.pumpWidget(createOnboardingWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.byType(AgeGroupStep), findsOneWidget);

        // Select 19–25
        await tester.tap(find.text('19–25'));
        await tester.pumpAndSettle();

        // Continue to Step 3 (Native Language)
        await tester.tap(find.byType(PrimaryButton));
        await tester.pumpAndSettle();

        expect(find.byType(NativeLanguageStep), findsOneWidget);
        expect(find.text('شو لغتك الأم؟'), findsOneWidget);

        // Tap Back button in AppBar
        final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        // Verify returned to AgeGroupStep with 19–25 selection preserved
        expect(find.byType(AgeGroupStep), findsOneWidget);
        expect(
          container.read(onboardingProvider).data.ageGroup?.label,
          '19–25',
        );
      },
    );

    testWidgets('3. Step 4 & 5: Goal and Experience selection', (
      WidgetTester tester,
    ) async {
      setMobileScreenSize(tester);
      final container = ProviderContainer();
      container.read(onboardingProvider.notifier).goToStep(3);

      await tester.pumpWidget(createOnboardingWidget(container: container));
      await tester.pumpAndSettle();

      expect(find.byType(LearningGoalStep), findsOneWidget);
      expect(find.text('ليش بدك تتعلم اللغة؟'), findsOneWidget);

      // Select Conversation goal
      await tester.tap(find.text('المحادثة'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      // Step 5: Experience
      expect(find.byType(ExperienceLevelStep), findsOneWidget);
      expect(find.text('قديش بتعرف عن اللغة؟'), findsOneWidget);

      await tester.tap(find.text('ولا كلمة تقريبًا'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      // Step 6: Account Registration
      expect(find.byType(AccountRegistrationStep), findsOneWidget);
    });

    testWidgets(
      '4. Step 6: Registration validation (empty, invalid email, weak password, mismatch)',
      (WidgetTester tester) async {
        setMobileScreenSize(tester);
        final container = ProviderContainer();
        container.read(onboardingProvider.notifier).goToStep(5);

        await tester.pumpWidget(createOnboardingWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.byType(AccountRegistrationStep), findsOneWidget);
        expect(find.text('أنشئ حسابك'), findsOneWidget);

        final continueButton = find.byType(PrimaryButton);

        // 1. Submit empty form
        await tester.tap(continueButton);
        await tester.pumpAndSettle();
        expect(find.text('اكتب اسمك أولاً.'), findsOneWidget);

        // 2. Fill name, invalid email
        await tester.enterText(find.byType(TextFormField).at(0), 'سامي');
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'invalid-email',
        );
        await tester.tap(continueButton);
        await tester.pumpAndSettle();
        expect(find.text('تأكد من البريد الإلكتروني.'), findsOneWidget);

        // 3. Valid email, short password
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'sami@example.com',
        );
        await tester.enterText(find.byType(TextFormField).at(2), '123');
        await tester.tap(continueButton);
        await tester.pumpAndSettle();
        expect(
          find.text('كلمة المرور لازم تكون أقوى (6 خانات على الأقل).'),
          findsOneWidget,
        );

        // 4. Mismatched passwords
        await tester.enterText(find.byType(TextFormField).at(2), 'password123');
        await tester.enterText(find.byType(TextFormField).at(3), 'mismatch456');
        await tester.tap(continueButton);
        await tester.pumpAndSettle();
        expect(find.text('كلمتا المرور غير متطابقتين.'), findsOneWidget);

        // 5. Valid inputs -> successfully registers and advances
        await tester.enterText(find.byType(TextFormField).at(3), 'password123');
        await tester.tap(continueButton);
        await tester.pumpAndSettle();

        // Verify advanced to TutorSelectionStep
        expect(find.byType(TutorSelectionStep), findsOneWidget);
        expect(find.text('مين بدك يكون مدربك؟'), findsOneWidget);
      },
    );

    testWidgets(
      '5. Step 7 to 10: Tutor selection, Placement Intro, Results, and completion to Home navigation',
      (WidgetTester tester) async {
        setMobileScreenSize(tester);
        final container = ProviderContainer();
        container.read(onboardingProvider.notifier).goToStep(6);

        await tester.pumpWidget(createOnboardingWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.byType(TutorSelectionStep), findsOneWidget);
        expect(find.text('عباس'), findsOneWidget);
        expect(find.text('دنيا'), findsOneWidget);

        // Select Abbas
        await tester.tap(find.text('عباس'));
        await tester.pumpAndSettle();

        // Tap Continue -> advances to Step 7 (Placement Intro)
        await tester.tap(find.byType(PrimaryButton));
        await tester.pumpAndSettle();

        expect(find.text('خلينا نشوف من وين نبدأ 🎯'), findsOneWidget);
        expect(find.text('يلا نبلش'), findsOneWidget);

        // Jump to Completion (Step 10) to verify Home navigation
        container.read(onboardingProvider.notifier).goToStep(10);
        await tester.pumpAndSettle();

        expect(find.byType(CompletionStep), findsOneWidget);
        expect(find.text('جاهزين! 🚀'), findsOneWidget);
        expect(find.text('خلينا نبدأ'), findsOneWidget);

        // Tap CTA to navigate to Home
        await tester.tap(find.text('خلينا نبدأ'));
        await tester.pumpAndSettle();

        expect(find.text('Home Page'), findsOneWidget);
      },
    );
  });
}
