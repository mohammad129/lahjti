import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/learning/domain/models/vocabulary_item.dart';
import 'package:lahjti/features/placement/domain/models/cefr_level.dart';
import 'package:lahjti/features/vocabulary/domain/models/vocabulary_practice_models.dart';

void main() {
  group('VocabularyPracticeModels Tests', () {
    final sampleItem = VocabularyItem(
      id: 'v_hello',
      term: 'Hello',
      translationArabic: 'مرحباً',
      exampleSentence: 'Hello, my name is John.',
      exampleTranslationArabic: 'مرحباً، اسمي جون.',
      difficulty: CefrLevel.a1,
      category: 'Greetings',
    );

    test('1. PracticeMode extensions provide localized names', () {
      expect(PracticeMode.recognizeMeaning.nameArabic, 'معرفة المعنى');
      expect(PracticeMode.wordSelection.nameArabic, 'اختيار الكلمة');
      expect(PracticeMode.sentenceCompletion.nameArabic, 'إكمال الجملة');
      expect(PracticeMode.speakingProduction.nameArabic, 'النطق والتحدث');

      expect(PracticeMode.recognizeMeaning.nameEnglish, 'Meaning Recognition');
    });

    test('2. PracticeQuestion isCorrect matches correctOptionIndex', () {
      final q = PracticeQuestion(
        id: 'q1',
        mode: PracticeMode.recognizeMeaning,
        targetItem: sampleItem,
        promptText: 'Hello',
        options: const ['صباح الخير', 'مرحباً', 'مع السلامة', 'شكراً'],
        correctOptionIndex: 1,
        explanationArabic: 'الكلمة تعني مرحباً',
        explanationEnglish: 'The word means Hello',
      );

      expect(q.isCorrect(1), isTrue);
      expect(q.isCorrect(0), isFalse);
      expect(q.isCorrect(2), isFalse);
    });

    test('3. PracticeSessionState calculates score percentage correctly', () {
      final q1 = PracticeQuestion(
        id: 'q1',
        mode: PracticeMode.recognizeMeaning,
        targetItem: sampleItem,
        promptText: 'Hello',
        options: const ['A', 'B'],
        correctOptionIndex: 0,
        explanationArabic: 'exp',
        explanationEnglish: 'exp',
      );
      final q2 = PracticeQuestion(
        id: 'q2',
        mode: PracticeMode.wordSelection,
        targetItem: sampleItem,
        promptText: 'مرحباً',
        options: const ['A', 'B'],
        correctOptionIndex: 1,
        explanationArabic: 'exp',
        explanationEnglish: 'exp',
      );

      final state = PracticeSessionState(
        questions: [q1, q2],
        currentIndex: 0,
        results: [
          PracticeAnswerResult(
            question: q1,
            selectedOptionIndex: 0,
            isCorrect: true,
            timestamp: DateTime.now(),
          ),
          PracticeAnswerResult(
            question: q2,
            selectedOptionIndex: 0,
            isCorrect: false,
            timestamp: DateTime.now(),
          ),
        ],
      );

      expect(state.totalQuestions, 2);
      expect(state.correctCount, 1);
      expect(state.incorrectCount, 1);
      expect(state.scorePercentage, 50.0);
    });

    test('4. DailyVocabularyGoal computes progress ratio and goal status', () {
      const goal = DailyVocabularyGoal(
        targetCount: 10,
        learnedTodayCount: 4,
        reviewedTodayCount: 6,
        masteredTotalCount: 15,
        dueForReviewCount: 2,
      );

      expect(goal.totalCompletedToday, 10);
      expect(goal.progressRatio, 1.0);
      expect(goal.isGoalReached, isTrue);

      const partialGoal = DailyVocabularyGoal(
        targetCount: 10,
        learnedTodayCount: 2,
        reviewedTodayCount: 3,
        masteredTotalCount: 5,
        dueForReviewCount: 4,
      );

      expect(partialGoal.totalCompletedToday, 5);
      expect(partialGoal.progressRatio, 0.5);
      expect(partialGoal.isGoalReached, isFalse);
    });
  });
}
