import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../domain/services/speech_to_text_service.dart';

/// Concrete implementation of [SpeechToTextService] using the `speech_to_text` plugin.
class PlatformSpeechToTextService implements SpeechToTextService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _hasPermission = false;

  @override
  bool get isAvailable => _isInitialized && _speech.isAvailable;

  @override
  bool get isListening => _speech.isListening;

  @override
  bool get hasPermission => _hasPermission;

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return _speech.isAvailable;

    try {
      _hasPermission = await _speech.initialize(
        onError: (val) => debugPrint('STT Error: ${val.errorMsg}'),
        onStatus: (val) => debugPrint('STT Status: $val'),
      );
      _isInitialized = true;
      return _hasPermission && _speech.isAvailable;
    } catch (e) {
      debugPrint('STT Initialization Exception: $e');
      _isInitialized = false;
      _hasPermission = false;
      return false;
    }
  }

  @override
  Future<void> startListening({
    required String languageCode,
    required void Function(String words, bool isFinal) onResult,
    void Function(double level)? onSoundLevelChange,
    void Function(String error)? onError,
  }) async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) {
        onError?.call('Microphone permission not granted or STT unavailable');
        return;
      }
    }

    if (_speech.isListening) {
      await _speech.stop();
    }

    final localeId = _mapLanguageToLocale(languageCode);

    try {
      final options = stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        cancelOnError: true,
        partialResults: true,
        localeId: localeId,
      );

      await _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords, result.finalResult);
        },
        onSoundLevelChange: onSoundLevelChange,
        listenOptions: options,
      );
    } catch (e) {
      onError?.call('Failed to start listening: $e');
    }
  }

  @override
  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  @override
  Future<void> cancel() async {
    if (_speech.isListening) {
      await _speech.cancel();
    }
  }

  @override
  void dispose() {
    _speech.stop();
  }

  String _mapLanguageToLocale(String code) {
    switch (code.toLowerCase()) {
      case 'es':
        return 'es_ES';
      case 'fr':
        return 'fr_FR';
      case 'de':
        return 'de_DE';
      case 'it':
        return 'it_IT';
      case 'tr':
        return 'tr_TR';
      case 'ja':
        return 'ja_JP';
      case 'zh':
        return 'zh_CN';
      case 'ko':
        return 'ko_KR';
      case 'ar':
        return 'ar_JO';
      case 'en':
      default:
        return 'en_US';
    }
  }
}
