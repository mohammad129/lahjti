import 'package:flutter/foundation.dart';
import 'account_context.dart';

/// Status of the user's subscription access.
enum SubscriptionStatus {
  /// User is in free trial mode.
  trial,

  /// Active paid or verified subscription.
  active,

  /// Trial or subscription period has elapsed.
  expired,

  /// Subscription was cancelled by the user but may remain active until period end.
  cancelled,

  /// Payment renewal failed or past due grace period.
  pastDue,

  /// Payment or verification is pending.
  pending,
  paymentPending,

  /// Access provided and managed by an enrolled school.
  schoolAccess,

  /// Account or institutional membership suspended.
  suspended;

  bool get isTrial => this == SubscriptionStatus.trial;
  bool get isActive => this == SubscriptionStatus.active;
  bool get isExpired => this == SubscriptionStatus.expired;
  bool get isCancelled => this == SubscriptionStatus.cancelled;
  bool get isPastDue => this == SubscriptionStatus.pastDue;
  bool get isPending =>
      this == SubscriptionStatus.pending ||
      this == SubscriptionStatus.paymentPending;
  bool get isPaymentPending => isPending;
  bool get isSchoolAccess => this == SubscriptionStatus.schoolAccess;
  bool get isSuspended => this == SubscriptionStatus.suspended;

  static SubscriptionStatus fromString(String? value) {
    if (value == null) return SubscriptionStatus.trial;
    switch (value.toLowerCase().trim()) {
      case 'active':
        return SubscriptionStatus.active;
      case 'expired':
        return SubscriptionStatus.expired;
      case 'cancelled':
        return SubscriptionStatus.cancelled;
      case 'pastdue':
      case 'past_due':
        return SubscriptionStatus.pastDue;
      case 'pending':
      case 'paymentpending':
      case 'payment_pending':
        return SubscriptionStatus.paymentPending;
      case 'schoolaccess':
      case 'school_access':
        return SubscriptionStatus.schoolAccess;
      case 'suspended':
        return SubscriptionStatus.suspended;
      case 'trial':
      default:
        return SubscriptionStatus.trial;
    }
  }
}

/// Immutable model representing the user's access and trial state.
@immutable
class SubscriptionAccess {
  final String userId;
  final AccountContext accountContext;
  final SubscriptionStatus status;
  final DateTime? trialStartsAt;
  final DateTime? trialEndsAt;
  final DateTime? subscriptionExpiresAt;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final DateTime? cancelledAt;
  final int trialDurationDays;
  final double pricePerMonthUsd;
  final String? schoolCode;
  final String? schoolName;

  const SubscriptionAccess({
    required this.userId,
    this.accountContext = AccountContext.individual,
    this.status = SubscriptionStatus.trial,
    this.trialStartsAt,
    this.trialEndsAt,
    this.subscriptionExpiresAt,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.cancelledAt,
    this.trialDurationDays = 3,
    this.pricePerMonthUsd = 10.0,
    this.schoolCode,
    this.schoolName,
  });

  /// Factory creating initial individual 3-day trial access.
  factory SubscriptionAccess.initialIndividualTrial({
    required String userId,
    DateTime? now,
  }) {
    final start = now ?? DateTime.now();
    final end = start.add(const Duration(days: 3));
    return SubscriptionAccess(
      userId: userId,
      accountContext: AccountContext.individual,
      status: SubscriptionStatus.trial,
      trialStartsAt: start,
      trialEndsAt: end,
      trialDurationDays: 3,
      pricePerMonthUsd: 10.0,
    );
  }

  /// Factory creating an active individual paid subscription.
  factory SubscriptionAccess.activeIndividualSubscription({
    required String userId,
    DateTime? now,
    int periodDays = 30,
  }) {
    final start = now ?? DateTime.now();
    final end = start.add(Duration(days: periodDays));
    return SubscriptionAccess(
      userId: userId,
      accountContext: AccountContext.individual,
      status: SubscriptionStatus.active,
      currentPeriodStart: start,
      currentPeriodEnd: end,
      subscriptionExpiresAt: end,
      pricePerMonthUsd: 10.0,
    );
  }

  /// Factory creating a cancelled individual subscription that remains valid until period end.
  factory SubscriptionAccess.cancelledIndividualSubscription({
    required String userId,
    required DateTime periodEnd,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    return SubscriptionAccess(
      userId: userId,
      accountContext: AccountContext.individual,
      status: SubscriptionStatus.cancelled,
      currentPeriodEnd: periodEnd,
      subscriptionExpiresAt: periodEnd,
      cancelledAt: currentTime,
      pricePerMonthUsd: 10.0,
    );
  }

  /// Factory creating an expired individual trial state.
  factory SubscriptionAccess.expiredIndividualTrial({
    required String userId,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    final start = currentTime.subtract(const Duration(days: 4));
    final end = currentTime.subtract(const Duration(days: 1));
    return SubscriptionAccess(
      userId: userId,
      accountContext: AccountContext.individual,
      status: SubscriptionStatus.expired,
      trialStartsAt: start,
      trialEndsAt: end,
      trialDurationDays: 3,
      pricePerMonthUsd: 10.0,
    );
  }

  /// Factory creating school student 10-day trial or institutional school access.
  factory SubscriptionAccess.schoolStudentAccess({
    required String userId,
    required String schoolCode,
    required String schoolName,
    DateTime? now,
    int trialDays = 10,
  }) {
    final start = now ?? DateTime.now();
    final end = start.add(Duration(days: trialDays));
    return SubscriptionAccess(
      userId: userId,
      accountContext: AccountContext.school,
      status: SubscriptionStatus.schoolAccess,
      trialStartsAt: start,
      trialEndsAt: end,
      trialDurationDays: trialDays,
      pricePerMonthUsd: 0.0,
      schoolCode: schoolCode,
      schoolName: schoolName,
    );
  }

  /// Whether current access permits learning features.
  bool get isValidAccess {
    if (status == SubscriptionStatus.suspended) {
      return false;
    }

    if (status == SubscriptionStatus.schoolAccess) {
      return true; // Institutional school access always grants full access
    }

    if (status == SubscriptionStatus.active) {
      final expiry = currentPeriodEnd ?? subscriptionExpiresAt;
      if (expiry != null) {
        return DateTime.now().isBefore(expiry);
      }
      return true;
    }

    // Cancelled subscriptions remain valid until currentPeriodEnd / subscriptionExpiresAt
    if (status == SubscriptionStatus.cancelled) {
      final expiry = currentPeriodEnd ?? subscriptionExpiresAt;
      if (expiry != null) {
        return DateTime.now().isBefore(expiry);
      }
      return false;
    }

    if (status == SubscriptionStatus.trial) {
      if (trialEndsAt == null) return true;
      return DateTime.now().isBefore(trialEndsAt!);
    }

    return false;
  }

  /// Whether the trial has elapsed.
  bool get isTrialExpired =>
      status == SubscriptionStatus.expired ||
      (status == SubscriptionStatus.trial && !isValidAccess);

  /// Formatted price tag string.
  String get priceDisplay =>
      '${pricePerMonthUsd.toStringAsFixed(0)} USD / month';

  /// Days remaining in current trial or subscription window.
  int get daysRemaining {
    final targetDate = trialEndsAt ?? currentPeriodEnd ?? subscriptionExpiresAt;
    if (targetDate == null) return 0;
    final diff = targetDate.difference(DateTime.now());
    return diff.isNegative ? 0 : diff.inDays + (diff.inHours % 24 > 0 ? 1 : 0);
  }

  SubscriptionAccess copyWith({
    String? userId,
    AccountContext? accountContext,
    SubscriptionStatus? status,
    DateTime? trialStartsAt,
    DateTime? trialEndsAt,
    DateTime? subscriptionExpiresAt,
    DateTime? currentPeriodStart,
    DateTime? currentPeriodEnd,
    DateTime? cancelledAt,
    int? trialDurationDays,
    double? pricePerMonthUsd,
    String? schoolCode,
    String? schoolName,
  }) {
    return SubscriptionAccess(
      userId: userId ?? this.userId,
      accountContext: accountContext ?? this.accountContext,
      status: status ?? this.status,
      trialStartsAt: trialStartsAt ?? this.trialStartsAt,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
      subscriptionExpiresAt:
          subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      currentPeriodStart: currentPeriodStart ?? this.currentPeriodStart,
      currentPeriodEnd: currentPeriodEnd ?? this.currentPeriodEnd,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      trialDurationDays: trialDurationDays ?? this.trialDurationDays,
      pricePerMonthUsd: pricePerMonthUsd ?? this.pricePerMonthUsd,
      schoolCode: schoolCode ?? this.schoolCode,
      schoolName: schoolName ?? this.schoolName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'accountContext': accountContext.name,
      'status': status.name,
      'trialStartsAt': trialStartsAt?.toIso8601String(),
      'trialEndsAt': trialEndsAt?.toIso8601String(),
      'subscriptionExpiresAt': subscriptionExpiresAt?.toIso8601String(),
      'currentPeriodStart': currentPeriodStart?.toIso8601String(),
      'currentPeriodEnd': currentPeriodEnd?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'trialDurationDays': trialDurationDays,
      'pricePerMonthUsd': pricePerMonthUsd,
      'schoolCode': schoolCode,
      'schoolName': schoolName,
    };
  }

  factory SubscriptionAccess.fromJson(Map<String, dynamic> json) {
    return SubscriptionAccess(
      userId: json['userId'] as String? ?? 'anonymous',
      accountContext: AccountContext.fromString(
        json['accountContext'] as String?,
      ),
      status: SubscriptionStatus.fromString(json['status'] as String?),
      trialStartsAt:
          json['trialStartsAt'] != null
              ? DateTime.tryParse(json['trialStartsAt'] as String)
              : null,
      trialEndsAt:
          json['trialEndsAt'] != null
              ? DateTime.tryParse(json['trialEndsAt'] as String)
              : null,
      subscriptionExpiresAt:
          json['subscriptionExpiresAt'] != null
              ? DateTime.tryParse(json['subscriptionExpiresAt'] as String)
              : null,
      currentPeriodStart:
          json['currentPeriodStart'] != null
              ? DateTime.tryParse(json['currentPeriodStart'] as String)
              : null,
      currentPeriodEnd:
          json['currentPeriodEnd'] != null
              ? DateTime.tryParse(json['currentPeriodEnd'] as String)
              : null,
      cancelledAt:
          json['cancelledAt'] != null
              ? DateTime.tryParse(json['cancelledAt'] as String)
              : null,
      trialDurationDays: json['trialDurationDays'] as int? ?? 3,
      pricePerMonthUsd: (json['pricePerMonthUsd'] as num?)?.toDouble() ?? 10.0,
      schoolCode: json['schoolCode'] as String?,
      schoolName: json['schoolName'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionAccess &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          accountContext == other.accountContext &&
          status == other.status &&
          trialStartsAt == other.trialStartsAt &&
          trialEndsAt == other.trialEndsAt &&
          subscriptionExpiresAt == other.subscriptionExpiresAt &&
          currentPeriodStart == other.currentPeriodStart &&
          currentPeriodEnd == other.currentPeriodEnd &&
          cancelledAt == other.cancelledAt &&
          trialDurationDays == other.trialDurationDays &&
          pricePerMonthUsd == other.pricePerMonthUsd &&
          schoolCode == other.schoolCode &&
          schoolName == other.schoolName;

  @override
  int get hashCode =>
      userId.hashCode ^
      accountContext.hashCode ^
      status.hashCode ^
      trialStartsAt.hashCode ^
      trialEndsAt.hashCode ^
      subscriptionExpiresAt.hashCode ^
      currentPeriodStart.hashCode ^
      currentPeriodEnd.hashCode ^
      cancelledAt.hashCode ^
      trialDurationDays.hashCode ^
      pricePerMonthUsd.hashCode ^
      schoolCode.hashCode ^
      schoolName.hashCode;
}
