import {
  boolean,
  index,
  integer,
  jsonb,
  pgTable,
  real,
  text,
  timestamp,
  uniqueIndex,
  varchar,
} from 'drizzle-orm/pg-core';

/**
 * 1. Learning Profiles Table
 * Authoritative user profile holding CEFR assessment, target language, and goals.
 */
export const learningProfiles = pgTable('learning_profiles', {
  userId: varchar('user_id', { length: 128 }).primaryKey(),
  targetLanguage: varchar('target_language', { length: 64 }).notNull().default('english'),
  ageGroup: varchar('age_group', { length: 32 }).notNull().default('age19_25'),
  nativeLanguage: varchar('native_language', { length: 32 }).notNull().default('arabic'),
  learningGoal: varchar('learning_goal', { length: 64 }).notNull().default('generalFluency'),
  experienceLevel: varchar('experience_level', { length: 64 }).notNull().default('beginnerWithBasics'),
  estimatedCefrLevel: varchar('estimated_cefr_level', { length: 16 }).notNull().default('a1'),
  currentLessonId: varchar('current_lesson_id', { length: 64 }).notNull().default('lesson_1_1'),
  selectedTutorId: varchar('selected_tutor_id', { length: 32 }).notNull().default('abbas'),
  grammarScore: integer('grammar_score').notNull().default(50),
  vocabularyScore: integer('vocabulary_score').notNull().default(50),
  comprehensionScore: integer('comprehension_score').notNull().default(50),
  communicationScore: integer('communication_score').notNull().default(50),
  pronunciationScore: integer('pronunciation_score'),
  strengths: jsonb('strengths').$type<string[]>().notNull().default([]),
  weaknesses: jsonb('weaknesses').$type<string[]>().notNull().default([]),
  recommendedFocusAreas: jsonb('recommended_focus_areas').$type<string[]>().notNull().default([]),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

/**
 * 2. Learner Progress Table
 * Overall curriculum milestones, totals, and active state.
 */
export const learnerProgress = pgTable('learner_progress', {
  userId: varchar('user_id', { length: 128 }).primaryKey(),
  completedLessonIds: jsonb('completed_lesson_ids').$type<string[]>().notNull().default([]),
  inProgressLessonId: varchar('in_progress_lesson_id', { length: 64 }).default('lesson_1_1'),
  masteredVocabCount: integer('mastered_vocab_count').notNull().default(0),
  reviewQueueCount: integer('review_queue_count').notNull().default(0),
  totalMinutesLearned: integer('total_minutes_learned').notNull().default(0),
  totalXp: integer('total_xp').notNull().default(0),
  tutorTurnsCount: integer('tutor_turns_count').notNull().default(0),
  completedExamsCount: integer('completed_exams_count').notNull().default(0),
  lastSessionDate: timestamp('last_session_date', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

/**
 * 3. Learner Streaks Table
 * Daily learning habit records and calendar continuity.
 */
export const learnerStreaks = pgTable('learner_streaks', {
  userId: varchar('user_id', { length: 128 }).primaryKey(),
  currentStreak: integer('current_streak').notNull().default(0),
  longestStreak: integer('longest_streak').notNull().default(0),
  totalActiveDays: integer('total_active_days').notNull().default(0),
  lastActiveDate: timestamp('last_active_date', { withTimezone: true }),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

/**
 * 4. Learner Skill Progress Table
 * Incremental evaluation across 6+ learning skills per user.
 */
export const learnerSkillProgress = pgTable(
  'learner_skill_progress',
  {
    id: varchar('id', { length: 128 }).primaryKey(),
    userId: varchar('user_id', { length: 128 }).notNull(),
    skill: varchar('skill', { length: 64 }).notNull(),
    levelScore: integer('level_score').notNull().default(45),
    assessedAttempts: integer('assessed_attempts').notNull().default(1),
    lastUpdated: timestamp('last_updated', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [
    uniqueIndex('user_skill_idx').on(table.userId, table.skill),
  ]
);

/**
 * 5. Learner Vocabulary Progress Table
 * Spaced-repetition mastery records per word and user.
 */
export const learnerVocabularyProgress = pgTable(
  'learner_vocabulary_progress',
  {
    id: varchar('id', { length: 128 }).primaryKey(),
    userId: varchar('user_id', { length: 128 }).notNull(),
    vocabularyId: varchar('vocabulary_id', { length: 64 }).notNull(),
    status: varchar('status', { length: 32 }).notNull().default('learning'),
    intervalDays: integer('interval_days').notNull().default(1),
    easeFactor: real('ease_factor').notNull().default(2.5),
    repetitions: integer('repetitions').notNull().default(0),
    nextReviewDate: timestamp('next_review_date', { withTimezone: true }).notNull().defaultNow(),
    lastReviewedDate: timestamp('last_reviewed_date', { withTimezone: true }),
    accuracyPercentage: integer('accuracy_percentage').notNull().default(0),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [
    uniqueIndex('user_vocab_idx').on(table.userId, table.vocabularyId),
  ]
);

/**
 * 6. Learner Exam Results Table
 * Historical assessment outcomes and pedagogical recommendations.
 */
export const learnerExamResults = pgTable('learner_exam_results', {
  id: varchar('id', { length: 128 }).primaryKey(),
  userId: varchar('user_id', { length: 128 }).notNull(),
  examId: varchar('exam_id', { length: 64 }).notNull(),
  examType: varchar('exam_type', { length: 32 }).notNull(),
  titleArabic: varchar('title_arabic', { length: 255 }).notNull(),
  overallScore: integer('overall_score').notNull(),
  earnedPoints: integer('earned_points').notNull(),
  totalPoints: integer('total_points').notNull(),
  isPassed: boolean('is_passed').notNull(),
  projectedCefrLevel: varchar('projected_cefr_level', { length: 16 }).notNull(),
  skillScores: jsonb('skill_scores').$type<any[]>().notNull().default([]),
  strengths: jsonb('strengths').$type<string[]>().notNull().default([]),
  improvementAreas: jsonb('improvement_areas').$type<string[]>().notNull().default([]),
  recommendations: jsonb('recommendations').$type<any[]>().notNull().default([]),
  completedAt: timestamp('completed_at', { withTimezone: true }).notNull().defaultNow(),
});

/**
 * 7. Learner XP Transactions Table
 * Audit log of verified XP increments.
 */
export const learnerXpTransactions = pgTable('learner_xp_transactions', {
  id: varchar('id', { length: 128 }).primaryKey(),
  userId: varchar('user_id', { length: 128 }).notNull(),
  activityType: varchar('activity_type', { length: 64 }).notNull(),
  xpEarned: integer('xp_earned').notNull(),
  referenceId: varchar('reference_id', { length: 128 }),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

/**
 * 8. Learner Achievements Table
 * Badges and milestone progress per user.
 */
export const learnerAchievements = pgTable(
  'learner_achievements',
  {
    id: varchar('id', { length: 128 }).primaryKey(),
    userId: varchar('user_id', { length: 128 }).notNull(),
    achievementId: varchar('achievement_id', { length: 64 }).notNull(),
    isUnlocked: boolean('is_unlocked').notNull().default(false),
    currentValue: integer('current_value').notNull().default(0),
    unlockedAt: timestamp('unlocked_at', { withTimezone: true }),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [
    uniqueIndex('user_achievement_idx').on(table.userId, table.achievementId),
  ]
);

/**
 * 9. Schools Table
 * Authoritative partner schools registry.
 */
export const schools = pgTable('schools', {
  id: varchar('id', { length: 128 }).primaryKey(),
  name: varchar('name', { length: 255 }).notNull(),
  schoolCode: varchar('school_code', { length: 64 }).notNull().unique(),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

/**
 * 10. School Memberships Table
 * Server-authoritative role binding (student or teacher) per school.
 */
export const schoolMemberships = pgTable(
  'school_memberships',
  {
    id: varchar('id', { length: 128 }).primaryKey(),
    schoolId: varchar('school_id', { length: 128 }).notNull(),
    userId: varchar('user_id', { length: 128 }).notNull(),
    role: varchar('role', { length: 32 }).notNull().default('student'), // 'student' | 'teacher'
    status: varchar('status', { length: 32 }).notNull().default('active'), // 'active' | 'inactive'
    displayName: varchar('display_name', { length: 255 }),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [
    uniqueIndex('school_user_role_idx').on(table.schoolId, table.userId),
  ]
);

/**
 * 11. Classrooms Table
 * Academic classes assigned to a school and teacher.
 */
export const classrooms = pgTable('classrooms', {
  id: varchar('id', { length: 128 }).primaryKey(),
  schoolId: varchar('school_id', { length: 128 }).notNull(),
  teacherId: varchar('teacher_id', { length: 128 }).notNull(),
  grade: varchar('grade', { length: 64 }).notNull(),
  section: varchar('section', { length: 32 }).notNull().default('A'),
  name: varchar('name', { length: 255 }).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

/**
 * 12. Classroom Students Table
 * Enrollment roster linking students to classes.
 */
export const classroomStudents = pgTable(
  'classroom_students',
  {
    id: varchar('id', { length: 128 }).primaryKey(),
    classroomId: varchar('classroom_id', { length: 128 }).notNull(),
    studentId: varchar('student_id', { length: 128 }).notNull(),
    joinedAt: timestamp('joined_at', { withTimezone: true }).notNull().defaultNow(),
    status: varchar('status', { length: 32 }).notNull().default('active'),
  },
  (table) => [
    uniqueIndex('classroom_student_idx').on(table.classroomId, table.studentId),
  ]
);

/**
 * 13. School Daily Tasks Table
 * Backend-persisted deterministic daily learning tasks.
 */
export const schoolDailyTasks = pgTable(
  'school_daily_tasks',
  {
    id: varchar('id', { length: 128 }).primaryKey(),
    studentId: varchar('student_id', { length: 128 }).notNull(),
    taskDate: varchar('task_date', { length: 16 }).notNull(), // 'YYYY-MM-DD'
    type: varchar('type', { length: 64 }).notNull(),
    title: varchar('title', { length: 255 }).notNull(),
    description: varchar('description', { length: 512 }).notNull(),
    skill: varchar('skill', { length: 64 }).notNull(),
    difficulty: varchar('difficulty', { length: 32 }).notNull().default('beginner'),
    durationMinutes: integer('duration_minutes').notNull().default(5),
    status: varchar('status', { length: 32 }).notNull().default('pending'), // 'pending' | 'inProgress' | 'completed' | 'skipped'
    progress: real('progress').notNull().default(0.0),
    xpReward: integer('xp_reward').notNull().default(15),
    actionRoute: varchar('action_route', { length: 255 }).notNull().default('/learning'),
    lessonId: varchar('lessonId', { length: 64 }),
    gameId: varchar('gameId', { length: 64 }),
    isForChild: boolean('is_for_child').notNull().default(false),
    completedAt: timestamp('completed_at', { withTimezone: true }),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [
    uniqueIndex('student_date_task_idx').on(table.studentId, table.taskDate, table.type),
  ]
);

/**
 * 14. School Game Results Table
 * Educationally bounded mini-game activity submissions with server-verified XP.
 */
export const schoolGameResults = pgTable('school_game_results', {
  id: varchar('id', { length: 128 }).primaryKey(),
  gameId: varchar('game_id', { length: 64 }).notNull(),
  taskId: varchar('task_id', { length: 128 }),
  studentId: varchar('student_id', { length: 128 }).notNull(),
  score: integer('score').notNull(),
  correctAnswers: integer('correct_answers').notNull(),
  incorrectAnswers: integer('incorrect_answers').notNull(),
  skill: varchar('skill', { length: 64 }).notNull(),
  vocabularyIds: jsonb('vocabulary_ids').$type<string[]>().notNull().default([]),
  earnedXp: integer('earned_xp').notNull().default(0),
  completedAt: timestamp('completed_at', { withTimezone: true }).notNull().defaultNow(),
});

/**
 * 15. User Subscriptions Table
 * Authoritative monetization, trial, and access state per user.
 */
export const userSubscriptions = pgTable(
  'user_subscriptions',
  {
    id: varchar('id', { length: 128 }).primaryKey(),
    userId: varchar('user_id', { length: 128 }).notNull(),
    accountContext: varchar('account_context', { length: 32 }).notNull().default('individual'), // 'individual' | 'school'
    role: varchar('role', { length: 32 }).notNull().default('individual'), // 'individual' | 'student' | 'teacher'
    status: varchar('status', { length: 32 }).notNull().default('trial'), // 'trial' | 'active' | 'expired' | 'cancelled' | 'paymentPending' | 'schoolAccess' | 'pastDue' | 'suspended'
    planId: varchar('plan_id', { length: 64 }).notNull().default('individual_monthly'),
    priceUsd: real('price_usd').notNull().default(10.0),
    trialStartsAt: timestamp('trial_starts_at', { withTimezone: true }),
    trialEndsAt: timestamp('trial_ends_at', { withTimezone: true }),
    trialDurationDays: integer('trial_duration_days').notNull().default(3),
    currentPeriodStart: timestamp('current_period_start', { withTimezone: true }),
    currentPeriodEnd: timestamp('current_period_end', { withTimezone: true }),
    subscriptionExpiresAt: timestamp('subscription_expires_at', { withTimezone: true }),
    cancelledAt: timestamp('cancelled_at', { withTimezone: true }),
    schoolId: varchar('school_id', { length: 128 }),
    schoolCode: varchar('school_code', { length: 64 }),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [
    uniqueIndex('user_subscription_user_idx').on(table.userId),
    index('user_subscription_status_idx').on(table.status),
    index('user_subscription_school_idx').on(table.schoolId),
  ]
);

/**
 * 16. AI Usage Records Table
 * Production scale telemetry and usage metering (metadata and token counters only, zero conversation surveillance).
 */
export const aiUsageRecords = pgTable(
  'ai_usage_records',
  {
    id: varchar('id', { length: 128 }).primaryKey(),
    userId: varchar('user_id', { length: 128 }).notNull(),
    usageDate: varchar('usage_date', { length: 10 }).notNull(), // 'YYYY-MM-DD'
    feature: varchar('feature', { length: 64 }).notNull(), // 'tutor_conversation' | 'placement_evaluation' | 'vocabulary_explanation' | 'grammar_practice'
    modelUsed: varchar('model_used', { length: 64 }).notNull(),
    requestCount: integer('request_count').notNull().default(1),
    inputTokens: integer('input_tokens').notNull().default(0),
    outputTokens: integer('output_tokens').notNull().default(0),
    voiceSeconds: real('voice_seconds').notNull().default(0.0),
    cachedResponsesCount: integer('cached_responses_count').notNull().default(0),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [
    uniqueIndex('user_date_feature_idx').on(table.userId, table.usageDate, table.feature),
    index('usage_date_idx').on(table.usageDate),
    index('usage_user_idx').on(table.userId),
  ]
);

/**
 * 17. School Tutor Sessions Table
 * Authoritative tracking of daily tutor sessions for school students:
 * maximum 4 sessions per day, bounded by a cumulative 1-hour (3600 seconds) cap.
 */
export const schoolTutorSessions = pgTable(
  'school_tutor_sessions',
  {
    id: varchar('id', { length: 128 }).primaryKey(),
    studentId: varchar('student_id', { length: 128 }).notNull(),
    sessionDate: varchar('session_date', { length: 10 }).notNull(), // 'YYYY-MM-DD'
    sessionNumber: integer('session_number').notNull(), // 1, 2, 3, 4
    durationSeconds: real('duration_seconds').notNull().default(0),
    turnsCount: integer('turns_count').notNull().default(0),
    status: varchar('status', { length: 32 }).notNull().default('active'), // 'active' | 'completed'
    startedAt: timestamp('started_at', { withTimezone: true }).notNull().defaultNow(),
    endedAt: timestamp('ended_at', { withTimezone: true }),
  },
  (table) => [
    index('student_session_date_idx').on(table.studentId, table.sessionDate),
  ]
);

/**
 * 18. Plans Table
 * Multi-target structured curriculum plans (Conversation, Interviews, Travel, School, 60-Day, etc.)
 */
export const plans = pgTable('plans', {
  id: varchar('id', { length: 64 }).primaryKey(),
  titleAr: varchar('title_ar', { length: 255 }).notNull(),
  titleEn: varchar('title_en', { length: 255 }).notNull(),
  descriptionAr: text('description_ar').notNull(),
  category: varchar('category', { length: 64 }).notNull(), // 'conversation' | 'job_interview' | 'travel' | 'study' | 'school' | 'intensive_60'
  targetGoal: varchar('target_goal', { length: 64 }).notNull(),
  targetAgeGroup: varchar('target_age_group', { length: 32 }).notNull(), // 'kids_6_10' | 'teens_11_15' | 'youth_16_20' | 'adults_21_plus'
  targetLevel: varchar('target_level', { length: 16 }).notNull(), // 'beginner' | 'elementary' | 'intermediate' | 'advanced'
  durationDays: integer('duration_days').notNull().default(60),
  totalLessons: integer('total_lessons').notNull().default(60),
  badgeRewardId: varchar('badge_reward_id', { length: 64 }),
  isActive: boolean('is_active').notNull().default(true),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

/**
 * 19. Plan Days Table
 * Day 1 to Day 60 daily sequence.
 */
export const planDays = pgTable(
  'plan_days',
  {
    id: varchar('id', { length: 128 }).primaryKey(),
    planId: varchar('plan_id', { length: 64 }).notNull(),
    dayNumber: integer('day_number').notNull(),
    titleAr: varchar('title_ar', { length: 255 }).notNull(),
    descriptionAr: text('description_ar').notNull(),
    focusTopic: varchar('focus_topic', { length: 128 }).notNull(),
    totalXpReward: integer('total_xp_reward').notNull().default(80),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [
    uniqueIndex('plan_day_idx').on(table.planId, table.dayNumber),
  ]
);

/**
 * 20. Plan Activities Table
 * Ordered micro-activities per day (quick review, new vocab, listening, dialogue, grammar, pronunciation, game, quiz, summary).
 */
export const planActivities = pgTable('plan_activities', {
  id: varchar('id', { length: 128 }).primaryKey(),
  planDayId: varchar('plan_day_id', { length: 128 }).notNull(),
  stepOrder: integer('step_order').notNull(), // 1 to 10
  activityType: varchar('activity_type', { length: 64 }).notNull(), // 'quick_review' | 'new_vocabulary' | 'listening' | 'dialogue' | 'grammar_bite' | 'pronunciation_drill' | 'mini_game' | 'quick_quiz' | 'day_summary'
  titleAr: varchar('title_ar', { length: 255 }).notNull(),
  contentPayload: jsonb('content_payload').notNull().default({}),
  audioAssetId: varchar('audio_asset_id', { length: 128 }),
  xpReward: integer('xp_reward').notNull().default(10),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

/**
 * 21. Student Plan Progress Table
 * Student's current active progress through an enrolled curriculum plan.
 */
export const studentPlanProgress = pgTable(
  'student_plan_progress',
  {
    id: varchar('id', { length: 128 }).primaryKey(),
    studentId: varchar('student_id', { length: 128 }).notNull(),
    planId: varchar('plan_id', { length: 64 }).notNull(),
    currentDay: integer('current_day').notNull().default(1),
    completedDays: integer('completed_days').notNull().default(0),
    status: varchar('status', { length: 32 }).notNull().default('active'), // 'active' | 'completed' | 'paused'
    startedAt: timestamp('started_at', { withTimezone: true }).notNull().defaultNow(),
    lastActivityAt: timestamp('last_activity_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [
    uniqueIndex('student_plan_idx').on(table.studentId, table.planId),
  ]
);

/**
 * 22. Student Activity Logs Table
 * Granular completion tracking per day activity.
 */
export const studentActivityLogs = pgTable(
  'student_activity_logs',
  {
    id: varchar('id', { length: 128 }).primaryKey(),
    studentId: varchar('student_id', { length: 128 }).notNull(),
    planDayId: varchar('plan_day_id', { length: 128 }).notNull(),
    activityId: varchar('activity_id', { length: 128 }).notNull(),
    score: integer('score').notNull().default(100),
    xpEarned: integer('xp_earned').notNull().default(10),
    isCompleted: boolean('is_completed').notNull().default(true),
    completedAt: timestamp('completed_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [
    uniqueIndex('student_activity_idx').on(table.studentId, table.activityId),
  ]
);

/**
 * 23. Student Codes Table
 * Quick-login identifier paired with scrypt-hashed PIN for student accounts.
 */
export const studentCodes = pgTable('student_codes', {
  id: varchar('id', { length: 128 }).primaryKey(),
  studentId: varchar('student_id', { length: 128 }).notNull().unique(),
  studentCode: varchar('student_code', { length: 32 }).notNull().unique(), // e.g. 'ST-8F4K29'
  pinHash: varchar('pin_hash', { length: 512 }).notNull(),
  schoolId: varchar('school_id', { length: 128 }),
  classroomId: varchar('classroom_id', { length: 128 }),
  teacherId: varchar('teacher_id', { length: 128 }),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

/**
 * 24. Points Transactions Table
 * Server-authoritative points ledger recording every single point source.
 */
export const pointsTransactions = pgTable(
  'points_transactions',
  {
    id: varchar('id', { length: 128 }).primaryKey(),
    studentId: varchar('student_id', { length: 128 }).notNull(),
    amount: integer('amount').notNull(),
    reasonCode: varchar('reason_code', { length: 64 }).notNull(), // 'lesson_completed' | 'correct_answer' | 'exam_completed' | 'game_completed' | 'daily_streak' | 'plan_day_finished'
    descriptionAr: varchar('description_ar', { length: 255 }).notNull(),
    referenceId: varchar('reference_id', { length: 128 }),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [
    index('points_tx_student_date_idx').on(table.studentId, table.createdAt),
  ]
);

/**
 * 25. Student Mistakes Table
 * Spaced-repetition error tracking (SuperMemo-2 / Leitner intervals) for continuous mastery.
 */
export const studentMistakes = pgTable(
  'student_mistakes',
  {
    id: varchar('id', { length: 128 }).primaryKey(),
    studentId: varchar('student_id', { length: 128 }).notNull(),
    contentId: varchar('content_id', { length: 128 }).notNull(),
    skillType: varchar('skill_type', { length: 64 }).notNull(), // 'vocabulary' | 'grammar' | 'listening' | 'spelling' | 'pronunciation'
    itemPrompt: varchar('item_prompt', { length: 512 }).notNull(),
    correctAnswer: varchar('correct_answer', { length: 512 }).notNull(),
    studentLastWrongAnswer: varchar('student_last_wrong_answer', { length: 512 }),
    mistakeCount: integer('mistake_count').notNull().default(1),
    intervalDays: integer('interval_days').notNull().default(1),
    easeFactor: real('ease_factor').notNull().default(2.5),
    repetitions: integer('repetitions').notNull().default(0),
    mastered: boolean('mastered').notNull().default(false),
    lastMistakeAt: timestamp('last_mistake_at', { withTimezone: true }).notNull().defaultNow(),
    nextReviewAt: timestamp('next_review_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [
    uniqueIndex('student_mistake_idx').on(table.studentId, table.contentId),
    index('student_review_idx').on(table.studentId, table.nextReviewAt, table.mastered),
  ]
);

/**
 * 26. Teacher Exams Table
 * Exams created by teachers for classes with dates, duration, and pass requirements.
 */
export const exams = pgTable('exams', {
  id: varchar('id', { length: 128 }).primaryKey(),
  teacherId: varchar('teacher_id', { length: 128 }).notNull(),
  schoolId: varchar('school_id', { length: 128 }),
  classroomId: varchar('classroom_id', { length: 128 }),
  title: varchar('title', { length: 255 }).notNull(),
  description: text('description'),
  durationMinutes: integer('duration_minutes').notNull().default(30),
  startDate: timestamp('start_date', { withTimezone: true }).notNull(),
  endDate: timestamp('end_date', { withTimezone: true }).notNull(),
  totalPoints: integer('total_points').notNull().default(100),
  passPoints: integer('pass_points').notNull().default(60),
  isPublished: boolean('is_published').notNull().default(false),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

/**
 * 27. Exam Questions Table
 * Questions created by teachers with server-authoritative keys across 8 question types.
 */
export const examQuestions = pgTable('exam_questions', {
  id: varchar('id', { length: 128 }).primaryKey(),
  examId: varchar('exam_id', { length: 128 }).notNull(),
  questionOrder: integer('question_order').notNull(),
  questionType: varchar('question_type', { length: 64 }).notNull(), // 'multiple_choice' | 'true_false' | 'fill_in_the_blank' | 'matching' | 'word_order' | 'image_choice' | 'listening' | 'free_writing'
  questionText: text('question_text').notNull(),
  instructionsAr: varchar('instructions_ar', { length: 512 }),
  audioAssetUrl: varchar('audio_asset_url', { length: 512 }),
  imageAssetUrl: varchar('image_asset_url', { length: 512 }),
  options: jsonb('options').$type<any[]>().notNull().default([]),
  correctAnswer: jsonb('correct_answer').notNull(),
  points: integer('points').notNull().default(5),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

/**
 * 28. Exam Submissions Table
 * Student test submissions evaluated automatically in backend logic with mistake breakdown.
 */
export const examSubmissions = pgTable(
  'exam_submissions',
  {
    id: varchar('id', { length: 128 }).primaryKey(),
    examId: varchar('exam_id', { length: 128 }).notNull(),
    studentId: varchar('student_id', { length: 128 }).notNull(),
    score: integer('score').notNull().default(0),
    totalPoints: integer('total_points').notNull().default(100),
    percentage: real('percentage').notNull().default(0.0),
    isPassed: boolean('is_passed').notNull().default(false),
    studentAnswers: jsonb('student_answers').$type<Record<string, any>>().notNull().default({}),
    evaluatedMistakes: jsonb('evaluated_mistakes').$type<any[]>().notNull().default([]),
    submittedAt: timestamp('submitted_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [
    uniqueIndex('exam_student_submission_idx').on(table.examId, table.studentId),
  ]
);

/**
 * 29. Educational Games Table
 * Teacher/Admin managed educational games hub.
 */
export const educationalGames = pgTable('educational_games', {
  id: varchar('id', { length: 64 }).primaryKey(),
  nameAr: varchar('name_ar', { length: 255 }).notNull(),
  nameEn: varchar('name_en', { length: 255 }).notNull(),
  gameType: varchar('game_type', { length: 64 }).notNull(), // 'word_match' | 'sentence_scramble' | 'memory_cards' | 'audio_challenge' | 'speed_quiz'
  targetAgeGroup: varchar('target_age_group', { length: 32 }).notNull().default('all'),
  difficulty: varchar('difficulty', { length: 32 }).notNull().default('beginner'),
  classroomId: varchar('classroom_id', { length: 128 }),
  durationSeconds: integer('duration_seconds').notNull().default(180),
  xpReward: integer('xp_reward').notNull().default(25),
  isActive: boolean('is_active').notNull().default(true),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

/**
 * 30. Game Questions Table
 * Questions and media assets linked to games.
 */
export const gameQuestions = pgTable('game_questions', {
  id: varchar('id', { length: 128 }).primaryKey(),
  gameId: varchar('game_id', { length: 64 }).notNull(),
  prompt: varchar('prompt', { length: 512 }).notNull(),
  correctAnswer: varchar('correct_answer', { length: 512 }).notNull(),
  distractors: jsonb('distractors').$type<string[]>().notNull().default([]),
  imageUrl: varchar('image_url', { length: 512 }),
  audioUrl: varchar('audio_url', { length: 512 }),
  points: integer('points').notNull().default(5),
});

/**
 * 31. Audio Assets Table
 * Pre-recorded audio files catalog for zero-TTS repeat usage.
 */
export const audioAssets = pgTable(
  'audio_assets',
  {
    id: varchar('id', { length: 128 }).primaryKey(),
    category: varchar('category', { length: 64 }).notNull(), // 'teacher_voice' | 'word_pronunciation' | 'sentence_audio' | 'instructions' | 'encouragement'
    textContent: varchar('text_content', { length: 512 }).notNull(),
    accent: varchar('accent', { length: 32 }).notNull().default('american'),
    audioUrl: varchar('audio_url', { length: 512 }).notNull(),
    speakerName: varchar('speaker_name', { length: 128 }).default('Teacher'),
    fileSizeBytes: integer('file_size_bytes'),
    durationSeconds: real('duration_seconds'),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [
    index('audio_content_category_idx').on(table.textContent, table.category),
  ]
);

/**
 * 32. Encouragement Templates Table
 * Pre-authored friendly, motivating Arabic phrases chosen dynamically based on student state.
 */
export const encouragementTemplates = pgTable('encouragement_templates', {
  id: varchar('id', { length: 64 }).primaryKey(),
  triggerContext: varchar('trigger_context', { length: 64 }).notNull(), // 'day_start' | 'streak_milestone' | 'high_score' | 'after_mistake' | 'day_complete'
  tone: varchar('tone', { length: 32 }).notNull().default('warm_friendly'),
  messageAr: varchar('message_ar', { length: 512 }).notNull(),
});
