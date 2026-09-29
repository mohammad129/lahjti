/// Status of a user's trial or subscription entitlement.
enum TrialStatus {
  /// Active trial period.
  trial,

  /// Active paid or verified entitlement.
  active,

  /// Expired trial or subscription period.
  expired,

  /// Institutional school access (managed by school license).
  schoolAccess,

  /// Unavailable or suspended access.
  unavailable;

  bool get isTrial => this == TrialStatus.trial;
  bool get isActive => this == TrialStatus.active;
  bool get isExpired => this == TrialStatus.expired;
  bool get isSchoolAccess => this == TrialStatus.schoolAccess;
  bool get isUnavailable => this == TrialStatus.unavailable;

  static TrialStatus fromString(String? value) {
    if (value == null) return TrialStatus.trial;
    switch (value.toLowerCase().trim()) {
      case 'active':
        return TrialStatus.active;
      case 'expired':
        return TrialStatus.expired;
      case 'schoolaccess':
      case 'school_access':
        return TrialStatus.schoolAccess;
      case 'unavailable':
        return TrialStatus.unavailable;
      case 'trial':
      default:
        return TrialStatus.trial;
    }
  }
}
