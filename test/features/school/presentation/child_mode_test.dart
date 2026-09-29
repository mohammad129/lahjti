import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahjti/core/theme/app_theme.dart';
import 'package:lahjti/features/onboarding/domain/models/age_group.dart';
import 'package:lahjti/features/school/domain/models/school_student_profile.dart';
import 'package:lahjti/features/school/presentation/providers/student_providers.dart';
import 'package:lahjti/features/school/presentation/screens/student_school_home_screen.dart';
import 'package:lahjti/l10n/app_localizations.dart';

void main() {
  Widget createChildModeTestWidget({
    required ProviderContainer container,
    Locale locale = const Locale('ar'),
  }) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const StudentSchoolHomeScreen(),
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

  group('Child Mode (Ages 6–10) Widget Tests', () {
    testWidgets(
      '1. Displays kid-friendly mode banner and larger playful cards when age is 6-10',
      (WidgetTester tester) async {
        setMobileScreenSize(tester);
        final container = ProviderContainer();

        // Set student profile with AgeGroup.age6_10
        container
            .read(currentSchoolStudentProfileProvider.notifier)
            .state = SchoolStudentProfile(
          studentId: 'stu_child_01',
          fullName: 'أحمد الصغير',
          schoolId: 'sch_1',
          schoolCode: 'SCH-1001',
          schoolName: 'مدرسة براعم النور',
          grade: 'الصف الثالث',
          classSection: 'أ',
          ageGroup: AgeGroup.age6_10,
          enrolledAt: DateTime(2026, 1, 10),
        );

        await tester.pumpWidget(
          createChildModeTestWidget(container: container),
        );
        await tester.pumpAndSettle();

        // Child Mode Fun Banner
        expect(find.text('وضع الأطفال التفاعلي 🎈'), findsOneWidget);
        expect(find.text('مرحباً يا أحمد 👋'), findsOneWidget);
        expect(find.textContaining('مغامرة الدرس'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Older students (11+) do not show child banner and get standard dashboard',
      (WidgetTester tester) async {
        setMobileScreenSize(tester);
        final container = ProviderContainer();

        container
            .read(currentSchoolStudentProfileProvider.notifier)
            .state = SchoolStudentProfile(
          studentId: 'stu_teen_01',
          fullName: 'ياسمين خليل',
          schoolId: 'sch_1',
          schoolCode: 'SCH-1001',
          schoolName: 'مدرسة القدس الثانوية',
          grade: 'الصف العاشر',
          classSection: 'ب',
          ageGroup: AgeGroup.age15_18,
          enrolledAt: DateTime(2026, 1, 10),
        );

        await tester.pumpWidget(
          createChildModeTestWidget(container: container),
        );
        await tester.pumpAndSettle();

        expect(find.text('وضع الأطفال التفاعلي 🎈'), findsNothing);
        expect(find.text('مرحباً يا ياسمين 👋'), findsOneWidget);
        expect(find.text('درس اليوم: في المقهى والمطعم'), findsOneWidget);
      },
    );
  });
}
