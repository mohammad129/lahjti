import { ILearningDb } from '../db/index.js';
import { NotFoundError, ValidationError } from '../errors/api_error.js';

export interface ExamInput {
  teacherId: string;
  schoolId?: string;
  classroomId?: string;
  title: string;
  description?: string;
  durationMinutes: number;
  startDate: string | Date;
  endDate: string | Date;
  totalPoints?: number;
  passPoints?: number;
  isPublished?: boolean;
  questions?: any[];
}

export class ExamManagementService {
  constructor(private db: ILearningDb) {}

  /**
   * 1. Create a new teacher exam with questions
   */
  async createExam(data: ExamInput): Promise<any> {
    if (!data.title || data.title.trim().length === 0) {
      throw new ValidationError('عنوان الاختبار مطلوب');
    }

    const examId = `exam_${Date.now()}`;
    const exam = await this.db.saveExam({
      id: examId,
      teacherId: data.teacherId,
      schoolId: data.schoolId || null,
      classroomId: data.classroomId || null,
      title: data.title.trim(),
      description: data.description || '',
      durationMinutes: data.durationMinutes || 30,
      startDate: new Date(data.startDate),
      endDate: new Date(data.endDate),
      totalPoints: data.totalPoints || 100,
      passPoints: data.passPoints || 60,
      isPublished: data.isPublished ?? true,
    });

    if (data.questions && data.questions.length > 0) {
      const questionsWithExamId = data.questions.map((q, idx) => ({
        id: q.id || `eq_${examId}_${idx + 1}`,
        examId,
        questionOrder: idx + 1,
        questionType: q.questionType, // multiple_choice | true_false | fill_in_the_blank | matching | word_order | image_choice | listening | free_writing
        questionText: q.questionText,
        instructionsAr: q.instructionsAr || null,
        audioAssetUrl: q.audioAssetUrl || null,
        imageAssetUrl: q.imageAssetUrl || null,
        options: q.options || [],
        correctAnswer: q.correctAnswer,
        points: q.points || 5,
      }));
      await this.db.saveExamQuestions(questionsWithExamId);
    }

    return await this.getExamDetails(examId);
  }

  /**
   * 2. Get exam details with its questions
   */
  async getExamDetails(examId: string, hideAnswers: boolean = false): Promise<any> {
    const exam = await this.db.getExamById(examId);
    if (!exam) throw new NotFoundError(`الاختبار رقم ${examId} غير موجود`);

    const questions = await this.db.getExamQuestions(examId);

    return {
      ...exam,
      questions: questions.map((q) => {
        if (hideAnswers) {
          const { correctAnswer, ...rest } = q;
          return rest;
        }
        return q;
      }),
    };
  }

  /**
   * 3. Submit exam and evaluate 100% deterministically in backend (ZERO AI cost for standard types)
   */
  async submitExam(
    examId: string,
    studentId: string,
    answers: Record<string, any>
  ): Promise<any> {
    const exam = await this.db.getExamById(examId);
    if (!exam) throw new NotFoundError(`الاختبار ${examId} غير موجود`);

    const questions = await this.db.getExamQuestions(examId);
    let totalScore = 0;
    let maxPoints = 0;
    const evaluatedMistakes: any[] = [];

    for (const q of questions) {
      const qPoints = q.points || 5;
      maxPoints += qPoints;
      const studentAns = answers[q.id];
      let isCorrect = false;

      switch (q.questionType) {
        case 'multiple_choice':
        case 'true_false':
        case 'image_choice':
        case 'listening': {
          const expected = String(q.correctAnswer).trim().toLowerCase();
          const actual = String(studentAns || '').trim().toLowerCase();
          isCorrect = expected === actual;
          break;
        }
        case 'fill_in_the_blank': {
          const expected = String(q.correctAnswer).trim().toLowerCase();
          const actual = String(studentAns || '').trim().toLowerCase();
          isCorrect = expected === actual;
          break;
        }
        case 'word_order': {
          // Expected is an ordered array of words or a string sentence
          if (Array.isArray(q.correctAnswer) && Array.isArray(studentAns)) {
            isCorrect =
              JSON.stringify(q.correctAnswer.map((w: string) => w.trim().toLowerCase())) ===
              JSON.stringify(studentAns.map((w: string) => w.trim().toLowerCase()));
          } else {
            const expected = String(q.correctAnswer).replace(/\s+/g, ' ').trim().toLowerCase();
            const actual = String(studentAns || '').replace(/\s+/g, ' ').trim().toLowerCase();
            isCorrect = expected === actual;
          }
          break;
        }
        case 'matching': {
          // Both expected and actual are key-value objects
          if (typeof q.correctAnswer === 'object' && typeof studentAns === 'object') {
            const keys = Object.keys(q.correctAnswer);
            let matchCount = 0;
            for (const k of keys) {
              if (
                studentAns[k] &&
                String(studentAns[k]).trim().toLowerCase() ===
                  String(q.correctAnswer[k]).trim().toLowerCase()
              ) {
                matchCount++;
              }
            }
            isCorrect = matchCount === keys.length;
          }
          break;
        }
        case 'free_writing':
        default: {
          // Heuristic grading for writing unless free writing AI is explicitly invoked
          const text = String(studentAns || '').trim();
          isCorrect = text.length >= 15; // basic completion check
          break;
        }
      }

      if (isCorrect) {
        totalScore += qPoints;
      } else {
        const mistakeRecord = {
          questionId: q.id,
          questionType: q.questionType,
          questionText: q.questionText,
          correctAnswer: q.correctAnswer,
          studentAnswer: studentAns || '(فارغ)',
        };
        evaluatedMistakes.push(mistakeRecord);

        // Automatically log mistake into student_mistakes for Spaced Repetition!
        await this.db.recordStudentMistake({
          studentId,
          contentId: `exam_${q.id}`,
          skillType: q.questionType === 'listening' ? 'listening' : 'grammar',
          itemPrompt: q.questionText,
          correctAnswer:
            typeof q.correctAnswer === 'object'
              ? JSON.stringify(q.correctAnswer)
              : String(q.correctAnswer),
          studentLastWrongAnswer: String(studentAns || ''),
        });
      }
    }

    const percentage = maxPoints > 0 ? (totalScore / maxPoints) * 100 : 0;
    const passThreshold =
      maxPoints >= (exam.passPoints || 60)
        ? (exam.passPoints || 60)
        : Math.round(maxPoints * 0.5);
    const isPassed = totalScore >= passThreshold;

    const submission = await this.db.submitExam({
      examId,
      studentId,
      score: totalScore,
      totalPoints: maxPoints,
      percentage,
      isPassed,
      studentAnswers: answers,
      evaluatedMistakes,
    });

    // Server-authoritative Points Transaction
    const xpReward = isPassed ? 30 : 10;
    await this.db.recordPointsTransaction({
      studentId,
      amount: xpReward,
      reasonCode: 'exam_completed',
      descriptionAr: `إنهاء اختبار: ${exam.title} (${Math.round(percentage)}%)`,
      referenceId: examId,
    });

    return {
      submission,
      totalScore,
      maxPoints,
      percentage: Math.round(percentage * 10) / 10,
      isPassed,
      xpEarned: xpReward,
      mistakesCount: evaluatedMistakes.length,
      evaluatedMistakes,
    };
  }

  /**
   * 4. Teacher Analytics: Submissions, Class Rankings, and Common Mistakes
   */
  async getExamAnalyticsForTeacher(examId: string): Promise<any> {
    const exam = await this.db.getExamById(examId);
    if (!exam) throw new NotFoundError(`الاختبار ${examId} غير موجود`);

    const submissions = await this.db.getExamSubmissions(examId);
    const questions = await this.db.getExamQuestions(examId);

    // Aggregate error frequency per question
    const questionMistakeFrequency: Record<string, number> = {};
    for (const sub of submissions) {
      if (Array.isArray(sub.evaluatedMistakes)) {
        for (const m of sub.evaluatedMistakes) {
          questionMistakeFrequency[m.questionId] =
            (questionMistakeFrequency[m.questionId] || 0) + 1;
        }
      }
    }

    const rankedSubmissions = [...submissions].sort((a, b) => b.score - a.score);

    return {
      exam,
      totalSubmissions: submissions.length,
      averageScore:
        submissions.length > 0
          ? Math.round(
              (submissions.reduce((sum, s) => sum + s.score, 0) / submissions.length) * 10
            ) / 10
          : 0,
      passRate:
        submissions.length > 0
          ? Math.round(
              (submissions.filter((s) => s.isPassed).length / submissions.length) * 100
            )
          : 0,
      submissions: rankedSubmissions.map((s, idx) => ({
        rank: idx + 1,
        studentId: s.studentId,
        score: s.score,
        totalPoints: s.totalPoints,
        percentage: s.percentage,
        isPassed: s.isPassed,
        submittedAt: s.submittedAt,
      })),
      mostMissedQuestions: questions
        .map((q) => ({
          questionId: q.id,
          questionText: q.questionText,
          questionType: q.questionType,
          mistakeCount: questionMistakeFrequency[q.id] || 0,
        }))
        .sort((a, b) => b.mistakeCount - a.mistakeCount),
    };
  }
}
