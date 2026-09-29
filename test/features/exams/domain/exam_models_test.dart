import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/exams/domain/models/exam_models.dart';
import 'package:lahjti/features/learning/domain/models/learning_skill.dart';
import 'package:lahjti/features/placement/domain/models/cefr_level.dart';

void main() {
  group('Exam Models Tests', () {
    test('1. ExamQuestionType metadata returns correct localized labels', () {
      expect(
        ExamQuestionType.vocabularySelection.nameArabic,
        'المفردات والسياق',
      );
      expect(ExamQuestionType.speakingProduction.nameArabic, 'النطق والتحدث');
      expect(
        ExamQuestionType.listeningComprehension.nameArabic,
        'الاستماع والفهم',
      );
      expect(ExamQuestionType.readingComprehension.nameArabic, 'فهم المقروء');
      expect(
        ExamQuestionType.practicalCommunication.nameArabic,
        'التواصل الواقعي',
      );
      expect(ExamQuestionType.grammarUsage.nameArabic, 'القواعد والتركيب');
    });

    test('2. ExamQuestion evaluates MCQ answers correctly', () {
      const question = ExamQuestion(
        id: 'q_mcq_1',
        sectionId: 'sec_1',
        type: ExamQuestionType.vocabularySelection,
        promptText: 'Apple',
        promptSubtext: 'ما معنى هذه الكلمة؟',
        options: ['تفاحة', 'موزة', 'برتقالة'],
        correctOptionIndex: 0,
        points: 10,
      );

      expect(question.isCorrectAnswer(0, null), isTrue);
      expect(question.isCorrectAnswer(1, null), isFalse);
    });

    test('3. ExamQuestion evaluates Speaking answers correctly', () {
      const question = ExamQuestion(
        id: 'q_spk_1',
        sectionId: 'sec_spk',
        type: ExamQuestionType.speakingProduction,
        promptText: 'Please say: Good morning',
        targetSpokenPhrase: 'Good morning',
        correctOptionIndex: 0,
        points: 10,
      );

      expect(question.isCorrectAnswer(null, 'Good morning'), isTrue);
      expect(question.isCorrectAnswer(null, 'good morning!'), isTrue);
      expect(question.isCorrectAnswer(null, 'Good night'), isFalse);
    });

    test('4. ExamSection correctly aggregates question points and count', () {
      const section = ExamSection(
        id: 'sec_1',
        titleArabic: 'قسم المفردات',
        titleEnglish: 'Vocabulary Section',
        skill: LearningSkill.vocabulary,
        questions: [
          ExamQuestion(
            id: 'q1',
            sectionId: 'sec_1',
            type: ExamQuestionType.vocabularySelection,
            promptText: 'Q1',
            options: ['A', 'B'],
            correctOptionIndex: 0,
            points: 5,
          ),
          ExamQuestion(
            id: 'q2',
            sectionId: 'sec_1',
            type: ExamQuestionType.vocabularySelection,
            promptText: 'Q2',
            options: ['A', 'B'],
            correctOptionIndex: 1,
            points: 10,
          ),
        ],
      );

      expect(section.questions.length, 2);
      expect(section.totalPoints, 15);
    });

    test(
      '5. Exam aggregates total questions and points across all sections',
      () {
        const exam = Exam(
          id: 'exam_milestone_1',
          titleArabic: 'اختبار الشهر الأول',
          titleEnglish: 'Month 1 Milestone Exam',
          descriptionArabic: 'تقييم شامل للأساسيات',
          descriptionEnglish: 'Comprehensive assessment',
          targetLanguage: 'en',
          cefrLevel: CefrLevel.a1,
          type: ExamType.monthlyMilestone,
          sections: [
            ExamSection(
              id: 'sec_vocab',
              titleArabic: 'مفردات',
              titleEnglish: 'Vocabulary',
              skill: LearningSkill.vocabulary,
              questions: [
                ExamQuestion(
                  id: 'q1',
                  sectionId: 'sec_vocab',
                  type: ExamQuestionType.vocabularySelection,
                  promptText: 'Q1',
                  options: ['A'],
                  correctOptionIndex: 0,
                  points: 10,
                ),
              ],
            ),
            ExamSection(
              id: 'sec_listen',
              titleArabic: 'استماع',
              titleEnglish: 'Listening',
              skill: LearningSkill.listening,
              questions: [
                ExamQuestion(
                  id: 'q2',
                  sectionId: 'sec_listen',
                  type: ExamQuestionType.listeningComprehension,
                  promptText: 'Listen',
                  options: ['A'],
                  correctOptionIndex: 0,
                  points: 10,
                ),
                ExamQuestion(
                  id: 'q3',
                  sectionId: 'sec_listen',
                  type: ExamQuestionType.listeningComprehension,
                  promptText: 'Listen 2',
                  options: ['B'],
                  correctOptionIndex: 0,
                  points: 10,
                ),
              ],
            ),
          ],
        );

        expect(exam.totalQuestions, 3);
        expect(exam.totalPoints, 30);
      },
    );

    test('6. ExamSkillScore calculates percentage and status accurately', () {
      const score = ExamSkillScore(
        skill: LearningSkill.grammar,
        scorePercentage: 80,
        pointsEarned: 16,
        pointsPossible: 20,
      );

      expect(score.scorePercentage, 80);
      expect(score.isStrength, isTrue); // >= 75
      expect(score.needsPractice, isFalse);
    });

    test('7. ExamResult calculates summary statistics properly', () {
      final result = ExamResult(
        id: 'res_1',
        examId: 'exam_1',
        examTitleArabic: 'اختبار تجريبي',
        examTitleEnglish: 'Practice Exam',
        overallScore: 85,
        estimatedCefrLevel: CefrLevel.a2,
        skillScores: const [
          ExamSkillScore(
            skill: LearningSkill.vocabulary,
            scorePercentage: 100,
            pointsEarned: 20,
            pointsPossible: 20,
          ),
        ],
        answeredCount: 1,
        skippedCount: 0,
        correctCount: 1,
        totalQuestions: 1,
        strengthsArabic: const ['المفردات ممتازة'],
        areasForImprovementArabic: const [],
        recommendations: const [],
        completedAt: DateTime.now(),
      );

      expect(result.overallScore, 85);
      expect(result.isPassing, isTrue);
      expect(result.isDistinction, isTrue);
      expect(result.strengthsArabic.first, 'المفردات ممتازة');
    });

    test('8. ExamAttemptState handles question navigation and completion', () {
      const exam = Exam(
        id: 'test_ex',
        titleArabic: 'اختبار قصير',
        titleEnglish: 'Short Exam',
        descriptionArabic: 'وصف',
        descriptionEnglish: 'Description',
        targetLanguage: 'en',
        cefrLevel: CefrLevel.a1,
        type: ExamType.skillCheckpoint,
        sections: [
          ExamSection(
            id: 's1',
            titleArabic: 'قسم 1',
            titleEnglish: 'Sec 1',
            skill: LearningSkill.vocabulary,
            questions: [
              ExamQuestion(
                id: 'q1',
                sectionId: 's1',
                type: ExamQuestionType.vocabularySelection,
                promptText: 'Q1',
                options: ['A', 'B'],
                correctOptionIndex: 0,
              ),
              ExamQuestion(
                id: 'q2',
                sectionId: 's1',
                type: ExamQuestionType.vocabularySelection,
                promptText: 'Q2',
                options: ['A', 'B'],
                correctOptionIndex: 1,
              ),
            ],
          ),
        ],
      );

      final state = ExamAttemptState(exam: exam);
      expect(state.currentQuestionIndex, 0);
      expect(state.currentGlobalQuestionNumber, 1);
      expect(state.isLastQuestion, isFalse);

      final state2 = state.copyWith(currentQuestionIndex: 1);
      expect(state2.isLastQuestion, isTrue);
    });
  });
}
