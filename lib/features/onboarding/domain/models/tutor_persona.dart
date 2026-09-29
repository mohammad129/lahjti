import 'package:flutter/foundation.dart';
import '../../../../l10n/app_localizations.dart';

/// Immutable model representing an AI Tutor Persona.
@immutable
class TutorPersona {
  final String id;
  final String nameAr;
  final String nameEn;
  final String gender;
  final String personality;
  final int humorLevel; // 1-10
  final String teachingStyle;
  final String descriptionAr;
  final String descriptionEn;
  final List<String> traitsAr;
  final List<String> traitsEn;
  final String avatarPlaceholder;

  const TutorPersona({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.gender,
    required this.personality,
    required this.humorLevel,
    required this.teachingStyle,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.traitsAr,
    required this.traitsEn,
    required this.avatarPlaceholder,
  });

  String get avatarEmoji => id == 'abbas' ? '👨‍🏫' : '👩‍🏫';

  String localizedName(AppLocalizations l10n) {
    return id == 'abbas' ? l10n.tutorAbbasName : l10n.tutorDunyaName;
  }

  String localizedRole(AppLocalizations l10n) {
    return id == 'abbas' ? l10n.tutorAbbasRole : l10n.tutorDunyaRole;
  }

  String localizedDescription(AppLocalizations l10n) {
    return id == 'abbas' ? l10n.tutorAbbasDesc : l10n.tutorDunyaDesc;
  }

  List<String> localizedTraits(AppLocalizations l10n) {
    if (id == 'abbas') {
      return [
        l10n.tutorAbbasTrait1,
        l10n.tutorAbbasTrait2,
        l10n.tutorAbbasTrait3,
        l10n.tutorAbbasTrait4,
      ];
    } else {
      return [
        l10n.tutorDunyaTrait1,
        l10n.tutorDunyaTrait2,
        l10n.tutorDunyaTrait3,
        l10n.tutorDunyaTrait4,
      ];
    }
  }

  static const List<TutorPersona> tutors = [
    TutorPersona(
      id: 'abbas',
      nameAr: 'عباس',
      nameEn: 'Abbas',
      gender: 'male',
      personality: 'friendly, energetic, witty, motivating',
      humorLevel: 8,
      teachingStyle: 'conversational, encouraging, natural practice partner',
      descriptionAr:
          'مدرب ذكي مرح، طاقته عالية، وبشجعك تحكي بطلاقة وعفوية باللغة اللي بتتعلمها 😂',
      descriptionEn:
          'A friendly, energetic, and witty AI language tutor who encourages you to speak naturally 😂',
      traitsAr: ['حيوي', 'فكاهي', 'مشجع', 'عفوي'],
      traitsEn: ['Energetic', 'Witty', 'Encouraging', 'Playful'],
      avatarPlaceholder: 'assets/avatars/abbas.png',
    ),
    TutorPersona(
      id: 'dunya',
      nameAr: 'دنيا',
      nameEn: 'Dunya',
      gender: 'female',
      personality: 'warm, patient, confident, supportive',
      humorLevel: 6,
      teachingStyle: 'gentle pacing, confidence-building, structured',
      descriptionAr:
          'مدربة ذكية دافية، صبورة، وواثقة بتساعدك تبني طلاقتك وثقتك باللغة خطوة بخطوة.',
      descriptionEn:
          'A warm, patient, and confident AI language tutor who helps you build conversational confidence.',
      traitsAr: ['دافية', 'صبورة', 'واثقة', 'مشجعة'],
      traitsEn: ['Warm', 'Patient', 'Confident', 'Encouraging'],
      avatarPlaceholder: 'assets/avatars/dunya.png',
    ),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TutorPersona &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TutorPersona(id: $id, nameEn: $nameEn)';
}
