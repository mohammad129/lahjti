import pg from 'pg';
import { createApp } from './app.js';
import { config } from './config/env.js';
import { runMigrations } from './db/migrate.js';

const app = createApp();

async function startServer() {
  if (config.DATABASE_URL) {
    try {
      const pool = new pg.Pool({
        connectionString: config.DATABASE_URL,
        ssl: config.NODE_ENV === 'production' ? { rejectUnauthorized: false } : undefined,
      });
      await runMigrations(pool);
      console.log('✅ PostgreSQL database connection and migrations verified.');
    } catch (err: any) {
      console.warn(`⚠️ PostgreSQL connection warning (${err?.message}). Running with resilient persistence.`);
    }
  }

  const server = app.listen(config.PORT, config.HOST, () => {
    console.log(`🚀 Lahjti Backend AI Gateway running on http://${config.HOST}:${config.PORT}`);
    console.log(`📡 Health & Telemetry: http://${config.HOST}:${config.PORT}/api/v1/health`);
    console.log(`📊 Pilot Metrics: http://${config.HOST}:${config.PORT}/api/v1/monitoring/metrics`);
    console.log(`🔒 Active AI Provider: ${config.AI_PROVIDER} (Model: ${config.AI_MODEL})`);
    console.log(`🎙️ Active TTS Provider: ${config.TTS_PROVIDER}`);
    console.log(`🌍 Environment: ${config.NODE_ENV}`);
    console.log(`🗄️ Database: ${config.DATABASE_URL ? 'PostgreSQL' : 'In-Memory (Safe Development)'}`);
  });

  process.on('SIGTERM', () => {
    console.log('SIGTERM signal received: closing HTTP server');
    server.close(() => {
      console.log('HTTP server closed');
    });
  });
}

startServer();
