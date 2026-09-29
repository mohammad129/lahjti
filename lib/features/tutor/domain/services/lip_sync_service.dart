import '../models/avatar_state.dart';

/// Abstract service contract for phoneme-level lip synchronization and viseme processing.
///
/// In this Step (Step 7), local procedural speech animation is implemented at $0 cost.
/// This contract standardizes the future integration point for cloud viseme / phoneme
/// streaming providers (such as HeyGen, D-ID, Simli, or local ONNX neural models).
abstract class LipSyncService {
  /// Initializes the lip-sync engine.
  Future<bool> initialize();

  /// Feeds raw audio buffer or viseme cues for phoneme alignment.
  Future<void> feedSpeechData({
    required String text,
    required String languageCode,
    List<VisemeData>? precomputedVisemes,
  });

  /// Subscribes to real-time viseme / blendshape frames during speech playback.
  Stream<LipSyncFrame> get frameStream;

  /// Stops current lip-sync playback.
  Future<void> stop();

  /// Releases resources.
  void dispose();
}
