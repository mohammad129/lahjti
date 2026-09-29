/// Represents the primary account context of the user in Lahjti.
enum AccountContext {
  /// Self-paced individual language learner.
  individual,

  /// Institutional school account (Student or Teacher).
  school;

  bool get isIndividual => this == AccountContext.individual;
  bool get isSchool => this == AccountContext.school;

  String get code => name;

  static AccountContext fromString(String? value) {
    if (value == null) return AccountContext.individual;
    switch (value.toLowerCase().trim()) {
      case 'school':
        return AccountContext.school;
      case 'individual':
      default:
        return AccountContext.individual;
    }
  }
}
