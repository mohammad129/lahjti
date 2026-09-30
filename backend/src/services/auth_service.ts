import crypto from 'crypto';
import pg from 'pg';
import { config } from '../config/env.js';
import { AiServiceUnavailableError, UnauthorizedError, ValidationError } from '../errors/api_error.js';

type Role = 'admin' | 'teacher' | 'student';
type User = { id: string; email: string; passwordHash: string; role: Role; status: string };
const memoryUsers = new Map<string, User>();
const memorySessions = new Map<string, { userId: string; expiresAt: Date; revoked: boolean }>();
let pool: pg.Pool | undefined;
let schemaReady: Promise<void> | undefined;

function database(): pg.Pool | undefined {
  if (!config.DATABASE_URL) return undefined;
  pool ??= new pg.Pool({ connectionString: config.DATABASE_URL });
  return pool;
}

/**
 * Auth must remain available even when a legacy, unrelated migration fails.
 * This deliberately contains only the two tables owned by AuthService and is
 * idempotent, so every production instance can safely call it before use.
 */
async function ensureAuthSchema(db: pg.Pool): Promise<void> {
  schemaReady ??= (async () => {
    await db.query(`
      CREATE TABLE IF NOT EXISTS users (
        id varchar(128) PRIMARY KEY,
        email varchar(320) NOT NULL UNIQUE,
        password_hash varchar(512) NOT NULL,
        role varchar(32) NOT NULL DEFAULT 'student',
        status varchar(32) NOT NULL DEFAULT 'active',
        created_at timestamp with time zone NOT NULL DEFAULT now(),
        updated_at timestamp with time zone NOT NULL DEFAULT now()
      );
      CREATE TABLE IF NOT EXISTS auth_sessions (
        id varchar(128) PRIMARY KEY,
        user_id varchar(128) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        expires_at timestamp with time zone NOT NULL,
        revoked_at timestamp with time zone,
        created_at timestamp with time zone NOT NULL DEFAULT now()
      );
      CREATE INDEX IF NOT EXISTS auth_sessions_user_idx ON auth_sessions (user_id);
    `);
  })();
  try {
    await schemaReady;
  } catch (error) {
    schemaReady = undefined;
    throw error;
  }
}

function hashPassword(password: string, salt = crypto.randomBytes(16).toString('base64url')): string {
  const derived = crypto.scryptSync(password, salt, 64).toString('base64url');
  return `scrypt$${salt}$${derived}`;
}
function verifyPassword(password: string, encoded: string): boolean {
  const [, salt, expected] = encoded.split('$');
  if (!salt || !expected) return false;
  const actual = crypto.scryptSync(password, salt, 64).toString('base64url');
  return actual.length === expected.length && crypto.timingSafeEqual(Buffer.from(actual), Buffer.from(expected));
}
function b64(value: unknown): string { return Buffer.from(JSON.stringify(value)).toString('base64url'); }

export class AuthService {
  async isSessionActive(sessionId: string, userId: string): Promise<boolean> {
    const db = database();
    if (db) {
      await ensureAuthSchema(db);
      const result = await db.query(
        'SELECT 1 FROM auth_sessions WHERE id=$1 AND user_id=$2 AND revoked_at IS NULL AND expires_at > now()',
        [sessionId, userId],
      );
      return result.rowCount === 1;
    }
    const session = memorySessions.get(sessionId);
    return Boolean(session && !session.revoked && session.userId === userId && session.expiresAt > new Date());
  }
  async register(emailInput: string, password: string, role: Role = 'student') {
    const email = emailInput.trim().toLowerCase();
    if (!/^\S+@\S+\.\S+$/.test(email)) throw new ValidationError('A valid email is required');
    if (password.length < 8) throw new ValidationError('Password must contain at least 8 characters');
    const id = `usr_${crypto.randomUUID()}`;
    const user: User = { id, email, passwordHash: hashPassword(password), role, status: 'active' };
    const db = database();
    if (db) {
      try {
        await ensureAuthSchema(db);
        await db.query('INSERT INTO users (id,email,password_hash,role,status) VALUES ($1,$2,$3,$4,$5)', [id, email, user.passwordHash, role, 'active']);
      } catch (error: any) {
        if (error?.code === '23505') throw new ValidationError('An account already exists for this email');
        throw new AiServiceUnavailableError('Authentication database unavailable');
      }
    } else if (config.NODE_ENV === 'production') {
      throw new AiServiceUnavailableError('Authentication database is not configured');
    } else {
      if (memoryUsers.has(email)) throw new ValidationError('An account already exists for this email');
      memoryUsers.set(email, user);
    }
    return this.createSession(user);
  }

  async login(emailInput: string, password: string) {
    const email = emailInput.trim().toLowerCase();
    const db = database();
    let user: User | undefined;
    if (db) {
      let result: pg.QueryResult;
      try {
        await ensureAuthSchema(db);
        result = await db.query('SELECT id,email,password_hash,role,status FROM users WHERE email=$1', [email]);
      } catch {
        throw new AiServiceUnavailableError('Authentication database unavailable');
      }
      const row = result.rows[0];
      if (row) user = { id: row.id, email: row.email, passwordHash: row.password_hash, role: row.role, status: row.status };
    } else if (config.NODE_ENV !== 'production') user = memoryUsers.get(email);
    if (!user || user.status !== 'active' || !verifyPassword(password, user.passwordHash)) throw new UnauthorizedError('Invalid email or password');
    return this.createSession(user);
  }

  async logout(sessionId: string): Promise<void> {
    const db = database();
    if (db) {
      await ensureAuthSchema(db);
      await db.query('UPDATE auth_sessions SET revoked_at=now() WHERE id=$1', [sessionId]);
    }
    else if (memorySessions.has(sessionId)) memorySessions.get(sessionId)!.revoked = true;
  }

  private async createSession(user: User) {
    const now = Math.floor(Date.now() / 1000);
    const exp = now + 60 * 60 * 24 * 7;
    const jti = crypto.randomUUID();
    const header = b64({ alg: 'HS256', typ: 'JWT' });
    const payload = b64({ iss: 'lahjti', aud: 'lahjti-mobile', sub: user.id, role: user.role, iat: now, exp, jti });
    const signature = crypto.createHmac('sha256', config.JWT_SECRET).update(`${header}.${payload}`).digest('base64url');
    const db = database();
    if (db) {
      try {
        await ensureAuthSchema(db);
        await db.query('INSERT INTO auth_sessions (id,user_id,expires_at) VALUES ($1,$2,to_timestamp($3))', [jti, user.id, exp]);
      } catch {
        throw new AiServiceUnavailableError('Authentication database unavailable');
      }
    }
    else memorySessions.set(jti, { userId: user.id, expiresAt: new Date(exp * 1000), revoked: false });
    return { token: `${header}.${payload}.${signature}`, expiresAt: new Date(exp * 1000).toISOString(), user: { id: user.id, email: user.email, role: user.role } };
  }
}
