import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lahjti/core/routing/app_routes.dart';
import 'package:lahjti/core/theme/app_colors.dart';
import 'package:lahjti/core/theme/app_spacing.dart';
import 'package:lahjti/core/utils/context_extensions.dart';
import 'package:lahjti/features/learning/domain/models/vocabulary_item.dart';
import 'package:lahjti/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:lahjti/features/tutor/presentation/providers/voice_session_provider.dart';
import 'package:lahjti/features/vocabulary/domain/models/vocabulary_practice_models.dart';
import 'package:lahjti/features/vocabulary/presentation/providers/vocabulary_providers.dart';

/// The main Vocabulary explorer and learning hub screen.
class VocabularyScreen extends ConsumerStatefulWidget {
  const VocabularyScreen({super.key});

  @override
  ConsumerState<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends ConsumerState<VocabularyScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final explorer = ref.watch(vocabularyExplorerNotifierProvider);
    final dailyGoal = ref.watch(dailyVocabularyGoalProvider);
    final ageConfig = ref.watch(ageAdaptiveUiConfigProvider);
    final onboardingData = ref.watch(onboardingProvider.select((s) => s.data));
    final isAbbas = (onboardingData.selectedTutorId ?? 'abbas') == 'abbas';
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          l10n.vocabulary,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20 * ageConfig.textScaleFactor,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.surfaceLight,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث',
            onPressed: () {
              ref
                  .read(vocabularyExplorerNotifierProvider.notifier)
                  .loadVocabulary();
            },
          ),
        ],
      ),
      body: SafeArea(
        child:
            explorer.isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomScrollView(
                  slivers: [
                    // 1. Daily Vocabulary Goal Header Card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: _buildDailyGoalCard(
                          context,
                          dailyGoal,
                          isAbbas,
                          ageConfig,
                        ),
                      ),
                    ),

                    // 2. Smart Review & AI Tutor Action Banner
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: _buildActionBanner(
                          context,
                          ref,
                          dailyGoal,
                          isAbbas,
                          ageConfig,
                        ),
                      ),
                    ),

                    // 3. Search Field
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            ref
                                .read(
                                  vocabularyExplorerNotifierProvider.notifier,
                                )
                                .setSearchQuery(val);
                          },
                          decoration: InputDecoration(
                            hintText: 'ابحث عن كلمة أو معنى...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon:
                                _searchController.text.isNotEmpty
                                    ? IconButton(
                                      icon: const Icon(Icons.clear_rounded),
                                      onPressed: () {
                                        _searchController.clear();
                                        ref
                                            .read(
                                              vocabularyExplorerNotifierProvider
                                                  .notifier,
                                            )
                                            .setSearchQuery('');
                                      },
                                    )
                                    : null,
                            filled: true,
                            fillColor: AppColors.surfaceLight,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.borderLight,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.borderLight,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 4. Filter Tabs (All / Due / Learning / Mastered)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        child: _buildFilterTabs(
                          ref,
                          explorer.activeTab,
                          dailyGoal.dueForReviewCount,
                        ),
                      ),
                    ),

                    // 5. Category / Topic Filter Chips
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 48,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 6,
                          ),
                          itemCount: explorer.availableCategories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final category =
                                explorer.availableCategories[index];
                            final isSelected =
                                explorer.selectedCategory == category;

                            return ChoiceChip(
                              label: Text(
                                category == 'All' ? 'جميع المواضيع' : category,
                                style: TextStyle(
                                  fontSize: 13 * ageConfig.textScaleFactor,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : AppColors.textPrimaryLight,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor:
                                  isAbbas
                                      ? AppColors.primary
                                      : AppColors.secondary,
                              backgroundColor: AppColors.surfaceLight,
                              onSelected: (_) {
                                ref
                                    .read(
                                      vocabularyExplorerNotifierProvider
                                          .notifier,
                                    )
                                    .selectCategory(category);
                              },
                            );
                          },
                        ),
                      ),
                    ),

                    // 6. Vocabulary Items List
                    if (explorer.filteredItems.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.menu_book_rounded,
                                  size: 56,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                const Text(
                                  'لا توجد كلمات مطابقة لهذا الفلتر',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final item = explorer.filteredItems[index];
                            return _buildVocabularyCard(
                              context,
                              ref,
                              item,
                              ageConfig,
                            );
                          }, childCount: explorer.filteredItems.length),
                        ),
                      ),
                  ],
                ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref
              .read(vocabularyPracticeNotifierProvider.notifier)
              .startSession(
                dueOnly: explorer.activeTab == VocabularyFilterTab.dueForReview,
                category: explorer.selectedCategory,
              );
          context.push(AppRoutes.vocabularyPractice);
        },
        backgroundColor: isAbbas ? AppColors.primary : AppColors.secondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.school_rounded),
        label: const Text(
          'بدء التدريب الذكي',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildDailyGoalCard(
    BuildContext context,
    DailyVocabularyGoal goal,
    bool isAbbas,
    AgeAdaptiveUiConfig ageConfig,
  ) {
    return Container(
      padding: EdgeInsets.all(ageConfig.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(ageConfig.borderRadius),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isAbbas
                                ? AppColors.primary
                                : AppColors.secondary)
                            .withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.track_changes_rounded,
                        color:
                            isAbbas ? AppColors.primary : AppColors.secondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'الهدف اليومي للمفردات',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16 * ageConfig.textScaleFactor,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      goal.isGoalReached
                          ? Colors.green.withValues(alpha: 0.12)
                          : Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  goal.isGoalReached
                      ? 'مكتمل اليوم! 🎉'
                      : '${goal.totalCompletedToday} / ${goal.targetCount}',
                  style: TextStyle(
                    fontSize: 12 * ageConfig.textScaleFactor,
                    fontWeight: FontWeight.w700,
                    color:
                        goal.isGoalReached
                            ? Colors.green.shade700
                            : Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: goal.progressRatio,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                isAbbas ? AppColors.primary : AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildStatItem(
                  'جديد اليوم',
                  '${goal.learnedTodayCount}',
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'تمت المراجعة',
                  '${goal.reviewedTodayCount}',
                  Colors.purple,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'مستحق الآن',
                  '${goal.dueForReviewCount}',
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'متقن',
                  '${goal.masteredTotalCount}',
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildActionBanner(
    BuildContext context,
    WidgetRef ref,
    DailyVocabularyGoal goal,
    bool isAbbas,
    AgeAdaptiveUiConfig ageConfig,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient:
            isAbbas
                ? AppColors.primaryGradient
                : const LinearGradient(
                  colors: [Color(0xFFEA580C), Color(0xFFFB923C)],
                ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تدرب على الكلمات في محادثة حية',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isAbbas
                      ? 'تحدث مع عباس لتطبيق مفرداتك'
                      : 'تحدث مع دنيا لتطبيق مفرداتك',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => context.push(AppRoutes.tutorConversation),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor:
                  isAbbas ? AppColors.primary : AppColors.secondary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              'بدء الحوار',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(
    WidgetRef ref,
    VocabularyFilterTab activeTab,
    int dueCount,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          _buildTabButton(
            ref,
            'الكل',
            VocabularyFilterTab.all,
            activeTab == VocabularyFilterTab.all,
          ),
          _buildTabButton(
            ref,
            'مستحق ($dueCount)',
            VocabularyFilterTab.dueForReview,
            activeTab == VocabularyFilterTab.dueForReview,
            highlight: dueCount > 0,
          ),
          _buildTabButton(
            ref,
            'قيد التعلم',
            VocabularyFilterTab.learning,
            activeTab == VocabularyFilterTab.learning,
          ),
          _buildTabButton(
            ref,
            'متقنة',
            VocabularyFilterTab.mastered,
            activeTab == VocabularyFilterTab.mastered,
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    WidgetRef ref,
    String label,
    VocabularyFilterTab tab,
    bool isSelected, {
    bool highlight = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          ref
              .read(vocabularyExplorerNotifierProvider.notifier)
              .setFilterTab(tab);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color:
                    isSelected
                        ? Colors.white
                        : (highlight
                            ? Colors.orange.shade800
                            : AppColors.textPrimaryLight),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVocabularyCard(
    BuildContext context,
    WidgetRef ref,
    VocabularyItem item,
    AgeAdaptiveUiConfig ageConfig,
  ) {
    final tts = ref.watch(textToSpeechServiceProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(ageConfig.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(ageConfig.borderRadius),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Word, phonetic, and TTS button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.term,
                        style: TextStyle(
                          fontSize: 18 * ageConfig.textScaleFactor,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.phonetic != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLightVariant,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.phonetic!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondaryLight,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.volume_up_rounded,
                  color: AppColors.primary,
                ),
                tooltip: 'استمع للنطق',
                onPressed: () {
                  tts.speak(text: item.term, languageCode: 'en');
                },
              ),
            ],
          ),

          // Arabic Meaning
          Text(
            item.translationArabic,
            style: TextStyle(
              fontSize: 15 * ageConfig.textScaleFactor,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),

          // Example Sentence
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLightVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.exampleSentence,
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.exampleTranslationArabic,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Bottom Metadata: Category, CEFR, Mastery Status, and Streak
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: _buildTagChip(
                        item.category,
                        Colors.grey.shade700,
                        Colors.grey.shade200,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildTagChip(
                      item.difficulty.code,
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildMasteryChip(item.status, item.correctStreak),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildMasteryChip(MasteryStatus status, int streak) {
    Color color;
    String label;

    switch (status) {
      case MasteryStatus.newWord:
        color = Colors.blue;
        label = 'جديدة';
        break;
      case MasteryStatus.learning:
        color = Colors.orange;
        label = 'قيد التعلم ($streak)';
        break;
      case MasteryStatus.reviewing:
        color = Colors.purple;
        label = 'مراجعة ($streak)';
        break;
      case MasteryStatus.mastered:
        color = Colors.green;
        label = 'متقنة ⭐';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
