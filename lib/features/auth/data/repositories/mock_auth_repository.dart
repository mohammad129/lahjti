import 'dart:async';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Clean in-memory mock implementation of [AuthRepository] for development & testing.
///
/// Security: Never stores plain-text passwords or logs credentials.
class MockAuthRepository implements AuthRepository {
  final _authStateController = StreamController<AuthUser?>.broadcast();
  AuthUser? _currentUser;

  @override
  Stream<AuthUser?> get authStateChanges => _authStateController.stream;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Future<AuthUser> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    // Artificial slight delay to simulate network call without storing raw password
    await Future.delayed(const Duration(milliseconds: 300));

    final user = AuthUser(
      id: 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
      email: email.trim().toLowerCase(),
      fullName: fullName.trim(),
      createdAt: DateTime.now(),
    );

    _currentUser = user;
    _authStateController.add(_currentUser);
    return user;
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final user = AuthUser(
      id: 'mock_user_existing',
      email: email.trim().toLowerCase(),
      fullName: 'User',
      createdAt: DateTime.now(),
    );

    _currentUser = user;
    _authStateController.add(_currentUser);
    return user;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
  }

  void dispose() {
    _authStateController.close();
  }
}
