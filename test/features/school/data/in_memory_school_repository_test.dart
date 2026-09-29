import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/school/data/repositories/in_memory_school_repository.dart';
import 'package:lahjti/features/school/domain/models/school.dart';

void main() {
  group('InMemorySchoolRepository Tests', () {
    late InMemorySchoolRepository repository;

    setUp(() {
      repository = InMemorySchoolRepository();
    });

    test('1. Finds seeded school by code case-insensitively', () async {
      final school1 = await repository.findSchoolByCode('SCH-1001');
      expect(school1, isNotNull);
      expect(school1!.name, 'أكاديمية عمان الدولية');

      final schoolLower = await repository.findSchoolByCode('  sch-1001  ');
      expect(schoolLower, isNotNull);
      expect(schoolLower!.id, school1.id);

      final lahjtiSchool = await repository.findSchoolByCode('LAH-EDU-2026');
      expect(lahjtiSchool, isNotNull);
      expect(lahjtiSchool!.name, 'مدارس لهجتي النموذجية');
    });

    test('2. Returns null and invalid status for non-existent code', () async {
      final school = await repository.findSchoolByCode('INVALID-CODE-999');
      expect(school, isNull);

      final isValid = await repository.validateSchoolCode('UNKNOWN');
      expect(isValid, isFalse);
    });

    test('3. Retrieves school by ID', () async {
      final school = await repository.getSchool('sch_amman_01');
      expect(school, isNotNull);
      expect(school!.code, 'SCH-1001');

      final nonExistent = await repository.getSchool('non_existent');
      expect(nonExistent, isNull);
    });

    test('4. Lists available active partner schools', () async {
      final schools = await repository.getAvailableSchools();
      expect(schools.isNotEmpty, isTrue);
      expect(schools.every((s) => s.isActive), isTrue);
    });

    test('5. Adds custom school dynamically', () async {
      final custom = School(
        id: 'sch_custom',
        name: 'Custom Partner School',
        code: 'CUSTOM-2026',
        city: 'Dubai',
        country: 'UAE',
        isActive: true,
        createdAt: DateTime.now(),
      );

      repository.addSchool(custom);

      final found = await repository.findSchoolByCode('custom-2026');
      expect(found, isNotNull);
      expect(found!.name, 'Custom Partner School');
    });
  });
}
