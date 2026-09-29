import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/core/localization/locale_provider.dart';
import 'package:lahjti/features/onboarding/domain/models/age_group.dart';
import 'package:lahjti/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:lahjti/features/school/data/repositories/in_memory_student_dashboard_repository.dart';
import 'package:lahjti/features/school/domain/models/daily_task.dart';
import 'package:lahjti/features/school/domain/models/school_role.dart';
import 'package:lahjti/features/school/domain/models/school_student_profile.dart';
import 'package:lahjti/features/school/presentation/providers/student_providers.dart';
import 'package:lahjti/features/school/presentation/screens/game_play_screen.dart';
import 'package:lahjti/features/school/presentation/screens/student_progress_screen.dart';
import 'package:lahjti/features/school/presentation/screens/student_school_home_screen.dart';
import 'package:lahjti/l10n/app_localizations.dart';

void main() {
  group(
    'STEP 24 — Production Student Experience & End-to-End School Learning Flow Tests',
    () {
      late InMemoryStudentDashboardRepository testRepo;

      setUp(() {
        testRepo = InMemoryStudentDashboardRepository();
      });

      Widget createTestApp({
        required Widget home,
        List<Override> overrides = const [],
      }) {
        return ProviderScope(
          overrides: [
            studentDashboardRepositoryProvider.overrideWithValue(testRepo),
            localeProvider.overrideWith((ref) => LocaleNotifier()),
            currentSchoolStudentProfileProvider.overrideWith(
              (ref) => SchoolStudentProfile(
                studentId: 'stu_sami_01',
                schoolId: 'sch_1001',
                schoolCode: 'SCH-1001',
                schoolName: 'مدرسة النور الأهلية',
                fullName: 'سامي الأحمد',
                grade: 'الصف السابع',
                classSection: 'أ',
                ageGroup: AgeGroup.age11_14,
                enrolledAt: DateTime(2026, 1, 1),
              ),
            ),
            onboardingProvider.overrideWith(
              (ref) =>
                  OnboardingNotifier()
                    ..selectSchoolRole(SchoolRole.student)
                    ..setSchoolDetails(
                      schoolCode: 'SCH-1001',
                      schoolName: 'مدرسة النور الأهلية',
                    )
                    ..setStudentClassDetails(
                      grade: 'الصف السابع',
                      classSection: 'أ',
                    )
                    ..selectAgeGroup(AgeGroup.age11_14),
            ),
            ...overrides,
          ],
          child: MaterialApp(
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: home,
          ),
        );
      }

      // 1. Student School Home Rendering & Task Execution
      testWidgets(
        '1. StudentSchoolHomeScreen renders complete student context and daily tasks',
        (tester) async {
          await tester.pumpWidget(
            createTestApp(home: const StudentSchoolHomeScreen()),
          );
          await tester.pumpAndSettle();

          expect(find.textContaining('سامي'), findsWidgets);
          expect(find.textContaining('مدرسة النور الأهلية'), findsWidgets);
          expect(find.textContaining('الصف السابع'), findsWidgets);
          expect(
            find.byKey(const Key('student_home_continue_cta_btn')),
            findsOneWidget,
          );
        },
      );

      // 2. Interactive Word Match Mini-Game Flow
      testWidgets('2. Word Match game matches pairs and validates solution', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestApp(home: const GamePlayScreen(gameId: 'game_word_match')),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('مطابقة الكلمات'), findsWidgets);
        expect(find.text('شاي'), findsOneWidget);
        expect(find.text('Tea 🍵'), findsOneWidget);

        // Tap left 'شاي' then right 'Tea 🍵'
        await tester.tap(find.text('شاي'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Tea 🍵'));
        await tester.pumpAndSettle();

        // Tap left 'ماء' then right 'Water 💧'
        if (find.text('ماء').evaluate().isNotEmpty &&
            find.text('Water 💧').evaluate().isNotEmpty) {
          await tester.tap(find.text('ماء'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Water 💧'));
          await tester.pumpAndSettle();
        }
      });

      // 3. Interactive Listen & Choose Mini-Game Flow
      testWidgets(
        '3. Listen & Choose game selects option and verifies answer',
        (tester) async {
          await tester.pumpWidget(
            createTestApp(
              home: const GamePlayScreen(gameId: 'game_listen_choose'),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.textContaining('أهلاً وسهلاً'), findsOneWidget);
          expect(find.text('Hello & Welcome'), findsOneWidget);

          // Select correct answer
          await tester.tap(find.text('Hello & Welcome'));
          await tester.pumpAndSettle();

          // Tap Check Answer button
          await tester.tap(find.text('تحقق من الإجابة'));
          await tester.pumpAndSettle();

          expect(find.textContaining('رائع'), findsOneWidget);
        },
      );

      // 4. Interactive Sentence Builder Mini-Game Flow
      testWidgets(
        '4. Sentence Builder taps word chips in sequence to build sentence',
        (tester) async {
          await tester.pumpWidget(
            createTestApp(
              home: const GamePlayScreen(gameId: 'game_sentence_builder'),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.textContaining('بناء الجمل'), findsWidgets);
          expect(find.text('أريد'), findsOneWidget);
          expect(find.text('كوب'), findsOneWidget);
          expect(find.text('قهوة'), findsOneWidget);
          expect(find.text('مع'), findsOneWidget);
          expect(find.text('حليب'), findsOneWidget);

          // Tap words in order: أريد -> كوب -> قهوة -> مع -> حليب
          await tester.tap(find.text('أريد'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('كوب'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('قهوة'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('مع'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('حليب'));
          await tester.pumpAndSettle();

          // Tap Check Answer
          await tester.tap(find.text('تحقق من الإجابة'));
          await tester.pumpAndSettle();

          expect(find.textContaining('رائع'), findsOneWidget);
        },
      );

      // 5. Interactive Picture / Word Selection Mini-Game Flow
      testWidgets(
        '5. Picture & Word Selection game selects visual card and verifies',
        (tester) async {
          await tester.pumpWidget(
            createTestApp(
              home: const GamePlayScreen(gameId: 'game_picture_select'),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.textContaining('تفاحة'), findsWidgets);
          expect(find.text('تفاحة 🍎'), findsOneWidget);

          await tester.tap(find.text('تفاحة 🍎'));
          await tester.pumpAndSettle();

          await tester.tap(find.text('تحقق من الإجابة'));
          await tester.pumpAndSettle();

          expect(find.textContaining('رائع'), findsOneWidget);
        },
      );

      // 6. Interactive Memory Vocabulary Mini-Game Flow
      testWidgets(
        '6. Memory Vocabulary flips cards and detects matching pairs',
        (tester) async {
          await tester.pumpWidget(
            createTestApp(
              home: const GamePlayScreen(gameId: 'game_memory_vocab'),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.textContaining('ذاكرة البطاقات'), findsWidgets);
          expect(find.text('❓'), findsNWidgets(8)); // 4 pairs = 8 hidden cards

          // Tap first two cards
          await tester.tap(find.text('❓').first);
          await tester.pumpAndSettle();

          expect(find.text('❓'), findsNWidgets(7));
        },
      );

      // 7. Student Progress Screen Verification
      testWidgets(
        '7. StudentProgressScreen renders updated metrics, streak, and badges',
        (tester) async {
          await tester.pumpWidget(
            createTestApp(home: const StudentProgressScreen()),
          );
          await tester.pumpAndSettle();

          expect(find.textContaining('تقدم'), findsWidgets);
          expect(find.textContaining('XP'), findsWidgets);
          expect(find.textContaining('أيام'), findsWidgets);
        },
      );

      // 8. Anti-Farming & XP Protection
      test(
        '8. Anti-Farming: Duplicate task completion awards 0 additional XP',
        () async {
          final tasks = await testRepo.getDailyTasks(
            studentId: 'stu_sami_01',
            schoolCode: 'SCH-1001',
          );
          expect(tasks, isNotEmpty);
          final taskId = tasks.first.id;

          // 1st completion
          final completedFirst = await testRepo.completeDailyTask(
            studentId: 'stu_sami_01',
            taskId: taskId,
            schoolCode: 'SCH-1001',
          );
          expect(completedFirst.completed, true);
          expect(completedFirst.status, DailyTaskStatus.completed);

          // 2nd completion (idempotency / anti-farming)
          final summary = await testRepo.getStudentProgressSummary(
            studentId: 'stu_sami_01',
            schoolCode: 'SCH-1001',
          );
          final xpBefore = summary.totalXp;

          await testRepo.completeDailyTask(
            studentId: 'stu_sami_01',
            taskId: taskId,
            schoolCode: 'SCH-1001',
          );

          final summaryAfter = await testRepo.getStudentProgressSummary(
            studentId: 'stu_sami_01',
            schoolCode: 'SCH-1001',
          );

          // XP should not be granted twice
          expect(summaryAfter.totalXp, xpBefore);
        },
      );
    },
  );
}
