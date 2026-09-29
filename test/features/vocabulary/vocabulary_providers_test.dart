import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/learning/data/repositories/local_learning_repository.dart';
import 'package:lahjti/features/learning/presentation/providers/learning_providers.dart';
import 'package:lahjti/features/onboarding/domain/models/age_group.dart';
import 'package:lahjti/features/vocabulary/presentation/providers/vocabulary_providers.dart';

void main() {
  group('Vocabulary Providers Tests', () {
    late ProviderContainer container;
    late LocalLearningRepository repo;

    setUp(() {
      repo = LocalLearningRepository();
      container = ProviderContainer(
        overrides: [learningRepositoryProvider.overrideWithValue(repo)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
      '1. VocabularyExplorerNotifier loads and filters items by category and status',
      () async {
        final notifier = container.read(
          vocabularyExplorerNotifierProvider.notifier,
        );
        await notifier.loadVocabulary();

        final state = container.read(vocabularyExplorerNotifierProvider);
        expect(state.allItems, isNotEmpty);
        expect(state.availableCategories.contains('All'), isTrue);
        expect(state.availableCategories.contains('Greetings'), isTrue);

        // Filter by category
        notifier.selectCategory('Greetings');
        final filteredByCategory =
            container.read(vocabularyExplorerNotifierProvider).filteredItems;
        for (final item in filteredByCategory) {
          expect(item.category, 'Greetings');
        }

        // Filter by search query
        notifier.selectCategory('All');
        notifier.setSearchQuery('hello');
        final searchResults =
            container.read(vocabularyExplorerNotifierProvider).filteredItems;
        expect(
          searchResults.any((i) => i.term.toLowerCase().contains('hello')),
          isTrue,
        );
      },
    );

    test(
      '2. DailyVocabularyGoal adapts target count to learner CEFR level',
      () {
        final goal = container.read(dailyVocabularyGoalProvider);
        // Default profile is A1 -> target should be 6
        expect(goal.targetCount, 6);
        expect(goal.progressRatio, inInclusiveRange(0.0, 1.0));
      },
    );

    test(
      '3. VocabularyPracticeNotifier drives session and updates spaced repetition intervals',
      () async {
        final explorerNotifier = container.read(
          vocabularyExplorerNotifierProvider.notifier,
        );
        await explorerNotifier.loadVocabulary();

        final practiceNotifier = container.read(
          vocabularyPracticeNotifierProvider.notifier,
        );

        practiceNotifier.startSession();
        var session = container.read(vocabularyPracticeNotifierProvider);
        expect(session.questions, isNotEmpty);
        expect(session.currentIndex, 0);

        final currentQ = session.currentQuestion!;
        final correctIdx = currentQ.correctOptionIndex;

        // Select correct answer and submit
        practiceNotifier.selectOption(correctIdx);
        await practiceNotifier.submitAnswer();

        session = container.read(vocabularyPracticeNotifierProvider);
        expect(session.isAnswerSubmitted, isTrue);
        expect(session.results.length, 1);
        expect(session.results.first.isCorrect, isTrue);

        // Verify item updated in repository with advanced streak
        final updatedList = await repo.getVocabularyList('usr_active');
        final updatedItem = updatedList.firstWhere(
          (i) => i.id == currentQ.targetItem.id,
        );
        expect(
          updatedItem.correctStreak,
          currentQ.targetItem.correctStreak + 1,
        );
      },
    );

    test('4. AgeAdaptiveUiConfig provides age-appropriate metrics', () {
      final childConfig = AgeAdaptiveUiConfig.fromAgeGroup(AgeGroup.age6_10);
      expect(childConfig.textScaleFactor, 1.2);
      expect(childConfig.minTouchTargetHeight, 56.0);
      expect(childConfig.enableSimplifiedLayout, isTrue);

      final adultConfig = AgeAdaptiveUiConfig.fromAgeGroup(AgeGroup.age26_35);
      expect(adultConfig.textScaleFactor, 1.0);
      expect(adultConfig.minTouchTargetHeight, 48.0);
      expect(adultConfig.enableSimplifiedLayout, isFalse);

      final seniorConfig = AgeAdaptiveUiConfig.fromAgeGroup(AgeGroup.age50Plus);
      expect(seniorConfig.textScaleFactor, 1.15);
      expect(seniorConfig.minTouchTargetHeight, 54.0);
    });
  });
}
