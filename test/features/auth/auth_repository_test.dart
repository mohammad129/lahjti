import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/auth/data/repositories/mock_auth_repository.dart';

void main() {
  group('MockAuthRepository Tests', () {
    late MockAuthRepository repository;

    setUp(() {
      repository = MockAuthRepository();
    });

    tearDown(() {
      repository.dispose();
    });

    test('1. Sign up creates user and emits auth state change', () async {
      expect(repository.currentUser, isNull);

      final user = await repository.signUp(
        fullName: 'Ahmad Al-Khatib',
        email: 'ahmad@example.com',
        password: 'securePassword123',
      );

      expect(user.fullName, 'Ahmad Al-Khatib');
      expect(user.email, 'ahmad@example.com');
      expect(repository.currentUser, user);
    });

    test('2. Sign out clears currentUser', () async {
      await repository.signUp(
        fullName: 'Layan Test',
        email: 'layan@example.com',
        password: 'securePassword123',
      );

      expect(repository.currentUser, isNotNull);

      await repository.signOut();
      expect(repository.currentUser, isNull);
    });
  });
}
