import request from 'supertest';
import { beforeEach, describe, expect, it } from 'vitest';
import { createApp } from '../src/app.js';
import { monitoringService } from '../src/services/monitoring_service.js';

describe('Step 30: Pilot Deployment & Telemetry Suite', () => {
  let app: ReturnType<typeof createApp>;

  beforeEach(() => {
    monitoringService.reset();
    app = createApp();
  });

  it('1. /api/v1/health returns HTTP 200 with structured pilot telemetry metadata', async () => {
    const res = await request(app).get('/api/v1/health');

    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
    expect(res.body.service).toBe('lahjti-backend');
    expect(res.body.metrics).toBeDefined();
    expect(res.body.metrics.requests).toBeDefined();
    expect(res.body.providers).toBeDefined();
  });

  it('2. /api/v1/monitoring/metrics returns clean non-sensitive system counters', async () => {
    // Generate some traffic
    await request(app).get('/api/v1/health');
    await request(app).post('/api/v1/tutor/conversation').send({}); // 401 unauthenticated

    const metricsRes = await request(app).get('/api/v1/monitoring/metrics');
    expect(metricsRes.status).toBe(200);
    expect(metricsRes.body.requests.total).toBeGreaterThanOrEqual(2);
    expect(metricsRes.body.requests.http2xx).toBeGreaterThanOrEqual(1);
    expect(metricsRes.body.requests.http4xx).toBeGreaterThanOrEqual(1);
    expect(metricsRes.body.auth.failures).toBeGreaterThanOrEqual(1);
  });

  it('3. Error Handler never leaks private internal secrets or stack traces', async () => {
    const unauthRes = await request(app)
      .post('/api/v1/tutor/conversation')
      .send({ userMessage: 'Hello' });

    expect(unauthRes.status).toBe(401);
    expect(unauthRes.body.error).toBeDefined();
    expect(unauthRes.body.error.code).toBe('UNAUTHORIZED');
    expect(unauthRes.body.error.arabicMessage).toBeDefined();
    expect(unauthRes.body.stack).toBeUndefined();
    expect(JSON.stringify(unauthRes.body)).not.toContain('apiKey');
    expect(JSON.stringify(unauthRes.body)).not.toContain('Bearer');
  });

  it('4. MonitoringService computes latency percentiles and error breakdown safely', () => {
    monitoringService.recordHttpRequest({
      method: 'POST',
      path: '/api/v1/tutor/conversation',
      statusCode: 200,
      durationMs: 45.2,
      timestamp: Date.now(),
    });

    monitoringService.recordHttpRequest({
      method: 'POST',
      path: '/api/v1/tutor/conversation',
      statusCode: 429,
      durationMs: 12.1,
      errorCode: 'RATE_LIMIT_EXCEEDED',
      timestamp: Date.now(),
    });

    const summary = monitoringService.getMetricsSummary();
    expect(summary.requests.total).toBe(2);
    expect(summary.requests.http2xx).toBe(1);
    expect(summary.requests.http4xx).toBe(1);
    expect(summary.errorBreakdown['RATE_LIMIT_EXCEEDED']).toBe(1);
    expect(summary.latencyMs.avgMs).toBeGreaterThan(0);
  });
});
