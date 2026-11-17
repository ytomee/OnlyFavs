import '../models/user_profile.dart';
import 'api_client.dart';

class ProfileService {
  final ApiClient _apiClient;

  ProfileService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> getProfile(int userId) async {
    final result = await _apiClient.get(
      '/Profile/Get',
      queryParameters: {'Id': userId.toString()},
    );
    return _readProfile(result, userId);
  }

  Future<Map<String, dynamic>> updateProfile({
    required int sessionUserId,
    required int userId,
    required String name,
    required String username,
    required String biography,
  }) async {
    if (sessionUserId != userId) {
      return {'success': false, 'message': 'Só podes editar o teu perfil.'};
    }
    final result = await _apiClient.put(
      '/Profile/Update',
      body: {
        'SessionUserId': sessionUserId,
        'Id': userId,
        'Name': name.trim(),
        'Username': username.trim().replaceFirst(RegExp(r'^@+'), ''),
        'Biography': biography.trim(),
      },
    );
    return _readProfile(result, userId);
  }

  Map<String, dynamic> _readProfile(Map<String, dynamic> result, int userId) {
    if (result['success'] != true) return result;
    final data = result['data'];
    final message = data is Map<String, dynamic> && data['Message'] is String
        ? (data['Message'] as String).trim()
        : '';
    if (data is Map<String, dynamic> && data['Success'] == false) {
      return {
        'success': false,
        'message': message.isNotEmpty
            ? message
            : 'Não foi possível concluir o pedido.',
      };
    }
    try {
      if (data is! Map<String, dynamic> ||
          data['ProfileInfo'] is! Map<String, dynamic>) {
        throw const FormatException();
      }
      final profile = UserProfile.fromJson(
        data['ProfileInfo'] as Map<String, dynamic>,
      );
      if (profile.id != userId) throw const FormatException();
      return {'success': true, 'profile': profile};
    } on FormatException {
      return {
        'success': false,
        'message': message.isNotEmpty
            ? message
            : 'O servidor devolveu dados de perfil inválidos.',
      };
    }
  }

  void dispose() => _apiClient.dispose();
}
