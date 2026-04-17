import '../models/user.dart';
import 'api_client.dart';
import 'token_storage.dart';

class AuthResult {
  final String token;
  final User user;
  AuthResult({required this.token, required this.user});
}

class AuthService {
  final ApiClient _api;
  final TokenStorage _storage;

  AuthService({ApiClient? api, TokenStorage? storage})
      : _api = api ?? ApiClient(),
        _storage = storage ?? TokenStorage();

  Future<AuthResult> register({
    required String nome,
    required String email,
    required String password,
    required int eta,
    required String sesso,
    required bool consensoPrivacy,
  }) async {
    final data = await _api.post('/utenti', auth: false, body: {
      'nome': nome,
      'email': email,
      'password': password,
      'eta': eta,
      'sesso': sesso,
      'consenso_privacy': consensoPrivacy,
    });
    return _handle(data);
  }

  Future<AuthResult> login(String email, String password) async {
    final data = await _api.post('/login', auth: false, body: {
      'email': email,
      'password': password,
    });
    return _handle(data);
  }

  Future<User> me() async {
    final data = await _api.get('/me');
    return User.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<User> updateProfile(int id, Map<String, dynamic> body) async {
    await _api.put('/utenti/$id', body: body);
    return me();
  }

  Future<void> deleteAccount(int id) async {
    await _api.delete('/utenti/$id');
    await logout();
  }

  Future<void> logout() => _storage.clear();

  Future<String?> token() => _storage.read();

  Future<AuthResult> _handle(dynamic data) async {
    final m = Map<String, dynamic>.from(data as Map);
    final token = m['token']?.toString() ?? '';
    if (token.isEmpty) {
      throw ApiException(500, 'Token mancante nella risposta');
    }
    await _storage.save(token);
    final userJson = m['user'] is Map
        ? Map<String, dynamic>.from(m['user'] as Map)
        : <String, dynamic>{'id': m['id'], 'email': '', 'nome': ''};
    return AuthResult(token: token, user: User.fromJson(userJson));
  }
}
