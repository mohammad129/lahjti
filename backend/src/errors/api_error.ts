export class ApiError extends Error {
  public readonly statusCode: number;
  public readonly arabicMessage: string;
  public readonly isOperational: boolean;
  public readonly code: string;

  constructor(
    statusCode: number,
    message: string,
    arabicMessage: string,
    code: string = 'INTERNAL_ERROR',
    isOperational: boolean = true
  ) {
    super(message);
    this.statusCode = statusCode;
    this.arabicMessage = arabicMessage;
    this.code = code;
    this.isOperational = isOperational;
    Object.setPrototypeOf(this, new.target.prototype);
  }
}

export class ValidationError extends ApiError {
  constructor(message: string, arabicMessage: string = 'البيانات المدخلة غير صحيحة. يرجى التأكد والمحاولة مرة أخرى.') {
    super(400, message, arabicMessage, 'VALIDATION_ERROR');
  }
}

export class UnauthorizedError extends ApiError {
  constructor(message: string = 'Unauthorized', arabicMessage: string = 'يرجى تسجيل الدخول للمتابعة.') {
    super(401, message, arabicMessage, 'UNAUTHORIZED');
  }
}

export class ForbiddenError extends ApiError {
  constructor(message: string = 'Forbidden', arabicMessage: string = 'ليس لديك صلاحية للوصول إلى هذا المحتوى.') {
    super(403, message, arabicMessage, 'FORBIDDEN');
  }
}

export class NotFoundError extends ApiError {
  constructor(message: string = 'Resource not found', arabicMessage: string = 'المورد المطلوب غير موجود.') {
    super(404, message, arabicMessage, 'NOT_FOUND');
  }
}

export class RateLimitError extends ApiError {
  constructor(
    message: string = 'Rate limit exceeded',
    arabicMessage: string = 'تم إرسال طلبات كثيرة جدًا. يرجى الانتظار قليلاً ثم المحاولة.'
  ) {
    super(429, message, arabicMessage, 'RATE_LIMIT_EXCEEDED');
  }
}

export class AiTimeoutError extends ApiError {
  constructor(
    message: string = 'AI evaluation timed out',
    arabicMessage: string = 'أخذ الرد وقت أطول من اللازم. جرب مرة ثانية.'
  ) {
    super(504, message, arabicMessage, 'AI_TIMEOUT');
  }
}

export class AiServiceUnavailableError extends ApiError {
  constructor(
    message: string = 'AI service unavailable',
    arabicMessage: string = 'المدرب مشغول شوي. جرب مرة ثانية.'
  ) {
    super(503, message, arabicMessage, 'AI_UNAVAILABLE');
  }
}

export class AiOutputValidationError extends ApiError {
  constructor(
    message: string = 'AI returned invalid structured output',
    arabicMessage: string = 'صار معنا خلل بسيط وإحنا بنحلل جوابك. جرب مرة ثانية.'
  ) {
    super(502, message, arabicMessage, 'AI_SCHEMA_ERROR');
  }
}

