import { and, desc, eq, lte, sql } from 'drizzle-orm';
import { drizzle } from 'drizzle-orm/node-postgres';
import pg from 'pg';
import { config } from '../config/env.js';
import * as schema from './schema.js';

const { Pool } = pg;

export interface ILearningDb {
  // Profiles
  getProfile(userId: string): Promise<any | null>;
  upsertProfile(userId: string, data: any): Promise<any>;

  // Progress
  getProgress(userId: string): Promise<any | null>;
  upsertProgress(userId: string, data: any): Promise<any>;

  // Streaks
  getStreak(userId: string): Promise<any | null>;
  upsertStreak(userId: string, data: any): Promise<any>;

  // Skills
  getSkills(userId: string): Promise<any[]>;
  upsertSkill(userId: string, skill: string, levelScore: number, assessedAttempts: number): Promise<any>;

  // Vocabulary
  getVocabularyList(userId: string): Promise<any[]>;
  upsertVocabularyProgress(userId: string, vocabData: any): Promise<any>;

  // Exams
  getExamResults(userId: string): Promise<any[]>;
  saveExamResult(userId: string, result: any): Promise<any>;

  // XP Transactions
  getXpTransactions(userId: string, limit?: number): Promise<any[]>;
  saveXpTransaction(userId: string, transaction: any): Promise<any>;

  // Achievements
  getAchievements(userId: string): Promise<any[]>;
  upsertAchievement(userId: string, achievementId: string, isUnlocked: boolean, currentValue: number, unlockedAt?: Date | null): Promise<any>;

  // School & Memberships
  getSchool(schoolId: string): Promise<any | null>;
  getSchoolByCode(schoolCode: string): Promise<any | null>;
  createSchool(data: any): Promise<any>;
  getSchoolMembership(userId: string): Promise<any | null>;
  getSchoolMembershipsBySchool(schoolId: string): Promise<any[]>;
  upsertSchoolMembership(data: any): Promise<any>;

  // Classrooms & Enrollments
  getClassroomsForTeacher(teacherId: string): Promise<any[]>;
  getClassroomsForSchool(schoolId: string): Promise<any[]>;
  getClassroom(classroomId: string): Promise<any | null>;
  createClassroom(data: any): Promise<any>;
  getClassroomStudents(classroomId: string): Promise<any[]>;
  getStudentClassrooms(studentId: string): Promise<any[]>;
  addStudentToClassroom(data: any): Promise<any>;

  // Daily Tasks
  getDailyTasks(studentId: string, taskDate: string): Promise<any[]>;
  saveDailyTasks(tasks: any[]): Promise<any[]>;
  getDailyTaskById(taskId: string): Promise<any | null>;
  updateDailyTask(taskId: string, updates: any): Promise<any | null>;

  // Game Results
  saveGameResult(result: any): Promise<any>;
  getGameResults(studentId: string, limit?: number): Promise<any[]>;

  // Subscriptions & Monetization
  getSubscription(userId: string): Promise<any | null>;
  upsertSubscription(data: any): Promise<any>;

  // AI Usage Metering & Cost Control
  recordAiUsage(data: {
    userId: string;
    usageDate: string;
    feature: string;
    modelUsed: string;
    inputTokens: number;
    outputTokens: number;
    voiceSeconds?: number;
    cachedResponsesCount?: number;
  }): Promise<any>;
  getDailyAiUsage(userId: string, usageDate: string): Promise<any[]>;
  getTotalDailyAiTokens(userId: string, usageDate: string): Promise<{
    totalInputTokens: number;
    totalOutputTokens: number;
    totalTokens: number;
    totalRequests: number;
    totalVoiceSeconds: number;
  }>;
  getStudentDailyTutorSessions(studentId: string, date: string): Promise<any[]>;
  saveStudentTutorSession(session: any): Promise<any>;
  updateStudentTutorSession(sessionId: string, updates: any): Promise<any>;

  // Plans & 60-Day Path
  getPlans(filters?: { category?: string; targetAgeGroup?: string; targetLevel?: string }): Promise<any[]>;
  getPlanById(planId: string): Promise<any | null>;
  savePlan(plan: any): Promise<any>;
  getPlanDays(planId: string): Promise<any[]>;
  getPlanDay(planId: string, dayNumber: number): Promise<any | null>;
  savePlanDays(days: any[]): Promise<any[]>;
  getPlanActivities(planDayId: string): Promise<any[]>;
  savePlanActivities(activities: any[]): Promise<any[]>;
  getStudentPlanProgress(studentId: string, planId: string): Promise<any | null>;
  upsertStudentPlanProgress(studentId: string, planId: string, data: any): Promise<any>;
  recordStudentActivity(data: any): Promise<any>;
  getStudentActivityLogs(studentId: string, planDayId: string): Promise<any[]>;

  // Student Codes & PIN Auth
  getStudentCodeByCode(code: string): Promise<any | null>;
  getStudentCodeByStudentId(studentId: string): Promise<any | null>;
  saveStudentCode(data: any): Promise<any>;

  // Points Transactions (Server-authoritative)
  recordPointsTransaction(data: {
    studentId: string;
    amount: number;
    reasonCode: string;
    descriptionAr: string;
    referenceId?: string;
  }): Promise<any>;
  getPointsTransactions(studentId: string, limit?: number): Promise<any[]>;

  // Student Mistakes & Spaced Repetition
  recordStudentMistake(data: {
    studentId: string;
    contentId: string;
    skillType: string;
    itemPrompt: string;
    correctAnswer: string;
    studentLastWrongAnswer?: string;
  }): Promise<any>;
  getStudentMistakesDue(studentId: string, limit?: number): Promise<any[]>;
  updateStudentMistakeReview(studentId: string, contentId: string, wasCorrect: boolean): Promise<any>;

  // Teacher Exams
  getExamsForClassroom(classroomId: string): Promise<any[]>;
  getExamsForTeacher(teacherId: string): Promise<any[]>;
  getExamById(examId: string): Promise<any | null>;
  saveExam(data: any): Promise<any>;
  getExamQuestions(examId: string): Promise<any[]>;
  saveExamQuestions(questions: any[]): Promise<any[]>;
  submitExam(submission: any): Promise<any>;
  getExamSubmissions(examId: string): Promise<any[]>;
  getStudentExamSubmission(examId: string, studentId: string): Promise<any | null>;

  // Educational Games Hub
  getEducationalGames(filters?: { targetAgeGroup?: string; difficulty?: string; classroomId?: string }): Promise<any[]>;
  getEducationalGameById(gameId: string): Promise<any | null>;
  saveEducationalGame(data: any): Promise<any>;
  getGameQuestions(gameId: string): Promise<any[]>;
  saveGameQuestions(questions: any[]): Promise<any[]>;

  // Audio Assets & Encouragement Templates
  getAudioAssets(category?: string): Promise<any[]>;
  findAudioAssetByText(text: string, category?: string): Promise<any | null>;
  saveAudioAsset(data: any): Promise<any>;
  getEncouragementTemplate(triggerContext: string, tone?: string): Promise<any | null>;
  saveEncouragementTemplate(data: any): Promise<any>;
}

/**
 * In-Memory Database Implementation
 * Used for automated test suites and local development without requiring external database setup.
 */
export class InMemoryLearningDb implements ILearningDb {
  private profiles = new Map<string, any>();
  private progress = new Map<string, any>();
  private streaks = new Map<string, any>();
  private skills = new Map<string, Map<string, any>>();
  private vocabulary = new Map<string, Map<string, any>>();
  private examResults = new Map<string, any[]>();
  private xpTransactions = new Map<string, any[]>();
  private achievements = new Map<string, Map<string, any>>();

  // School stores
  private schools = new Map<string, any>();
  private memberships = new Map<string, any>(); // userId -> membership
  private classrooms = new Map<string, any>(); // classroomId -> classroom
  private classroomStudentsList: any[] = [];
  private dailyTasks = new Map<string, any>(); // taskId -> task
  private gameResults = new Map<string, any[]>(); // studentId -> results
  private subscriptions = new Map<string, any>(); // userId -> subscription
  private aiUsage = new Map<string, any>(); // `${userId}_${usageDate}_${feature}` -> record
  private schoolTutorSessionsList = new Map<string, any>(); // sessionId -> session

  // New Stores for Plans, Exams, Games, Points, and Mistakes
  private plansStore = new Map<string, any>();
  private planDaysStore = new Map<string, any[]>(); // planId -> planDays
  private planActivitiesStore = new Map<string, any[]>(); // planDayId -> activities
  private studentPlanProgressStore = new Map<string, any>(); // `${studentId}_${planId}` -> progress
  private studentActivityLogsStore = new Map<string, any[]>(); // `${studentId}_${planDayId}` -> logs
  private studentCodesStore = new Map<string, any>(); // studentCode or studentId -> codeRecord
  private pointsTransactionsStore = new Map<string, any[]>(); // studentId -> transactions
  private studentMistakesStore = new Map<string, any>(); // `${studentId}_${contentId}` -> mistake
  private examsStore = new Map<string, any>(); // examId -> exam
  private examQuestionsStore = new Map<string, any[]>(); // examId -> questions
  private examSubmissionsStore = new Map<string, any[]>(); // examId -> submissions
  private educationalGamesStore = new Map<string, any>(); // gameId -> game
  private gameQuestionsStore = new Map<string, any[]>(); // gameId -> questions
  private audioAssetsStore = new Map<string, any>(); // id -> asset
  private encouragementTemplatesStore = new Map<string, any>(); // id -> template

  constructor() {
    this.seedInitialData();
  }

  async getProfile(userId: string): Promise<any | null> {
    const profile = this.profiles.get(userId);
    return profile ? { ...profile } : null;
  }

  async upsertProfile(userId: string, data: any): Promise<any> {
    const existing = this.profiles.get(userId) || {};
    const updated = {
      ...existing,
      ...data,
      userId,
      updatedAt: new Date(),
      createdAt: existing.createdAt || new Date(),
    };
    this.profiles.set(userId, updated);
    return { ...updated };
  }

  async getProgress(userId: string): Promise<any | null> {
    const prog = this.progress.get(userId);
    return prog ? { ...prog } : null;
  }

  async upsertProgress(userId: string, data: any): Promise<any> {
    const existing = this.progress.get(userId) || {};
    const updated = {
      ...existing,
      ...data,
      userId,
      updatedAt: new Date(),
    };
    this.progress.set(userId, updated);
    return { ...updated };
  }

  async getStreak(userId: string): Promise<any | null> {
    const s = this.streaks.get(userId);
    return s ? { ...s } : null;
  }

  async upsertStreak(userId: string, data: any): Promise<any> {
    const existing = this.streaks.get(userId) || {};
    const updated = {
      ...existing,
      ...data,
      userId,
      updatedAt: new Date(),
    };
    this.streaks.set(userId, updated);
    return { ...updated };
  }

  async getSkills(userId: string): Promise<any[]> {
    const userSkills = this.skills.get(userId);
    if (!userSkills) return [];
    return Array.from(userSkills.values()).map((s) => ({ ...s }));
  }

  async upsertSkill(
    userId: string,
    skill: string,
    levelScore: number,
    assessedAttempts: number
  ): Promise<any> {
    if (!this.skills.has(userId)) {
      this.skills.set(userId, new Map());
    }
    const userSkills = this.skills.get(userId)!;
    const record = {
      id: `skill_${userId}_${skill}`,
      userId,
      skill,
      levelScore,
      assessedAttempts,
      lastUpdated: new Date(),
    };
    userSkills.set(skill, record);
    return { ...record };
  }

  async getVocabularyList(userId: string): Promise<any[]> {
    const userVocab = this.vocabulary.get(userId);
    if (!userVocab) return [];
    return Array.from(userVocab.values()).map((v) => ({ ...v }));
  }

  async upsertVocabularyProgress(userId: string, vocabData: any): Promise<any> {
    if (!this.vocabulary.has(userId)) {
      this.vocabulary.set(userId, new Map());
    }
    const userVocab = this.vocabulary.get(userId)!;
    const existing = userVocab.get(vocabData.vocabularyId) || {};
    const record = {
      ...existing,
      ...vocabData,
      id: `vocab_${userId}_${vocabData.vocabularyId}`,
      userId,
      updatedAt: new Date(),
    };
    userVocab.set(vocabData.vocabularyId, record);
    return { ...record };
  }

  async getExamResults(userId: string): Promise<any[]> {
    const results = this.examResults.get(userId) || [];
    return results.map((r) => ({ ...r }));
  }

  async saveExamResult(userId: string, result: any): Promise<any> {
    if (!this.examResults.has(userId)) {
      this.examResults.set(userId, []);
    }
    const record = {
      ...result,
      id: result.id || `exam_res_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
      userId,
      completedAt: result.completedAt ? new Date(result.completedAt) : new Date(),
    };
    this.examResults.get(userId)!.unshift(record);
    return { ...record };
  }

  async getXpTransactions(userId: string, limit: number = 50): Promise<any[]> {
    const txs = this.xpTransactions.get(userId) || [];
    return txs.slice(0, limit).map((t) => ({ ...t }));
  }

  async saveXpTransaction(userId: string, transaction: any): Promise<any> {
    if (!this.xpTransactions.has(userId)) {
      this.xpTransactions.set(userId, []);
    }
    const record = {
      ...transaction,
      id: transaction.id || `tx_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
      userId,
      createdAt: transaction.timestamp ? new Date(transaction.timestamp) : new Date(),
    };
    this.xpTransactions.get(userId)!.unshift(record);
    return { ...record };
  }

  async getAchievements(userId: string): Promise<any[]> {
    const userAch = this.achievements.get(userId);
    if (!userAch) return [];
    return Array.from(userAch.values()).map((a) => ({ ...a }));
  }

  async upsertAchievement(
    userId: string,
    achievementId: string,
    isUnlocked: boolean,
    currentValue: number,
    unlockedAt?: Date | null
  ): Promise<any> {
    if (!this.achievements.has(userId)) {
      this.achievements.set(userId, new Map());
    }
    const userAch = this.achievements.get(userId)!;
    const existing = userAch.get(achievementId) || {};
    const record = {
      ...existing,
      id: `ach_${userId}_${achievementId}`,
      userId,
      achievementId,
      isUnlocked,
      currentValue,
      unlockedAt: isUnlocked ? (existing.unlockedAt || unlockedAt || new Date()) : null,
      updatedAt: new Date(),
    };
    userAch.set(achievementId, record);
    return { ...record };
  }

  // School methods
  async getSchool(schoolId: string): Promise<any | null> {
    const s = this.schools.get(schoolId);
    return s ? { ...s } : null;
  }

  async getSchoolByCode(schoolCode: string): Promise<any | null> {
    for (const s of this.schools.values()) {
      if (s.schoolCode === schoolCode) return { ...s };
    }
    return null;
  }

  async createSchool(data: any): Promise<any> {
    const id = data.id || `school_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const record = { ...data, id, createdAt: data.createdAt || new Date() };
    this.schools.set(id, record);
    return { ...record };
  }

  async getSchoolMembership(userId: string): Promise<any | null> {
    const m = this.memberships.get(userId);
    return m ? { ...m } : null;
  }

  async getSchoolMembershipsBySchool(schoolId: string): Promise<any[]> {
    const list: any[] = [];
    for (const m of this.memberships.values()) {
      if (m.schoolId === schoolId) list.push({ ...m });
    }
    return list;
  }

  async upsertSchoolMembership(data: any): Promise<any> {
    const existing = this.memberships.get(data.userId) || {};
    const record = {
      id: data.id || existing.id || `mem_${data.userId}_${data.schoolId}`,
      ...existing,
      ...data,
      createdAt: existing.createdAt || new Date(),
    };
    this.memberships.set(data.userId, record);
    return { ...record };
  }

  async getClassroomsForTeacher(teacherId: string): Promise<any[]> {
    const list: any[] = [];
    for (const c of this.classrooms.values()) {
      if (c.teacherId === teacherId) list.push({ ...c });
    }
    return list;
  }

  async getClassroomsForSchool(schoolId: string): Promise<any[]> {
    const list: any[] = [];
    for (const c of this.classrooms.values()) {
      if (c.schoolId === schoolId) list.push({ ...c });
    }
    return list;
  }

  async getClassroom(classroomId: string): Promise<any | null> {
    const c = this.classrooms.get(classroomId);
    return c ? { ...c } : null;
  }

  async createClassroom(data: any): Promise<any> {
    const id = data.id || `class_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const record = { ...data, id, createdAt: data.createdAt || new Date() };
    this.classrooms.set(id, record);
    return { ...record };
  }

  async getClassroomStudents(classroomId: string): Promise<any[]> {
    return this.classroomStudentsList
      .filter((cs) => cs.classroomId === classroomId)
      .map((cs) => ({ ...cs }));
  }

  async getStudentClassrooms(studentId: string): Promise<any[]> {
    const classroomIds = this.classroomStudentsList
      .filter((cs) => cs.studentId === studentId && cs.status === 'active')
      .map((cs) => cs.classroomId);

    return classroomIds
      .map((id) => this.classrooms.get(id))
      .filter((c) => !!c)
      .map((c) => ({ ...c }));
  }

  async addStudentToClassroom(data: any): Promise<any> {
    const existingIdx = this.classroomStudentsList.findIndex(
      (cs) => cs.classroomId === data.classroomId && cs.studentId === data.studentId
    );
    const record = {
      id: data.id || `cs_${data.classroomId}_${data.studentId}`,
      ...data,
      joinedAt: data.joinedAt || new Date(),
      status: data.status || 'active',
    };
    if (existingIdx >= 0) {
      this.classroomStudentsList[existingIdx] = record;
    } else {
      this.classroomStudentsList.push(record);
    }
    return { ...record };
  }

  async getDailyTasks(studentId: string, taskDate: string): Promise<any[]> {
    const list: any[] = [];
    for (const t of this.dailyTasks.values()) {
      if (t.studentId === studentId && t.taskDate === taskDate) {
        list.push({ ...t });
      }
    }
    return list;
  }

  async saveDailyTasks(tasks: any[]): Promise<any[]> {
    const saved: any[] = [];
    for (const t of tasks) {
      const id = t.id || `task_${t.studentId}_${t.taskDate}_${t.type}`;
      const record = {
        ...t,
        id,
        createdAt: t.createdAt || new Date(),
      };
      this.dailyTasks.set(id, record);
      saved.push({ ...record });
    }
    return saved;
  }

  async getDailyTaskById(taskId: string): Promise<any | null> {
    const t = this.dailyTasks.get(taskId);
    return t ? { ...t } : null;
  }

  async updateDailyTask(taskId: string, updates: any): Promise<any | null> {
    const existing = this.dailyTasks.get(taskId);
    if (!existing) return null;
    const updated = {
      ...existing,
      ...updates,
    };
    this.dailyTasks.set(taskId, updated);
    return { ...updated };
  }

  async saveGameResult(result: any): Promise<any> {
    const studentId = result.studentId;
    if (!this.gameResults.has(studentId)) {
      this.gameResults.set(studentId, []);
    }
    const record = {
      ...result,
      id: result.id || `game_res_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
      completedAt: result.completedAt ? new Date(result.completedAt) : new Date(),
    };
    this.gameResults.get(studentId)!.unshift(record);
    return { ...record };
  }

  async getGameResults(studentId: string, limit: number = 50): Promise<any[]> {
    const list = this.gameResults.get(studentId) || [];
    return list.slice(0, limit).map((r) => ({ ...r }));
  }

  async getSubscription(userId: string): Promise<any | null> {
    const sub = this.subscriptions.get(userId);
    return sub ? { ...sub } : null;
  }

  async upsertSubscription(data: any): Promise<any> {
    const userId = data.userId;
    const existing = this.subscriptions.get(userId) || {};
    const record = {
      ...existing,
      ...data,
      id: data.id || existing.id || `sub_${userId}`,
      updatedAt: new Date(),
      createdAt: existing.createdAt || data.createdAt || new Date(),
    };
    this.subscriptions.set(userId, record);
    return { ...record };
  }

  async recordAiUsage(data: {
    userId: string;
    usageDate: string;
    feature: string;
    modelUsed: string;
    inputTokens: number;
    outputTokens: number;
    voiceSeconds?: number;
    cachedResponsesCount?: number;
  }): Promise<any> {
    const key = `${data.userId}_${data.usageDate}_${data.feature}`;
    const existing = this.aiUsage.get(key) || {
      id: `usage_${data.userId}_${data.usageDate}_${data.feature}`,
      userId: data.userId,
      usageDate: data.usageDate,
      feature: data.feature,
      modelUsed: data.modelUsed,
      requestCount: 0,
      inputTokens: 0,
      outputTokens: 0,
      voiceSeconds: 0,
      cachedResponsesCount: 0,
      createdAt: new Date(),
    };

    const updated = {
      ...existing,
      modelUsed: data.modelUsed,
      requestCount: existing.requestCount + 1,
      inputTokens: existing.inputTokens + data.inputTokens,
      outputTokens: existing.outputTokens + data.outputTokens,
      voiceSeconds: existing.voiceSeconds + (data.voiceSeconds || 0),
      cachedResponsesCount: existing.cachedResponsesCount + (data.cachedResponsesCount || 0),
      updatedAt: new Date(),
    };
    this.aiUsage.set(key, updated);
    return { ...updated };
  }

  async getDailyAiUsage(userId: string, usageDate: string): Promise<any[]> {
    const records = Array.from(this.aiUsage.values()).filter(
      (r) => r.userId === userId && r.usageDate === usageDate
    );
    return records.map((r) => ({ ...r }));
  }

  async getTotalDailyAiTokens(userId: string, usageDate: string): Promise<{
    totalInputTokens: number;
    totalOutputTokens: number;
    totalTokens: number;
    totalRequests: number;
    totalVoiceSeconds: number;
  }> {
    const records = await this.getDailyAiUsage(userId, usageDate);
    const totalInputTokens = records.reduce((sum, r) => sum + (r.inputTokens || 0), 0);
    const totalOutputTokens = records.reduce((sum, r) => sum + (r.outputTokens || 0), 0);
    const totalRequests = records.reduce((sum, r) => sum + (r.requestCount || 0), 0);
    const totalVoiceSeconds = records.reduce((sum, r) => sum + (r.voiceSeconds || 0), 0);
    return {
      totalInputTokens,
      totalOutputTokens,
      totalTokens: totalInputTokens + totalOutputTokens,
      totalRequests,
      totalVoiceSeconds,
    };
  }

  async getStudentDailyTutorSessions(studentId: string, date: string): Promise<any[]> {
    const list: any[] = [];
    for (const s of this.schoolTutorSessionsList.values()) {
      if (s.studentId === studentId && s.sessionDate === date) {
        list.push({ ...s });
      }
    }
    return list.sort((a, b) => (a.sessionNumber || 0) - (b.sessionNumber || 0));
  }

  async saveStudentTutorSession(session: any): Promise<any> {
    const id = session.id || `sess_${session.studentId}_${session.sessionDate}_${session.sessionNumber}`;
    const record = {
      ...session,
      id,
      startedAt: session.startedAt || new Date(),
    };
    this.schoolTutorSessionsList.set(id, record);
    return { ...record };
  }

  async updateStudentTutorSession(sessionId: string, updates: any): Promise<any> {
    const existing = this.schoolTutorSessionsList.get(sessionId);
    if (!existing) return null;
    const updated = {
      ...existing,
      ...updates,
    };
    this.schoolTutorSessionsList.set(sessionId, updated);
    return { ...updated };
  }

  // --- Seed Initial Data ---
  private seedInitialData(): void {
    // 1. Initial Standard Plans
    const standardPlans = [
      {
        id: 'plan_conversation_60',
        titleAr: 'خطة إتقان المحادثة باللغة الإنجليزية',
        titleEn: 'English Conversation Mastery (60 Days)',
        descriptionAr: 'خطة مكثفة وممتعة مدتها 60 يوماً تركز على بناء الثقة بالنفس، إتقان التراكيب التلقائية، والمحادثات اليومية الواقعية دون تردد.',
        category: 'conversation',
        targetGoal: 'conversationFluency',
        targetAgeGroup: 'youth_and_adults',
        targetLevel: 'intermediate',
        durationDays: 60,
        totalLessons: 60,
        badgeRewardId: 'badge_master_speaker',
        isActive: true,
      },
      {
        id: 'plan_interviews_60',
        titleAr: 'خطة مقابلات العمل Job Interviews',
        titleEn: 'Job Interviews Preparation Plan',
        descriptionAr: 'تأهيلك لاجتياز المقابلات الوظيفية بالإنجليزية، التعريف بالنفس، الإجابة على الأسئلة السلوكية، والتفاوض بثقة.',
        category: 'job_interview',
        targetGoal: 'careerAdvancement',
        targetAgeGroup: 'adults_21_plus',
        targetLevel: 'intermediate',
        durationDays: 60,
        totalLessons: 60,
        badgeRewardId: 'badge_interview_pro',
        isActive: true,
      },
      {
        id: 'plan_travel_60',
        titleAr: 'خطة السفر واستكشاف العالم Travel English',
        titleEn: 'Travel and Global Communication Plan',
        descriptionAr: 'دليلك الشامل للتنقل، حجز الفنادق، طلب الطعام، التعامل في المطارات، والمواقف الطارئة أثناء السفر بكل سهولة.',
        category: 'travel',
        targetGoal: 'travelAndTourism',
        targetAgeGroup: 'all',
        targetLevel: 'beginner',
        durationDays: 60,
        totalLessons: 60,
        badgeRewardId: 'badge_world_traveler',
        isActive: true,
      },
      {
        id: 'plan_school_curriculum',
        titleAr: 'خطة اللغة الإنجليزية المدرسية لرفع التحصيل',
        titleEn: 'School Curriculum Excellence Plan',
        descriptionAr: 'منهج داعم للمناهج المدرسية، يركز على القواعد الأساسية، تكوين الجمل، الفهم والاستيعاب، وحل نماذج الاختبارات.',
        category: 'school',
        targetGoal: 'schoolExcellence',
        targetAgeGroup: 'teens_11_15',
        targetLevel: 'elementary',
        durationDays: 60,
        totalLessons: 60,
        badgeRewardId: 'badge_top_student',
        isActive: true,
      },
      {
        id: 'plan_kids_foundations',
        titleAr: 'خطة التأسيس الممتع للأطفال',
        titleEn: 'Kids English Fun Foundations',
        descriptionAr: 'رحلة تفاعلية مليئة بالألوان والأصوات اللطيفة والألعاب لتعليم الأطفال الحروف والكلمات الأولى والنطق الصحيح.',
        category: 'kids',
        targetGoal: 'kidsFoundation',
        targetAgeGroup: 'kids_6_10',
        targetLevel: 'beginner',
        durationDays: 60,
        totalLessons: 60,
        badgeRewardId: 'badge_young_explorer',
        isActive: true,
      },
    ];

    for (const p of standardPlans) {
      this.plansStore.set(p.id, { ...p, createdAt: new Date(), updatedAt: new Date() });
    }

    // Seed plan_60_days_intensive as the primary intensive conversation plan
    const intensivePlan = {
      ...standardPlans[0],
      id: 'plan_60_days_intensive',
      titleAr: 'خطة إتقان المحادثة باللغة الإنجليزية (60 يوماً)',
    };
    this.plansStore.set('plan_60_days_intensive', { ...intensivePlan, createdAt: new Date(), updatedAt: new Date() });

    // 2. Seed Days & Micro-Activities for Conversation Plan (Day 1 & Day 2)
    const convDay1 = {
      id: 'day_conv_1',
      planId: 'plan_conversation_60',
      dayNumber: 1,
      titleAr: 'اليوم الأول: كسر الجليد والتحيات الطبيعية',
      descriptionAr: 'نتعلم كيف نحيي الآخرين بأسلوب عفوي وطبيعي وكيف نبدأ حواراً قصيراً بودية.',
      focusTopic: 'Natural Greetings & Introductions',
      totalXpReward: 80,
      createdAt: new Date(),
    };
    const convDay2 = {
      id: 'day_conv_2',
      planId: 'plan_conversation_60',
      dayNumber: 2,
      titleAr: 'اليوم الثاني: السؤال عن الحال والأخبار',
      descriptionAr: 'عبارات بديلة لـ How are you وكيف تجيب بطريقة حيوية وممتعة.',
      focusTopic: 'How are you & Daily Small Talk',
      totalXpReward: 80,
      createdAt: new Date(),
    };
    this.planDaysStore.set('plan_conversation_60', [convDay1, convDay2]);
    this.planDaysStore.set('plan_60_days_intensive', [
      { ...convDay1, id: 'day_intensive_1', planId: 'plan_60_days_intensive' },
      { ...convDay2, id: 'day_intensive_2', planId: 'plan_60_days_intensive' },
    ]);

    // 3. Seed 9 Structured Micro-Activities for Day 1
    const day1Activities = [
      {
        id: 'act_conv_1_1',
        planDayId: 'day_conv_1',
        stepOrder: 1,
        activityType: 'quick_review',
        titleAr: 'مراجعة سريعة: مرحباً بك في رحلتك',
        contentPayload: { textAr: 'تذكير: الهدف هو الاستمرارية والحديث بثقة وليس الحفظ المجرد.' },
        audioAssetId: 'audio_welcome_tip',
        xpReward: 5,
      },
      {
        id: 'act_conv_1_2',
        planDayId: 'day_conv_1',
        stepOrder: 2,
        activityType: 'new_vocabulary',
        titleAr: 'كلمات اليوم: 3 عبارات تحية عصرية',
        contentPayload: {
          words: [
            { en: 'Hey there', ar: 'مرحباً (عفوية وودودة)', audio: 'audio_hey_there' },
            { en: 'Nice to meet you', ar: 'تشرفت بلقائك', audio: 'audio_nice_meet' },
            { en: 'How is it going?', ar: 'كيف تسير الأمور معك؟', audio: 'audio_how_going' },
          ],
        },
        xpReward: 10,
      },
      {
        id: 'act_conv_1_3',
        planDayId: 'day_conv_1',
        stepOrder: 3,
        activityType: 'listening',
        titleAr: 'استماع: حوار قصير في المقهى',
        contentPayload: {
          audioUrl: 'https://assets.lahjti.com/audio/dialogue_cafe_intro.mp3',
          questionAr: 'أين التقى الصديقان؟',
          options: ['في المقهى', 'في المطار', 'في الجامعة'],
          correctOptionIndex: 0,
        },
        xpReward: 10,
      },
      {
        id: 'act_conv_1_4',
        planDayId: 'day_conv_1',
        stepOrder: 4,
        activityType: 'dialogue',
        titleAr: 'محادثة تدريبية: دورك للتحدث',
        contentPayload: {
          partnerPromptEn: "Hey there! Nice to meet you. I'm Alex.",
          suggestedResponseEn: 'Nice to meet you too Alex! My name is...',
        },
        xpReward: 10,
      },
      {
        id: 'act_conv_1_5',
        planDayId: 'day_conv_1',
        stepOrder: 5,
        activityType: 'grammar_bite',
        titleAr: 'قاعدة اليوم البسيطة: استخدام I am و You are',
        contentPayload: {
          ruleTitle: 'فعل الكينونة للتعريف بالنفس',
          explanationAr: 'نستخدم I am لتقديم الاسم، ويمكن اختصارها إلى I\'m لنبدو أكثر طبيعية.',
          examples: ["I'm Sarah", "You're welcome"],
        },
        xpReward: 10,
      },
      {
        id: 'act_conv_1_6',
        planDayId: 'day_conv_1',
        stepOrder: 6,
        activityType: 'pronunciation_drill',
        titleAr: 'تدريب نطق: مخارج حروف التحية',
        contentPayload: {
          targetPhraseEn: "Nice to meet you",
          phoneticHint: "نايس تو ميت يو - وصل الصوت بين t و y بنعومة",
        },
        xpReward: 10,
      },
      {
        id: 'act_conv_1_7',
        planDayId: 'day_conv_1',
        stepOrder: 7,
        activityType: 'mini_game',
        titleAr: 'لعبة ترتيب الكلمات: تكوين التحية الصحيحة',
        contentPayload: {
          scrambledWords: ['meet', 'Nice', 'you', 'to'],
          correctOrder: ['Nice', 'to', 'meet', 'you'],
        },
        xpReward: 10,
      },
      {
        id: 'act_conv_1_8',
        planDayId: 'day_conv_1',
        stepOrder: 8,
        activityType: 'quick_quiz',
        titleAr: 'اختبار سريع (3 أسئلة لتأكيد الفهم)',
        contentPayload: {
          questions: [
            {
              question: "What is the most natural reply to 'Nice to meet you'?",
              options: ['Nice to meet you too', 'Yes, goodbye', 'I am 20 years old'],
              correctAnswer: 'Nice to meet you too',
            },
            {
              question: "Complete: I _____ excited to learn English today!",
              options: ['am', 'is', 'are'],
              correctAnswer: 'am',
            },
          ],
        },
        xpReward: 10,
      },
      {
        id: 'act_conv_1_9',
        planDayId: 'day_conv_1',
        stepOrder: 9,
        activityType: 'day_summary',
        titleAr: 'نتيجة اليوم والنقاط المكتسبة 🔥',
        contentPayload: {
          summaryTitleAr: 'رائع جداً! أكملت اليوم الأول بنجاح.',
          pointsEarned: 80,
          encouragementAr: 'خطوت أول خطوة في خطة الـ 60 يوماً. موعدنا غداً مع اليوم الثاني!',
        },
        xpReward: 5,
      },
    ];
    this.planActivitiesStore.set('day_conv_1', day1Activities);
    this.planActivitiesStore.set(
      'day_intensive_1',
      day1Activities.map((a) => ({ ...a, id: a.id.replace('conv', 'intensive'), planDayId: 'day_intensive_1' }))
    );

    // 4. Seed Encouragement Templates
    const templates = [
      { id: 'enc_1', triggerContext: 'day_start', tone: 'warm_friendly', messageAr: 'أهلاً بك 👋 جاهز لمغامرة اليوم؟ لنكتشف كلمات ومحادثات ممتعة معاً!' },
      { id: 'enc_2', triggerContext: 'streak_milestone', tone: 'warm_friendly', messageAr: 'رائع يا بطل! 🔥 حافظت على استمراريتك اليومية، التزامك يصنع الفرق الحقيقي!' },
      { id: 'enc_3', triggerContext: 'high_score', tone: 'warm_friendly', messageAr: 'ممتاز جداً! 🌟 إجاباتك دقيقة وحصلت على العلامة الكاملة.' },
      { id: 'enc_4', triggerContext: 'after_mistake', tone: 'warm_friendly', messageAr: 'لا بأس أبداً، الخطأ هو أول خطوة لنتعلم بشكل صحيح! سنراجعها معاً لاحقاً 💪' },
      { id: 'enc_5', triggerContext: 'day_complete', tone: 'warm_friendly', messageAr: 'ألف مبروك! 🎉 أنهيت جميع أنشطة اليوم وحصلت على كامل النقاط.' },
    ];
    for (const t of templates) {
      this.encouragementTemplatesStore.set(t.id, t);
    }

    // 5. Seed Pre-recorded Audio Assets
    const audios = [
      {
        id: 'audio_hey_there',
        category: 'word_pronunciation',
        textContent: 'Hey there',
        accent: 'american',
        audioUrl: 'https://assets.lahjti.com/audio/hey_there.mp3',
        speakerName: 'Teacher Abbas',
        durationSeconds: 1.2,
      },
      {
        id: 'audio_nice_meet',
        category: 'word_pronunciation',
        textContent: 'Nice to meet you',
        accent: 'american',
        audioUrl: 'https://assets.lahjti.com/audio/nice_to_meet_you.mp3',
        speakerName: 'Teacher Abbas',
        durationSeconds: 1.5,
      },
      {
        id: 'audio_how_going',
        category: 'sentence_audio',
        textContent: 'How is it going?',
        accent: 'american',
        audioUrl: 'https://assets.lahjti.com/audio/how_is_it_going.mp3',
        speakerName: 'Teacher Abbas',
        durationSeconds: 1.4,
      },
      {
        id: 'audio_welcome_tip',
        category: 'instructions',
        textContent: 'Welcome to your 60-day journey',
        accent: 'american',
        audioUrl: 'https://assets.lahjti.com/audio/welcome_tip.mp3',
        speakerName: 'Teacher Abbas',
        durationSeconds: 3.5,
      },
    ];
    for (const a of audios) {
      this.audioAssetsStore.set(a.id, a);
    }
  }

  // --- Plans & 60-Day Path Implementation ---
  async getPlans(filters?: { category?: string; targetAgeGroup?: string; targetLevel?: string }): Promise<any[]> {
    let list = Array.from(this.plansStore.values()).filter((p) => p.isActive !== false);
    if (filters?.category) {
      list = list.filter((p) => p.category === filters.category);
    }
    if (filters?.targetAgeGroup && filters.targetAgeGroup !== 'all') {
      list = list.filter((p) => p.targetAgeGroup === filters.targetAgeGroup || p.targetAgeGroup === 'all');
    }
    if (filters?.targetLevel) {
      list = list.filter((p) => p.targetLevel === filters.targetLevel);
    }
    return list;
  }

  async getPlanById(planId: string): Promise<any | null> {
    const plan = this.plansStore.get(planId);
    return plan ? { ...plan } : null;
  }

  async savePlan(plan: any): Promise<any> {
    const id = plan.id || `plan_${Date.now()}`;
    const record = {
      ...plan,
      id,
      createdAt: plan.createdAt || new Date(),
      updatedAt: new Date(),
    };
    this.plansStore.set(id, record);
    return { ...record };
  }

  async getPlanDays(planId: string): Promise<any[]> {
    const days = this.planDaysStore.get(planId) || [];
    return [...days].sort((a, b) => a.dayNumber - b.dayNumber);
  }

  async getPlanDay(planId: string, dayNumber: number): Promise<any | null> {
    const days = this.planDaysStore.get(planId) || [];
    const found = days.find((d) => d.dayNumber === dayNumber);
    return found ? { ...found } : null;
  }

  async savePlanDays(days: any[]): Promise<any[]> {
    for (const d of days) {
      const existing = this.planDaysStore.get(d.planId) || [];
      const filtered = existing.filter((item) => item.dayNumber !== d.dayNumber);
      filtered.push(d);
      this.planDaysStore.set(d.planId, filtered);
    }
    return days;
  }

  async getPlanActivities(planDayId: string): Promise<any[]> {
    const acts = this.planActivitiesStore.get(planDayId) || [];
    return [...acts].sort((a, b) => a.stepOrder - b.stepOrder);
  }

  async savePlanActivities(activities: any[]): Promise<any[]> {
    for (const a of activities) {
      const existing = this.planActivitiesStore.get(a.planDayId) || [];
      const filtered = existing.filter((item) => item.id !== a.id);
      filtered.push(a);
      this.planActivitiesStore.set(a.planDayId, filtered);
    }
    return activities;
  }

  async getStudentPlanProgress(studentId: string, planId: string): Promise<any | null> {
    const key = `${studentId}_${planId}`;
    const progress = this.studentPlanProgressStore.get(key);
    return progress ? { ...progress } : null;
  }

  async upsertStudentPlanProgress(studentId: string, planId: string, data: any): Promise<any> {
    const key = `${studentId}_${planId}`;
    const existing = this.studentPlanProgressStore.get(key) || {
      id: `spp_${studentId}_${planId}`,
      studentId,
      planId,
      currentDay: 1,
      completedDays: 0,
      status: 'active',
      startedAt: new Date(),
    };
    const updated = {
      ...existing,
      ...data,
      lastActivityAt: new Date(),
    };
    this.studentPlanProgressStore.set(key, updated);
    return { ...updated };
  }

  async recordStudentActivity(data: any): Promise<any> {
    const record = {
      ...data,
      id: data.id || `actlog_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
      completedAt: new Date(),
    };
    const key = `${data.studentId}_${data.planDayId}`;
    const list = this.studentActivityLogsStore.get(key) || [];
    const filtered = list.filter((l) => l.activityId !== data.activityId);
    filtered.push(record);
    this.studentActivityLogsStore.set(key, filtered);
    return { ...record };
  }

  async getStudentActivityLogs(studentId: string, planDayId: string): Promise<any[]> {
    const key = `${studentId}_${planDayId}`;
    return this.studentActivityLogsStore.get(key) || [];
  }

  // --- Student Codes & PIN Auth Implementation ---
  async getStudentCodeByCode(code: string): Promise<any | null> {
    const trimmed = code.trim().toUpperCase();
    for (const c of this.studentCodesStore.values()) {
      if (c.studentCode === trimmed) return { ...c };
    }
    return null;
  }

  async getStudentCodeByStudentId(studentId: string): Promise<any | null> {
    const found = this.studentCodesStore.get(`user_${studentId}`) || this.studentCodesStore.get(studentId);
    if (found) return { ...found };
    for (const c of this.studentCodesStore.values()) {
      if (c.studentId === studentId) return { ...c };
    }
    return null;
  }

  async saveStudentCode(data: any): Promise<any> {
    const record = {
      ...data,
      id: data.id || `sc_${Date.now()}`,
      studentCode: data.studentCode.trim().toUpperCase(),
      createdAt: data.createdAt || new Date(),
      updatedAt: new Date(),
    };
    this.studentCodesStore.set(record.studentCode, record);
    this.studentCodesStore.set(`user_${record.studentId}`, record);
    return { ...record };
  }

  // --- Points Transactions Implementation (Server-authoritative) ---
  async recordPointsTransaction(data: {
    studentId: string;
    amount: number;
    reasonCode: string;
    descriptionAr: string;
    referenceId?: string;
  }): Promise<any> {
    const tx = {
      ...data,
      id: `ptx_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
      createdAt: new Date(),
    };
    const list = this.pointsTransactionsStore.get(data.studentId) || [];
    list.unshift(tx);
    this.pointsTransactionsStore.set(data.studentId, list);

    // Also increment user progress totalXp to keep synced
    const prog = await this.getProgress(data.studentId);
    if (prog) {
      await this.upsertProgress(data.studentId, {
        totalXp: (prog.totalXp || 0) + data.amount,
      });
    }
    return { ...tx };
  }

  async getPointsTransactions(studentId: string, limit: number = 50): Promise<any[]> {
    const list = this.pointsTransactionsStore.get(studentId) || [];
    return list.slice(0, limit);
  }

  // --- Student Mistakes & Spaced Repetition Implementation ---
  async recordStudentMistake(data: {
    studentId: string;
    contentId: string;
    skillType: string;
    itemPrompt: string;
    correctAnswer: string;
    studentLastWrongAnswer?: string;
  }): Promise<any> {
    const key = `${data.studentId}_${data.contentId}`;
    const existing = this.studentMistakesStore.get(key);
    const mistakeCount = (existing?.mistakeCount || 0) + 1;
    const nextReview = new Date(); // Immediately available for student review

    const record = {
      id: existing?.id || `smist_${Date.now()}`,
      ...data,
      mistakeCount,
      intervalDays: 1,
      easeFactor: Math.max(1.3, (existing?.easeFactor || 2.5) - 0.2),
      repetitions: 0,
      mastered: false,
      lastMistakeAt: new Date(),
      nextReviewAt: nextReview,
    };
    this.studentMistakesStore.set(key, record);
    return { ...record };
  }

  async getStudentMistakesDue(studentId: string, limit: number = 20): Promise<any[]> {
    const now = new Date();
    const list: any[] = [];
    for (const m of this.studentMistakesStore.values()) {
      if (m.studentId === studentId && !m.mastered && new Date(m.nextReviewAt) <= now) {
        list.push({ ...m });
      }
    }
    return list.slice(0, limit);
  }

  async updateStudentMistakeReview(studentId: string, contentId: string, wasCorrect: boolean): Promise<any> {
    const key = `${studentId}_${contentId}`;
    const m = this.studentMistakesStore.get(key);
    if (!m) return null;

    if (wasCorrect) {
      const repetitions = (m.repetitions || 0) + 1;
      const easeFactor = Math.min(3.0, (m.easeFactor || 2.5) + 0.1);
      const intervalDays = repetitions === 1 ? 2 : repetitions === 2 ? 6 : Math.round((m.intervalDays || 1) * easeFactor);
      const mastered = repetitions >= 4;
      const nextReviewAt = new Date(Date.now() + intervalDays * 24 * 60 * 60 * 1000);

      const updated = {
        ...m,
        repetitions,
        easeFactor,
        intervalDays,
        mastered,
        nextReviewAt,
      };
      this.studentMistakesStore.set(key, updated);
      return { ...updated };
    } else {
      const updated = {
        ...m,
        repetitions: 0,
        intervalDays: 1,
        mistakeCount: (m.mistakeCount || 1) + 1,
        mastered: false,
        lastMistakeAt: new Date(),
        nextReviewAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
      };
      this.studentMistakesStore.set(key, updated);
      return { ...updated };
    }
  }

  // --- Teacher Exams Implementation ---
  async getExamsForClassroom(classroomId: string): Promise<any[]> {
    const list: any[] = [];
    for (const e of this.examsStore.values()) {
      if (e.classroomId === classroomId || !e.classroomId) {
        list.push({ ...e });
      }
    }
    return list.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
  }

  async getExamsForTeacher(teacherId: string): Promise<any[]> {
    const list: any[] = [];
    for (const e of this.examsStore.values()) {
      if (e.teacherId === teacherId) list.push({ ...e });
    }
    return list.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
  }

  async getExamById(examId: string): Promise<any | null> {
    const exam = this.examsStore.get(examId);
    return exam ? { ...exam } : null;
  }

  async saveExam(data: any): Promise<any> {
    const id = data.id || `exam_${Date.now()}`;
    const record = {
      ...data,
      id,
      createdAt: data.createdAt || new Date(),
      updatedAt: new Date(),
    };
    this.examsStore.set(id, record);
    return { ...record };
  }

  async getExamQuestions(examId: string): Promise<any[]> {
    const list = this.examQuestionsStore.get(examId) || [];
    return [...list].sort((a, b) => a.questionOrder - b.questionOrder);
  }

  async saveExamQuestions(questions: any[]): Promise<any[]> {
    if (!questions || questions.length === 0) return [];
    const examId = questions[0].examId;
    this.examQuestionsStore.set(examId, questions);
    return questions;
  }

  async submitExam(submission: any): Promise<any> {
    const id = submission.id || `sub_${Date.now()}`;
    const record = {
      ...submission,
      id,
      submittedAt: new Date(),
    };
    const list = this.examSubmissionsStore.get(submission.examId) || [];
    const filtered = list.filter((s) => s.studentId !== submission.studentId);
    filtered.push(record);
    this.examSubmissionsStore.set(submission.examId, filtered);
    return { ...record };
  }

  async getExamSubmissions(examId: string): Promise<any[]> {
    return this.examSubmissionsStore.get(examId) || [];
  }

  async getStudentExamSubmission(examId: string, studentId: string): Promise<any | null> {
    const list = this.examSubmissionsStore.get(examId) || [];
    const found = list.find((s) => s.studentId === studentId);
    return found ? { ...found } : null;
  }

  // --- Educational Games Hub Implementation ---
  async getEducationalGames(filters?: { targetAgeGroup?: string; difficulty?: string; classroomId?: string }): Promise<any[]> {
    let list = Array.from(this.educationalGamesStore.values()).filter((g) => g.isActive !== false);
    if (filters?.targetAgeGroup && filters.targetAgeGroup !== 'all') {
      list = list.filter((g) => g.targetAgeGroup === filters.targetAgeGroup || g.targetAgeGroup === 'all');
    }
    if (filters?.difficulty) {
      list = list.filter((g) => g.difficulty === filters.difficulty);
    }
    if (filters?.classroomId) {
      list = list.filter((g) => !g.classroomId || g.classroomId === filters.classroomId);
    }
    return list;
  }

  async getEducationalGameById(gameId: string): Promise<any | null> {
    const g = this.educationalGamesStore.get(gameId);
    return g ? { ...g } : null;
  }

  async saveEducationalGame(data: any): Promise<any> {
    const id = data.id || `game_${Date.now()}`;
    const record = {
      ...data,
      id,
      createdAt: data.createdAt || new Date(),
    };
    this.educationalGamesStore.set(id, record);
    return { ...record };
  }

  async getGameQuestions(gameId: string): Promise<any[]> {
    return this.gameQuestionsStore.get(gameId) || [];
  }

  async saveGameQuestions(questions: any[]): Promise<any[]> {
    if (!questions || questions.length === 0) return [];
    const gameId = questions[0].gameId;
    this.gameQuestionsStore.set(gameId, questions);
    return questions;
  }

  // --- Audio Assets & Encouragement Templates Implementation ---
  async getAudioAssets(category?: string): Promise<any[]> {
    const list = Array.from(this.audioAssetsStore.values());
    if (category) return list.filter((a) => a.category === category);
    return list;
  }

  async findAudioAssetByText(text: string, category?: string): Promise<any | null> {
    const clean = text.trim().toLowerCase();
    for (const a of this.audioAssetsStore.values()) {
      if (a.textContent.trim().toLowerCase() === clean) {
        if (!category || a.category === category) return { ...a };
      }
    }
    return null;
  }

  async saveAudioAsset(data: any): Promise<any> {
    const id = data.id || `audio_${Date.now()}`;
    const record = {
      ...data,
      id,
      createdAt: new Date(),
    };
    this.audioAssetsStore.set(id, record);
    return { ...record };
  }

  async getEncouragementTemplate(triggerContext: string, tone?: string): Promise<any | null> {
    const list = Array.from(this.encouragementTemplatesStore.values()).filter(
      (t) => t.triggerContext === triggerContext
    );
    if (list.length === 0) return null;
    if (tone) {
      const match = list.find((t) => t.tone === tone);
      if (match) return { ...match };
    }
    return { ...list[Math.floor(Math.random() * list.length)] };
  }

  async saveEncouragementTemplate(data: any): Promise<any> {
    const id = data.id || `enc_${Date.now()}`;
    const record = { ...data, id };
    this.encouragementTemplatesStore.set(id, record);
    return { ...record };
  }
}


/**
 * PostgreSQL Database Implementation using Drizzle ORM
 */
export class PgLearningDb implements ILearningDb {
  private db: ReturnType<typeof drizzle>;

  constructor(pool: pg.Pool) {
    this.db = drizzle(pool, { schema });
  }

  async getProfile(userId: string): Promise<any | null> {
    const res = await this.db
      .select()
      .from(schema.learningProfiles)
      .where(eq(schema.learningProfiles.userId, userId));
    return res[0] || null;
  }

  async upsertProfile(userId: string, data: any): Promise<any> {
    const res = await this.db
      .insert(schema.learningProfiles)
      .values({ ...data, userId, updatedAt: new Date() })
      .onConflictDoUpdate({
        target: schema.learningProfiles.userId,
        set: { ...data, updatedAt: new Date() },
      })
      .returning();
    return res[0];
  }

  async getProgress(userId: string): Promise<any | null> {
    const res = await this.db
      .select()
      .from(schema.learnerProgress)
      .where(eq(schema.learnerProgress.userId, userId));
    return res[0] || null;
  }

  async upsertProgress(userId: string, data: any): Promise<any> {
    const res = await this.db
      .insert(schema.learnerProgress)
      .values({ ...data, userId, updatedAt: new Date() })
      .onConflictDoUpdate({
        target: schema.learnerProgress.userId,
        set: { ...data, updatedAt: new Date() },
      })
      .returning();
    return res[0];
  }

  async getStreak(userId: string): Promise<any | null> {
    const res = await this.db
      .select()
      .from(schema.learnerStreaks)
      .where(eq(schema.learnerStreaks.userId, userId));
    return res[0] || null;
  }

  async upsertStreak(userId: string, data: any): Promise<any> {
    const res = await this.db
      .insert(schema.learnerStreaks)
      .values({ ...data, userId, updatedAt: new Date() })
      .onConflictDoUpdate({
        target: schema.learnerStreaks.userId,
        set: { ...data, updatedAt: new Date() },
      })
      .returning();
    return res[0];
  }

  async getSkills(userId: string): Promise<any[]> {
    return await this.db
      .select()
      .from(schema.learnerSkillProgress)
      .where(eq(schema.learnerSkillProgress.userId, userId));
  }

  async upsertSkill(
    userId: string,
    skill: string,
    levelScore: number,
    assessedAttempts: number
  ): Promise<any> {
    const res = await this.db
      .insert(schema.learnerSkillProgress)
      .values({
        id: `skill_${userId}_${skill}`,
        userId,
        skill,
        levelScore,
        assessedAttempts,
        lastUpdated: new Date(),
      })
      .onConflictDoUpdate({
        target: [schema.learnerSkillProgress.userId, schema.learnerSkillProgress.skill],
        set: { levelScore, assessedAttempts, lastUpdated: new Date() },
      })
      .returning();
    return res[0];
  }

  async getVocabularyList(userId: string): Promise<any[]> {
    return await this.db
      .select()
      .from(schema.learnerVocabularyProgress)
      .where(eq(schema.learnerVocabularyProgress.userId, userId));
  }

  async upsertVocabularyProgress(userId: string, vocabData: any): Promise<any> {
    const res = await this.db
      .insert(schema.learnerVocabularyProgress)
      .values({
        ...vocabData,
        id: `vocab_${userId}_${vocabData.vocabularyId}`,
        userId,
        updatedAt: new Date(),
      })
      .onConflictDoUpdate({
        target: [schema.learnerVocabularyProgress.userId, schema.learnerVocabularyProgress.vocabularyId],
        set: { ...vocabData, updatedAt: new Date() },
      })
      .returning();
    return res[0];
  }

  async getExamResults(userId: string): Promise<any[]> {
    return await this.db
      .select()
      .from(schema.learnerExamResults)
      .where(eq(schema.learnerExamResults.userId, userId))
      .orderBy(desc(schema.learnerExamResults.completedAt));
  }

  async saveExamResult(userId: string, result: any): Promise<any> {
    const res = await this.db
      .insert(schema.learnerExamResults)
      .values({
        ...result,
        id: result.id || `exam_res_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
        userId,
        completedAt: result.completedAt ? new Date(result.completedAt) : new Date(),
      })
      .returning();
    return res[0];
  }

  async getXpTransactions(userId: string, limit: number = 50): Promise<any[]> {
    return await this.db
      .select()
      .from(schema.learnerXpTransactions)
      .where(eq(schema.learnerXpTransactions.userId, userId))
      .orderBy(desc(schema.learnerXpTransactions.createdAt))
      .limit(limit);
  }

  async saveXpTransaction(userId: string, transaction: any): Promise<any> {
    const res = await this.db
      .insert(schema.learnerXpTransactions)
      .values({
        ...transaction,
        id: transaction.id || `tx_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
        userId,
        createdAt: transaction.timestamp ? new Date(transaction.timestamp) : new Date(),
      })
      .returning();
    return res[0];
  }

  async getAchievements(userId: string): Promise<any[]> {
    return await this.db
      .select()
      .from(schema.learnerAchievements)
      .where(eq(schema.learnerAchievements.userId, userId));
  }

  async upsertAchievement(
    userId: string,
    achievementId: string,
    isUnlocked: boolean,
    currentValue: number,
    unlockedAt?: Date | null
  ): Promise<any> {
    const res = await this.db
      .insert(schema.learnerAchievements)
      .values({
        id: `ach_${userId}_${achievementId}`,
        userId,
        achievementId,
        isUnlocked,
        currentValue,
        unlockedAt: isUnlocked ? (unlockedAt || new Date()) : null,
        updatedAt: new Date(),
      })
      .onConflictDoUpdate({
        target: [schema.learnerAchievements.userId, schema.learnerAchievements.achievementId],
        set: {
          isUnlocked,
          currentValue,
          unlockedAt: isUnlocked ? (unlockedAt || new Date()) : null,
          updatedAt: new Date(),
        },
      })
      .returning();
    return res[0];
  }

  // School methods
  async getSchool(schoolId: string): Promise<any | null> {
    const res = await this.db
      .select()
      .from(schema.schools)
      .where(eq(schema.schools.id, schoolId));
    return res[0] || null;
  }

  async getSchoolByCode(schoolCode: string): Promise<any | null> {
    const res = await this.db
      .select()
      .from(schema.schools)
      .where(eq(schema.schools.schoolCode, schoolCode));
    return res[0] || null;
  }

  async createSchool(data: any): Promise<any> {
    const id = data.id || `school_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const res = await this.db
      .insert(schema.schools)
      .values({ ...data, id, createdAt: data.createdAt || new Date() })
      .returning();
    return res[0];
  }

  async getSchoolMembership(userId: string): Promise<any | null> {
    const res = await this.db
      .select()
      .from(schema.schoolMemberships)
      .where(eq(schema.schoolMemberships.userId, userId));
    return res[0] || null;
  }

  async getSchoolMembershipsBySchool(schoolId: string): Promise<any[]> {
    return await this.db
      .select()
      .from(schema.schoolMemberships)
      .where(eq(schema.schoolMemberships.schoolId, schoolId));
  }

  async upsertSchoolMembership(data: any): Promise<any> {
    const id = data.id || `mem_${data.userId}_${data.schoolId}`;
    const res = await this.db
      .insert(schema.schoolMemberships)
      .values({ ...data, id, createdAt: new Date() })
      .onConflictDoUpdate({
        target: [schema.schoolMemberships.schoolId, schema.schoolMemberships.userId],
        set: { ...data },
      })
      .returning();
    return res[0];
  }

  async getClassroomsForTeacher(teacherId: string): Promise<any[]> {
    return await this.db
      .select()
      .from(schema.classrooms)
      .where(eq(schema.classrooms.teacherId, teacherId));
  }

  async getClassroomsForSchool(schoolId: string): Promise<any[]> {
    return await this.db
      .select()
      .from(schema.classrooms)
      .where(eq(schema.classrooms.schoolId, schoolId));
  }

  async getClassroom(classroomId: string): Promise<any | null> {
    const res = await this.db
      .select()
      .from(schema.classrooms)
      .where(eq(schema.classrooms.id, classroomId));
    return res[0] || null;
  }

  async createClassroom(data: any): Promise<any> {
    const id = data.id || `class_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const res = await this.db
      .insert(schema.classrooms)
      .values({ ...data, id, createdAt: data.createdAt || new Date() })
      .returning();
    return res[0];
  }

  async getClassroomStudents(classroomId: string): Promise<any[]> {
    return await this.db
      .select()
      .from(schema.classroomStudents)
      .where(eq(schema.classroomStudents.classroomId, classroomId));
  }

  async getStudentClassrooms(studentId: string): Promise<any[]> {
    const enrollments = await this.db
      .select()
      .from(schema.classroomStudents)
      .where(and(eq(schema.classroomStudents.studentId, studentId), eq(schema.classroomStudents.status, 'active')));

    if (enrollments.length === 0) return [];

    const classroomList: any[] = [];
    for (const en of enrollments) {
      const c = await this.getClassroom(en.classroomId);
      if (c) classroomList.push(c);
    }
    return classroomList;
  }

  async addStudentToClassroom(data: any): Promise<any> {
    const id = data.id || `cs_${data.classroomId}_${data.studentId}`;
    const res = await this.db
      .insert(schema.classroomStudents)
      .values({ ...data, id, joinedAt: data.joinedAt || new Date() })
      .onConflictDoUpdate({
        target: [schema.classroomStudents.classroomId, schema.classroomStudents.studentId],
        set: { status: data.status || 'active' },
      })
      .returning();
    return res[0];
  }

  async getDailyTasks(studentId: string, taskDate: string): Promise<any[]> {
    return await this.db
      .select()
      .from(schema.schoolDailyTasks)
      .where(and(eq(schema.schoolDailyTasks.studentId, studentId), eq(schema.schoolDailyTasks.taskDate, taskDate)));
  }

  async saveDailyTasks(tasks: any[]): Promise<any[]> {
    const results: any[] = [];
    for (const t of tasks) {
      const id = t.id || `task_${t.studentId}_${t.taskDate}_${t.type}`;
      const res = await this.db
        .insert(schema.schoolDailyTasks)
        .values({ ...t, id, createdAt: t.createdAt || new Date() })
        .onConflictDoUpdate({
          target: [schema.schoolDailyTasks.studentId, schema.schoolDailyTasks.taskDate, schema.schoolDailyTasks.type],
          set: { ...t },
        })
        .returning();
      results.push(res[0]);
    }
    return results;
  }

  async getDailyTaskById(taskId: string): Promise<any | null> {
    const res = await this.db
      .select()
      .from(schema.schoolDailyTasks)
      .where(eq(schema.schoolDailyTasks.id, taskId));
    return res[0] || null;
  }

  async updateDailyTask(taskId: string, updates: any): Promise<any | null> {
    const res = await this.db
      .update(schema.schoolDailyTasks)
      .set(updates)
      .where(eq(schema.schoolDailyTasks.id, taskId))
      .returning();
    return res[0] || null;
  }

  async saveGameResult(result: any): Promise<any> {
    const id = result.id || `game_res_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const res = await this.db
      .insert(schema.schoolGameResults)
      .values({
        ...result,
        id,
        completedAt: result.completedAt ? new Date(result.completedAt) : new Date(),
      })
      .returning();
    return res[0];
  }

  async getGameResults(studentId: string, limit: number = 50): Promise<any[]> {
    return await this.db
      .select()
      .from(schema.schoolGameResults)
      .where(eq(schema.schoolGameResults.studentId, studentId))
      .orderBy(desc(schema.schoolGameResults.completedAt))
      .limit(limit);
  }

  async getSubscription(userId: string): Promise<any | null> {
    const res = await this.db
      .select()
      .from(schema.userSubscriptions)
      .where(eq(schema.userSubscriptions.userId, userId));
    return res[0] || null;
  }

  async upsertSubscription(data: any): Promise<any> {
    const id = data.id || `sub_${data.userId}`;
    const res = await this.db
      .insert(schema.userSubscriptions)
      .values({
        ...data,
        id,
        updatedAt: new Date(),
      })
      .onConflictDoUpdate({
        target: schema.userSubscriptions.userId,
        set: {
          ...data,
          updatedAt: new Date(),
        },
      })
      .returning();
    return res[0];
  }

  async recordAiUsage(data: {
    userId: string;
    usageDate: string;
    feature: string;
    modelUsed: string;
    inputTokens: number;
    outputTokens: number;
    voiceSeconds?: number;
    cachedResponsesCount?: number;
  }): Promise<any> {
    const id = `usage_${data.userId}_${data.usageDate}_${data.feature}`;
    const res = await this.db
      .insert(schema.aiUsageRecords)
      .values({
        id,
        userId: data.userId,
        usageDate: data.usageDate,
        feature: data.feature,
        modelUsed: data.modelUsed,
        requestCount: 1,
        inputTokens: data.inputTokens,
        outputTokens: data.outputTokens,
        voiceSeconds: data.voiceSeconds || 0,
        cachedResponsesCount: data.cachedResponsesCount || 0,
        createdAt: new Date(),
        updatedAt: new Date(),
      })
      .onConflictDoUpdate({
        target: [schema.aiUsageRecords.userId, schema.aiUsageRecords.usageDate, schema.aiUsageRecords.feature],
        set: {
          modelUsed: data.modelUsed,
          requestCount: sql`${schema.aiUsageRecords.requestCount} + 1`,
          inputTokens: sql`${schema.aiUsageRecords.inputTokens} + ${data.inputTokens}`,
          outputTokens: sql`${schema.aiUsageRecords.outputTokens} + ${data.outputTokens}`,
          voiceSeconds: sql`${schema.aiUsageRecords.voiceSeconds} + ${data.voiceSeconds || 0}`,
          cachedResponsesCount: sql`${schema.aiUsageRecords.cachedResponsesCount} + ${data.cachedResponsesCount || 0}`,
          updatedAt: new Date(),
        },
      })
      .returning();
    return res[0];
  }

  async getDailyAiUsage(userId: string, usageDate: string): Promise<any[]> {
    return await this.db
      .select()
      .from(schema.aiUsageRecords)
      .where(and(eq(schema.aiUsageRecords.userId, userId), eq(schema.aiUsageRecords.usageDate, usageDate)));
  }

  async getTotalDailyAiTokens(userId: string, usageDate: string): Promise<{
    totalInputTokens: number;
    totalOutputTokens: number;
    totalTokens: number;
    totalRequests: number;
    totalVoiceSeconds: number;
  }> {
    const records = await this.getDailyAiUsage(userId, usageDate);
    const totalInputTokens = records.reduce((sum, r) => sum + (r.inputTokens || 0), 0);
    const totalOutputTokens = records.reduce((sum, r) => sum + (r.outputTokens || 0), 0);
    const totalRequests = records.reduce((sum, r) => sum + (r.requestCount || 0), 0);
    const totalVoiceSeconds = records.reduce((sum, r) => sum + (r.voiceSeconds || 0), 0);
    return {
      totalInputTokens,
      totalOutputTokens,
      totalTokens: totalInputTokens + totalOutputTokens,
      totalRequests,
      totalVoiceSeconds,
    };
  }

  async getStudentDailyTutorSessions(studentId: string, date: string): Promise<any[]> {
    return await this.db
      .select()
      .from(schema.schoolTutorSessions)
      .where(and(eq(schema.schoolTutorSessions.studentId, studentId), eq(schema.schoolTutorSessions.sessionDate, date)))
      .orderBy(schema.schoolTutorSessions.sessionNumber);
  }

  async saveStudentTutorSession(session: any): Promise<any> {
    const id = session.id || `sess_${session.studentId}_${session.sessionDate}_${session.sessionNumber}`;
    const res = await this.db
      .insert(schema.schoolTutorSessions)
      .values({
        id,
        studentId: session.studentId,
        sessionDate: session.sessionDate,
        sessionNumber: session.sessionNumber,
        durationSeconds: session.durationSeconds || 0,
        turnsCount: session.turnsCount || 0,
        status: session.status || 'active',
        startedAt: session.startedAt || new Date(),
        endedAt: session.endedAt || null,
      })
      .onConflictDoUpdate({
        target: schema.schoolTutorSessions.id,
        set: {
          durationSeconds: session.durationSeconds,
          turnsCount: session.turnsCount,
          status: session.status,
          endedAt: session.endedAt,
        },
      })
      .returning();
    return res[0];
  }

  async updateStudentTutorSession(sessionId: string, updates: any): Promise<any> {
    const res = await this.db
      .update(schema.schoolTutorSessions)
      .set(updates)
      .where(eq(schema.schoolTutorSessions.id, sessionId))
      .returning();
    return res[0] || null;
  }

  // --- Plans & 60-Day Path Implementation ---
  async getPlans(filters?: { category?: string; targetAgeGroup?: string; targetLevel?: string }): Promise<any[]> {
    const conditions = [eq(schema.plans.isActive, true)];
    if (filters?.category) conditions.push(eq(schema.plans.category, filters.category));
    if (filters?.targetAgeGroup && filters.targetAgeGroup !== 'all') conditions.push(eq(schema.plans.targetAgeGroup, filters.targetAgeGroup));
    if (filters?.targetLevel) conditions.push(eq(schema.plans.targetLevel, filters.targetLevel));
    return await this.db.select().from(schema.plans).where(and(...conditions));
  }

  async getPlanById(planId: string): Promise<any | null> {
    const res = await this.db.select().from(schema.plans).where(eq(schema.plans.id, planId));
    return res[0] || null;
  }

  async savePlan(plan: any): Promise<any> {
    const id = plan.id || `plan_${Date.now()}`;
    const res = await this.db
      .insert(schema.plans)
      .values({ ...plan, id, updatedAt: new Date() })
      .onConflictDoUpdate({
        target: schema.plans.id,
        set: { ...plan, updatedAt: new Date() },
      })
      .returning();
    return res[0];
  }

  async getPlanDays(planId: string): Promise<any[]> {
    return await this.db
      .select()
      .from(schema.planDays)
      .where(eq(schema.planDays.planId, planId))
      .orderBy(schema.planDays.dayNumber);
  }

  async getPlanDay(planId: string, dayNumber: number): Promise<any | null> {
    const res = await this.db
      .select()
      .from(schema.planDays)
      .where(and(eq(schema.planDays.planId, planId), eq(schema.planDays.dayNumber, dayNumber)));
    return res[0] || null;
  }

  async savePlanDays(days: any[]): Promise<any[]> {
    const results: any[] = [];
    for (const d of days) {
      const res = await this.db
        .insert(schema.planDays)
        .values(d)
        .onConflictDoUpdate({
          target: [schema.planDays.planId, schema.planDays.dayNumber],
          set: d,
        })
        .returning();
      results.push(res[0]);
    }
    return results;
  }

  async getPlanActivities(planDayId: string): Promise<any[]> {
    return await this.db
      .select()
      .from(schema.planActivities)
      .where(eq(schema.planActivities.planDayId, planDayId))
      .orderBy(schema.planActivities.stepOrder);
  }

  async savePlanActivities(activities: any[]): Promise<any[]> {
    const results: any[] = [];
    for (const a of activities) {
      const res = await this.db
        .insert(schema.planActivities)
        .values(a)
        .onConflictDoUpdate({
          target: schema.planActivities.id,
          set: a,
        })
        .returning();
      results.push(res[0]);
    }
    return results;
  }

  async getStudentPlanProgress(studentId: string, planId: string): Promise<any | null> {
    const res = await this.db
      .select()
      .from(schema.studentPlanProgress)
      .where(and(eq(schema.studentPlanProgress.studentId, studentId), eq(schema.studentPlanProgress.planId, planId)));
    return res[0] || null;
  }

  async upsertStudentPlanProgress(studentId: string, planId: string, data: any): Promise<any> {
    const id = data.id || `spp_${studentId}_${planId}`;
    const res = await this.db
      .insert(schema.studentPlanProgress)
      .values({
        id,
        studentId,
        planId,
        currentDay: data.currentDay || 1,
        completedDays: data.completedDays || 0,
        status: data.status || 'active',
        startedAt: data.startedAt || new Date(),
        lastActivityAt: new Date(),
      })
      .onConflictDoUpdate({
        target: [schema.studentPlanProgress.studentId, schema.studentPlanProgress.planId],
        set: {
          currentDay: data.currentDay,
          completedDays: data.completedDays,
          status: data.status,
          lastActivityAt: new Date(),
        },
      })
      .returning();
    return res[0];
  }

  async recordStudentActivity(data: any): Promise<any> {
    const id = data.id || `actlog_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const res = await this.db
      .insert(schema.studentActivityLogs)
      .values({
        id,
        studentId: data.studentId,
        planDayId: data.planDayId,
        activityId: data.activityId,
        score: data.score || 100,
        xpEarned: data.xpEarned || 10,
        isCompleted: data.isCompleted ?? true,
        completedAt: new Date(),
      })
      .onConflictDoUpdate({
        target: [schema.studentActivityLogs.studentId, schema.studentActivityLogs.activityId],
        set: {
          score: data.score,
          xpEarned: data.xpEarned,
          isCompleted: data.isCompleted,
          completedAt: new Date(),
        },
      })
      .returning();
    return res[0];
  }

  async getStudentActivityLogs(studentId: string, planDayId: string): Promise<any[]> {
    return await this.db
      .select()
      .from(schema.studentActivityLogs)
      .where(and(eq(schema.studentActivityLogs.studentId, studentId), eq(schema.studentActivityLogs.planDayId, planDayId)));
  }

  // --- Student Codes & PIN Auth Implementation ---
  async getStudentCodeByCode(code: string): Promise<any | null> {
    const trimmed = code.trim().toUpperCase();
    const res = await this.db.select().from(schema.studentCodes).where(eq(schema.studentCodes.studentCode, trimmed));
    return res[0] || null;
  }

  async getStudentCodeByStudentId(studentId: string): Promise<any | null> {
    const res = await this.db.select().from(schema.studentCodes).where(eq(schema.studentCodes.studentId, studentId));
    return res[0] || null;
  }

  async saveStudentCode(data: any): Promise<any> {
    const id = data.id || `sc_${Date.now()}`;
    const code = data.studentCode.trim().toUpperCase();
    const res = await this.db
      .insert(schema.studentCodes)
      .values({
        id,
        studentId: data.studentId,
        studentCode: code,
        pinHash: data.pinHash,
        schoolId: data.schoolId || null,
        classroomId: data.classroomId || null,
        teacherId: data.teacherId || null,
        createdAt: data.createdAt || new Date(),
        updatedAt: new Date(),
      })
      .onConflictDoUpdate({
        target: schema.studentCodes.studentId,
        set: {
          studentCode: code,
          pinHash: data.pinHash,
          schoolId: data.schoolId,
          classroomId: data.classroomId,
          teacherId: data.teacherId,
          updatedAt: new Date(),
        },
      })
      .returning();
    return res[0];
  }

  // --- Points Transactions Implementation (Server-authoritative) ---
  async recordPointsTransaction(data: {
    studentId: string;
    amount: number;
    reasonCode: string;
    descriptionAr: string;
    referenceId?: string;
  }): Promise<any> {
    const id = `ptx_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    const res = await this.db
      .insert(schema.pointsTransactions)
      .values({
        id,
        studentId: data.studentId,
        amount: data.amount,
        reasonCode: data.reasonCode,
        descriptionAr: data.descriptionAr,
        referenceId: data.referenceId || null,
        createdAt: new Date(),
      })
      .returning();

    // Increment progress totalXp to keep synced
    await this.db
      .update(schema.learnerProgress)
      .set({
        totalXp: sql`${schema.learnerProgress.totalXp} + ${data.amount}`,
        updatedAt: new Date(),
      })
      .where(eq(schema.learnerProgress.userId, data.studentId));

    return res[0];
  }

  async getPointsTransactions(studentId: string, limit: number = 50): Promise<any[]> {
    return await this.db
      .select()
      .from(schema.pointsTransactions)
      .where(eq(schema.pointsTransactions.studentId, studentId))
      .orderBy(desc(schema.pointsTransactions.createdAt))
      .limit(limit);
  }

  // --- Student Mistakes & Spaced Repetition Implementation ---
  async recordStudentMistake(data: {
    studentId: string;
    contentId: string;
    skillType: string;
    itemPrompt: string;
    correctAnswer: string;
    studentLastWrongAnswer?: string;
  }): Promise<any> {
    const id = `smist_${Date.now()}`;
    const nextReview = new Date(); // Immediately available for student review
    const res = await this.db
      .insert(schema.studentMistakes)
      .values({
        id,
        studentId: data.studentId,
        contentId: data.contentId,
        skillType: data.skillType,
        itemPrompt: data.itemPrompt,
        correctAnswer: data.correctAnswer,
        studentLastWrongAnswer: data.studentLastWrongAnswer || null,
        mistakeCount: 1,
        intervalDays: 1,
        easeFactor: 2.5,
        repetitions: 0,
        mastered: false,
        lastMistakeAt: new Date(),
        nextReviewAt: nextReview,
      })
      .onConflictDoUpdate({
        target: [schema.studentMistakes.studentId, schema.studentMistakes.contentId],
        set: {
          mistakeCount: sql`${schema.studentMistakes.mistakeCount} + 1`,
          studentLastWrongAnswer: data.studentLastWrongAnswer || null,
          repetitions: 0,
          intervalDays: 1,
          mastered: false,
          lastMistakeAt: new Date(),
          nextReviewAt: nextReview,
        },
      })
      .returning();
    return res[0];
  }

  async getStudentMistakesDue(studentId: string, limit: number = 20): Promise<any[]> {
    return await this.db
      .select()
      .from(schema.studentMistakes)
      .where(and(eq(schema.studentMistakes.studentId, studentId), eq(schema.studentMistakes.mastered, false), lte(schema.studentMistakes.nextReviewAt, new Date())))
      .limit(limit);
  }

  async updateStudentMistakeReview(studentId: string, contentId: string, wasCorrect: boolean): Promise<any> {
    const existing = await this.db
      .select()
      .from(schema.studentMistakes)
      .where(and(eq(schema.studentMistakes.studentId, studentId), eq(schema.studentMistakes.contentId, contentId)));
    if (!existing[0]) return null;
    const m = existing[0];

    if (wasCorrect) {
      const repetitions = (m.repetitions || 0) + 1;
      const easeFactor = Math.min(3.0, (m.easeFactor || 2.5) + 0.1);
      const intervalDays = repetitions === 1 ? 2 : repetitions === 2 ? 6 : Math.round((m.intervalDays || 1) * easeFactor);
      const mastered = repetitions >= 4;
      const nextReviewAt = new Date(Date.now() + intervalDays * 24 * 60 * 60 * 1000);

      const res = await this.db
        .update(schema.studentMistakes)
        .set({ repetitions, easeFactor, intervalDays, mastered, nextReviewAt })
        .where(eq(schema.studentMistakes.id, m.id))
        .returning();
      return res[0];
    } else {
      const res = await this.db
        .update(schema.studentMistakes)
        .set({
          repetitions: 0,
          intervalDays: 1,
          mistakeCount: (m.mistakeCount || 1) + 1,
          mastered: false,
          lastMistakeAt: new Date(),
          nextReviewAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
        })
        .where(eq(schema.studentMistakes.id, m.id))
        .returning();
      return res[0];
    }
  }

  // --- Teacher Exams Implementation ---
  async getExamsForClassroom(classroomId: string): Promise<any[]> {
    return await this.db
      .select()
      .from(schema.exams)
      .where(eq(schema.exams.classroomId, classroomId))
      .orderBy(desc(schema.exams.createdAt));
  }

  async getExamsForTeacher(teacherId: string): Promise<any[]> {
    return await this.db
      .select()
      .from(schema.exams)
      .where(eq(schema.exams.teacherId, teacherId))
      .orderBy(desc(schema.exams.createdAt));
  }

  async getExamById(examId: string): Promise<any | null> {
    const res = await this.db.select().from(schema.exams).where(eq(schema.exams.id, examId));
    return res[0] || null;
  }

  async saveExam(data: any): Promise<any> {
    const id = data.id || `exam_${Date.now()}`;
    const res = await this.db
      .insert(schema.exams)
      .values({ ...data, id, updatedAt: new Date() })
      .onConflictDoUpdate({ target: schema.exams.id, set: { ...data, updatedAt: new Date() } })
      .returning();
    return res[0];
  }

  async getExamQuestions(examId: string): Promise<any[]> {
    return await this.db
      .select()
      .from(schema.examQuestions)
      .where(eq(schema.examQuestions.examId, examId))
      .orderBy(schema.examQuestions.questionOrder);
  }

  async saveExamQuestions(questions: any[]): Promise<any[]> {
    const results: any[] = [];
    for (const q of questions) {
      const id = q.id || `eq_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
      const res = await this.db
        .insert(schema.examQuestions)
        .values({ ...q, id })
        .onConflictDoUpdate({ target: schema.examQuestions.id, set: q })
        .returning();
      results.push(res[0]);
    }
    return results;
  }

  async submitExam(submission: any): Promise<any> {
    const id = submission.id || `sub_${Date.now()}`;
    const res = await this.db
      .insert(schema.examSubmissions)
      .values({ ...submission, id, submittedAt: new Date() })
      .onConflictDoUpdate({
        target: [schema.examSubmissions.examId, schema.examSubmissions.studentId],
        set: { ...submission, submittedAt: new Date() },
      })
      .returning();
    return res[0];
  }

  async getExamSubmissions(examId: string): Promise<any[]> {
    return await this.db.select().from(schema.examSubmissions).where(eq(schema.examSubmissions.examId, examId));
  }

  async getStudentExamSubmission(examId: string, studentId: string): Promise<any | null> {
    const res = await this.db
      .select()
      .from(schema.examSubmissions)
      .where(and(eq(schema.examSubmissions.examId, examId), eq(schema.examSubmissions.studentId, studentId)));
    return res[0] || null;
  }

  // --- Educational Games Hub Implementation ---
  async getEducationalGames(filters?: { targetAgeGroup?: string; difficulty?: string; classroomId?: string }): Promise<any[]> {
    const conditions = [eq(schema.educationalGames.isActive, true)];
    if (filters?.targetAgeGroup && filters.targetAgeGroup !== 'all') {
      conditions.push(eq(schema.educationalGames.targetAgeGroup, filters.targetAgeGroup));
    }
    if (filters?.difficulty) {
      conditions.push(eq(schema.educationalGames.difficulty, filters.difficulty));
    }
    if (filters?.classroomId) {
      conditions.push(eq(schema.educationalGames.classroomId, filters.classroomId));
    }
    return await this.db.select().from(schema.educationalGames).where(and(...conditions));
  }

  async getEducationalGameById(gameId: string): Promise<any | null> {
    const res = await this.db.select().from(schema.educationalGames).where(eq(schema.educationalGames.id, gameId));
    return res[0] || null;
  }

  async saveEducationalGame(data: any): Promise<any> {
    const id = data.id || `game_${Date.now()}`;
    const res = await this.db
      .insert(schema.educationalGames)
      .values({ ...data, id })
      .onConflictDoUpdate({ target: schema.educationalGames.id, set: data })
      .returning();
    return res[0];
  }

  async getGameQuestions(gameId: string): Promise<any[]> {
    return await this.db.select().from(schema.gameQuestions).where(eq(schema.gameQuestions.gameId, gameId));
  }

  async saveGameQuestions(questions: any[]): Promise<any[]> {
    const results: any[] = [];
    for (const q of questions) {
      const id = q.id || `gq_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
      const res = await this.db
        .insert(schema.gameQuestions)
        .values({ ...q, id })
        .returning();
      results.push(res[0]);
    }
    return results;
  }

  // --- Audio Assets & Encouragement Templates Implementation ---
  async getAudioAssets(category?: string): Promise<any[]> {
    if (category) {
      return await this.db.select().from(schema.audioAssets).where(eq(schema.audioAssets.category, category));
    }
    return await this.db.select().from(schema.audioAssets);
  }

  async findAudioAssetByText(text: string, category?: string): Promise<any | null> {
    const conditions = [eq(schema.audioAssets.textContent, text.trim())];
    if (category) conditions.push(eq(schema.audioAssets.category, category));
    const res = await this.db.select().from(schema.audioAssets).where(and(...conditions));
    return res[0] || null;
  }

  async saveAudioAsset(data: any): Promise<any> {
    const id = data.id || `audio_${Date.now()}`;
    const res = await this.db
      .insert(schema.audioAssets)
      .values({ ...data, id, createdAt: new Date() })
      .returning();
    return res[0];
  }

  async getEncouragementTemplate(triggerContext: string, tone?: string): Promise<any | null> {
    const conditions = [eq(schema.encouragementTemplates.triggerContext, triggerContext)];
    if (tone) conditions.push(eq(schema.encouragementTemplates.tone, tone));
    const res = await this.db.select().from(schema.encouragementTemplates).where(and(...conditions));
    if (res.length === 0) return null;
    return res[Math.floor(Math.random() * res.length)];
  }

  async saveEncouragementTemplate(data: any): Promise<any> {
    const id = data.id || `enc_${Date.now()}`;
    const res = await this.db
      .insert(schema.encouragementTemplates)
      .values({ ...data, id })
      .returning();
    return res[0];
  }
}


/**
 * Singleton database provider
 */
let dbInstance: ILearningDb | null = null;

export function getDatabase(): ILearningDb {
  if (!dbInstance) {
    if (config.DATABASE_URL && config.DATABASE_URL.length > 0) {
      try {
        const pool = new Pool({ connectionString: config.DATABASE_URL });
        dbInstance = new PgLearningDb(pool);
      } catch (err) {
        console.warn('⚠️ Could not connect to PostgreSQL via DATABASE_URL. Falling back to in-memory database store.');
        dbInstance = new InMemoryLearningDb();
      }
    } else {
      dbInstance = new InMemoryLearningDb();
    }
  }
  return dbInstance;
}

export function setDatabase(customDb: ILearningDb): void {
  dbInstance = customDb;
}

