import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/in_memory_school_repository.dart';
import '../../data/repositories/in_memory_teacher_dashboard_repository.dart';
import '../../domain/models/classroom_models.dart';
import '../../domain/models/school.dart';
import '../../domain/models/school_student_profile.dart';
import '../../domain/models/teacher_profile.dart';
import '../../domain/repositories/school_repository.dart';
import '../../domain/repositories/teacher_dashboard_repository.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';

/// Provider for the SchoolRepository instance.
final schoolRepositoryProvider = Provider<SchoolRepository>((ref) {
  return InMemorySchoolRepository();
});

/// FutureProvider to find a school by its code.
final schoolByCodeProvider = FutureProvider.family<School?, String>((
  ref,
  code,
) async {
  if (code.trim().isEmpty) return null;
  final repository = ref.watch(schoolRepositoryProvider);
  return repository.findSchoolByCode(code);
});

/// StateProvider holding the current authenticated Teacher profile (if applicable).
final currentTeacherProfileProvider = StateProvider<TeacherProfile?>(
  (ref) => null,
);

/// StateProvider holding the current enrolled Student profile (if applicable).
final currentSchoolStudentProfileProvider =
    StateProvider<SchoolStudentProfile?>((ref) => null);

/// Provider for the TeacherDashboardRepository instance.
final teacherDashboardRepositoryProvider = Provider<TeacherDashboardRepository>(
  (ref) {
    return InMemoryTeacherDashboardRepository();
  },
);

/// Provider for teacher overview data on dashboard.
final teacherOverviewProvider = FutureProvider<TeacherOverviewData>((
  ref,
) async {
  final repo = ref.watch(teacherDashboardRepositoryProvider);
  final onboardingData = ref.watch(onboardingProvider.select((s) => s.data));
  final teacherProfile = ref.watch(currentTeacherProfileProvider);

  final teacherId = teacherProfile?.teacherId ?? 'teacher_default';
  final schoolCode =
      teacherProfile?.schoolCode ?? onboardingData.schoolCode ?? 'SCH-1001';

  return repo.getTeacherOverview(teacherId: teacherId, schoolCode: schoolCode);
});

/// Provider for teacher assigned classes.
final teacherClassesProvider = FutureProvider<List<TeacherClassSummary>>((
  ref,
) async {
  final repo = ref.watch(teacherDashboardRepositoryProvider);
  final onboardingData = ref.watch(onboardingProvider.select((s) => s.data));
  final teacherProfile = ref.watch(currentTeacherProfileProvider);

  final teacherId = teacherProfile?.teacherId ?? 'teacher_default';
  final schoolCode =
      teacherProfile?.schoolCode ?? onboardingData.schoolCode ?? 'SCH-1001';

  return repo.getTeacherClasses(teacherId: teacherId, schoolCode: schoolCode);
});

/// Provider for specific classroom details.
final teacherClassDetailsProvider = FutureProvider.family<Classroom?, String>((
  ref,
  classId,
) async {
  final repo = ref.watch(teacherDashboardRepositoryProvider);
  final onboardingData = ref.watch(onboardingProvider.select((s) => s.data));
  final teacherProfile = ref.watch(currentTeacherProfileProvider);

  final teacherId = teacherProfile?.teacherId ?? 'teacher_default';
  final schoolCode =
      teacherProfile?.schoolCode ?? onboardingData.schoolCode ?? 'SCH-1001';

  return repo.getClassById(
    classId: classId,
    teacherId: teacherId,
    schoolCode: schoolCode,
  );
});

/// Provider for list of students in a classroom.
final teacherClassStudentsProvider = FutureProvider.family<
  List<TeacherStudentSummary>,
  String
>((ref, classId) async {
  final repo = ref.watch(teacherDashboardRepositoryProvider);
  final onboardingData = ref.watch(onboardingProvider.select((s) => s.data));
  final teacherProfile = ref.watch(currentTeacherProfileProvider);

  final teacherId = teacherProfile?.teacherId ?? 'teacher_default';
  final schoolCode =
      teacherProfile?.schoolCode ?? onboardingData.schoolCode ?? 'SCH-1001';

  return repo.getClassStudents(
    classId: classId,
    teacherId: teacherId,
    schoolCode: schoolCode,
  );
});

/// Query parameter container for student queries
class StudentQueryParams {
  final String studentId;
  final String classId;

  const StudentQueryParams({required this.studentId, required this.classId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentQueryParams &&
          runtimeType == other.runtimeType &&
          studentId == other.studentId &&
          classId == other.classId;

  @override
  int get hashCode => studentId.hashCode ^ classId.hashCode;
}

/// Provider for student learning overview.
final teacherStudentOverviewProvider = FutureProvider.family<
  StudentLearningOverview?,
  StudentQueryParams
>((ref, params) async {
  final repo = ref.watch(teacherDashboardRepositoryProvider);
  final onboardingData = ref.watch(onboardingProvider.select((s) => s.data));
  final teacherProfile = ref.watch(currentTeacherProfileProvider);

  final teacherId = teacherProfile?.teacherId ?? 'teacher_default';
  final schoolCode =
      teacherProfile?.schoolCode ?? onboardingData.schoolCode ?? 'SCH-1001';

  return repo.getStudentOverview(
    studentId: params.studentId,
    classId: params.classId,
    teacherId: teacherId,
    schoolCode: schoolCode,
  );
});

/// Provider for student skill progress breakdown.
final teacherStudentSkillsProvider = FutureProvider.family<
  List<StudentSkillSummary>,
  StudentQueryParams
>((ref, params) async {
  final repo = ref.watch(teacherDashboardRepositoryProvider);
  final onboardingData = ref.watch(onboardingProvider.select((s) => s.data));
  final teacherProfile = ref.watch(currentTeacherProfileProvider);

  final teacherId = teacherProfile?.teacherId ?? 'teacher_default';
  final schoolCode =
      teacherProfile?.schoolCode ?? onboardingData.schoolCode ?? 'SCH-1001';

  return repo.getStudentSkills(
    studentId: params.studentId,
    classId: params.classId,
    teacherId: teacherId,
    schoolCode: schoolCode,
  );
});

/// Provider for student educational activity log.
final teacherStudentActivitiesProvider = FutureProvider.family<
  List<StudentActivitySummary>,
  StudentQueryParams
>((ref, params) async {
  final repo = ref.watch(teacherDashboardRepositoryProvider);
  final onboardingData = ref.watch(onboardingProvider.select((s) => s.data));
  final teacherProfile = ref.watch(currentTeacherProfileProvider);

  final teacherId = teacherProfile?.teacherId ?? 'teacher_default';
  final schoolCode =
      teacherProfile?.schoolCode ?? onboardingData.schoolCode ?? 'SCH-1001';

  return repo.getStudentActivities(
    studentId: params.studentId,
    classId: params.classId,
    teacherId: teacherId,
    schoolCode: schoolCode,
  );
});

/// Provider for student attention items.
final teacherStudentAttentionProvider = FutureProvider.family<
  List<String>,
  StudentQueryParams
>((ref, params) async {
  final repo = ref.watch(teacherDashboardRepositoryProvider);
  final onboardingData = ref.watch(onboardingProvider.select((s) => s.data));
  final teacherProfile = ref.watch(currentTeacherProfileProvider);

  final teacherId = teacherProfile?.teacherId ?? 'teacher_default';
  final schoolCode =
      teacherProfile?.schoolCode ?? onboardingData.schoolCode ?? 'SCH-1001';

  return repo.getStudentNeedsAttention(
    studentId: params.studentId,
    classId: params.classId,
    teacherId: teacherId,
    schoolCode: schoolCode,
  );
});
