import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/tutor/domain/models/avatar_state.dart';
import 'package:lahjti/features/tutor/presentation/widgets/tutor_avatar_view.dart';

void main() {
  group('TutorAvatarView Widget Tests', () {
    testWidgets('1. Renders Abbas avatar in idle state without error', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: TutorAvatarView(
                state: AvatarState.idle,
                personaId: 'abbas',
                size: 140,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TutorAvatarView), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('2. Renders Dunya avatar in speaking state with sound level', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: TutorAvatarView(
                state: AvatarState.speaking,
                personaId: 'dunya',
                soundLevel: 0.75,
                size: 140,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TutorAvatarView), findsOneWidget);
    });

    testWidgets('3. Renders avatar in listening, thinking, and error states', (
      tester,
    ) async {
      for (final state in [
        AvatarState.listening,
        AvatarState.thinking,
        AvatarState.error,
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: TutorAvatarView(
                  state: state,
                  personaId: 'abbas',
                  size: 120,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(TutorAvatarView), findsOneWidget);
      }
    });
  });
}
