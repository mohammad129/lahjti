import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/school/domain/models/school.dart';
import 'package:lahjti/features/school/domain/models/school_role.dart';
import 'package:lahjti/features/school/domain/models/school_student_profile.dart';
import 'package:lahjti/features/school/domain/models/teacher_profile.dart';

void main() {
  group('School Domain Models Tests', () {
    test('1. SchoolRole enum properties and parser', () {
      expect(SchoolRole.values.length, 2);
      expect(SchoolRole.student.isStudent, isTrue);
      expect(SchoolRole.student.isTeacher, isFalse);
      expect(SchoolRole.teacher.isStudent, isFalse);
      expect(SchoolRole.teacher.isTeacher, isTrue);

      expect(SchoolRole.fromString('student'), SchoolRole.student);
      expect(SchoolRole.fromString('TEACHER'), SchoolRole.teacher);
      expect(SchoolRole.fromString('invalid'), isNull);
      expect(SchoolRole.fromString(null), isNull);
    });

    test('2. School entity properties and serialization', () {
      final now = DateTime(2026, 9, 21);
      final school = School(
        id: 'sch_1',
        name: 'Amman International School',
        code: 'AMMAN-2026',
        city: 'Amman',
        country: 'Jordan',
        isActive: true,
        createdAt: now,
      );

      expect(school.id, 'sch_1');
      expect(school.name, 'Amman International School');
      expect(school.code, 'AMMAN-2026');
      expect(school.isActive, isTrue);

      final json = school.toJson();
      expect(json['code'], 'AMMAN-2026');
      expect(json['name'], 'Amman International School');

      final reconstructed = School.fromJson(json);
      expect(reconstructed.id, school.id);
      expect(reconstructed.code, school.code);
    });

    test('3. SchoolStudentProfile properties and serialization', () {
      final now = DateTime(2026, 9, 21);
      final profile = SchoolStudentProfile(
        studentId: 'stu_1',
        fullName: 'Sami Ahmad',
        schoolId: 'sch_1',
        schoolCode: 'AMMAN-2026',
        schoolName: 'Amman International School',
        grade: 'Grade 10',
        classSection: 'Section B',
        enrolledAt: now,
      );

      expect(profile.studentId, 'stu_1');
      expect(profile.fullName, 'Sami Ahmad');
      expect(profile.grade, 'Grade 10');
      expect(profile.classSection, 'Section B');

      final json = profile.toJson();
      expect(json['grade'], 'Grade 10');
      expect(json['classSection'], 'Section B');

      final reconstructed = SchoolStudentProfile.fromJson(json);
      expect(reconstructed.schoolCode, profile.schoolCode);
      expect(reconstructed.grade, profile.grade);
    });

    test('4. TeacherProfile properties and serialization', () {
      final now = DateTime(2026, 9, 21);
      final teacher = TeacherProfile(
        teacherId: 'tch_1',
        fullName: 'Prof. Ahmad',
        email: 'ahmad@school.edu',
        schoolId: 'sch_1',
        schoolCode: 'AMMAN-2026',
        schoolName: 'Amman International School',
        subjectTaught: 'English Conversation',
        gradesTaught: ['Grade 9', 'Grade 10', 'Grade 11'],
        createdAt: now,
      );

      expect(teacher.teacherId, 'tch_1');
      expect(teacher.fullName, 'Prof. Ahmad');
      expect(teacher.email, 'ahmad@school.edu');
      expect(teacher.subjectTaught, 'English Conversation');
      expect(teacher.gradesTaught.length, 3);

      final json = teacher.toJson();
      expect(json['subjectTaught'], 'English Conversation');
      expect(json['gradesTaught'], contains('Grade 9'));

      final reconstructed = TeacherProfile.fromJson(json);
      expect(reconstructed.fullName, teacher.fullName);
      expect(reconstructed.subjectTaught, teacher.subjectTaught);
    });
  });
}
