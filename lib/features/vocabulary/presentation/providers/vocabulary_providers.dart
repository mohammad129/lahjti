import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahjti/features/learning/domain/models/vocabulary_item.dart';
import 'package:lahjti/features/learning/domain/repositories/learning_repository.dart';
import 'package:lahjti/features/learning/presentation/providers/learning_providers.dart';
import 'package:lahjti/features/onboarding/domain/models/age_group.dart';
import 'package:lahjti/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:lahjti/features/placement/domain/models/cefr_level.dart';
import 'package:lahjti/features/vocabulary/domain/models/vocabulary_practice_models.dart';
import 'package:lahjti/features/vocabulary/domain/services/practice_question_generator.dart';

/// Filter criteria for the vocabulary explorer.
enum VocabularyFilterTab { all, dueForReview, learning, mastered }

/// State for the vocabulary screen explorer.
@immutable
class VocabularyExplorerState {
  final List<VocabularyItem> allItems;
  final String selectedCategory;
  final VocabularyFilterTab activeTab;
  final String searchQuery;
  final bool isLoading;

  const VocabularyExplorerState({
    required this.allItems,
    this.selectedCategory = 'All',
    this.activeTab = VocabularyFilterTab.all,
    this.searchQuery = '',
    this.isLoading = false,
  });

  List<String> get availableCategories {
    final categories =
        allItems.map((item) => item.category).toSet().toList()..sort();
    return ['All', ...categories];
  }

  List<VocabularyItem> get filteredItems {
    final now = DateTime.now();
    return allItems.where((item) {
      // Category filter
      if (selectedCategory != 'All' && item.category != selectedCategory) {
        return false;
      }
      // Tab filter
      switch (activeTab) {
        case VocabularyFilterTab.all:
          break;
        case VocabularyFilterTab.dueForReview:
          if (!item.isDueForReview(now)) return false;
          break;
        case VocabularyFilterTab.learning:
          if (item.status != MasteryStatus.learning &&
              item.status != MasteryStatus.reviewing) {
            return false;
          }
          break;
        case VocabularyFilterTab.mastered:
          if (item.status != MasteryStatus.mastered) return false;
          break;
      }
      // Search query
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase().trim();
        final matchesTerm = item.term.toLowerCase().contains(query);
        final matchesTranslation = item.translationArabic
            .toLowerCase()
            .contains(query);
        final matchesExample = item.exampleSentence.toLowerCase().contains(
          query,
        );
        if (!matchesTerm && !matchesTranslation && !matchesExample) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  VocabularyExplorerState copyWith({
    List<VocabularyItem>? allItems,
    String? selectedCategory,
    VocabularyFilterTab? activeTab,
    String? searchQuery,
    bool? isLoading,
  }) {
    return VocabularyExplorerState(
      allItems: allItems ?? this.allItems,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      activeTab: activeTab ?? this.activeTab,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// StateNotifier for managing the vocabulary list and filter operations.
class VocabularyExplorerNotifier
    extends StateNotifier<VocabularyExplorerState> {
  final LearningRepository _repo;

  VocabularyExplorerNotifier(this._repo)
    : super(const VocabularyExplorerState(allItems: [], isLoading: true)) {
    loadVocabulary();
  }

  Future<void> loadVocabulary() async {
    state = state.copyWith(isLoading: true);
    final items = await _repo.getVocabularyList('usr_active');
    state = state.copyWith(allItems: items, isLoading: false);
  }

  void selectCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setFilterTab(VocabularyFilterTab tab) {
    state = state.copyWith(activeTab: tab);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> updateItem(VocabularyItem updated) async {
    final updatedList =
        state.allItems.map((item) {
          return item.id == updated.id ? updated : item;
        }).toList();

    state = state.copyWith(allItems: updatedList);
    await _repo.updateVocabularyItem('usr_active', updated);
  }
}

/// Provider for vocabulary explorer state.
final vocabularyExplorerNotifierProvider =
    StateNotifierProvider<VocabularyExplorerNotifier, VocabularyExplorerState>((
      ref,
    ) {
      final repo = ref.watch(learningRepositoryProvider);
      return VocabularyExplorerNotifier(repo);
    });

/// Computes the [DailyVocabularyGoal] based on CEFR level and today's activity.
final dailyVocabularyGoalProvider = Provider<DailyVocabularyGoal>((ref) {
  final explorerState = ref.watch(vocabularyExplorerNotifierProvider);
  final profile = ref.watch(learningProfileProvider);
  final allItems = explorerState.allItems;
  final now = DateTime.now();

  // Target count adapted by CEFR level
  int targetCount;
  switch (profile.estimatedCefrLevel) {
    case CefrLevel.preA1:
    case CefrLevel.a1:
      targetCount = 6;
      break;
    case CefrLevel.a2:
      targetCount = 8;
      break;
    case CefrLevel.b1:
      targetCount = 10;
      break;
    case CefrLevel.b2:
    case CefrLevel.c1:
    case CefrLevel.c2:
      targetCount = 14;
      break;
  }

  final dueCount = allItems.where((i) => i.isDueForReview(now)).length;
  final masteredCount =
      allItems.where((i) => i.status == MasteryStatus.mastered).length;
  final reviewedToday =
      allItems.where((i) {
        if (i.lastReviewed == null) return false;
        final diff = now.difference(i.lastReviewed!);
        return diff.inHours < 24 && i.totalAttempts > 0;
      }).length;

  final learnedToday =
      allItems.where((i) {
        return i.status != MasteryStatus.newWord &&
            i.totalAttempts == 1 &&
            i.lastReviewed != null &&
            now.difference(i.lastReviewed!).inHours < 24;
      }).length;

  return DailyVocabularyGoal(
    targetCount: targetCount,
    learnedTodayCount: learnedToday,
    reviewedTodayCount: reviewedToday,
    masteredTotalCount: masteredCount,
    dueForReviewCount: dueCount,
  );
});

/// StateNotifier for driving an active vocabulary practice session.
class VocabularyPracticeNotifier extends StateNotifier<PracticeSessionState> {
  final Ref _ref;
  final PracticeQuestionGenerator _generator;

  VocabularyPracticeNotifier(this._ref, {PracticeQuestionGenerator? generator})
    : _generator = generator ?? PracticeQuestionGenerator(),
      super(const PracticeSessionState(questions: []));

  /// Initializes and starts a new practice session.
  void startSession({
    List<VocabularyItem>? targetItems,
    String? category,
    bool dueOnly = false,
  }) {
    final explorer = _ref.read(vocabularyExplorerNotifierProvider);
    final allItems = explorer.allItems;
    final now = DateTime.now();

    List<VocabularyItem> pool = targetItems ?? allItems;

    if (dueOnly) {
      pool = pool.where((item) => item.isDueForReview(now)).toList();
      // If none are strictly due, practice all available items
      if (pool.isEmpty) pool = allItems;
    } else if (category != null && category != 'All') {
      pool = pool.where((item) => item.category == category).toList();
    }

    final questions = _generator.generateQuestions(
      targetItems: pool,
      allItemsPool: allItems,
      maxQuestions: 8,
    );

    state = PracticeSessionState(
      questions: questions,
      currentIndex: 0,
      isAnswerSubmitted: false,
      results: const [],
      isCompleted: false,
    );
  }

  void selectOption(int index) {
    if (state.isAnswerSubmitted == true) return;
    state = state.copyWith(selectedOptionIndex: index);
  }

  /// Submits the selected multiple choice answer and applies spaced review updates.
  Future<void> submitAnswer() async {
    final currentQ = state.currentQuestion;
    final selectedIdx = state.selectedOptionIndex;
    if (currentQ == null ||
        selectedIdx == null ||
        state.isAnswerSubmitted == true) {
      return;
    }

    final isCorrect = currentQ.isCorrect(selectedIdx);
    final result = PracticeAnswerResult(
      question: currentQ,
      selectedOptionIndex: selectedIdx,
      isCorrect: isCorrect,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      isAnswerSubmitted: true,
      results: [...state.results, result],
    );

    // Update vocabulary item via deterministic spaced repetition engine
    await _applySpacedReviewUpdate(currentQ.targetItem, isCorrect);
  }

  /// Evaluates speech input for speaking practice mode.
  Future<void> evaluateSpokenText(String spokenText) async {
    final currentQ = state.currentQuestion;
    if (currentQ == null || state.isAnswerSubmitted == true) return;

    state = state.copyWith(isEvaluatingSpeech: true);

    final targetTermClean = _normalizeText(currentQ.targetItem.term);
    final spokenClean = _normalizeText(spokenText);

    // Check if spoken text contains or matches the target term
    final isCorrect =
        spokenClean.contains(targetTermClean) ||
        targetTermClean.contains(spokenClean);

    final result = PracticeAnswerResult(
      question: currentQ,
      spokenText: spokenText,
      isCorrect: isCorrect,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      isAnswerSubmitted: true,
      isEvaluatingSpeech: false,
      results: [...state.results, result],
    );

    await _applySpacedReviewUpdate(currentQ.targetItem, isCorrect);
  }

  Future<void> _applySpacedReviewUpdate(
    VocabularyItem item,
    bool isCorrect,
  ) async {
    final engine = _ref.read(adaptiveLearningEngineProvider);
    final updatedItem = engine.computeNextReview(
      item: item,
      wasCorrect: isCorrect,
      now: DateTime.now(),
    );

    await _ref
        .read(vocabularyExplorerNotifierProvider.notifier)
        .updateItem(updatedItem);
  }

  String _normalizeText(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
  }

  void nextQuestion() {
    if (state.currentIndex + 1 < state.totalQuestions) {
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        selectedOptionIndex: null,
        isAnswerSubmitted: false,
      );
    } else {
      state = state.copyWith(isCompleted: true);
    }
  }
}

/// Provider for the active practice session.
final vocabularyPracticeNotifierProvider =
    StateNotifierProvider<VocabularyPracticeNotifier, PracticeSessionState>((
      ref,
    ) {
      return VocabularyPracticeNotifier(ref);
    });

/// Age-Adaptive UI styling parameters.
@immutable
class AgeAdaptiveUiConfig {
  final double textScaleFactor;
  final double minTouchTargetHeight;
  final double cardPadding;
  final double borderRadius;
  final bool showVisualBadges;
  final bool enableSimplifiedLayout;

  const AgeAdaptiveUiConfig({
    required this.textScaleFactor,
    required this.minTouchTargetHeight,
    required this.cardPadding,
    required this.borderRadius,
    required this.showVisualBadges,
    required this.enableSimplifiedLayout,
  });

  static AgeAdaptiveUiConfig fromAgeGroup(AgeGroup? ageGroup) {
    if (ageGroup == null) {
      return const AgeAdaptiveUiConfig(
        textScaleFactor: 1.0,
        minTouchTargetHeight: 48.0,
        cardPadding: 16.0,
        borderRadius: 16.0,
        showVisualBadges: true,
        enableSimplifiedLayout: false,
      );
    }

    if (ageGroup.isChild) {
      return const AgeAdaptiveUiConfig(
        textScaleFactor: 1.2,
        minTouchTargetHeight: 56.0,
        cardPadding: 20.0,
        borderRadius: 20.0,
        showVisualBadges: true,
        enableSimplifiedLayout: true,
      );
    } else if (ageGroup.isTeen) {
      return const AgeAdaptiveUiConfig(
        textScaleFactor: 1.05,
        minTouchTargetHeight: 48.0,
        cardPadding: 16.0,
        borderRadius: 16.0,
        showVisualBadges: true,
        enableSimplifiedLayout: false,
      );
    } else if (ageGroup == AgeGroup.age50Plus ||
        ageGroup == AgeGroup.age55Plus) {
      return const AgeAdaptiveUiConfig(
        textScaleFactor: 1.15,
        minTouchTargetHeight: 54.0,
        cardPadding: 18.0,
        borderRadius: 16.0,
        showVisualBadges: false,
        enableSimplifiedLayout: false,
      );
    } else {
      return const AgeAdaptiveUiConfig(
        textScaleFactor: 1.0,
        minTouchTargetHeight: 48.0,
        cardPadding: 16.0,
        borderRadius: 16.0,
        showVisualBadges: false,
        enableSimplifiedLayout: false,
      );
    }
  }
}

/// Provider for age-adaptive UI configurations.
final ageAdaptiveUiConfigProvider = Provider<AgeAdaptiveUiConfig>((ref) {
  final ageGroup = ref.watch(onboardingProvider.select((s) => s.data.ageGroup));
  return AgeAdaptiveUiConfig.fromAgeGroup(ageGroup);
});
