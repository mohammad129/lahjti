import 'package:flutter/foundation.dart';

/// Semantic rationale explaining why access was granted or restricted.
enum AccessDecisionReason {
  /// Individual user is within their active 3-day trial period.
  individualActiveTrial,

  /// Individual user possesses an active paid subscription.
  individualActiveSubscription,

  /// Individual user cancelled their subscription, but the paid period remains active.
  individualCancelledGracePeriod,

  /// Individual 3-day trial has elapsed without an active subscription.
  individualExpiredTrial,

  /// Individual subscription has elapsed or expired.
  individualSubscriptionExpired,

  /// Individual payment renewal failed or is past due.
  individualPastDue,

  /// School student is enrolled in a verified, active school license.
  schoolStudentActive,

  /// School teacher is verified and authorized by their institution.
  schoolTeacherActive,

  /// School membership or institution license has been suspended.
  schoolMembershipSuspended,

  /// School membership or institutional school access has expired.
  schoolMembershipExpired,

  /// No valid user identity or unauthenticated session.
  unauthenticated;

  bool get isAllowed =>
      this == AccessDecisionReason.individualActiveTrial ||
      this == AccessDecisionReason.individualActiveSubscription ||
      this == AccessDecisionReason.individualCancelledGracePeriod ||
      this == AccessDecisionReason.schoolStudentActive ||
      this == AccessDecisionReason.schoolTeacherActive;
}

/// Action the user is prompted to take if access is restricted or in trial.
enum AccessRequiredAction {
  /// No action needed; full access granted.
  none,

  /// User should subscribe to the individual monthly plan ($10/month).
  subscribe,

  /// User should renew their expired or past-due subscription.
  renewSubscription,

  /// User should join a school or verify their school invitation code.
  joinSchool,

  /// User should contact their school administrator to resolve institutional suspension.
  contactSchoolAdmin;

  bool get isNone => this == AccessRequiredAction.none;
  bool get requiresSubscription =>
      this == AccessRequiredAction.subscribe ||
      this == AccessRequiredAction.renewSubscription;
}

/// Immutable evaluation result from the Access Decision Engine.
@immutable
class AccessDecision {
  final bool isAccessAllowed;
  final AccessDecisionReason reason;
  final AccessRequiredAction requiredAction;
  final Duration? remainingTrialDuration;
  final DateTime? currentPeriodEnd;
  final String descriptionAr;
  final String descriptionEn;

  const AccessDecision({
    required this.isAccessAllowed,
    required this.reason,
    this.requiredAction = AccessRequiredAction.none,
    this.remainingTrialDuration,
    this.currentPeriodEnd,
    required this.descriptionAr,
    required this.descriptionEn,
  });

  /// Days remaining in trial (rounded up), or 0 if trial ended/not applicable.
  int get remainingTrialDays {
    if (remainingTrialDuration == null) return 0;
    if (remainingTrialDuration!.isNegative) return 0;
    final inDays = remainingTrialDuration!.inDays;
    final remainingHours = remainingTrialDuration!.inHours % 24;
    return inDays + (remainingHours > 0 ? 1 : 0);
  }

  Map<String, dynamic> toJson() {
    return {
      'isAccessAllowed': isAccessAllowed,
      'reason': reason.name,
      'requiredAction': requiredAction.name,
      'remainingTrialDurationMs': remainingTrialDuration?.inMilliseconds,
      'currentPeriodEnd': currentPeriodEnd?.toIso8601String(),
      'descriptionAr': descriptionAr,
      'descriptionEn': descriptionEn,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccessDecision &&
          runtimeType == other.runtimeType &&
          isAccessAllowed == other.isAccessAllowed &&
          reason == other.reason &&
          requiredAction == other.requiredAction &&
          currentPeriodEnd == other.currentPeriodEnd;

  @override
  int get hashCode =>
      isAccessAllowed.hashCode ^
      reason.hashCode ^
      requiredAction.hashCode ^
      currentPeriodEnd.hashCode;

  @override
  String toString() =>
      'AccessDecision(allowed: $isAccessAllowed, reason: ${reason.name}, action: ${requiredAction.name})';
}
