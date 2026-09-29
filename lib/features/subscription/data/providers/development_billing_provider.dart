import 'dart:async';
import '../../domain/models/subscription_plan.dart';
import '../../domain/services/billing_provider.dart';

/// Safe development implementation of [BillingProvider].
///
/// Designed to provide real UI plans without initiating real financial transactions
/// or connecting live store gateways in development phases.
class DevelopmentBillingProvider implements BillingProvider {
  final StreamController<PurchaseUpdate> _controller =
      StreamController<PurchaseUpdate>.broadcast();

  final List<SubscriptionPlan> _plans = const [
    SubscriptionPlan.individualMonthly,
  ];

  @override
  Future<List<SubscriptionPlan>> getAvailablePlans() async {
    return _plans;
  }

  @override
  Future<PurchaseResult> purchasePlan(SubscriptionPlan plan) async {
    // Deliberate constraint: No real payment processing in Step 23
    return PurchaseResult.disabled(planId: plan.id);
  }

  @override
  Future<RestoreResult> restorePurchases() async {
    return RestoreResult.developmentMode();
  }

  @override
  Stream<PurchaseUpdate> get purchaseStream => _controller.stream;

  void dispose() {
    _controller.close();
  }
}
