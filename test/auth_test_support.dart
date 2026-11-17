import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:onlyfavs/services/api_client.dart';
import 'package:onlyfavs/services/auth_service.dart';

const testUser = {
  'Id': 7,
  'Name': 'Tomás',
  'Username': 'tomas',
  'Email': 'tomas@exemplo.com',
};

http.Response jsonResponse(Map<String, dynamic> data, [int status = 200]) {
  return http.Response(
    jsonEncode(data),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

AuthService testAuth(Future<http.Response> Function(http.Request) handler) {
  return AuthService(apiClient: ApiClient(client: MockClient(handler)));
}
