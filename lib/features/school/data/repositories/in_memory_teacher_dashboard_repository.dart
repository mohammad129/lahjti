import '../../domain/models/classroom_models.dart';
import '../../domain/repositories/teacher_dashboard_repository.dart';
import '../../../learning/domain/models/learning_skill.dart';

/// In-memory implementation of TeacherDashboardRepository for deterministic testing and local execution.
class InMemoryTeacherDashboardRepository implements TeacherDashboardRepository {
  final Map<String, Classroom> _classrooms = {};
  final Map<String, List<ClassroomStudent>> _classStudents = {};
  final Map<String, StudentLearningOverview> _studentOverviews = {};
  final Map<String, List<StudentSkillSummary>> _studentSkills = {};
  final Map<String, List<StudentActivitySummary>> _studentActivities = {};
  final Map<String, List<String>> _studentAttentionMap = {};

  InMemoryTeacherDashboardRepository({bool seedDefaults = true}) {
    if (seedDefaults) {
      _seedDefaultData();
    }
  }

  void _seedDefaultData() {
    final now = DateTime.now();

    // Class 1: Grade 6 - A (Teacher: teacher_default / u_teacher_1, School: SCH-1001)
    final class1 = Classroom(
      id: 'cls_grade6_a',
      schoolCode: 'SCH-1001',
      name: 'الصف السادس - أ',
      grade: 'الصف السادس',
      section: 'أ',
      teacherId: 'teacher_default',
      active: true,
      createdAt: DateTime(2026, 1, 10),
    );
    _classrooms[class1.id] = class1;

    // Class 2: Grade 7 - B (Teacher: teacher_default, School: SCH-1001)
    final class2 = Classroom(
      id: 'cls_grade7_b',
      schoolCode: 'SCH-1001',
      name: 'الصف السابع - ب',
      grade: 'الصف السابع',
      section: 'ب',
      teacherId: 'teacher_default',
      active: true,
      createdAt: DateTime(2026, 1, 10),
    );
    _classrooms[class2.id] = class2;

    // Class 3: Empty Class with 0 students (Teacher: teacher_default, School: SCH-1001)
    final class3 = Classroom(
      id: 'cls_grade8_c',
      schoolCode: 'SCH-1001',
      name: 'الصف الثامن - ج',
      grade: 'الصف الثامن',
      section: 'ج',
      teacherId: 'teacher_default',
      active: true,
      createdAt: DateTime(2026, 1, 10),
    );
    _classrooms[class3.id] = class3;
    _classStudents[class3.id] = [];

    // Class 4: Another Teacher's Class (Teacher: other_teacher, School: OTHER-SCH)
    final classOther = Classroom(
      id: 'cls_other_school',
      schoolCode: 'OTHER-SCH',
      name: 'الصف التاسع - أ',
      grade: 'الصف التاسع',
      section: 'أ',
      teacherId: 'other_teacher',
      active: true,
      createdAt: DateTime(2026, 1, 10),
    );
    _classrooms[classOther.id] = classOther;

    // Students for Class 1 (Grade 6 - A)
    final student1 = ClassroomStudent(
      studentId: 'stu_sami_01',
      classId: class1.id,
      schoolCode: class1.schoolCode,
      fullName: 'سامي عبد الله عواد',
      avatarEmoji: '🎒',
      joinedAt: DateTime(2026, 1, 15),
    );
    final student2 = ClassroomStudent(
      studentId: 'stu_layla_02',
      classId: class1.id,
      schoolCode: class1.schoolCode,
      fullName: 'ليلى طارق خليل',
      avatarEmoji: '🌟',
      joinedAt: DateTime(2026, 1, 16),
    );
    final student3 = ClassroomStudent(
      studentId: 'stu_youssef_03',
      classId: class1.id,
      schoolCode: class1.schoolCode,
      fullName: 'يوسف رائد المصري',
      avatarEmoji: '⚡',
      joinedAt: DateTime(2026, 1, 17),
    );
    _classStudents[class1.id] = [student1, student2, student3];

    // Students for Class 2 (Grade 7 - B)
    final student4 = ClassroomStudent(
      studentId: 'stu_nour_04',
      classId: class2.id,
      schoolCode: class2.schoolCode,
      fullName: 'نور الدين الخطيب',
      avatarEmoji: '🎯',
      joinedAt: DateTime(2026, 1, 18),
    );
    _classStudents[class2.id] = [student4];

    // Detailed Overview for Student 1 (Sami - Complete Data)
    _studentOverviews[student1.studentId] = StudentLearningOverview(
      studentId: student1.studentId,
      visibleName: student1.visibleName,
      cefrLevel: 'A2 - مبتدئ متقدم',
      totalXp: 450,
      streakDays: 5,
      lessonsCompletedCount: 14,
      vocabularyMasteredCount: 42,
      examsCompletedCount: 3,
      totalLearningMinutes: 185,
      hasSufficientData: true,
      lastActiveDate: now,
    );
    _studentSkills[student1.studentId] = [
      const StudentSkillSummary(
        skill: LearningSkill.speaking,
        score: 75,
        assessedAttempts: 6,
        hasSufficientEvidence: true,
      ),
      const StudentSkillSummary(
        skill: LearningSkill.listening,
        score: 82,
        assessedAttempts: 8,
        hasSufficientEvidence: true,
      ),
      const StudentSkillSummary(
        skill: LearningSkill.vocabulary,
        score: 88,
        assessedAttempts: 12,
        hasSufficientEvidence: true,
      ),
      const StudentSkillSummary(
        skill: LearningSkill.grammar,
        score: 68,
        assessedAttempts: 5,
        hasSufficientEvidence: true,
      ),
      const StudentSkillSummary(
        skill: LearningSkill.reading,
        score: 80,
        assessedAttempts: 7,
        hasSufficientEvidence: true,
      ),
      const StudentSkillSummary(
        skill: LearningSkill.comprehension,
        score: 78,
        assessedAttempts: 6,
        hasSufficientEvidence: true,
      ),
    ];
    _studentActivities[student1.studentId] = [
      StudentActivitySummary(
        id: 'act_1',
        title: 'درس: في المطعم والمقهى',
        type: 'lesson',
        timestamp: now.subtract(const Duration(hours: 2)),
        details: 'إتمام الدرس بنسبة إتقان 90% وكسب 30 نقطة XP',
      ),
      StudentActivitySummary(
        id: 'act_2',
        title: 'تدريب مفردات: التعابير اليومية',
        type: 'vocabulary',
        timestamp: now.subtract(const Duration(hours: 5)),
        details: 'مراجعة 10 كلمات ومفردات محكية',
      ),
      StudentActivitySummary(
        id: 'act_3',
        title: 'امتحان الشهر الأول التجريبي',
        type: 'exam',
        timestamp: now.subtract(const Duration(days: 1)),
        details: 'الحصول على درجة 84% وتثبيت مستوى A2',
      ),
    ];
    _studentAttentionMap[student1.studentId] = [
      'بحاجة لتركيز إضافي على استخدام تصريف الأفعال الماضية في القواعد.',
    ];

    // Detailed Overview for Student 2 (Layla - Active, High Performance)
    _studentOverviews[student2.studentId] = StudentLearningOverview(
      studentId: student2.studentId,
      visibleName: student2.visibleName,
      cefrLevel: 'B1 - متوسط',
      totalXp: 820,
      streakDays: 12,
      lessonsCompletedCount: 26,
      vocabularyMasteredCount: 88,
      examsCompletedCount: 5,
      totalLearningMinutes: 320,
      hasSufficientData: true,
      lastActiveDate: now,
    );
    _studentSkills[student2.studentId] = [
      const StudentSkillSummary(
        skill: LearningSkill.speaking,
        score: 90,
        assessedAttempts: 15,
        hasSufficientEvidence: true,
      ),
      const StudentSkillSummary(
        skill: LearningSkill.listening,
        score: 94,
        assessedAttempts: 18,
        hasSufficientEvidence: true,
      ),
      const StudentSkillSummary(
        skill: LearningSkill.vocabulary,
        score: 92,
        assessedAttempts: 22,
        hasSufficientEvidence: true,
      ),
      const StudentSkillSummary(
        skill: LearningSkill.grammar,
        score: 85,
        assessedAttempts: 10,
        hasSufficientEvidence: true,
      ),
      const StudentSkillSummary(
        skill: LearningSkill.reading,
        score: 88,
        assessedAttempts: 11,
        hasSufficientEvidence: true,
      ),
      const StudentSkillSummary(
        skill: LearningSkill.comprehension,
        score: 91,
        assessedAttempts: 14,
        hasSufficientEvidence: true,
      ),
    ];
    _studentActivities[student2.studentId] = [
      StudentActivitySummary(
        id: 'act_4',
        title: 'محادثة المدرب: مناقشة الهوايات',
        type: 'tutor',
        timestamp: now.subtract(const Duration(hours: 1)),
        details: 'محادثة صوتية مدتها 6 دقائق بنبرة واثقة',
      ),
    ];
    _studentAttentionMap[student2.studentId] = [];

    // Detailed Overview for Student 3 (Youssef - Insufficient Data, New Student)
    _studentOverviews[student3.studentId] = StudentLearningOverview(
      studentId: student3.studentId,
      visibleName: student3.visibleName,
      cefrLevel: 'Pre-A1',
      totalXp: 20,
      streakDays: 1,
      lessonsCompletedCount: 1,
      vocabularyMasteredCount: 3,
      examsCompletedCount: 0,
      totalLearningMinutes: 8,
      hasSufficientData: false,
      lastActiveDate: now.subtract(const Duration(days: 3)),
    );
    _studentSkills[student3.studentId] = [
      const StudentSkillSummary(
        skill: LearningSkill.speaking,
        score: 40,
        assessedAttempts: 1,
        hasSufficientEvidence: false,
      ),
      const StudentSkillSummary(
        skill: LearningSkill.listening,
        score: 50,
        assessedAttempts: 1,
        hasSufficientEvidence: false,
      ),
    ];
    _studentActivities[student3.studentId] = [];
    _studentAttentionMap[student3.studentId] = [];
  }

  bool _isTeacherAuthorized({
    required String teacherId,
    required String schoolCode,
    required Classroom classroom,
  }) {
    final normalizedCode = schoolCode.trim().toUpperCase();
    final classSchool = classroom.schoolCode.trim().toUpperCase();
    return classroom.teacherId == teacherId && classSchool == normalizedCode;
  }

  @override
  Future<TeacherOverviewData> getTeacherOverview({
    required String teacherId,
    required String schoolCode,
  }) async {
    final classes = await getTeacherClasses(
      teacherId: teacherId,
      schoolCode: schoolCode,
    );

    if (classes.isEmpty) {
      return TeacherOverviewData.empty();
    }

    int totalStudents = 0;
    int activeToday = 0;
    int completedTasks = 0;
    double totalProgress = 0.0;
    int classesWithProgress = 0;

    for (final c in classes) {
      totalStudents += c.studentCount;
      activeToday += c.activeTodayCount;
      completedTasks += c.completedTasksTodayCount;
      if (c.hasSufficientData) {
        totalProgress += c.averageProgressPercentage;
        classesWithProgress++;
      }
    }

    final avgProgress =
        classesWithProgress > 0 ? totalProgress / classesWithProgress : 0.0;

    return TeacherOverviewData(
      totalStudents: totalStudents,
      activeTodayCount: activeToday,
      completedTasksTodayCount: completedTasks,
      averageProgressPercentage: avgProgress,
      hasSufficientData: classesWithProgress > 0 && totalStudents > 0,
    );
  }

  @override
  Future<List<TeacherClassSummary>> getTeacherClasses({
    required String teacherId,
    required String schoolCode,
  }) async {
    final authorizedClasses =
        _classrooms.values.where((c) {
          return c.active &&
              _isTeacherAuthorized(
                teacherId: teacherId,
                schoolCode: schoolCode,
                classroom: c,
              );
        }).toList();

    final List<TeacherClassSummary> summaries = [];

    for (final classroom in authorizedClasses) {
      final students = _classStudents[classroom.id] ?? [];
      int activeToday = 0;
      int completedTasks = 0;
      double progressSum = 0.0;
      int studentsWithData = 0;

      for (final s in students) {
        final overview = _studentOverviews[s.studentId];
        if (overview != null) {
          final isToday =
              overview.lastActiveDate.difference(DateTime.now()).inHours.abs() <
              24;
          if (isToday) activeToday++;
          if (overview.streakDays > 0) completedTasks++;
          if (overview.hasSufficientData) {
            final pct = (overview.lessonsCompletedCount / 30.0) * 100.0;
            progressSum += pct.clamp(0.0, 100.0);
            studentsWithData++;
          }
        }
      }

      final avgProgress =
          studentsWithData > 0 ? progressSum / studentsWithData : 0.0;

      summaries.add(
        TeacherClassSummary(
          classId: classroom.id,
          className: classroom.name,
          grade: classroom.grade,
          section: classroom.section,
          studentCount: students.length,
          activeTodayCount: activeToday,
          completedTasksTodayCount: completedTasks,
          averageProgressPercentage: avgProgress,
          hasSufficientData: studentsWithData > 0,
        ),
      );
    }

    return summaries;
  }

  @override
  Future<Classroom?> getClassById({
    required String classId,
    required String teacherId,
    required String schoolCode,
  }) async {
    final classroom = _classrooms[classId];
    if (classroom == null) return null;
    if (!_isTeacherAuthorized(
      teacherId: teacherId,
      schoolCode: schoolCode,
      classroom: classroom,
    )) {
      return null;
    }
    return classroom;
  }

  @override
  Future<List<TeacherStudentSummary>> getClassStudents({
    required String classId,
    required String teacherId,
    required String schoolCode,
  }) async {
    final classroom = await getClassById(
      classId: classId,
      teacherId: teacherId,
      schoolCode: schoolCode,
    );
    if (classroom == null) return [];

    final students = _classStudents[classId] ?? [];
    final List<TeacherStudentSummary> list = [];

    for (final s in students) {
      final overview = _studentOverviews[s.studentId];
      final isToday =
          overview != null &&
          overview.lastActiveDate.difference(DateTime.now()).inHours.abs() < 24;
      final progressPct =
          overview != null
              ? ((overview.lessonsCompletedCount / 30.0) * 100.0).clamp(
                0.0,
                100.0,
              )
              : 0.0;

      list.add(
        TeacherStudentSummary(
          studentId: s.studentId,
          classId: classId,
          visibleName: s.visibleName,
          avatarEmoji: s.avatarEmoji,
          cefrLevel: overview?.cefrLevel ?? 'Pre-A1',
          totalXp: overview?.totalXp ?? 0,
          streakDays: overview?.streakDays ?? 0,
          completedTasksToday: isToday && (overview.streakDays) > 0,
          overallProgressPercentage: progressPct,
          hasSufficientData: overview?.hasSufficientData ?? false,
          lastActiveDate: overview?.lastActiveDate ?? s.joinedAt,
        ),
      );
    }

    return list;
  }

  @override
  Future<StudentLearningOverview?> getStudentOverview({
    required String studentId,
    required String classId,
    required String teacherId,
    required String schoolCode,
  }) async {
    final classroom = await getClassById(
      classId: classId,
      teacherId: teacherId,
      schoolCode: schoolCode,
    );
    if (classroom == null) return null;

    final students = _classStudents[classId] ?? [];
    if (!students.any((s) => s.studentId == studentId)) {
      return null;
    }

    return _studentOverviews[studentId];
  }

  @override
  Future<List<StudentSkillSummary>> getStudentSkills({
    required String studentId,
    required String classId,
    required String teacherId,
    required String schoolCode,
  }) async {
    final overview = await getStudentOverview(
      studentId: studentId,
      classId: classId,
      teacherId: teacherId,
      schoolCode: schoolCode,
    );
    if (overview == null) return [];

    return _studentSkills[studentId] ?? [];
  }

  @override
  Future<List<StudentActivitySummary>> getStudentActivities({
    required String studentId,
    required String classId,
    required String teacherId,
    required String schoolCode,
  }) async {
    final overview = await getStudentOverview(
      studentId: studentId,
      classId: classId,
      teacherId: teacherId,
      schoolCode: schoolCode,
    );
    if (overview == null) return [];

    return _studentActivities[studentId] ?? [];
  }

  @override
  Future<List<String>> getStudentNeedsAttention({
    required String studentId,
    required String classId,
    required String teacherId,
    required String schoolCode,
  }) async {
    final overview = await getStudentOverview(
      studentId: studentId,
      classId: classId,
      teacherId: teacherId,
      schoolCode: schoolCode,
    );
    if (overview == null) return [];

    return _studentAttentionMap[studentId] ?? [];
  }

  // Testing helpers for custom mock data injection
  void addClassroom(Classroom classroom) {
    _classrooms[classroom.id] = classroom;
  }

  void addStudentsToClass(String classId, List<ClassroomStudent> students) {
    _classStudents[classId] = students;
  }

  void setStudentOverview(String studentId, StudentLearningOverview overview) {
    _studentOverviews[studentId] = overview;
  }
}
