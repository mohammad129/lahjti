import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/repositories/plan_repository.dart';
import '../../domain/models/plan_models.dart';

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RemotePlanRepository(apiClient);
});

final plansListProvider = FutureProvider<List<LearningPlan>>((ref) async {
  final repository = ref.watch(planRepositoryProvider);
  return repository.getPlans();
});

final enrolledPlanIdProvider = StateProvider<String>((ref) => 'plan_60_days_intensive');

final activePlanProvider = FutureProvider<LearningPlan?>((ref) async {
  final repository = ref.watch(planRepositoryProvider);
  final planId = ref.watch(enrolledPlanIdProvider);
  return repository.getPlanDetails(planId);
});

final planDaysProvider = FutureProvider.family<List<PlanDay>, String>((ref, planId) async {
  final repository = ref.watch(planRepositoryProvider);
  return repository.getPlanDays(planId);
});

class DayActivitiesParams {
  final String planId;
  final int dayNumber;

  const DayActivitiesParams({required this.planId, required this.dayNumber});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayActivitiesParams &&
          runtimeType == other.runtimeType &&
          planId == other.planId &&
          dayNumber == other.dayNumber;

  @override
  int get hashCode => planId.hashCode ^ dayNumber.hashCode;
}

final dayActivitiesProvider =
    FutureProvider.family<List<PlanActivity>, DayActivitiesParams>((ref, params) async {
  final repository = ref.watch(planRepositoryProvider);
  return repository.getDayActivities(params.planId, params.dayNumber);
});

final currentActivityStepProvider = StateProvider<int>((ref) => 0);

final dueMistakesProvider = FutureProvider<List<StudentMistakeItem>>((ref) async {
  final repository = ref.watch(planRepositoryProvider);
  return repository.getDueMistakes();
});
