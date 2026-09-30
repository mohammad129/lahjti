import crypto from 'crypto';
import pg from 'pg';
import { config } from '../config/env.js';
import { AiServiceUnavailableError, NotFoundError, ValidationError } from '../errors/api_error.js';

const tables = { lessons: 'content_lessons', vocabulary: 'content_vocabulary_items' } as const;
type Kind = keyof typeof tables;
let pool: pg.Pool | undefined;
function db(): pg.Pool { if (!config.DATABASE_URL) throw new AiServiceUnavailableError('Content database is not configured'); return pool ??= new pg.Pool({ connectionString: config.DATABASE_URL }); }
function clean(input: unknown, max = 2000): string { return String(input ?? '').trim().slice(0, max); }

export class ContentManagementService {
  async list(kind: Kind) { return (await db().query(`SELECT * FROM ${tables[kind]} ORDER BY updated_at DESC LIMIT 200`)).rows; }
  async create(kind: Kind, input: Record<string, unknown>) {
    if (kind === 'lessons') {
      const fields = ['title','language','cefr','ageGroup','learningGoal','skill'];
      for (const field of fields) if (!clean(input[field])) throw new ValidationError(`${field} is required`);
      const row = await db().query(`INSERT INTO content_lessons (id,title,description,language,cefr,age_group,learning_goal,skill,steps,published) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING *`, [
        `lesson_${crypto.randomUUID()}`, clean(input.title,255), clean(input.description), clean(input.language,64), clean(input.cefr,16), clean(input.ageGroup,32), clean(input.learningGoal,64), clean(input.skill,64), JSON.stringify(Array.isArray(input.steps) ? input.steps : []), input.published === true]);
      return row.rows[0];
    }
    const fields = ['word','translation','language','cefr','topic','difficulty'];
    for (const field of fields) if (!clean(input[field])) throw new ValidationError(`${field} is required`);
    const row = await db().query(`INSERT INTO content_vocabulary_items (id,word,translation,language,cefr,topic,example,pronunciation,difficulty,published) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING *`, [
      `vocab_${crypto.randomUUID()}`, clean(input.word,255), clean(input.translation,512), clean(input.language,64), clean(input.cefr,16), clean(input.topic,128), clean(input.example), clean(input.pronunciation,512), clean(input.difficulty,32), input.published === true]);
    return row.rows[0];
  }
  async update(kind: Kind, id: string, input: Record<string, unknown>) {
    const allowed = kind === 'lessons' ? ['title','description','language','cefr','ageGroup','learningGoal','skill','steps','published'] : ['word','translation','language','cefr','topic','example','pronunciation','difficulty','published'];
    const columns: string[] = []; const values: unknown[] = [];
    for (const key of allowed) if (key in input) { columns.push(`${({ageGroup:'age_group', learningGoal:'learning_goal'} as Record<string,string>)[key] ?? key}=$${values.length + 1}`); values.push(key === 'steps' ? JSON.stringify(Array.isArray(input.steps) ? input.steps : []) : key === 'published' ? input.published === true : clean(input[key])); }
    if (!columns.length) throw new ValidationError('No editable fields supplied');
    values.push(id); const result = await db().query(`UPDATE ${tables[kind]} SET ${columns.join(',')},updated_at=now() WHERE id=$${values.length} RETURNING *`, values);
    if (!result.rows[0]) throw new NotFoundError('Content item not found'); return result.rows[0];
  }
  async remove(kind: Kind, id: string) { const result = await db().query(`DELETE FROM ${tables[kind]} WHERE id=$1 RETURNING id`, [id]); if (!result.rows[0]) throw new NotFoundError('Content item not found'); }
}
