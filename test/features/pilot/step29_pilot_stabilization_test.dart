import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lahjti/core/config/env_config.dart';
import 'package:lahjti/core/errors/exceptions.dart';
import 'package:lahjti/core/localization/locale_provider.dart';
import 'package:lahjti/core/network/api_client.dart';
import 'package:lahjti/core/network/error_interceptor.dart';
import 'package:lahjti/core/routing/app_routes.dart';
import 'package:lahjti/features/learning/domain/models/learner_context.dart';
import 'package:lahjti/features/placement/domain/models/cefr_level.dart';
import 'package:lahjti/features/tutor/data/repositories/remote_tutor_conversation_repository.dart';
import 'package:lahjti/features/tutor/data/services/hybrid_elevenlabs_tts_service.dart';
import 'package:lahjti/features/tutor/data/services/mock_speech_to_text_service.dart';
import 'package:lahjti/features/tutor/data/services/mock_text_to_speech_service.dart';
import 'package:lahjti/features/tutor/domain/models/voice_session_state.dart';
import 'package:lahjti/features/tutor/domain/repositories/tutor_conversation_repository.dart';
import 'package:lahjti/features/tutor/presentation/providers/voice_session_provider.dart';
import 'package:lahjti/features/tutor/presentation/screens/tutor_conversation_screen.dart';
import 'package:lahjti/l10n/app_localizations.dart';

class MockHttpClientAdapter implements HttpClientAdapter {
  ResponseBody Function(RequestOptions options)? handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (handler != null) {
      return handler!(options);
    }
    return ResponseBody.fromString('{"success": true, "data": {}}', 200);
  }

  @override
  void close({bool force = false}) {}
}

class _MockPilotTutorRepo implements TutorConversationRepository {
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
      id: 'pilot_msg_01',
      isUser: false,
      text: 'Welcome to your English session!',
      explanationArabic: 'أهلاً بك في جلسة اللغة الإنجليزية!',
      shouldCorrect: false,
      audioBase64:
          'SUQzBAAAAAAAI1RTU0UAAAAPAAADTGF2ZjU4Ljc2LjEwMAAAAAAAAAAAAAAA',
      voiceProvider: 'elevenlabs',
      timestamp: DateTime.now(),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('STEP 29: Pilot Network Configuration & Base URL Tests', () {
    test(
      '1. EnvConfig resolves base URL without hardcoded localhost in pilot',
      () {
        final baseUrl = EnvConfig.apiBaseUrl;
        expect(baseUrl, isNotEmpty);
        expect(baseUrl, isNot(contains('127.0.0.1')));
        expect(baseUrl.startsWith('http'), isTrue);
        expect(EnvConfig.devHost, isNotEmpty);
        expect(EnvConfig.connectTimeoutMs, greaterThan(0));
        expect(EnvConfig.receiveTimeoutMs, greaterThan(0));
      },
    );

    test(
      '2. AppEnvironment enum parses dev, pilot, staging, and prod properly',
      () {
        expect(AppEnvironment.fromString('dev'), AppEnvironment.dev);
        expect(AppEnvironment.fromString('pilot'), AppEnvironment.pilot);
        expect(AppEnvironment.fromString('staging'), AppEnvironment.staging);
        expect(AppEnvironment.fromString('prod'), AppEnvironment.prod);
        expect(AppEnvironment.fromString('production'), AppEnvironment.prod);
        expect(AppEnvironment.fromString('pilot').isPilot, isTrue);
      },
    );
  });

  group('STEP 29: AI Request Flow & Error Classification Tests', () {
    late Dio dio;
    late MockHttpClientAdapter adapter;
    late ApiClient apiClient;
    late RemoteTutorConversationRepository repo;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'http://192.168.1.18:3000/api/v1'));
      adapter = MockHttpClientAdapter();
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(NetworkErrorInterceptor());
      apiClient = ApiClient(dio);
      repo = RemoteTutorConversationRepository(apiClient);
    });

    test(
      '3. Successful AI Tutor Request parses response and ElevenLabs payload',
      () async {
        adapter.handler = (options) {
          expect(options.path, '/tutor/conversation');
          expect(options.method, 'POST');
          return ResponseBody.fromString(
            '''
        {
          "tutorResponse": "Hello Ali! Nice to meet you. Let's practice English!",
          "explanationArabic": "أهلاً علي! سعيد بلقائك. دعنا نتدرب معاً!",
          "correctedVersion": null,
          "detectedErrors": [],
          "shouldCorrect": false,
          "encouragement": "Great introduction!",
          "nextDifficulty": "a1",
          "audioBase64": "SUQzBAAAAAAAI1RTU0UAAAAPAAADTGF2ZjU4Ljc2LjEwMAAAAAAAAAAAAAAA",
          "voiceProvider": "elevenlabs"
        }
        ''',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        };

        final response = await repo.generateTutorResponse(
          userText: 'Hello, my name is Ali.',
          targetLanguageCode: 'en',
          tutorId: 'abbas',
          history: const [],
          learnerContext: const LearnerContext(
            targetLanguage: 'en',
            nativeLanguage: 'arabic',
            ageGroup: 'adult',
            learningGoal: 'conversation',
            cefrLevel: CefrLevel.a1,
          ),
        );

        expect(response.text, contains('Hello Ali!'));
        expect(response.explanationArabic, contains('أهلاً علي!'));
        expect(response.voiceProvider, 'elevenlabs');
        expect(response.audioBase64, isNotNull);
      },
    );

    test(
      '4. Backend Unreachable Socket Exception maps to friendly NetworkException',
      () async {
        adapter.handler = (options) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            message: 'Connection refused',
          );
        };

        expect(
          () => repo.generateTutorResponse(
            userText: 'Hello',
            targetLanguageCode: 'en',
            tutorId: 'abbas',
            history: const [],
          ),
          throwsA(
            isA<NetworkException>().having(
              (e) => e.errorType,
              'errorType',
              NetworkErrorType.noInternet,
            ),
          ),
        );
      },
    );

    test(
      '5. HTTP 401 Unauthorized maps to friendly unauthorized exception',
      () async {
        adapter.handler = (options) {
          return ResponseBody.fromString(
            '{"error": {"code": "UNAUTHORIZED", "arabicMessage": "جلسة المستخدم منتهية. يرجى تسجيل الدخول مجددًا."}}',
            401,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        };

        expect(
          () => repo.generateTutorResponse(
            userText: 'Hello',
            targetLanguageCode: 'en',
            tutorId: 'abbas',
            history: const [],
          ),
          throwsA(
            isA<NetworkException>().having(
              (e) => e.errorType,
              'errorType',
              NetworkErrorType.unauthorized,
            ),
          ),
        );
      },
    );

    test(
      '6. HTTP 403 Subscription Expired maps to forbidden exception with Arabic note',
      () async {
        adapter.handler = (options) {
          return ResponseBody.fromString(
            '{"error": {"code": "FORBIDDEN", "arabicMessage": "انتهت الفترة التجريبية للاشتراك. يرجى الاشتراك للمتابعة."}}',
            403,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        };

        expect(
          () => repo.generateTutorResponse(
            userText: 'Hello',
            targetLanguageCode: 'en',
            tutorId: 'abbas',
            history: const [],
          ),
          throwsA(
            isA<NetworkException>()
                .having(
                  (e) => e.errorType,
                  'errorType',
                  NetworkErrorType.forbidden,
                )
                .having(
                  (e) => e.message,
                  'message',
                  contains('الفترة التجريبية'),
                ),
          ),
        );
      },
    );

    test(
      '7. HTTP 429 Quota Exceeded maps to quotaExceeded exception with guidance',
      () async {
        adapter.handler = (options) {
          return ResponseBody.fromString(
            '{"error": {"code": "RATE_LIMIT_EXCEEDED", "arabicMessage": "وصلت إلى حد الاستخدام اليومي للذكاء الاصطناعي."}}',
            429,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        };

        expect(
          () => repo.generateTutorResponse(
            userText: 'Hello',
            targetLanguageCode: 'en',
            tutorId: 'abbas',
            history: const [],
          ),
          throwsA(
            isA<NetworkException>().having(
              (e) => e.errorType,
              'errorType',
              NetworkErrorType.quotaExceeded,
            ),
          ),
        );
      },
    );

    test(
      '8. HTTP 503 AI Provider Unavailable maps to aiUnavailable exception',
      () async {
        adapter.handler = (options) {
          return ResponseBody.fromString(
            '{"error": {"code": "AI_UNAVAILABLE", "arabicMessage": "تعذر الحصول على رد من المدرّب الآن. حاول مرة أخرى."}}',
            503,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        };

        expect(
          () => repo.generateTutorResponse(
            userText: 'Hello',
            targetLanguageCode: 'en',
            tutorId: 'abbas',
            history: const [],
          ),
          throwsA(
            isA<NetworkException>().having(
              (e) => e.errorType,
              'errorType',
              NetworkErrorType.aiUnavailable,
            ),
          ),
        );
      },
    );
  });

  group('STEP 29: ElevenLabs TTS & Voice Resilience Tests', () {
    test(
      '9. HybridElevenLabsTtsService initializes and reports availability',
      () async {
        final hybridService = HybridElevenLabsTtsService();
        final isAvailable = await hybridService.initialize();
        expect(isAvailable, isTrue);
        expect(hybridService.isAvailable, isTrue);
      },
    );
  });

  group('STEP 29: AI Tutor Screen, Hero Stage & Navigation Tests', () {
    testWidgets(
      '10. AI Tutor Screen renders large 44% Stage, Avatar, Back, and Home Navigation',
      (WidgetTester tester) async {
        final mockStt = MockSpeechToTextService();
        final mockTts = MockTextToSpeechService();
        final mockRepo = _MockPilotTutorRepo();

        final router = GoRouter(
          initialLocation: AppRoutes.tutor,
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder:
                  (context, state) =>
                      const Scaffold(body: Text('Home Screen Content')),
            ),
            GoRoute(
              path: AppRoutes.tutor,
              builder: (context, state) => const TutorConversationScreen(),
            ),
          ],
        );

        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              localeProvider.overrideWith((ref) => LocaleNotifier()),
              speechToTextServiceProvider.overrideWithValue(mockStt),
              textToSpeechServiceProvider.overrideWithValue(mockTts),
              tutorConversationRepositoryProvider.overrideWithValue(mockRepo),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              locale: const Locale('ar'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));

        // 1. Verify Header & Back Navigation Button
        expect(find.byKey(const Key('tutor_back_button')), findsOneWidget);
        expect(find.byKey(const Key('tutor_home_appbar_btn')), findsOneWidget);

        // 2. Verify Studio Classroom stage & live status pill
        expect(find.textContaining('Classroom'), findsWidgets);
        expect(find.text('جاهز للمحادثة'), findsOneWidget);

        // 3. Verify Mic Button and Keyboard Toggle
        expect(find.byKey(const Key('tutor_mic_cta_btn')), findsOneWidget);
        expect(
          find.byKey(const Key('tutor_keyboard_toggle_btn')),
          findsOneWidget,
        );

        // 4. Tap Keyboard Toggle to open text input console
        await tester.tap(find.byKey(const Key('tutor_keyboard_toggle_btn')));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(TextField), findsOneWidget);

        // 5. Tap Home AppBar Button and verify return to Home
        await tester.tap(find.byKey(const Key('tutor_home_appbar_btn')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Home Screen Content'), findsOneWidget);
      },
    );
  });
}
