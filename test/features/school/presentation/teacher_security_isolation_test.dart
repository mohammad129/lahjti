import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahjti/core/theme/app_theme.dart';
import 'package:lahjti/features/school/presentation/providers/school_providers.dart';
import 'package:lahjti/features/school/presentation/screens/teacher_class_details_screen.dart';
import 'package:lahjti/features/school/presentation/screens/teacher_student_details_screen.dart';
import 'package:lahjti/l10n/app_localizations.dart';

void main() {
  Widget createSecurityTestWidget({required Widget child}) {
    return ProviderScope(
      child: MaterialApp(
        locale: const Locale('ar'),
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  group('Teacher Security & Isolation Tests', () {
    testWidgets('1. Teacher cannot view another school/teacher class details', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createSecurityTestWidget(
          child: const TeacherClassDetailsScreen(classId: 'cls_other_school'),
        ),
      );
      await tester.pumpAndSettle();

      // Renders Not Found / Safe fallback without leaking unauthorized class data
      expect(find.text('الصف التاسع - أ'), findsNothing);
      expect(find.text('لسه ما في بيانات كافية'), findsOneWidget);
    });

    testWidgets(
      '2. Teacher cannot view students belonging to unauthorized class',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createSecurityTestWidget(
            child: const TeacherStudentDetailsScreen(
              studentId: 'stu_unknown',
              classId: 'cls_other_school',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('لسه ما في بيانات كافية'), findsWidgets);
      },
    );

    test(
      '3. Repository strictly enforces school code and teacher ID checks',
      () async {
        final container = ProviderContainer();
        final repo = container.read(teacherDashboardRepositoryProvider);

        final result = await repo.getClassById(
          classId: 'cls_other_school',
          teacherId: 'teacher_unauthorized',
          schoolCode: 'SCH-1001',
        );

        expect(result, isNull);

        final students = await repo.getClassStudents(
          classId: 'cls_other_school',
          teacherId: 'teacher_unauthorized',
          schoolCode: 'SCH-1001',
        );

        expect(students, isEmpty);
      },
    );
  });
}
