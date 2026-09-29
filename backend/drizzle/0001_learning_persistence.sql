-- Migration: 0001_learning_persistence
-- Lahjti (لهجتي) Secure User Learning Data & Gamification Persistence

-- 1. Learning Profiles
CREATE TABLE IF NOT EXISTS "learning_profiles" (
  "user_id" varchar(128) PRIMARY KEY,
  "target_language" varchar(64) NOT NULL DEFAULT 'english',
  "age_group" varchar(32) NOT NULL DEFAULT 'age19_25',
  "native_language" varchar(32) NOT NULL DEFAULT 'arabic',
  "learning_goal" varchar(64) NOT NULL DEFAULT 'generalFluency',
  "experience_level" varchar(64) NOT NULL DEFAULT 'beginnerWithBasics',
  "estimated_cefr_level" varchar(16) NOT NULL DEFAULT 'a1',
  "current_lesson_id" varchar(64) NOT NULL DEFAULT 'lesson_1_1',
  "selected_tutor_id" varchar(32) NOT NULL DEFAULT 'abbas',
  "grammar_score" integer NOT NULL DEFAULT 50,
  "vocabulary_score" integer NOT NULL DEFAULT 50,
  "comprehension_score" integer NOT NULL DEFAULT 50,
  "communication_score" integer NOT NULL DEFAULT 50,
  "pronunciation_score" integer,
  "strengths" jsonb NOT NULL DEFAULT '[]'::jsonb,
  "weaknesses" jsonb NOT NULL DEFAULT '[]'::jsonb,
  "recommended_focus_areas" jsonb NOT NULL DEFAULT '[]'::jsonb,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);

-- 2. Learner Progress
CREATE TABLE IF NOT EXISTS "learner_progress" (
  "user_id" varchar(128) PRIMARY KEY,
  "completed_lesson_ids" jsonb NOT NULL DEFAULT '[]'::jsonb,
  "in_progress_lesson_id" varchar(64) DEFAULT 'lesson_1_1',
  "mastered_vocab_count" integer NOT NULL DEFAULT 0,
  "review_queue_count" integer NOT NULL DEFAULT 0,
  "total_minutes_learned" integer NOT NULL DEFAULT 0,
  "total_xp" integer NOT NULL DEFAULT 0,
  "tutor_turns_count" integer NOT NULL DEFAULT 0,
  "completed_exams_count" integer NOT NULL DEFAULT 0,
  "last_session_date" timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);

-- 3. Learner Streaks
CREATE TABLE IF NOT EXISTS "learner_streaks" (
  "user_id" varchar(128) PRIMARY KEY,
  "current_streak" integer NOT NULL DEFAULT 0,
  "longest_streak" integer NOT NULL DEFAULT 0,
  "total_active_days" integer NOT NULL DEFAULT 0,
  "last_active_date" timestamp with time zone,
  "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);

-- 4. Learner Skill Progress
CREATE TABLE IF NOT EXISTS "learner_skill_progress" (
  "id" varchar(128) PRIMARY KEY,
  "user_id" varchar(128) NOT NULL,
  "skill" varchar(64) NOT NULL,
  "level_score" integer NOT NULL DEFAULT 45,
  "assessed_attempts" integer NOT NULL DEFAULT 1,
  "last_updated" timestamp with time zone NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS "user_skill_idx" ON "learner_skill_progress" ("user_id", "skill");

-- 5. Learner Vocabulary Progress
CREATE TABLE IF NOT EXISTS "learner_vocabulary_progress" (
  "id" varchar(128) PRIMARY KEY,
  "user_id" varchar(128) NOT NULL,
  "vocabulary_id" varchar(64) NOT NULL,
  "status" varchar(32) NOT NULL DEFAULT 'learning',
  "interval_days" integer NOT NULL DEFAULT 1,
  "ease_factor" real NOT NULL DEFAULT 2.5,
  "repetitions" integer NOT NULL DEFAULT 0,
  "next_review_date" timestamp with time zone NOT NULL DEFAULT now(),
  "last_reviewed_date" timestamp with time zone,
  "accuracy_percentage" integer NOT NULL DEFAULT 0,
  "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS "user_vocab_idx" ON "learner_vocabulary_progress" ("user_id", "vocabulary_id");

-- 6. Learner Exam Results
CREATE TABLE IF NOT EXISTS "learner_exam_results" (
  "id" varchar(128) PRIMARY KEY,
  "user_id" varchar(128) NOT NULL,
  "exam_id" varchar(64) NOT NULL,
  "exam_type" varchar(32) NOT NULL,
  "title_arabic" varchar(255) NOT NULL,
  "overall_score" integer NOT NULL,
  "earned_points" integer NOT NULL,
  "total_points" integer NOT NULL,
  "is_passed" boolean NOT NULL,
  "projected_cefr_level" varchar(16) NOT NULL,
  "skill_scores" jsonb NOT NULL DEFAULT '[]'::jsonb,
  "strengths" jsonb NOT NULL DEFAULT '[]'::jsonb,
  "improvement_areas" jsonb NOT NULL DEFAULT '[]'::jsonb,
  "recommendations" jsonb NOT NULL DEFAULT '[]'::jsonb,
  "completed_at" timestamp with time zone NOT NULL DEFAULT now()
);

-- 7. Learner XP Transactions
CREATE TABLE IF NOT EXISTS "learner_xp_transactions" (
  "id" varchar(128) PRIMARY KEY,
  "user_id" varchar(128) NOT NULL,
  "activity_type" varchar(64) NOT NULL,
  "xp_earned" integer NOT NULL,
  "reference_id" varchar(128),
  "created_at" timestamp with time zone NOT NULL DEFAULT now()
);

-- 8. Learner Achievements
CREATE TABLE IF NOT EXISTS "learner_achievements" (
  "id" varchar(128) PRIMARY KEY,
  "user_id" varchar(128) NOT NULL,
  "achievement_id" varchar(64) NOT NULL,
  "is_unlocked" boolean NOT NULL DEFAULT false,
  "current_value" integer NOT NULL DEFAULT 0,
  "unlocked_at" timestamp with time zone,
  "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS "user_achievement_idx" ON "learner_achievements" ("user_id", "achievement_id");
