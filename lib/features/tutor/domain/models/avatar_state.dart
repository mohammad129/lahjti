import 'package:flutter/foundation.dart';
import '../../../onboarding/domain/models/tutor_persona.dart';

/// Distinct visual states of the AI tutor avatar during interaction.
enum AvatarState { idle, listening, thinking, speaking, error }

/// Represents future phoneme-to-viseme timing data for cloud lip-sync engines.
@immutable
class VisemeData {
  final int visemeId; // 0-21 standard MPEG-4 / Oculus viseme indices
  final int timeOffsetMs;
  final int durationMs;
  final double weight; // 0.0 to 1.0

  const VisemeData({
    required this.visemeId,
    required this.timeOffsetMs,
    required this.durationMs,
    this.weight = 1.0,
  });

  Map<String, dynamic> toJson() => {
    'visemeId': visemeId,
    'timeOffsetMs': timeOffsetMs,
    'durationMs': durationMs,
    'weight': weight,
  };
}

/// Frame-level blendshape / lip-sync parameter set for future 3D/2D mesh drivers.
@immutable
class LipSyncFrame {
  final int timestampMs;
  final double mouthOpenness; // 0.0 (closed) to 1.0 (wide open)
  final double mouthWidth; // -1.0 (narrow/pucker) to 1.0 (wide smile)
  final double jawDrop; // 0.0 to 1.0

  const LipSyncFrame({
    required this.timestampMs,
    this.mouthOpenness = 0.0,
    this.mouthWidth = 0.0,
    this.jawDrop = 0.0,
  });
}

/// Visual styling configuration for a tutor persona.
@immutable
class AvatarVisualProfile {
  final String id;
  final String nameArabic;
  final String nameEnglish;
  final String title;
  final String gender;
  final String avatarEmoji;

  const AvatarVisualProfile({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    required this.title,
    required this.gender,
    required this.avatarEmoji,
  });

  static const abbas = AvatarVisualProfile(
    id: 'abbas',
    nameArabic: 'عباس',
    nameEnglish: 'Abbas',
    title: 'معلم ومرشد أردني',
    gender: 'male',
    avatarEmoji: '👨‍🏫',
  );

  static const dunya = AvatarVisualProfile(
    id: 'dunya',
    nameArabic: 'دنيا',
    nameEnglish: 'Dunya',
    title: 'معلمة ومرشدة أردنية',
    gender: 'female',
    avatarEmoji: '👩‍🏫',
  );

  static AvatarVisualProfile fromPersona(TutorPersona persona) {
    if (persona.id == 'dunya') return dunya;
    return abbas;
  }
}
