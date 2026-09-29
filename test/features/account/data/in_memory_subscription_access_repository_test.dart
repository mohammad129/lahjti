import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/account/data/repositories/in_memory_subscription_access_repository.dart';
import 'package:lahjti/features/account/domain/models/account_context.dart';
import 'package:lahjti/features/account/domain/models/subscription_access.dart';

void main() {
  group('InMemorySubscriptionAccessRepository Tests', () {
    late InMemorySubscriptionAccessRepository repository;

    setUp(() {
      repository = InMemorySubscriptionAccessRepository();
    });

    test(
      '1. Creates and retrieves individual 3-day trial access by default',
      () async {
        final access = await repository.getAccessState(userId: 'user_ind_01');

        expect(access.accountContext, AccountContext.individual);
        expect(access.status, SubscriptionStatus.trial);
        expect(access.isValidAccess, isTrue);
        expect(access.daysRemaining, inInclusiveRange(2, 3));
      },
    );

    test('2. Creates school student access with 10-day trial', () async {
      final schoolAccess = await repository.startSchoolStudentAccess(
        userId: 'user_school_01',
        schoolCode: 'SCH-1001',
        schoolName: 'Amman Academy',
      );

      expect(schoolAccess.accountContext, AccountContext.school);
      expect(schoolAccess.status, SubscriptionStatus.schoolAccess);
      expect(schoolAccess.schoolCode, 'SCH-1001');
      expect(schoolAccess.schoolName, 'Amman Academy');
      expect(schoolAccess.daysRemaining, inInclusiveRange(9, 10));

      final retrieved = await repository.getAccessState(
        userId: 'user_school_01',
      );
      expect(retrieved.status, SubscriptionStatus.schoolAccess);
      expect(retrieved.schoolCode, 'SCH-1001');
    });

    test(
      '3. Saves and updates subscription access without real payment gateway',
      () async {
        final updated = SubscriptionAccess(
          userId: 'user_custom',
          accountContext: AccountContext.individual,
          status: SubscriptionStatus.active,
          subscriptionExpiresAt: DateTime.now().add(const Duration(days: 30)),
        );

        repository.setAccessOverride(updated);
        final retrieved = await repository.getAccessState(
          userId: 'user_custom',
        );

        expect(retrieved.userId, 'user_custom');
        expect(retrieved.status, SubscriptionStatus.active);
        expect(retrieved.isValidAccess, isTrue);
      },
    );

    test('4. checkStatus flags expired access correctly', () async {
      final expired = SubscriptionAccess(
        userId: 'user_expired',
        accountContext: AccountContext.individual,
        status: SubscriptionStatus.trial,
        trialStartsAt: DateTime.now().subtract(const Duration(days: 10)),
        trialEndsAt: DateTime.now().subtract(const Duration(days: 5)),
      );

      repository.setAccessOverride(expired);
      final checked = await repository.checkStatus('user_expired');

      expect(checked.status, SubscriptionStatus.expired);
      expect(checked.isValidAccess, isFalse);
    });
  });
}
