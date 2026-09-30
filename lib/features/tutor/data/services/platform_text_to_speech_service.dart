import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../domain/services/text_to_speech_service.dart';

/// Concrete implementation of [TextToSpeechService] using the `flutter_tts` plugin.
class PlatformTextToSpeechService implements TextToSpeechService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  bool get isAvailable => _isInitialized;

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('TTS Error: $msg');
      });

      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('TTS Initialization Error: $e');
      _isInitialized = false;
      return false;
    }
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
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) {
        onError?.call('TTS engine not available');
        return;
      }
    }

    try {
      final ttsLang = _mapLanguageToTtsCode(languageCode);
      await _flutterTts.setLanguage(ttsLang);

      if (onComplete != null) {
        _flutterTts.setCompletionHandler(() {
          _isSpeaking = false;
          onComplete();
        });
      }

      if (onError != null) {
        _flutterTts.setErrorHandler((msg) {
          _isSpeaking = false;
          onError(msg.toString());
        });
      }

      _isSpeaking = true;
      await _flutterTts.speak(text);
    } catch (e) {
      _isSpeaking = false;
      onError?.call('Failed to speak text: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (e) {
      debugPrint('Error stopping TTS: $e');
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      debugPrint('Error pausing TTS: $e');
    }
  }

  @override
  Future<void> resume() async {
    // FlutterTTS does not support resume on all platforms, fallback to no-op
  }

  @override
  void dispose() {
    _flutterTts.stop();
  }

  String _mapLanguageToTtsCode(String code) {
    final normalized = code.toLowerCase();
    if (normalized.startsWith('ar')) return 'ar';
    if (normalized.startsWith('en')) return 'en-US';
    if (normalized.startsWith('es')) return 'es-ES';
    if (normalized.startsWith('fr')) return 'fr-FR';
    if (normalized.startsWith('de')) return 'de-DE';
    if (normalized.startsWith('it')) return 'it-IT';
    if (normalized.startsWith('tr')) return 'tr-TR';
    if (normalized.startsWith('ja')) return 'ja-JP';
    if (normalized.startsWith('zh')) return 'zh-CN';
    if (normalized.startsWith('ko')) return 'ko-KR';

    switch (normalized) {
      case 'es':
        return 'es-ES';
      case 'fr':
        return 'fr-FR';
      case 'de':
        return 'de-DE';
      case 'it':
        return 'it-IT';
      case 'tr':
        return 'tr-TR';
      case 'ja':
        return 'ja-JP';
      case 'zh':
        return 'zh-CN';
      case 'ko':
        return 'ko-KR';
      case 'ar':
        return 'ar';
      case 'en':
      default:
        return 'en-US';
    }
  }
}
