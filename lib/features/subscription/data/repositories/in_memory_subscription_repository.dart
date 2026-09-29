import '../../../account/domain/models/account_context.dart';
import '../../../account/domain/models/subscription_access.dart';
import '../../../school/domain/models/school_role.dart';
import '../../domain/models/access_permission.dart';
import '../../domain/models/feature_access_key.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../domain/services/access_policy_engine.dart';

/// In-memory and offline store for subscriptions and trials.
class InMemorySubscriptionRepository implements SubscriptionRepository {
  final Map<String, SubscriptionAccess> _storage = {};
  final AccessPolicyEngine _policyEngine = const AccessPolicyEngine();

  @override
  Future<SubscriptionAccess> getSubscriptionStatus({
    required String userId,
    AccountContext context = AccountContext.individual,
    SchoolRole role = SchoolRole.student,
    String? schoolCode,
  }) async {
    final existing = _storage[userId];
    if (existing != null) {
      return existing;
    }

    // Auto-create initial trial
    return startTrial(
      userId: userId,
      context: context,
      role: role,
      schoolCode: schoolCode,
    );
  }

  @override
  Future<SubscriptionAccess> startTrial({
    required String userId,
    required AccountContext context,
    required SchoolRole role,
    String? schoolCode,
  }) async {
    final existing = _storage[userId];
    if (existing != null) {
      // Do not reset elapsed trial
      return existing;
    }

    final SubscriptionAccess record;
    if (context == AccountContext.school) {
      if (role == SchoolRole.teacher) {
        record = SubscriptionAccess(
          userId: userId,
          accountContext: AccountContext.school,
          status: SubscriptionStatus.schoolAccess,
          trialDurationDays: 0,
          pricePerMonthUsd: 0.0,
          schoolCode: schoolCode,
          schoolName: 'المدرسة المعتمدة',
        );
      } else {
        record = SubscriptionAccess.schoolStudentAccess(
          userId: userId,
          schoolCode: schoolCode ?? 'SCH-1001',
          schoolName: 'المدرسة الشريكة',
          trialDays: 10,
        );
      }
    } else {
      record = SubscriptionAccess.initialIndividualTrial(userId: userId);
    }

    _storage[userId] = record;
    return record;
  }

  @override
  Future<SubscriptionAccess> simulateCheckout({
    required String userId,
    String planId = 'individual_monthly',
    int periodDays = 30,
  }) async {
    final sub = SubscriptionAccess.activeIndividualSubscription(
      userId: userId,
      periodDays: periodDays,
    );
    _storage[userId] = sub;
    return sub;
  }

  @override
  Future<SubscriptionAccess> cancelSubscription({
    required String userId,
  }) async {
    final existing = await getSubscriptionStatus(userId: userId);
    final periodEnd =
        existing.currentPeriodEnd ??
        DateTime.now().add(const Duration(days: 30));

    final cancelled = SubscriptionAccess.cancelledIndividualSubscription(
      userId: userId,
      periodEnd: periodEnd,
    );
    _storage[userId] = cancelled;
    return cancelled;
  }

  @override
  Future<SubscriptionAccess> restoreSubscription({
    required String userId,
  }) async {
    return getSubscriptionStatus(userId: userId);
  }

  @override
  Future<AccessPermission> checkFeatureAccess({
    required String userId,
    required FeatureAccessKey feature,
  }) async {
    final sub = await getSubscriptionStatus(userId: userId);
    final role =
        sub.accountContext == AccountContext.school
            ? (sub.trialDurationDays == 0
                ? SchoolRole.teacher
                : SchoolRole.student)
            : SchoolRole.student;

    return _policyEngine.evaluateFeatureAccess(
      feature: feature,
      subscription: sub,
      accountContext: sub.accountContext,
      schoolRole: role,
    );
  }

  /// Testing helper to set manual access states.
  void setSubscriptionState(String userId, SubscriptionAccess state) {
    _storage[userId] = state;
  }
}
