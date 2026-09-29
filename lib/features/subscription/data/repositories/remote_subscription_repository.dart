import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../account/domain/models/account_context.dart';
import '../../../account/domain/models/subscription_access.dart';
import '../../../school/domain/models/school_role.dart';
import '../../domain/models/access_permission.dart';
import '../../domain/models/feature_access_key.dart';
import '../../domain/repositories/subscription_repository.dart';
import 'in_memory_subscription_repository.dart';

/// Production-ready Remote Subscription Repository connecting to Express backend endpoints.
/// Seamlessly falls back to local in-memory storage when offline or in standalone test harnesses.
class RemoteSubscriptionRepository implements SubscriptionRepository {
  final ApiClient _apiClient;
  final InMemorySubscriptionRepository _fallbackStore;

  RemoteSubscriptionRepository(
    this._apiClient, [
    InMemorySubscriptionRepository? fallbackStore,
  ]) : _fallbackStore = fallbackStore ?? InMemorySubscriptionRepository();

  Map<String, dynamic> _extractMap(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      return responseData;
    }
    if (responseData is String) {
      try {
        final decoded = jsonDecode(responseData);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (e) {
        debugPrint('⚠️ JSON Decode Error in RemoteSubscriptionRepository: $e');
      }
    }
    return <String, dynamic>{};
  }

  SubscriptionAccess _parseSubscription(
    Map<String, dynamic> json,
    String defaultUserId,
  ) {
    final data =
        json['data'] is Map<String, dynamic>
            ? json['data'] as Map<String, dynamic>
            : json;

    final userId = data['userId'] as String? ?? defaultUserId;
    final contextStr = data['accountContext'] as String? ?? 'individual';
    final statusStr = data['status'] as String? ?? 'trial';
    final price =
        (data['priceUsd'] as num?)?.toDouble() ??
        (contextStr == 'school' ? 0.0 : 10.0);
    final trialDays =
        (data['trialDurationDays'] as num?)?.toInt() ??
        (contextStr == 'school' ? 10 : 3);

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    return SubscriptionAccess(
      userId: userId,
      accountContext: AccountContext.fromString(contextStr),
      status: SubscriptionStatus.fromString(statusStr),
      pricePerMonthUsd: price,
      trialDurationDays: trialDays,
      trialStartsAt: parseDate(data['trialStartsAt']),
      trialEndsAt: parseDate(data['trialEndsAt']),
      currentPeriodStart: parseDate(data['currentPeriodStart']),
      currentPeriodEnd: parseDate(data['currentPeriodEnd']),
      subscriptionExpiresAt: parseDate(data['subscriptionExpiresAt']),
      cancelledAt: parseDate(data['cancelledAt']),
      schoolCode: data['schoolCode'] as String?,
      schoolName: data['schoolName'] as String?,
    );
  }

  @override
  Future<SubscriptionAccess> getSubscriptionStatus({
    required String userId,
    AccountContext context = AccountContext.individual,
    SchoolRole role = SchoolRole.student,
    String? schoolCode,
  }) async {
    try {
      final response = await _apiClient.get(
        '/subscription/status',
        queryParameters: {
          'context': context.name,
          'role': role.name,
          if (schoolCode != null) 'schoolCode': schoolCode,
        },
      );

      final map = _extractMap(response.data);
      final parsed = _parseSubscription(map, userId);
      _fallbackStore.setSubscriptionState(userId, parsed);
      return parsed;
    } catch (err) {
      debugPrint('ℹ️ Fallback to in-memory subscription status: $err');
      return _fallbackStore.getSubscriptionStatus(
        userId: userId,
        context: context,
        role: role,
        schoolCode: schoolCode,
      );
    }
  }

  @override
  Future<SubscriptionAccess> startTrial({
    required String userId,
    required AccountContext context,
    required SchoolRole role,
    String? schoolCode,
  }) async {
    try {
      final response = await _apiClient.post(
        '/subscription/trial/start',
        data: {
          'accountContext': context.name,
          'role': role.name,
          if (schoolCode != null) 'schoolCode': schoolCode,
        },
      );

      final map = _extractMap(response.data);
      final parsed = _parseSubscription(map, userId);
      _fallbackStore.setSubscriptionState(userId, parsed);
      return parsed;
    } catch (err) {
      debugPrint('ℹ️ Fallback to in-memory start trial: $err');
      return _fallbackStore.startTrial(
        userId: userId,
        context: context,
        role: role,
        schoolCode: schoolCode,
      );
    }
  }

  @override
  Future<SubscriptionAccess> simulateCheckout({
    required String userId,
    String planId = 'individual_monthly',
    int periodDays = 30,
  }) async {
    try {
      final response = await _apiClient.post(
        '/subscription/simulate-checkout',
        data: {'planId': planId, 'periodDays': periodDays},
      );

      final map = _extractMap(response.data);
      final parsed = _parseSubscription(map, userId);
      _fallbackStore.setSubscriptionState(userId, parsed);
      return parsed;
    } catch (err) {
      debugPrint('ℹ️ Fallback to in-memory simulate checkout: $err');
      return _fallbackStore.simulateCheckout(
        userId: userId,
        planId: planId,
        periodDays: periodDays,
      );
    }
  }

  @override
  Future<SubscriptionAccess> cancelSubscription({
    required String userId,
  }) async {
    try {
      final response = await _apiClient.post('/subscription/cancel');
      final map = _extractMap(response.data);
      final parsed = _parseSubscription(map, userId);
      _fallbackStore.setSubscriptionState(userId, parsed);
      return parsed;
    } catch (err) {
      debugPrint('ℹ️ Fallback to in-memory cancel subscription: $err');
      return _fallbackStore.cancelSubscription(userId: userId);
    }
  }

  @override
  Future<SubscriptionAccess> restoreSubscription({
    required String userId,
  }) async {
    try {
      final response = await _apiClient.post('/subscription/restore');
      final map = _extractMap(response.data);
      final parsed = _parseSubscription(map, userId);
      _fallbackStore.setSubscriptionState(userId, parsed);
      return parsed;
    } catch (err) {
      debugPrint('ℹ️ Fallback to in-memory restore subscription: $err');
      return _fallbackStore.restoreSubscription(userId: userId);
    }
  }

  @override
  Future<AccessPermission> checkFeatureAccess({
    required String userId,
    required FeatureAccessKey feature,
  }) async {
    try {
      final response = await _apiClient.get(
        '/subscription/entitlements',
        queryParameters: {'feature': feature.name},
      );

      final map = _extractMap(response.data);
      final data =
          map['data'] is Map<String, dynamic>
              ? map['data'] as Map<String, dynamic>
              : map;

      final isAllowed = data['isAllowed'] as bool? ?? false;
      final reason = data['reason'] as String?;
      final requiredAction = data['requiredAction'] as String?;
      final sub =
          data['subscription'] != null
              ? _parseSubscription(data['subscription'], userId)
              : null;

      if (isAllowed) {
        return AccessPermission.granted(sub);
      }
      return AccessPermission.denied(
        reason: reason ?? 'Access restricted',
        requiredActionRoute: requiredAction ?? '/subscription/access',
        subscription: sub,
      );
    } catch (err) {
      debugPrint('ℹ️ Fallback to in-memory feature access evaluation: $err');
      return _fallbackStore.checkFeatureAccess(
        userId: userId,
        feature: feature,
      );
    }
  }
}
