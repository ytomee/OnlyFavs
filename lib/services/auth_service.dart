import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';

class AuthService {
  static const userKey = 'onlyfavs_user';

  final ApiClient _apiClient;
  final FlutterSecureStorage _storage;

  Map<String, dynamic>? user;
  String? token;

  int? get sessionUserId => user?['Id'] as int?;

  AuthService({ApiClient? apiClient, FlutterSecureStorage? storage})
    : _apiClient = apiClient ?? ApiClient(),
      _storage = storage ?? const FlutterSecureStorage();

  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String username,
    required String email,
    required String password,
  }) {
    return _apiClient.post(
      '/Users/Register',
      body: {
        'Name': name,
        'Username': username,
        'Email': email.trim().toLowerCase(),
        'Password': password,
      },
    );
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final result = await _apiClient.post(
      '/Users/Login',
      body: {'Email': email.trim().toLowerCase(), 'Password': password},
    );

    if (result['success'] != true) {
      if (result['statusCode'] == 401) {
        result['message'] = 'Email ou palavra-passe incorretos.';
      }
      return result;
    }

    final loggedUser = _readUser(result['data']);
    if (loggedUser == null) {
      return {
        'success': false,
        'message': 'O servidor não devolveu um utilizador válido.',
      };
    }

    try {
      await _storage.write(key: userKey, value: jsonEncode(loggedUser));
      _setUser(loggedUser);
      return {'success': true};
    } catch (_) {
      return {
        'success': false,
        'message': 'Não foi possível guardar o utilizador neste dispositivo.',
      };
    }
  }

  Future<void> restoreUser() async {
    user = null;
    token = null;
    try {
      final saved = await _storage.read(key: userKey);
      if (saved == null) return;

      final savedUser = _readUser({'User': jsonDecode(saved)});
      if (savedUser == null) {
        await _storage.delete(key: userKey);
        return;
      }
      _setUser(savedUser);
    } catch (_) {
      // Se não conseguir ler os dados, abre as boas-vindas.
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      await _storage.delete(key: userKey);
      user = null;
      token = null;
      return {'success': true};
    } catch (_) {
      return {
        'success': false,
        'message':
            'Não foi possível apagar os dados guardados. Tenta novamente.',
      };
    }
  }

  void _setUser(Map<String, dynamic> user) {
    this.user = user;
    // Identificador local em Base64. Não é JWT nem autentica pedidos ao servidor.
    token = base64Url.encode(utf8.encode(jsonEncode(user)));
  }

  Map<String, dynamic>? _readUser(dynamic data) {
    if (data is! Map<String, dynamic>) return null;
    if (data['Success'] == false) return null;
    final user = data['User'];
    if (user is! Map<String, dynamic> ||
        user['Id'] is! int ||
        (user['Id'] as int) <= 0 ||
        user['Name'] is! String ||
        user['Email'] is! String) {
      return null;
    }
    return {
      'Id': user['Id'],
      'Name': user['Name'],
      if (user['Username'] is String) 'Username': user['Username'],
      'Email': user['Email'],
    };
  }

  void dispose() => _apiClient.dispose();
}
