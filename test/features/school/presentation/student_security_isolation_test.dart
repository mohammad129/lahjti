import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahjti/features/school/data/repositories/in_memory_student_dashboard_repository.dart';
import 'package:lahjti/features/school/presentation/providers/student_providers.dart';

void main() {
  group('Student Security, Isolation & Multi-Tenant Tests', () {
    test(
      '1. Student tasks and progress are strictly isolated per student ID and school code',
      () async {
        final container = ProviderContainer(
          overrides: [
            studentDashboardRepositoryProvider.overrideWithValue(
              InMemoryStudentDashboardRepository(),
            ),
          ],
        );
        final repo = container.read(studentDashboardRepositoryProvider);

        final tasksStudent1 = await repo.getDailyTasks(
          studentId: 'stu_sami_01',
          schoolCode: 'SCH-1001',
        );

        final tasksStudent2 = await repo.getDailyTasks(
          studentId: 'stu_layla_02',
          schoolCode: 'SCH-1001',
        );

        expect(tasksStudent2, isNotEmpty);

        // Complete task for student 1
        await repo.completeDailyTask(
          studentId: 'stu_sami_01',
          taskId: tasksStudent1.first.id,
          schoolCode: 'SCH-1001',
        );

        final summary1 = await repo.getStudentProgressSummary(
          studentId: 'stu_sami_01',
          schoolCode: 'SCH-1001',
        );

        final summary2 = await repo.getStudentProgressSummary(
          studentId: 'stu_layla_02',
          schoolCode: 'SCH-1001',
        );

        // Student 1 completed 1 task; Student 2 has 0 completed tasks
        expect(summary1.completedTasksTodayCount, 1);
        expect(summary2.completedTasksTodayCount, 0);
        expect(summary1.totalXp, greaterThan(summary2.totalXp));
      },
    );

    test(
      '2. Attempting to complete a non-existent task throws ArgumentError',
      () async {
        final container = ProviderContainer(
          overrides: [
            studentDashboardRepositoryProvider.overrideWithValue(
              InMemoryStudentDashboardRepository(),
            ),
          ],
        );
        final repo = container.read(studentDashboardRepositoryProvider);

        expect(
          () => repo.completeDailyTask(
            studentId: 'stu_sami_01',
            taskId: 'task_fake_999',
            schoolCode: 'SCH-1001',
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );
  });
}
