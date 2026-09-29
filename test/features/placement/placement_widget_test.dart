import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahjti/core/theme/app_theme.dart';
import 'package:lahjti/features/onboarding/domain/models/age_group.dart';
import 'package:lahjti/features/onboarding/domain/models/experience_level.dart';
import 'package:lahjti/features/onboarding/domain/models/learning_goal.dart';
import 'package:lahjti/features/onboarding/domain/models/native_language.dart';
import 'package:lahjti/features/onboarding/domain/models/onboarding_data.dart';
import 'package:lahjti/features/onboarding/domain/models/supported_language.dart';
import 'package:lahjti/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:lahjti/features/placement/data/providers/mock_language_evaluation_provider.dart';
import 'package:lahjti/features/placement/domain/models/cefr_level.dart';
import 'package:lahjti/features/placement/domain/models/placement_result.dart';
import 'package:lahjti/features/placement/presentation/providers/placement_provider.dart';
import 'package:lahjti/features/placement/presentation/steps/placement_assessment_step.dart';
import 'package:lahjti/features/placement/presentation/steps/placement_intro_step.dart';
import 'package:lahjti/features/placement/presentation/steps/placement_result_step.dart';
import 'package:lahjti/l10n/app_localizations.dart';

void main() {
  void setMobileScreenSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget createWidgetUnderTest({
    required Widget child,
    Locale locale = const Locale('ar'),
    ProviderContainer? container,
  }) {
    return UncontrolledProviderScope(
      container: container ?? ProviderContainer(),
      child: MaterialApp(
        locale: locale,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SafeArea(child: child)),
      ),
    );
  }

  group('Placement Widgets Tests', () {
    testWidgets('17. Step 7: Placement Intro renders tutor message and CTA', (
      WidgetTester tester,
    ) async {
      setMobileScreenSize(tester);
      final container = ProviderContainer();
      container.read(onboardingProvider.notifier).selectTutor('abbas');

      await tester.pumpWidget(
        createWidgetUnderTest(
          child: const PlacementIntroStep(),
          container: container,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('خلينا نشوف من وين نبدأ 🎯'), findsOneWidget);
      expect(find.text('عباس'), findsOneWidget);
      expect(
        find.text(
          'أنا عباس، ورح أمشي معك خطوة خطوة. إذا ما عرفت جواب، الدنيا مش واقفة 😂',
        ),
        findsOneWidget,
      );
      expect(find.text('يلا نبلش'), findsOneWidget);
    });

    testWidgets('18. Step 8: Placement Assessment renders question & inputs', (
      WidgetTester tester,
    ) async {
      setMobileScreenSize(tester);
      final container = ProviderContainer(
        overrides: [
          languageEvaluationProvider.overrideWithValue(
            const MockLanguageEvaluationProvider(
              shouldSimulateNetworkDelay: false,
            ),
          ),
        ],
      );

      final testData = OnboardingData(
        targetLanguage: const SupportedLanguage(
          id: 'en',
          nameEn: 'English',
          nameAr: 'الإنجليزية',
          flagEmoji: '🇬🇧',
        ),
        nativeLanguage: NativeLanguage.arabic,
        ageGroup: AgeGroup.age19_25,
        learningGoal: const LearningGoal(id: 'conversation', icon: '🗣️'),
        experienceLevel: ExperienceLevel.zero,
        selectedTutorId: 'dunya',
      );

      container.read(onboardingProvider.notifier).selectTutor('dunya');

      await container
          .read(placementNotifierProvider.notifier)
          .startSession(testData);

      await tester.pumpWidget(
        createWidgetUnderTest(
          child: const PlacementAssessmentStep(),
          container: container,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PlacementAssessmentStep), findsOneWidget);
      expect(find.text('دنيا'), findsOneWidget);
      expect(find.text('جاوب'), findsOneWidget);
      expect(find.text('مش عارف'), findsOneWidget);

      // Enter response
      await tester.enterText(find.byType(TextField), 'Hello there');
      await tester.tap(find.text('جاوب'));
      await tester.pumpAndSettle();

      // Feedback banner displays
      expect(find.text('ممتاز 👏 نرفعها شوي.'), findsOneWidget);
    });

    testWidgets(
      '19. Step 9: Placement Result renders CEFR level and pronunciation notice',
      (WidgetTester tester) async {
        setMobileScreenSize(tester);
        final container = ProviderContainer();

        final state = PlacementState(
          result: const PlacementResult(
            estimatedCefrLevel: CefrLevel.a1,
            overallScore: 68,
            comprehensionScore: 75,
            vocabularyScore: 65,
            grammarScore: 70,
            fluencyScore: 60,
            strengths: ['سرعة الفهم والاستيعاب'],
            weaknesses: ['المفردات التخصصية واليومية'],
            recommendedStartingDifficulty: CefrLevel.a1,
            recommendedFocusAreas: ['توسيع بنك الكلمات النشطة'],
          ),
        );

        container.read(placementNotifierProvider.notifier).state = state;

        await tester.pumpWidget(
          createWidgetUnderTest(
            child: const PlacementResultStep(),
            container: container,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('عرفنا من وين نبدأ 🎯'), findsOneWidget);
        expect(find.text('A1'), findsOneWidget);
        expect(find.text('مبتدئ'), findsOneWidget);
        expect(
          find.text('النطق: رح نقيسه لما نبدأ الحكي بالصوت 🎙️'),
          findsOneWidget,
        );
        expect(find.text('أقوى شغلاتك'), findsOneWidget);
        expect(find.text('سرعة الفهم والاستيعاب'), findsOneWidget);
        expect(find.text('كمّل رحلتي'), findsOneWidget);
      },
    );
  });
}
