import '../models/classroom_models.dart';

/// Repository interface for teacher dashboard queries, classroom management, and student progress inspection.
abstract class TeacherDashboardRepository {
  /// Fetches aggregate overview metrics for the teacher's dashboard.
  Future<TeacherOverviewData> getTeacherOverview({
    required String teacherId,
    required String schoolCode,
  });

  /// Fetches list of classrooms assigned to the teacher.
  Future<List<TeacherClassSummary>> getTeacherClasses({
    required String teacherId,
    required String schoolCode,
  });

  /// Fetches details for a specific classroom with authorization check.
  Future<Classroom?> getClassById({
    required String classId,
    required String teacherId,
    required String schoolCode,
  });

  /// Fetches list of enrolled students and their progress summary for a classroom.
  Future<List<TeacherStudentSummary>> getClassStudents({
    required String classId,
    required String teacherId,
    required String schoolCode,
  });

  /// Fetches educational learning overview for an enrolled student.
  Future<StudentLearningOverview?> getStudentOverview({
    required String studentId,
    required String classId,
    required String teacherId,
    required String schoolCode,
  });

  /// Fetches skill breakdown metrics for a student across all tracked skills.
  Future<List<StudentSkillSummary>> getStudentSkills({
    required String studentId,
    required String classId,
    required String teacherId,
    required String schoolCode,
  });

  /// Fetches recent educational learning activities for a student.
  Future<List<StudentActivitySummary>> getStudentActivities({
    required String studentId,
    required String classId,
    required String teacherId,
    required String schoolCode,
  });

  /// Fetches evidence-based attention items or warnings for a student.
  Future<List<String>> getStudentNeedsAttention({
    required String studentId,
    required String classId,
    required String teacherId,
    required String schoolCode,
  });
}
