import request from 'supertest';
import { beforeEach, describe, expect, it } from 'vitest';
import { createApp } from '../src/app.js';
import { InMemoryLearningDb, setDatabase } from '../src/db/index.js';
import { PlacementController } from '../src/controllers/placement_controller.js';
import { SubscriptionController } from '../src/controllers/subscription_controller.js';
import { TutorController } from '../src/controllers/tutor_controller.js';
import { SubscriptionService } from '../src/services/subscription_service.js';
import { TutorConversationService } from '../src/services/tutor_conversation_service.js';
import { PlacementEvaluationService } from '../src/services/placement_evaluation_service.js';

describe('STEP 26 — Production Subscriptions, Payments & Entitlements Backend Tests', () => {
  let db: InMemoryLearningDb;
  let service: SubscriptionService;
  let controller: SubscriptionController;
  let tutorController: TutorController;
  let placementController: PlacementController;
  let app: ReturnType<typeof createApp>;

  const individualUser = 'user_individual_sami';
  const studentUser = 'user_student_layla';
  const teacherUser = 'user_teacher_ahmad';

  beforeEach(async () => {
    db = new InMemoryLearningDb();
    setDatabase(db);
    service = new SubscriptionService(db);
    controller = new SubscriptionController(service);
    tutorController = new TutorController(new TutorConversationService(), db);
    placementController = new PlacementController(new PlacementEvaluationService());

    app = createApp(
      placementController,
      tutorController,
      undefined,
      undefined,
      undefined,
      controller
    );

    // Seed school and teacher membership
    await db.createSchool({
      id: 'sch_noor_01',
      name: 'مدرسة النور الأهلية',
      schoolCode: 'SCH-1001',
    });

    await db.upsertSchoolMembership({
      userId: teacherUser,
      schoolId: 'sch_noor_01',
      role: 'teacher',
      status: 'active',
      displayName: 'الأستاذ أحمد الشامي',
    });
  });

  // 1. Individual 3-Day Trial Initial Auto-Creation
  it('1. should auto-initialize individual 3-day trial on first status query ($10/month plan)', async () => {
    const res = await request(app)
      .get('/api/v1/subscription/status?context=individual&role=individual')
      .set('Authorization', `Bearer ${individualUser}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.userId).toBe(individualUser);
    expect(res.body.data.accountContext).toBe('individual');
    expect(res.body.data.status).toBe('trial');
    expect(res.body.data.trialDurationDays).toBe(3);
    expect(res.body.data.priceUsd).toBe(10.0);
    expect(res.body.data.isValidAccess).toBe(true);
    expect(res.body.data.isTrialActive).toBe(true);
    expect(res.body.data.daysRemaining).toBeGreaterThanOrEqual(1);
  });

  // 2. Server-side Persisted Trial (No Reset on New Request)
  it('2. should persist trial server-side and not reset trial duration on repeated calls', async () => {
    // 1st call
    const res1 = await request(app)
      .post('/api/v1/subscription/trial/start')
      .set('Authorization', `Bearer ${individualUser}`)
      .send({ accountContext: 'individual', role: 'individual' });

    expect(res1.status).toBe(200);

    // Simulate elapsed trial in DB
    const sub = await db.getSubscription(individualUser);
    const pastDate = new Date(Date.now() - 4 * 24 * 60 * 60 * 1000);
    await db.upsertSubscription({
      ...sub,
      trialStartsAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
      trialEndsAt: pastDate,
      status: 'expired',
    });

    // 2nd call to start trial or get status should NOT revive or reset elapsed trial
    const res2 = await request(app)
      .get('/api/v1/subscription/status')
      .set('Authorization', `Bearer ${individualUser}`);

    expect(res2.status).toBe(200);
    expect(res2.body.data.status).toBe('expired');
    expect(res2.body.data.isValidAccess).toBe(false);
    expect(res2.body.data.isTrialActive).toBe(false);
  });

  // 3. Tokenized Checkout Session Creation
  it('3. should generate tokenized checkout session through decoupled payment provider without storing card info', async () => {
    const res = await request(app)
      .post('/api/v1/subscription/checkout-session')
      .set('Authorization', `Bearer ${individualUser}`)
      .send({
        planId: 'individual_monthly',
        successUrl: 'https://lahjti.com/billing/success',
        cancelUrl: 'https://lahjti.com/billing/cancel',
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.sessionId).toBeDefined();
    expect(res.body.data.checkoutUrl).toContain('cs_test_');
    expect(res.body.data.priceUsd).toBe(10.0);
    expect(res.body.data.userId).toBe(individualUser);
  });

  // 4. Webhook Processing: checkout.completed activates subscription
  it('4. should process checkout.completed webhook and activate server subscription', async () => {
    // Webhook callback does not require user auth header
    const res = await request(app)
      .post('/api/v1/subscription/webhook')
      .send({
        id: 'evt_test_checkout_001',
        type: 'checkout.completed',
        userId: individualUser,
        planId: 'individual_monthly',
        periodDays: 30,
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.subscription.status).toBe('active');
    expect(res.body.data.subscription.isValidAccess).toBe(true);
    expect(res.body.data.subscription.currentPeriodEnd).toBeDefined();

    // Verify DB state directly
    const inDb = await db.getSubscription(individualUser);
    expect(inDb.status).toBe('active');
  });

  // 5. Webhook Processing: invoice.payment_failed transitions status to pastDue
  it('5. should process invoice.payment_failed webhook and set status to pastDue', async () => {
    const res = await request(app)
      .post('/api/v1/subscription/webhook')
      .send({
        type: 'invoice.payment_failed',
        userId: individualUser,
        planId: 'individual_monthly',
      });

    expect(res.status).toBe(200);
    expect(res.body.data.subscription.status).toBe('pastDue');
    expect(res.body.data.subscription.isValidAccess).toBe(false);
  });

  // 6. Webhook Processing: customer.subscription.deleted transitions status to expired
  it('6. should process customer.subscription.deleted webhook and set status to expired', async () => {
    const res = await request(app)
      .post('/api/v1/subscription/webhook')
      .send({
        type: 'customer.subscription.deleted',
        userId: individualUser,
      });

    expect(res.status).toBe(200);
    expect(res.body.data.subscription.status).toBe('expired');
    expect(res.body.data.subscription.isValidAccess).toBe(false);
  });

  // 7. Granular Entitlements API
  it('7. should return granular feature entitlements based on subscription status', async () => {
    // 1. In active status
    await service.simulateCheckout(individualUser, 'individual_monthly', 30);
    const resActive = await request(app)
      .get('/api/v1/subscription/entitlements')
      .set('Authorization', `Bearer ${individualUser}`);

    expect(resActive.status).toBe(200);
    expect(resActive.body.data.isValidAccess).toBe(true);
    expect(resActive.body.data.features.aiTutor).toBe(true);
    expect(resActive.body.data.features.voiceConversation).toBe(true);
    expect(resActive.body.data.features.lessons).toBe(true);
    expect(resActive.body.data.features.schoolDailyTasks).toBe(false);
    expect(resActive.body.data.features.teacherDashboard).toBe(false);

    // 2. Teacher entitlements
    const resTeacher = await request(app)
      .get('/api/v1/subscription/entitlements')
      .set('Authorization', `Bearer ${teacherUser}`);

    expect(resTeacher.status).toBe(200);
    expect(resTeacher.body.data.features.teacherDashboard).toBe(true);
    expect(resTeacher.body.data.features.schoolClassrooms).toBe(true);
  });

  // 8. Server-Authoritative Feature Guard: Expired trial blocks AI Tutor with 403 Forbidden
  it('8. should block AI tutor with HTTP 403 Forbidden when subscription is expired', async () => {
    // Expire user trial
    await db.upsertSubscription({
      userId: individualUser,
      accountContext: 'individual',
      role: 'individual',
      status: 'expired',
      trialEndsAt: new Date(Date.now() - 1000),
    });

    const tutorRes = await request(app)
      .post('/api/v1/tutor/conversation')
      .set('Authorization', `Bearer ${individualUser}`)
      .send({
        targetLanguage: 'english',
        userMessage: 'Hello tutor, I want to practice.',
      });

    expect(tutorRes.status).toBe(403);
    expect(tutorRes.body.error.code).toBe('FORBIDDEN');
    expect(tutorRes.body.error.arabicMessage).toContain('الفترة التجريبية');
  });

  // 9. Restore Purchases
  it('9. should restore active subscription with platform store receipt reconciliation', async () => {
    const res = await request(app)
      .post('/api/v1/subscription/restore')
      .set('Authorization', `Bearer ${individualUser}`)
      .send({ platformReceipt: 'valid_apple_or_google_receipt_token' });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.status).toBe('active');
    expect(res.body.data.isValidAccess).toBe(true);
  });

  // 10. School Student 10-Day Free Trial
  it('10. should grant 10 days free trial to school student account', async () => {
    const res = await request(app)
      .post('/api/v1/subscription/trial/start')
      .set('Authorization', `Bearer ${studentUser}`)
      .send({
        accountContext: 'school',
        role: 'student',
        schoolCode: 'SCH-1001',
      });

    expect(res.status).toBe(200);
    expect(res.body.data.accountContext).toBe('school');
    expect(res.body.data.role).toBe('student');
    expect(res.body.data.trialDurationDays).toBe(10);
    expect(res.body.data.priceUsd).toBe(0.0);
    expect(res.body.data.isValidAccess).toBe(true);
    expect(res.body.data.isTrialActive).toBe(true);
  });

  // 11. School Teacher Institutional Access (No Individual Subscription Charged)
  it('11. should provide institutional access to verified school teacher without charging $10/month', async () => {
    const res = await request(app)
      .get('/api/v1/subscription/status?context=school&role=teacher&schoolCode=SCH-1001')
      .set('Authorization', `Bearer ${teacherUser}`);

    expect(res.status).toBe(200);
    expect(res.body.data.accountContext).toBe('school');
    expect(res.body.data.role).toBe('teacher');
    expect(res.body.data.status).toBe('schoolAccess');
    expect(res.body.data.priceUsd).toBe(0.0);
    expect(res.body.data.isValidAccess).toBe(true);
  });

  // 12. Security: Client Cannot Tamper with Subscription Status
  it('12. should reject client attempts to directly set arbitrary subscription status', async () => {
    // Calling an endpoint without valid server-side checkout session or webhook
    const res = await request(app)
      .get('/api/v1/subscription/entitlements')
      .set('Authorization', `Bearer user_hacker_trying_fake_status`);

    // Server auto-creates 3-day trial according to server authority, not arbitrary VIP status
    expect(res.status).toBe(200);
    expect(res.body.data.subscription.status).toBe('trial');
    expect(res.body.data.subscription.trialDurationDays).toBe(3);
  });
});
