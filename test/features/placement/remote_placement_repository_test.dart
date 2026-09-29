import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/core/errors/exceptions.dart';
import 'package:lahjti/core/network/api_client.dart';
import 'package:lahjti/features/onboarding/domain/models/age_group.dart';
import 'package:lahjti/features/onboarding/domain/models/learning_goal.dart';
import 'package:lahjti/features/onboarding/domain/models/native_language.dart';
import 'package:lahjti/features/onboarding/domain/models/supported_language.dart';
import 'package:lahjti/features/placement/data/providers/remote_language_evaluation_provider.dart';
import 'package:lahjti/features/placement/data/repositories/remote_placement_repository.dart';
import 'package:lahjti/features/placement/domain/models/cefr_level.dart';
import 'package:lahjti/features/placement/domain/models/placement_answer.dart';
import 'package:lahjti/features/placement/domain/models/placement_question.dart';
import 'package:lahjti/features/placement/domain/models/question_type.dart';

class FakeDio extends Fake implements Dio {
  Map<String, dynamic>? lastPostData;
  String? lastPostPath;
  Response<dynamic>? nextResponse;
  DioException? nextException;

  @override
  BaseOptions get options => BaseOptions();

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    lastPostPath = path;
    lastPostData = data as Map<String, dynamic>?;

    if (nextException != null) {
      throw nextException!;
    }

    return Response<T>(
      requestOptions:
          nextResponse?.requestOptions ?? RequestOptions(path: path),
      statusCode: nextResponse?.statusCode ?? 200,
      data: nextResponse?.data as T?,
    );
  }
}

void main() {
  late FakeDio fakeDio;
  late ApiClient apiClient;
  late RemotePlacementRepository repository;
  late RemoteLanguageEvaluationProvider remoteProvider;

  const testLanguage = SupportedLanguage(
    id: 'en',
    nameEn: 'English',
    nameAr: 'الإنجليزية',
    flagEmoji: '🇬🇧',
  );

  const testGoal = LearningGoal(id: 'conversation', icon: '🗣️');

  final testQuestion = const PlacementQuestion(
    id: 'q_test_01',
    type: QuestionType.comprehension,
    targetLanguage: 'en',
    difficulty: CefrLevel.a1,
    prompt: 'Where are you from?',
    promptArabic: 'من وين أنت؟',
  );

  final testAnswer = PlacementAnswer(
    questionId: 'q_test_01',
    userResponse: 'I am from Jordan.',
    responseDuration: const Duration(seconds: 4),
    skipped: false,
    submittedAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    fakeDio = FakeDio();
    apiClient = ApiClient(fakeDio);
    repository = RemotePlacementRepository(apiClient);
    remoteProvider = RemoteLanguageEvaluationProvider(repository);
  });

  group('RemotePlacementRepository & RemoteLanguageEvaluationProvider Tests', () {
    test(
      '18. Repository formats request payload and sends to /placement/evaluate',
      () async {
        fakeDio.nextResponse = Response(
          requestOptions: RequestOptions(path: '/placement/evaluate'),
          statusCode: 200,
          data: {
            'semanticScore': 90,
            'grammarScore': 85,
            'vocabularyScore': 88,
            'comprehensionScore': 92,
            'fluencyScore': 80,
            'pronunciationScore': null,
            'confidence': 0.95,
            'detectedErrors': [],
            'correctedAnswer': 'I am from Jordan.',
            'explanationArabic': 'ممتاز ومفهوم 👏',
            'wasUnderstandable': true,
            'difficultyRecommendation': 'increase',
          },
        );

        final evaluation = await remoteProvider.evaluate(
          targetLanguage: testLanguage,
          nativeLanguage: NativeLanguage.arabic,
          ageGroup: AgeGroup.age26_35,
          learningGoal: testGoal,
          question: testQuestion,
          answer: testAnswer,
        );

        expect(fakeDio.lastPostPath, '/placement/evaluate');
        expect(fakeDio.lastPostData?['targetLanguage'], 'en');
        expect(fakeDio.lastPostData?['nativeLanguage'], 'ar');
        expect(fakeDio.lastPostData?['ageGroup'], 'age26_35');
        expect(fakeDio.lastPostData?['learningGoal'], 'conversation');
        expect(fakeDio.lastPostData?['difficulty'], 'a1');
        expect(fakeDio.lastPostData?['response'], 'I am from Jordan.');
        expect(fakeDio.lastPostData?['responseDurationMs'], 4000);
        expect(fakeDio.lastPostData?['skipped'], false);

        expect(evaluation.semanticScore, 90);
        expect(evaluation.pronunciationScore, isNull);
        expect(evaluation.wasUnderstandable, isTrue);
        expect(evaluation.shouldIncreaseDifficulty, isTrue);
      },
    );

    test(
      '19. Backend response deserializes properly into PlacementEvaluation model',
      () async {
        fakeDio.nextResponse = Response(
          requestOptions: RequestOptions(path: '/placement/evaluate'),
          statusCode: 200,
          data: {
            'semanticScore': 60,
            'grammarScore': 50,
            'vocabularyScore': 55,
            'comprehensionScore': 60,
            'fluencyScore': 40,
            'pronunciationScore': null,
            'confidence': 0.88,
            'detectedErrors': ['verb tense'],
            'correctedAnswer': 'I went yesterday.',
            'explanationArabic': 'الفعل لازم يكون بالماضي.',
            'wasUnderstandable': true,
            'difficultyRecommendation': 'same',
          },
        );

        final evaluation = await repository.evaluateAnswer(
          targetLanguage: testLanguage,
          nativeLanguage: NativeLanguage.arabic,
          ageGroup: AgeGroup.age26_35,
          learningGoal: testGoal,
          difficulty: CefrLevel.a1,
          question: testQuestion,
          answer: testAnswer,
        );

        expect(evaluation.semanticScore, 60);
        expect(evaluation.grammarScore, 50);
        expect(evaluation.pronunciationScore, isNull);
        expect(evaluation.explanationArabic, contains('الماضي'));
        expect(evaluation.shouldIncreaseDifficulty, isFalse);
        expect(evaluation.shouldDecreaseDifficulty, isFalse);
      },
    );

    test('20. Backend network failure throws AppException', () async {
      fakeDio.nextException = DioException(
        requestOptions: RequestOptions(path: '/placement/evaluate'),
        type: DioExceptionType.connectionTimeout,
        error: const NetworkException(
          message: 'Connection timed out',
          errorType: NetworkErrorType.connectionTimeout,
        ),
      );

      expect(
        () => repository.evaluateAnswer(
          targetLanguage: testLanguage,
          nativeLanguage: NativeLanguage.arabic,
          ageGroup: AgeGroup.age26_35,
          learningGoal: testGoal,
          difficulty: CefrLevel.a1,
          question: testQuestion,
          answer: testAnswer,
        ),
        throwsA(isA<AppException>()),
      );
    });
  });
}
