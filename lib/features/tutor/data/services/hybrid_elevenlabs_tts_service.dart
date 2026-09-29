import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/services/text_to_speech_service.dart';
import 'platform_text_to_speech_service.dart';

/// Production-ready Hybrid Text-To-Speech Service integrating backend ElevenLabs
/// studio audio playback with instant fallback to on-device platform TTS.
class HybridElevenLabsTtsService implements TextToSpeechService {
  final ApiClient? _apiClient;
  final PlatformTextToSpeechService _fallbackDeviceTts;
  AudioPlayer? _audioPlayer;

  bool _isInitialized = false;
  bool _isPlayingAudio = false;

  HybridElevenLabsTtsService({
    ApiClient? apiClient,
    PlatformTextToSpeechService? fallbackDeviceTts,
    AudioPlayer? audioPlayer,
  }) : _apiClient = apiClient,
       _fallbackDeviceTts = fallbackDeviceTts ?? PlatformTextToSpeechService(),
       _audioPlayer = audioPlayer;

  AudioPlayer? _getAudioPlayerSafely() {
    if (_audioPlayer != null) return _audioPlayer;
    try {
      _audioPlayer = AudioPlayer();
      _audioPlayer!.onPlayerStateChanged.listen((state) {
        _isPlayingAudio = (state == PlayerState.playing);
      });
      return _audioPlayer;
    } catch (e) {
      debugPrint('AudioPlayer initialization skipped: $e');
      return null;
    }
  }

  @override
  bool get isSpeaking => _isPlayingAudio || _fallbackDeviceTts.isSpeaking;

  @override
  bool get isAvailable => _isInitialized;

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      await _fallbackDeviceTts.initialize();
    } catch (e) {
      debugPrint('Device TTS initialization notice: $e');
    }
    _isInitialized = true;
    return true;
  }

  /// Speaks the given text.
  /// If [audioBase64] is provided or can be fetched from backend ElevenLabs,
  /// it plays via [AudioPlayer]. Otherwise, it delegates to on-device TTS.
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
      await initialize();
    }

    // 1. If audioBase64 is already supplied in message
    if (audioBase64 != null && audioBase64.trim().isNotEmpty) {
      final played = await _playBase64Audio(
        audioBase64: audioBase64,
        onComplete: onComplete,
        onError: onError,
      );
      if (played) return;
    }

    // 2. Try fetching ElevenLabs audio on-demand if ApiClient is available
    if (_apiClient != null && text.trim().isNotEmpty) {
      try {
        final response = await _apiClient.post(
          '/tutor/synthesize',
          data: {
            'text': text,
            'tutorPersona': tutorPersona ?? 'abbas',
            'targetLanguage': languageCode,
          },
        );

        final rawBase64 = response.data?['audioBase64'] as String?;
        if (rawBase64 != null && rawBase64.isNotEmpty) {
          final played = await _playBase64Audio(
            audioBase64: rawBase64,
            onComplete: onComplete,
            onError: onError,
          );
          if (played) return;
        }
      } catch (e) {
        debugPrint(
          'ElevenLabs remote synthesis unavailable, using device fallback: $e',
        );
      }
    }

    // 3. Fallback: On-Device Platform TTS (100% resilient)
    await _fallbackDeviceTts.speak(
      text: text,
      languageCode: languageCode,
      onComplete: onComplete,
      onError: onError,
    );
  }

  Future<bool> _playBase64Audio({
    required String audioBase64,
    void Function()? onComplete,
    void Function(String error)? onError,
  }) async {
    try {
      final player = _getAudioPlayerSafely();
      if (player == null) return false;

      final bytes = base64Decode(audioBase64.trim());
      if (bytes.isEmpty) return false;

      // Stop any existing playback
      await stop();

      // Listen for playback completion
      player.onPlayerComplete.first.then((_) {
        _isPlayingAudio = false;
        onComplete?.call();
      });

      await player.play(BytesSource(bytes));
      _isPlayingAudio = true;
      return true;
    } catch (e) {
      debugPrint('Error playing ElevenLabs base64 audio: $e');
      _isPlayingAudio = false;
      return false;
    }
  }

  @override
  Future<void> stop() async {
    try {
      if (_isPlayingAudio && _audioPlayer != null) {
        await _audioPlayer!.stop();
        _isPlayingAudio = false;
      }
      await _fallbackDeviceTts.stop();
    } catch (e) {
      debugPrint('Error stopping hybrid TTS: $e');
    }
  }

  @override
  Future<void> pause() async {
    try {
      if (_isPlayingAudio && _audioPlayer != null) {
        await _audioPlayer!.pause();
        _isPlayingAudio = false;
      }
      await _fallbackDeviceTts.pause();
    } catch (e) {
      debugPrint('Error pausing hybrid TTS: $e');
    }
  }

  @override
  Future<void> resume() async {
    try {
      if (_isInitialized && _audioPlayer != null) {
        await _audioPlayer!.resume();
        _isPlayingAudio = true;
      }
      await _fallbackDeviceTts.resume();
    } catch (e) {
      debugPrint('Error resuming hybrid TTS: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    _fallbackDeviceTts.dispose();
  }
}
