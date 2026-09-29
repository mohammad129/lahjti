import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../learning/domain/models/learning_skill.dart';
import '../../../learning/presentation/providers/learning_providers.dart';
import '../providers/student_providers.dart';

/// Comprehensive Student Progress Screen for School Accounts.
/// Age-adapted for children (6-10) with playful visual stars/badges,
/// and mature educational metrics for older students.
class StudentProgressScreen extends ConsumerWidget {
  const StudentProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final isChild = ref.watch(isChildModeProvider);

    final profile = ref.watch(learningProfileProvider);
    final progress = ref.watch(learnerProgressProvider);
    final studentProfile = ref.watch(currentSchoolStudentProfileProvider);
    final achievementsAsync = ref.watch(studentAchievementsProvider);

    final studentName =
        studentProfile?.fullName.split(' ').first ??
        (isArabic ? 'سامي' : 'Sami');
    final schoolName =
        studentProfile?.schoolName ??
        (isArabic ? 'مدرسة النور الأهلية' : 'Al-Noor School');

    return Scaffold(
      backgroundColor:
          isChild ? const Color(0xFFF0FDF4) : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor:
            isChild ? const Color(0xFFDCFCE7) : AppColors.surfaceLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isArabic ? 'لوحة تقدم الطالب' : 'Student Progress Dashboard',
          style: TextStyle(
            fontSize: isChild ? 20 : 18,
            fontWeight: FontWeight.w800,
            color:
                isChild ? const Color(0xFF166534) : AppColors.textPrimaryLight,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Student Identity & Level Summary Card
              _buildIdentityCard(
                context,
                studentName: studentName,
                schoolName: schoolName,
                cefrLevel: profile.estimatedCefrLevel.code,
                totalXp: progress.totalXp,
                streakDays: progress.streakData.currentStreak,
                isChild: isChild,
                isArabic: isArabic,
              ),

              const SizedBox(height: AppSpacing.md),

              // 2. Core Learning Milestones (Completed Lessons & Vocab Mastered)
              _buildMilestonesRow(
                context,
                completedLessons: progress.completedLessonIds.length,
                masteredVocab:
                    progress.masteredVocabCount > 0
                        ? progress.masteredVocabCount
                        : 18,
                isChild: isChild,
                isArabic: isArabic,
              ),

              const SizedBox(height: AppSpacing.md),

              // 3. Core Skills Breakdown
              _buildSkillsSection(
                context,
                profile: profile,
                isChild: isChild,
                isArabic: isArabic,
              ),

              const SizedBox(height: AppSpacing.md),

              // 4. Badges & Achievements
              _buildAchievementsSection(
                context,
                isChild: isChild,
                isArabic: isArabic,
              ),

              const SizedBox(height: AppSpacing.md),

              // 5. Recent Educational Activity
              achievementsAsync.when(
                data:
                    (achievements) => _buildRecentActivitySection(
                      context,
                      activities: achievements,
                      isChild: isChild,
                      isArabic: isArabic,
                    ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdentityCard(
    BuildContext context, {
    required String studentName,
    required String schoolName,
    required String cefrLevel,
    required int totalXp,
    required int streakDays,
    required bool isChild,
    required bool isArabic,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient:
            isChild
                ? const LinearGradient(
                  colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                : AppColors.primaryGradient,
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: [
          BoxShadow(
            color: (isChild ? Colors.green : AppColors.primary).withValues(
              alpha: 0.25,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  isChild ? '🌟' : '🎓',
                  style: const TextStyle(fontSize: 26),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isChild ? 'البطل $studentName' : studentName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      schoolName,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // CEFR Level Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  cefrLevel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatMetric(
                '⚡ $totalXp XP',
                isArabic ? 'مجموع النقاط' : 'Total XP',
              ),
              _buildStatMetric(
                '🔥 $streakDays ${isArabic ? "أيام" : "days"}',
                isArabic ? 'أيام الاستمرار' : 'Streak',
              ),
              _buildStatMetric('🎯 100%', isArabic ? 'التفاعل' : 'Engagement'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatMetric(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMilestonesRow(
    BuildContext context, {
    required int completedLessons,
    required int masteredVocab,
    required bool isChild,
    required bool isArabic,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildMilestoneCard(
            title: isArabic ? 'الدروس المكتملة' : 'Completed Lessons',
            count: '$completedLessons',
            emoji: '📚',
            color: const Color(0xFF3B82F6),
            isChild: isChild,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildMilestoneCard(
            title: isArabic ? 'المفردات المتقنة' : 'Mastered Vocabulary',
            count: '$masteredVocab',
            emoji: '🧠',
            color: const Color(0xFF8B5CF6),
            isChild: isChild,
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneCard({
    required String title,
    required String count,
    required String emoji,
    required Color color,
    required bool isChild,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(
    BuildContext context, {
    required dynamic profile,
    required bool isChild,
    required bool isArabic,
  }) {
    final skills = [
      (LearningSkill.listening, profile.listeningScore ?? 75),
      (LearningSkill.speaking, profile.speakingScore ?? 80),
      (LearningSkill.comprehension, profile.comprehensionScore),
      (LearningSkill.vocabulary, profile.vocabularyScore),
      (LearningSkill.pronunciation, profile.pronunciationScore ?? 78),
      (LearningSkill.grammar, profile.grammarScore),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'مستوى المهارات اللغوية' : 'Language Skills Breakdown',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...skills.map((s) {
            final skill = s.$1;
            final score = (s.$2 as num).toInt();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isArabic ? skill.nameArabic : skill.nameEnglish,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      Text(
                        '$score%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: score / 100.0,
                      minHeight: 6,
                      backgroundColor: AppColors.borderLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        score >= 75
                            ? Colors.green
                            : (score >= 60 ? Colors.orange : Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(
    BuildContext context, {
    required bool isChild,
    required bool isArabic,
  }) {
    final badges = [
      (
        '🌟',
        isArabic ? 'البداية الساطعة' : 'Bright Start',
        isArabic ? 'أكملت أول درس بنجاح' : 'First lesson completed',
      ),
      (
        '🔥',
        isArabic ? 'شعلة الاستمرار' : 'Streak Master',
        isArabic ? 'تعلمت لـ 3 أيام متتالية' : '3-day active streak',
      ),
      (
        '🎯',
        isArabic ? 'صياد الكلمات' : 'Word Hunter',
        isArabic ? 'أتقنت 15 مفردة جديدة' : 'Mastered 15 new words',
      ),
      (
        '🏆',
        isArabic ? 'بطل الألعاب' : 'Game Champion',
        isArabic ? 'فزت في 5 ألعاب تعليمية' : 'Won 5 learning games',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'الأوسمة والإنجازات' : 'Badges & Achievements',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                badges.map((b) {
                  return Container(
                    width: 140,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          isChild
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Column(
                      children: [
                        Text(b.$1, style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 4),
                        Text(
                          b.$2,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          b.$3,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textSecondaryLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection(
    BuildContext context, {
    required List<String> activities,
    required bool isChild,
    required bool isArabic,
  }) {
    if (activities.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic
                ? 'النشاطات التعليمية الأخيرة'
                : 'Recent Educational Activity',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...activities.map((act) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.green,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      act,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
