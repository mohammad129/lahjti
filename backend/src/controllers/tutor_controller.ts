import { NextFunction, Request, Response } from 'express';
import { getDatabase, ILearningDb } from '../db/index.js';
import { UnauthorizedError } from '../errors/api_error.js';
import {
  TtsSynthesizeRequestSchema,
  TutorConversationRequestSchema,
} from '../schemas/tutor_conversation_schemas.js';
import { ttsService, TtsService } from '../services/tts_service.js';
import { TutorConversationService } from '../services/tutor_conversation_service.js';

export class TutorController {
  private service: TutorConversationService;
  private tts: TtsService;
  private db: ILearningDb;

  constructor(
    service?: TutorConversationService,
    db?: ILearningDb,
    tts?: TtsService
  ) {
    this.service = service ?? new TutorConversationService();
    this.db = db ?? getDatabase();
    this.tts = tts ?? ttsService;
  }

  converse = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const user = req.user;
      if (!user?.userId) {
        throw new UnauthorizedError('User authentication is required');
      }

      // 1. Strict Request Validation
      const validatedRequest = TutorConversationRequestSchema.parse(req.body);

      // 2. Server-Authoritative Profile Context Enrichment
      try {
        const profile = await this.db.getProfile(user.userId);
        if (profile) {
          if (profile.estimatedCefrLevel) {
            validatedRequest.difficulty = profile.estimatedCefrLevel.toLowerCase() as any;
          }
          if (Array.isArray(profile.weaknesses) && profile.weaknesses.length > 0) {
            const merged = Array.from(
              new Set([...profile.weaknesses, ...validatedRequest.recentWeaknesses])
            );
            validatedRequest.recentWeaknesses = merged.slice(0, 5);
          }
          if (Array.isArray(profile.strengths) && profile.strengths.length > 0) {
            const merged = Array.from(
              new Set([...profile.strengths, ...validatedRequest.recentStrengths])
            );
            validatedRequest.recentStrengths = merged.slice(0, 5);
          }
        }
      } catch {
        // Fallback: non-fatal if db lookup fails during standalone mock tests
      }

      // 3. Delegate to Service
      const conversationOutput = await this.service.converse(
        validatedRequest,
        {
          userId: user.userId,
          requestId: req.headers['x-request-id'] as string | undefined,
        },
        validatedRequest.voiceDurationSeconds || 0
      );

      // 4. Return HTTP 200 with strict JSON schema
      res.status(200).json(conversationOutput);
    } catch (err) {
      next(err);
    }
  };

  synthesize = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const user = req.user;
      if (!user?.userId) {
        throw new UnauthorizedError('User authentication is required');
      }

      const validated = TtsSynthesizeRequestSchema.parse(req.body);
      const result = await this.tts.synthesizeSpeech({
        text: validated.text,
        tutorPersona: validated.tutorPersona,
        targetLanguage: validated.targetLanguage,
        voiceId: validated.voiceId,
        userId: user.userId,
      });

      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  };
}
