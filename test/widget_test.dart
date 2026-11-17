import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:onlyfavs/main.dart';
import 'package:onlyfavs/screens/home_screen.dart';
import 'package:onlyfavs/screens/login_screen.dart';
import 'package:onlyfavs/screens/profile_screen.dart';
import 'package:onlyfavs/screens/welcome_screen.dart';
import 'package:onlyfavs/services/auth_service.dart';

import 'auth_test_support.dart';
import 'profile_test_support.dart';

Future<void> openApp(WidgetTester tester, AuthService auth) async {
  final profiles = testProfileService(
    (_) async => jsonResponse({'ProfileInfo': testProfile}),
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    auth.dispose();
    profiles.dispose();
  });
  await tester.pumpWidget(
    OnlyFavsApp(authService: auth, profileService: profiles),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('sem User abre boas-vindas e valida o login', (tester) async {
    var requests = 0;
    final auth = testAuth((_) async {
      requests++;
      return jsonResponse({});
    });
    await openApp(tester, auth);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
    await tester.tap(find.text('Já tenho conta'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('LOGIN'));
    await tester.tap(find.text('LOGIN'));
    await tester.pumpAndSettle();
    expect(find.text('Preenche o email e a palavra-passe.'), findsOneWidget);
    expect(requests, 0);
  });

  testWidgets('receber User abre Home; sair impede voltar à conta', (
    tester,
  ) async {
    var requests = 0;
    final auth = testAuth((request) async {
      requests++;
      expect(request.url.path, endsWith('/Users/Login'));
      return jsonResponse({'User': testUser});
    });
    await openApp(tester, auth);
    await tester.tap(find.text('Já tenho conta'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'tomas@exemplo.com');
    await tester.enterText(find.byType(TextField).at(1), 'palavra-passe');
    await tester.ensureVisible(find.text('LOGIN'));
    await tester.tap(find.text('LOGIN'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Olá, Tomás!'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(tester.widget<ProfileScreen>(find.byType(ProfileScreen)).userId, 7);
    await tester.tap(find.text('Feed'));
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    expect(navigator.canPop(), isFalse);

    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();
    expect(requests, 1);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(navigator.canPop(), isFalse);
    expect(auth.token, isNull);
    expect(await const FlutterSecureStorage().readAll(), isEmpty);
  });

  testWidgets('User guardado reabre a Home sem rede', (tester) async {
    FlutterSecureStorage.setMockInitialValues({
      AuthService.userKey: jsonEncode(testUser),
    });
    var requests = 0;
    final auth = testAuth((_) async {
      requests++;
      throw http.ClientException('Sem rede');
    });
    await openApp(tester, auth);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('tomas@exemplo.com'), findsOneWidget);
    expect(auth.token, isNotNull);
    expect(requests, 0);
  });

  testWidgets('password errada mantém o ecrã de login', (tester) async {
    final auth = testAuth(
      (_) async => jsonResponse({'Message': 'Credenciais incorretas'}, 401),
    );
    await openApp(tester, auth);
    await tester.tap(find.text('Já tenho conta'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'tomas@exemplo.com');
    await tester.enterText(find.byType(TextField).at(1), 'errada');
    await tester.ensureVisible(find.text('LOGIN'));
    await tester.tap(find.text('LOGIN'));
    await tester.pumpAndSettle();
    expect(find.text('Email ou palavra-passe incorretos.'), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('registo vazio não faz pedidos ao servidor', (tester) async {
    var requests = 0;
    final auth = testAuth((_) async {
      requests++;
      return jsonResponse({});
    });
    await openApp(tester, auth);
    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();

    final submit = find.widgetWithText(ElevatedButton, 'Criar conta');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('Preenche todos os campos.'), findsOneWidget);
    expect(requests, 0);
  });

  testWidgets('criar conta envia os dados e regressa ao login', (tester) async {
    var requests = 0;
    final response = Completer<http.Response>();
    final auth = testAuth((request) async {
      requests++;
      expect(request.url.path, endsWith('/Users/Register'));
      expect(jsonDecode(request.body), {
        'Name': 'Tomás',
        'Username': 'tomas',
        'Email': 'tomas@exemplo.com',
        'Password': ' palavra-passe ',
      });
      return response.future;
    });
    await openApp(tester, auth);
    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), ' Tomás ');
    await tester.enterText(find.byType(TextField).at(1), ' tomas ');
    await tester.enterText(find.byType(TextField).at(2), ' TOMAS@exemplo.com ');
    await tester.enterText(find.byType(TextField).at(3), ' palavra-passe ');
    await tester.enterText(find.byType(TextField).at(4), ' palavra-passe ');
    final submit = find.widgetWithText(ElevatedButton, 'Criar conta');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();

    final loadingButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'A criar conta...'),
    );
    expect(loadingButton.onPressed, isNull);
    expect(requests, 1);

    response.complete(jsonResponse({}));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Conta criada com sucesso.'), findsOneWidget);
    expect(auth.user, isNull);
    expect(await const FlutterSecureStorage().readAll(), isEmpty);

    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });
}
