/// Represents a user's role within a school context in Lahjti.
enum SchoolRole {
  /// School student enrolled in classes.
  student,

  /// School teacher managing instruction and courses.
  teacher;

  bool get isStudent => this == SchoolRole.student;
  bool get isTeacher => this == SchoolRole.teacher;

  String get code => name;

  static SchoolRole? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase().trim()) {
      case 'student':
        return SchoolRole.student;
      case 'teacher':
        return SchoolRole.teacher;
      default:
        return null;
    }
  }
}
