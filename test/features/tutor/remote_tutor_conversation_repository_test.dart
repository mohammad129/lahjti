import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/core/errors/exceptions.dart';
import 'package:lahjti/core/network/api_client.dart';
import 'package:lahjti/features/learning/domain/models/learner_context.dart';
import 'package:lahjti/features/tutor/data/repositories/remote_tutor_conversation_repository.dart';

class MockDioAdapter implements HttpClientAdapter {
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
    return ResponseBody.fromString('{}', 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('RemoteTutorConversationRepository Tests', () {
    late Dio dio;
    late MockDioAdapter mockAdapter;
    late ApiClient apiClient;
    late RemoteTutorConversationRepository repository;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api/v1'));
      mockAdapter = MockDioAdapter();
      dio.httpClientAdapter = mockAdapter;
      apiClient = ApiClient(dio);
      repository = RemoteTutorConversationRepository(apiClient);
    });

    test(
      '1. Successful conversation turn returns parsed VoiceMessage',
      () async {
        mockAdapter.handler = (options) {
          expect(options.path, '/tutor/conversation');
          return ResponseBody.fromString(
            '''
          {
            "tutorResponse": "Hey there! Tell me more about your day.",
            "correctedVersion": "I went yesterday.",
            "explanationArabic": "الفعل لازم يكون بالماضي",
            "detectedErrors": ["Past tense error"],
            "shouldCorrect": true,
            "encouragement": "أحسنت!",
            "nextDifficulty": "same"
          }
          ''',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        };

        final result = await repository.generateTutorResponse(
          userText: 'I go yesterday',
          targetLanguageCode: 'en',
          tutorId: 'abbas',
          history: const [],
        );

        expect(result.text, 'Hey there! Tell me more about your day.');
        expect(result.correctedAnswer, 'I went yesterday.');
        expect(result.explanationArabic, 'الفعل لازم يكون بالماضي');
        expect(result.shouldCorrect, isTrue);
        expect(result.encouragement, 'أحسنت!');
        expect(result.detectedErrors, contains('Past tense error'));
      },
    );

    test('2. LearnerContext payload is included and sent to backend', () async {
      mockAdapter.handler = (options) {
        final data = options.data as Map<String, dynamic>;
        expect(data['currentLessonTitle'], 'Ordering Coffee');
        expect(data['currentTopic'], 'Restaurant & Cafe');
        expect(data['targetVocabulary'], contains('coffee'));
        expect(data['recentWeaknesses'], contains('past_tense'));

        return ResponseBody.fromString(
          '''
          {
            "tutorResponse": "Would you like some coffee?",
            "correctedVersion": null,
            "explanationArabic": null,
            "detectedErrors": [],
            "shouldCorrect": false,
            "encouragement": "Good job!",
            "nextDifficulty": "same"
          }
          ''',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final result = await repository.generateTutorResponse(
        userText: 'I would like coffee',
        targetLanguageCode: 'en',
        tutorId: 'abbas',
        history: const [],
        learnerContext: const LearnerContext(
          currentLessonTitle: 'Ordering Coffee',
          currentTopic: 'Restaurant & Cafe',
          targetVocabulary: ['coffee', 'sugar', 'milk'],
          weaknesses: ['past_tense'],
        ),
      );

      expect(result.text, 'Would you like some coffee?');
    });

    test('3. Server error throws ServerException', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          '{"error": {"code": "SERVICE_UNAVAILABLE", "message": "Service unavailable"}}',
          503,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      expect(
        () => repository.generateTutorResponse(
          userText: 'Hello',
          targetLanguageCode: 'en',
          tutorId: 'abbas',
          history: const [],
        ),
        throwsA(isA<AppException>()),
      );
    });
  });
}
