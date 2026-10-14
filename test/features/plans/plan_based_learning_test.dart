import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/core/network/api_client.dart';
import 'package:lahjti/features/auth/presentation/widgets/student_code_login_dialog.dart';
import 'package:lahjti/features/plans/data/repositories/plan_repository.dart';
import 'package:lahjti/features/plans/domain/models/plan_models.dart';
import 'package:lahjti/features/plans/presentation/screens/mistakes_review_screen.dart';
import 'package:lahjti/features/plans/presentation/screens/plans_list_screen.dart';
import 'package:lahjti/features/plans/presentation/screens/sixty_day_path_screen.dart';
import 'package:lahjti/features/school/presentation/screens/teacher_exam_builder_screen.dart';
import 'package:lahjti/l10n/app_localizations.dart';

void main() {
  group('Plan-Based English Learning Track — Models & Domain Tests', () {
    test('1. LearningPlan deserializes properly from JSON', () {
      final json = {
        'id': 'plan_60_days_intensive',
        'titleAr': 'خطة الـ 60 يوماً المكثفة للطلاقة',
        'titleEn': '60-Day Intensive English Fluency Path',
        'descriptionAr': 'مسار يومي محكم',
        'descriptionEn': 'Structured 60-day roadmap',
        'targetAudience': 'all',
        'durationDays': 60,
        'level': 'A1-B2',
        'icon': '🚀',
        'isFeatured': true,
        'isActive': true,
        'progress': {
          'currentDay': 5,
          'completedDays': 4,
          'totalPoints': 250,
        },
      };

      final plan = LearningPlan.fromJson(json);
      expect(plan.id, 'plan_60_days_intensive');
      expect(plan.titleAr, 'خطة الـ 60 يوماً المكثفة للطلاقة');
      expect(plan.durationDays, 60);
      expect(plan.isEnrolled, isTrue);
      expect(plan.currentDay, 5);
      expect(plan.completedDays, 4);
      expect(plan.totalPoints, 250);
      expect(plan.progressPercent, closeTo(4 / 60, 0.001));
    });

    test('2. PlanDay model deserializes and holds roadmap details', () {
      final json = {
        'id': 'day_1',
        'planId': 'plan_60_days_intensive',
        'dayNumber': 1,
        'titleAr': 'اليوم 1: التحيات وكسر الجليد بثقة',
        'titleEn': 'Day 1: Greetings & Breaking the Ice',
        'descriptionAr': 'أنشطة تطبيقية مركزة',
        'descriptionEn': 'Focused micro-activities',
        'focusSkill': 'speaking',
        'xpReward': 100,
        'isUnlocked': true,
        'isCompleted': false,
        'activitiesCount': 9,
      };

      final day = PlanDay.fromJson(json);
      expect(day.id, 'day_1');
      expect(day.dayNumber, 1);
      expect(day.isUnlocked, isTrue);
      expect(day.isCompleted, isFalse);
      expect(day.activitiesCount, 9);
      expect(day.focusSkill, 'speaking');
    });

    test('3. PlanActivity model provides appropriate type name and icon for micro-activities', () {
      final activity = PlanActivity(
        id: 'act_1_1',
        planDayId: 'day_1',
        activityType: 'quick_review',
        orderIndex: 1,
        titleAr: 'مراجعة سريعة لما سبق',
        titleEn: 'Quick Memory Refresh',
        instructionAr: 'تذكر سريع لأهم عبارة',
        instructionEn: 'Quick recall',
        contentJson: const {'prompt': 'What does "Hello" mean?'},
        xpReward: 10,
        estimatedMinutes: 2,
      );

      expect(activity.icon, '🔄');
      expect(activity.typeArabicName, 'مراجعة سريعة');

      final vocabActivity = activity.copyWith(activityType: 'vocab');
      expect(vocabActivity.icon, '📚');
      expect(vocabActivity.typeArabicName, 'مفردات اليوم');

      final quizActivity = activity.copyWith(activityType: 'quick_quiz');
      expect(quizActivity.icon, '📝');
      expect(quizActivity.typeArabicName, 'اختبار ختامي سريع');
    });

    test('4. StudentMistakeItem deserializes with SuperMemo-2 spaced repetition properties', () {
      final json = {
        'id': 'mstk_01',
        'studentId': 'std_100',
        'sourceType': 'exam',
        'questionPrompt': 'What is the past tense of teach?',
        'studentAnswer': 'teached',
        'correctAnswer': 'taught',
        'explanation': 'Irregular verb: teach -> taught',
        'repetitionInterval': 2,
        'easeFactor': 2.4,
        'reviewCount': 1,
        'nextReviewAt': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      };

      final item = StudentMistakeItem.fromJson(json);
      expect(item.id, 'mstk_01');
      expect(item.sourceType, 'exam');
      expect(item.correctAnswer, 'taught');
      expect(item.studentAnswer, 'teached');
      expect(item.easeFactor, 2.4);
      expect(item.repetitionInterval, 2);
      expect(item.isDue, isTrue);
    });
  });

  group('PlanRepository Tests', () {
    test('5. RemotePlanRepository returns all 7 planned tracks seamlessly', () async {
      final dio = Dio();
      final client = ApiClient(dio);
      final repo = RemotePlanRepository(client);

      final plans = await repo.getPlans();
      expect(plans.length, 7);
      expect(plans.any((p) => p.id == 'plan_60_days_intensive'), isTrue);
      expect(plans.any((p) => p.id == 'plan_conversation_mastery'), isTrue);
      expect(plans.any((p) => p.id == 'plan_job_interview'), isTrue);
      expect(plans.any((p) => p.id == 'plan_travel'), isTrue);
      expect(plans.any((p) => p.id == 'plan_academic'), isTrue);
      expect(plans.any((p) => p.id == 'plan_school_support'), isTrue);
      expect(plans.any((p) => p.id == 'plan_kids_foundation'), isTrue);
    });

    test('6. RemotePlanRepository returns 60 days and 9 micro-activities per day', () async {
      final dio = Dio();
      final client = ApiClient(dio);
      final repo = RemotePlanRepository(client);

      final days = await repo.getPlanDays('plan_60_days_intensive');
      expect(days.length, 60);

      final activities = await repo.getDayActivities('plan_60_days_intensive', 1);
      expect(activities.length, 9);
      expect(activities[0].activityType, 'quick_review');
      expect(activities[1].activityType, 'vocab');
      expect(activities[2].activityType, 'listening');
      expect(activities[3].activityType, 'dialogue');
      expect(activities[4].activityType, 'grammar');
      expect(activities[5].activityType, 'pronunciation');
      expect(activities[6].activityType, 'mini_game');
      expect(activities[7].activityType, 'quick_quiz');
      expect(activities[8].activityType, 'day_summary');
    });

    test('7. RemotePlanRepository completes activity without requiring AI tokens', () async {
      final dio = Dio();
      final client = ApiClient(dio);
      final repo = RemotePlanRepository(client);

      final result = await repo.completeActivity('act_1_1', {'answer': 'كيف حالك اليوم؟'});
      expect(result['pointsAwarded'], 25);
      expect(result['encouragement'], isNotEmpty);
    });
  });

  group('UI Screens Widget Tests', () {
    testWidgets('8. PlansListScreen displays header, filter chips and plan cards', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            locale: Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: PlansListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('الخطط التعليمية المنظمة'), findsOneWidget);
      expect(find.text('اختر خطتك وابدأ مسارك المنظم'), findsOneWidget);
      expect(find.text('الكل'), findsOneWidget);
      expect(find.text('مكثف 60 يوم'), findsOneWidget);
      expect(find.text('خطة الـ 60 يوماً المكثفة للطلاقة'), findsOneWidget);
    });

    testWidgets('9. SixtyDayPathScreen displays 60-day roadmap and quick start button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            locale: Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SixtyDayPathScreen(planId: 'plan_60_days_intensive'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('ابدأ الآن'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('10. StudentCodeLoginDialog shows input fields and validation', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            locale: Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: StudentCodeLoginDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('الدخول السريع بكود الطالب'), findsOneWidget);
      expect(find.text('دخول إلى صفي'), findsOneWidget);

      // Tap submit with empty fields -> shows validation errors
      await tester.tap(find.text('دخول إلى صفي'));
      await tester.pumpAndSettle();

      expect(find.text('يرجى إدخال رمز الطالب'), findsOneWidget);
    });

    testWidgets('11. MistakesReviewScreen renders spaced repetition banner and cards', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            locale: Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MistakesReviewScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('بنك أخطائي والمراجعة الذكية'), findsOneWidget);
      expect(find.text('نظام التكرار المتباعد (Spaced Repetition)'), findsOneWidget);
      expect(find.text('أتقنتها تماماً'), findsWidgets);
    });

    testWidgets('12. TeacherExamBuilderScreen renders form to add questions and set pass criteria', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            locale: Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: TeacherExamBuilderScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('منشئ الاختبارات المدرسية'), findsOneWidget);
      expect(find.text('معلومات الاختبار'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('حفظ ونشر الاختبار للطلاب 📋'), findsOneWidget);
    });
  });
}
