import '../models/auth_user.dart';

/// Abstract contract for authentication operations.
/// Production implementation will hook into backend / OAuth / Firebase / Supabase.
abstract class AuthRepository {
  /// Stream of authentication state changes
  Stream<AuthUser?> get authStateChanges;

  /// Current authenticated user (if any)
  AuthUser? get currentUser;

  /// Registers a new user account.
  /// Passwords must never be logged or stored in plain-text.
  Future<AuthUser> signUp({
    required String fullName,
    required String email,
    required String password,
  });

  /// Signs in an existing user.
  Future<AuthUser> signIn({required String email, required String password});

  /// Signs out the current session.
  Future<void> signOut();
}
