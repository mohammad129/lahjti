import 'package:flutter/foundation.dart';
import '../models/subscription_plan.dart';

/// Outcome status of an attempted in-app purchase.
enum PurchaseStatus {
  /// Purchase completed and verified by server.
  success,

  /// Payment transaction is pending store authorization.
  pending,

  /// User dismissed or cancelled the checkout modal.
  userCancelled,

  /// Payment or store network failure.
  error,

  /// Real payments are disabled (development / foundation mode).
  disabledInDevelopment;

  bool get isSuccess => this == PurchaseStatus.success;
  bool get isPending => this == PurchaseStatus.pending;
  bool get isCancelled => this == PurchaseStatus.userCancelled;
  bool get isDisabled => this == PurchaseStatus.disabledInDevelopment;
}

/// Immutable result returned after an attempted plan purchase.
@immutable
class PurchaseResult {
  final PurchaseStatus status;
  final String? planId;
  final String? transactionId;
  final String? purchaseToken;
  final String? errorMessage;

  const PurchaseResult({
    required this.status,
    this.planId,
    this.transactionId,
    this.purchaseToken,
    this.errorMessage,
  });

  factory PurchaseResult.disabled({String? planId}) {
    return PurchaseResult(
      status: PurchaseStatus.disabledInDevelopment,
      planId: planId,
      errorMessage:
          'Real payment processing is disabled in this development phase.',
    );
  }

  factory PurchaseResult.success({
    required String planId,
    required String transactionId,
    required String purchaseToken,
  }) {
    return PurchaseResult(
      status: PurchaseStatus.success,
      planId: planId,
      transactionId: transactionId,
      purchaseToken: purchaseToken,
    );
  }

  factory PurchaseResult.error(String message, {String? planId}) {
    return PurchaseResult(
      status: PurchaseStatus.error,
      planId: planId,
      errorMessage: message,
    );
  }
}

/// Immutable result returned when attempting to restore past store purchases.
@immutable
class RestoreResult {
  final bool isSuccessful;
  final List<String> restoredPlanIds;
  final String message;

  const RestoreResult({
    required this.isSuccessful,
    this.restoredPlanIds = const [],
    required this.message,
  });

  factory RestoreResult.developmentMode() {
    return const RestoreResult(
      isSuccessful: false,
      message: 'Restore purchases is unavailable in development mode.',
    );
  }

  factory RestoreResult.restored(List<String> planIds) {
    return RestoreResult(
      isSuccessful: true,
      restoredPlanIds: planIds,
      message: 'Purchases restored successfully.',
    );
  }
}

/// Real-time update emitted during store transaction lifecycles.
@immutable
class PurchaseUpdate {
  final String planId;
  final PurchaseStatus status;
  final DateTime timestamp;
  final String? error;

  const PurchaseUpdate({
    required this.planId,
    required this.status,
    required this.timestamp,
    this.error,
  });
}

/// Abstract contract decoupling the application from specific store billing systems
/// (Google Play Billing, Apple StoreKit, Stripe, etc.).
abstract class BillingProvider {
  /// Fetches available subscription plans from store or configuration.
  Future<List<SubscriptionPlan>> getAvailablePlans();

  /// Initiates a purchase flow for a given plan.
  Future<PurchaseResult> purchasePlan(SubscriptionPlan plan);

  /// Restores active purchases across store accounts.
  Future<RestoreResult> restorePurchases();

  /// Stream of asynchronous purchase updates.
  Stream<PurchaseUpdate> get purchaseStream;
}
