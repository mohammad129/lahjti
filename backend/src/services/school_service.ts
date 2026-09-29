import { ILearningDb } from '../db/index.js';

export interface StudentHomeData {
  student: {
    displayName: string;
    grade: string;
    section: string;
    schoolName: string;
    cefrLevel: string;
    xp: number;
    streak: number;
  };
  currentLearning: {
    currentLesson: string;
    currentUnit: string;
    recommendation: string;
  };
  dailyTasks: any[];
  vocabularyReview: {
    dueCount: number;
  };
}

export class SchoolService {
  constructor(private db: ILearningDb) {}

  /**
   * 1. Get Student School Home Context
   * Server-authoritative: Returns only the student's own educational state.
   */
  async getStudentHome(studentId: string): Promise<StudentHomeData> {
    const today = new Date().toISOString().split('T')[0];

    // 1. Fetch or create baseline profile
    let profile = await this.db.getProfile(studentId);
    if (!profile) {
      profile = await this.db.upsertProfile(studentId, {
        targetLanguage: 'english',
        estimatedCefrLevel: 'A1',
        ageGroup: 'age13_15',
        currentLessonId: 'lesson_1_1',
      });
    }

    // 2. Fetch progress & streak
    let progress = await this.db.getProgress(studentId);
    if (!progress) {
      progress = await this.db.upsertProgress(studentId, {
        totalXp: 120,
        completedLessonIds: ['lesson_1_1'],
        inProgressLessonId: 'lesson_1_2',
        masteredVocabCount: 15,
        reviewQueueCount: 4,
      });
    }

    let streak = await this.db.getStreak(studentId);
    if (!streak) {
      streak = await this.db.upsertStreak(studentId, {
        currentStreak: 3,
        longestStreak: 5,
        totalActiveDays: 7,
        lastActiveDate: new Date(),
      });
    }

    // 3. Fetch school membership and classroom
    const membership = await this.db.getSchoolMembership(studentId);
    let schoolName = 'Lahjti Academy';
    let grade = 'الصف السابع';
    let section = 'أ';

    if (membership && membership.schoolId) {
      const school = await this.db.getSchool(membership.schoolId);
      if (school) schoolName = school.name;
    }

    const classrooms = await this.db.getStudentClassrooms(studentId);
    if (classrooms.length > 0) {
      grade = classrooms[0].grade || grade;
      section = classrooms[0].section || section;
    }

    // 4. Deterministic daily tasks for today
    const isChild = profile.ageGroup === 'age6_9' || profile.ageGroup === 'age10_12';
    const dailyTasks = await this.getOrCreateDailyTasks(studentId, today, isChild);

    // 5. Due vocabulary review count
    const vocabList = await this.db.getVocabularyList(studentId);
    const now = new Date();
    const dueCount = vocabList.filter(
      (v) => !v.nextReviewDate || new Date(v.nextReviewDate) <= now
    ).length || (progress.reviewQueueCount || 3);

    return {
      student: {
        displayName: membership?.displayName || profile?.displayName || 'طالب متميز',
        grade,
        section,
        schoolName,
        cefrLevel: profile?.estimatedCefrLevel?.toUpperCase() || 'A1',
        xp: progress.totalXp || 0,
        streak: streak.currentStreak || 0,
      },
      currentLearning: {
        currentLesson: progress.inProgressLessonId || 'lesson_1_2',
        currentUnit: 'الوحدة الثانية: المحادثة اليومية',
        recommendation: isChild ? 'العب لعبة مطابقة الكلمات اليومية' : 'أكمل المهام اليومية للحفاظ على استمرارية التعلم',
      },
      dailyTasks,
      vocabularyReview: {
        dueCount,
      },
    };
  }

  /**
   * 2. Deterministic Daily Task Generator
   * Generates identical tasks for the same student on the same date.
   */
  async getOrCreateDailyTasks(studentId: string, taskDate: string, isChild = false): Promise<any[]> {
    const existingTasks = await this.db.getDailyTasks(studentId, taskDate);
    if (existingTasks && existingTasks.length > 0) {
      return existingTasks;
    }

    // Build deterministic task set
    const tasksToCreate = [
      {
        studentId,
        taskDate,
        type: 'lesson',
        title: isChild ? 'درس الكلمات المصورة' : 'إكمال الدرس اليومي',
        description: isChild ? 'تعلم ٥ كلمات جديدة مع الصور' : 'درس القواعد والمحادثة الأساسية',
        skill: 'grammar',
        difficulty: isChild ? 'beginner' : 'intermediate',
        durationMinutes: isChild ? 5 : 10,
        status: 'pending',
        progress: 0.0,
        xpReward: 25,
        actionRoute: '/learning/lesson',
        lessonId: 'lesson_1_2',
        isForChild: isChild,
      },
      {
        studentId,
        taskDate,
        type: 'vocabulary',
        title: isChild ? 'لعبة سحب الكلمات' : 'تحدي مراجعة المفردات',
        description: isChild ? 'طابق الكلمات بالصور الصحيحة' : 'مراجعة الكلمات المستحقة في التكرار المتباعد',
        skill: 'vocabulary',
        difficulty: 'beginner',
        durationMinutes: 5,
        status: 'pending',
        progress: 0.0,
        xpReward: 15,
        actionRoute: '/learning/vocabulary',
        gameId: 'flashcard_sprint',
        isForChild: isChild,
      },
      {
        studentId,
        taskDate,
        type: 'game',
        title: isChild ? 'فقاعات النطق السريع' : 'سباق مطابقة المعاني',
        description: isChild ? 'فرقع الفقاعات ذات النطق السليم' : 'لعبة تفاعلية لتعزيز سرعة الفهم',
        skill: 'comprehension',
        difficulty: 'intermediate',
        durationMinutes: 5,
        status: 'pending',
        progress: 0.0,
        xpReward: 20,
        actionRoute: '/learning/game',
        gameId: isChild ? 'bubble_pop' : 'word_match',
        isForChild: isChild,
      },
    ];

    return await this.db.saveDailyTasks(tasksToCreate);
  }

  /**
   * 3. Complete Daily Task
   * Server-authoritative validation & anti-farming XP calculation.
   */
  async completeDailyTask(studentId: string, taskId: string): Promise<{
    success: boolean;
    earnedXp: number;
    task: any;
    message?: string;
  }> {
    const task = await this.db.getDailyTaskById(taskId);
    if (!task) {
      throw new Error('NOT_FOUND: Daily task not found');
    }

    if (task.studentId !== studentId) {
      throw new Error('FORBIDDEN: You are not authorized to complete this task');
    }

    // Anti-farming check: If already completed, grant 0 XP
    if (task.status === 'completed') {
      return {
        success: true,
        earnedXp: 0,
        task,
        message: 'Task was already completed.',
      };
    }

    const earnedXp = task.xpReward || 20;

    // Update task
    const updatedTask = await this.db.updateDailyTask(taskId, {
      status: 'completed',
      progress: 1.0,
      completedAt: new Date(),
    });

    // Update Learner Progress XP
    let progress = await this.db.getProgress(studentId);
    const newTotalXp = (progress?.totalXp || 0) + earnedXp;
    await this.db.upsertProgress(studentId, {
      ...progress,
      totalXp: newTotalXp,
      lastSessionDate: new Date(),
    });

    // Record XP Transaction
    await this.db.saveXpTransaction(studentId, {
      activityType: `daily_task_${task.type}`,
      xpEarned: earnedXp,
      referenceId: taskId,
      timestamp: new Date(),
    });

    // Increment Skill Progress
    if (task.skill) {
      const skills = await this.db.getSkills(studentId);
      const existingSkill = skills.find((s) => s.skill === task.skill);
      const currentScore = existingSkill ? existingSkill.levelScore : 50;
      const currentAttempts = existingSkill ? existingSkill.assessedAttempts : 0;
      await this.db.upsertSkill(
        studentId,
        task.skill,
        Math.min(100, currentScore + 2),
        currentAttempts + 1
      );
    }

    return {
      success: true,
      earnedXp,
      task: updatedTask,
    };
  }

  /**
   * 4. Submit Game Result
   * Server calculates XP and verifies student ownership.
   */
  async submitGameResult(studentId: string, payload: {
    gameId: string;
    taskId?: string;
    score: number;
    correctAnswers: number;
    incorrectAnswers: number;
    skill: string;
    vocabularyIds?: string[];
  }): Promise<{
    success: boolean;
    earnedXp: number;
    gameResult: any;
  }> {
    // Server-side XP calculation based on score percentage
    const maxGameXp = 20;
    const earnedXp = payload.score > 0
      ? Math.max(5, Math.min(maxGameXp, Math.round((payload.score / 100) * maxGameXp)))
      : 0;

    // Save Game Result record
    const resultRecord = await this.db.saveGameResult({
      studentId,
      gameId: payload.gameId,
      taskId: payload.taskId || null,
      score: payload.score,
      correctAnswers: payload.correctAnswers,
      incorrectAnswers: payload.incorrectAnswers,
      skill: payload.skill,
      vocabularyIds: payload.vocabularyIds || [],
      earnedXp,
      completedAt: new Date(),
    });

    // If linked to a daily task, attempt completion
    if (payload.taskId) {
      try {
        await this.completeDailyTask(studentId, payload.taskId);
      } catch (err) {
        // Task might already be complete or invalid; continue gracefully
      }
    }

    // Award XP
    if (earnedXp > 0) {
      const progress = await this.db.getProgress(studentId);
      await this.db.upsertProgress(studentId, {
        ...progress,
        totalXp: (progress?.totalXp || 0) + earnedXp,
        lastSessionDate: new Date(),
      });

      await this.db.saveXpTransaction(studentId, {
        activityType: `game_${payload.gameId}`,
        xpEarned: earnedXp,
        referenceId: resultRecord.id,
        timestamp: new Date(),
      });
    }

    // Update Skill Progress
    if (payload.skill) {
      const skills = await this.db.getSkills(studentId);
      const existingSkill = skills.find((s) => s.skill === payload.skill);
      const currentScore = existingSkill ? existingSkill.levelScore : 50;
      const currentAttempts = existingSkill ? existingSkill.assessedAttempts : 0;
      const boost = payload.score >= 70 ? 3 : 1;
      await this.db.upsertSkill(
        studentId,
        payload.skill,
        Math.min(100, currentScore + boost),
        currentAttempts + 1
      );
    }

    return {
      success: true,
      earnedXp,
      gameResult: resultRecord,
    };
  }

  /**
   * 5. Get Student Progress
   */
  async getStudentProgress(studentId: string): Promise<any> {
    const profile = await this.db.getProfile(studentId);
    const progress = await this.db.getProgress(studentId);
    const streak = await this.db.getStreak(studentId);
    const skills = await this.db.getSkills(studentId);
    const achievements = await this.db.getAchievements(studentId);
    const recentXp = await this.db.getXpTransactions(studentId, 20);
    const gameResults = await this.db.getGameResults(studentId, 10);

    return {
      profile: {
        cefrLevel: profile?.estimatedCefrLevel?.toUpperCase() || 'A1',
        learningGoal: profile?.learningGoal || 'generalFluency',
        grammarScore: profile?.grammarScore || 50,
        vocabularyScore: profile?.vocabularyScore || 50,
      },
      progress: {
        totalXp: progress?.totalXp || 0,
        completedLessonsCount: progress?.completedLessonIds?.length || 0,
        masteredVocabCount: progress?.masteredVocabCount || 0,
        totalMinutesLearned: progress?.totalMinutesLearned || 0,
      },
      streak: {
        currentStreak: streak?.currentStreak || 0,
        longestStreak: streak?.longestStreak || 0,
        totalActiveDays: streak?.totalActiveDays || 0,
      },
      skills,
      achievements,
      recentActivity: recentXp,
      recentGameResults: gameResults,
    };
  }

  /**
   * 6. Teacher Home / Dashboard Overview
   * Strict privacy: Only educational aggregate data, NO AI chat transcripts or voice logs.
   */
  async getTeacherHome(teacherId: string): Promise<any> {
    const membership = await this.db.getSchoolMembership(teacherId);
    if (!membership || membership.role !== 'teacher') {
      throw new Error('FORBIDDEN: Teacher authorization required');
    }

    const school = await this.db.getSchool(membership.schoolId);
    const classrooms = await this.db.getClassroomsForTeacher(teacherId);

    let totalStudents = 0;
    const classSummaries: any[] = [];
    const studentIdsSet = new Set<string>();

    for (const c of classrooms) {
      const enrollments = await this.db.getClassroomStudents(c.id);
      const activeCount = enrollments.filter((e) => e.status === 'active').length;
      totalStudents += activeCount;
      for (const e of enrollments) {
        if (e.status === 'active') studentIdsSet.add(e.studentId);
      }

      classSummaries.push({
        id: c.id,
        name: c.name,
        grade: c.grade,
        section: c.section,
        studentCount: activeCount,
      });
    }

    // Compute basic aggregated metrics
    let activeTodayCount = 0;
    let totalXpSum = 0;
    const studentIds = Array.from(studentIdsSet);

    for (const sId of studentIds) {
      const p = await this.db.getProgress(sId);
      if (p) {
        totalXpSum += p.totalXp || 0;
        if (p.lastSessionDate) {
          const diffHours = (Date.now() - new Date(p.lastSessionDate).getTime()) / (1000 * 3600);
          if (diffHours < 24) activeTodayCount++;
        }
      }
    }

    const averageXp = studentIds.length > 0 ? Math.round(totalXpSum / studentIds.length) : 0;

    return {
      teacher: {
        id: teacherId,
        displayName: membership.displayName || 'معلم المادة',
        schoolName: school?.name || 'مدرسة لهجتي',
      },
      metrics: {
        totalStudents,
        totalClasses: classrooms.length,
        activeToday: activeTodayCount,
        averageXp,
      },
      classes: classSummaries,
    };
  }

  /**
   * 7. Teacher Class Detail
   * Authorizes teacher owns the classroom.
   */
  async getTeacherClassDetail(teacherId: string, classroomId: string): Promise<any> {
    const classroom = await this.db.getClassroom(classroomId);
    if (!classroom) {
      throw new Error('NOT_FOUND: Classroom not found');
    }

    if (classroom.teacherId !== teacherId) {
      throw new Error('FORBIDDEN: You do not have access to this classroom');
    }

    const enrollments = await this.db.getClassroomStudents(classroomId);
    const students: any[] = [];

    for (const en of enrollments) {
      const studentId = en.studentId;
      const mem = await this.db.getSchoolMembership(studentId);
      const prof = await this.db.getProfile(studentId);
      const prog = await this.db.getProgress(studentId);
      const strk = await this.db.getStreak(studentId);

      students.push({
        id: studentId,
        displayName: mem?.displayName || prof?.displayName || `طالب ${studentId.substring(0, 5)}`,
        cefrLevel: prof?.estimatedCefrLevel?.toUpperCase() || 'A1',
        totalXp: prog?.totalXp || 0,
        completedLessonsCount: prog?.completedLessonIds?.length || 0,
        streak: strk?.currentStreak || 0,
        lastActive: prog?.lastSessionDate || en.joinedAt,
      });
    }

    return {
      classroom: {
        id: classroom.id,
        name: classroom.name,
        grade: classroom.grade,
        section: classroom.section,
        schoolId: classroom.schoolId,
      },
      students,
    };
  }

  /**
   * 8. Teacher Student Detail (Aggregated Educational Progress Only)
   * Enforces cross-school and cross-class privacy. No AI transcripts.
   */
  async getTeacherStudentDetail(teacherId: string, studentId: string): Promise<any> {
    // 1. Verify that teacher has a class containing this student
    const teacherClasses = await this.db.getClassroomsForTeacher(teacherId);
    let isAuthorized = false;

    for (const c of teacherClasses) {
      const students = await this.db.getClassroomStudents(c.id);
      if (students.some((s) => s.studentId === studentId && s.status === 'active')) {
        isAuthorized = true;
        break;
      }
    }

    if (!isAuthorized) {
      throw new Error('FORBIDDEN: You are not authorized to view this student');
    }

    // 2. Fetch educational data
    const mem = await this.db.getSchoolMembership(studentId);
    const prof = await this.db.getProfile(studentId);
    const prog = await this.db.getProgress(studentId);
    const strk = await this.db.getStreak(studentId);
    const skills = await this.db.getSkills(studentId);

    return {
      student: {
        id: studentId,
        displayName: mem?.displayName || prof?.displayName || 'طالب',
        cefrLevel: prof?.estimatedCefrLevel?.toUpperCase() || 'A1',
        totalXp: prog?.totalXp || 0,
        completedLessonsCount: prog?.completedLessonIds?.length || 0,
        streak: strk?.currentStreak || 0,
        skills: skills.map((s) => ({ skill: s.skill, score: s.levelScore })),
      },
    };
  }

  /**
   * Helper: Join or Register School
   */
  async joinSchool(userId: string, data: {
    schoolCode: string;
    role: 'student' | 'teacher';
    displayName?: string;
  }): Promise<any> {
    const school = await this.db.getSchoolByCode(data.schoolCode);
    if (!school) {
      throw new Error('NOT_FOUND: School code is invalid');
    }

    const membership = await this.db.upsertSchoolMembership({
      schoolId: school.id,
      userId,
      role: data.role,
      displayName: data.displayName || (data.role === 'teacher' ? 'المعلم' : 'الطالب'),
      status: 'active',
    });

    return { school, membership };
  }
}
