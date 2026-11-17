import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:onlyfavs/services/api_client.dart';
import 'package:onlyfavs/services/profile_service.dart';

const testProfile = {
  'Id': 7,
  'Name': 'Maria Pinto',
  'Username': 'maria',
  'Biography': 'Crio e partilho os meus pequenos momentos.',
  'IsPublic': true,
  'PublicationCount': 32,
  'PhotoCount': 18,
  'VideoCount': 9,
};

ProfileService testProfileService(
  Future<http.Response> Function(http.Request) handler,
) {
  return ProfileService(apiClient: ApiClient(client: MockClient(handler)));
}
