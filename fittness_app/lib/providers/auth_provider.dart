import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _auth;
  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  String? _error;
  bool _loading = false;

  AuthProvider({AuthService? service}) : _auth = service ?? AuthService();

  AuthStatus get status => _status;
  User? get user => _user;
  String? get error => _error;
  bool get loading => _loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> bootstrap() async {
    final t = await _auth.token();
    if (t == null || t.isEmpty) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      _user = await _auth.me();
      _status = AuthStatus.authenticated;
    } catch (_) {
      await _auth.logout();
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    return _run(() async {
      final r = await _auth.login(email, password);
      _user = r.user;
      _status = AuthStatus.authenticated;
    });
  }

  Future<bool> register({
    required String nome,
    required String email,
    required String password,
    required int eta,
    required String sesso,
    required bool consensoPrivacy,
  }) async {
    return _run(() async {
      final r = await _auth.register(
        nome: nome,
        email: email,
        password: password,
        eta: eta,
        sesso: sesso,
        consensoPrivacy: consensoPrivacy,
      );
      _user = r.user;
      _status = AuthStatus.authenticated;
    });
  }

  Future<bool> refreshMe() async {
    try {
      _user = await _auth.me();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> body) async {
    if (_user == null) return false;
    return _run(() async {
      _user = await _auth.updateProfile(_user!.id, body);
    });
  }

  Future<void> logout() async {
    await _auth.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> deleteAccount() async {
    if (_user == null) return false;
    return _run(() async {
      await _auth.deleteAccount(_user!.id);
      _user = null;
      _status = AuthStatus.unauthenticated;
    });
  }

  Future<bool> _run(Future<void> Function() fn) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await fn();
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
    return false;
  }
}
