import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static const baseUrl =
      'https://personal-ctmif2sq.outsystemscloud.com/OnlyFavs/rest';

  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParameters,
  }) => _request('GET', endpoint, queryParameters: queryParameters);

  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) => _request('POST', endpoint, body: body ?? {});

  Future<Map<String, dynamic>> put(
    String endpoint, {
    required Map<String, dynamic> body,
  }) => _request('PUT', endpoint, body: body);

  Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint')
        .replace(queryParameters: queryParameters);
    final http.Response response;
    try {
      final request = http.Request(method, url);
      request.headers['Accept'] = 'application/json';
      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(body);
      }
      response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      return {
        'success': false,
        'message': 'O servidor demorou a responder. Tenta novamente.',
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Não foi possível ligar ao servidor.',
      };
    }

    if (kDebugMode) {
      debugPrint('$method $url -> HTTP ${response.statusCode}');
    }

    try {
      final data = response.body.trim().isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
      if (data is! Map<String, dynamic>) throw const FormatException();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': data};
      }

      return {
        'success': false,
        'statusCode': response.statusCode,
        'message': data['Message'] is String
            ? data['Message']
            : 'Não foi possível concluir o pedido (HTTP ${response.statusCode}).',
      };
    } on FormatException {
      return {
        'success': false,
        'statusCode': response.statusCode,
        'message': 'O servidor devolveu uma resposta inválida.',
      };
    }
  }

  void dispose() => _client.close();
}
