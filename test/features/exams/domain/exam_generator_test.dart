import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/exams/domain/models/exam_models.dart';
import 'package:lahjti/features/exams/domain/services/exam_generator.dart';
import 'package:lahjti/features/learning/domain/models/learning_skill.dart';
import 'package:lahjti/features/onboarding/domain/models/age_group.dart';
import 'package:lahjti/features/placement/domain/models/cefr_level.dart';

void main() {
  group('ExamGenerator Tests', () {
    const generator = ExamGenerator();

    test('1. Generates Month 1 Milestone Exam with all 6 core skills', () {
      final exam = generator.generateMonth1MilestoneExam(
        targetLanguage: 'en',
        cefrLevel: CefrLevel.a1,
        ageGroup: AgeGroup.age19_25,
      );

      expect(exam.type, ExamType.monthlyMilestone);
      expect(exam.month, 1);
      expect(exam.sections.isNotEmpty, isTrue);
      expect(exam.totalQuestions, inInclusiveRange(4, 15));
      expect(exam.estimatedMinutes, inInclusiveRange(8, 20));

      final coveredSkills = exam.sections.map((s) => s.skill).toSet();
      expect(coveredSkills.contains(LearningSkill.vocabulary), isTrue);
      expect(coveredSkills.contains(LearningSkill.grammar), isTrue);
      expect(coveredSkills.contains(LearningSkill.reading), isTrue);
      expect(coveredSkills.contains(LearningSkill.listening), isTrue);
      expect(coveredSkills.contains(LearningSkill.speaking), isTrue);
      expect(coveredSkills.contains(LearningSkill.fluency), isTrue);
    });

    test('2. Generates Month 2 & Month 3 Milestone Exams', () {
      final examM2 = generator.generateMonth2MilestoneExam(
        targetLanguage: 'en',
        cefrLevel: CefrLevel.a2,
        ageGroup: AgeGroup.age19_25,
      );
      expect(examM2.type, ExamType.monthlyMilestone);
      expect(examM2.month, 2);
      expect(examM2.totalQuestions, greaterThanOrEqualTo(1));

      final examM3 = generator.generateMonth3MilestoneExam(
        targetLanguage: 'en',
        cefrLevel: CefrLevel.b1,
        ageGroup: AgeGroup.age19_25,
      );
      expect(examM3.type, ExamType.monthlyMilestone);
      expect(examM3.month, 3);
      expect(examM3.totalQuestions, greaterThanOrEqualTo(1));
    });

    test('3. Generates Skill Checkpoint exams focused on specific skill', () {
      final speakingCheckpoint = generator.generateSkillCheckpointExam(
        skill: LearningSkill.speaking,
        targetLanguage: 'en',
        cefrLevel: CefrLevel.a1,
        ageGroup: AgeGroup.age19_25,
      );
      expect(speakingCheckpoint.type, ExamType.skillCheckpoint);
      expect(speakingCheckpoint.sections.length, 1);
      expect(speakingCheckpoint.sections.first.skill, LearningSkill.speaking);
    });

    test('4. Generates exams across different target languages', () {
      final supportedLangs = [
        'en',
        'es',
        'fr',
        'de',
        'it',
        'tr',
        'ja',
        'zh',
        'ko',
      ];
      for (final lang in supportedLangs) {
        final exam = generator.generateMonth1MilestoneExam(
          targetLanguage: lang,
          cefrLevel: CefrLevel.a1,
          ageGroup: AgeGroup.age19_25,
        );
        expect(exam.targetLanguage, lang);
        expect(exam.sections.isNotEmpty, isTrue);
      }
    });

    test('5. Age adaptation for children vs adults', () {
      final childExam = generator.generateMonth1MilestoneExam(
        targetLanguage: 'en',
        cefrLevel: CefrLevel.a1,
        ageGroup: AgeGroup.age6_10,
      );

      final adultExam = generator.generateMonth1MilestoneExam(
        targetLanguage: 'en',
        cefrLevel: CefrLevel.a1,
        ageGroup: AgeGroup.age19_25,
      );

      expect(
        childExam.estimatedMinutes,
        lessThanOrEqualTo(adultExam.estimatedMinutes),
      );
      expect(childExam.sections.isNotEmpty, isTrue);
    });

    test('6. Generates available standard exam catalog', () {
      final catalog = generator.generateAvailableExams(
        targetLanguage: 'en',
        cefrLevel: CefrLevel.a1,
        ageGroup: AgeGroup.age19_25,
      );

      expect(catalog.length, greaterThanOrEqualTo(4));
      expect(catalog.any((e) => e.month == 1), isTrue);
      expect(catalog.any((e) => e.month == 2), isTrue);
      expect(catalog.any((e) => e.month == 3), isTrue);
    });
  });
}
