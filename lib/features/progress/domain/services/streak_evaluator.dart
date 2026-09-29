import '../models/streak_models.dart';

/// Pure domain service evaluating daily learning streaks deterministically and calendar-accurately.
class StreakEvaluator {
  const StreakEvaluator();

  /// Evaluates and updates the student's streak upon a meaningful learning activity at [activityTime].
  StreakUpdateResult evaluateActivity({
    required StreakData currentStreak,
    required DateTime activityTime,
  }) {
    final activityMidnight = DateTime(
      activityTime.year,
      activityTime.month,
      activityTime.day,
    );

    // Initial first-time activity
    if (currentStreak.lastActiveDate == null) {
      final updated = StreakData(
        currentStreak: 1,
        longestStreak: 1,
        lastActiveDate: activityMidnight,
        totalActiveDays: 1,
      );

      return StreakUpdateResult(
        updatedStreak: updated,
        didIncrement: true,
        didBreakLongestRecord: true,
        feedbackMessageArabic: 'أول يوم في رحلتك! بداية مباركة ومشجعة 🚀',
        feedbackMessageEnglish: 'First day of learning! Great start.',
      );
    }

    final lastActive = currentStreak.lastActiveDate!;
    final lastMidnight = DateTime(
      lastActive.year,
      lastActive.month,
      lastActive.day,
    );

    // Safeguard against clock skew / future date manipulation
    if (activityMidnight.isBefore(lastMidnight)) {
      return StreakUpdateResult(
        updatedStreak: currentStreak,
        didIncrement: false,
        didBreakLongestRecord: false,
        feedbackMessageArabic: 'تم تسجيل نشاطك بنجاح 👍',
        feedbackMessageEnglish: 'Activity recorded successfully.',
      );
    }

    final daysDifference = activityMidnight.difference(lastMidnight).inDays;

    if (daysDifference == 0) {
      // Activity completed on the same calendar day -> Streak maintained, no duplicate count
      return StreakUpdateResult(
        updatedStreak: currentStreak.copyWith(lastActiveDate: activityMidnight),
        didIncrement: false,
        didBreakLongestRecord: false,
        feedbackMessageArabic: 'أداء رائع ومثابرة مستمرة اليوم! 🔥',
        feedbackMessageEnglish: 'Great dedication today! Keep it up.',
      );
    } else if (daysDifference == 1) {
      // Consecutive day -> Increment streak by 1
      final newStreak = currentStreak.currentStreak + 1;
      final newLongest =
          newStreak > currentStreak.longestStreak
              ? newStreak
              : currentStreak.longestStreak;
      final isRecord = newStreak > currentStreak.longestStreak;

      final updated = currentStreak.copyWith(
        currentStreak: newStreak,
        longestStreak: newLongest,
        lastActiveDate: activityMidnight,
        totalActiveDays: currentStreak.totalActiveDays + 1,
      );

      return StreakUpdateResult(
        updatedStreak: updated,
        didIncrement: true,
        didBreakLongestRecord: isRecord,
        feedbackMessageArabic:
            isRecord
                ? 'رقم قياسي جديد! واصلت التعلم لـ $newStreak أيام متتالية! 🏆'
                : 'واصلت السلسلة! $newStreak أيام متتالية من التعلم المستمر 🔥',
        feedbackMessageEnglish:
            'Streak extended to $newStreak consecutive days!',
      );
    } else {
      // Missed one or more days -> Restart streak smoothly at 1 without harsh shame
      final updated = currentStreak.copyWith(
        currentStreak: 1,
        lastActiveDate: activityMidnight,
        totalActiveDays: currentStreak.totalActiveDays + 1,
      );

      return StreakUpdateResult(
        updatedStreak: updated,
        didIncrement: true,
        didBreakLongestRecord: false,
        feedbackMessageArabic:
            'أهلاً بعودتك! بداية جديدة لسلسلة تعلم مميزة وناجحة 🌟',
        feedbackMessageEnglish: 'Welcome back! Starting a new learning streak.',
      );
    }
  }
}
