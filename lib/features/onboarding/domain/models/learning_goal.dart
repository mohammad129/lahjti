import 'package:flutter/foundation.dart';
import '../../../../l10n/app_localizations.dart';

/// Immutable model representing a language learning objective.
@immutable
class LearningGoal {
  final String id;
  final String icon;

  const LearningGoal({required this.id, required this.icon});

  String get name => id;

  String localizedTitle(AppLocalizations l10n) {
    switch (id) {
      case 'study':
        return l10n.goalStudy;
      case 'work':
        return l10n.goalWork;
      case 'travel':
        return l10n.goalTravel;
      case 'conversation':
        return l10n.goalConversation;
      case 'daily':
        return l10n.goalDaily;
      case 'hobby':
        return l10n.goalHobby;
      case 'comprehensive':
        return l10n.goalComprehensive;
      default:
        return id;
    }
  }

  String localizedDescription(AppLocalizations l10n) {
    switch (id) {
      case 'study':
        return l10n.goalStudyDesc;
      case 'work':
        return l10n.goalWorkDesc;
      case 'travel':
        return l10n.goalTravelDesc;
      case 'conversation':
        return l10n.goalConversationDesc;
      case 'daily':
        return l10n.goalDailyDesc;
      case 'hobby':
        return l10n.goalHobbyDesc;
      case 'comprehensive':
        return l10n.goalComprehensiveDesc;
      default:
        return '';
    }
  }

  static const LearningGoal casualConversation = LearningGoal(
    id: 'conversation',
    icon: '🗣️',
  );

  static const List<LearningGoal> goals = [
    LearningGoal(id: 'study', icon: '🎓'),
    LearningGoal(id: 'work', icon: '💼'),
    LearningGoal(id: 'travel', icon: '✈️'),
    LearningGoal(id: 'conversation', icon: '🗣️'),
    LearningGoal(id: 'daily', icon: '🌍'),
    LearningGoal(id: 'hobby', icon: '❤️'),
    LearningGoal(id: 'comprehensive', icon: '🚀'),
  ];

  static const List<LearningGoal> values = goals;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningGoal &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'LearningGoal(id: $id)';
}
