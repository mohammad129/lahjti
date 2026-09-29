import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../domain/models/game_models.dart';
import '../providers/student_providers.dart';

/// Interactive Gameplay Screen for all 5 educational mini-games.
class GamePlayScreen extends ConsumerStatefulWidget {
  final String gameId;

  const GamePlayScreen({super.key, required this.gameId});

  @override
  ConsumerState<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends ConsumerState<GamePlayScreen> {
  int _currentQuestionIndex = 0;
  int _correctCount = 0;
  bool _isAnswerChecked = false;
  bool _isCorrect = false;

  // Word Match state
  String? _selectedMatchLeft;
  final Set<String> _matchedPairs = {};

  // Sentence Builder state
  final List<String> _constructedWords = [];

  // Memory Game state
  final List<int> _flippedIndices = [];
  final Set<int> _solvedIndices = {};

  // Multiple Choice selection
  int? _selectedOptionIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final isChild = ref.watch(isChildModeProvider);
    final gameAsync = ref.watch(gameDetailsProvider(widget.gameId));

    return Scaffold(
      backgroundColor:
          isChild ? const Color(0xFFF4F9F9) : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor:
            isChild ? const Color(0xFFE6F4F1) : AppColors.surfaceLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: gameAsync.when(
          data:
              (game) => Text(
                game?.localizedTitle(isArabic) ?? l10n.educationalGames,
                style: TextStyle(
                  fontSize: isChild ? 20 : 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight,
                ),
              ),
          loading: () => Text(l10n.educationalGames),
          error: (_, __) => Text(l10n.educationalGames),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: gameAsync.when(
          data: (game) {
            if (game == null || game.questions.isEmpty) {
              return const Center(child: Text('اللعبة غير متوفرة'));
            }

            final totalQuestions = game.questions.length;
            final currentQuestion = game.questions[_currentQuestionIndex];

            return Column(
              children: [
                // Top Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value:
                                (totalQuestions > 0)
                                    ? (_currentQuestionIndex + 1) /
                                        totalQuestions
                                    : 0.0,
                            minHeight: 8,
                            backgroundColor: AppColors.borderLight,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF6366F1),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        '${_currentQuestionIndex + 1} / $totalQuestions',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: AppSpacing.screenPadding,
                    child: _buildGameContent(
                      context,
                      game: game,
                      question: currentQuestion,
                      isArabic: isArabic,
                      isChild: isChild,
                    ),
                  ),
                ),

                // Bottom Action Footer
                _buildActionFooter(
                  context,
                  game: game,
                  question: currentQuestion,
                  isChild: isChild,
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('حدث خطأ')),
        ),
      ),
    );
  }

  Widget _buildGameContent(
    BuildContext context, {
    required GameActivity game,
    required GameQuestion question,
    required bool isArabic,
    required bool isChild,
  }) {
    switch (game.gameType) {
      case GameType.wordMatch:
        return _buildWordMatchContent(context, question, isChild: isChild);
      case GameType.listenAndChoose:
        return _buildListenChooseContent(context, question, isChild: isChild);
      case GameType.pictureWordSelect:
        return _buildPictureWordSelectContent(
          context,
          question,
          isChild: isChild,
          isArabic: isArabic,
        );
      case GameType.sentenceBuilder:
        return _buildSentenceBuilderContent(
          context,
          question,
          isChild: isChild,
        );
      case GameType.memoryVocab:
        return _buildMemoryVocabContent(context, question, isChild: isChild);
      case GameType.quickQuiz:
        return _buildQuizContent(context, question, isChild: isChild);
    }
  }

  // 1. Picture / Word Select Game Widget
  Widget _buildPictureWordSelectContent(
    BuildContext context,
    GameQuestion question, {
    required bool isChild,
    required bool isArabic,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Column(
            children: [
              const Text('🖼️', style: TextStyle(fontSize: 32)),
              const SizedBox(height: 6),
              Text(
                question.promptArabic,
                style: TextStyle(
                  fontSize: isChild ? 20 : 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF166534),
                ),
                textAlign: TextAlign.center,
              ),
              if (question.promptEnglish.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  question.promptEnglish,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF15803D),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
          ),
          itemCount: question.options.length,
          itemBuilder: (context, index) {
            final option = question.options[index];
            final isSelected = _selectedOptionIndex == index;
            final isCorrect = index == question.correctOptionIndex;

            Color bgColor = AppColors.surfaceLight;
            Color borderColor = AppColors.borderLight;

            if (_isAnswerChecked) {
              if (isCorrect) {
                bgColor = AppColors.successContainer;
                borderColor = AppColors.success;
              } else if (isSelected) {
                bgColor = AppColors.errorContainer;
                borderColor = AppColors.error;
              }
            } else if (isSelected) {
              bgColor = const Color(0xFFDCFCE7);
              borderColor = const Color(0xFF22C55E);
            }

            return InkWell(
              onTap:
                  _isAnswerChecked
                      ? null
                      : () {
                        setState(() {
                          _selectedOptionIndex = index;
                        });
                      },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: borderColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor:
                          isSelected
                              ? const Color(0xFF22C55E)
                              : AppColors.borderLight,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color:
                              isSelected
                                  ? Colors.white
                                  : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      option,
                      style: TextStyle(
                        fontSize: isChild ? 16 : 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryLight,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // 1. Word Match Game Widget
  Widget _buildWordMatchContent(
    BuildContext context,
    GameQuestion question, {
    required bool isChild,
  }) {
    final l10n = context.l10n;
    final pairs = question.matchPairs ?? {};
    final leftItems = pairs.keys.toList();
    final rightItems = pairs.values.toList()..shuffle();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          question.promptArabic,
          style: TextStyle(
            fontSize: isChild ? 20 : 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.tapToMatch,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondaryLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column (Arabic words)
            Expanded(
              child: Column(
                children:
                    leftItems.map((word) {
                      final isMatched = _matchedPairs.contains(word);
                      final isSelected = _selectedMatchLeft == word;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: InkWell(
                          onTap:
                              isMatched
                                  ? null
                                  : () {
                                    setState(() {
                                      _selectedMatchLeft = word;
                                    });
                                  },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: isChild ? 56 : 48,
                            decoration: BoxDecoration(
                              color:
                                  isMatched
                                      ? AppColors.successContainer
                                      : isSelected
                                      ? const Color(0xFFE0E7FF)
                                      : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    isMatched
                                        ? AppColors.success
                                        : isSelected
                                        ? const Color(0xFF6366F1)
                                        : AppColors.borderLight,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                word,
                                style: TextStyle(
                                  fontSize: isChild ? 16 : 15,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      isMatched
                                          ? AppColors.success
                                          : AppColors.textPrimaryLight,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Right Column (English/Meaning words)
            Expanded(
              child: Column(
                children:
                    rightItems.map((meaning) {
                      final isMatched = _matchedPairs.any(
                        (k) => pairs[k] == meaning,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: InkWell(
                          onTap:
                              isMatched || _selectedMatchLeft == null
                                  ? null
                                  : () {
                                    final currentLeft = _selectedMatchLeft!;
                                    final correctRight = pairs[currentLeft];
                                    if (correctRight == meaning) {
                                      setState(() {
                                        _matchedPairs.add(currentLeft);
                                        _selectedMatchLeft = null;
                                        if (_matchedPairs.length ==
                                            pairs.length) {
                                          _isAnswerChecked = true;
                                          _isCorrect = true;
                                          _correctCount++;
                                        }
                                      });
                                    } else {
                                      setState(() {
                                        _selectedMatchLeft = null;
                                      });
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('حاول مرة أخرى 💪'),
                                          duration: Duration(milliseconds: 700),
                                        ),
                                      );
                                    }
                                  },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: isChild ? 56 : 48,
                            decoration: BoxDecoration(
                              color:
                                  isMatched
                                      ? AppColors.successContainer
                                      : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    isMatched
                                        ? AppColors.success
                                        : AppColors.borderLight,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                meaning,
                                style: TextStyle(
                                  fontSize: isChild ? 15 : 14,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      isMatched
                                          ? AppColors.success
                                          : AppColors.textPrimaryLight,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Listen & Choose Game Widget
  Widget _buildListenChooseContent(
    BuildContext context,
    GameQuestion question, {
    required bool isChild,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Audio Prompt Play Card
        Container(
          padding: AppSpacing.paddingXl,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: Color(0xFF6366F1),
                child: Icon(
                  Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                question.promptArabic,
                style: TextStyle(
                  fontSize: isChild ? 24 : 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Choice Options
        ...List.generate(question.options.length, (index) {
          final option = question.options[index];
          final isSelected = _selectedOptionIndex == index;
          final isCorrect = index == question.correctOptionIndex;

          Color bgColor = AppColors.surfaceLight;
          Color borderColor = AppColors.borderLight;

          if (_isAnswerChecked) {
            if (isCorrect) {
              bgColor = AppColors.successContainer;
              borderColor = AppColors.success;
            } else if (isSelected) {
              bgColor = AppColors.errorContainer;
              borderColor = AppColors.error;
            }
          } else if (isSelected) {
            bgColor = const Color(0xFFE0E7FF);
            borderColor = const Color(0xFF6366F1);
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: InkWell(
              onTap:
                  _isAnswerChecked
                      ? null
                      : () {
                        setState(() {
                          _selectedOptionIndex = index;
                        });
                      },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: borderColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor:
                          isSelected
                              ? const Color(0xFF6366F1)
                              : AppColors.borderLight,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color:
                              isSelected
                                  ? Colors.white
                                  : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: isChild ? 16 : 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // 3. Sentence Builder Game Widget
  Widget _buildSentenceBuilderContent(
    BuildContext context,
    GameQuestion question, {
    required bool isChild,
  }) {
    final l10n = context.l10n;
    final words = question.scrambledWords ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          question.promptArabic,
          style: TextStyle(
            fontSize: isChild ? 20 : 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.arrangeSentence,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondaryLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Constructed Sentence Dropzone
        Container(
          constraints: const BoxConstraints(minHeight: 80),
          padding: AppSpacing.paddingMd,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  _isAnswerChecked
                      ? (_isCorrect ? AppColors.success : AppColors.error)
                      : const Color(0xFF6366F1).withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child:
              _constructedWords.isEmpty
                  ? const Center(
                    child: Text(
                      'المس الكلمات بالترتيب لتضعها هنا 👆',
                      style: TextStyle(
                        color: AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                  : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _constructedWords.map((word) {
                          return ActionChip(
                            label: Text(
                              word,
                              style: TextStyle(
                                fontSize: isChild ? 16 : 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: const Color(0xFF6366F1),
                            onPressed:
                                _isAnswerChecked
                                    ? null
                                    : () {
                                      setState(() {
                                        _constructedWords.remove(word);
                                      });
                                    },
                          );
                        }).toList(),
                  ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Scrambled Source Chips
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children:
              words.map((word) {
                final isUsed = _constructedWords.contains(word);
                return ActionChip(
                  label: Text(
                    word,
                    style: TextStyle(
                      fontSize: isChild ? 16 : 14,
                      fontWeight: FontWeight.w700,
                      color:
                          isUsed
                              ? AppColors.textSecondaryLight
                              : AppColors.textPrimaryLight,
                    ),
                  ),
                  backgroundColor:
                      isUsed ? AppColors.borderLight : const Color(0xFFE0E7FF),
                  onPressed:
                      (isUsed || _isAnswerChecked)
                          ? null
                          : () {
                            setState(() {
                              _constructedWords.add(word);
                            });
                          },
                );
              }).toList(),
        ),
      ],
    );
  }

  // 4. Memory Vocabulary Flashcards Game Widget
  Widget _buildMemoryVocabContent(
    BuildContext context,
    GameQuestion question, {
    required bool isChild,
  }) {
    final pairs = question.matchPairs ?? {};
    final List<String> deck = [];
    pairs.forEach((k, v) {
      deck.add(k);
      deck.add(v);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          question.promptArabic,
          style: TextStyle(
            fontSize: isChild ? 20 : 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),

        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
          ),
          itemCount: deck.length,
          itemBuilder: (context, index) {
            final item = deck[index];
            final isSolved = _solvedIndices.contains(index);
            final isFlipped = _flippedIndices.contains(index) || isSolved;

            return InkWell(
              onTap:
                  (isSolved ||
                          _flippedIndices.contains(index) ||
                          _flippedIndices.length >= 2)
                      ? null
                      : () {
                        setState(() {
                          _flippedIndices.add(index);
                        });

                        if (_flippedIndices.length == 2) {
                          final i1 = _flippedIndices[0];
                          final i2 = _flippedIndices[1];
                          final item1 = deck[i1];
                          final item2 = deck[i2];

                          final isPair =
                              pairs[item1] == item2 || pairs[item2] == item1;
                          if (isPair) {
                            setState(() {
                              _solvedIndices.add(i1);
                              _solvedIndices.add(i2);
                              _flippedIndices.clear();
                              if (_solvedIndices.length == deck.length) {
                                _isAnswerChecked = true;
                                _isCorrect = true;
                                _correctCount++;
                              }
                            });
                          } else {
                            Future.delayed(
                              const Duration(milliseconds: 900),
                              () {
                                if (mounted) {
                                  setState(() {
                                    _flippedIndices.clear();
                                  });
                                }
                              },
                            );
                          }
                        }
                      },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color:
                      isSolved
                          ? AppColors.successContainer
                          : isFlipped
                          ? const Color(0xFFE0E7FF)
                          : const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSolved ? AppColors.success : AppColors.borderLight,
                  ),
                ),
                child: Center(
                  child: Text(
                    isFlipped ? item : '❓',
                    style: TextStyle(
                      fontSize: isFlipped ? 16 : 24,
                      fontWeight: FontWeight.w700,
                      color:
                          isSolved
                              ? AppColors.success
                              : isFlipped
                              ? AppColors.textPrimaryLight
                              : Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // 5. Quick Quiz Multiple Choice Game Widget
  Widget _buildQuizContent(
    BuildContext context,
    GameQuestion question, {
    required bool isChild,
  }) {
    return _buildListenChooseContent(context, question, isChild: isChild);
  }

  // Bottom Action / Verification Button
  Widget _buildActionFooter(
    BuildContext context, {
    required GameActivity game,
    required GameQuestion question,
    required bool isChild,
  }) {
    final l10n = context.l10n;
    final totalQuestions = game.questions.length;

    return Container(
      padding: AppSpacing.screenPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child:
          !_isAnswerChecked
              ? ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: () {
                  if (game.gameType == GameType.sentenceBuilder) {
                    final sentence = _constructedWords.join(' ');
                    final isRight =
                        sentence.trim() == question.correctAnswer.trim();
                    setState(() {
                      _isAnswerChecked = true;
                      _isCorrect = isRight;
                      if (isRight) _correctCount++;
                    });
                  } else if (game.gameType == GameType.listenAndChoose ||
                      game.gameType == GameType.pictureWordSelect ||
                      game.gameType == GameType.quickQuiz) {
                    if (_selectedOptionIndex == null) return;
                    final isRight =
                        _selectedOptionIndex == question.correctOptionIndex;
                    setState(() {
                      _isAnswerChecked = true;
                      _isCorrect = isRight;
                      if (isRight) _correctCount++;
                    });
                  }
                },
                child: Text(
                  l10n.checkAnswer,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
              : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isCorrect ? AppColors.success : const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: () async {
                  if (_currentQuestionIndex + 1 < totalQuestions) {
                    setState(() {
                      _currentQuestionIndex++;
                      _isAnswerChecked = false;
                      _isCorrect = false;
                      _selectedOptionIndex = null;
                      _selectedMatchLeft = null;
                      _matchedPairs.clear();
                      _constructedWords.clear();
                      _flippedIndices.clear();
                      _solvedIndices.clear();
                    });
                  } else {
                    // Game Complete!
                    final scorePct =
                        (_correctCount /
                            (totalQuestions > 0 ? totalQuestions : 1)) *
                        100;
                    final result = GameResult(
                      gameId: game.id,
                      gameType: game.gameType,
                      totalQuestions: totalQuestions,
                      correctAnswers: _correctCount,
                      scorePercentage: scorePct,
                      earnedXp: game.xpReward,
                      completedAt: DateTime.now(),
                      passed: scorePct >= 50.0,
                    );

                    await ref
                        .read(studentActionsProvider.notifier)
                        .submitGame(result);

                    if (context.mounted) {
                      _showVictoryDialog(context, result: result, game: game);
                    }
                  }
                },
                child: Text(
                  _isCorrect ? l10n.gameGreatJob : l10n.gameTryAgain,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
    );
  }

  void _showVictoryDialog(
    BuildContext context, {
    required GameResult result,
    required GameActivity game,
  }) {
    final l10n = context.l10n;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 48)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.gameOverTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('⭐⭐⭐', style: const TextStyle(fontSize: 24)),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF08A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '+${game.xpReward} XP ⭐',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF713F12),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.scoreResult(result.scorePercentage.toInt()),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                context.go('/student/home');
              },
              child: Text(
                l10n.backToTasks,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
