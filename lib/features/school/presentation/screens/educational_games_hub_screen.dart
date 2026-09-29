import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/context_extensions.dart';
import '../providers/student_providers.dart';

/// Educational Mini-Games Hub Screen for School Students.
class EducationalGamesHubScreen extends ConsumerWidget {
  const EducationalGamesHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final isChild = ref.watch(isChildModeProvider);
    final gamesAsync = ref.watch(availableGamesProvider);

    return Scaffold(
      backgroundColor:
          isChild ? const Color(0xFFF4F9F9) : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor:
            isChild ? const Color(0xFFE6F4F1) : AppColors.surfaceLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.gamesHubTitle,
          style: TextStyle(
            fontSize: isChild ? 20 : 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(availableGamesProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Banner
                Container(
                  padding: AppSpacing.paddingLg,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                        isChild
                            ? BorderRadius.circular(24)
                            : AppSpacing.borderRadiusXl,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: isChild ? 56 : 48,
                        height: isChild ? 56 : 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            '🎮',
                            style: TextStyle(fontSize: isChild ? 30 : 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.gamesHubTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.gamesHubSubtitle,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Games List
                gamesAsync.when(
                  data: (games) {
                    if (games.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child: Text('لا توجد ألعاب متوفرة حالياً'),
                        ),
                      );
                    }
                    return Column(
                      children:
                          games.map((game) {
                            return Container(
                              margin: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              padding:
                                  isChild
                                      ? const EdgeInsets.all(AppSpacing.md)
                                      : AppSpacing.paddingMd,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius:
                                    isChild
                                        ? BorderRadius.circular(20)
                                        : AppSpacing.borderRadiusLg,
                                border: Border.all(
                                  color: AppColors.borderLight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: isChild ? 52 : 46,
                                    height: isChild ? 52 : 46,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF6366F1,
                                      ).withValues(alpha: 0.1),
                                      borderRadius:
                                          isChild
                                              ? BorderRadius.circular(16)
                                              : AppSpacing.borderRadiusSm,
                                    ),
                                    child: Center(
                                      child: Text(
                                        game.iconEmoji,
                                        style: TextStyle(
                                          fontSize: isChild ? 26 : 22,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          game.localizedTitle(isArabic),
                                          style: TextStyle(
                                            fontSize: isChild ? 16 : 15,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimaryLight,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          game.localizedDescription(isArabic),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondaryLight,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFFD97706,
                                                ).withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '+${game.xpReward} XP ⭐',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFFD97706),
                                                ),
                                              ),
                                            ),
                                            Text(
                                              '${game.questions.length} ${isArabic ? "تحديات" : "challenges"}',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color:
                                                    AppColors
                                                        .textSecondaryLight,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6366F1),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            isChild
                                                ? BorderRadius.circular(16)
                                                : AppSpacing.borderRadiusSm,
                                      ),
                                      minimumSize: Size(
                                        isChild ? 80 : 70,
                                        isChild ? 44 : 36,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                    ),
                                    onPressed: () {
                                      context.push('/student/games/${game.id}');
                                    },
                                    child: Text(
                                      l10n.playNow,
                                      style: TextStyle(
                                        fontSize: isChild ? 13 : 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    );
                  },
                  loading:
                      () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  error:
                      (_, __) => const Center(
                        child: Text('حدث خطأ أثناء تحميل الألعاب'),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
