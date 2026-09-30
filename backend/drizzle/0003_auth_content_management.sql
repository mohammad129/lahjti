-- Public pilot authentication and server-managed learning content.
CREATE TABLE IF NOT EXISTS "users" (
  "id" varchar(128) PRIMARY KEY,
  "email" varchar(320) NOT NULL UNIQUE,
  "password_hash" varchar(512) NOT NULL,
  "role" varchar(32) NOT NULL DEFAULT 'student',
  "status" varchar(32) NOT NULL DEFAULT 'active',
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "auth_sessions" (
  "id" varchar(128) PRIMARY KEY,
  "user_id" varchar(128) NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
  "expires_at" timestamp with time zone NOT NULL,
  "revoked_at" timestamp with time zone,
  "created_at" timestamp with time zone NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS "auth_sessions_user_idx" ON "auth_sessions" ("user_id");

CREATE TABLE IF NOT EXISTS "content_lessons" (
  "id" varchar(128) PRIMARY KEY,
  "title" varchar(255) NOT NULL,
  "description" varchar(2000) NOT NULL DEFAULT '',
  "language" varchar(64) NOT NULL,
  "cefr" varchar(16) NOT NULL,
  "age_group" varchar(32) NOT NULL,
  "learning_goal" varchar(64) NOT NULL,
  "skill" varchar(64) NOT NULL,
  "steps" jsonb NOT NULL DEFAULT '[]'::jsonb,
  "published" boolean NOT NULL DEFAULT false,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "content_vocabulary_items" (
  "id" varchar(128) PRIMARY KEY,
  "word" varchar(255) NOT NULL,
  "translation" varchar(512) NOT NULL,
  "language" varchar(64) NOT NULL,
  "cefr" varchar(16) NOT NULL,
  "topic" varchar(128) NOT NULL,
  "example" varchar(2000) NOT NULL DEFAULT '',
  "pronunciation" varchar(512) NOT NULL DEFAULT '',
  "difficulty" varchar(32) NOT NULL,
  "published" boolean NOT NULL DEFAULT false,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS "content_lessons_published_idx" ON "content_lessons" ("published", "language", "cefr");
CREATE INDEX IF NOT EXISTS "content_vocabulary_published_idx" ON "content_vocabulary_items" ("published", "language", "cefr");
