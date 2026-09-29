import { and, desc, eq, sql } from 'drizzle-orm';
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

