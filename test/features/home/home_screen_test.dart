import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/home/presentation/screens/home_screen.dart';
import 'package:lahjti/features/onboarding/domain/models/tutor_persona.dart';
import 'package:lahjti/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:lahjti/l10n/app_localizations.dart';

Widget createHomeScreen({
  required TutorPersona tutor,
  Locale locale = const Locale('ar'),
}) {
  return ProviderScope(
    overrides: [
      onboardingProvider.overrideWith((ref) {
        final notifier = OnboardingNotifier();
        notifier.selectTutor(tutor.id);
        return notifier;
      }),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeScreen(),
    ),
  );
}

void main() {
  group('HomeScreen Widget Tests', () {
    final abbasTutor = TutorPersona.tutors.firstWhere((t) => t.id == 'abbas');
    final dunyaTutor = TutorPersona.tutors.firstWhere((t) => t.id == 'dunya');

    testWidgets(
      '1. Renders HomeScreen with Abbas tutor persona and recommendation',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createHomeScreen(tutor: abbasTutor));
        await tester.pumpAndSettle();

        expect(find.textContaining('عباس'), findsWidgets);
        expect(find.text('A1'), findsOneWidget);
        expect(find.text('خطوتك التالية الذكية'), findsOneWidget);
        expect(find.text('رحلة الـ 3 أشهر'), findsOneWidget);
        expect(find.text('خطة التعلم — الشهر الأول'), findsOneWidget);
        expect(find.text('تحدث مع عباس'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Renders HomeScreen with Dunya tutor persona and floating action',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createHomeScreen(tutor: dunyaTutor));
        await tester.pumpAndSettle();

        expect(find.textContaining('دنيا'), findsWidgets);
        expect(find.text('تحدث مع دنيا'), findsOneWidget);
      },
    );
  });
}
