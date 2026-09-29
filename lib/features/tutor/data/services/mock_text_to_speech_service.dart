import '../../domain/services/text_to_speech_service.dart';

/// Mock TTS service for automated testing and offline development.
class MockTextToSpeechService implements TextToSpeechService {
  bool _isSpeaking = false;
  bool _isAvailable = true;
  String? lastSpokenText;
  String? lastLanguageCode;
  int speakCount = 0;
  int stopCount = 0;

  MockTextToSpeechService({bool isAvailable = true})
    : _isAvailable = isAvailable;

  void setAvailability(bool available) => _isAvailable = available;

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  bool get isAvailable => _isAvailable;

  @override
  Future<bool> initialize() async {
    return _isAvailable;
  }

  @override
  Future<void> speak({
    required String text,
    required String languageCode,
    String? audioBase64,
    String? tutorPersona,
    void Function()? onComplete,
    void Function(String error)? onError,
  }) async {
    if (!_isAvailable) {
      onError?.call('TTS unavailable');
      return;
    }

    _isSpeaking = true;
    lastSpokenText = text;
    lastLanguageCode = languageCode;
    speakCount++;

    _isSpeaking = false;
    onComplete?.call();
  }

  @override
  Future<void> stop() async {
    _isSpeaking = false;
    stopCount++;
  }

  @override
  Future<void> pause() async {
    _isSpeaking = false;
  }

  @override
  Future<void> resume() async {
    _isSpeaking = true;
  }

  @override
  void dispose() {
    _isSpeaking = false;
  }
}
