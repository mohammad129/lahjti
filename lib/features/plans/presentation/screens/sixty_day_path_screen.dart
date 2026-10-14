import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/plan_models.dart';
import '../providers/plan_providers.dart';

class SixtyDayPathScreen extends ConsumerWidget {
  final String planId;

  const SixtyDayPathScreen({super.key, required this.planId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysAsync = ref.watch(planDaysProvider(planId));
    final planAsync = ref.watch(activePlanProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        title: Text(
          planAsync.value?.titleAr ?? 'مسار الخطة اليومي',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
            onPressed: () => _showPlanInfoModal(context, planAsync.value),
            tooltip: 'تفاصيل الخطة',
          ),
        ],
      ),
      body: SafeArea(
        child: daysAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: Text('حدث خطأ في تحميل المسار: $err'),
            ),
          ),
          data: (days) {
            final activeDay = days.firstWhere(
              (d) => !d.isCompleted && d.isUnlocked,
              orElse: () => days.first,
            );

            return Column(
              children: [
                // Active Day Quick Launch Card
                Container(
                  margin: AppSpacing.screenPadding,
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: AppSpacing.borderRadiusLg,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Text('⚡', style: TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'اليوم المستهدف: اليوم ${activeDay.dayNumber}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activeDay.titleAr,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        onPressed: () {
                          context.push('/plans/$planId/day/${activeDay.dayNumber}');
                        },
                        child: const Text(
                          'ابدأ الآن',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

                // Roadmap Header Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'خريطة الـ 60 يوماً (${days.where((d) => d.isCompleted).length} من ${days.length} منجز)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const Row(
                        children: [
                          Icon(Icons.workspace_premium_rounded, size: 18, color: Color(0xFFD97706)),
                          SizedBox(width: 4),
                          Text(
                            '+100 XP / يوم',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(height: 16),

                // Timeline List
                Expanded(
                  child: ListView.builder(
                    padding: AppSpacing.screenPadding,
                    itemCount: days.length,
                    itemBuilder: (context, index) {
                      final day = days[index];
                      final isMilestone = day.dayNumber % 10 == 0;
                      return _buildDayItem(context, day, isMilestone);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDayItem(BuildContext context, PlanDay day, bool isMilestone) {
    Color itemColor;
    IconData statusIcon;
    String statusText;

    if (day.isCompleted) {
      itemColor = Colors.green;
      statusIcon = Icons.check_circle_rounded;
      statusText = 'مكتمل';
    } else if (day.isUnlocked) {
      itemColor = AppColors.primary;
      statusIcon = Icons.play_circle_filled_rounded;
      statusText = 'متاح الآن';
    } else {
      itemColor = Colors.grey.shade400;
      statusIcon = Icons.lock_rounded;
      statusText = 'مغلق';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: day.isUnlocked ? itemColor.withValues(alpha: 0.5) : AppColors.borderLight,
          width: day.isUnlocked ? 1.5 : 1.0,
        ),
        boxShadow: day.isUnlocked
            ? [
                BoxShadow(
                  color: itemColor.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: itemColor.withValues(alpha: 0.15),
          child: Text(
            '${day.dayNumber}',
            style: TextStyle(
              color: itemColor,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                day.titleAr,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: day.isUnlocked ? AppColors.textPrimaryLight : AppColors.textSecondaryLight,
                ),
              ),
            ),
            if (isMilestone)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'محطة مميزة 🏅',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD97706),
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          '${day.activitiesCount} أنشطة تفاعلية • $statusText • +${day.xpReward} XP',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
        ),
        trailing: Icon(statusIcon, color: itemColor),
        onTap: day.isUnlocked
            ? () {
                context.push('/plans/$planId/day/${day.dayNumber}');
              }
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('أكمل اليوم ${day.dayNumber - 1} لفتح هذا اليوم 🔒'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
      ),
    );
  }

  void _showPlanInfoModal(BuildContext context, LearningPlan? plan) {
    if (plan == null) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              plan.titleAr,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              plan.descriptionAr,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondaryLight, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoPill(title: '9 أنشطة', subtitle: 'يومياً'),
                _InfoPill(title: '15 دقيقة', subtitle: 'الوقت المقدر'),
                _InfoPill(title: '0 تشتت', subtitle: 'تركيز كامل'),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String title;
  final String subtitle;

  const _InfoPill({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryDark)),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
      ],
    );
  }
}
