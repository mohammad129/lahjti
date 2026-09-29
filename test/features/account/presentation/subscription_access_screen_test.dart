import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahjti/core/theme/app_theme.dart';
import 'package:lahjti/features/account/presentation/screens/subscription_access_screen.dart';
import 'package:lahjti/l10n/app_localizations.dart';

void main() {
  Widget createSubscriptionScreenWidget({
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
        home: const SubscriptionAccessScreen(),
      ),
    );
  }

  void setMobileScreenSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('SubscriptionAccessScreen Widget Tests', () {
    testWidgets(
      '1. Renders active trial and transparent pricing note in Arabic',
      (WidgetTester tester) async {
        setMobileScreenSize(tester);
        final container = ProviderContainer();

        await tester.pumpWidget(
          createSubscriptionScreenWidget(container: container),
        );
        await tester.pumpAndSettle();

        expect(find.text('الاشتراك والوصول'), findsOneWidget);
        expect(find.text('فترة تجريبية مجانية نشطة'), findsOneWidget);
        expect(
          find.text('10 دولارات شهرياً بعد انتهاء التجربة'),
          findsOneWidget,
        );
      },
    );

    testWidgets('2. Renders in English LTR without crashing or missing keys', (
      WidgetTester tester,
    ) async {
      setMobileScreenSize(tester);
      final container = ProviderContainer();

      await tester.pumpWidget(
        createSubscriptionScreenWidget(
          locale: const Locale('en'),
          container: container,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Subscription & Access'), findsOneWidget);
      expect(find.text('Free Trial Active'), findsOneWidget);
      expect(find.text('\$10/month after trial ends'), findsOneWidget);
    });
  });
}
