import '../../domain/models/account_context.dart';
import '../../domain/models/subscription_access.dart';
import '../../domain/repositories/subscription_access_repository.dart';

/// In-memory implementation of SubscriptionAccessRepository.
class InMemorySubscriptionAccessRepository
    implements SubscriptionAccessRepository {
  final Map<String, SubscriptionAccess> _storage = {};

  @override
  Future<SubscriptionAccess> getAccessState({
    required String userId,
    AccountContext? context,
  }) async {
    final existing = _storage[userId];
    if (existing != null) {
      return existing;
    }

    // Default to active 3-day individual trial
    final initial = SubscriptionAccess.initialIndividualTrial(userId: userId);
    _storage[userId] = initial;
    return initial;
  }

  @override
  Future<SubscriptionAccess> startIndividualTrial(String userId) async {
    final trial = SubscriptionAccess.initialIndividualTrial(userId: userId);
    _storage[userId] = trial;
    return trial;
  }

  @override
  Future<SubscriptionAccess> startSchoolStudentAccess({
    required String userId,
    required String schoolCode,
    required String schoolName,
  }) async {
    final access = SubscriptionAccess.schoolStudentAccess(
      userId: userId,
      schoolCode: schoolCode,
      schoolName: schoolName,
    );
    _storage[userId] = access;
    return access;
  }

  @override
  Future<SubscriptionAccess> activatePaidSubscription(String userId) async {
    final paid = SubscriptionAccess.activeIndividualSubscription(
      userId: userId,
      now: DateTime.now(),
    );
    _storage[userId] = paid;
    return paid;
  }

  @override
  Future<SubscriptionAccess> checkStatus(String userId) async {
    final current = await getAccessState(userId: userId);
    if (!current.isValidAccess &&
        current.status != SubscriptionStatus.expired) {
      final updated = current.copyWith(status: SubscriptionStatus.expired);
      _storage[userId] = updated;
      return updated;
    }
    return current;
  }

  /// Testing helper to simulate manual access overrides.
  void setAccessOverride(SubscriptionAccess access) {
    _storage[access.userId] = access;
  }
}
