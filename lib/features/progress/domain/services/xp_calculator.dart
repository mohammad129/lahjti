import '../models/xp_models.dart';

/// Pure domain service calculating bounded, meaningful XP rewards while preventing abuse and farming.
class XpCalculator {
  const XpCalculator();

  /// Calculates the earned XP for a specific learning activity.
  int calculateActivityXp({
    required XpActivityType activityType,
    int? accuracyPercentage,
    int? itemsCount,
    bool isDuplicateAttempt = false,
  }) {
    // Prevent XP farming by repeating already completed actions with no new effort
    if (isDuplicateAttempt) {
      return (activityType.basePoints * 0.2).round().clamp(1, 10);
    }

    final base = activityType.basePoints;

    // Apply performance scaling where accuracy is relevant
    if (accuracyPercentage != null) {
      if (accuracyPercentage <= 0) {
        return 0; // Zero-effort / skipped attempts earn 0 XP
      }

      if (accuracyPercentage >= 90) {
        return (base * 1.25).round(); // High performance bonus (+25%)
      } else if (accuracyPercentage >= 70) {
        return base; // Standard completion reward
      } else if (accuracyPercentage >= 50) {
        return (base * 0.75).round(); // Partial completion
      } else {
        return (base * 0.40).round().clamp(5, base); // Effort acknowledgment
      }
    }

    // Scale by items count for bulk vocabulary reviews
    if (itemsCount != null && itemsCount > 0) {
      final perItem = (base / 5).clamp(2, 10);
      return (itemsCount * perItem).round().clamp(base, base * 3);
    }

    return base;
  }
}
