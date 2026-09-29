import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/avatar_state.dart';
import '../../domain/models/voice_session_state.dart';
import 'voice_session_provider.dart';

/// Maps the active [VoiceSessionState] directly into the appropriate [AvatarState].
final avatarStateProvider = Provider.autoDispose<AvatarState>((ref) {
  final voiceState = ref.watch(voiceSessionNotifierProvider);

  if (voiceState.errorMessage != null &&
      voiceState.status == VoiceSessionStatus.error) {
    return AvatarState.error;
  }

  switch (voiceState.status) {
    case VoiceSessionStatus.speaking:
      return AvatarState.speaking;
    case VoiceSessionStatus.listening:
      return AvatarState.listening;
    case VoiceSessionStatus.processing:
    case VoiceSessionStatus.requestingPermission:
      return AvatarState.thinking;
    case VoiceSessionStatus.error:
      return AvatarState.error;
    case VoiceSessionStatus.idle:
    case VoiceSessionStatus.ready:
    case VoiceSessionStatus.paused:
      return AvatarState.idle;
  }
});

/// Exposes the live sound level for avatar audio reaction (0.0 to 1.0).
final avatarSoundLevelProvider = Provider.autoDispose<double>((ref) {
  return ref.watch(voiceSessionNotifierProvider.select((s) => s.soundLevel));
});
