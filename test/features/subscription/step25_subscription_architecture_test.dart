import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/core/network/api_client.dart';
import 'package:lahjti/features/account/domain/models/account_context.dart';
import 'package:lahjti/features/account/domain/models/subscription_access.dart';
import 'package:lahjti/features/account/presentation/screens/subscription_access_screen.dart';
import 'package:lahjti/features/school/domain/models/school_role.dart';
import 'package:lahjti/features/subscription/data/repositories/in_memory_subscription_repository.dart';
import 'package:lahjti/features/subscription/data/repositories/remote_subscription_repository.dart';
import 'package:lahjti/features/subscription/domain/models/feature_access_key.dart';
import 'package:lahjti/features/subscription/domain/services/access_policy_engine.dart';
import 'package:lahjti/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:lahjti/features/subscription/presentation/widgets/subscription_guard.dart';
import 'package:lahjti/l10n/app_localizations.dart';

class MockDioAdapter implements HttpClientAdapter {
  ResponseBody Function(RequestOptions options)? handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (handler != null) {
      return handler!(options);
    }
    return ResponseBody.fromString('{"success": true, "data": {}}', 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('STEP 25 — Subscription, Trial & Monetization Architecture Tests', () {
    const policyEngine = AccessPolicyEngine();

    // 1. Individual 3-Day Trial Domain Model
    test(
      '1. Individual subscription creates 3-day free trial at 10 USD/month',
      () {
        final now = DateTime.now();
        final sub = SubscriptionAccess.initialIndividualTrial(
          userId: 'usr_sami_01',
          now: now,
        );

        expect(sub.userId, 'usr_sami_01');
        expect(sub.accountContext, AccountContext.individual);
        expect(sub.status, SubscriptionStatus.trial);
        expect(sub.trialDurationDays, 3);
        expect(sub.pricePerMonthUsd, 10.0);
        expect(sub.trialEndsAt, now.add(const Duration(days: 3)));
        expect(sub.isValidAccess, isTrue);
        expect(sub.isTrialExpired, isFalse);
      },
    );

    // 2. School Student 10-Day Free Trial
    test(
      '2. School Student subscription creates 10-day trial covered by school license (0 USD)',
      () {
        final now = DateTime(2026, 9, 22, 10, 0);
        final sub = SubscriptionAccess.schoolStudentAccess(
          userId: 'usr_layla_02',
          schoolCode: 'SCH-1001',
          schoolName: 'مدرسة النور الأهلية',
          now: now,
          trialDays: 10,
        );

        expect(sub.accountContext, AccountContext.school);
        expect(sub.trialDurationDays, 10);
        expect(sub.pricePerMonthUsd, 0.0);
        expect(sub.schoolCode, 'SCH-1001');
        expect(sub.isValidAccess, isTrue);
      },
    );

    // 3. Status Enum Parsing & Aliases
    test('3. SubscriptionStatus parses status strings and aliases', () {
      expect(SubscriptionStatus.fromString('trial'), SubscriptionStatus.trial);
      expect(
        SubscriptionStatus.fromString('active'),
        SubscriptionStatus.active,
      );
      expect(
        SubscriptionStatus.fromString('expired'),
        SubscriptionStatus.expired,
      );
      expect(
        SubscriptionStatus.fromString('cancelled'),
        SubscriptionStatus.cancelled,
      );
      expect(
        SubscriptionStatus.fromString('paymentPending'),
        SubscriptionStatus.paymentPending,
      );
      expect(
        SubscriptionStatus.fromString('payment_pending'),
        SubscriptionStatus.paymentPending,
      );
      expect(
        SubscriptionStatus.fromString('school_access'),
        SubscriptionStatus.schoolAccess,
      );
    });

    // 4. AccessPolicyEngine: Individual Active Trial Permissions
    test(
      '4. AccessPolicyEngine grants learning features and denies school features for individual trial',
      () {
        final now = DateTime(2026, 9, 22, 10, 0);
        final sub = SubscriptionAccess.initialIndividualTrial(
          userId: 'usr_sami_01',
          now: now,
        );

        // Core learning features allowed
        final permLessons = policyEngine.evaluateFeatureAccess(
          feature: FeatureAccessKey.lessons,
          subscription: sub,
          accountContext: AccountContext.individual,
          currentTime: now,
        );
        expect(permLessons.isAllowed, isTrue);

        final permTutor = policyEngine.evaluateFeatureAccess(
          feature: FeatureAccessKey.aiTutor,
          subscription: sub,
          accountContext: AccountContext.individual,
          currentTime: now,
        );
        expect(permTutor.isAllowed, isTrue);

        final permGames = policyEngine.evaluateFeatureAccess(
          feature: FeatureAccessKey.games,
          subscription: sub,
          accountContext: AccountContext.individual,
          currentTime: now,
        );
        expect(permGames.isAllowed, isTrue);

        // Teacher dashboard forbidden for individual account
        final permTeacher = policyEngine.evaluateFeatureAccess(
          feature: FeatureAccessKey.teacherDashboard,
          subscription: sub,
          accountContext: AccountContext.individual,
          currentTime: now,
        );
        expect(permTeacher.isAllowed, isFalse);
      },
    );

    // 5. AccessPolicyEngine: Expired Individual Trial Restricts Access
    test(
      '5. AccessPolicyEngine restricts learning features when individual trial is expired',
      () {
        final now = DateTime(2026, 9, 22, 10, 0);
        final expiredSub = SubscriptionAccess.expiredIndividualTrial(
          userId: 'usr_sami_01',
          now: now,
        );

        final perm = policyEngine.evaluateFeatureAccess(
          feature: FeatureAccessKey.lessons,
          subscription: expiredSub,
          accountContext: AccountContext.individual,
          currentTime: now,
        );

        expect(perm.isAllowed, isFalse);
        expect(perm.requiredActionRoute, '/subscription/access');
      },
    );

    // 6. AccessPolicyEngine: Teacher Role Bypasses Individual Subscription
    test(
      '6. AccessPolicyEngine grants teacher dashboard to verified teacher without individual payment',
      () {
        final teacherSub = const SubscriptionAccess(
          userId: 'usr_teacher_01',
          accountContext: AccountContext.school,
          status: SubscriptionStatus.schoolAccess,
          pricePerMonthUsd: 0.0,
        );

        final perm = policyEngine.evaluateFeatureAccess(
          feature: FeatureAccessKey.teacherDashboard,
          subscription: teacherSub,
          accountContext: AccountContext.school,
          schoolRole: SchoolRole.teacher,
        );

        expect(perm.isAllowed, isTrue);
      },
    );

    // 7. RemoteSubscriptionRepository JSON Parsing & API Client
    test(
      '7. RemoteSubscriptionRepository communicates with /subscription/status and parses DTO',
      () async {
        final dio = Dio(
          BaseOptions(baseUrl: 'https://api-dev.lahjti.com/api/v1'),
        );
        final mockAdapter = MockDioAdapter();
        dio.httpClientAdapter = mockAdapter;
        final apiClient = ApiClient(dio);
        final repo = RemoteSubscriptionRepository(apiClient);

        mockAdapter.handler = (options) {
          expect(options.path, '/subscription/status');
          expect(options.method, 'GET');
          return ResponseBody.fromString(
            '''
          {
            "success": true,
            "data": {
              "userId": "usr_remote_01",
              "accountContext": "individual",
              "role": "individual",
              "status": "trial",
              "planId": "individual_monthly",
              "priceUsd": 10.0,
              "trialDurationDays": 3,
              "trialStartsAt": "${DateTime.now().toIso8601String()}",
              "trialEndsAt": "${DateTime.now().add(const Duration(days: 3)).toIso8601String()}",
              "isValidAccess": true,
              "isTrialActive": true,
              "daysRemaining": 3
            }
          }
          ''',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        };

        final result = await repo.getSubscriptionStatus(
          userId: 'usr_remote_01',
        );
        expect(result.userId, 'usr_remote_01');
        expect(result.status, SubscriptionStatus.trial);
        expect(result.pricePerMonthUsd, 10.0);
        expect(result.isValidAccess, isTrue);
      },
    );

    // 8. SubscriptionGuard Widget: Unrestricted State
    testWidgets('8. SubscriptionGuard renders child when access is allowed', (
      tester,
    ) async {
      final allowedRepo = InMemorySubscriptionRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionRepositoryProvider.overrideWithValue(allowedRepo),
          ],
          child: const MaterialApp(
            locale: Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SubscriptionGuard(
                feature: FeatureAccessKey.lessons,
                child: Text('محتوى الدرس المفتوح'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('محتوى الدرس المفتوح'), findsOneWidget);
      expect(
        find.byKey(const Key('subscription_guard_upgrade_btn')),
        findsNothing,
      );
    });

    // 8b. SubscriptionGuard Widget: Locked / Paywall State
    testWidgets(
      '8b. SubscriptionGuard renders paywall card and CTA button when access is denied',
      (tester) async {
        final lockedRepo = InMemorySubscriptionRepository();
        lockedRepo.setSubscriptionState(
          'usr_local_learner',
          SubscriptionAccess.expiredIndividualTrial(
            userId: 'usr_local_learner',
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              subscriptionRepositoryProvider.overrideWithValue(lockedRepo),
            ],
            child: const MaterialApp(
              locale: Locale('ar'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: SubscriptionGuard(
                  feature: FeatureAccessKey.lessons,
                  child: Text('محتوى الدرس المفتوح'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('الميزة مقفلة حالياً'), findsOneWidget);
        expect(find.text('محتوى الدرس المفتوح'), findsNothing);
        expect(
          find.byKey(const Key('subscription_guard_upgrade_btn')),
          findsOneWidget,
        );
      },
    );

    // 9. SubscriptionAccessScreen UI Presentation
    testWidgets(
      '9. SubscriptionAccessScreen renders transparent 10 USD/mo plan and trial badge in Arabic',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              subscriptionRepositoryProvider.overrideWithValue(
                InMemorySubscriptionRepository(),
              ),
            ],
            child: const MaterialApp(
              locale: Locale('ar'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: SubscriptionAccessScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('الاشتراك والوصول'), findsOneWidget);
        expect(find.textContaining('10'), findsWidgets);
      },
    );

    // 10. Expired Subscription Access Evaluation
    test(
      '10. AccessPolicyEngine restricts learning when paid subscription has expired',
      () {
        final now = DateTime(2026, 9, 22, 10, 0);
        final expiredPaidSub = SubscriptionAccess(
          userId: 'usr_expired_paid',
          accountContext: AccountContext.individual,
          status: SubscriptionStatus.expired,
          pricePerMonthUsd: 10.0,
          currentPeriodStart: now.subtract(const Duration(days: 60)),
          currentPeriodEnd: now.subtract(const Duration(days: 30)),
          subscriptionExpiresAt: now.subtract(const Duration(days: 30)),
        );

        final perm = policyEngine.evaluateFeatureAccess(
          feature: FeatureAccessKey.lessons,
          subscription: expiredPaidSub,
          accountContext: AccountContext.individual,
          currentTime: now,
        );

        expect(perm.isAllowed, isFalse);
        expect(perm.requiredActionRoute, '/subscription/access');
        expect(expiredPaidSub.isValidAccess, isFalse);
      },
    );

    // 11. Trial Anti-Reset: InMemory and Server-side Repository prevents resetting elapsed trial
    test(
      '11. SubscriptionRepository prevents resetting expired trial duration upon startTrial re-invocation',
      () async {
        final repo = InMemorySubscriptionRepository();
        final now = DateTime(2026, 9, 22, 10, 0);

        // Initial trial started
        final sub1 = await repo.startTrial(
          userId: 'usr_anti_reset',
          context: AccountContext.individual,
          role: SchoolRole.student,
        );
        expect(sub1.status, SubscriptionStatus.trial);

        // Set to expired state in database
        final expired = SubscriptionAccess.expiredIndividualTrial(
          userId: 'usr_anti_reset',
          now: now,
        );
        repo.setSubscriptionState('usr_anti_reset', expired);

        // Re-invoking startTrial (simulating logout/login or app reinstall) returns existing expired state without resetting!
        final sub2 = await repo.startTrial(
          userId: 'usr_anti_reset',
          context: AccountContext.individual,
          role: SchoolRole.student,
        );
        expect(sub2.status, SubscriptionStatus.expired);
        expect(sub2.isValidAccess, isFalse);
      },
    );

    // 12. Server-Authoritative Access vs Client Tampering Isolation
    test(
      '12. AccessPolicyEngine rejects unverified student attempting to access teacher features',
      () {
        final studentSub = const SubscriptionAccess(
          userId: 'usr_student_malicious',
          accountContext: AccountContext.school,
          status: SubscriptionStatus.trial,
          pricePerMonthUsd: 0.0,
        );

        // Student attempting to access teacher dashboard
        final perm = policyEngine.evaluateFeatureAccess(
          feature: FeatureAccessKey.teacherDashboard,
          subscription: studentSub,
          accountContext: AccountContext.school,
          schoolRole: SchoolRole.student, // Student role
        );

        expect(perm.isAllowed, isFalse);
        expect(perm.requiredActionRoute, '/welcome');
      },
    );
  });
}
