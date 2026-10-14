import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/plan_models.dart';
import '../providers/plan_providers.dart';

class PlansListScreen extends ConsumerStatefulWidget {
  const PlansListScreen({super.key});

  @override
  ConsumerState<PlansListScreen> createState() => _PlansListScreenState();
}

class _PlansListScreenState extends ConsumerState<PlansListScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(plansListProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        title: const Text(
          'الخطط التعليمية المنظمة',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: () => ref.refresh(plansListProvider),
            tooltip: 'تحديث الخطط',
          ),
        ],
      ),
      body: SafeArea(
        child: plansAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                  const SizedBox(height: AppSpacing.md),
                  Text('تعذر تحميل الخطط: $err', textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    onPressed: () => ref.refresh(plansListProvider),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          ),
          data: (plans) {
            final filtered = _filterPlans(plans, _selectedFilter);
            return RefreshIndicator(
              onRefresh: () async => ref.refresh(plansListProvider),
              child: ListView(
                padding: AppSpacing.screenPadding,
                children: [
                  // Motivating Hero Header Banner
                  Container(
                    padding: AppSpacing.paddingLg,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: AppSpacing.borderRadiusXl,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Text('🎯', style: TextStyle(fontSize: 24)),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            const Expanded(
                              child: Text(
                                'اختر خطتك وابدأ مسارك المنظم',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Text(
                          'مسارات تدريبية مركزة مبنية على خطوات يومية قصيرة تضمن لك التقدم الثابت والطلاقة الحقيقية دون ملل أو تشتت.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Filter Chips Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('الكل', 'all'),
                        _buildFilterChip('مكثف 60 يوم', 'intensive'),
                        _buildFilterChip('محادثة', 'conversation'),
                        _buildFilterChip('مقابلات وعمل', 'professional'),
                        _buildFilterChip('سفر وسياحة', 'travel'),
                        _buildFilterChip('دراسة وجامعة', 'academic'),
                        _buildFilterChip('مدارس', 'school'),
                        _buildFilterChip('أطفال', 'kids'),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Plans Cards
                  ...filtered.map((plan) => _buildPlanCard(context, plan)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<LearningPlan> _filterPlans(List<LearningPlan> plans, String filter) {
    if (filter == 'all') return plans;
    if (filter == 'intensive') return plans.where((p) => p.durationDays >= 60).toList();
    if (filter == 'conversation') return plans.where((p) => p.id.contains('conversation')).toList();
    if (filter == 'professional') return plans.where((p) => p.id.contains('interview') || p.targetAudience == 'professionals').toList();
    if (filter == 'travel') return plans.where((p) => p.id.contains('travel') || p.targetAudience == 'travelers').toList();
    if (filter == 'academic') return plans.where((p) => p.id.contains('academic') || p.targetAudience == 'students').toList();
    if (filter == 'school') return plans.where((p) => p.id.contains('school') || p.targetAudience == 'school').toList();
    if (filter == 'kids') return plans.where((p) => p.id.contains('kids') || p.targetAudience == 'kids').toList();
    return plans;
  }

  Widget _buildFilterChip(String label, String key) {
    final isSelected = _selectedFilter == key;
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textPrimaryLight,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          fontSize: 13,
        ),
        backgroundColor: AppColors.surfaceLight,
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
          ),
        ),
        onSelected: (_) {
          setState(() {
            _selectedFilter = key;
          });
        },
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, LearningPlan plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: plan.isFeatured ? AppColors.primary : AppColors.borderLight,
          width: plan.isFeatured ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: AppSpacing.borderRadiusLg,
        onTap: () {
          ref.read(enrolledPlanIdProvider.notifier).state = plan.id;
          context.push('/plans/${plan.id}');
        },
        child: Padding(
          padding: AppSpacing.paddingMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Badges & Icon Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: AppSpacing.borderRadiusMd,
                    ),
                    child: Center(
                      child: Text(plan.icon, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${plan.durationDays} يوماً',
                                style: const TextStyle(
                                  color: AppColors.primaryDark,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'المستوى ${plan.level}',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (plan.isFeatured) ...[
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star_rounded, size: 14, color: Color(0xFFD97706)),
                                    SizedBox(width: 2),
                                    Text(
                                      'مميزة',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFD97706),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          plan.titleAr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        Text(
                          plan.titleEn,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryLight,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              // Description
              Text(
                plan.descriptionAr,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondaryLight,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Progress Bar if enrolled
              if (plan.isEnrolled) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'اليوم ${plan.currentDay} من ${plan.durationDays}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      '${(plan.progressPercent * 100).toInt()}% منجز',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: plan.progressPercent,
                    backgroundColor: AppColors.borderLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              // Action button row
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: plan.isEnrolled ? AppColors.primary : AppColors.surfaceLightVariant,
                    foregroundColor: plan.isEnrolled ? Colors.white : AppColors.primaryDark,
                    elevation: plan.isEnrolled ? 2 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: () {
                    ref.read(enrolledPlanIdProvider.notifier).state = plan.id;
                    context.push('/plans/${plan.id}');
                  },
                  icon: Icon(
                    plan.isEnrolled ? Icons.play_arrow_rounded : Icons.explore_rounded,
                    size: 18,
                  ),
                  label: Text(
                    plan.isEnrolled ? 'متابعة مسار الخطة' : 'استكشاف وبدء الخطة',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
