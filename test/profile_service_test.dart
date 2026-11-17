import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:onlyfavs/models/user_profile.dart';

import 'auth_test_support.dart';
import 'profile_test_support.dart';

void main() {
  test('GET envia o ID no URL, sem body, e lê os dados do servidor', () async {
    final service = testProfileService((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/OnlyFavs/rest/Profile/Get');
      expect(request.url.queryParameters, {'Id': '7'});
      expect(request.body, isEmpty);
      return jsonResponse({'ProfileInfo': testProfile, 'Message': ''});
    });
    addTearDown(service.dispose);
    final result = await service.getProfile(7);
    expect(result['success'], isTrue);
    final profile = result['profile'] as UserProfile;
    expect(profile.id, 7);
    expect(profile.name, 'Maria Pinto');
    expect(profile.username, 'maria');
    expect(profile.biography, testProfile['Biography']);
    expect(profile.isPublic, isTrue);
    expect(profile.publicationCount, 32);
    expect(profile.photoCount, 18);
    expect(profile.videoCount, 9);
  });

  test('PUT envia os dois IDs e os dados editáveis no body', () async {
    final service = testProfileService((request) async {
      expect(request.method, 'PUT');
      expect(request.url.path, '/OnlyFavs/rest/Profile/Update');
      expect(request.url.query, isEmpty);
      expect(request.headers['Content-Type'], contains('application/json'));
      expect(jsonDecode(request.body), {
        'SessionUserId': 7,
        'Id': 7,
        'Name': 'Maria Inês',
        'Username': 'maria.ines',
        'Biography': '',
      });
      return jsonResponse({
        'ProfileInfo': {
          ...testProfile,
          'Name': 'Maria Inês (servidor)',
          'Username': 'maria.ines',
          'Biography': '',
        },
      });
    });
    addTearDown(service.dispose);
    final result = await service.updateProfile(
      sessionUserId: 7,
      userId: 7,
      name: ' Maria Inês ',
      username: ' @maria.ines ',
      biography: '  ',
    );
    expect(result['success'], isTrue);
    expect((result['profile'] as UserProfile).name, 'Maria Inês (servidor)');
    expect((result['profile'] as UserProfile).biography, isEmpty);
  });

  test('aceita a resposta do GET sem biografia e visibilidade', () async {
    final service = testProfileService((request) async {
      expect(request.url.queryParameters, {'Id': '10'});
      return jsonResponse({
        'ProfileInfo': {
          'Id': 10,
          'Name': 'Utilizador de teste',
          'Username': 'utilizador',
          'PublicationCount': 3,
          'PhotoCount': 2,
          'VideoCount': 1,
        },
      });
    });
    addTearDown(service.dispose);
    final result = await service.getProfile(10);
    expect(result['success'], isTrue);
    final profile = result['profile'] as UserProfile;
    expect(profile.id, 10);
    expect(profile.biography, isEmpty);
    expect(profile.isPublic, isFalse);
    expect(profile.publicationCount, 3);
    expect(profile.photoCount, 2);
    expect(profile.videoCount, 1);
  });

  test(
    'campos opcionais omitidos ou nulos usam os valores por defeito',
    () async {
      final service = testProfileService(
        (_) async => jsonResponse({
          'ProfileInfo': {
            'Id': 7,
            'Name': 'Utilizador de teste',
            'Username': 'utilizador',
            'Biography': null,
            'IsPublic': null,
          },
        }),
      );
      addTearDown(service.dispose);
      final result = await service.getProfile(7);
      expect(result['success'], isTrue);
      final profile = result['profile'] as UserProfile;
      expect(profile.biography, isEmpty);
      expect(profile.isPublic, isFalse);
      expect(profile.publicationCount, 0);
      expect(profile.photoCount, 0);
      expect(profile.videoCount, 0);
    },
  );

  test(
    'IDs diferentes impedem editar outro perfil sem enviar um pedido',
    () async {
      var requests = 0;
      final service = testProfileService((_) async {
        requests++;
        return jsonResponse({'ProfileInfo': testProfile});
      });
      addTearDown(service.dispose);
      final result = await service.updateProfile(
        sessionUserId: 7,
        userId: 8,
        name: 'Outro utilizador',
        username: 'outro',
        biography: '',
      );
      expect(result['success'], isFalse);
      expect(result['message'], 'Só podes editar o teu perfil.');
      expect(requests, 0);
    },
  );

  for (final status in [400, 403, 404, 409]) {
    test('mantém a mensagem do servidor em HTTP $status', () async {
      final service = testProfileService(
        (_) async =>
            jsonResponse({'Message': 'Não foi possível guardar.'}, status),
      );
      addTearDown(service.dispose);
      final result = await service.updateProfile(
        sessionUserId: 7,
        userId: 7,
        name: 'Maria',
        username: 'maria',
        biography: '',
      );
      expect(result['success'], isFalse);
      expect(result['message'], 'Não foi possível guardar.');
    });
  }

  test('aceita erro de negócio com HTTP 200', () async {
    final service = testProfileService(
      (_) async => jsonResponse({
        'Success': false,
        'Message': 'Este username já está a ser utilizado.',
      }),
    );
    addTearDown(service.dispose);
    final result = await service.getProfile(7);
    expect(result['success'], isFalse);
    expect(result['message'], 'Este username já está a ser utilizado.');
  });

  for (final user in [
    null,
    <String, dynamic>{},
    {...testProfile, 'Id': 0},
  ]) {
    test(
      'GET mostra Message quando o servidor não devolve um perfil válido: $user',
      () async {
        final service = testProfileService(
          (_) async => jsonResponse({
            'ProfileInfo': user,
            'Message': 'Utilizador não encontrado.',
          }),
        );
        addTearDown(service.dispose);
        final result = await service.getProfile(7);
        expect(result['success'], isFalse);
        expect(result['message'], 'Utilizador não encontrado.');
      },
    );
  }

  test('GET preserva Message de um erro HTTP', () async {
    final service = testProfileService(
      (_) async => jsonResponse({
        'ProfileInfo': null,
        'Message': 'Utilizador não encontrado.',
      }, 404),
    );
    addTearDown(service.dispose);
    final result = await service.getProfile(7);
    expect(result['success'], isFalse);
    expect(result['message'], 'Utilizador não encontrado.');
  });

  for (final invalid in [
    <String, dynamic>{},
    {
      'ProfileInfo': {...testProfile, 'Id': 8},
    },
    {
      'ProfileInfo': {...testProfile, 'Biography': 123},
    },
    {
      'ProfileInfo': {...testProfile, 'PublicationCount': -1},
    },
    {
      'ProfileInfo': {...testProfile, 'IsPublic': 'true'},
    },
  ]) {
    test('rejeita resposta de perfil inválida: $invalid', () async {
      final service = testProfileService((_) async => jsonResponse(invalid));
      addTearDown(service.dispose);
      expect((await service.getProfile(7))['success'], isFalse);
    });
  }

  test('rede e timeout devolvem mensagens para nova tentativa', () async {
    final service = testProfileService((request) async {
      if (request.method == 'GET') throw http.ClientException('Sem rede');
      throw TimeoutException('Timeout');
    });
    addTearDown(service.dispose);
    expect(
      (await service.getProfile(7))['message'],
      contains('ligar ao servidor'),
    );
    final result = await service.updateProfile(
      sessionUserId: 7,
      userId: 7,
      name: 'Maria',
      username: 'maria',
      biography: '',
    );
    expect(result['success'], isFalse);
    expect(result['message'], contains('demorou'));
  });
}
