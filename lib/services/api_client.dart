import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'https://personal-ctmif2sq.outsystemscloud.com/OnlyFavs/rest';

  Future<Map<String, dynamic>> post(
      String endpoint, {
        Map<String, dynamic>? body,
      }) async {
    final url = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body ?? {}),
      );

      final data = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : <String, dynamic>{};

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': data,
        };
      }

      return {
        'success': false,
        'message': data is Map
            ? data['Message'] ??
            data['message'] ??
            'Não foi possível concluir o pedido.'
            : 'Não foi possível concluir o pedido.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Não foi possível ligar ao servidor.',
      };
    }
  }
}