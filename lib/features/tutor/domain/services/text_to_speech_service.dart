/// Abstract interface for Text-To-Speech (TTS) services.
/// Allows speaking tutor messages in target and native languages without vendor lock-in.
abstract class TextToSpeechService {
  /// Initializes the TTS engine and configures default audio parameters.
  Future<bool> initialize();

  /// Speaks the given [text] aloud in the specified [languageCode] (e.g. 'en', 'es', 'ar').
  ///
  /// Optional [audioBase64] provides pre-synthesized audio (e.g. from ElevenLabs).
  /// [onComplete] is triggered when playback finishes.
  Future<void> speak({
    required String text,
    required String languageCode,
    String? audioBase64,
    String? tutorPersona,
    void Function()? onComplete,
    void Function(String error)? onError,
  });

  /// Immediately stops audio playback.
  Future<void> stop();

  /// Pauses audio playback if supported.
  Future<void> pause();

  /// Resumes audio playback if supported.
  Future<void> resume();

  /// Whether the TTS engine is currently playing speech.
  bool get isSpeaking;

  /// Whether the TTS engine is ready and available on this device.
  bool get isAvailable;

  /// Releases resources.
  void dispose();
}
