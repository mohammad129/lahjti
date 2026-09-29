/// Abstract interface for Speech-To-Text (STT) services.
/// Decouples UI and state management from any underlying platform or hardware SDKs.
abstract class SpeechToTextService {
  /// Checks permissions and initializes the speech recognition engine.
  /// Returns `true` if speech recognition is available on this device.
  Future<bool> initialize();

  /// Starts listening to microphone input in the specified language code (e.g. 'en', 'es', 'ar').
  ///
  /// [onResult] delivers progressive transcripts (both partial and final).
  /// [onSoundLevelChange] delivers sound level normalized from 0.0 to 1.0.
  /// [onError] delivers error descriptions if speech recognition fails.
  Future<void> startListening({
    required String languageCode,
    required void Function(String words, bool isFinal) onResult,
    void Function(double level)? onSoundLevelChange,
    void Function(String error)? onError,
  });

  /// Stops listening and finalizes the audio recognition stream.
  Future<void> stopListening();

  /// Cancels listening immediately without finalizing.
  Future<void> cancel();

  /// Whether speech recognition is available and initialized.
  bool get isAvailable;

  /// Whether the microphone is currently active and listening.
  bool get isListening;

  /// Whether the user has granted microphone permission.
  bool get hasPermission;

  /// Releases resources.
  void dispose();
}
