import fs from 'fs';
import path from 'path';
import pg from 'pg';
import { fileURLToPath } from 'url';
import { config } from '../config/env.js';

const { Pool } = pg;
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * Executes all pending SQL migration files in sequence safely and non-destructively.
 */
export async function runMigrations(pool: pg.Pool): Promise<void> {
  const drizzleDir = path.resolve(__dirname, '../../drizzle');
  if (!fs.existsSync(drizzleDir)) {
    console.warn(`⚠️ Drizzle migration directory not found at ${drizzleDir}`);
    return;
  }

  const files = fs
    .readdirSync(drizzleDir)
    .filter((f) => f.endsWith('.sql'))
    .sort();

  console.log(`📦 Running ${files.length} PostgreSQL database migration files...`);

  const client = await pool.connect();
  try {
    for (const file of files) {
      const filePath = path.join(drizzleDir, file);
      const sqlContent = fs.readFileSync(filePath, 'utf-8');
      console.log(`  ↪ Executing migration: ${file}`);
      await client.query(sqlContent);
    }
    console.log('✅ PostgreSQL database migrations completed successfully.');
  } finally {
    client.release();
  }
}

// Standalone CLI runner
if (process.argv[1] && process.argv[1].endsWith('migrate.ts')) {
  const dbUrl = config.DATABASE_URL || process.env.DATABASE_URL;
  if (!dbUrl) {
    console.error('❌ DATABASE_URL environment variable is required to run migrations.');
    process.exit(1);
  }

  const pool = new Pool({ connectionString: dbUrl });
  runMigrations(pool)
    .then(() => {
      console.log('🚀 All migrations applied.');
      return pool.end();
    })
    .catch((err) => {
      console.error('❌ Migration failed:', err);
      pool.end();
      process.exit(1);
    });
}
