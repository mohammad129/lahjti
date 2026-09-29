import '../../../account/domain/models/account_context.dart';
import '../../../account/domain/models/subscription_access.dart';
import '../../../school/domain/models/school_role.dart';
import '../models/access_permission.dart';
import '../models/feature_access_key.dart';

/// Pure domain service enforcing strict multi-tenant access control and entitlement policies.
class AccessPolicyEngine {
  const AccessPolicyEngine();

  /// Evaluates whether the user is permitted to access the given feature.
  AccessPermission evaluateFeatureAccess({
    required FeatureAccessKey feature,
    required SubscriptionAccess subscription,
    required AccountContext accountContext,
    SchoolRole? schoolRole,
    DateTime? currentTime,
  }) {
    final now = currentTime ?? DateTime.now();

    // 1. Account Suspensions
    if (subscription.status == SubscriptionStatus.suspended) {
      return AccessPermission.denied(
        reason: 'الحساب موقوف من قبل إدارة النظام / Account suspended',
        requiredActionRoute: '/welcome',
        subscription: subscription,
      );
    }

    // 2. Teacher Dashboard & Classroom Oversight Features
    if (feature == FeatureAccessKey.teacherDashboard ||
        feature == FeatureAccessKey.schoolClassrooms) {
      if (accountContext.isSchool && schoolRole == SchoolRole.teacher) {
        return AccessPermission.granted(subscription);
      }
      return AccessPermission.denied(
        reason:
            'خاص بالمعلمين المعتمدين والمؤسسات التعليمية / Teacher credentials required',
        requiredActionRoute: '/welcome',
        subscription: subscription,
      );
    }

    // 3. School Student Daily Tasks
    if (feature == FeatureAccessKey.schoolDailyTasks) {
      if (!accountContext.isSchool) {
        return AccessPermission.denied(
          reason:
              'المهام اليومية المدرسية متاحة لطلاب المدارس فقط / School account required',
          requiredActionRoute: '/welcome',
          subscription: subscription,
        );
      }

      if (schoolRole == SchoolRole.student) {
        if (_isAccessValid(subscription, now)) {
          return AccessPermission.granted(subscription);
        }
        return AccessPermission.denied(
          reason:
              'انتهت فترة تجربة الطالب المدرسي (10 أيام). يرجى التحقق من رخصة مدرستك / School trial elapsed',
          requiredActionRoute: '/subscription/access',
          subscription: subscription,
        );
      }

      // Teachers have inspection access
      if (schoolRole == SchoolRole.teacher) {
        return AccessPermission.granted(subscription);
      }
    }

    // 4. Core Educational & Learning Features (Lessons, Vocab, Games, AI Tutor, Progress)
    if (accountContext.isIndividual) {
      if (_isAccessValid(subscription, now)) {
        return AccessPermission.granted(subscription);
      }
      return AccessPermission.denied(
        reason:
            'انتهت الفترة التجريبية (3 أيام). يرجى الاشتراك بمبلغ 10 دولار / شهرياً للمتابعة / Individual trial elapsed',
        requiredActionRoute: '/subscription/access',
        subscription: subscription,
      );
    }

    if (accountContext.isSchool) {
      if (schoolRole == SchoolRole.teacher) {
        return AccessPermission.granted(subscription);
      }

      if (schoolRole == SchoolRole.student) {
        if (_isAccessValid(subscription, now)) {
          return AccessPermission.granted(subscription);
        }
        return AccessPermission.denied(
          reason:
              'انتهت فترة تجربة الطالب المدرسي (10 أيام). يلزم تفعيل رخصة المدرسة / School license required',
          requiredActionRoute: '/subscription/access',
          subscription: subscription,
        );
      }
    }

    // Default fallback
    if (_isAccessValid(subscription, now)) {
      return AccessPermission.granted(subscription);
    }

    return AccessPermission.denied(
      reason: 'يلزم اشتراك نشط للمتابعة / Active subscription required',
      requiredActionRoute: '/subscription/access',
      subscription: subscription,
    );
  }

  /// Internal authoritative evaluation of whether subscription is currently valid.
  bool _isAccessValid(SubscriptionAccess sub, DateTime now) {
    if (sub.status == SubscriptionStatus.schoolAccess) {
      return true; // Institutional school licenses are fully active
    }

    if (sub.status == SubscriptionStatus.active) {
      final expiry = sub.currentPeriodEnd ?? sub.subscriptionExpiresAt;
      if (expiry != null) {
        return now.isBefore(expiry);
      }
      return true;
    }

    if (sub.status == SubscriptionStatus.cancelled) {
      final expiry = sub.currentPeriodEnd ?? sub.subscriptionExpiresAt;
      if (expiry != null) {
        return now.isBefore(expiry);
      }
      return false;
    }

    if (sub.status == SubscriptionStatus.trial) {
      if (sub.trialEndsAt == null) return true;
      return now.isBefore(sub.trialEndsAt!);
    }

    return false;
  }
}
