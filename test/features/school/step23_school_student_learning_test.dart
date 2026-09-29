import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/core/localization/locale_provider.dart';
import 'package:lahjti/features/learning/data/repositories/local_learning_repository.dart';
import 'package:lahjti/features/learning/domain/models/learner_progress.dart';
import 'package:lahjti/features/learning/domain/models/learning_profile.dart';
import 'package:lahjti/features/learning/domain/models/learning_skill.dart';
import 'package:lahjti/features/learning/domain/models/lesson_models.dart';
import 'package:lahjti/features/learning/domain/models/vocabulary_item.dart';
import 'package:lahjti/features/learning/presentation/providers/learning_providers.dart';
import 'package:lahjti/features/onboarding/domain/models/age_group.dart';
import 'package:lahjti/features/onboarding/domain/models/onboarding_data.dart';
import 'package:lahjti/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:lahjti/features/placement/domain/models/cefr_level.dart';
import 'package:lahjti/features/school/domain/models/daily_task.dart';
import 'package:lahjti/features/school/domain/models/game_models.dart';
import 'package:lahjti/features/school/domain/models/school_student_profile.dart';
import 'package:lahjti/features/school/domain/services/daily_task_engine.dart';
import 'package:lahjti/features/school/presentation/providers/student_providers.dart';
import 'package:lahjti/features/school/presentation/screens/student_progress_screen.dart';
import 'package:lahjti/features/school/presentation/screens/student_school_home_screen.dart';
import 'package:lahjti/l10n/app_localizations.dart';

void main() {
  group('STEP 23 — School Student Daily Task Domain Models Tests', () {
    test(
      '1. DailyTask model serializes and deserializes accurately with status and progress',
      () {
        final now = DateTime(2026, 9, 22, 10, 0);
        final task = DailyTask(
          id: 'task_school_01',
          titleArabic: 'تحدي القواعد المدرسية',
          titleEnglish: 'School Grammar Challenge',
          descriptionArabic: 'تدريب على تراكيب الجمل',
          descriptionEnglish: 'Practice sentence structure',
          type: DailyTaskType.grammar,
          skill: LearningSkill.grammar,
          difficulty: 'intermediate',
          estimatedMinutes: 6,
          xpReward: 25,
          completed: false,
          status: DailyTaskStatus.inProgress,
          progress: 0.5,
          dueDate: now,
          actionRoute: '/student/games/game_sentence_builder',
          isForChild: false,
        );

        final json = task.toJson();
        expect(json['id'], 'task_school_01');
        expect(json['type'], 'grammar');
        expect(json['status'], 'inProgress');
        expect(json['difficulty'], 'intermediate');

        final fromJson = DailyTask.fromJson(json);
        expect(fromJson.id, task.id);
        expect(fromJson.type, DailyTaskType.grammar);
        expect(fromJson.status, DailyTaskStatus.inProgress);
        expect(fromJson.difficulty, 'intermediate');
        expect(fromJson.progress, 0.5);
      },
    );

    test(
      '2. DailyTaskProgress computes completed ratio and total minutes correctly',
      () {
        final tasks = [
          DailyTask(
            id: 't1',
            titleArabic: 'المهمة 1',
            titleEnglish: 'Task 1',
            descriptionArabic: 'وصف 1',
            descriptionEnglish: 'Desc 1',
            type: DailyTaskType.lesson,
            skill: LearningSkill.speaking,
            estimatedMinutes: 5,
            xpReward: 30,
            completed: true,
            status: DailyTaskStatus.completed,
            dueDate: DateTime.now(),
            actionRoute: '/learning',
          ),
          DailyTask(
            id: 't2',
            titleArabic: 'المهمة 2',
            titleEnglish: 'Task 2',
            descriptionArabic: 'وصف 2',
            descriptionEnglish: 'Desc 2',
            type: DailyTaskType.vocabulary,
            skill: LearningSkill.vocabulary,
            estimatedMinutes: 5,
            xpReward: 20,
            completed: false,
            status: DailyTaskStatus.pending,
            dueDate: DateTime.now(),
            actionRoute: '/vocabulary/practice',
          ),
        ];

        final progress = DailyTaskProgress.fromTasks(tasks);
        expect(progress.totalTasks, 2);
        expect(progress.completedTasks, 1);
        expect(progress.estimatedTotalMinutes, 10);
        expect(progress.earnedXpToday, 30);
        expect(progress.completionPercentage, 50.0);
      },
    );

    test(
      '3. GameType aliases and GameResult with taskId and vocabularyIds',
      () {
        expect(GameType.listeningChoice, GameType.listenAndChoose);
        expect(
          GameType.fromString('listeningChoice'),
          GameType.listenAndChoose,
        );
        expect(
          GameType.fromString('pictureWordSelect'),
          GameType.pictureWordSelect,
        );

        final result = GameResult(
          gameId: 'game_word_match',
          taskId: 'task_game_01',
          gameType: GameType.wordMatch,
          totalQuestions: 5,
          correctAnswers: 4,
          scorePercentage: 80.0,
          earnedXp: 25,
          completedAt: DateTime.now(),
          passed: true,
          vocabularyIds: const ['v1', 'v2'],
        );

        expect(result.incorrectAnswers, 1);
        expect(result.vocabularyIds.length, 2);

        final json = result.toJson();
        final fromJson = GameResult.fromJson(json);
        expect(fromJson.gameId, 'game_word_match');
        expect(fromJson.taskId, 'task_game_01');
        expect(fromJson.incorrectAnswers, 1);
      },
    );
  });

  group('STEP 23 — DailyTaskEngine Deterministic Decision Rules Tests', () {
    const engine = DailyTaskEngine();
    final fixedNow = DateTime(2026, 9, 22, 10, 0);

    final lesson1 = Lesson(
      id: 'lesson_1_1',
      moduleId: 'mod_1',
      month: 1,
      order: 1,
      title: 'Greetings & Introductions',
      titleArabic: 'التحية والتعارف',
      description: 'Learn greeting words',
      descriptionArabic: 'تعلم كلمات التحية والتعارف',
      cefrLevel: CefrLevel.a1,
      primarySkill: LearningSkill.speaking,
      estimatedMinutes: 8,
      steps: const [],
    );

    final dueVocab = VocabularyItem(
      id: 'vocab_due_1',
      term: 'Marhaban',
      translationArabic: 'مرحباً',
      exampleSentence: 'Marhaban bika',
      exampleTranslationArabic: 'مرحباً بك',
      difficulty: CefrLevel.a1,
      category: 'greetings',
      nextReview: fixedNow.subtract(const Duration(hours: 2)),
    );

    test('4. Incomplete lesson is prioritized as recommended task', () {
      final profile = LearningProfile.defaultProfile(
        userId: 'student_01',
      ).copyWith(currentLessonId: 'lesson_1_1', overallScore: 70);
      final progress = LearnerProgress(
        completedLessonIds: const [],
        lastSessionDate: fixedNow,
      ); // 0 completed lessons

      final plan = engine.generatePlan(
        profile: profile,
        progress: progress,
        vocabularyList: const [],
        availableLessons: [lesson1],
        isChild: false,
        currentDate: fixedNow,
      );

      expect(plan.recommendedTask.type, DailyTaskType.lesson);
      expect(plan.recommendedTask.lessonId, 'lesson_1_1');
      expect(plan.recommendedTask.completed, isFalse);
    });

    test('5. Spaced vocabulary review is included when vocabulary is due', () {
      final profile = LearningProfile.defaultProfile(
        userId: 'student_01',
      ).copyWith(currentLessonId: 'lesson_1_1');
      final progress = LearnerProgress(
        completedLessonIds: const ['lesson_1_1'],
        lastSessionDate: fixedNow,
      );

      final plan = engine.generatePlan(
        profile: profile,
        progress: progress,
        vocabularyList: [dueVocab],
        availableLessons: [lesson1],
        isChild: false,
        currentDate: fixedNow,
      );

      expect(plan.dueVocabularyCount, 1);
      final hasVocabTask = plan.tasks.any(
        (t) => t.type == DailyTaskType.vocabulary,
      );
      expect(hasVocabTask, isTrue);
    });

    test(
      '6. Weak grammar (<65) assigns targeted sentence builder grammar task',
      () {
        final profile = LearningProfile.defaultProfile(
          userId: 'student_01',
        ).copyWith(currentLessonId: 'lesson_1_1', grammarScore: 50);
        final progress = LearnerProgress(
          completedLessonIds: const ['lesson_1_1'],
          lastSessionDate: fixedNow,
        );

        final plan = engine.generatePlan(
          profile: profile,
          progress: progress,
          vocabularyList: const [],
          availableLessons: [lesson1],
          isChild: false,
          currentDate: fixedNow,
        );

        final grammarTask = plan.tasks.firstWhere(
          (t) => t.id == 'task_adaptive_grammar',
        );
        expect(grammarTask.type, DailyTaskType.grammar);
        expect(grammarTask.gameId, 'game_sentence_builder');
      },
    );

    test(
      '7. Strong learner (overallScore >= 80) receives advanced fluency challenge',
      () {
        final profile = LearningProfile.defaultProfile(
          userId: 'student_01',
        ).copyWith(
          currentLessonId: 'lesson_1_1',
          overallScore: 88,
          grammarScore: 85,
          listeningScore: 90,
        );
        final progress = LearnerProgress(
          completedLessonIds: const ['lesson_1_1'],
          lastSessionDate: fixedNow,
        );

        final plan = engine.generatePlan(
          profile: profile,
          progress: progress,
          vocabularyList: const [],
          availableLessons: [lesson1],
          isChild: false,
          currentDate: fixedNow,
        );

        final hasChallenge = plan.tasks.any(
          (t) => t.id == 'task_adaptive_strong_challenge',
        );
        expect(hasChallenge, isTrue);
      },
    );

    test(
      '8. Child Mode (age 6-10) enforces short durations and child-friendly task flags',
      () {
        final profile = LearningProfile.defaultProfile(
          userId: 'child_01',
        ).copyWith(currentLessonId: 'lesson_1_1');
        final progress = LearnerProgress(lastSessionDate: fixedNow);

        final plan = engine.generatePlan(
          profile: profile,
          progress: progress,
          vocabularyList: const [],
          availableLessons: [lesson1],
          isChild: true,
          currentDate: fixedNow,
        );

        for (final task in plan.tasks) {
          expect(task.isForChild, isTrue);
          expect(task.estimatedMinutes, lessThanOrEqualTo(6));
        }
      },
    );

    test(
      '9. All completed tasks trigger enrichment conversational activity',
      () {
        final profile = LearningProfile.defaultProfile(
          userId: 'student_01',
        ).copyWith(
          currentLessonId: 'lesson_1_1',
          overallScore: 75,
          grammarScore: 75,
          listeningScore: 80,
        );
        final progress = LearnerProgress(
          completedLessonIds: const ['lesson_1_1'],
          lastSessionDate: fixedNow,
        );

        final plan = engine.generatePlan(
          profile: profile,
          progress: progress,
          vocabularyList: const [],
          availableLessons: [lesson1],
          isChild: false,
          completedTaskIds: const [
            'task_lesson_completed_lesson_1_1',
            'task_vocab_daily',
            'task_adaptive_speaking',
            'task_game_word_match',
          ],
          currentDate: fixedNow,
        );

        final hasEnrichment = plan.tasks.any(
          (t) => t.id == 'task_enrichment_convo',
        );
        expect(hasEnrichment, isTrue);
      },
    );
  });

  group('STEP 23 — Student School Home & Progress UI Tests', () {
    Widget buildTestApp(
      Widget child, {
      Locale locale = const Locale('ar'),
      List<Override> overrides = const [],
    }) {
      return ProviderScope(
        overrides: [
          localeProvider.overrideWith((ref) {
            final notifier = LocaleNotifier();
            notifier.setLocale(locale);
            return notifier;
          }),
          learningRepositoryProvider.overrideWithValue(
            LocalLearningRepository(),
          ),
          currentSchoolStudentProfileProvider.overrideWith((ref) {
            return SchoolStudentProfile(
              studentId: 'stu_sami_01',
              fullName: 'سامي الأحمد',
              schoolId: 'SCH-1001',
              schoolCode: 'SCH-1001',
              schoolName: 'مدرسة النور الأهلية',
              grade: 'الصف السادس',
              classSection: 'أ',
              ageGroup: AgeGroup.age11_15,
              enrolledAt: DateTime(2026, 1, 1),
            );
          }),
          ...overrides,
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      );
    }

    testWidgets(
      '10. StudentSchoolHomeScreen renders greeting, continue CTA, and daily tasks in Arabic',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestApp(const StudentSchoolHomeScreen()));
        await tester.pumpAndSettle();

        expect(find.textContaining('سامي'), findsWidgets);
        expect(find.textContaining('مدرسة النور الأهلية'), findsWidgets);
        expect(
          find.byKey(const Key('student_home_continue_cta_btn')),
          findsOneWidget,
        );
        expect(find.text('متابعة التعلم'), findsOneWidget);
        expect(find.text('ألعاب تعليمية'), findsOneWidget);
        expect(find.text('لوحة التقدم'), findsOneWidget);
      },
    );

    testWidgets(
      '11. StudentSchoolHomeScreen renders English LTR layout properly',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestApp(
            const StudentSchoolHomeScreen(),
            locale: const Locale('en'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Continue Learning'), findsOneWidget);
        expect(find.text('Educational Games'), findsOneWidget);
        expect(find.text('Progress Hub'), findsOneWidget);
      },
    );

    testWidgets(
      '12. StudentSchoolHomeScreen renders Child Mode banner when student is age 6-10',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestApp(
            const StudentSchoolHomeScreen(),
            overrides: [
              onboardingProvider.overrideWith((ref) {
                return OnboardingNotifier(
                  initialState: OnboardingState(
                    data: OnboardingData(ageGroup: AgeGroup.age6_10),
                  ),
                );
              }),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('وضع الأطفال'), findsOneWidget);
      },
    );

    testWidgets(
      '13. StudentProgressScreen renders student identity, level, skills, and achievements',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestApp(const StudentProgressScreen()));
        await tester.pumpAndSettle();

        expect(find.text('لوحة تقدم الطالب'), findsOneWidget);
        expect(find.text('مستوى المهارات اللغوية'), findsOneWidget);
        expect(find.text('الأوسمة والإنجازات'), findsOneWidget);
        expect(find.text('الدروس المكتملة'), findsOneWidget);
        expect(find.text('المفردات المتقنة'), findsOneWidget);
      },
    );
  });
}
