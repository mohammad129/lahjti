-- Migration: 0002_school_monetization_ai_metering
-- Lahjti (لهجتي) School Multi-tenancy, Monetization, and AI Telemetry Tables

-- 9. Schools Table
CREATE TABLE IF NOT EXISTS "schools" (
  "id" varchar(128) PRIMARY KEY,
  "name" varchar(255) NOT NULL,
  "school_code" varchar(64) NOT NULL UNIQUE,
  "created_at" timestamp with time zone NOT NULL DEFAULT now()
);

-- 10. School Memberships Table
CREATE TABLE IF NOT EXISTS "school_memberships" (
  "id" varchar(128) PRIMARY KEY,
  "school_id" varchar(128) NOT NULL,
  "user_id" varchar(128) NOT NULL,
  "role" varchar(32) NOT NULL DEFAULT 'student',
  "status" varchar(32) NOT NULL DEFAULT 'active',
  "display_name" varchar(255),
  "created_at" timestamp with time zone NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS "school_user_role_idx" ON "school_memberships" ("school_id", "user_id");

-- 11. Classrooms Table
CREATE TABLE IF NOT EXISTS "classrooms" (
  "id" varchar(128) PRIMARY KEY,
  "school_id" varchar(128) NOT NULL,
  "teacher_id" varchar(128) NOT NULL,
  "grade" varchar(64) NOT NULL,
  "section" varchar(32) NOT NULL DEFAULT 'A',
  "name" varchar(255) NOT NULL,
  "created_at" timestamp with time zone NOT NULL DEFAULT now()
);

-- 12. Classroom Students Table
CREATE TABLE IF NOT EXISTS "classroom_students" (
  "id" varchar(128) PRIMARY KEY,
  "classroom_id" varchar(128) NOT NULL,
  "student_id" varchar(128) NOT NULL,
  "joined_at" timestamp with time zone NOT NULL DEFAULT now(),
  "status" varchar(32) NOT NULL DEFAULT 'active'
);
CREATE UNIQUE INDEX IF NOT EXISTS "classroom_student_idx" ON "classroom_students" ("classroom_id", "student_id");

-- 13. School Daily Tasks Table
CREATE TABLE IF NOT EXISTS "school_daily_tasks" (
  "id" varchar(128) PRIMARY KEY,
  "student_id" varchar(128) NOT NULL,
  "task_date" varchar(16) NOT NULL,
  "type" varchar(64) NOT NULL,
  "title" varchar(255) NOT NULL,
  "description" varchar(512) NOT NULL,
  "skill" varchar(64) NOT NULL,
  "difficulty" varchar(32) NOT NULL DEFAULT 'beginner',
  "duration_minutes" integer NOT NULL DEFAULT 5,
  "status" varchar(32) NOT NULL DEFAULT 'pending',
  "progress" real NOT NULL DEFAULT 0.0,
  "xp_reward" integer NOT NULL DEFAULT 15,
  "action_route" varchar(255) NOT NULL DEFAULT '/learning',
  "lesson_id" varchar(64),
  "game_id" varchar(64),
  "is_for_child" boolean NOT NULL DEFAULT false,
  "completed_at" timestamp with time zone,
  "created_at" timestamp with time zone NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS "student_date_task_idx" ON "school_daily_tasks" ("student_id", "task_date", "type");

-- 14. School Game Results Table
CREATE TABLE IF NOT EXISTS "school_game_results" (
  "id" varchar(128) PRIMARY KEY,
  "game_id" varchar(64) NOT NULL,
  "task_id" varchar(128),
  "student_id" varchar(128) NOT NULL,
  "score" integer NOT NULL,
  "correct_answers" integer NOT NULL,
  "incorrect_answers" integer NOT NULL,
  "skill" varchar(64) NOT NULL,
  "vocabulary_ids" jsonb NOT NULL DEFAULT '[]'::jsonb,
  "earned_xp" integer NOT NULL DEFAULT 0,
  "completed_at" timestamp with time zone NOT NULL DEFAULT now()
);

-- 15. User Subscriptions Table
CREATE TABLE IF NOT EXISTS "user_subscriptions" (
  "id" varchar(128) PRIMARY KEY,
  "user_id" varchar(128) NOT NULL,
  "account_context" varchar(32) NOT NULL DEFAULT 'individual',
  "role" varchar(32) NOT NULL DEFAULT 'individual',
  "status" varchar(32) NOT NULL DEFAULT 'trial',
  "plan_id" varchar(64) NOT NULL DEFAULT 'individual_monthly',
  "price_usd" real NOT NULL DEFAULT 10.0,
  "trial_starts_at" timestamp with time zone,
  "trial_ends_at" timestamp with time zone,
  "trial_duration_days" integer NOT NULL DEFAULT 3,
  "current_period_start" timestamp with time zone,
  "current_period_end" timestamp with time zone,
  "subscription_expires_at" timestamp with time zone,
  "cancelled_at" timestamp with time zone,
  "school_id" varchar(128),
  "school_code" varchar(64),
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS "user_subscription_user_idx" ON "user_subscriptions" ("user_id");
CREATE INDEX IF NOT EXISTS "user_subscription_status_idx" ON "user_subscriptions" ("status");
CREATE INDEX IF NOT EXISTS "user_subscription_school_idx" ON "user_subscriptions" ("school_id");

-- 16. AI Usage Records Table
CREATE TABLE IF NOT EXISTS "ai_usage_records" (
  "id" varchar(128) PRIMARY KEY,
  "user_id" varchar(128) NOT NULL,
  "usage_date" varchar(10) NOT NULL,
  "feature" varchar(64) NOT NULL,
  "model_used" varchar(64) NOT NULL,
  "request_count" integer NOT NULL DEFAULT 1,
  "input_tokens" integer NOT NULL DEFAULT 0,
  "output_tokens" integer NOT NULL DEFAULT 0,
  "voice_seconds" real NOT NULL DEFAULT 0.0,
  "cached_responses_count" integer NOT NULL DEFAULT 0,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS "user_date_feature_idx" ON "ai_usage_records" ("user_id", "usage_date", "feature");
CREATE INDEX IF NOT EXISTS "usage_date_idx" ON "ai_usage_records" ("usage_date");
CREATE INDEX IF NOT EXISTS "usage_user_idx" ON "ai_usage_records" ("user_id");
