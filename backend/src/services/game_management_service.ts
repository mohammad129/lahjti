import { ILearningDb } from '../db/index.js';
import { NotFoundError, ValidationError } from '../errors/api_error.js';

export interface GameInput {
  nameAr: string;
  nameEn: string;
  gameType: 'word_match' | 'sentence_scramble' | 'memory_cards' | 'audio_challenge' | 'speed_quiz';
  targetAgeGroup?: string;
  difficulty?: string;
  classroomId?: string;
  durationSeconds?: number;
  xpReward?: number;
  isActive?: boolean;
  questions?: any[];
}

export class GameManagementService {
  constructor(private db: ILearningDb) {}

  /**
   * 1. List educational games
   */
  async listGames(filters?: { targetAgeGroup?: string; difficulty?: string; classroomId?: string }): Promise<any[]> {
    return await this.db.getEducationalGames(filters);
  }

  /**
   * 2. Get game details with questions and attached assets
   */
  async getGameDetails(gameId: string): Promise<any> {
    const game = await this.db.getEducationalGameById(gameId);
    if (!game) throw new NotFoundError(`اللعبة ${gameId} غير موجودة`);

    const questions = await this.db.getGameQuestions(gameId);
    return {
      ...game,
      questions,
    };
  }

  /**
   * 3. Teacher/Admin: Create or update an educational game
   */
  async createGame(data: GameInput): Promise<any> {
    if (!data.nameAr || !data.nameEn) {
      throw new ValidationError('اسم اللعبة بالعربية والإنجليزية مطلوب');
    }

    const gameId = `game_${Date.now()}`;
    const game = await this.db.saveEducationalGame({
      id: gameId,
      nameAr: data.nameAr.trim(),
      nameEn: data.nameEn.trim(),
      gameType: data.gameType,
      targetAgeGroup: data.targetAgeGroup || 'all',
      difficulty: data.difficulty || 'beginner',
      classroomId: data.classroomId || null,
      durationSeconds: data.durationSeconds || 180,
      xpReward: data.xpReward || 25,
      isActive: data.isActive ?? true,
    });

    if (data.questions && data.questions.length > 0) {
      const qRecords = data.questions.map((q, idx) => ({
        id: q.id || `gq_${gameId}_${idx + 1}`,
        gameId,
        prompt: q.prompt,
        correctAnswer: q.correctAnswer,
        distractors: q.distractors || [],
        imageUrl: q.imageUrl || null,
        audioUrl: q.audioUrl || null,
        points: q.points || 5,
      }));
      await this.db.saveGameQuestions(qRecords);
    }

    return await this.getGameDetails(gameId);
  }

  /**
   * 4. Student: Submit game play result with server-verified XP
   */
  async submitGamePlay(
    gameId: string,
    studentId: string,
    submission: {
      score: number;
      correctAnswers: number;
      incorrectAnswers: number;
      playedSeconds?: number;
    }
  ): Promise<any> {
    const game = await this.db.getEducationalGameById(gameId);
    if (!game) throw new NotFoundError(`اللعبة ${gameId} غير موجودة`);

    // Verify and bound score
    const safeScore = Math.max(0, Math.min(100, submission.score));
    const baseReward = game.xpReward || 25;
    const earnedXp = Math.round((baseReward * safeScore) / 100);

    // Save game result in school game results
    const result = await this.db.saveGameResult({
      gameId,
      studentId,
      score: safeScore,
      correctAnswers: submission.correctAnswers || 0,
      incorrectAnswers: submission.incorrectAnswers || 0,
      skill: game.gameType,
      earnedXp,
    });

    // Record server-authoritative Points Transaction
    if (earnedXp > 0) {
      await this.db.recordPointsTransaction({
        studentId,
        amount: earnedXp,
        reasonCode: 'game_completed',
        descriptionAr: `إكمال لعبة تعليمية: ${game.nameAr} (${safeScore}%)`,
        referenceId: gameId,
      });
    }

    const encouragement = safeScore >= 80
      ? await this.db.getEncouragementTemplate('high_score')
      : await this.db.getEncouragementTemplate('after_mistake');

    return {
      success: true,
      resultId: result.id,
      gameId,
      score: safeScore,
      earnedXp,
      encouragementMessage: encouragement?.messageAr || 'لعبة رائعة! استمر في التعلم واللعب.',
    };
  }
}
