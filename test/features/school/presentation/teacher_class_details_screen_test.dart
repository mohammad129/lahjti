import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lahjti/core/theme/app_theme.dart';
import 'package:lahjti/features/school/presentation/screens/teacher_class_details_screen.dart';
import 'package:lahjti/l10n/app_localizations.dart';

void main() {
  Widget createClassDetailsWidget({
    required String classId,
    Locale locale = const Locale('ar'),
    ProviderContainer? container,
  }) {
    final router = GoRouter(
      initialLocation: '/teacher/classes/$classId',
      routes: [
        GoRoute(
          path: '/teacher/classes/:classId',
          builder:
              (context, state) => TeacherClassDetailsScreen(
                classId: state.pathParameters['classId'] ?? classId,
              ),
        ),
        GoRoute(
          path: '/teacher/students/:studentId',
          builder:
              (context, state) => Scaffold(
                body: Center(
                  child: Text(
                    'Student Details ${state.pathParameters['studentId']} (Class: ${state.uri.queryParameters['classId']})',
                  ),
                ),
              ),
        ),
      ],
    );

    return UncontrolledProviderScope(
      container: container ?? ProviderContainer(),
      child: MaterialApp.router(
        locale: locale,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
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

  group('TeacherClassDetailsScreen Widget Tests', () {
    testWidgets(
      '1. Displays class header and student roster with privacy-safe names in Arabic',
      (WidgetTester tester) async {
        setMobileScreenSize(tester);
        final container = ProviderContainer();

        await tester.pumpWidget(
          createClassDetailsWidget(
            classId: 'cls_grade6_a',
            container: container,
          ),
        );
        await tester.pumpAndSettle();

        // Header
        expect(find.text('الصف السادس - أ'), findsWidgets);
        expect(find.text('الصف السادس • أ'), findsOneWidget);

        // Section title
        expect(find.text('قائمة الطلاب'), findsOneWidget);

        // Student rows (Privacy-safe names)
        expect(find.text('سامي ع.'), findsOneWidget);
        expect(find.text('ليلى خ.'), findsOneWidget);
        expect(find.text('يوسف ا.'), findsOneWidget);

        // Metrics badges
        expect(find.text('A2 - مبتدئ متقدم'), findsOneWidget);
        expect(find.text('B1 - متوسط'), findsOneWidget);
        expect(find.text('أنجز مهام اليوم ✅'), findsWidgets);
      },
    );

    testWidgets(
      '2. Tapping a student navigates to TeacherStudentDetailsScreen',
      (WidgetTester tester) async {
        setMobileScreenSize(tester);
        final container = ProviderContainer();

        await tester.pumpWidget(
          createClassDetailsWidget(
            classId: 'cls_grade6_a',
            container: container,
          ),
        );
        await tester.pumpAndSettle();

        final studentCard = find.text('سامي ع.');
        expect(studentCard, findsOneWidget);
        await tester.tap(studentCard);
        await tester.pumpAndSettle();

        expect(
          find.text('Student Details stu_sami_01 (Class: cls_grade6_a)'),
          findsOneWidget,
        );
      },
    );

    testWidgets('3. Displays empty state message for class with 0 students', (
      WidgetTester tester,
    ) async {
      setMobileScreenSize(tester);
      final container = ProviderContainer();

      await tester.pumpWidget(
        createClassDetailsWidget(classId: 'cls_grade8_c', container: container),
      );
      await tester.pumpAndSettle();

      expect(find.text('الصف الثامن - ج'), findsWidgets);
      expect(find.text('لسه ما أضفت طلاب لهالصف.'), findsOneWidget);
    });

    testWidgets('4. Displays cleanly in English LTR', (
      WidgetTester tester,
    ) async {
      setMobileScreenSize(tester);
      final container = ProviderContainer();

      await tester.pumpWidget(
        createClassDetailsWidget(
          classId: 'cls_grade6_a',
          locale: const Locale('en'),
          container: container,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Class Students'), findsOneWidget);
    });
  });
}
