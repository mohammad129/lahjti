import 'package:flutter/foundation.dart';

/// Event type for asynchronous webhook and store billing events.
enum BillingEventType {
  created('subscription.created'),
  renewed('subscription.renewed'),
  cancelled('subscription.cancelled'),
  expired('subscription.expired'),
  paymentFailed('subscription.payment_failed');

  final String eventName;
  const BillingEventType(this.eventName);

  static BillingEventType fromString(String? value) {
    if (value == null) return BillingEventType.created;
    switch (value.toLowerCase().trim()) {
      case 'subscription.renewed':
      case 'renewed':
        return BillingEventType.renewed;
      case 'subscription.cancelled':
      case 'cancelled':
        return BillingEventType.cancelled;
      case 'subscription.expired':
      case 'expired':
        return BillingEventType.expired;
      case 'subscription.payment_failed':
      case 'payment_failed':
      case 'paymentfailed':
        return BillingEventType.paymentFailed;
      case 'subscription.created':
      case 'created':
      default:
        return BillingEventType.created;
    }
  }
}

/// Immutable webhook event payload representation for backend billing integration.
@immutable
class BillingEvent {
  final String eventId;
  final String idempotencyKey;
  final String userId;
  final String planId;
  final BillingEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> payload;

  const BillingEvent({
    required this.eventId,
    required this.idempotencyKey,
    required this.userId,
    required this.planId,
    required this.type,
    required this.timestamp,
    this.payload = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'idempotencyKey': idempotencyKey,
      'userId': userId,
      'planId': planId,
      'type': type.eventName,
      'timestamp': timestamp.toIso8601String(),
      'payload': payload,
    };
  }

  factory BillingEvent.fromJson(Map<String, dynamic> json) {
    return BillingEvent(
      eventId: json['eventId'] as String? ?? '',
      idempotencyKey: json['idempotencyKey'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      planId: json['planId'] as String? ?? '',
      type: BillingEventType.fromString(json['type'] as String?),
      timestamp:
          json['timestamp'] != null
              ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
              : DateTime.now(),
      payload: (json['payload'] as Map<String, dynamic>?) ?? const {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillingEvent &&
          runtimeType == other.runtimeType &&
          eventId == other.eventId &&
          idempotencyKey == other.idempotencyKey;

  @override
  int get hashCode => eventId.hashCode ^ idempotencyKey.hashCode;
}

/// In-memory idempotency tracker to guarantee repeated webhook events do not duplicate records.
class BillingEventIdempotencyTracker {
  final Set<String> _processedKeys = {};

  /// Returns true if this event is new and should be processed.
  /// Returns false if this idempotency key was already recorded.
  bool recordAndVerify(String idempotencyKey) {
    if (_processedKeys.contains(idempotencyKey)) {
      return false; // Duplicate event ignored
    }
    _processedKeys.add(idempotencyKey);
    return true;
  }

  int get processedCount => _processedKeys.length;

  void clear() => _processedKeys.clear();
}
