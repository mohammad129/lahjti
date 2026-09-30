import 'package:flutter/foundation.dart';
import '../../../onboarding/domain/models/tutor_persona.dart';

/// Distinct operational states for the real-time voice session.
enum VoiceSessionStatus {
  idle,
  requestingPermission,
  ready,
  listening,
  processing,
  speaking,
  paused,
  error,
}

/// Represents a single conversational message exchange between learner and AI tutor.
@immutable
class VoiceMessage {
  final String id;
  final bool isUser;
  final String text;
  final String? explanationArabic;
  final String? correctedAnswer;
  final List<String> detectedErrors;
  final bool shouldCorrect;
  final String? encouragement;
  final String? nextDifficulty;
  final String? audioBase64;
  final String? voiceProvider;
  final String? conversationLanguage;
  final DateTime timestamp;

  const VoiceMessage({
    required this.id,
    required this.isUser,
    required this.text,
    this.explanationArabic,
    this.correctedAnswer,
    this.detectedErrors = const [],
    this.shouldCorrect = false,
    this.encouragement,
    this.nextDifficulty,
    this.audioBase64,
    this.voiceProvider,
    this.conversationLanguage,
    required this.timestamp,
  });

  factory VoiceMessage.fromJson(
    Map<String, dynamic> json, {
    required String id,
    DateTime? timestamp,
  }) {
    return VoiceMessage(
      id: id,
      isUser: false,
      text: json['tutorResponse'] as String? ?? '',
      explanationArabic: json['explanationArabic'] as String?,
      correctedAnswer: json['correctedVersion'] as String?,
      detectedErrors:
          (json['detectedErrors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      shouldCorrect: json['shouldCorrect'] as bool? ?? false,
      encouragement: json['encouragement'] as String?,
      nextDifficulty: json['nextDifficulty'] as String?,
      audioBase64: json['audioBase64'] as String?,
      voiceProvider: json['voiceProvider'] as String?,
      conversationLanguage: json['conversationLanguage'] as String?,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isUser': isUser,
      'text': text,
      'explanationArabic': explanationArabic,
      'correctedAnswer': correctedAnswer,
      'detectedErrors': detectedErrors,
      'shouldCorrect': shouldCorrect,
      'encouragement': encouragement,
      'nextDifficulty': nextDifficulty,
      'audioBase64': audioBase64,
      'voiceProvider': voiceProvider,
      'conversationLanguage': conversationLanguage,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoiceMessage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Immutable state container for the live voice conversational tutor session.
@immutable
class VoiceSessionState {
  final VoiceSessionStatus status;
  final TutorPersona tutor;
  final String targetLanguageCode;
  final List<VoiceMessage> messages;
  final String currentTranscript;
  final bool isSpeechAvailable;
  final bool isTtsAvailable;
  final String? errorMessage;
  final double soundLevel; // 0.0 to 1.0 for audio wave animation

  const VoiceSessionState({
    this.status = VoiceSessionStatus.idle,
    required this.tutor,
    this.targetLanguageCode = 'en',
    this.messages = const [],
    this.currentTranscript = '',
    this.isSpeechAvailable = true,
    this.isTtsAvailable = true,
    this.errorMessage,
    this.soundLevel = 0.0,
  });

  bool get isListening => status == VoiceSessionStatus.listening;
  bool get isProcessing => status == VoiceSessionStatus.processing;
  bool get isSpeaking => status == VoiceSessionStatus.speaking;

  VoiceSessionState copyWith({
    VoiceSessionStatus? status,
    TutorPersona? tutor,
    String? targetLanguageCode,
    List<VoiceMessage>? messages,
    String? currentTranscript,
    bool? isSpeechAvailable,
    bool? isTtsAvailable,
    String? errorMessage,
    double? soundLevel,
  }) {
    return VoiceSessionState(
      status: status ?? this.status,
      tutor: tutor ?? this.tutor,
      targetLanguageCode: targetLanguageCode ?? this.targetLanguageCode,
      messages: messages ?? this.messages,
      currentTranscript: currentTranscript ?? this.currentTranscript,
      isSpeechAvailable: isSpeechAvailable ?? this.isSpeechAvailable,
      isTtsAvailable: isTtsAvailable ?? this.isTtsAvailable,
      errorMessage: errorMessage,
      soundLevel: soundLevel ?? this.soundLevel,
    );
  }
}
