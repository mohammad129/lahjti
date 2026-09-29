import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahjti/features/welcome/presentation/welcome_screen.dart';
import 'package:lahjti/l10n/app_localizations.dart';

void main() {
  Widget createTestWidget({Locale locale = const Locale('ar')}) {
    return ProviderScope(
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const WelcomeScreen(),
      ),
    );
  }

  testWidgets('2. Welcome screen renders expected brand text and primary CTA', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Verify Brand Name
    expect(find.text('لهجتي'), findsOneWidget);

    // Verify Main Tagline
    expect(find.text('احكيها... مش بس احفظها.'), findsOneWidget);

    // Verify Supporting text
    expect(
      find.text('مدربك AI معك، يسمعك، يحكي معك، ويصححلك.'),
      findsOneWidget,
    );

    // Verify Primary Button CTA
    expect(find.text('ابدأ رحلتك 🚀'), findsOneWidget);

    // Verify School Portal Secondary Button
    expect(find.text('🏫 دخول المدارس (طالب / معلم)'), findsOneWidget);

    // Verify AI badge
    expect(find.text('مدرب ذكي'), findsOneWidget);
  });

  testWidgets('3. Tapping School Portal opens role selection modal', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    final schoolBtn = find.text('🏫 دخول المدارس (طالب / معلم)');
    expect(schoolBtn, findsOneWidget);
    await tester.tap(schoolBtn);
    await tester.pumpAndSettle();

    expect(find.text('شو دورك بالمدرسة؟'), findsOneWidget);
    expect(find.text('طالب'), findsOneWidget);
    expect(find.text('معلم'), findsOneWidget);
  });
}
