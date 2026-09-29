import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../account/domain/models/account_context.dart';
import '../../../account/domain/models/subscription_access.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../../school/domain/models/school_role.dart';
import '../../data/repositories/remote_subscription_repository.dart';
import '../../domain/models/access_permission.dart';
import '../../domain/models/feature_access_key.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../domain/services/access_policy_engine.dart';

/// Provider for SubscriptionRepository instance.
final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RemoteSubscriptionRepository(apiClient);
});

/// Provider for the pure AccessPolicyEngine.
final accessPolicyEngineProvider = Provider<AccessPolicyEngine>(
  (ref) => const AccessPolicyEngine(),
);

/// Notifier managing active subscription lifecycle and user actions.
class SubscriptionNotifier
    extends StateNotifier<AsyncValue<SubscriptionAccess>> {
  final SubscriptionRepository _repository;
  final Ref _ref;

  SubscriptionNotifier(this._repository, this._ref)
    : super(const AsyncValue.loading()) {
    refresh();
  }

  String get _currentUserId {
    final authState = _ref.read(authNotifierProvider);
    return authState.user?.id ?? 'usr_local_learner';
  }

  AccountContext get _currentContext {
    final onboardingData = _ref.read(onboardingProvider.select((s) => s.data));
    return onboardingData.accountContext;
  }

  SchoolRole get _currentRole {
    final onboardingData = _ref.read(onboardingProvider.select((s) => s.data));
    return onboardingData.schoolRole ?? SchoolRole.student;
  }

  String? get _currentSchoolCode {
    final onboardingData = _ref.read(onboardingProvider.select((s) => s.data));
    return onboardingData.schoolCode;
  }

  /// Refreshes authoritative subscription from server.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final sub = await _repository.getSubscriptionStatus(
        userId: _currentUserId,
        context: _currentContext,
        role: _currentRole,
        schoolCode: _currentSchoolCode,
      );
      state = AsyncValue.data(sub);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  /// Starts or ensures a trial is active.
  Future<void> startTrial() async {
    state = const AsyncValue.loading();
    try {
      final sub = await _repository.startTrial(
        userId: _currentUserId,
        context: _currentContext,
        role: _currentRole,
        schoolCode: _currentSchoolCode,
      );
      state = AsyncValue.data(sub);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  /// Simulates upgrading to individual active $10/month subscription (Demo mode - no card charged).
  Future<void> simulateCheckout({
    String planId = 'individual_monthly',
    int periodDays = 30,
  }) async {
    state = const AsyncValue.loading();
    try {
      final sub = await _repository.simulateCheckout(
        userId: _currentUserId,
        planId: planId,
        periodDays: periodDays,
      );
      state = AsyncValue.data(sub);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  /// Cancels individual subscription. Remains active until period end.
  Future<void> cancelSubscription() async {
    state = const AsyncValue.loading();
    try {
      final sub = await _repository.cancelSubscription(userId: _currentUserId);
      state = AsyncValue.data(sub);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  /// Restores subscriptions.
  Future<void> restoreSubscription() async {
    state = const AsyncValue.loading();
    try {
      final sub = await _repository.restoreSubscription(userId: _currentUserId);
      state = AsyncValue.data(sub);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }
}

/// Provider managing active user subscription state.
final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, AsyncValue<SubscriptionAccess>>(
      (ref) {
        final repo = ref.watch(subscriptionRepositoryProvider);
        return SubscriptionNotifier(repo, ref);
      },
    );

/// Provider checking whether current user subscription is actively valid.
final isSubscriptionValidProvider = Provider<bool>((ref) {
  final subAsync = ref.watch(subscriptionProvider);
  return subAsync.maybeWhen(
    data: (sub) => sub.isValidAccess,
    orElse: () => true, // optimistic fallback to prevent UI blocking
  );
});

/// Provider checking whether user is in an active individual trial.
final isIndividualTrialActiveProvider = Provider<bool>((ref) {
  final subAsync = ref.watch(subscriptionProvider);
  return subAsync.maybeWhen(
    data:
        (sub) =>
            sub.accountContext == AccountContext.individual &&
            sub.status == SubscriptionStatus.trial &&
            sub.isValidAccess,
    orElse: () => false,
  );
});

/// Provider checking whether school student is in their 10-day trial.
final isSchoolStudentTrialActiveProvider = Provider<bool>((ref) {
  final subAsync = ref.watch(subscriptionProvider);
  return subAsync.maybeWhen(
    data:
        (sub) =>
            sub.accountContext == AccountContext.school &&
            sub.status == SubscriptionStatus.trial &&
            sub.isValidAccess,
    orElse: () => false,
  );
});

/// Provider family evaluating feature-level permissions using AccessPolicyEngine.
final featureAccessProvider =
    Provider.family<AccessPermission, FeatureAccessKey>((ref, feature) {
      final subAsync = ref.watch(subscriptionProvider);
      final engine = ref.watch(accessPolicyEngineProvider);
      final onboardingData = ref.watch(
        onboardingProvider.select((s) => s.data),
      );

      return subAsync.maybeWhen(
        data:
            (sub) => engine.evaluateFeatureAccess(
              feature: feature,
              subscription: sub,
              accountContext: onboardingData.accountContext,
              schoolRole: onboardingData.schoolRole,
            ),
        orElse: () => AccessPermission.granted(),
      );
    });
