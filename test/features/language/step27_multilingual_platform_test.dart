import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/learning/domain/models/learner_context.dart';
import 'package:lahjti/features/learning/domain/models/learning_skill.dart';
import 'package:lahjti/features/onboarding/domain/models/supported_language.dart';
import 'package:lahjti/features/onboarding/domain/models/target_language.dart';
import 'package:lahjti/features/onboarding/domain/models/tutor_persona.dart';
import 'package:lahjti/features/placement/domain/models/cefr_level.dart';
import 'package:lahjti/features/school/data/repositories/in_memory_student_dashboard_repository.dart';
import 'package:lahjti/features/school/domain/models/game_models.dart';

void main() {
  group('STEP 27 — Production Multilingual Platform & TargetLanguage Tests', () {
    // 1. TargetLanguage Single Source of Truth
    test(
      '1. TargetLanguage defines code, name, nativeName, locale, and supported status',
      () {
        const en = SupportedLanguage.english;
        expect(en.code, 'en');
        expect(en.name, 'English');
        expect(en.nativeName, 'الإنجليزية');
        expect(en.locale, 'en_US');
        expect(en.supported, isTrue);

        const es = SupportedLanguage.spanish;
        expect(es.code, 'es');
        expect(es.name, 'Spanish');
        expect(es.nativeName, 'الإسبانية');
        expect(es.locale, 'es_ES');
        expect(es.supported, isTrue);

        final fr = SupportedLanguage.fromCode('fr');
        expect(fr, isNotNull);
        expect(fr!.code, 'fr');
        expect(fr.locale, 'fr_FR');

        final de = SupportedLanguage.fromCode('de');
        expect(de, isNotNull);
        expect(de!.code, 'de');
        expect(de.locale, 'de_DE');

        final ar = SupportedLanguage.fromCode('ar');
        expect(ar, isNotNull);
        expect(ar!.code, 'ar');
        expect(ar.locale, 'ar_SA');

        final jo = SupportedLanguage.fromCode('jo');
        expect(jo, isNotNull);
        expect(jo!.code, 'jo');
        expect(jo.locale, 'ar_JO');
      },
    );

    // 2. TargetLanguage typedef & fallback
    test('2. TargetLanguage typedef aliases SupportedLanguage seamlessly', () {
      TargetLanguage lang = SupportedLanguage.english;
      expect(lang.code, 'en');
      expect(lang.flagEmoji, '🇬🇧');

      final custom = TargetLanguage.fromCode('it');
      expect(custom?.locale, 'it_IT');
    });

    // 3. Abbas & Dunya Multilingual Personas
    test(
      '3. Abbas and Dunya personas are defined as universal multilingual language coaches',
      () {
        final abbas = TutorPersona.tutors.firstWhere((t) => t.id == 'abbas');
        expect(abbas.id, 'abbas');
        expect(abbas.nameEn, 'Abbas');
        expect(abbas.avatarEmoji, '👨‍🏫');
        expect(abbas.traitsEn, contains('Energetic'));
        expect(abbas.traitsEn, contains('Witty'));

        final dunya = TutorPersona.tutors.firstWhere((t) => t.id == 'dunya');
        expect(dunya.id, 'dunya');
        expect(dunya.nameEn, 'Dunya');
        expect(dunya.avatarEmoji, '👩‍🏫');
        expect(dunya.traitsEn, contains('Warm'));
        expect(dunya.traitsEn, contains('Patient'));
      },
    );

    // 4. LearnerContext target language routing
    test(
      '4. LearnerContext accepts configurable target language without dialect lock-in',
      () {
        const contextEn = LearnerContext(
          targetLanguage: 'english',
          nativeLanguage: 'arabic',
          ageGroup: 'adult',
          cefrLevel: CefrLevel.b1,
          learningGoal: 'conversation',
          experienceLevel: 'intermediate',
          tutorPersona: 'abbas',
        );

        expect(contextEn.targetLanguage, 'english');
        expect(contextEn.nativeLanguage, 'arabic');

        const contextEs = LearnerContext(
          targetLanguage: 'spanish',
          nativeLanguage: 'english',
          ageGroup: 'teen',
          cefrLevel: CefrLevel.a2,
          learningGoal: 'travel',
          experienceLevel: 'beginner',
          tutorPersona: 'dunya',
        );

        expect(contextEs.targetLanguage, 'spanish');
        expect(contextEs.nativeLanguage, 'english');
      },
    );

    // 5. Educational Games Catalog Verification
    test(
      '5. Educational games catalog includes all 5 core games with dual localized content',
      () async {
        final repo = InMemoryStudentDashboardRepository();
        final games = await repo.getAvailableGames(
          studentId: 'student_001',
          schoolCode: 'SCH_001',
        );

        expect(games.length, greaterThanOrEqualTo(5));

        final types = games.map((g) => g.gameType).toSet();
        expect(types, contains(GameType.wordMatch));
        expect(types, contains(GameType.listenAndChoose));
        expect(types, contains(GameType.sentenceBuilder));
        expect(types, contains(GameType.memoryVocab));
        expect(types, contains(GameType.pictureWordSelect));

        for (final game in games) {
          expect(game.titleArabic, isNotEmpty);
          expect(game.titleEnglish, isNotEmpty);
          expect(game.questions, isNotEmpty);
          expect(game.xpReward, greaterThan(0));
        }
      },
    );

    // 6. Game Answer Evaluation & XP Reward
    test(
      '6. Game play submits answer, awards XP, and tracks pass status',
      () async {
        final repo = InMemoryStudentDashboardRepository();
        final result = await repo.submitGameResult(
          studentId: 'student_001',
          schoolCode: 'SCH_001',
          result: GameResult(
            gameId: 'game_word_match',
            gameType: GameType.wordMatch,
            totalQuestions: 4,
            correctAnswers: 4,
            scorePercentage: 100.0,
            earnedXp: 30,
            completedAt: DateTime.now(),
            passed: true,
            skill: LearningSkill.vocabulary,
          ),
        );

        expect(result.passed, isTrue);
        expect(result.earnedXp, 30);
        expect(result.scorePercentage, 100.0);
      },
    );
  });
}
