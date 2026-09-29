import 'package:flutter/foundation.dart';
import 'cefr_level.dart';
import 'question_type.dart';

/// Immutable model representing a single placement question.
@immutable
class PlacementQuestion {
  final String id;
  final QuestionType type;
  final String targetLanguage;
  final CefrLevel difficulty;
  final String prompt;
  final String promptArabic;
  final List<String> expectedSkills;
  final bool hintsAllowed;
  final String? hint;
  final Map<String, dynamic> metadata;

  const PlacementQuestion({
    required this.id,
    required this.type,
    required this.targetLanguage,
    required this.difficulty,
    required this.prompt,
    required this.promptArabic,
    this.expectedSkills = const [],
    this.hintsAllowed = false,
    this.hint,
    this.metadata = const {},
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlacementQuestion &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'PlacementQuestion(id: $id, type: $type, difficulty: ${difficulty.code})';
}
