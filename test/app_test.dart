import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahjti/main.dart';
import 'package:lahjti/features/welcome/presentation/welcome_screen.dart';

void main() {
  testWidgets('1. Application starts and renders WelcomeScreen initially', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: LahjtiApp()));
    await tester.pumpAndSettle();

    expect(find.byType(LahjtiApp), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });
}
