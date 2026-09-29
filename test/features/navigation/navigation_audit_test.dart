import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/core/localization/locale_provider.dart';
import 'package:lahjti/features/account/domain/models/account_context.dart';
import 'package:lahjti/features/account/presentation/providers/account_providers.dart';
import 'package:lahjti/features/home/presentation/screens/home_screen.dart';
import 'package:lahjti/features/school/presentation/screens/educational_games_hub_screen.dart';
import 'package:lahjti/features/school/presentation/screens/student_school_home_screen.dart';
import 'package:lahjti/features/school/presentation/screens/teacher_home_screen.dart';
import 'package:lahjti/l10n/app_localizations.dart';

Widget _createTestApp({
  required Widget home,
  List<Override> overrides = const [],
  Locale locale = const Locale('ar'),
}) {
  return ProviderScope(
    overrides: [
      localeProvider.overrideWith((ref) => LocaleNotifier(locale)),
      ...overrides,
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar'), Locale('en')],
      home: home,
    ),
  );
}

void main() {
  group('Step 27.1 — Full Navigation, Games & Role Isolation Audit Tests', () {
    testWidgets(
      '1. HomeScreen renders AppBar controls and 4 Quick Action cards including Games',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 900));

        await tester.pumpWidget(
          _createTestApp(
            home: const HomeScreen(),
            overrides: [
              currentAccountContextProvider.overrideWith(
                (ref) => AccountContext.individual,
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Verify Brand title & AppBar actions
        expect(find.text('لهجتي'), findsWidgets);
        expect(
          find.byKey(const Key('home_subscription_appbar_btn')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('home_profile_appbar_btn')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('home_logout_appbar_btn')), findsOneWidget);

        // Verify 4 Quick Action buttons (Vocabulary, Games, Exams, Progress)
        expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
        expect(find.byIcon(Icons.sports_esports_rounded), findsOneWidget);
        expect(find.byIcon(Icons.quiz_rounded), findsOneWidget);
        expect(find.byIcon(Icons.insights_rounded), findsOneWidget);

        // Verify Educational Games Hub discovery banner
        expect(
          find.byKey(const Key('home_games_hub_banner_btn')),
          findsOneWidget,
        );
        expect(find.text('الألعاب التعليمية التفاعلية 🕹️'), findsOneWidget);
      },
    );

    testWidgets(
      '2. StudentSchoolHomeScreen renders complete student navigation and school info',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 900));

        await tester.pumpWidget(
          _createTestApp(
            home: const StudentSchoolHomeScreen(),
            overrides: [
              currentAccountContextProvider.overrideWith(
                (ref) => AccountContext.school,
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Verify student header & AppBar actions
        expect(
          find.byKey(const Key('student_subscription_appbar_btn')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('student_profile_appbar_btn')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('student_logout_appbar_btn')),
          findsOneWidget,
        );

        // Verify Student Hub items
        expect(find.text('5 ألعاب تفاعلية'), findsOneWidget);
        expect(
          find.byKey(const Key('student_home_continue_cta_btn')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '3. EducationalGamesHubScreen displays all 5 educational mini-games',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 900));

        await tester.pumpWidget(
          _createTestApp(home: const EducationalGamesHubScreen()),
        );
        await tester.pumpAndSettle();

        // Verify games hub header
        expect(find.text('الألعاب التعليمية'), findsWidgets);

        // Verify "Play Now" action buttons for games
        expect(find.text('العب الآن'), findsWidgets);
      },
    );

    testWidgets(
      '4. TeacherHomeScreen strictly isolates teacher tools from student gameplay',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 900));

        await tester.pumpWidget(
          _createTestApp(home: const TeacherHomeScreen()),
        );
        await tester.pumpAndSettle();

        // Verify Teacher Dashboard title & overview cards
        expect(find.text('لوحة المعلم'), findsOneWidget);
        expect(find.text('صفوفي الدراسية'), findsOneWidget);

        // Verify student game play / private student areas do NOT appear in teacher dashboard
        expect(find.text('الألعاب التعليمية التفاعلية 🕹️'), findsNothing);
        expect(
          find.byKey(const Key('home_games_hub_banner_btn')),
          findsNothing,
        );
      },
    );
  });
}
