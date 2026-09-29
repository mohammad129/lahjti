import '../models/achievement_models.dart';

/// Pure domain service evaluating student progress against achievement milestones.
class AchievementEvaluator {
  const AchievementEvaluator();

  /// Default baseline achievement catalog for Lahjti learners.
  List<Achievement> get defaultAchievements => const [
    Achievement(
      id: 'first_lesson',
      titleArabic: 'الخطوة الأولى 🚀',
      titleEnglish: 'First Step',
      descriptionArabic: 'أكملت أول درس تعليمي تفاعلي في رحلتك.',
      descriptionEnglish: 'Completed your very first learning lesson.',
      iconEmoji: '🚀',
      category: AchievementCategory.lessons,
      xpReward: 50,
      targetValue: 1,
    ),
    Achievement(
      id: 'first_vocab',
      titleArabic: 'بداية الحصيلة 📖',
      titleEnglish: 'Word Collector',
      descriptionArabic: 'تدربت على أول مجموعة من المفردات الجديدة.',
      descriptionEnglish: 'Practiced your first vocabulary set.',
      iconEmoji: '📖',
      category: AchievementCategory.vocabulary,
      xpReward: 30,
      targetValue: 1,
    ),
    Achievement(
      id: 'first_tutor',
      titleArabic: 'صوت واثق 🎙️',
      titleEnglish: 'Confident Voice',
      descriptionArabic: 'خضت أول محادثة صوتية مع معلمك الذكي عباس أو دنيا.',
      descriptionEnglish: 'Had your first voice session with your AI Tutor.',
      iconEmoji: '🎙️',
      category: AchievementCategory.tutor,
      xpReward: 50,
      targetValue: 1,
    ),
    Achievement(
      id: 'first_exam',
      titleArabic: 'تحدي الشجاعة 🏆',
      titleEnglish: 'Assessment Master',
      descriptionArabic: 'أتممت واجتزت أول اختبار تقييمي بنجاح.',
      descriptionEnglish: 'Passed your first milestone assessment.',
      iconEmoji: '🏆',
      category: AchievementCategory.exams,
      xpReward: 100,
      targetValue: 1,
    ),
    Achievement(
      id: 'streak_3',
      titleArabic: 'شعلة الالتزام 🔥',
      titleEnglish: '3-Day Fire',
      descriptionArabic: 'حافظت على سلسلة التعلم لمدة 3 أيام متتالية.',
      descriptionEnglish: 'Maintained a 3-day active learning streak.',
      iconEmoji: '🔥',
      category: AchievementCategory.streaks,
      xpReward: 60,
      targetValue: 3,
    ),
    Achievement(
      id: 'streak_7',
      titleArabic: 'الأسبوع الذهبي ⚡',
      titleEnglish: 'Golden Week',
      descriptionArabic: 'أتممت 7 أيام متتالية من التعلم المنتظم والمثمر.',
      descriptionEnglish: 'Completed 7 consecutive learning days.',
      iconEmoji: '⚡',
      category: AchievementCategory.streaks,
      xpReward: 120,
      targetValue: 7,
    ),
    Achievement(
      id: 'vocab_25',
      titleArabic: 'خازن الكلمات 📚',
      titleEnglish: 'Vocabulary Vault',
      descriptionArabic: 'أتقنت 25 مفردة وعبارة في رصيدك اللغوي.',
      descriptionEnglish: 'Mastered 25 vocabulary items.',
      iconEmoji: '📚',
      category: AchievementCategory.vocabulary,
      xpReward: 80,
      targetValue: 25,
    ),
    Achievement(
      id: 'vocab_50',
      titleArabic: 'قاموس ناطق 🧠',
      titleEnglish: 'Fluent Lexicon',
      descriptionArabic: 'أتقنت 50 مفردة أساسية مع التكرار المتباعد.',
      descriptionEnglish: 'Mastered 50 words with spaced repetition.',
      iconEmoji: '🧠',
      category: AchievementCategory.vocabulary,
      xpReward: 150,
      targetValue: 50,
    ),
    Achievement(
      id: 'xp_500',
      titleArabic: 'نجم التعلّم 🌟',
      titleEnglish: 'Star Learner',
      descriptionArabic: 'جمعت أكثر من 500 نقطة خبرة (XP) في التطبيق.',
      descriptionEnglish: 'Earned 500 cumulative XP points.',
      iconEmoji: '🌟',
      category: AchievementCategory.milestones,
      xpReward: 100,
      targetValue: 500,
    ),
  ];

  /// Evaluates the full list of achievements based on active student metrics.
  List<Achievement> evaluateAchievements({
    required List<Achievement> currentList,
    required int completedLessonsCount,
    required int masteredVocabCount,
    required int currentStreak,
    required int completedExamsCount,
    required int tutorTurnsCount,
    required int totalXp,
    required DateTime now,
  }) {
    final catalog = currentList.isNotEmpty ? currentList : defaultAchievements;

    return catalog.map((achievement) {
      if (achievement.isUnlocked) return achievement;

      int currentVal = 0;
      switch (achievement.id) {
        case 'first_lesson':
          currentVal = completedLessonsCount;
          break;
        case 'first_vocab':
          currentVal = masteredVocabCount > 0 ? 1 : 0;
          break;
        case 'first_tutor':
          currentVal = tutorTurnsCount > 0 ? 1 : 0;
          break;
        case 'first_exam':
          currentVal = completedExamsCount;
          break;
        case 'streak_3':
        case 'streak_7':
          currentVal = currentStreak;
          break;
        case 'vocab_25':
        case 'vocab_50':
          currentVal = masteredVocabCount;
          break;
        case 'xp_500':
          currentVal = totalXp;
          break;
        default:
          currentVal = achievement.currentValue;
          break;
      }

      final shouldUnlock = currentVal >= achievement.targetValue;

      return achievement.copyWith(
        currentValue: currentVal,
        isUnlocked: shouldUnlock,
        unlockedAt: shouldUnlock ? (achievement.unlockedAt ?? now) : null,
      );
    }).toList();
  }
}
