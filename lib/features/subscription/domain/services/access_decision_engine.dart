import '../../../account/domain/models/account_context.dart';
import '../../../account/domain/models/school_membership.dart';
import '../../../account/domain/models/subscription_access.dart';
import '../../../school/domain/models/school_role.dart';
import '../models/access_decision.dart';

/// Pure deterministic decision engine governing learning feature access in Lahjti.
///
/// Designed to run both on client-side state and be mirrored identically on backend services.
class AccessDecisionEngine {
  const AccessDecisionEngine();

  /// Evaluates entitlement and produces an immutable [AccessDecision].
  AccessDecision evaluate({
    required AccountContext accountContext,
    SubscriptionAccess? subscriptionAccess,
    SchoolMembership? schoolMembership,
    DateTime? currentTime,
  }) {
    final now = currentTime ?? DateTime.now();

    // =========================================================================
    // 1. SCHOOL CONTEXT EVALUATION
    // =========================================================================
    if (accountContext.isSchool) {
      if (schoolMembership == null) {
        return const AccessDecision(
          isAccessAllowed: false,
          reason: AccessDecisionReason.unauthenticated,
          requiredAction: AccessRequiredAction.joinSchool,
          descriptionAr:
              'يرجى إدخال رمز المدرسة المعتمد للوصول إلى الحساب المدرسي.',
          descriptionEn:
              'Please enter a valid school code to access institutional learning.',
        );
      }

      if (!schoolMembership.isVerified) {
        return const AccessDecision(
          isAccessAllowed: false,
          reason: AccessDecisionReason.schoolMembershipSuspended,
          requiredAction: AccessRequiredAction.contactSchoolAdmin,
          descriptionAr:
              'عضوية المدرسة غير مفعلة أو تم تعليقها من قبل إدارة المدرسة.',
          descriptionEn:
              'School membership is unverified or suspended by your administrator.',
        );
      }

      if (subscriptionAccess?.status == SubscriptionStatus.suspended) {
        return const AccessDecision(
          isAccessAllowed: false,
          reason: AccessDecisionReason.schoolMembershipSuspended,
          requiredAction: AccessRequiredAction.contactSchoolAdmin,
          descriptionAr:
              'تم تعليق ترخيص المدرسة مؤقتاً. يرجى مراجعة إدارة المدرسة.',
          descriptionEn:
              'School institutional license is suspended. Please contact school administration.',
        );
      }

      if (schoolMembership.role == SchoolRole.teacher) {
        return const AccessDecision(
          isAccessAllowed: true,
          reason: AccessDecisionReason.schoolTeacherActive,
          requiredAction: AccessRequiredAction.none,
          descriptionAr: 'وصول معلم معتمد ونشط عبر ترخيص المؤسسة التعليمية.',
          descriptionEn:
              'Verified teacher access granted via institutional license.',
        );
      }

      // School Student
      if (schoolMembership.trialDaysRemaining <= 0 &&
          subscriptionAccess != null &&
          !subscriptionAccess.isValidAccess) {
        return const AccessDecision(
          isAccessAllowed: false,
          reason: AccessDecisionReason.schoolMembershipExpired,
          requiredAction: AccessRequiredAction.contactSchoolAdmin,
          descriptionAr: 'انتهت فترة الوصول المدرسي المخصصة لصفك الدراسي.',
          descriptionEn:
              'Educational school trial period has expired. Contact your teacher.',
        );
      }

      final remainingTrial = subscriptionAccess?.trialEndsAt?.difference(now);

      return AccessDecision(
        isAccessAllowed: true,
        reason: AccessDecisionReason.schoolStudentActive,
        requiredAction: AccessRequiredAction.none,
        remainingTrialDuration:
            remainingTrial != null && !remainingTrial.isNegative
                ? remainingTrial
                : null,
        descriptionAr: 'وصول طالب معتمد عبر ترخيص المدرسة وبدون أي رسوم فردية.',
        descriptionEn:
            'Active school student access granted via institutional license.',
      );
    }

    // =========================================================================
    // 2. INDIVIDUAL LEARNER CONTEXT EVALUATION
    // =========================================================================
    if (subscriptionAccess == null) {
      // Default fallback: fresh 3-day trial
      final defaultEnd = now.add(const Duration(days: 3));
      return AccessDecision(
        isAccessAllowed: true,
        reason: AccessDecisionReason.individualActiveTrial,
        requiredAction: AccessRequiredAction.none,
        remainingTrialDuration: const Duration(days: 3),
        currentPeriodEnd: defaultEnd,
        descriptionAr: 'فترة تجريبية مجانية نشطة لمدة 3 أيام للتعلم الفردي.',
        descriptionEn: 'Active 3-day free trial for individual learning.',
      );
    }

    // A) Active Paid Subscription
    if (subscriptionAccess.status == SubscriptionStatus.active) {
      final periodEnd =
          subscriptionAccess.currentPeriodEnd ??
          subscriptionAccess.subscriptionExpiresAt;
      if (periodEnd != null && now.isAfter(periodEnd)) {
        return const AccessDecision(
          isAccessAllowed: false,
          reason: AccessDecisionReason.individualSubscriptionExpired,
          requiredAction: AccessRequiredAction.renewSubscription,
          descriptionAr:
              'انتهت فترة اشتراكك الحالي. يرجى تجديد الاشتراك للمتابعة.',
          descriptionEn:
              'Your active subscription period has elapsed. Please renew to continue.',
        );
      }

      return AccessDecision(
        isAccessAllowed: true,
        reason: AccessDecisionReason.individualActiveSubscription,
        requiredAction: AccessRequiredAction.none,
        currentPeriodEnd: periodEnd,
        descriptionAr: 'اشتراك فردي نشط في منصة لهجتي (10 دولارات شهرياً).',
        descriptionEn: r'Active Lahjti Individual Subscription ($10/month).',
      );
    }

    // B) Cancelled Subscription (Grace period until current period ends)
    if (subscriptionAccess.status == SubscriptionStatus.cancelled) {
      final periodEnd =
          subscriptionAccess.currentPeriodEnd ??
          subscriptionAccess.subscriptionExpiresAt;
      if (periodEnd != null && now.isBefore(periodEnd)) {
        return AccessDecision(
          isAccessAllowed: true,
          reason: AccessDecisionReason.individualCancelledGracePeriod,
          requiredAction: AccessRequiredAction.none,
          currentPeriodEnd: periodEnd,
          descriptionAr:
              'تم إلغاء الاشتراك، لكن الوصول يبقى متاحاً حتى نهاية الفترة المدفوعة.',
          descriptionEn:
              'Subscription cancelled. Access remains active until end of billing cycle.',
        );
      }

      return const AccessDecision(
        isAccessAllowed: false,
        reason: AccessDecisionReason.individualSubscriptionExpired,
        requiredAction: AccessRequiredAction.subscribe,
        descriptionAr:
            'انتهت الفترة المدفوعة لاشتراكك الملغي. اشترك مجدداً للمتابعة.',
        descriptionEn:
            'Your cancelled subscription period has ended. Subscribe to regain access.',
      );
    }

    // C) Past Due / Payment Failed
    if (subscriptionAccess.status == SubscriptionStatus.pastDue) {
      return const AccessDecision(
        isAccessAllowed: false,
        reason: AccessDecisionReason.individualPastDue,
        requiredAction: AccessRequiredAction.renewSubscription,
        descriptionAr:
            'تعذر تجديد الاشتراك. يرجى تحديث وسيلة الدفع لتفعيل الوصول.',
        descriptionEn:
            'Subscription renewal failed. Please update payment method to continue.',
      );
    }

    // D) Active Trial vs Expired Trial
    if (subscriptionAccess.status == SubscriptionStatus.trial) {
      if (subscriptionAccess.trialEndsAt == null) {
        return const AccessDecision(
          isAccessAllowed: true,
          reason: AccessDecisionReason.individualActiveTrial,
          requiredAction: AccessRequiredAction.none,
          remainingTrialDuration: Duration(days: 3),
          descriptionAr: 'فترة تجريبية مجانية نشطة.',
          descriptionEn: 'Free trial active.',
        );
      }

      if (now.isBefore(subscriptionAccess.trialEndsAt!)) {
        final remaining = subscriptionAccess.trialEndsAt!.difference(now);
        return AccessDecision(
          isAccessAllowed: true,
          reason: AccessDecisionReason.individualActiveTrial,
          requiredAction: AccessRequiredAction.none,
          remainingTrialDuration: remaining,
          currentPeriodEnd: subscriptionAccess.trialEndsAt,
          descriptionAr:
              'فترة تجريبية مجانية نشطة (متبقي ${remaining.inDays + 1} أيام).',
          descriptionEn:
              'Free trial active (${remaining.inDays + 1} days remaining).',
        );
      }
    }

    // E) Expired Trial / Expired State
    return const AccessDecision(
      isAccessAllowed: false,
      reason: AccessDecisionReason.individualExpiredTrial,
      requiredAction: AccessRequiredAction.subscribe,
      descriptionAr:
          'انتهت الفترة التجريبية المجانية (3 أيام). يلزم الاشتراك للمتابعة بـ 10 دولارات شهرياً.',
      descriptionEn:
          r'Your 3-day free trial has expired. Subscribe for $10/month to continue.',
    );
  }
}
