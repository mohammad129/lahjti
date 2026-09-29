import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/learning/domain/models/learner_context.dart';
import 'package:lahjti/features/onboarding/domain/models/tutor_persona.dart';
import 'package:lahjti/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:lahjti/features/tutor/data/services/mock_speech_to_text_service.dart';
import 'package:lahjti/features/tutor/data/services/mock_text_to_speech_service.dart';
import 'package:lahjti/features/tutor/domain/models/voice_session_state.dart';
import 'package:lahjti/features/tutor/domain/repositories/tutor_conversation_repository.dart';
import 'package:lahjti/features/tutor/presentation/providers/voice_session_provider.dart';
import 'package:lahjti/features/tutor/presentation/screens/tutor_conversation_screen.dart';
import 'package:lahjti/features/tutor/presentation/widgets/tutor_avatar_view.dart';
import 'package:lahjti/l10n/app_localizations.dart';

class FakeWidgetRepo implements TutorConversationRepository {
  @override
  Future<VoiceMessage> generateTutorResponse({
    required String userText,
    required String targetLanguageCode,
    required String tutorId,
    required List<VoiceMessage> history,
    String nativeLanguage = 'arabic',
    String ageGroup = 'adult',
    String learningGoal = 'conversation',
    String difficulty = 'a1',
    bool isSessionStart = false,
    LearnerContext? learnerContext,
  }) async {
    return VoiceMessage(
      id: 'm1',
      isUser: false,
      text: 'Hello from tutor!',
      explanationArabic: 'مرحبًا بك!',
      shouldCorrect: false,
      encouragement: 'أهلاً وسهلاً!',
      nextDifficulty: 'same',
      timestamp: DateTime.now(),
    );
  }
}

Widget createTutorScreen({
  required TutorPersona tutor,
  required MockSpeechToTextService stt,
  required MockTextToSpeechService tts,
  Locale locale = const Locale('ar'),
}) {
  return ProviderScope(
    overrides: [
      speechToTextServiceProvider.overrideWithValue(stt),
      textToSpeechServiceProvider.overrideWithValue(tts),
      tutorConversationRepositoryProvider.overrideWithValue(FakeWidgetRepo()),
      onboardingProvider.overrideWith((ref) {
        final notifier = OnboardingNotifier();
        notifier.selectTutor(tutor.id);
        return notifier;
      }),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const TutorConversationScreen(),
    ),
  );
}

void main() {
  group('TutorConversationScreen Widget Tests', () {
    late MockSpeechToTextService mockStt;
    late MockTextToSpeechService mockTts;

    final abbasTutor = TutorPersona.tutors.firstWhere((t) => t.id == 'abbas');
    final dunyaTutor = TutorPersona.tutors.firstWhere((t) => t.id == 'dunya');

    setUp(() {
      mockStt = MockSpeechToTextService(autoFinalize: false);
      mockTts = MockTextToSpeechService();
    });

    testWidgets(
      '8. Screen renders Abbas persona and animated Avatar stage in Arabic',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          createTutorScreen(tutor: abbasTutor, stt: mockStt, tts: mockTts),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('عباس'), findsWidgets);
        expect(find.byType(TutorAvatarView), findsOneWidget);
        expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
      },
    );

    testWidgets('9. Screen renders Dunya persona and mic controls', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTutorScreen(
          tutor: dunyaTutor,
          stt: mockStt,
          tts: mockTts,
          locale: const Locale('en'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Dunya'), findsWidgets);
      expect(find.byType(TutorAvatarView), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    });

    testWidgets('10. Tapping microphone button activates listening state', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTutorScreen(tutor: abbasTutor, stt: mockStt, tts: mockTts),
      );
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byIcon(Icons.mic_rounded));
      await tester.pump(const Duration(milliseconds: 50));

      expect(mockStt.isListening, isTrue);
    });
  });
}
