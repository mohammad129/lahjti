import { ILearningDb } from '../db/index.js';
import { NotFoundError, ValidationError } from '../errors/api_error.js';

export interface PlanFilter {
  category?: string;
  targetAgeGroup?: string;
  targetLevel?: string;
}

export interface ActivitySubmission {
  activityId: string;
  score?: number;
  studentAnswer?: any;
}

export class PlanService {
  constructor(private db: ILearningDb) {}

  /**
   * 1. List active curriculum plans according to user's goals/age/level
   */
  async listPlans(filters?: PlanFilter): Promise<any[]> {
    return await this.db.getPlans(filters);
  }

  /**
   * 2. Get specific plan details along with its 60-day roadmap metadata
   */
  async getPlanDetails(planId: string, studentId?: string): Promise<any> {
    let effectivePlanId = planId;
    let plan = await this.db.getPlanById(effectivePlanId);
    if (!plan && (planId === 'plan_60_days_intensive' || planId === 'plan_conversation_60')) {
      effectivePlanId = planId === 'plan_60_days_intensive' ? 'plan_conversation_60' : 'plan_60_days_intensive';
      plan = await this.db.getPlanById(effectivePlanId);
    }
    if (!plan) throw new NotFoundError(`Plan with ID ${planId} was not found`);

    let days = await this.db.getPlanDays(effectivePlanId);
    if (days.length === 0 && effectivePlanId !== 'plan_conversation_60') {
      days = await this.db.getPlanDays('plan_conversation_60');
    }
    let enrollment: any = null;

    if (studentId) {
      enrollment =
        (await this.db.getStudentPlanProgress(studentId, planId)) ||
        (await this.db.getStudentPlanProgress(studentId, effectivePlanId));
    }

    return {
      plan: { ...plan, id: planId },
      totalDays: days.length > 0 ? days.length : 60,
      daysSummary: days.map((d) => ({
        dayNumber: d.dayNumber,
        titleAr: d.titleAr,
        focusTopic: d.focusTopic,
        totalXpReward: d.totalXpReward,
      })),
      enrollment: enrollment || {
        isEnrolled: false,
        currentDay: 1,
        completedDays: 0,
        status: 'not_enrolled',
      },
    };
  }

  /**
   * 3. Enroll a student into a curriculum plan
   */
  async enrollStudent(studentId: string, planId: string): Promise<any> {
    let effectivePlanId = planId;
    let plan = await this.db.getPlanById(effectivePlanId);
    if (!plan && (planId === 'plan_60_days_intensive' || planId === 'plan_conversation_60')) {
      effectivePlanId = planId === 'plan_60_days_intensive' ? 'plan_conversation_60' : 'plan_60_days_intensive';
      plan = await this.db.getPlanById(effectivePlanId);
    }
    if (!plan) throw new NotFoundError(`Plan with ID ${planId} was not found`);

    let progress = await this.db.getStudentPlanProgress(studentId, planId);
    if (!progress) {
      progress = await this.db.upsertStudentPlanProgress(studentId, planId, {
        currentDay: 1,
        completedDays: 0,
        status: 'active',
      });
    }

    // Friendly Arabic welcome message
    const welcomeTemplate = await this.db.getEncouragementTemplate('day_start', 'warm_friendly');

    return {
      success: true,
      planTitle: plan.titleAr,
      currentDay: progress.currentDay,
      completedDays: progress.completedDays,
      status: progress.status,
      welcomeMessage: welcomeTemplate?.messageAr || 'أهلاً بك! لنبدأ خطة الـ 60 يوماً معاً بحماس وعزيمة.',
    };
  }

  /**
   * 4. Get a student's daily path activities (the 9-10 structured micro-activities)
   */
  async getDayActivities(studentId: string, planId: string, dayNumber: number): Promise<any> {
    let effectivePlanId = planId;
    let plan = await this.db.getPlanById(effectivePlanId);
    if (!plan && (planId === 'plan_60_days_intensive' || planId === 'plan_conversation_60')) {
      effectivePlanId = planId === 'plan_60_days_intensive' ? 'plan_conversation_60' : 'plan_60_days_intensive';
      plan = await this.db.getPlanById(effectivePlanId);
    }
    if (!plan) throw new NotFoundError(`Plan ${planId} not found`);

    let day = await this.db.getPlanDay(planId, dayNumber);
    if (!day && effectivePlanId !== planId) {
      day = await this.db.getPlanDay(effectivePlanId, dayNumber);
    }
    if (!day) throw new NotFoundError(`Day ${dayNumber} for plan ${planId} not found`);

    const activities = await this.db.getPlanActivities(day.id);
    const logs = await this.db.getStudentActivityLogs(studentId, day.id);
    const completedActivityIds = new Set(logs.filter((l) => l.isCompleted).map((l) => l.activityId));

    // Fetch dynamic personalized encouragement message based on progress
    const encouragement = await this.db.getEncouragementTemplate('day_start');

    return {
      planId,
      planTitle: plan.titleAr,
      dayNumber: day.dayNumber,
      dayTitle: day.titleAr,
      focusTopic: day.focusTopic,
      descriptionAr: day.descriptionAr,
      totalXpReward: day.totalXpReward,
      encouragementMessage: encouragement?.messageAr || 'جاهز للتحدي اليوم؟ رائع، هيا بنا!',
      activities: activities.map((act) => ({
        id: act.id,
        stepOrder: act.stepOrder,
        activityType: act.activityType,
        titleAr: act.titleAr,
        contentPayload: act.contentPayload,
        audioAssetId: act.audioAssetId,
        xpReward: act.xpReward,
        isCompleted: completedActivityIds.has(act.id),
      })),
      isDayFullyCompleted: activities.length > 0 && activities.every((a) => completedActivityIds.has(a.id)),
    };
  }

  /**
   * 5. Server-authoritative completion of a daily micro-activity (ZERO AI requirement)
   */
  async completeActivity(
    studentId: string,
    planDayId: string,
    activityId: string,
    submission: { score?: number; answers?: any } = {}
  ): Promise<any> {
    // 1. Verify existence of the activity
    const activities = await this.db.getPlanActivities(planDayId);
    const activity = activities.find((a) => a.id === activityId);
    if (!activity) {
      throw new NotFoundError(`Activity ${activityId} not found in day ${planDayId}`);
    }

    // 2. Deterministic checking for quiz/matching without AI
    let finalScore = submission.score ?? 100;
    if (activity.activityType === 'quick_quiz' && activity.contentPayload?.questions) {
      const questions: any[] = activity.contentPayload.questions;
      let correct = 0;
      for (const q of questions) {
        const studentAns = submission.answers?.[q.question];
        if (studentAns && studentAns.trim().toLowerCase() === q.correctAnswer.trim().toLowerCase()) {
          correct++;
        } else if (studentAns) {
          // Record mistake for spaced repetition!
          await this.db.recordStudentMistake({
            studentId,
            contentId: `act_q_${q.question.substring(0, 32)}`,
            skillType: 'vocabulary',
            itemPrompt: q.question,
            correctAnswer: q.correctAnswer,
            studentLastWrongAnswer: studentAns,
          });
        }
      }
      if (questions.length > 0) {
        finalScore = Math.round((correct / questions.length) * 100);
      }
    }

    // 3. Record student activity log
    const xpReward = Math.round((activity.xpReward * finalScore) / 100);
    const log = await this.db.recordStudentActivity({
      studentId,
      planDayId,
      activityId,
      score: finalScore,
      xpEarned: xpReward,
      isCompleted: true,
    });

    // 4. Server-authoritative Points Transaction
    if (xpReward > 0) {
      await this.db.recordPointsTransaction({
        studentId,
        amount: xpReward,
        reasonCode: 'lesson_completed',
        descriptionAr: `إكمال نشاط: ${activity.titleAr}`,
        referenceId: activityId,
      });
    }

    // 5. Check if all activities for this day are finished
    const allLogs = await this.db.getStudentActivityLogs(studentId, planDayId);
    const completedSet = new Set(allLogs.filter((l) => l.isCompleted).map((l) => l.activityId));
    const isDayComplete = activities.every((a) => completedSet.has(a.id));

    let dayCompletedBonus = 0;
    let encouragementMessage = 'أحسنت! خطوة ممتازة نحو طلاقة الإنجليزية.';

    if (isDayComplete) {
      // Award Day Finish Streak Bonus
      dayCompletedBonus = 20;
      await this.db.recordPointsTransaction({
        studentId,
        amount: dayCompletedBonus,
        reasonCode: 'plan_day_finished',
        descriptionAr: 'مكافأة إكمال مسار اليوم بالكامل 🔥',
        referenceId: planDayId,
      });

      // Update student plan progress to next day
      // Determine planId from planDay
      const day = activities.length > 0 ? await this.findPlanDayById(planDayId) : null;
      if (day) {
        const currentProg = await this.db.getStudentPlanProgress(studentId, day.planId);
        if (currentProg) {
          const nextDay = Math.min(60, currentProg.currentDay + 1);
          await this.db.upsertStudentPlanProgress(studentId, day.planId, {
            currentDay: nextDay,
            completedDays: currentProg.completedDays + 1,
            status: nextDay >= 60 ? 'completed' : 'active',
          });
        }
      }

      const template = await this.db.getEncouragementTemplate('day_complete');
      if (template) encouragementMessage = template.messageAr;
    } else {
      const template = await this.db.getEncouragementTemplate('high_score');
      if (template) encouragementMessage = template.messageAr;
    }

    return {
      success: true,
      activityId,
      score: finalScore,
      xpEarned: xpReward,
      isDayComplete,
      dayCompletedBonus,
      totalPointsAdded: xpReward + dayCompletedBonus,
      encouragementMessage,
    };
  }

  private async findPlanDayById(planDayId: string): Promise<any | null> {
    const plans = await this.db.getPlans();
    for (const p of plans) {
      const days = await this.db.getPlanDays(p.id);
      const found = days.find((d) => d.id === planDayId);
      if (found) return found;
    }
    return null;
  }
}
