import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:onlyfavs/main.dart';
import 'package:onlyfavs/screens/edit_profile_screen.dart';
import 'package:onlyfavs/services/auth_service.dart';

import 'auth_test_support.dart';
import 'profile_test_support.dart';

Future<AuthService> openProfile(
  WidgetTester tester,
  Future<http.Response> Function(http.Request) handler,
) async {
  final auth = testAuth((_) async => throw StateError('Pedido inesperado'));
  final profiles = testProfileService(handler);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    auth.dispose();
    profiles.dispose();
  });
  await tester.pumpWidget(
    OnlyFavsApp(authService: auth, profileService: profiles),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Perfil'));
  await tester.pumpAndSettle();
  return auth;
}

Future<void> openEditor(WidgetTester tester) async {
  final edit = find.widgetWithText(FilledButton, 'Editar perfil');
  await tester.ensureVisible(edit);
  await tester.tap(edit);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      AuthService.userKey: jsonEncode(testUser),
    });
  });

  testWidgets(
    'guardar envia os campos, impede duplicados e mostra a resposta',
    (tester) async {
      final response = Completer<http.Response>();
      var saves = 0;
      var loads = 0;
      final auth = await openProfile(tester, (request) async {
        if (request.method == 'GET') {
          loads++;
          expect(request.url.queryParameters, {'Id': '7'});
          return jsonResponse({
            'ProfileInfo': loads == 1
                ? testProfile
                : {
                    ...testProfile,
                    'Name': 'Maria Atualizada',
                    'Username': 'maria.atual',
                    'Biography': 'Biografia atual no servidor.',
                  },
          });
        }
        saves++;
        expect(request.method, 'PUT');
        expect(request.url.path, '/OnlyFavs/rest/Profile/Update');
        expect(request.url.query, isEmpty);
        expect(jsonDecode(request.body), {
          'SessionUserId': 7,
          'Id': 7,
          'Name': 'Maria Inês',
          'Username': 'maria.ines',
          'Biography': 'Nova biografia.',
        });
        return response.future;
      });
      await openEditor(tester);
      expect(loads, 2);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      final fields = find.byType(TextFormField);
      expect(
        tester.widget<TextFormField>(fields.at(0)).controller!.text,
        'Maria Atualizada',
      );
      expect(
        tester.widget<TextFormField>(fields.at(1)).controller!.text,
        'maria.atual',
      );
      expect(
        tester.widget<TextFormField>(fields.at(2)).controller!.text,
        'Biografia atual no servidor.',
      );

      await tester.enterText(fields.at(0), ' Maria Inês ');
      await tester.enterText(fields.at(1), '@maria.ines');
      await tester.enterText(fields.at(2), ' Nova biografia. ');
      final save = find.widgetWithText(ElevatedButton, 'Guardar alterações');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pump();
      final loading = find.widgetWithText(ElevatedButton, 'A guardar...');
      expect(tester.widget<ElevatedButton>(loading).onPressed, isNull);
      expect(
        tester
            .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
            .onTap,
        isNull,
      );
      await tester.tap(loading);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(EditProfileScreen), findsOneWidget);
      expect(saves, 1);

      response.complete(
        jsonResponse({
          'ProfileInfo': {
            ...testProfile,
            'Name': 'Maria Inês — confirmado',
            'Username': 'maria.ines',
            'Biography': 'Nova biografia.',
          },
        }),
      );
      await tester.pumpAndSettle();
      expect(find.byType(EditProfileScreen), findsNothing);
      expect(find.text('Maria Inês — confirmado'), findsOneWidget);
      expect(find.text('@maria.ines'), findsOneWidget);
      expect(find.text('Nova biografia.'), findsOneWidget);
      expect(find.text('Perfil atualizado com sucesso.'), findsOneWidget);
      expect(auth.user, testUser);
    },
  );

  testWidgets('cancelar descarta alterações sem enviar PUT', (tester) async {
    var requests = 0;
    await openProfile(tester, (request) async {
      requests++;
      expect(request.method, 'GET');
      return jsonResponse({'ProfileInfo': testProfile});
    });
    await openEditor(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Alteração local');
    final cancel = find.widgetWithText(FilledButton, 'Cancelar');
    await tester.ensureVisible(cancel);
    await tester.tap(cancel);
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileScreen), findsNothing);
    expect(find.text('Maria Pinto'), findsOneWidget);
    expect(requests, 2);
  });

  testWidgets('erro ao guardar mantém os campos e permite tentar novamente', (
    tester,
  ) async {
    var saves = 0;
    await openProfile(tester, (request) async {
      if (request.method == 'GET') {
        return jsonResponse({'ProfileInfo': testProfile});
      }
      saves++;
      return jsonResponse({
        'Message': 'Este username já está a ser utilizado.',
      }, 409);
    });
    await openEditor(tester);
    await tester.enterText(find.byType(TextFormField).at(1), 'maria.nova');
    final save = find.widgetWithText(ElevatedButton, 'Guardar alterações');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Este username já está a ser utilizado.'), findsOneWidget);
    expect(find.byType(EditProfileScreen), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).at(1))
          .controller!
          .text,
      'maria.nova',
    );
    expect(tester.widget<ElevatedButton>(save).onPressed, isNotNull);
    expect(saves, 1);
  });

  testWidgets('nome e username inválidos não enviam alterações', (
    tester,
  ) async {
    var requests = 0;
    await openProfile(tester, (request) async {
      requests++;
      expect(request.method, 'GET');
      return jsonResponse({'ProfileInfo': testProfile});
    });
    await openEditor(tester);
    await tester.enterText(find.byType(TextFormField).at(0), '  ');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'nome com espaços',
    );
    final save = find.widgetWithText(ElevatedButton, 'Guardar alterações');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Introduz o teu nome.'), findsOneWidget);
    expect(find.text('O username não pode ter espaços.'), findsOneWidget);
    expect(requests, 2);
  });

  testWidgets('erro na consulta mostra nova tentativa sem dados da sessão', (
    tester,
  ) async {
    var requests = 0;
    await openProfile(tester, (request) async {
      requests++;
      if (requests == 1) {
        return jsonResponse({
          'ProfileInfo': null,
          'Message': 'Perfil indisponível.',
        });
      }
      return jsonResponse({'ProfileInfo': testProfile});
    });
    expect(find.text('Perfil indisponível.'), findsOneWidget);
    expect(find.text('Tomás'), findsNothing);
    expect(find.text('@tomas'), findsNothing);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Maria Pinto'), findsOneWidget);
    expect(requests, 2);
  });

  testWidgets(
    'edição mostra o erro do GET e volta a carregar antes de editar',
    (tester) async {
      var loads = 0;
      await openProfile(tester, (request) async {
        expect(request.method, 'GET');
        loads++;
        if (loads == 2) {
          return jsonResponse({
            'ProfileInfo': null,
            'Message': 'Não foi possível carregar o perfil para edição.',
          }, 503);
        }
        return jsonResponse({'ProfileInfo': testProfile});
      });
      await openEditor(tester);
      expect(find.byType(TextFormField), findsNothing);
      expect(
        find.text('Não foi possível carregar o perfil para edição.'),
        findsOneWidget,
      );
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(loads, 3);
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'Maria Pinto',
      );
    },
  );

  testWidgets('voltar enquanto carrega a edição cancela a página sem erros', (
    tester,
  ) async {
    var loads = 0;
    final response = Completer<http.Response>();
    await openProfile(tester, (request) async {
      expect(request.method, 'GET');
      loads++;
      if (loads == 1) return jsonResponse({'ProfileInfo': testProfile});
      return response.future;
    });
    final edit = find.widgetWithText(FilledButton, 'Editar perfil');
    await tester.ensureVisible(edit);
    await tester.tap(edit);
    // A resposta está pendente: confirma o carregamento e permite voltar.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileScreen), findsNothing);
    response.complete(jsonResponse({'ProfileInfo': testProfile}));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(loads, 2);
  });

  testWidgets(
    'edição faz scroll com teclado e navbar navega para outros separadores',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await openProfile(
        tester,
        (_) async => jsonResponse({'ProfileInfo': testProfile}),
      );
      await openEditor(tester);
      final navbar = find.byType(BottomNavigationBar);
      final position = tester.getRect(navbar);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(navbar), position);
      await tester.showKeyboard(find.byType(TextFormField).at(2));
      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      final save = find.widgetWithText(ElevatedButton, 'Guardar alterações');
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      expect(save.hitTestable(), findsOneWidget);
      expect(tester.getRect(navbar), position);
      expect(tester.takeException(), isNull);
      await tester.tap(
        find.descendant(of: navbar, matching: find.text('Publicar')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(EditProfileScreen), findsNothing);
      expect(tester.widget<BottomNavigationBar>(navbar).currentIndex, 1);
    },
  );
}
