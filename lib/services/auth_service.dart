import 'api_client.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    return await _apiClient.post(
      '/Users/Register',
      body: {
        'Name': name,
        'Username': username,
        'Email': email,
        'Password': password,
      },
    );
  }
}