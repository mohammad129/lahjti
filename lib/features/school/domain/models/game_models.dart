import 'package:flutter/foundation.dart';
import '../../../learning/domain/models/learning_skill.dart';

/// Educational mini-game categories for interactive learning.
enum GameType {
  wordMatch,
  listenAndChoose,
  pictureWordSelect,
  sentenceBuilder,
  memoryVocab,
  quickQuiz;

  /// Alias for listenAndChoose for requirement compatibility
  static GameType get listeningChoice => GameType.listenAndChoose;

  String get iconEmoji {
    switch (this) {
      case GameType.wordMatch:
        return '🧩';
      case GameType.listenAndChoose:
        return '🎧';
      case GameType.pictureWordSelect:
        return '🖼️';
      case GameType.sentenceBuilder:
        return '🧱';
      case GameType.memoryVocab:
        return '🃏';
      case GameType.quickQuiz:
        return '⚡';
    }
  }

  static GameType fromString(String value) {
    if (value == 'listeningChoice') return GameType.listenAndChoose;
    return GameType.values.firstWhere(
      (g) => g.name == value,
      orElse: () => GameType.wordMatch,
    );
  }
}

/// A question/card/challenge inside an educational mini-game.
@immutable
class GameQuestion {
  final String id;
  final String promptArabic;
  final String promptEnglish;
  final String? promptAudio;
  final String? promptImage;
  final List<String> options;
  final int correctOptionIndex;
  final String correctAnswer;
  final String? explanationArabic;
  final String? explanationEnglish;
  final List<String>? scrambledWords;
  final Map<String, String>? matchPairs;

  const GameQuestion({
    required this.id,
    required this.promptArabic,
    required this.promptEnglish,
    this.promptAudio,
    this.promptImage,
    this.options = const [],
    this.correctOptionIndex = 0,
    required this.correctAnswer,
    this.explanationArabic,
    this.explanationEnglish,
    this.scrambledWords,
    this.matchPairs,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'promptArabic': promptArabic,
      'promptEnglish': promptEnglish,
      'promptAudio': promptAudio,
      'promptImage': promptImage,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'correctAnswer': correctAnswer,
      'explanationArabic': explanationArabic,
      'explanationEnglish': explanationEnglish,
      'scrambledWords': scrambledWords,
      'matchPairs': matchPairs,
    };
  }

  factory GameQuestion.fromJson(Map<String, dynamic> json) {
    return GameQuestion(
      id: json['id'] as String,
      promptArabic: json['promptArabic'] as String,
      promptEnglish: json['promptEnglish'] as String,
      promptAudio: json['promptAudio'] as String?,
      promptImage: json['promptImage'] as String?,
      options:
          (json['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      correctOptionIndex: json['correctOptionIndex'] as int? ?? 0,
      correctAnswer: json['correctAnswer'] as String? ?? '',
      explanationArabic: json['explanationArabic'] as String?,
      explanationEnglish: json['explanationEnglish'] as String?,
      scrambledWords:
          (json['scrambledWords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(),
      matchPairs: (json['matchPairs'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v.toString()),
      ),
    );
  }
}

/// An educational mini-game activity that can be played by students.
@immutable
class GameActivity {
  final String id;
  final String titleArabic;
  final String titleEnglish;
  final String descriptionArabic;
  final String descriptionEnglish;
  final GameType gameType;
  final String difficulty;
  final LearningSkill skill;
  final int xpReward;
  final String iconEmoji;
  final bool isChildFriendly;
  final List<GameQuestion> questions;

  const GameActivity({
    required this.id,
    required this.titleArabic,
    required this.titleEnglish,
    required this.descriptionArabic,
    required this.descriptionEnglish,
    required this.gameType,
    required this.difficulty,
    required this.skill,
    required this.xpReward,
    required this.iconEmoji,
    this.isChildFriendly = true,
    required this.questions,
  });

  String localizedTitle(bool isArabic) => isArabic ? titleArabic : titleEnglish;
  String localizedDescription(bool isArabic) =>
      isArabic ? descriptionArabic : descriptionEnglish;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titleArabic': titleArabic,
      'titleEnglish': titleEnglish,
      'descriptionArabic': descriptionArabic,
      'descriptionEnglish': descriptionEnglish,
      'gameType': gameType.name,
      'difficulty': difficulty,
      'skill': skill.name,
      'xpReward': xpReward,
      'iconEmoji': iconEmoji,
      'isChildFriendly': isChildFriendly,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }

  factory GameActivity.fromJson(Map<String, dynamic> json) {
    return GameActivity(
      id: json['id'] as String,
      titleArabic: json['titleArabic'] as String,
      titleEnglish: json['titleEnglish'] as String,
      descriptionArabic: json['descriptionArabic'] as String,
      descriptionEnglish: json['descriptionEnglish'] as String,
      gameType: GameType.fromString(json['gameType'] as String),
      difficulty: json['difficulty'] as String? ?? 'beginner',
      skill: LearningSkill.values.firstWhere(
        (s) => s.name == json['skill'],
        orElse: () => LearningSkill.vocabulary,
      ),
      xpReward: json['xpReward'] as int? ?? 25,
      iconEmoji: json['iconEmoji'] as String? ?? '🎮',
      isChildFriendly: json['isChildFriendly'] as bool? ?? true,
      questions:
          (json['questions'] as List<dynamic>?)
              ?.map((q) => GameQuestion.fromJson(q as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

/// Result of playing an educational game session.
@immutable
class GameResult {
  final String gameId;
  final String? taskId;
  final GameType gameType;
  final int totalQuestions;
  final int correctAnswers;
  final int incorrectAnswers;
  final double scorePercentage;
  final int earnedXp;
  final DateTime completedAt;
  final bool passed;
  final LearningSkill? skill;
  final List<String> vocabularyIds;

  const GameResult({
    required this.gameId,
    this.taskId,
    required this.gameType,
    required this.totalQuestions,
    required this.correctAnswers,
    int? incorrectAnswers,
    required this.scorePercentage,
    required this.earnedXp,
    required this.completedAt,
    required this.passed,
    this.skill,
    this.vocabularyIds = const [],
  }) : incorrectAnswers = incorrectAnswers ?? (totalQuestions - correctAnswers);

  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'taskId': taskId,
      'gameType': gameType.name,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'incorrectAnswers': incorrectAnswers,
      'scorePercentage': scorePercentage,
      'earnedXp': earnedXp,
      'completedAt': completedAt.toIso8601String(),
      'passed': passed,
      'skill': skill?.name,
      'vocabularyIds': vocabularyIds,
    };
  }

  factory GameResult.fromJson(Map<String, dynamic> json) {
    final total = json['totalQuestions'] as int? ?? 0;
    final correct = json['correctAnswers'] as int? ?? 0;
    final incorrect = json['incorrectAnswers'] as int? ?? (total - correct);

    return GameResult(
      gameId: json['gameId'] as String,
      taskId: json['taskId'] as String?,
      gameType: GameType.fromString(json['gameType'] as String),
      totalQuestions: total,
      correctAnswers: correct,
      incorrectAnswers: incorrect,
      scorePercentage: (json['scorePercentage'] as num?)?.toDouble() ?? 0.0,
      earnedXp: json['earnedXp'] as int? ?? 0,
      completedAt:
          json['completedAt'] != null
              ? DateTime.tryParse(json['completedAt'] as String) ??
                  DateTime.now()
              : DateTime.now(),
      passed: json['passed'] as bool? ?? true,
      skill:
          json['skill'] != null
              ? LearningSkill.values.firstWhere(
                (s) => s.name == json['skill'],
                orElse: () => LearningSkill.vocabulary,
              )
              : null,
      vocabularyIds:
          (json['vocabularyIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  GameResult copyWith({
    String? gameId,
    String? taskId,
    GameType? gameType,
    int? totalQuestions,
    int? correctAnswers,
    int? incorrectAnswers,
    double? scorePercentage,
    int? earnedXp,
    DateTime? completedAt,
    bool? passed,
    LearningSkill? skill,
    List<String>? vocabularyIds,
  }) {
    return GameResult(
      gameId: gameId ?? this.gameId,
      taskId: taskId ?? this.taskId,
      gameType: gameType ?? this.gameType,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      incorrectAnswers: incorrectAnswers ?? this.incorrectAnswers,
      scorePercentage: scorePercentage ?? this.scorePercentage,
      earnedXp: earnedXp ?? this.earnedXp,
      completedAt: completedAt ?? this.completedAt,
      passed: passed ?? this.passed,
      skill: skill ?? this.skill,
      vocabularyIds: vocabularyIds ?? this.vocabularyIds,
    );
  }
}
