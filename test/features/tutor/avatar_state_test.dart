import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/onboarding/domain/models/tutor_persona.dart';
import 'package:lahjti/features/tutor/domain/models/avatar_state.dart';
import 'package:lahjti/features/tutor/domain/models/voice_session_state.dart';
import 'package:lahjti/features/tutor/presentation/providers/avatar_state_provider.dart';
import 'package:lahjti/features/tutor/presentation/providers/voice_session_provider.dart';

void main() {
  group('Avatar Domain & State Tests', () {
    test('1. AvatarVisualProfile correctly maps Abbas and Dunya personas', () {
      final abbasPersona = TutorPersona.tutors.firstWhere(
        (t) => t.id == 'abbas',
      );
      final dunyaPersona = TutorPersona.tutors.firstWhere(
        (t) => t.id == 'dunya',
      );

      final abbasProfile = AvatarVisualProfile.fromPersona(abbasPersona);
      expect(abbasProfile.id, 'abbas');
      expect(abbasProfile.gender, 'male');
      expect(abbasProfile.nameArabic, 'عباس');

      final dunyaProfile = AvatarVisualProfile.fromPersona(dunyaPersona);
      expect(dunyaProfile.id, 'dunya');
      expect(dunyaProfile.gender, 'female');
      expect(dunyaProfile.nameArabic, 'دنيا');
    });

    test(
      '2. VisemeData and LipSyncFrame serialize correctly for future cloud sync',
      () {
        const viseme = VisemeData(
          visemeId: 4,
          timeOffsetMs: 120,
          durationMs: 80,
          weight: 0.95,
        );

        final json = viseme.toJson();
        expect(json['visemeId'], 4);
        expect(json['timeOffsetMs'], 120);
        expect(json['durationMs'], 80);
        expect(json['weight'], 0.95);

        const frame = LipSyncFrame(
          timestampMs: 250,
          mouthOpenness: 0.8,
          mouthWidth: 0.2,
          jawDrop: 0.6,
        );
        expect(frame.timestampMs, 250);
        expect(frame.mouthOpenness, 0.8);
        expect(frame.jawDrop, 0.6);
      },
    );

    test(
      '3. avatarStateProvider maps speaking status to AvatarState.speaking',
      () {
        final container = ProviderContainer(
          overrides: [
            voiceSessionNotifierProvider.overrideWith((ref) {
              return _FakeNotifier(
                VoiceSessionState(
                  status: VoiceSessionStatus.speaking,
                  tutor: TutorPersona.tutors.first,
                ),
              );
            }),
          ],
        );
        addTearDown(container.dispose);

        expect(container.read(avatarStateProvider), AvatarState.speaking);
      },
    );

    test(
      '4. avatarStateProvider maps listening status to AvatarState.listening',
      () {
        final container = ProviderContainer(
          overrides: [
            voiceSessionNotifierProvider.overrideWith((ref) {
              return _FakeNotifier(
                VoiceSessionState(
                  status: VoiceSessionStatus.listening,
                  tutor: TutorPersona.tutors.first,
                ),
              );
            }),
          ],
        );
        addTearDown(container.dispose);

        expect(container.read(avatarStateProvider), AvatarState.listening);
      },
    );

    test(
      '5. avatarStateProvider maps processing status to AvatarState.thinking',
      () {
        final container = ProviderContainer(
          overrides: [
            voiceSessionNotifierProvider.overrideWith((ref) {
              return _FakeNotifier(
                VoiceSessionState(
                  status: VoiceSessionStatus.processing,
                  tutor: TutorPersona.tutors.first,
                ),
              );
            }),
          ],
        );
        addTearDown(container.dispose);

        expect(container.read(avatarStateProvider), AvatarState.thinking);
      },
    );

    test('6. avatarStateProvider maps ready status to AvatarState.idle', () {
      final container = ProviderContainer(
        overrides: [
          voiceSessionNotifierProvider.overrideWith((ref) {
            return _FakeNotifier(
              VoiceSessionState(
                status: VoiceSessionStatus.ready,
                tutor: TutorPersona.tutors.first,
              ),
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(avatarStateProvider), AvatarState.idle);
    });

    test('7. avatarStateProvider maps error status to AvatarState.error', () {
      final container = ProviderContainer(
        overrides: [
          voiceSessionNotifierProvider.overrideWith((ref) {
            return _FakeNotifier(
              VoiceSessionState(
                status: VoiceSessionStatus.error,
                errorMessage: 'Mic error',
                tutor: TutorPersona.tutors.first,
              ),
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(avatarStateProvider), AvatarState.error);
    });
  });
}

class _FakeNotifier extends StateNotifier<VoiceSessionState>
    implements VoiceSessionNotifier {
  _FakeNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
