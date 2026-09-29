import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/core/localization/locale_provider.dart';
import 'package:lahjti/features/account/domain/models/account_context.dart';
import 'package:lahjti/features/home/presentation/screens/home_screen.dart';
import 'package:lahjti/features/learning/data/curriculum/starter_curriculum.dart';
import 'package:lahjti/features/learning/data/repositories/local_learning_repository.dart';
import 'package:lahjti/features/learning/domain/models/daily_learning_task.dart';
import 'package:lahjti/features/learning/domain/models/learner_progress.dart';
import 'package:lahjti/features/learning/domain/models/learning_profile.dart';
import 'package:lahjti/features/learning/domain/models/learning_skill.dart';
import 'package:lahjti/features/learning/domain/models/vocabulary_item.dart';
import 'package:lahjti/features/learning/domain/services/daily_learning_plan_engine.dart';
import 'package:lahjti/features/learning/presentation/providers/learning_providers.dart';
import 'package:lahjti/features/learning/presentation/screens/lesson_session_screen.dart';
import 'package:lahjti/features/onboarding/domain/models/age_group.dart';
import 'package:lahjti/features/onboarding/domain/models/onboarding_data.dart';
import 'package:lahjti/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:lahjti/features/placement/domain/models/cefr_level.dart';
import 'package:lahjti/l10n/app_localizations.dart';

void main() {
  group('STEP 24 — Daily Learning Task & Domain Models Tests', () {
    test(
      '1. DailyLearningTask model serializes and deserializes accurately',
      () {
        final now = DateTime(2026, 9, 22);
        final task = DailyLearningTask(
          id: 'task_1',
          titleArabic: 'متابعة الدرس الأول',
          titleEnglish: 'Continue Lesson 1',
          descriptionArabic: 'شرح التحيات الأساسية',
          descriptionEnglish: 'Basic greetings explanation',
          type: DailyLearningTaskType.lesson,
          skill: LearningSkill.speaking,
          estimatedMinutes: 8,
          xpReward: 30,
          completed: false,
          progress: 0.0,
          createdDate: now,
          lessonId: 'lesson_1_1',
          actionRoute: '/learning',
          isForChild: false,
        );

        expect(task.type.iconEmoji, equals('📚'));
        expect(task.localizedTitle(true), equals('متابعة الدرس الأول'));
        expect(task.localizedTitle(false), equals('Continue Lesson 1'));

        final json = task.toJson();
        final fromJson = DailyLearningTask.fromJson(json);

        expect(fromJson.id, equals('task_1'));
        expect(fromJson.type, equals(DailyLearningTaskType.lesson));
        expect(fromJson.xpReward, equals(30));
        expect(fromJson.lessonId, equals('lesson_1_1'));
      },
    );

    test('2. DailyLearningTaskType enum parser handles aliases correctly', () {
      expect(
        DailyLearningTaskType.fromString('vocabulary_review'),
        equals(DailyLearningTaskType.vocabularyReview),
      );
      expect(
        DailyLearningTaskType.fromString('educational_game'),
        equals(DailyLearningTaskType.educationalGame),
      );
      expect(
        DailyLearningTaskType.fromString('game'),
        equals(DailyLearningTaskType.educationalGame),
      );
      expect(
        DailyLearningTaskType.fromString('speaking'),
        equals(DailyLearningTaskType.speaking),
      );
    });
  });

  group('STEP 24 — DailyLearningPlanEngine Deterministic Rules Tests', () {
    const engine = DailyLearningPlanEngine();
    final fixedNow = DateTime(2026, 9, 22, 10, 0);
    final allLessons =
        StarterCurriculum.modules.expand((m) => m.lessons).toList();

    test('3. Incomplete lesson is prioritized as primary recommended task', () {
      final profile = LearningProfile.defaultProfile(
        userId: 'u1',
      ).copyWith(currentLessonId: 'lesson_1_1');
      final progress = LearnerProgress(
        completedLessonIds: const [], // lesson_1_1 incomplete
        inProgressLessonId: 'lesson_1_1',
        lastSessionDate: fixedNow,
      );

      final plan = engine.generatePlan(
        profile: profile,
        progress: progress,
        vocabularyItems: const [],
        availableLessons: allLessons,
        currentTime: fixedNow,
      );

      expect(plan.recommendedTask.type, equals(DailyLearningTaskType.lesson));
      expect(plan.recommendedTask.lessonId, equals('lesson_1_1'));
      expect(plan.recommendedTask.completed, isFalse);
    });

    test(
      '4. Due vocabulary is prioritized when words are due for spaced repetition',
      () {
        final profile = LearningProfile.defaultProfile(
          userId: 'u2',
        ).copyWith(currentLessonId: 'lesson_1_1');
        final progress = LearnerProgress(
          completedLessonIds: const ['lesson_1_1'], // Lesson already completed
          lastSessionDate: fixedNow,
        );
        final dueItems = [
          VocabularyItem(
            id: 'v1',
            term: 'Hello',
            translationArabic: 'مرحباً',
            exampleSentence: 'Hello world',
            exampleTranslationArabic: 'مرحباً بالعالم',
            difficulty: CefrLevel.a1,
            category: 'greetings',
            lastReviewed: fixedNow.subtract(const Duration(days: 2)),
            nextReview: fixedNow.subtract(const Duration(hours: 1)), // Due!
          ),
        ];

        final plan = engine.generatePlan(
          profile: profile,
          progress: progress,
          vocabularyItems: dueItems,
          availableLessons: allLessons,
          currentTime: fixedNow,
        );

        expect(plan.dueVocabularyCount, equals(1));
        expect(
          plan.recommendedTask.type,
          equals(DailyLearningTaskType.vocabularyReview),
        );
      },
    );

    test(
      '5. Weak grammar score (<65) generates targeted grammar practice task',
      () {
        final profile = LearningProfile.defaultProfile(userId: 'u3').copyWith(
          grammarScore: 50, // Weak grammar!
          vocabularyScore: 80,
        );
        final progress = LearnerProgress(
          completedLessonIds: const [],
          lastSessionDate: fixedNow,
        );

        final plan = engine.generatePlan(
          profile: profile,
          progress: progress,
          vocabularyItems: const [],
          availableLessons: allLessons,
          currentTime: fixedNow,
        );

        final hasGrammarTask = plan.tasks.any(
          (t) => t.skill == LearningSkill.grammar,
        );
        expect(hasGrammarTask, isTrue);
      },
    );

    test(
      '6. Strong learner (overallScore >= 80) receives fluency challenge task',
      () {
        final profile = LearningProfile.defaultProfile(userId: 'u4').copyWith(
          overallScore: 88, // Strong performance!
          grammarScore: 85,
          vocabularyScore: 85,
        );
        final progress = LearnerProgress(
          completedLessonIds: const [],
          lastSessionDate: fixedNow,
        );

        final plan = engine.generatePlan(
          profile: profile,
          progress: progress,
          vocabularyItems: const [],
          availableLessons: allLessons,
          isChild: false,
          currentTime: fixedNow,
        );

        final hasFluencyChallenge = plan.tasks.any(
          (t) =>
              t.type == DailyLearningTaskType.conversation &&
              t.estimatedMinutes >= 8,
        );
        expect(hasFluencyChallenge, isTrue);
      },
    );

    test(
      '7. Child Mode (age 6-10) caps task durations and generates educational mini-game',
      () {
        final profile = LearningProfile.defaultProfile(userId: 'kid_1');
        final progress = LearnerProgress(
          completedLessonIds: const [],
          lastSessionDate: fixedNow,
        );

        final plan = engine.generatePlan(
          profile: profile,
          progress: progress,
          vocabularyItems: const [],
          availableLessons: allLessons,
          isChild: true, // Child mode!
          currentTime: fixedNow,
        );

        // All task durations capped to <= 5 minutes for young attention spans
        for (final task in plan.tasks) {
          expect(task.estimatedMinutes, lessThanOrEqualTo(5));
        }

        final hasGameTask = plan.tasks.any(
          (t) => t.type == DailyLearningTaskType.educationalGame,
        );
        expect(hasGameTask, isTrue);
      },
    );

    test(
      '8. School student context incorporates institutional homework tasks',
      () {
        final profile = LearningProfile.defaultProfile(userId: 'school_stu');
        final progress = LearnerProgress(
          completedLessonIds: const [],
          lastSessionDate: fixedNow,
        );
        final schoolTasks = [
          DailyLearningTask(
            id: 'sch_task_1',
            titleArabic: 'واجب الوحدة الأولى من المعلمة سارة',
            titleEnglish: 'Unit 1 Homework from Teacher Sarah',
            descriptionArabic: 'حل تدريبات التحيات المدرسية',
            descriptionEnglish: 'Complete classroom greetings exercises',
            type: DailyLearningTaskType.lesson,
            skill: LearningSkill.speaking,
            estimatedMinutes: 5,
            xpReward: 25,
            createdDate: fixedNow,
            actionRoute: '/student/home',
            isSchoolTask: true,
            schoolCode: 'SCH-1001',
          ),
        ];

        final plan = engine.generatePlan(
          profile: profile,
          progress: progress,
          vocabularyItems: const [],
          availableLessons: allLessons,
          schoolAssignedTasks: schoolTasks,
          accountContext: AccountContext.school,
          currentTime: fixedNow,
        );

        expect(plan.tasks.any((t) => t.id == 'sch_task_1'), isTrue);
        expect(plan.tasks.first.isSchoolTask, isTrue);
      },
    );

    test(
      '9. All completed tasks generate bonus enrichment conversational activity',
      () {
        final profile = LearningProfile.defaultProfile(
          userId: 'u_all_done',
        ).copyWith(
          currentLessonId: 'lesson_1_1',
          grammarScore: 75,
          vocabularyScore: 75,
        );
        final progress = LearnerProgress(
          completedLessonIds: const ['lesson_1_1'],
          lastSessionDate: fixedNow,
        );

        final plan = engine.generatePlan(
          profile: profile,
          progress: progress,
          vocabularyItems: const [], // No due vocab
          availableLessons: allLessons,
          currentTime: fixedNow,
        );

        final hasEnrichment = plan.tasks.any(
          (t) => t.id.startsWith('task_enrichment_'),
        );
        expect(hasEnrichment, isTrue);
      },
    );
  });

  group('STEP 24 — Lesson Session Screen & UI Tests', () {
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
      '10. LessonSessionScreen traverses steps and completes lesson with +30 XP',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestApp(const LessonSessionScreen(lessonId: 'lesson_1_1')),
        );
        await tester.pumpAndSettle();

        // Verify header & title
        expect(find.text('التحية والتعريف بالاسم'), findsOneWidget);
        expect(find.text('الخطوة 1 من 3'), findsOneWidget);

        // Tap Next to advance to Step 2
        expect(
          find.byKey(const Key('lesson_session_next_btn')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('lesson_session_next_btn')));
        await tester.pumpAndSettle();

        expect(find.text('الخطوة 2 من 3'), findsOneWidget);

        // Tap Next to advance to Step 3
        await tester.tap(find.byKey(const Key('lesson_session_next_btn')));
        await tester.pumpAndSettle();

        expect(find.text('الخطوة 3 من 3'), findsOneWidget);

        // Tap Complete Lesson on the final step
        await tester.tap(find.byKey(const Key('lesson_session_next_btn')));
        await tester.pumpAndSettle();

        // Verify Celebration screen
        expect(find.text('أحسنت! أكملت الدرس بنجاح'), findsOneWidget);
        expect(find.text('+30 XP'), findsOneWidget);
        expect(
          find.byKey(const Key('lesson_session_return_home_btn')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '11. HomeScreen renders greeting, tutor badge, continue learning CTA, and daily tasks in Arabic',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestApp(const HomeScreen()));
        await tester.pumpAndSettle();

        // Verify personalized greeting & tutor
        expect(find.textContaining('مرحباً يا'), findsOneWidget);
        expect(find.textContaining('معلمك:'), findsOneWidget);

        // Verify Continue Learning button
        expect(
          find.byKey(const Key('continue_learning_hero_btn')),
          findsOneWidget,
        );
        expect(find.text('متابعة التعلم ➔'), findsOneWidget);

        // Verify Daily Tasks header
        expect(find.text('مهام اليوم التعليمية'), findsOneWidget);

        // Verify floating tutor call action
        expect(find.byKey(const Key('home_tutor_fab_btn')), findsOneWidget);
      },
    );

    testWidgets('12. HomeScreen renders English LTR layout properly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(const HomeScreen(), locale: const Locale('en')),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Welcome,'), findsOneWidget);
      expect(find.textContaining('Tutor:'), findsOneWidget);
      expect(find.text("Today's Learning Tasks"), findsOneWidget);
      expect(find.text('Continue Learning ➔'), findsOneWidget);
    });

    testWidgets(
      '13. HomeScreen renders Child Mode banner when learner is in age 6-10 bracket',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestApp(
            const HomeScreen(),
            overrides: [
              onboardingProvider.overrideWith(
                (ref) => OnboardingNotifier(
                  initialState: const OnboardingState(
                    data: OnboardingData(
                      ageGroup: AgeGroup.age6_10,
                      registeredName: 'سامي',
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('وضع الأطفال التفاعلي'), findsOneWidget);
      },
    );
  });
}
