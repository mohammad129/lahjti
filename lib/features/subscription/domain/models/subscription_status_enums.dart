/// Billing period frequency for subscription plans.
enum SubscriptionPeriod {
  monthly,
  quarterly,
  yearly;

  String get code => name;

  static SubscriptionPeriod fromString(String? value) {
    if (value == null) return SubscriptionPeriod.monthly;
    switch (value.toLowerCase().trim()) {
      case 'yearly':
      case 'annual':
        return SubscriptionPeriod.yearly;
      case 'quarterly':
        return SubscriptionPeriod.quarterly;
      case 'monthly':
      default:
        return SubscriptionPeriod.monthly;
    }
  }
}

/// Status of an institutional school access tier.
enum SchoolAccessStatus {
  active,
  suspended,
  expired;

  bool get isActive => this == SchoolAccessStatus.active;
  bool get isSuspended => this == SchoolAccessStatus.suspended;
  bool get isExpired => this == SchoolAccessStatus.expired;

  static SchoolAccessStatus fromString(String? value) {
    if (value == null) return SchoolAccessStatus.active;
    switch (value.toLowerCase().trim()) {
      case 'suspended':
        return SchoolAccessStatus.suspended;
      case 'expired':
        return SchoolAccessStatus.expired;
      case 'active':
      default:
        return SchoolAccessStatus.active;
    }
  }
}
