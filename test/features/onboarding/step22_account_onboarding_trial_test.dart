import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/account/domain/models/account_context.dart';
import 'package:lahjti/features/account/domain/models/onboarding_profile.dart';
import 'package:lahjti/features/account/domain/models/school_membership.dart';
import 'package:lahjti/features/account/domain/models/subscription_access.dart';
import 'package:lahjti/features/account/domain/models/trial_status.dart';
import 'package:lahjti/features/account/domain/models/user_role.dart';
import 'package:lahjti/features/account/presentation/screens/subscription_access_screen.dart';
import 'package:lahjti/features/onboarding/domain/models/age_group.dart';
import 'package:lahjti/features/onboarding/domain/models/experience_level.dart';
import 'package:lahjti/features/onboarding/domain/models/learning_goal.dart';
import 'package:lahjti/features/onboarding/domain/models/native_language.dart';
import 'package:lahjti/features/onboarding/domain/models/supported_language.dart';
import 'package:lahjti/features/onboarding/presentation/onboarding_screen.dart';
import 'package:lahjti/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:lahjti/features/onboarding/presentation/steps/age_group_step.dart';
import 'package:lahjti/features/school/domain/models/school_role.dart';
import 'package:lahjti/features/welcome/presentation/welcome_screen.dart';
import 'package:lahjti/l10n/app_localizations.dart';

void main() {
  group('STEP 22 — Domain Models & Security Isolation Tests', () {
    test('1. UserRole enum defines explicit roles and helpers', () {
      expect(UserRole.individualLearner.isIndividual, isTrue);
      expect(UserRole.individualLearner.isStudent, isFalse);
      expect(UserRole.individualLearner.isTeacher, isFalse);

      expect(UserRole.schoolStudent.isStudent, isTrue);
      expect(UserRole.schoolStudent.isIndividual, isFalse);

      expect(UserRole.schoolTeacher.isTeacher, isTrue);
      expect(UserRole.schoolTeacher.isIndividual, isFalse);

      expect(UserRole.fromString('student'), equals(UserRole.schoolStudent));
      expect(UserRole.fromString('teacher'), equals(UserRole.schoolTeacher));
      expect(
        UserRole.fromString('individual'),
        equals(UserRole.individualLearner),
      );
    });

    test('2. TrialStatus enum provides deterministic state properties', () {
      expect(TrialStatus.trial.isTrial, isTrue);
      expect(TrialStatus.active.isActive, isTrue);
      expect(TrialStatus.expired.isExpired, isTrue);
      expect(TrialStatus.schoolAccess.isSchoolAccess, isTrue);
      expect(TrialStatus.unavailable.isUnavailable, isTrue);

      expect(TrialStatus.fromString('expired'), equals(TrialStatus.expired));
      expect(
        TrialStatus.fromString('school_access'),
        equals(TrialStatus.schoolAccess),
      );
    });

    test('3. SchoolMembership model isolates institutional details', () {
      final now = DateTime(2026, 9, 21);
      final membership = SchoolMembership(
        schoolId: 'sch_123',
        schoolCode: 'SCH-1001',
        schoolName: 'Al-Noor Academy',
        role: SchoolRole.student,
        grade: 'Grade 6',
        classSection: 'A',
        joinedAt: now,
        isVerified: true,
        trialDaysRemaining: 10,
      );

      expect(membership.schoolId, equals('sch_123'));
      expect(membership.role, equals(SchoolRole.student));
      expect(membership.isVerified, isTrue);
      expect(membership.trialDaysRemaining, equals(10));

      final json = membership.toJson();
      final fromJson = SchoolMembership.fromJson(json);
      expect(fromJson.schoolCode, equals('SCH-1001'));
      expect(fromJson.role, equals(SchoolRole.student));
    });

    test('4. OnboardingProfile consolidates complete learner profile', () {
      final profile = OnboardingProfile(
        userId: 'user_001',
        userRole: UserRole.individualLearner,
        accountContext: AccountContext.individual,
        name: 'Ahmad Al-Mansoor',
        ageGroup: AgeGroup.age6_10,
        nativeLanguage: NativeLanguage.arabic,
        targetLanguage: SupportedLanguage.jordanianDialect,
        learningGoal: LearningGoal.casualConversation,
        experienceLevel: ExperienceLevel.beginner,
        selectedTutorId: 'abbas',
        createdAt: DateTime.now(),
        isCompleted: true,
      );

      expect(profile.isChild, isTrue);
      expect(profile.isTeen, isFalse);
      expect(profile.isAdult, isFalse);
      expect(profile.userRole, equals(UserRole.individualLearner));

      final json = profile.toJson();
      final deserialized = OnboardingProfile.fromJson(json);
      expect(deserialized.name, equals('Ahmad Al-Mansoor'));
      expect(deserialized.ageGroup, equals(AgeGroup.age6_10));
      expect(deserialized.isChild, isTrue);
    });

    test('5. AgeGroup brackets and age-adaptive properties', () {
      expect(AgeGroup.age6_10.isChild, isTrue);
      expect(AgeGroup.age6_10.minTouchTargetSize, equals(56.0));
      expect(AgeGroup.age6_10.categoryKey, equals('child'));

      expect(AgeGroup.age11_15.isTeen, isTrue);
      expect(AgeGroup.age16_17.isTeen, isTrue);
      expect(AgeGroup.age11_15.categoryKey, equals('teen'));

      expect(AgeGroup.age18_25.isAdult, isTrue);
      expect(AgeGroup.age26_40.isAdult, isTrue);
      expect(AgeGroup.age41_55.isAdult, isTrue);
      expect(AgeGroup.age18_25.categoryKey, equals('adult'));
      expect(AgeGroup.age18_25.minTouchTargetSize, equals(48.0));
    });
  });

  group('STEP 22 — Deterministic Trial & Subscription Logic Tests', () {
    test('6. Individual 3-day trial creation and validation', () {
      final now = DateTime.now();
      final trial = SubscriptionAccess.initialIndividualTrial(
        userId: 'ind_user_1',
        now: now,
      );

      expect(trial.trialDurationDays, equals(3));
      expect(trial.status, equals(SubscriptionStatus.trial));
      expect(trial.trialStartsAt, equals(now));
      expect(trial.trialEndsAt, equals(now.add(const Duration(days: 3))));
      expect(trial.pricePerMonthUsd, equals(10.0));
      expect(trial.isValidAccess, isTrue);
      expect(trial.priceDisplay, equals('10 USD / month'));
    });

    test('7. Expired individual trial state and calculation', () {
      final now = DateTime(2026, 9, 21, 10, 0);
      final expired = SubscriptionAccess.expiredIndividualTrial(
        userId: 'ind_user_2',
        now: now,
      );

      expect(expired.status, equals(SubscriptionStatus.expired));
      expect(expired.isValidAccess, isFalse);
      expect(expired.isTrialExpired, isTrue);
      expect(expired.daysRemaining, equals(0));
    });

    test(
      '8. School 10-day educational trial and institutional access override',
      () {
        final now = DateTime(2026, 9, 21, 10, 0);
        final schoolAccess = SubscriptionAccess.schoolStudentAccess(
          userId: 'student_1',
          schoolCode: 'SCH-999',
          schoolName: 'King Abdullah Academy',
          now: now,
          trialDays: 10,
        );

        expect(schoolAccess.accountContext, equals(AccountContext.school));
        expect(schoolAccess.status, equals(SubscriptionStatus.schoolAccess));
        expect(schoolAccess.trialDurationDays, equals(10));
        expect(schoolAccess.pricePerMonthUsd, equals(0.0));
        expect(
          schoolAccess.isValidAccess,
          isTrue,
        ); // School access overrides individual subscription
      },
    );
  });

  group('STEP 22 — UI Presentation & Accessibility Tests', () {
    Widget buildTestApp(Widget child, {Locale locale = const Locale('ar')}) {
      return ProviderScope(
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      );
    }

    testWidgets(
      '9. WelcomeScreen renders clear two-path entry model and attribution',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestApp(const WelcomeScreen()));
        await tester.pumpAndSettle();

        // Brand & Entry A) Individual Person CTA
        expect(find.text('لهجتي'), findsOneWidget);
        expect(find.text('ابدأ رحلتك 🚀'), findsOneWidget);

        // Entry B) School Portal
        expect(
          find.byKey(const Key('welcome_school_portal_btn')),
          findsOneWidget,
        );

        // Official Company & Developer attribution
        expect(
          find.text(
            'Phoenix Technical Group (PTG) • Mohammad Abu Abbas • mohammadabuabbas.my',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('10. WelcomeScreen school entry opens "هل أنت؟" role modal', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestApp(const WelcomeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('welcome_school_portal_btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('modal_select_student')), findsOneWidget);
      expect(find.byKey(const Key('modal_select_teacher')), findsOneWidget);
      expect(find.text('طالب'), findsOneWidget);
      expect(find.text('معلم'), findsOneWidget);
    });

    testWidgets(
      '11. AgeGroupStep displays age categories with adaptive subtitles',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestApp(const Scaffold(body: AgeGroupStep())),
        );
        await tester.pumpAndSettle();

        // Check primary age brackets
        expect(find.byKey(const Key('age_option_age6_10')), findsOneWidget);
        expect(find.byKey(const Key('age_option_age11_15')), findsOneWidget);
        expect(find.byKey(const Key('age_option_age16_17')), findsOneWidget);
        expect(find.byKey(const Key('age_option_age18_25')), findsOneWidget);
        expect(find.byKey(const Key('age_option_age26_40')), findsOneWidget);
        expect(find.byKey(const Key('age_option_age41_55')), findsOneWidget);

        // Verify child mode hint
        expect(
          find.text('تجربة مرحة وسهلة مع ألعاب تعليمية مبسطة'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '12. SubscriptionAccessScreen renders trial, price tag, and upgrade button',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestApp(const SubscriptionAccessScreen()));
        await tester.pumpAndSettle();

        // Subscription Title & Features
        expect(find.text('الاشتراك والوصول'), findsOneWidget);
        expect(find.text('ماذا تشمل باقة لهجتي الكاملة؟'), findsOneWidget);
        expect(find.text('10 دولارات شهرياً (10 USD / Month)'), findsOneWidget);

        // Upgrade CTA button (Sandbox payment for pilot)
        final btnFinder = find.byKey(const Key('subscription_upgrade_cta_btn'));
        expect(btnFinder, findsOneWidget);

        // Developer attribution
        expect(find.text('mohammadabuabbas.my'), findsOneWidget);
      },
    );

    testWidgets(
      '13. English LTR layout renders correctly for SubscriptionAccessScreen',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestApp(
            const SubscriptionAccessScreen(),
            locale: const Locale('en'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Subscription & Access'), findsOneWidget);
        expect(find.text("What's included in full Lahjti?"), findsOneWidget);
        expect(find.text('10 USD / month'), findsOneWidget);
        expect(
          find.byKey(const Key('subscription_upgrade_cta_btn')),
          findsOneWidget,
        );
        expect(
          find.text(
            'Developed by: Mohammad Abu Abbas • Phoenix Technical Group (PTG)',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '14. OnboardingScreen displays child banner when age 6-10 is selected',
      (WidgetTester tester) async {
        final container = ProviderContainer();
        container
            .read(onboardingProvider.notifier)
            .selectAgeGroup(AgeGroup.age6_10);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              locale: Locale('ar'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: OnboardingScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Child mode banner should be visible
        expect(find.text('🎈 أطفال'), findsOneWidget);
      },
    );
  });
}
