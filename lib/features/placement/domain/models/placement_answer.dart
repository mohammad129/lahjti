import 'package:flutter/foundation.dart';

/// Immutable model representing the user's submitted response to a placement question.
@immutable
class PlacementAnswer {
  final String questionId;
  final String userResponse;
  final Duration responseDuration;
  final bool skipped;
  final DateTime submittedAt;

  const PlacementAnswer({
    required this.questionId,
    required this.userResponse,
    required this.responseDuration,
    required this.skipped,
    required this.submittedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlacementAnswer &&
          runtimeType == other.runtimeType &&
          questionId == other.questionId &&
          userResponse == other.userResponse &&
          skipped == other.skipped;

  @override
  int get hashCode =>
      questionId.hashCode ^ userResponse.hashCode ^ skipped.hashCode;

  @override
  String toString() =>
      'PlacementAnswer(qId: $questionId, skipped: $skipped, response: $userResponse)';
}
