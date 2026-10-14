import crypto from 'crypto';
import { config } from '../config/env.js';
import { ILearningDb } from '../db/index.js';
import { UnauthorizedError, ValidationError } from '../errors/api_error.js';

export function hashPin(pin: string, salt = crypto.randomBytes(16).toString('base64url')): string {
  const derived = crypto.scryptSync(pin, salt, 64).toString('base64url');
  return `scrypt$${salt}$${derived}`;
}

export function verifyPin(pin: string, encoded: string): boolean {
  const [, salt, expected] = encoded.split('$');
  if (!salt || !expected) return false;
  const actual = crypto.scryptSync(pin, salt, 64).toString('base64url');
  return actual.length === expected.length && crypto.timingSafeEqual(Buffer.from(actual), Buffer.from(expected));
}

function b64(value: unknown): string {
  return Buffer.from(JSON.stringify(value)).toString('base64url');
}

export class StudentCodeAuthService {
  constructor(private db: ILearningDb) {}

  /**
   * Generates a unique Student Code (e.g. ST-8F4K29) with a scrypt-hashed PIN.
   */
  async generateCodeForStudent(params: {
    studentId: string;
    pin: string;
    schoolId?: string;
    classroomId?: string;
    teacherId?: string;
  }): Promise<{ studentCode: string }> {
    const { studentId, pin, schoolId, classroomId, teacherId } = params;
    if (!pin || pin.trim().length < 4) {
      throw new ValidationError('PIN must be at least 4 digits');
    }

    // Generate unique human-readable code: ST-XXXXXX
    const randomHex = crypto.randomBytes(3).toString('hex').toUpperCase();
    const studentCode = `ST-${randomHex}`;
    const pinHash = hashPin(pin.trim());

    await this.db.saveStudentCode({
      studentId,
      studentCode,
      pinHash,
      schoolId,
      classroomId,
      teacherId,
    });

    return { studentCode };
  }

  /**
   * Quick-login using Student Code + PIN.
   * Returns a signed JWT session compatible with mobile app auth.
   */
  async loginWithStudentCode(studentCodeInput: string, pinInput: string): Promise<{
    token: string;
    expiresAt: string;
    user: { id: string; studentCode: string; role: string };
  }> {
    const cleanCode = studentCodeInput.trim().toUpperCase();
    const cleanPin = pinInput.trim();

    if (!cleanCode || !cleanPin) {
      throw new ValidationError('Student code and PIN are required');
    }

    const codeRecord = await this.db.getStudentCodeByCode(cleanCode);
    if (!codeRecord || !verifyPin(cleanPin, codeRecord.pinHash)) {
      throw new UnauthorizedError('رمز الطالب أو الـ PIN غير صحيح');
    }

    // Generate standard Lahjti signed session token
    const now = Math.floor(Date.now() / 1000);
    const exp = now + 60 * 60 * 24 * 7; // 7 days
    const jti = crypto.randomUUID();

    const header = b64({ alg: 'HS256', typ: 'JWT' });
    const payload = b64({
      iss: 'lahjti',
      aud: 'lahjti-mobile',
      sub: codeRecord.studentId,
      role: 'student',
      studentCode: codeRecord.studentCode,
      iat: now,
      exp,
      jti,
    });

    const signature = crypto
      .createHmac('sha256', config.JWT_SECRET)
      .update(`${header}.${payload}`)
      .digest('base64url');

    return {
      token: `${header}.${payload}.${signature}`,
      expiresAt: new Date(exp * 1000).toISOString(),
      user: {
        id: codeRecord.studentId,
        studentCode: codeRecord.studentCode,
        role: 'student',
      },
    };
  }
}
