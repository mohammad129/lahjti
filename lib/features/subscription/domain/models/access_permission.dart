import 'package:flutter/foundation.dart';
import '../../../account/domain/models/subscription_access.dart';

/// Immutable model describing the authorization outcome for a protected feature.
@immutable
class AccessPermission {
  final bool isAllowed;
  final String? denialReason;
  final String? requiredActionRoute;
  final SubscriptionAccess? subscription;

  const AccessPermission({
    required this.isAllowed,
    this.denialReason,
    this.requiredActionRoute,
    this.subscription,
  });

  /// Factory creating an unrestricted positive permission.
  factory AccessPermission.granted([SubscriptionAccess? subscription]) {
    return AccessPermission(isAllowed: true, subscription: subscription);
  }

  /// Factory creating a restricted negative permission with a reason and destination route.
  factory AccessPermission.denied({
    required String reason,
    required String requiredActionRoute,
    SubscriptionAccess? subscription,
  }) {
    return AccessPermission(
      isAllowed: false,
      denialReason: reason,
      requiredActionRoute: requiredActionRoute,
      subscription: subscription,
    );
  }

  bool get isDenied => !isAllowed;
}
