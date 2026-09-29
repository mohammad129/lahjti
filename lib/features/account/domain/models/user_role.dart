/// Represents the explicit user roles in Lahjti (لهجتي).
///
/// Ensures strict role separation and multi-tenant security boundaries.
enum UserRole {
  /// Self-paced individual language learner.
  individualLearner,

  /// School student enrolled in classes under school supervision.
  schoolStudent,

  /// School teacher with classroom instruction and student analytics access.
  schoolTeacher;

  bool get isIndividual => this == UserRole.individualLearner;
  bool get isStudent => this == UserRole.schoolStudent;
  bool get isTeacher => this == UserRole.schoolTeacher;

  String get code => name;

  static UserRole fromString(String? value) {
    if (value == null) return UserRole.individualLearner;
    switch (value.toLowerCase().trim()) {
      case 'schoolstudent':
      case 'student':
        return UserRole.schoolStudent;
      case 'schoolteacher':
      case 'teacher':
        return UserRole.schoolTeacher;
      case 'individuallearner':
      case 'individual':
      default:
        return UserRole.individualLearner;
    }
  }

  Map<String, dynamic> toJson() => {'role': name};
}
