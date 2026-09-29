import '../../../account/domain/models/account_context.dart';
import '../../../account/domain/models/subscription_access.dart';
import '../../../school/domain/models/school_role.dart';
import '../models/access_permission.dart';
import '../models/feature_access_key.dart';

/// Comprehensive contract for monetization, trial lifecycle, and entitlement evaluation.
abstract class SubscriptionRepository {
  /// Fetches authoritative subscription state from server/store.
  Future<SubscriptionAccess> getSubscriptionStatus({
    required String userId,
    AccountContext context = AccountContext.individual,
    SchoolRole role = SchoolRole.student,
    String? schoolCode,
  });

  /// Starts a free trial (3 days for Individual, 10 days for School Student).
  Future<SubscriptionAccess> startTrial({
    required String userId,
    required AccountContext context,
    required SchoolRole role,
    String? schoolCode,
  });

  /// Simulates checkout / subscription upgrade to $10/month plan (Demo mode - no card charged).
  Future<SubscriptionAccess> simulateCheckout({
    required String userId,
    String planId = 'individual_monthly',
    int periodDays = 30,
  });

  /// Cancels an active individual subscription. Remains valid until current period end.
  Future<SubscriptionAccess> cancelSubscription({required String userId});

  /// Restores server-side subscriptions.
  Future<SubscriptionAccess> restoreSubscription({required String userId});

  /// Evaluates server-authoritative entitlement for a feature.
  Future<AccessPermission> checkFeatureAccess({
    required String userId,
    required FeatureAccessKey feature,
  });
}
