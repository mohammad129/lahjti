import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/mock_auth_repository.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Provider for the abstract [AuthRepository].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repository = MockAuthRepository();
  ref.onDispose(() => repository.dispose());
  return repository;
});

/// Auth state holder
class AuthState {
  final AuthUser? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({this.user, this.isLoading = false, this.errorMessage});

  bool get isAuthenticated => user != null;

  AuthState copyWith({AuthUser? user, bool? isLoading, String? errorMessage}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// State notifier for user authentication operations
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository)
    : super(AuthState(user: _repository.currentUser));

  Future<AuthUser?> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _repository.signUp(
        fullName: fullName,
        email: email,
        password: password,
      );
      state = state.copyWith(user: user, isLoading: false);
      return user;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthState();
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});
