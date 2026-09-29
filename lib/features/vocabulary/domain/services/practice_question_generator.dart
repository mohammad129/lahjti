import 'dart:math';
import 'package:lahjti/features/learning/domain/models/vocabulary_item.dart';
import 'package:lahjti/features/vocabulary/domain/models/vocabulary_practice_models.dart';

/// Deterministic generator for creating multi-modal vocabulary practice questions.
class PracticeQuestionGenerator {
  final Random _random;

  PracticeQuestionGenerator({Random? random}) : _random = random ?? Random(42);

  /// Generates a set of practice questions for the given target items.
  List<PracticeQuestion> generateQuestions({
    required List<VocabularyItem> targetItems,
    required List<VocabularyItem> allItemsPool,
    int maxQuestions = 10,
  }) {
    if (targetItems.isEmpty) return const [];

    final questions = <PracticeQuestion>[];
    final shuffledTargets = List<VocabularyItem>.from(targetItems)
      ..shuffle(_random);

    final selectedTargets = shuffledTargets.take(maxQuestions).toList();

    for (int i = 0; i < selectedTargets.length; i++) {
      final item = selectedTargets[i];
      // Rotate modes deterministically
      final mode = _selectPracticeMode(i, item);
      final question = _buildQuestion(item, mode, allItemsPool, i + 1);
      questions.add(question);
    }

    return questions;
  }

  PracticeMode _selectPracticeMode(int index, VocabularyItem item) {
    // 0: recognizeMeaning, 1: wordSelection, 2: sentenceCompletion, 3: speakingProduction
    final modes = [
      PracticeMode.recognizeMeaning,
      PracticeMode.wordSelection,
      PracticeMode.sentenceCompletion,
      PracticeMode.speakingProduction,
    ];
    return modes[index % modes.length];
  }

  PracticeQuestion _buildQuestion(
    VocabularyItem target,
    PracticeMode mode,
    List<VocabularyItem> pool,
    int index,
  ) {
    final distractors = _getDistractors(target, pool, 3);

    switch (mode) {
      case PracticeMode.recognizeMeaning:
        final options = [target.translationArabic];
        options.addAll(distractors.map((d) => d.translationArabic));
        options.shuffle(_random);
        final correctIdx = options.indexOf(target.translationArabic);

        return PracticeQuestion(
          id: 'q_${target.id}_$index',
          mode: mode,
          targetItem: target,
          promptText: target.term,
          promptSubtext: 'ما هو المعنى الصحيح لهذه الكلمة؟',
          options: options,
          correctOptionIndex: correctIdx,
          explanationArabic:
              'الكلمة "${target.term}" تعني "${target.translationArabic}". مثال: ${target.exampleSentence}',
          explanationEnglish:
              '"${target.term}" translates to "${target.translationArabic}". Example: ${target.exampleSentence}',
        );

      case PracticeMode.wordSelection:
        final options = [target.term];
        options.addAll(distractors.map((d) => d.term));
        options.shuffle(_random);
        final correctIdx = options.indexOf(target.term);

        return PracticeQuestion(
          id: 'q_${target.id}_$index',
          mode: mode,
          targetItem: target,
          promptText: target.translationArabic,
          promptSubtext: 'اختر الكلمة الإنجليزية المناسبة:',
          options: options,
          correctOptionIndex: correctIdx,
          explanationArabic:
              'الترجمة الإنجليزية لـ "${target.translationArabic}" هي "${target.term}".',
          explanationEnglish:
              'The English word for "${target.translationArabic}" is "${target.term}".',
        );

      case PracticeMode.sentenceCompletion:
        final blankSentence = _createBlankSentence(
          target.exampleSentence,
          target.term,
        );
        final options = [target.term];
        options.addAll(distractors.map((d) => d.term));
        options.shuffle(_random);
        final correctIdx = options.indexOf(target.term);

        return PracticeQuestion(
          id: 'q_${target.id}_$index',
          mode: mode,
          targetItem: target,
          promptText: blankSentence,
          promptSubtext: 'أكمل الفراغ بالكلمة المناسبة في السياق:',
          options: options,
          correctOptionIndex: correctIdx,
          explanationArabic:
              'الجملة الكاملة: "${target.exampleSentence}" (المعنى: ${target.exampleTranslationArabic})',
          explanationEnglish:
              'Full sentence: "${target.exampleSentence}" (${target.exampleTranslationArabic})',
        );

      case PracticeMode.speakingProduction:
        // In speaking mode, options show pronunciation tips / phonetic breakdown
        final options = [target.term, ...distractors.map((d) => d.term)]
          ..shuffle(_random);
        final correctIdx = options.indexOf(target.term);

        return PracticeQuestion(
          id: 'q_${target.id}_$index',
          mode: mode,
          targetItem: target,
          promptText: target.term,
          promptSubtext: 'انطق الكلمة بوضوح عبر الميكروفون 🎙️',
          options: options,
          correctOptionIndex: correctIdx,
          explanationArabic:
              'النطق الصحيح: "${target.phonetic ?? target.term}" — تدرب على تكرارها بصوت واضح.',
          explanationEnglish:
              'Pronunciation: "${target.phonetic ?? target.term}" — Practice saying it clearly.',
        );
    }
  }

  String _createBlankSentence(String sentence, String word) {
    final pattern = RegExp(RegExp.escape(word), caseSensitive: false);
    if (pattern.hasMatch(sentence)) {
      return sentence.replaceFirst(pattern, '_______');
    }
    // Fallback if exact match isn't found
    return '$sentence (_______)';
  }

  List<VocabularyItem> _getDistractors(
    VocabularyItem target,
    List<VocabularyItem> pool,
    int count,
  ) {
    final filtered = pool.where((item) => item.id != target.id).toList();
    if (filtered.isEmpty) {
      // Fallback dummy distractors if pool is too small
      return [
        VocabularyItem(
          id: 'dummy_1',
          term: 'Word A',
          translationArabic: 'خيار أ',
          exampleSentence: 'Example A',
          exampleTranslationArabic: 'مثال أ',
          difficulty: target.difficulty,
          category: target.category,
        ),
        VocabularyItem(
          id: 'dummy_2',
          term: 'Word B',
          translationArabic: 'خيار ب',
          exampleSentence: 'Example B',
          exampleTranslationArabic: 'مثال ب',
          difficulty: target.difficulty,
          category: target.category,
        ),
        VocabularyItem(
          id: 'dummy_3',
          term: 'Word C',
          translationArabic: 'خيار ج',
          exampleSentence: 'Example C',
          exampleTranslationArabic: 'مثال ج',
          difficulty: target.difficulty,
          category: target.category,
        ),
      ];
    }

    filtered.shuffle(_random);
    return filtered.take(count).toList();
  }
}
