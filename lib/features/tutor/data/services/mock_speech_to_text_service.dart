import '../../domain/services/speech_to_text_service.dart';

/// Mock STT service for deterministic testing and offline development.
class MockSpeechToTextService implements SpeechToTextService {
  bool _isListening = false;
  bool _isAvailable = true;
  bool _hasPermission = true;
  final bool autoFinalize;
  String? simulatedSpeechResult;

  MockSpeechToTextService({
    bool isAvailable = true,
    bool hasPermission = true,
    this.autoFinalize = false,
    this.simulatedSpeechResult,
  }) : _isAvailable = isAvailable,
       _hasPermission = hasPermission;

  void setAvailability(bool available) => _isAvailable = available;
  void setPermission(bool permission) => _hasPermission = permission;

  @override
  bool get isAvailable => _isAvailable;

  @override
  bool get isListening => _isListening;

  @override
  bool get hasPermission => _hasPermission;

  @override
  Future<bool> initialize() async {
    return _isAvailable && _hasPermission;
  }

  @override
  Future<void> startListening({
    required String languageCode,
    required void Function(String words, bool isFinal) onResult,
    void Function(double level)? onSoundLevelChange,
    void Function(String error)? onError,
  }) async {
    if (!_hasPermission) {
      onError?.call('Microphone permission denied');
      return;
    }

    if (!_isAvailable) {
      onError?.call('Speech recognition unavailable');
      return;
    }

    _isListening = true;
    onSoundLevelChange?.call(0.6);

    final words = simulatedSpeechResult ?? 'Hello, my name is Abbas';
    if (autoFinalize) {
      onResult(words, true);
      _isListening = false;
    } else {
      onResult(words.split(' ').first, false);
    }
  }

  @override
  Future<void> stopListening() async {
    _isListening = false;
  }

  @override
  Future<void> cancel() async {
    _isListening = false;
  }

  @override
  void dispose() {
    _isListening = false;
  }
}
