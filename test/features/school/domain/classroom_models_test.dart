import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/learning/domain/models/learning_skill.dart';
import 'package:lahjti/features/school/domain/models/classroom_models.dart';

void main() {
  group('Classroom & Teacher Dashboard Domain Models Tests', () {
    test('1. Classroom model properties and serialization', () {
      final now = DateTime(2026, 9, 21);
      final classroom = Classroom(
        id: 'cls_1',
        schoolCode: 'SCH-1001',
        name: 'الصف السادس - أ',
        grade: 'الصف السادس',
        section: 'أ',
        teacherId: 't_01',
        active: true,
        createdAt: now,
      );

      expect(classroom.id, 'cls_1');
      expect(classroom.displayName, 'الصف السادس - أ');
      expect(classroom.active, isTrue);

      final json = classroom.toJson();
      expect(json['id'], 'cls_1');
      expect(json['schoolCode'], 'SCH-1001');

      final reconstructed = Classroom.fromJson(json);
      expect(reconstructed.id, classroom.id);
      expect(reconstructed.name, classroom.name);
    });

    test('2. ClassroomStudent privacy-safe visible name formatting', () {
      final now = DateTime(2026, 9, 21);
      final studentFull = ClassroomStudent(
        studentId: 'stu_1',
        classId: 'cls_1',
        schoolCode: 'SCH-1001',
        fullName: 'سامي عبد الله عواد',
        joinedAt: now,
      );

      expect(studentFull.visibleName, 'سامي ع.');

      final studentSingle = ClassroomStudent(
        studentId: 'stu_2',
        classId: 'cls_1',
        schoolCode: 'SCH-1001',
        fullName: 'سامي',
        joinedAt: now,
      );
      expect(studentSingle.visibleName, 'سامي');
    });

    test('3. TeacherOverviewData empty factory', () {
      final empty = TeacherOverviewData.empty();
      expect(empty.totalStudents, 0);
      expect(empty.activeTodayCount, 0);
      expect(empty.hasSufficientData, isFalse);
    });

    test('4. StudentSkillSummary properties', () {
      const skill = StudentSkillSummary(
        skill: LearningSkill.speaking,
        score: 85,
        assessedAttempts: 4,
        hasSufficientEvidence: true,
      );

      expect(skill.skill, LearningSkill.speaking);
      expect(skill.score, 85);
      expect(skill.hasSufficientEvidence, isTrue);
    });

    test('5. StudentActivitySummary properties', () {
      final now = DateTime(2026, 9, 21);
      final activity = StudentActivitySummary(
        id: 'act_01',
        title: 'درس المحادثة',
        type: 'lesson',
        timestamp: now,
        details: 'إتمام بنجاح',
      );

      expect(activity.id, 'act_01');
      expect(activity.type, 'lesson');
      expect(activity.details, 'إتمام بنجاح');
    });
  });
}
