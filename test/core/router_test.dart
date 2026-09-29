import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahjti/main.dart';
import 'package:lahjti/features/welcome/presentation/welcome_screen.dart';
import 'package:lahjti/features/onboarding/presentation/onboarding_screen.dart';
import 'package:lahjti/features/onboarding/presentation/steps/target_language_step.dart';
import 'package:lahjti/core/widgets/buttons/primary_button.dart';

void main() {
  testWidgets(
    '5. Navigation from Welcome to Onboarding screen works on CTA tap',
    (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: LahjtiApp()));
      await tester.pumpAndSettle();

      // Verify currently on Welcome screen
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);

      // Find and tap the primary CTA button
      final ctaButton = find.byType(PrimaryButton);
      expect(ctaButton, findsOneWidget);

      await tester.tap(ctaButton);
      await tester.pumpAndSettle();

      // Verify navigated to OnboardingScreen and TargetLanguageStep
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(TargetLanguageStep), findsOneWidget);
      expect(find.text('شو اللغة اللي بدك تتعلمها؟'), findsOneWidget);
    },
  );
}
