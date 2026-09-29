import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/learning/data/curriculum/starter_curriculum.dart';
import 'package:lahjti/features/vocabulary/domain/models/vocabulary_practice_models.dart';
import 'package:lahjti/features/vocabulary/domain/services/practice_question_generator.dart';

void main() {
  group('PracticeQuestionGenerator Tests', () {
    final generator = PracticeQuestionGenerator(random: Random(123));
    final pool = StarterCurriculum.starterVocabulary;

    test('1. Generates empty questions list when target items are empty', () {
      final questions = generator.generateQuestions(
        targetItems: [],
        allItemsPool: pool,
      );

      expect(questions, isEmpty);
    });

    test('2. Generates balanced questions across multiple practice modes', () {
      final questions = generator.generateQuestions(
        targetItems: pool,
        allItemsPool: pool,
        maxQuestions: 8,
      );

      expect(questions.length, 8);

      final modes = questions.map((q) => q.mode).toSet();
      expect(modes.contains(PracticeMode.recognizeMeaning), isTrue);
      expect(modes.contains(PracticeMode.wordSelection), isTrue);
      expect(modes.contains(PracticeMode.sentenceCompletion), isTrue);
      expect(modes.contains(PracticeMode.speakingProduction), isTrue);
    });

    test('3. Question options contain exactly 1 correct answer', () {
      final questions = generator.generateQuestions(
        targetItems: pool.take(4).toList(),
        allItemsPool: pool,
      );

      for (final q in questions) {
        expect(q.options.length, greaterThanOrEqualTo(2));
        expect(q.correctOptionIndex, inInclusiveRange(0, q.options.length - 1));

        if (q.mode == PracticeMode.recognizeMeaning) {
          expect(
            q.options[q.correctOptionIndex],
            q.targetItem.translationArabic,
          );
        } else if (q.mode == PracticeMode.wordSelection ||
            q.mode == PracticeMode.sentenceCompletion ||
            q.mode == PracticeMode.speakingProduction) {
          expect(q.options[q.correctOptionIndex], q.targetItem.term);
        }
      }
    });

    test('4. Sentence completion question masks the target word', () {
      final questions = generator.generateQuestions(
        targetItems: pool.take(6).toList(),
        allItemsPool: pool,
      );

      final sentenceQ = questions.firstWhere(
        (q) => q.mode == PracticeMode.sentenceCompletion,
      );

      expect(sentenceQ.promptText.contains('_______'), isTrue);
    });
  });
}
