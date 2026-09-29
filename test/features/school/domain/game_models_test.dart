import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/learning/domain/models/learning_skill.dart';
import 'package:lahjti/features/school/domain/models/game_models.dart';

void main() {
  group('Educational Game Domain Models Tests', () {
    test('1. GameType enum parsing and icon emojis', () {
      expect(GameType.fromString('wordMatch'), GameType.wordMatch);
      expect(GameType.fromString('listenAndChoose'), GameType.listenAndChoose);
      expect(GameType.fromString('sentenceBuilder'), GameType.sentenceBuilder);
      expect(GameType.fromString('memoryVocab'), GameType.memoryVocab);
      expect(GameType.fromString('quickQuiz'), GameType.quickQuiz);

      expect(GameType.wordMatch.iconEmoji, '🧩');
      expect(GameType.listenAndChoose.iconEmoji, '🎧');
      expect(GameType.sentenceBuilder.iconEmoji, '🧱');
      expect(GameType.memoryVocab.iconEmoji, '🃏');
      expect(GameType.quickQuiz.iconEmoji, '⚡');
    });

    test('2. GameActivity and GameQuestion JSON serialization', () {
      const question = GameQuestion(
        id: 'q1',
        promptArabic: 'طابق الكلمات',
        promptEnglish: 'Match Words',
        correctAnswer: 'matched',
        matchPairs: {'شاي': 'Tea', 'قهوة': 'Coffee'},
      );

      const activity = GameActivity(
        id: 'game_wm_1',
        titleArabic: 'مطابقة الكلمات',
        titleEnglish: 'Word Match',
        descriptionArabic: 'طابق الكلمات بالمعاني',
        descriptionEnglish: 'Match words with meanings',
        gameType: GameType.wordMatch,
        difficulty: 'beginner',
        skill: LearningSkill.vocabulary,
        xpReward: 30,
        iconEmoji: '🧩',
        questions: [question],
      );

      final json = activity.toJson();
      final fromJson = GameActivity.fromJson(json);

      expect(fromJson.id, 'game_wm_1');
      expect(fromJson.gameType, GameType.wordMatch);
      expect(fromJson.questions.length, 1);
      expect(fromJson.questions.first.matchPairs?['شاي'], 'Tea');
    });

    test('3. GameResult calculates score and pass criteria', () {
      final result = GameResult(
        gameId: 'game_wm_1',
        gameType: GameType.wordMatch,
        totalQuestions: 5,
        correctAnswers: 4,
        scorePercentage: 80.0,
        earnedXp: 30,
        completedAt: DateTime(2026, 9, 21),
        passed: true,
      );

      expect(result.passed, isTrue);
      expect(result.scorePercentage, 80.0);
      expect(result.earnedXp, 30);

      final json = result.toJson();
      final fromJson = GameResult.fromJson(json);
      expect(fromJson.gameId, 'game_wm_1');
      expect(fromJson.correctAnswers, 4);
    });
  });
}
