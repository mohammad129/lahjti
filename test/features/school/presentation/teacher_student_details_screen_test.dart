import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahjti/core/theme/app_theme.dart';
import 'package:lahjti/features/school/presentation/screens/teacher_student_details_screen.dart';
import 'package:lahjti/l10n/app_localizations.dart';

void main() {
  Widget createStudentDetailsWidget({
    required String studentId,
    required String classId,
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
        home: TeacherStudentDetailsScreen(
          studentId: studentId,
          classId: classId,
        ),
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

  group('TeacherStudentDetailsScreen Widget Tests', () {
    testWidgets(
      '1. Displays comprehensive educational learning overview, skills, and activities in Arabic',
      (WidgetTester tester) async {
        setMobileScreenSize(tester);
        final container = ProviderContainer();

        await tester.pumpWidget(
          createStudentDetailsWidget(
            studentId: 'stu_sami_01',
            classId: 'cls_grade6_a',
            container: container,
          ),
        );
        await tester.pumpAndSettle();

        // Student Header
        expect(find.text('سامي ع.'), findsWidgets);
        expect(find.text('A2 - مبتدئ متقدم'), findsOneWidget);

        // Section 1: Learning Overview
        expect(find.text('نظرة عامة على التعلم'), findsOneWidget);
        expect(find.text('الدروس المكتملة'), findsOneWidget);
        expect(find.text('14'), findsOneWidget);
        expect(find.text('المفردات المتقنة'), findsOneWidget);
        expect(find.text('42'), findsOneWidget);
        expect(find.text('الامتحانات المنجزة'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);

        // Section 2: Skill Progress
        expect(find.text('مستوى المهارات'), findsOneWidget);
        expect(find.text('المحادثة والتحدث'), findsOneWidget);
        expect(find.text('الاستماع والفهم'), findsOneWidget);
        expect(find.text('المفردات والكلمات'), findsOneWidget);
        expect(find.text('القواعد والتراكيب'), findsOneWidget);
        expect(find.text('القراءة والنصوص'), findsOneWidget);
        expect(find.text('الاستيعاب العام'), findsOneWidget);

        // Section 3: Needs Attention
        expect(find.text('نقاط تحتاج إلى متابعة'), findsOneWidget);
        expect(
          find.text(
            'بحاجة لتركيز إضافي على استخدام تصريف الأفعال الماضية في القواعد.',
          ),
          findsOneWidget,
        );

        // Section 4: Recent Activity
        expect(find.text('النشاط الأخير'), findsOneWidget);
        expect(find.text('درس: في المطعم والمقهى'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Displays positive attention state for student with no issues',
      (WidgetTester tester) async {
        setMobileScreenSize(tester);
        final container = ProviderContainer();

        await tester.pumpWidget(
          createStudentDetailsWidget(
            studentId: 'stu_layla_02',
            classId: 'cls_grade6_a',
            container: container,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('ليلى خ.'), findsWidgets);
        expect(find.text('B1 - متوسط'), findsOneWidget);
        expect(
          find.text('لا توجد تنبيهات، الطالب يسير بوتيرة ممتازة 👏'),
          findsOneWidget,
        );
      },
    );

    testWidgets('3. Displays in English LTR correctly', (
      WidgetTester tester,
    ) async {
      setMobileScreenSize(tester);
      final container = ProviderContainer();

      await tester.pumpWidget(
        createStudentDetailsWidget(
          studentId: 'stu_sami_01',
          classId: 'cls_grade6_a',
          locale: const Locale('en'),
          container: container,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Learning Overview'), findsOneWidget);
      expect(find.text('Lessons Completed'), findsOneWidget);
      expect(find.text('Skill Progress'), findsOneWidget);
      expect(find.text('Speaking'), findsOneWidget);
      expect(find.text('Listening'), findsOneWidget);
      expect(find.text('Needs Attention'), findsOneWidget);
      expect(find.text('Recent Activity'), findsOneWidget);
    });
  });
}
