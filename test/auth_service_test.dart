import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:onlyfavs/controllers/login_controller.dart';
import 'package:onlyfavs/services/auth_service.dart';

import 'auth_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'envia email e password, recebe User e cria token apenas no Flutter',
    () async {
      final auth = testAuth((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, endsWith('/Users/Login'));
        expect(request.headers.containsKey('Authorization'), isFalse);
        expect(jsonDecode(request.body), {
          'Email': 'tomas@exemplo.com',
          'Password': ' palavra-passe ',
        });
        return jsonResponse({'User': testUser});
      });
      addTearDown(auth.dispose);

      final result = await auth.login(
        email: ' TOMAS@exemplo.com ',
        password: ' palavra-passe ',
      );
      expect(result['success'], isTrue);
      expect(auth.user, testUser);
      expect(auth.sessionUserId, testUser['Id']);
      expect(jsonDecode(utf8.decode(base64Url.decode(auth.token!))), testUser);
      expect(await const FlutterSecureStorage().readAll(), {
        AuthService.userKey: jsonEncode(testUser),
      });
    },
  );

  test('guarda só os dados públicos do User', () async {
    final auth = testAuth(
      (_) async => jsonResponse({
        'User': {...testUser, 'Password': 'nao-guardar', 'IsAdmin': true},
      }),
    );
    addTearDown(auth.dispose);

    expect(
      (await auth.login(
        email: 'tomas@exemplo.com',
        password: 'teste',
      ))['success'],
      isTrue,
    );
    expect(auth.user, testUser);
    expect(auth.sessionUserId, testUser['Id']);
    expect(jsonDecode(utf8.decode(base64Url.decode(auth.token!))), testUser);
    expect(
      await const FlutterSecureStorage().read(key: AuthService.userKey),
      jsonEncode(testUser),
    );
  });

  test('password errada não guarda User nem cria token', () async {
    final auth = testAuth(
      (_) async => jsonResponse({'Message': 'Credenciais incorretas'}, 401),
    );
    addTearDown(auth.dispose);

    final result = await auth.login(
      email: 'tomas@exemplo.com',
      password: 'errada',
    );
    expect(result['success'], isFalse);
    expect(result['message'], 'Email ou palavra-passe incorretos.');
    expect(auth.user, isNull);
    expect(auth.sessionUserId, isNull);
    expect(auth.token, isNull);
    expect(await const FlutterSecureStorage().readAll(), isEmpty);
  });

  for (final invalid in [
    <String, dynamic>{},
    {
      'User': {'Id': 0, 'Name': 'Tomás', 'Email': 'tomas@exemplo.com'},
    },
    {'Success': false, 'User': testUser},
  ]) {
    test('rejeita resposta de login inválida: $invalid', () async {
      final auth = testAuth((_) async => jsonResponse(invalid));
      addTearDown(auth.dispose);
      expect(
        (await auth.login(
          email: 'tomas@exemplo.com',
          password: 'teste',
        ))['success'],
        isFalse,
      );
      expect(auth.user, isNull);
      expect(auth.token, isNull);
      expect(await const FlutterSecureStorage().readAll(), isEmpty);
    });
  }

  test('recupera User e recria token sem consultar o servidor', () async {
    FlutterSecureStorage.setMockInitialValues({
      AuthService.userKey: jsonEncode(testUser),
    });
    var requests = 0;
    final auth = testAuth((_) async {
      requests++;
      throw http.ClientException('Sem rede');
    });
    addTearDown(auth.dispose);

    await auth.restoreUser();
    expect(requests, 0);
    expect(auth.user, testUser);
    expect(jsonDecode(utf8.decode(base64Url.decode(auth.token!))), testUser);
  });

  test('dados locais corrompidos deixam o acesso por iniciar', () async {
    FlutterSecureStorage.setMockInitialValues({
      AuthService.userKey: 'nao e JSON',
    });
    final auth = testAuth((_) async => throw StateError('Pedido inesperado'));
    addTearDown(auth.dispose);

    await auth.restoreUser();
    expect(auth.user, isNull);
    expect(auth.token, isNull);
  });

  test('logout apaga User e token localmente, sem rede', () async {
    FlutterSecureStorage.setMockInitialValues({
      AuthService.userKey: jsonEncode(testUser),
    });
    var requests = 0;
    final auth = testAuth((_) async {
      requests++;
      throw http.ClientException('Sem rede');
    });
    addTearDown(auth.dispose);
    await auth.restoreUser();

    expect((await auth.logout())['success'], isTrue);
    expect(requests, 0);
    expect(auth.user, isNull);
    expect(auth.token, isNull);
    expect(await const FlutterSecureStorage().readAll(), isEmpty);
  });

  test('erro de rede não inicia acesso', () async {
    final auth = testAuth((_) async => throw http.ClientException('Sem rede'));
    addTearDown(auth.dispose);
    expect(
      (await auth.login(
        email: 'tomas@exemplo.com',
        password: 'teste',
      ))['success'],
      isFalse,
    );
    expect(auth.user, isNull);
    expect(auth.token, isNull);
  });

  test('timeout apresenta erro e permite tentar novamente', () async {
    final auth = testAuth((_) async => throw TimeoutException('Timeout'));
    addTearDown(auth.dispose);
    final result = await auth.login(
      email: 'tomas@exemplo.com',
      password: 'teste',
    );
    expect(result['success'], isFalse);
    expect(result['message'], contains('demorou'));
    expect(auth.user, isNull);
  });

  test('valida os campos sem alterar a password', () {
    final auth = testAuth((_) async => throw StateError('Pedido inesperado'));
    final controller = LoginController(authService: auth);
    addTearDown(auth.dispose);
    addTearDown(controller.dispose);
    expect(controller.validate(), isNotNull);
    controller.email.text = 'email-invalido';
    controller.password.text = ' palavra-passe ';
    expect(controller.validate(), 'Introduz um email válido.');
    controller.email.text = ' TOMAS@exemplo.com ';
    expect(controller.validate(), isNull);
    expect(controller.password.text, ' palavra-passe ');
  });
}
