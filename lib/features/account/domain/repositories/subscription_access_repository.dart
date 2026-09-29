import '../models/account_context.dart';
import '../models/subscription_access.dart';

/// Repository interface for subscription and trial access queries.
abstract class SubscriptionAccessRepository {
  /// Fetches current access state for a given user.
  Future<SubscriptionAccess> getAccessState({
    required String userId,
    AccountContext? context,
  });

  /// Starts or resets an individual 3-day free trial.
  Future<SubscriptionAccess> startIndividualTrial(String userId);

  /// Starts or binds school student 10-day access.
  Future<SubscriptionAccess> startSchoolStudentAccess({
    required String userId,
    required String schoolCode,
    required String schoolName,
  });

  /// Upgrades user to active paid subscription ($10/month) in pilot/sandbox mode.
  Future<SubscriptionAccess> activatePaidSubscription(String userId);

  /// Refreshes/validates access expiration for user.
  Future<SubscriptionAccess> checkStatus(String userId);
}
