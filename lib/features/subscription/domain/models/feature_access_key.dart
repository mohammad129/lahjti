/// Granular feature identifiers protected by subscription and school access policies.
enum FeatureAccessKey {
  /// Core learning modules & curriculum lessons.
  lessons,

  /// Spaced-repetition vocabulary repository and review practice.
  vocabulary,

  /// Interactive educational mini-games (Word Match, Listen & Choose, etc.).
  games,

  /// Real-time AI voice/text tutor conversational agent.
  aiTutor,

  /// CEFR level tracking, skill score charts, and milestone achievements.
  progress,

  /// Daily deterministic learning and school tasks.
  schoolDailyTasks,

  /// School classroom rosters, student progress oversight, and assignments.
  schoolClassrooms,

  /// Teacher dashboard metrics and institutional class management.
  teacherDashboard;

  String get code => name;

  static FeatureAccessKey fromString(String? value) {
    if (value == null) return FeatureAccessKey.lessons;
    return FeatureAccessKey.values.firstWhere(
      (f) => f.name.toLowerCase() == value.toLowerCase().trim(),
      orElse: () => FeatureAccessKey.lessons,
    );
  }
}
