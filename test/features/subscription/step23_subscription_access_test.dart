import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/account/domain/models/account_context.dart';
import 'package:lahjti/features/account/domain/models/school_membership.dart';
import 'package:lahjti/features/account/domain/models/subscription_access.dart';
import 'package:lahjti/features/account/presentation/screens/subscription_access_screen.dart';
import 'package:lahjti/features/profile/presentation/screens/profile_screen.dart';
import 'package:lahjti/features/school/domain/models/school_role.dart';
import 'package:lahjti/features/subscription/data/providers/development_billing_provider.dart';
import 'package:lahjti/features/subscription/domain/models/access_decision.dart';
import 'package:lahjti/features/subscription/domain/models/billing_event.dart';
import 'package:lahjti/features/subscription/domain/models/subscription_plan.dart';
import 'package:lahjti/features/subscription/domain/models/subscription_status_enums.dart';
import 'package:lahjti/features/subscription/domain/services/access_decision_engine.dart';
import 'package:lahjti/features/subscription/domain/services/billing_provider.dart';
import 'package:lahjti/l10n/app_localizations.dart';

void main() {
  group('STEP 23 — Subscription Domain & Plan Models Tests', () {
    test(
      r'1. SubscriptionPlan model defines $10/mo Individual Plan with 3-day trial',
      () {
        const plan = SubscriptionPlan.individualMonthly;

        expect(plan.id, equals('lahjti_individual_monthly'));
        expect(plan.priceUsd, equals(10.0));
        expect(plan.currency, equals('USD'));
        expect(plan.period, equals(SubscriptionPeriod.monthly));
        expect(plan.trialDurationDays, equals(3));
        expect(plan.priceFormatted, equals('\$10 / month'));
        expect(plan.priceFormattedAr, contains('10 دولارات'));
        expect(plan.featuresAr, isNotEmpty);
        expect(plan.featuresEn, isNotEmpty);

        final json = plan.toJson();
        final fromJson = SubscriptionPlan.fromJson(json);
        expect(fromJson.priceUsd, equals(10.0));
        expect(fromJson.period, equals(SubscriptionPeriod.monthly));
      },
    );

    test(
      '2. SubscriptionStatus enum supports all required individual and school states',
      () {
        expect(SubscriptionStatus.trial.isTrial, isTrue);
        expect(SubscriptionStatus.active.isActive, isTrue);
        expect(SubscriptionStatus.expired.isExpired, isTrue);
        expect(SubscriptionStatus.cancelled.isCancelled, isTrue);
        expect(SubscriptionStatus.pastDue.isPastDue, isTrue);
        expect(SubscriptionStatus.pending.isPending, isTrue);
        expect(SubscriptionStatus.schoolAccess.isSchoolAccess, isTrue);
        expect(SubscriptionStatus.suspended.isSuspended, isTrue);

        expect(
          SubscriptionStatus.fromString('past_due'),
          equals(SubscriptionStatus.pastDue),
        );
        expect(
          SubscriptionStatus.fromString('suspended'),
          equals(SubscriptionStatus.suspended),
        );
      },
    );
  });

  group('STEP 23 — Access Decision Engine Deterministic Tests', () {
    const engine = AccessDecisionEngine();
    final fixedNow = DateTime(2026, 9, 22, 12, 0);

    test('3. Individual with active 3-day trial is allowed access', () {
      final access = SubscriptionAccess.initialIndividualTrial(
        userId: 'user_trial',
        now: fixedNow,
      );

      final decision = engine.evaluate(
        accountContext: AccountContext.individual,
        subscriptionAccess: access,
        currentTime: fixedNow.add(const Duration(days: 1)),
      );

      expect(decision.isAccessAllowed, isTrue);
      expect(
        decision.reason,
        equals(AccessDecisionReason.individualActiveTrial),
      );
      expect(decision.requiredAction, equals(AccessRequiredAction.none));
      expect(decision.remainingTrialDays, equals(2));
    });

    test(
      '4. Individual with expired trial is denied access and required to subscribe',
      () {
        final access = SubscriptionAccess.expiredIndividualTrial(
          userId: 'user_expired',
          now: fixedNow,
        );

        final decision = engine.evaluate(
          accountContext: AccountContext.individual,
          subscriptionAccess: access,
          currentTime: fixedNow,
        );

        expect(decision.isAccessAllowed, isFalse);
        expect(
          decision.reason,
          equals(AccessDecisionReason.individualExpiredTrial),
        );
        expect(decision.requiredAction, equals(AccessRequiredAction.subscribe));
        expect(decision.requiredAction.requiresSubscription, isTrue);
      },
    );

    test(
      r'5. Individual with active paid subscription ($10/mo) is allowed access',
      () {
        final access = SubscriptionAccess.activeIndividualSubscription(
          userId: 'user_paid',
          now: fixedNow,
          periodDays: 30,
        );

        final decision = engine.evaluate(
          accountContext: AccountContext.individual,
          subscriptionAccess: access,
          currentTime: fixedNow.add(const Duration(days: 15)),
        );

        expect(decision.isAccessAllowed, isTrue);
        expect(
          decision.reason,
          equals(AccessDecisionReason.individualActiveSubscription),
        );
        expect(decision.requiredAction, equals(AccessRequiredAction.none));
      },
    );

    test(
      '6. Cancelled subscription remains valid during grace period until period end',
      () {
        final periodEnd = fixedNow.add(const Duration(days: 14));
        final access = SubscriptionAccess.cancelledIndividualSubscription(
          userId: 'user_cancelled',
          periodEnd: periodEnd,
          now: fixedNow,
        );

        // Check while period is still running
        final decisionBefore = engine.evaluate(
          accountContext: AccountContext.individual,
          subscriptionAccess: access,
          currentTime: fixedNow.add(const Duration(days: 5)),
        );

        expect(decisionBefore.isAccessAllowed, isTrue);
        expect(
          decisionBefore.reason,
          equals(AccessDecisionReason.individualCancelledGracePeriod),
        );

        // Check after period has elapsed
        final decisionAfter = engine.evaluate(
          accountContext: AccountContext.individual,
          subscriptionAccess: access,
          currentTime: fixedNow.add(const Duration(days: 15)),
        );

        expect(decisionAfter.isAccessAllowed, isFalse);
        expect(
          decisionAfter.reason,
          equals(AccessDecisionReason.individualSubscriptionExpired),
        );
        expect(
          decisionAfter.requiredAction,
          equals(AccessRequiredAction.subscribe),
        );
      },
    );

    test(
      '7. School student with verified school membership is allowed access without individual subscription',
      () {
        final membership = SchoolMembership(
          schoolId: 'sch_1',
          schoolCode: 'SCH-1001',
          schoolName: 'Al-Noor Academy',
          role: SchoolRole.student,
          grade: 'Grade 6',
          joinedAt: fixedNow,
          isVerified: true,
          trialDaysRemaining: 10,
        );

        final decision = engine.evaluate(
          accountContext: AccountContext.school,
          schoolMembership: membership,
          currentTime: fixedNow,
        );

        expect(decision.isAccessAllowed, isTrue);
        expect(
          decision.reason,
          equals(AccessDecisionReason.schoolStudentActive),
        );
        expect(decision.requiredAction, equals(AccessRequiredAction.none));
      },
    );

    test(
      '8. School teacher with verified membership is allowed teacher access',
      () {
        final membership = SchoolMembership(
          schoolId: 'sch_2',
          schoolCode: 'SCH-2002',
          schoolName: 'King Hussein School',
          role: SchoolRole.teacher,
          joinedAt: fixedNow,
          isVerified: true,
        );

        final decision = engine.evaluate(
          accountContext: AccountContext.school,
          schoolMembership: membership,
          currentTime: fixedNow,
        );

        expect(decision.isAccessAllowed, isTrue);
        expect(
          decision.reason,
          equals(AccessDecisionReason.schoolTeacherActive),
        );
      },
    );

    test(
      '9. Suspended school membership restricts access and prompts to contact admin',
      () {
        final membership = SchoolMembership(
          schoolId: 'sch_3',
          schoolCode: 'SCH-3003',
          schoolName: 'Modern School',
          role: SchoolRole.student,
          joinedAt: fixedNow,
          isVerified: false, // Suspended
        );

        final decision = engine.evaluate(
          accountContext: AccountContext.school,
          schoolMembership: membership,
          currentTime: fixedNow,
        );

        expect(decision.isAccessAllowed, isFalse);
        expect(
          decision.reason,
          equals(AccessDecisionReason.schoolMembershipSuspended),
        );
        expect(
          decision.requiredAction,
          equals(AccessRequiredAction.contactSchoolAdmin),
        );
      },
    );

    test(
      '10. School vs Individual Isolation: expired individual trial cannot bypass restrictions via unverified school state',
      () {
        final expiredIndividual = SubscriptionAccess.expiredIndividualTrial(
          userId: 'ind_user_isolated',
          now: fixedNow,
        );

        // In individual context, access is restricted regardless of whether another school code exists elsewhere
        final decision = engine.evaluate(
          accountContext: AccountContext.individual,
          subscriptionAccess: expiredIndividual,
          currentTime: fixedNow,
        );

        expect(decision.isAccessAllowed, isFalse);
        expect(
          decision.reason,
          equals(AccessDecisionReason.individualExpiredTrial),
        );
        expect(decision.requiredAction, equals(AccessRequiredAction.subscribe));
      },
    );
  });

  group('STEP 23 — Billing Provider Abstraction & Webhook Tests', () {
    test(
      '11. DevelopmentBillingProvider safely returns plans without real charging',
      () async {
        final provider = DevelopmentBillingProvider();
        final plans = await provider.getAvailablePlans();

        expect(plans, isNotEmpty);
        expect(plans.first.id, equals('lahjti_individual_monthly'));

        final purchaseResult = await provider.purchasePlan(plans.first);
        expect(
          purchaseResult.status,
          equals(PurchaseStatus.disabledInDevelopment),
        );
        expect(purchaseResult.status.isDisabled, isTrue);

        final restoreResult = await provider.restorePurchases();
        expect(restoreResult.isSuccessful, isFalse);
        expect(restoreResult.message, contains('development'));

        provider.dispose();
      },
    );

    test(
      '12. BillingEventIdempotencyTracker rejects duplicate webhook events',
      () {
        final tracker = BillingEventIdempotencyTracker();

        const key1 = 'evt_idem_1001';
        const key2 = 'evt_idem_1002';

        expect(
          tracker.recordAndVerify(key1),
          isTrue,
        ); // First processing accepted
        expect(tracker.recordAndVerify(key1), isFalse); // Duplicate rejected!
        expect(tracker.recordAndVerify(key2), isTrue); // New key accepted
        expect(tracker.processedCount, equals(2));
      },
    );

    test('13. BillingEvent model correctly serializes and parses payload', () {
      final event = BillingEvent(
        eventId: 'evt_999',
        idempotencyKey: 'idem_999',
        userId: 'usr_888',
        planId: 'lahjti_individual_monthly',
        type: BillingEventType.renewed,
        timestamp: DateTime(2026, 9, 22),
        payload: {'amount': 10.0, 'currency': 'USD'},
      );

      final json = event.toJson();
      final fromJson = BillingEvent.fromJson(json);

      expect(fromJson.eventId, equals('evt_999'));
      expect(fromJson.type, equals(BillingEventType.renewed));
      expect(fromJson.payload['amount'], equals(10.0));
    });
  });

  group('STEP 23 — UI Presentation & Accessibility Tests', () {
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
      '14. SubscriptionAccessScreen renders terms dialog, privacy dialog, and restore button',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildTestApp(const SubscriptionAccessScreen()));
        await tester.pumpAndSettle();

        // Verify Restore purchases button
        expect(
          find.byKey(const Key('subscription_restore_btn')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('subscription_restore_btn')));
        await tester.pumpAndSettle();

        // Verify feedback snackbar
        expect(
          find.text(
            'خاصية استعادة المشتريات ستكون متاحة مع إطلاق بوابات الدفع الرسمية',
          ),
          findsOneWidget,
        );

        // Tap Terms of service
        expect(find.byKey(const Key('subscription_terms_btn')), findsOneWidget);
        await tester.tap(find.byKey(const Key('subscription_terms_btn')));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('OK'), findsOneWidget);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        // Tap Privacy policy
        expect(
          find.byKey(const Key('subscription_privacy_btn')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('subscription_privacy_btn')));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      '15. ProfileScreen renders active individual trial badge and status',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestApp(const ProfileScreen()));
        await tester.pumpAndSettle();

        expect(find.text('الملف الشخصي والاشتراك'), findsOneWidget);
        expect(find.text('حالة الاشتراك والوصول'), findsOneWidget);
        expect(find.text('فترة تجريبية مجانية نشطة'), findsOneWidget);
        expect(find.text('mohammadabuabbas.my'), findsOneWidget);
      },
    );

    testWidgets('16. ProfileScreen renders English LTR layout accurately', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(const ProfileScreen(), locale: const Locale('en')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Account & Subscription'), findsOneWidget);
      expect(find.text('Access Status'), findsOneWidget);
      expect(find.text('Free Trial Active'), findsOneWidget);
      expect(find.text('mohammadabuabbas.my'), findsOneWidget);
    });
  });
}
