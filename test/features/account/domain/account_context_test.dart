import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/account/domain/models/account_context.dart';

void main() {
  group('AccountContext Domain Model Tests', () {
    test('1. Has individual and school contexts', () {
      expect(AccountContext.values.length, 2);
      expect(AccountContext.values, contains(AccountContext.individual));
      expect(AccountContext.values, contains(AccountContext.school));
    });

    test('2. Helper properties verify context properly', () {
      const individual = AccountContext.individual;
      expect(individual.isIndividual, isTrue);
      expect(individual.isSchool, isFalse);

      const school = AccountContext.school;
      expect(school.isIndividual, isFalse);
      expect(school.isSchool, isTrue);
    });

    test('3. Serialization and deserialization from string code', () {
      expect(
        AccountContext.fromString('individual'),
        AccountContext.individual,
      );
      expect(
        AccountContext.fromString('INDIVIDUAL'),
        AccountContext.individual,
      );
      expect(AccountContext.fromString('school'), AccountContext.school);
      expect(AccountContext.fromString('SCHOOL'), AccountContext.school);
      expect(AccountContext.fromString('unknown'), AccountContext.individual);
      expect(AccountContext.fromString(null), AccountContext.individual);

      expect(AccountContext.individual.code, 'individual');
      expect(AccountContext.school.code, 'school');
    });
  });
}
