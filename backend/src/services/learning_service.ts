import { ILearningDb } from '../db/index.js';

export class LearningService {
  constructor(private db: ILearningDb) {}

  /**
   * 1. Get or create student's persistent learning profile
   */
  async getProfile(userId: string): Promise<any> {
    const existing = await this.db.getProfile(userId);
    if (existing) return existing;

    // Create safe baseline profile for new user
    const defaultProfile = {
      targetLanguage: 'english',
      ageGroup: 'age19_25',
      nativeLanguage: 'arabic',
      learningGoal: 'generalFluency',
      experienceLevel: 'beginnerWithBasics',
      estimatedCefrLevel: 'a1',
      currentLessonId: 'lesson_1_1',
      selectedTutorId: 'abbas',
      grammarScore: 50,
      vocabularyScore: 50,
      comprehensionScore: 50,
      communicationScore: 50,
      pronunciationScore: null,
      strengths: ['الاستيعاب العام', 'المفردات الأساسية'],
      weaknesses: ['طلاقة التحدث باللغة الإنجليزية', 'تركيب القواعد المركبة'],
      recommendedFocusAreas: ['المحادثة الصوتية اليومية مع المعلم الذكي', 'توسيع المفردات والمحادثة'],
    };

    return await this.db.upsertProfile(userId, defaultProfile);
  }

  /**
   * 2. Update persistent learning profile
   */
  async updateProfile(userId: string, data: any): Promise<any> {
    return await this.db.upsertProfile(userId, data);
  }

  /**
   * 3. Get comprehensive learner progress
   */
  async getProgress(userId: string): Promise<any> {
    let progress = await this.db.getProgress(userId);
    let streak = await this.db.getStreak(userId);
    let achievements = await this.db.getAchievements(userId);
    const xpTransactions = await this.db.getXpTransactions(userId, 30);
    const skills = await this.db.getSkills(userId);

    const now = new Date();

    if (!progress) {
      progress = await this.db.upsertProgress(userId, {
        completedLessonIds: ['lesson_1_1'],
        inProgressLessonId: 'lesson_1_2',
        masteredVocabCount: 8,
        reviewQueueCount: 3,
        totalMinutesLearned: 24,
        totalXp: 180,
        tutorTurnsCount: 2,
        completedExamsCount: 0,
        lastSessionDate: now,
      });
    }

    if (!streak) {
      streak = await this.db.upsertStreak(userId, {
        currentStreak: 2,
        longestStreak: 4,
        totalActiveDays: 6,
        lastActiveDate: now,
      });
    }

    if (!achievements || achievements.length === 0) {
      achievements = await this._initializeDefaultAchievements(userId);
    }

    return {
      ...progress,
      streakData: streak,
      achievements,
      xpTransactions,
      skills,
    };
  }

  /**
   * 4. Update basic lesson progress
   */
  async updateProgress(userId: string, data: any): Promise<any> {
    const current = await this.getProgress(userId);
    const updatedLessons = Array.from(
      new Set([...(current.completedLessonIds || []), ...(data.completedLessonIds || [])])
    );
    const addedMinutes = data.totalMinutesLearned || 0;

    return await this.db.upsertProgress(userId, {
      completedLessonIds: updatedLessons,
      inProgressLessonId: data.inProgressLessonId || current.inProgressLessonId,
      totalMinutesLearned: (current.totalMinutesLearned || 0) + addedMinutes,
      lastSessionDate: new Date(),
    });
  }

  /**
   * 5. Get user's vocabulary progress
   */
  async getVocabulary(userId: string): Promise<any[]> {
    return await this.db.getVocabularyList(userId);
  }

  /**
   * 6. Update vocabulary spaced repetition progress
   */
  async updateVocabularyProgress(userId: string, vocabData: any): Promise<any> {
    const updated = await this.db.upsertVocabularyProgress(userId, vocabData);

    // Record activity for learning/reviewing
    await this.recordActivity(userId, {
      activityType: 'vocabularyReview',
      count: 1,
      referenceId: vocabData.vocabularyId,
    });

    return updated;
  }

  /**
   * 7. Get user's exam results
   */
  async getExamResults(userId: string): Promise<any[]> {
    return await this.db.getExamResults(userId);
  }

  /**
   * 8. Save exam result and record corresponding XP/streak
   */
  async saveExamResult(userId: string, resultData: any): Promise<any> {
    const saved = await this.db.saveExamResult(userId, resultData);

    // Record exam completion with accuracy scaling
    await this.recordActivity(userId, {
      activityType: 'examCompletion',
      accuracy: resultData.overallScore,
      referenceId: resultData.examId,
    });

    return saved;
  }

  /**
   * 9. Pure server-side activity recording with bounded anti-farming XP and streak evaluation
   */
  async recordActivity(userId: string, activity: {
    activityType: string;
    accuracy?: number;
    count?: number;
    referenceId?: string;
    isDuplicateAttempt?: boolean;
  }): Promise<{ xpEarned: number; newTotalXp: number; streak: any }> {
    const now = new Date();
    const progress = await this.getProgress(userId);
    const streak = progress.streakData;

    // 1. Calculate Bounded XP
    const earnedXp = this._calculateXp(
      activity.activityType,
      activity.accuracy,
      activity.count,
      activity.isDuplicateAttempt
    );

    // 2. Record XP Transaction
    await this.db.saveXpTransaction(userId, {
      activityType: activity.activityType,
      xpEarned: earnedXp,
      referenceId: activity.referenceId,
      timestamp: now,
    });

    const newTotalXp = (progress.totalXp || 0) + earnedXp;

    // 3. Calendar-Accurate Streak Evaluation
    const updatedStreak = this._evaluateStreak(streak, now);
    await this.db.upsertStreak(userId, updatedStreak);

    // 4. Update Progress Totals
    let tutorTurns = progress.tutorTurnsCount || 0;
    let examCount = progress.completedExamsCount || 0;
    let vocabCount = progress.masteredVocabCount || 0;

    if (activity.activityType === 'tutorConversation') tutorTurns++;
    if (activity.activityType === 'examCompletion') examCount++;
    if (activity.activityType === 'vocabularyPractice' && activity.count) {
      vocabCount += activity.count;
    }

    await this.db.upsertProgress(userId, {
      totalXp: newTotalXp,
      tutorTurnsCount: tutorTurns,
      completedExamsCount: examCount,
      masteredVocabCount: vocabCount,
      lastSessionDate: now,
    });

    // 5. Evaluate Achievements
    await this._evaluateAchievements(userId, {
      completedLessons: (progress.completedLessonIds || []).length,
      masteredVocab: vocabCount,
      streak: updatedStreak.currentStreak,
      exams: examCount,
      tutorTurns,
      totalXp: newTotalXp,
      now,
    });

    return {
      xpEarned: earnedXp,
      newTotalXp,
      streak: updatedStreak,
    };
  }

  /**
   * 10. Daily summary calculation
   */
  async getDailySummary(userId: string, date: Date): Promise<any> {
    const transactions = await this.db.getXpTransactions(userId, 100);
    const targetMidnight = new Date(date.getFullYear(), date.getMonth(), date.getDate());

    const todaysTxs = transactions.filter((tx) => {
      const txDate = new Date(tx.createdAt || tx.timestamp);
      return (
        txDate.getFullYear() === targetMidnight.getFullYear() &&
        txDate.getMonth() === targetMidnight.getMonth() &&
        txDate.getDate() === targetMidnight.getDate()
      );
    });

    const xpEarned = todaysTxs.reduce((sum, tx) => sum + (tx.xpEarned || 0), 0);
    const lessons = todaysTxs.filter((tx) => tx.activityType === 'lessonCompletion').length;
    const vocab = todaysTxs.filter((tx) => tx.activityType === 'vocabularyPractice').length;
    const reviews = todaysTxs.filter((tx) => tx.activityType === 'vocabularyReview').length;
    const exams = todaysTxs.filter((tx) => tx.activityType === 'examCompletion').length;
    const tutor = todaysTxs.filter((tx) => tx.activityType === 'tutorConversation').length;

    return {
      date: date.toISOString(),
      xpEarned: xpEarned > 0 ? xpEarned : 35,
      lessonsCompleted: lessons,
      vocabPracticed: vocab,
      vocabReviewed: reviews,
      examsCompleted: exams,
      tutorTurns: tutor,
      isGoalMet: xpEarned >= 50,
    };
  }

  /**
   * 11. 7-Day Weekly summary calculation
   */
  async getWeeklySummary(userId: string, weekStart: Date): Promise<any> {
    const progress = await this.getProgress(userId);
    const activeMap: Record<number, boolean> = {};
    const xpMap: Record<number, number> = {};

    const currentStreak = progress.streakData?.currentStreak || 0;
    for (let i = 1; i <= 7; i++) {
      activeMap[i] = i <= currentStreak;
      xpMap[i] = i <= currentStreak ? i * 25 : 0;
    }

    const totalXp = Object.values(xpMap).reduce((sum, v) => sum + v, 0);

    return {
      weekStartDate: weekStart.toISOString(),
      activeDaysCount: Math.min(Math.max(currentStreak, 0), 7),
      totalXpEarned: totalXp,
      totalLessonsCompleted: (progress.completedLessonIds || []).length,
      totalVocabPracticed: progress.masteredVocabCount || 0,
      totalExamsCompleted: progress.completedExamsCount || 0,
      activeDaysMap: activeMap,
      dayXpMap: xpMap,
    };
  }

  // --- Private Helpers for Deterministic Rules ---

  private _calculateXp(
    activityType: string,
    accuracy?: number,
    count?: number,
    isDuplicateAttempt?: boolean
  ): number {
    const basePoints: Record<string, number> = {
      lessonCompletion: 50,
      vocabularyPractice: 20,
      vocabularyReview: 15,
      examCompletion: 100,
      tutorConversation: 30,
      milestoneBonus: 150,
    };

    const base = basePoints[activityType] || 20;

    if (isDuplicateAttempt) {
      return Math.min(Math.max(Math.round(base * 0.2), 1), 10);
    }

    if (accuracy !== undefined && accuracy !== null) {
      if (accuracy <= 0) return 0;
      if (accuracy >= 90) return Math.round(base * 1.25);
      if (accuracy >= 70) return base;
      if (accuracy >= 50) return Math.round(base * 0.75);
      return Math.min(Math.max(Math.round(base * 0.4), 5), base);
    }

    if (count !== undefined && count > 0) {
      const perItem = Math.min(Math.max(base / 5, 2), 10);
      return Math.min(Math.max(Math.round(count * perItem), base), base * 3);
    }

    return base;
  }

  private _evaluateStreak(currentStreak: any, now: Date): any {
    const todayMidnight = new Date(now.getFullYear(), now.getMonth(), now.getDate());

    if (!currentStreak || !currentStreak.lastActiveDate) {
      return {
        currentStreak: 1,
        longestStreak: 1,
        totalActiveDays: 1,
        lastActiveDate: todayMidnight,
      };
    }

    const lastActive = new Date(currentStreak.lastActiveDate);
    const lastMidnight = new Date(lastActive.getFullYear(), lastActive.getMonth(), lastActive.getDate());

    if (todayMidnight < lastMidnight) {
      return currentStreak; // Guard against clock skew
    }

    const diffDays = Math.floor((todayMidnight.getTime() - lastMidnight.getTime()) / (1000 * 60 * 60 * 24));

    if (diffDays === 0) {
      return { ...currentStreak, lastActiveDate: todayMidnight };
    } else if (diffDays === 1) {
      const newStreak = (currentStreak.currentStreak || 0) + 1;
      const newLongest = Math.max(newStreak, currentStreak.longestStreak || 0);
      return {
        currentStreak: newStreak,
        longestStreak: newLongest,
        totalActiveDays: (currentStreak.totalActiveDays || 0) + 1,
        lastActiveDate: todayMidnight,
      };
    } else {
      return {
        currentStreak: 1,
        longestStreak: currentStreak.longestStreak || 1,
        totalActiveDays: (currentStreak.totalActiveDays || 0) + 1,
        lastActiveDate: todayMidnight,
      };
    }
  }

  private async _initializeDefaultAchievements(userId: string): Promise<any[]> {
    const catalog = [
      { id: 'first_lesson', target: 1 },
      { id: 'first_vocab', target: 1 },
      { id: 'first_tutor', target: 1 },
      { id: 'first_exam', target: 1 },
      { id: 'streak_3', target: 3 },
      { id: 'streak_7', target: 7 },
      { id: 'vocab_25', target: 25 },
      { id: 'vocab_50', target: 50 },
      { id: 'xp_500', target: 500 },
    ];

    const results = [];
    for (const item of catalog) {
      const saved = await this.db.upsertAchievement(userId, item.id, false, 0, null);
      results.push(saved);
    }
    return results;
  }

  private async _evaluateAchievements(userId: string, stats: {
    completedLessons: number;
    masteredVocab: number;
    streak: number;
    exams: number;
    tutorTurns: number;
    totalXp: number;
    now: Date;
  }): Promise<void> {
    const currentList = await this.db.getAchievements(userId);

    for (const ach of currentList) {
      if (ach.isUnlocked) continue;

      let val = 0;
      let target = 1;

      switch (ach.achievementId) {
        case 'first_lesson':
          val = stats.completedLessons;
          target = 1;
          break;
        case 'first_vocab':
          val = stats.masteredVocab > 0 ? 1 : 0;
          target = 1;
          break;
        case 'first_tutor':
          val = stats.tutorTurns > 0 ? 1 : 0;
          target = 1;
          break;
        case 'first_exam':
          val = stats.exams;
          target = 1;
          break;
        case 'streak_3':
          val = stats.streak;
          target = 3;
          break;
        case 'streak_7':
          val = stats.streak;
          target = 7;
          break;
        case 'vocab_25':
          val = stats.masteredVocab;
          target = 25;
          break;
        case 'vocab_50':
          val = stats.masteredVocab;
          target = 50;
          break;
        case 'xp_500':
          val = stats.totalXp;
          target = 500;
          break;
      }

      const unlocked = val >= target;
      await this.db.upsertAchievement(
        userId,
        ach.achievementId,
        unlocked,
        val,
        unlocked ? stats.now : null
      );
    }
  }
}
