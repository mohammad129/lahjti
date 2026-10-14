import { ILearningDb } from '../db/index.js';

export class SpacedRepetitionMistakeService {
  constructor(private db: ILearningDb) {}

  /**
   * 1. Record an incorrect answer or mistake for future spaced-repetition review
   */
  async recordMistake(params: {
    studentId: string;
    contentId: string;
    skillType: 'vocabulary' | 'grammar' | 'listening' | 'spelling' | 'pronunciation';
    itemPrompt: string;
    correctAnswer: string;
    studentLastWrongAnswer?: string;
  }): Promise<any> {
    return await this.db.recordStudentMistake(params);
  }

  /**
   * 2. Get list of due mistakes scheduled for review today
   */
  async getDueReviews(studentId: string, limit: number = 15): Promise<any> {
    const dueItems = await this.db.getStudentMistakesDue(studentId, limit);

    return {
      studentId,
      dueCount: dueItems.length,
      reviews: dueItems.map((item) => ({
        id: item.id,
        contentId: item.contentId,
        skillType: item.skillType,
        itemPrompt: item.itemPrompt,
        correctAnswer: item.correctAnswer,
        studentLastWrongAnswer: item.studentLastWrongAnswer,
        mistakeCount: item.mistakeCount,
        intervalDays: item.intervalDays,
        easeFactor: item.easeFactor,
        repetitions: item.repetitions,
        nextReviewAt: item.nextReviewAt,
      })),
    };
  }

  /**
   * 3. Submit review attempt (pure backend algorithmic SM-2 update)
   */
  async submitReviewAttempt(
    studentId: string,
    contentId: string,
    studentAnswer: string
  ): Promise<any> {
    // 1. Fetch existing item
    const dueList = await this.db.getStudentMistakesDue(studentId, 100);
    const item = dueList.find((i) => i.contentId === contentId);

    let wasCorrect = false;
    let correctAnswer = '';

    if (item) {
      correctAnswer = item.correctAnswer;
      wasCorrect =
        studentAnswer.trim().toLowerCase() === item.correctAnswer.trim().toLowerCase();
    } else {
      wasCorrect = true;
    }

    // 2. Update spaced repetition intervals
    const updated = await this.db.updateStudentMistakeReview(
      studentId,
      contentId,
      wasCorrect
    );

    // 3. Award points if correctly reviewed and mastered
    let xpEarned = 0;
    if (wasCorrect) {
      xpEarned = 5;
      await this.db.recordPointsTransaction({
        studentId,
        amount: xpEarned,
        reasonCode: 'correct_answer',
        descriptionAr: 'مراجعة خطأ وإتقانه بالتكرار المتباعد 🎯',
        referenceId: contentId,
      });
    }

    const encouragement = wasCorrect
      ? await this.db.getEncouragementTemplate('high_score')
      : await this.db.getEncouragementTemplate('after_mistake');

    return {
      success: true,
      wasCorrect,
      correctAnswer,
      xpEarned,
      mastered: updated?.mastered || false,
      nextReviewInDays: updated?.intervalDays || 1,
      encouragementMessage:
        encouragement?.messageAr ||
        (wasCorrect
          ? 'ممتاز! أتقنت هذه النقطة بنجاح.'
          : 'لا بأس، سنعيد مراجعتها لاحقاً لتثبيتها!'),
    };
  }
}
