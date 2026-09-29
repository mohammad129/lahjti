import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/account/domain/models/account_context.dart';
import 'package:lahjti/features/account/domain/models/subscription_access.dart';

void main() {
  group('SubscriptionAccess Domain Model Tests', () {
    test('1. Individual 3-day trial creation and validation', () {
      final trial = SubscriptionAccess.initialIndividualTrial(
        userId: 'u_individual',
      );

      expect(trial.accountContext, AccountContext.individual);
      expect(trial.status, SubscriptionStatus.trial);
      expect(trial.status.isTrial, isTrue);
      expect(trial.isValidAccess, isTrue);
      expect(trial.daysRemaining, inInclusiveRange(2, 3));
      expect(trial.pricePerMonthUsd, 10.0);
    });

    test('2. Expired trial calculation', () {
      final expiredTrial = SubscriptionAccess(
        userId: 'u_individual',
        accountContext: AccountContext.individual,
        status: SubscriptionStatus.trial,
        trialStartsAt: DateTime.now().subtract(const Duration(days: 5)),
        trialEndsAt: DateTime.now().subtract(const Duration(days: 2)),
      );

      expect(expiredTrial.status.isTrial, isTrue);
      expect(expiredTrial.isValidAccess, isFalse);
      expect(expiredTrial.daysRemaining, 0);
    });

    test('3. Active paid subscription model (No real payment provider)', () {
      final activeSub = SubscriptionAccess(
        userId: 'u_paid',
        accountContext: AccountContext.individual,
        status: SubscriptionStatus.active,
        subscriptionExpiresAt: DateTime.now().add(const Duration(days: 25)),
      );

      expect(activeSub.status, SubscriptionStatus.active);
      expect(activeSub.status.isActive, isTrue);
      expect(activeSub.isValidAccess, isTrue);
      expect(activeSub.daysRemaining, inInclusiveRange(24, 25));
    });

    test('4. School Student 10-day trial and permanent school access', () {
      final studentAccess = SubscriptionAccess.schoolStudentAccess(
        userId: 'u_student',
        schoolCode: 'SCH-1001',
        schoolName: 'Al Rowad School',
        trialDays: 10,
      );

      expect(studentAccess.accountContext, AccountContext.school);
      expect(studentAccess.schoolCode, 'SCH-1001');
      expect(studentAccess.status, SubscriptionStatus.schoolAccess);
      expect(studentAccess.isValidAccess, isTrue);
      expect(studentAccess.daysRemaining, inInclusiveRange(9, 10));
    });

    test('5. JSON Serialization and Deserialization', () {
      final original = SubscriptionAccess.initialIndividualTrial(
        userId: 'u_test',
      );
      final json = original.toJson();
      final reconstructed = SubscriptionAccess.fromJson(json);

      expect(reconstructed.userId, original.userId);
      expect(reconstructed.status, original.status);
      expect(reconstructed.accountContext, original.accountContext);
      expect(reconstructed.pricePerMonthUsd, original.pricePerMonthUsd);
    });
  });
}
