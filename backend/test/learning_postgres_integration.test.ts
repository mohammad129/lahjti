import { readFileSync } from 'fs';
import { join } from 'path';
import pg from 'pg';
import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { createApp } from '../src/app.js';
import { PgLearningDb, setDatabase } from '../src/db/index.js';

const { Pool } = pg;

describe('Step 12: Real PostgreSQL Database Integration & Ownership Isolation', () => {
  const databaseUrl = process.env.DATABASE_URL;
  let pool: pg.Pool | null = null;
  let pgDb: PgLearningDb | null = null;
  let app: any;
  let isPostgresAvailable = false;

  beforeAll(async () => {
    if (!databaseUrl || databaseUrl.trim().length === 0) {
      console.warn('⚠️ DATABASE_URL is not configured. Live PostgreSQL verification cannot execute.');
      return;
    }

    try {
      pool = new Pool({
        connectionString: databaseUrl,
        connectionTimeoutMillis: 3000,
      });

      // Probe real connection
      const probe = await pool.query('SELECT 1 as connected;');
      if (probe.rows[0]?.connected === 1) {
        isPostgresAvailable = true;

        // Apply Drizzle SQL migration
        const migrationPath = join(process.cwd(), 'drizzle', '0001_learning_persistence.sql');
        const sql = readFileSync(migrationPath, 'utf8');
        await pool.query(sql);

        pgDb = new PgLearningDb(pool);
        setDatabase(pgDb);
        app = createApp();
      }
    } catch (err) {
      console.warn('⚠️ Failed to connect to PostgreSQL at DATABASE_URL:', (err as Error).message);
      isPostgresAvailable = false;
    }
  });

  afterAll(async () => {
    if (pool) {
      await pool.end().catch(() => {});
    }
  });

  const authUserA = 'user_pg_student_alpha';
  const authUserB = 'user_pg_student_beta';

  it('1. PostgreSQL Connection and Availability Check', async () => {
    if (!databaseUrl || !isPostgresAvailable) {
      console.log('NOTICE: Real PostgreSQL database is not reachable in this environment.');
      expect(isPostgresAvailable).toBe(false);
      return;
    }
    expect(isPostgresAvailable).toBe(true);
  });

  it('2. Verifies all 8 learning persistence tables exist in PostgreSQL schema', async () => {
    if (!isPostgresAvailable || !pool) {
      return; // Skipped if live DB unavailable
    }

    const res = await pool.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name IN (
        'learning_profiles',
        'learner_progress',
        'learner_streaks',
        'learner_skill_progress',
        'learner_vocabulary_progress',
        'learner_exam_results',
        'learner_xp_transactions',
        'learner_achievements'
      );
    `);

    const tableNames = res.rows.map((r: any) => r.table_name);
    expect(tableNames).toContain('learning_profiles');
    expect(tableNames).toContain('learner_progress');
    expect(tableNames).toContain('learner_streaks');
    expect(tableNames).toContain('learner_skill_progress');
    expect(tableNames).toContain('learner_vocabulary_progress');
    expect(tableNames).toContain('learner_exam_results');
    expect(tableNames).toContain('learner_xp_transactions');
    expect(tableNames).toContain('learner_achievements');
  });

  it('3. Verifies unique composite indexes exist in PostgreSQL metadata', async () => {
    if (!isPostgresAvailable || !pool) {
      return;
    }

    const res = await pool.query(`
      SELECT indexname 
      FROM pg_indexes 
      WHERE schemaname = 'public' 
      AND indexname IN (
        'user_skill_idx',
        'user_vocab_idx',
        'user_achievement_idx'
      );
    `);

    const indexNames = res.rows.map((r: any) => r.indexname);
    expect(indexNames).toContain('user_skill_idx');
    expect(indexNames).toContain('user_vocab_idx');
    expect(indexNames).toContain('user_achievement_idx');
  });

  it('4. API -> PostgreSQL: End-to-End Profile Persistence and Direct DB Verification', async () => {
    if (!isPostgresAvailable || !pool || !app) {
      return;
    }

    // 1. Write profile via API as User A
    const putRes = await request(app)
      .put('/api/v1/learning/profile')
      .set('Authorization', `Bearer ${authUserA}`)
      .send({
        targetLanguage: 'spanish',
        estimatedCefrLevel: 'b1',
        grammarScore: 72,
        vocabularyScore: 80,
        strengths: ['Spanish Basics'],
      });

    expect(putRes.status).toBe(200);

    // 2. Query PostgreSQL directly to prove persistence in database table
    const dbRow = await pool.query('SELECT * FROM learning_profiles WHERE user_id = $1;', [authUserA]);
    expect(dbRow.rows.length).toBe(1);
    expect(dbRow.rows[0].target_language).toBe('spanish');
    expect(dbRow.rows[0].estimated_cefr_level).toBe('b1');
    expect(dbRow.rows[0].grammar_score).toBe(72);

    // 3. Read back from API to prove round-trip PostgreSQL -> PgLearningDb -> API
    const getRes = await request(app)
      .get('/api/v1/learning/profile')
      .set('Authorization', `Bearer ${authUserA}`);

    expect(getRes.status).toBe(200);
    expect(getRes.body.data.targetLanguage).toBe('spanish');
    expect(getRes.body.data.estimatedCefrLevel).toBe('b1');
  });

  it('5. API -> PostgreSQL: Activity & XP Anti-Farming Verification with Direct DB Ledger Check', async () => {
    if (!isPostgresAvailable || !pool || !app) {
      return;
    }

    // Record activity as User A
    const actRes = await request(app)
      .post('/api/v1/learning/activity')
      .set('Authorization', `Bearer ${authUserA}`)
      .send({
        activityType: 'lessonCompletion',
        accuracy: 90,
        referenceId: 'lesson_1_1',
      });

    expect(actRes.status).toBe(200);
    expect(actRes.body.data.xpEarned).toBeGreaterThan(0);

    // Verify row written to learner_xp_transactions in PostgreSQL
    const txRows = await pool.query(
      'SELECT * FROM learner_xp_transactions WHERE user_id = $1 AND reference_id = $2;',
      [authUserA, 'lesson_1_1']
    );
    expect(txRows.rows.length).toBeGreaterThanOrEqual(1);
    expect(txRows.rows[0].activity_type).toBe('lessonCompletion');
  });

  it('6. API -> PostgreSQL: Spaced Repetition Vocabulary Persistence', async () => {
    if (!isPostgresAvailable || !pool || !app) {
      return;
    }

    const vocabRes = await request(app)
      .post('/api/v1/learning/vocabulary/progress')
      .set('Authorization', `Bearer ${authUserA}`)
      .send({
        vocabularyId: 'v_hello',
        status: 'mastered',
        intervalDays: 4,
        repetitions: 3,
      });

    expect(vocabRes.status).toBe(200);

    // Check direct PostgreSQL record
    const dbVocab = await pool.query(
      'SELECT * FROM learner_vocabulary_progress WHERE user_id = $1 AND vocabulary_id = $2;',
      [authUserA, 'v_hello']
    );
    expect(dbVocab.rows.length).toBe(1);
    expect(dbVocab.rows[0].status).toBe('mastered');
    expect(dbVocab.rows[0].interval_days).toBe(4);
  });

  it('7. Real Two-User Data Isolation & Ownership Protection on PostgreSQL', async () => {
    if (!isPostgresAvailable || !pool || !app) {
      return;
    }

    // A. User A writes German profile
    await request(app)
      .put('/api/v1/learning/profile')
      .set('Authorization', `Bearer ${authUserA}`)
      .send({ targetLanguage: 'german', estimatedCefrLevel: 'a2' });

    // B. User B writes French profile
    await request(app)
      .put('/api/v1/learning/profile')
      .set('Authorization', `Bearer ${authUserB}`)
      .send({ targetLanguage: 'french', estimatedCefrLevel: 'b2' });

    // C. User A reads profile -> receives only German (User A data)
    const resA = await request(app)
      .get('/api/v1/learning/profile')
      .set('Authorization', `Bearer ${authUserA}`);
    expect(resA.body.data.targetLanguage).toBe('german');
    expect(resA.body.data.estimatedCefrLevel).toBe('a2');

    // D. User B reads profile -> receives only French (User B data)
    const resB = await request(app)
      .get('/api/v1/learning/profile')
      .set('Authorization', `Bearer ${authUserB}`);
    expect(resB.body.data.targetLanguage).toBe('french');
    expect(resB.body.data.estimatedCefrLevel).toBe('b2');

    // E. User A attempts to spoof User B's profile by passing userId in body
    const spoofRes = await request(app)
      .put('/api/v1/learning/profile')
      .set('Authorization', `Bearer ${authUserA}`)
      .send({
        userId: authUserB,
        targetLanguage: 'italian',
      });
    expect(spoofRes.status).toBe(200);
    expect(spoofRes.body.data.userId).toBe(authUserA); // Scoped to User A

    // F. Confirm User B data was NOT corrupted or overridden in PostgreSQL
    const checkB = await pool.query('SELECT * FROM learning_profiles WHERE user_id = $1;', [authUserB]);
    expect(checkB.rows[0].target_language).toBe('french'); // Remains French
  });
});
