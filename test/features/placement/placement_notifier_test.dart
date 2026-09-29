import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahjti/features/onboarding/domain/models/age_group.dart';
import 'package:lahjti/features/onboarding/domain/models/experience_level.dart';
import 'package:lahjti/features/onboarding/domain/models/learning_goal.dart';
import 'package:lahjti/features/onboarding/domain/models/native_language.dart';
import 'package:lahjti/features/onboarding/domain/models/onboarding_data.dart';
import 'package:lahjti/features/onboarding/domain/models/supported_language.dart';
import 'package:lahjti/features/placement/data/providers/mock_language_evaluation_provider.dart';
import 'package:lahjti/features/placement/data/providers/mock_placement_content_provider.dart';
import 'package:lahjti/features/placement/domain/providers/placement_engine.dart';
import 'package:lahjti/features/placement/presentation/providers/placement_provider.dart';

void main() {
  group('PlacementNotifier Tests', () {
    late ProviderContainer container;

    final testData = OnboardingData(
      targetLanguage: const SupportedLanguage(
        id: 'es',
        nameEn: 'Spanish',
        nameAr: 'الإسبانية',
        flagEmoji: '🇪🇸',
      ),
      nativeLanguage: NativeLanguage.arabic,
      ageGroup: AgeGroup.age26_35,
      learningGoal: const LearningGoal(id: 'travel', icon: '✈️'),
      experienceLevel: ExperienceLevel.basic,
      selectedTutorId: 'abbas',
      registeredUserId: 'user_789',
    );

    setUp(() {
      container = ProviderContainer(
        overrides: [
          placementContentProvider.overrideWithValue(
            const MockPlacementContentProvider(),
          ),
          languageEvaluationProvider.overrideWithValue(
            const MockLanguageEvaluationProvider(
              shouldSimulateNetworkDelay: false,
            ),
          ),
          placementEngineProvider.overrideWithValue(
            const PlacementEngine(
              config: PlacementEngineConfig(minQuestions: 2, maxQuestions: 4),
            ),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
      '1. Placement session initializes with user context parameters',
      () async {
        final notifier = container.read(placementNotifierProvider.notifier);
        await notifier.startSession(testData);

        final state = container.read(placementNotifierProvider);
        expect(state.status, PlacementStatus.questionReady);
        expect(state.session, isNotNull);
        expect(state.session!.targetLanguage.id, 'es');
        expect(state.session!.ageGroup, AgeGroup.age26_35);
        expect(state.session!.learningGoal.id, 'travel');
        expect(state.currentQuestion, isNotNull);
        expect(state.currentQuestion!.targetLanguage, 'es');
      },
    );

    test(
      '9. Skip / "مش عارف" records skipped answer and adapts difficulty',
      () async {
        final notifier = container.read(placementNotifierProvider.notifier);
        await notifier.startSession(testData);

        await notifier.submitAnswer(response: '', isSkipped: true);

        final state = container.read(placementNotifierProvider);
        expect(state.session!.answers.first.skipped, isTrue);
        expect(state.lastEvaluation, isNotNull);
        expect(state.lastEvaluation!.wasUnderstandable, isFalse);
      },
    );

    test(
      '15. Provider failure shows recoverable error without losing session',
      () async {
        final notifier = container.read(placementNotifierProvider.notifier);
        await notifier.startSession(testData);

        // Submit error simulation keyword
        await notifier.submitAnswer(response: '__SIMULATE_ERROR__');

        final state = container.read(placementNotifierProvider);
        expect(state.status, PlacementStatus.error);
        expect(state.errorMessage, isNotNull);
        expect(state.session, isNotNull); // Session is preserved
      },
    );

    test('16. Duplicate submission is prevented while evaluating', () async {
      final notifier = container.read(placementNotifierProvider.notifier);
      await notifier.startSession(testData);

      // Fire 2 submits simultaneously
      final future1 = notifier.submitAnswer(response: 'Hola');
      final future2 = notifier.submitAnswer(response: 'Hola again');

      await Future.wait([future1, future2]);

      final state = container.read(placementNotifierProvider);
      // Only 1 answer should be recorded
      expect(state.session!.answers.length, 1);
    });
  });
}
