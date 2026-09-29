import { z } from 'zod';

export const SubscriptionStatusEnum = z.enum([
  'trial',
  'active',
  'expired',
  'cancelled',
  'paymentPending',
  'schoolAccess',
  'pastDue',
  'suspended',
]);

export const AccountContextEnum = z.enum(['individual', 'school']);
export const RoleEnum = z.enum(['individual', 'student', 'teacher', 'admin']);

export const startTrialSchema = z.object({
  accountContext: AccountContextEnum.default('individual'),
  role: RoleEnum.default('individual'),
  schoolCode: z.string().optional(),
});

export const createCheckoutSessionSchema = z.object({
  planId: z.string().default('individual_monthly'),
  successUrl: z.string().url().optional(),
  cancelUrl: z.string().url().optional(),
});

export const webhookPayloadSchema = z.object({
  id: z.string().optional(),
  type: z.enum([
    'checkout.completed',
    'invoice.payment_succeeded',
    'invoice.payment_failed',
    'customer.subscription.deleted',
    'customer.subscription.updated',
  ]),
  userId: z.string().min(1),
  planId: z.string().optional().default('individual_monthly'),
  periodDays: z.number().int().positive().optional().default(30),
  status: z.string().optional(),
  timestamp: z.string().optional(),
});

export const restorePurchasesSchema = z.object({
  platformReceipt: z.string().optional(),
});

export const simulateCheckoutSchema = z.object({
  planId: z.string().default('individual_monthly'),
  periodDays: z.number().int().positive().default(30),
  simulatePending: z.boolean().optional().default(false),
});

export const updateSubscriptionSchema = z.object({
  status: SubscriptionStatusEnum,
  planId: z.string().optional(),
  periodDays: z.number().int().positive().optional(),
});

export const checkAccessSchema = z.object({
  feature: z.enum([
    'lessons',
    'vocabulary',
    'exams',
    'games',
    'aiTutor',
    'voiceConversation',
    'progress',
    'schoolDailyTasks',
    'schoolClassrooms',
    'teacherDashboard',
  ]),
});
