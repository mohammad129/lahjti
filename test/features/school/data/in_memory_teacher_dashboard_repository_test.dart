import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/school/data/repositories/in_memory_teacher_dashboard_repository.dart';

void main() {
  group('InMemoryTeacherDashboardRepository Tests', () {
    late InMemoryTeacherDashboardRepository repository;

    setUp(() {
      repository = InMemoryTeacherDashboardRepository(seedDefaults: true);
    });

    test(
      '1. Computes teacher overview metrics accurately from real student data',
      () async {
        final overview = await repository.getTeacherOverview(
          teacherId: 'teacher_default',
          schoolCode: 'SCH-1001',
        );

        expect(
          overview.totalStudents,
          4,
        ); // 3 in class1 + 1 in class2 + 0 in class3
        expect(overview.activeTodayCount, greaterThan(0));
        expect(overview.hasSufficientData, isTrue);
        expect(overview.averageProgressPercentage, greaterThan(0.0));
      },
    );

    test('2. Retrieves assigned classes for teacher', () async {
      final classes = await repository.getTeacherClasses(
        teacherId: 'teacher_default',
        schoolCode: 'SCH-1001',
      );

      expect(classes.length, 3);
      expect(
        classes.any((c) => c.grade == 'الصف السادس' && c.section == 'أ'),
        isTrue,
      );
      expect(
        classes.any((c) => c.grade == 'الصف الثامن' && c.section == 'ج'),
        isTrue,
      );
    });

    test('3. Retrieves class details by ID', () async {
      final classroom = await repository.getClassById(
        classId: 'cls_grade6_a',
        teacherId: 'teacher_default',
        schoolCode: 'SCH-1001',
      );

      expect(classroom, isNotNull);
      expect(classroom!.grade, 'الصف السادس');
      expect(classroom.section, 'أ');
    });

    test('4. Retrieves class students with privacy-safe names', () async {
      final students = await repository.getClassStudents(
        classId: 'cls_grade6_a',
        teacherId: 'teacher_default',
        schoolCode: 'SCH-1001',
      );

      expect(students.length, 3);
      expect(students[0].visibleName, 'سامي ع.');
      expect(students[0].cefrLevel, 'A2 - مبتدئ متقدم');
      expect(students[0].streakDays, 5);
    });

    test(
      '5. Retrieves student educational learning overview, skills, and activities',
      () async {
        final overview = await repository.getStudentOverview(
          studentId: 'stu_sami_01',
          classId: 'cls_grade6_a',
          teacherId: 'teacher_default',
          schoolCode: 'SCH-1001',
        );

        expect(overview, isNotNull);
        expect(overview!.totalXp, 450);
        expect(overview.lessonsCompletedCount, 14);

        final skills = await repository.getStudentSkills(
          studentId: 'stu_sami_01',
          classId: 'cls_grade6_a',
          teacherId: 'teacher_default',
          schoolCode: 'SCH-1001',
        );

        expect(skills.length, 6);
        expect(skills.every((s) => s.hasSufficientEvidence), isTrue);

        final activities = await repository.getStudentActivities(
          studentId: 'stu_sami_01',
          classId: 'cls_grade6_a',
          teacherId: 'teacher_default',
          schoolCode: 'SCH-1001',
        );

        expect(activities.length, 3);
        expect(activities[0].type, 'lesson');
      },
    );

    test('6. Handles empty class with 0 students gracefully', () async {
      final emptyStudents = await repository.getClassStudents(
        classId: 'cls_grade8_c',
        teacherId: 'teacher_default',
        schoolCode: 'SCH-1001',
      );

      expect(emptyStudents, isEmpty);
    });

    test(
      '7. Unauthorized access rejection: teacher cannot access other school classes',
      () async {
        final unauthorizedClass = await repository.getClassById(
          classId: 'cls_other_school',
          teacherId: 'teacher_default',
          schoolCode: 'SCH-1001',
        );

        expect(unauthorizedClass, isNull);

        final unauthorizedStudents = await repository.getClassStudents(
          classId: 'cls_other_school',
          teacherId: 'teacher_default',
          schoolCode: 'SCH-1001',
        );

        expect(unauthorizedStudents, isEmpty);
      },
    );
  });
}
