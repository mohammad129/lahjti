import 'dart:async';
import '../../../../core/network/api_client.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Backend-backed auth. The token remains runtime-only until secure storage is
/// configured for the target platform; it is never a build-time secret.
class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository(this._apiClient);
  final ApiClient _apiClient;
  final _changes = StreamController<AuthUser?>.broadcast();
  AuthUser? _user;
  String? _token;
  @override AuthUser? get currentUser => _user;
  @override Stream<AuthUser?> get authStateChanges => _changes.stream;

  @override
  Future<AuthUser> signUp({required String fullName, required String email, required String password}) async {
    final response = await _apiClient.post<dynamic>('/auth/register', data: {'email': email, 'password': password});
    return _apply(response.data, fullName);
  }
  @override
  Future<AuthUser> signIn({required String email, required String password}) async {
    final response = await _apiClient.post<dynamic>('/auth/login', data: {'email': email, 'password': password});
    return _apply(response.data, '');
  }
  AuthUser _apply(dynamic body, String fullName) {
    final data = body is Map ? body['data'] : null;
    if (data is! Map || data['token'] is! String || data['user'] is! Map) throw StateError('Invalid authentication response');
    final user = data['user'] as Map;
    _token = data['token'] as String;
    _apiClient.setAuthToken(_token);
    _user = AuthUser(id: '${user['id']}', email: '${user['email']}', fullName: fullName.isNotEmpty ? fullName : '${user['email']}', createdAt: DateTime.now());
    _changes.add(_user);
    return _user!;
  }
  @override
  Future<void> signOut() async {
    try { await _apiClient.post<dynamic>('/auth/logout'); } finally { _token = null; _user = null; _apiClient.setAuthToken(null); _changes.add(null); }
  }
  void dispose() => _changes.close();
}
