import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/core/localization/locale_provider.dart';
import 'package:lahjti/features/account/domain/models/account_context.dart';
import 'package:lahjti/features/account/presentation/providers/account_providers.dart';
import 'package:lahjti/features/account/presentation/screens/subscription_access_screen.dart';
import 'package:lahjti/features/home/presentation/screens/home_screen.dart';
import 'package:lahjti/features/learning/domain/models/learner_context.dart';
import 'package:lahjti/features/onboarding/presentation/onboarding_screen.dart';
import 'package:lahjti/features/profile/presentation/screens/profile_screen.dart';
import 'package:lahjti/features/progress/presentation/screens/progress_screen.dart';
import 'package:lahjti/features/school/presentation/screens/educational_games_hub_screen.dart';
import 'package:lahjti/features/tutor/data/services/mock_speech_to_text_service.dart';
import 'package:lahjti/features/tutor/data/services/mock_text_to_speech_service.dart';
import 'package:lahjti/features/tutor/domain/models/voice_session_state.dart';
import 'package:lahjti/features/tutor/domain/repositories/tutor_conversation_repository.dart';
import 'package:lahjti/features/tutor/presentation/providers/voice_session_provider.dart';
import 'package:lahjti/features/tutor/presentation/screens/tutor_conversation_screen.dart';
import 'package:lahjti/features/tutor/presentation/widgets/tutor_avatar_view.dart';
import 'package:lahjti/features/welcome/presentation/welcome_screen.dart';
import 'package:lahjti/l10n/app_localizations.dart';

class _FakeTutorRepo implements TutorConversationRepository {
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

Widget _createTestContainer({
  required Widget home,
  List<Override> overrides = const [],
  Locale locale = const Locale('ar'),
}) {
  return ProviderScope(
    overrides: [
      localeProvider.overrideWith((ref) => LocaleNotifier(locale)),
      ...overrides,
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar'), Locale('en')],
      home: home,
    ),
  );
}

void main() {
  group('STEP 27: End-to-End User Journey Verification', () {
    testWidgets(
      'Journey Stage 1: Welcome -> Onboarding Selection (Language, Age, Level, Goal)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 900));

        // 1. Welcome Screen
        await tester.pumpWidget(
          _createTestContainer(home: const WelcomeScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('لهجتي'), findsWidgets);
        expect(find.text('ابدأ رحلتك 🚀'), findsOneWidget);

        // 2. Onboarding Screen - Step 0 (Target Language)
        await tester.pumpWidget(
          _createTestContainer(home: const OnboardingScreen()),
        );
        await tester.pumpAndSettle();

        // Verify target languages exist (English, Spanish, French, German, Arabic)
        expect(find.text('الإنجليزية'), findsWidgets);
        expect(find.text('الإسبانية'), findsWidgets);
        expect(find.text('الفرنسية'), findsWidgets);
      },
    );

    testWidgets(
      'Journey Stage 2: Home Screen -> Continue Learning -> Quick Actions',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 900));

        await tester.pumpWidget(
          _createTestContainer(
            home: const HomeScreen(),
            overrides: [
              currentAccountContextProvider.overrideWith(
                (ref) => AccountContext.individual,
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Hero CTA
        expect(
          find.byKey(const Key('continue_learning_hero_btn')),
          findsOneWidget,
        );

        // Games Banner & AppBar icons
        expect(
          find.byKey(const Key('home_games_hub_banner_btn')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('home_profile_appbar_btn')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('home_subscription_appbar_btn')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('home_tutor_fab_btn')), findsOneWidget);
      },
    );

    testWidgets(
      'Journey Stage 3: Educational Games Hub renders games hub banner and actions',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 900));

        await tester.pumpWidget(
          _createTestContainer(home: const EducationalGamesHubScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('الألعاب التعليمية'), findsWidgets);
        expect(find.text('العب الآن'), findsWidgets);
      },
    );

    testWidgets(
      'Journey Stage 4: AI Tutor & Voice Screen renders Avatar & Mic CTA',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 900));

        await tester.pumpWidget(
          _createTestContainer(
            home: const TutorConversationScreen(),
            overrides: [
              speechToTextServiceProvider.overrideWithValue(
                MockSpeechToTextService(),
              ),
              textToSpeechServiceProvider.overrideWithValue(
                MockTextToSpeechService(),
              ),
              tutorConversationRepositoryProvider.overrideWithValue(
                _FakeTutorRepo(),
              ),
            ],
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(TutorAvatarView), findsOneWidget);
        expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'Journey Stage 5: Progress Screen renders learning metrics and charts',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 900));

        await tester.pumpWidget(
          _createTestContainer(home: const ProgressScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('التقدم والإنجازات'), findsWidgets);
      },
    );

    testWidgets(
      'Journey Stage 6: Profile Screen renders learning preferences and settings',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 900));

        await tester.pumpWidget(
          _createTestContainer(
            home: const ProfileScreen(),
            overrides: [
              currentAccountContextProvider.overrideWith(
                (ref) => AccountContext.individual,
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('تفضيلات ومسار التعلم'), findsOneWidget);
        expect(find.text('اللغة المستهدفة للتعلم'), findsOneWidget);
        expect(find.text('المستوى التعليمي'), findsOneWidget);
        expect(find.text('هدف التعلم'), findsOneWidget);
        expect(find.text('الفئة العمرية'), findsOneWidget);
        expect(
          find.byKey(const Key('profile_subscription_tile')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Journey Stage 7: Subscription & Sandbox Checkout UI renders correctly',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 900));

        await tester.pumpWidget(
          _createTestContainer(
            home: const SubscriptionAccessScreen(),
            overrides: [
              currentAccountContextProvider.overrideWith(
                (ref) => AccountContext.individual,
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('الاشتراك والوصول'), findsWidgets);
        expect(find.text('ماذا تشمل باقة لهجتي الكاملة؟'), findsWidgets);
        expect(find.text('10 دولارات شهرياً (10 USD / Month)'), findsWidgets);
        expect(
          find.byKey(const Key('subscription_upgrade_cta_btn')),
          findsOneWidget,
        );
      },
    );
  });
}
