import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlyfavs/main.dart';
import 'package:onlyfavs/screens/profile_screen.dart';
import 'package:onlyfavs/services/auth_service.dart';

import 'auth_test_support.dart';
import 'profile_test_support.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      AuthService.userKey: jsonEncode(testUser),
    });
  });

  testWidgets('navbar mantém-se e perfil mostra dados da API, fora da sessão', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({
      AuthService.userKey: jsonEncode({...testUser, 'Id': 10}),
    });
    var requests = 0;
    final auth = testAuth(
      (_) async => throw StateError('Pedido de autenticação inesperado'),
    );
    final profiles = testProfileService((request) async {
      requests++;
      expect(request.method, 'GET');
      expect(request.url.queryParameters, {'Id': '10'});
      expect(request.body, isEmpty);
      return jsonResponse({
        'ProfileInfo': {...testProfile, 'Id': 10},
      });
    });
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      auth.dispose();
      profiles.dispose();
    });
    await tester.pumpWidget(
      OnlyFavsApp(authService: auth, profileService: profiles),
    );
    await tester.pumpAndSettle();
    expect(requests, 0);
    expect(auth.sessionUserId, 10);

    final navbar = find.byType(BottomNavigationBar);
    for (final tab in ['Publicar', 'Acessos', 'Perfil']) {
      await tester.tap(find.descendant(of: navbar, matching: find.text(tab)));
      await tester.pumpAndSettle();
      expect(navbar, findsOneWidget);
    }

    final profile = tester.widget<ProfileScreen>(find.byType(ProfileScreen));
    expect(profile.userId, 10);
    expect(profile.sessionUserId, 10);
    expect(find.text('Maria Pinto'), findsOneWidget);
    expect(find.text('@maria'), findsOneWidget);
    expect(find.text('Tomás'), findsNothing);
    expect(find.text(testProfile['Biography'] as String), findsOneWidget);
    expect(find.text('32 publicações'), findsOneWidget);
    expect(find.text('18 fotografias'), findsOneWidget);
    expect(find.text('9 vídeos'), findsOneWidget);
    final images = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => (image.image as AssetImage).assetName);
    expect(
      images,
      containsAll(['assets/images/user.jpg', 'assets/images/banner.jpg']),
    );

    final edit = find.widgetWithText(FilledButton, 'Editar perfil');
    final share = find.widgetWithText(FilledButton, 'Partilhar');
    final configure = find.widgetWithText(
      TextButton,
      'Configurar acesso e preços →',
    );
    expect(tester.widget<FilledButton>(edit).onPressed, isNotNull);
    expect(tester.widget<FilledButton>(share).onPressed, isNull);
    expect(tester.widget<TextButton>(configure).onPressed, isNull);
    await tester.ensureVisible(share);
    await tester.tap(share);
    await tester.ensureVisible(configure);
    await tester.tap(configure);
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(requests, 1);
  });

  testWidgets(
    'outro perfil só mostra os dados e o próprio mostra os controlos',
    (tester) async {
      final requestedIds = <int>[];
      final profiles = testProfileService((request) async {
        expect(request.method, 'GET');
        expect(request.body, isEmpty);
        final id = int.parse(request.url.queryParameters['Id']!);
        requestedIds.add(id);
        return jsonResponse({
          'ProfileInfo': {
            ...testProfile,
            'Id': id,
            'Name': id == 7 ? 'Maria Pinto' : 'João Silva',
            'Username': id == 7 ? 'maria' : 'joao',
            'Biography': '',
            'PublicationCount': 0,
            'PhotoCount': 0,
            'VideoCount': 0,
          },
        });
      });
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        profiles.dispose();
      });

      Widget page(int userId, int sessionUserId) => MaterialApp(
        home: Scaffold(
          body: ProfileScreen(
            userId: userId,
            sessionUserId: sessionUserId,
            profileService: profiles,
            onTabSelected: (_) {},
          ),
        ),
      );

      await tester.pumpWidget(page(42, 7));
      await tester.pumpAndSettle();
      expect(find.text('João Silva'), findsOneWidget);
      expect(find.text('@joao'), findsOneWidget);
      expect(find.text('Publicações'), findsOneWidget);
      expect(find.text('Ainda não há biografia.'), findsOneWidget);
      expect(find.text('Ainda não há publicações.'), findsOneWidget);
      expect(find.text('Editar perfil'), findsNothing);
      expect(find.text('Partilhar'), findsNothing);
      expect(find.text('Configurar acesso e preços →'), findsNothing);

      // A mesma página passa a carregar o próprio perfil quando muda o ID.
      await tester.pumpWidget(page(7, 7));
      await tester.pumpAndSettle();
      expect(find.text('Maria Pinto'), findsOneWidget);
      expect(find.text('João Silva'), findsNothing);
      expect(find.text('As minhas publicações'), findsOneWidget);
      expect(find.text('Editar perfil'), findsOneWidget);
      expect(find.text('Partilhar'), findsOneWidget);
      expect(requestedIds, [42, 7]);

      // A identidade da sessão é independente do ID do perfil apresentado.
      await tester.pumpWidget(page(7, 99));
      await tester.pumpAndSettle();
      expect(find.text('Maria Pinto'), findsOneWidget);
      expect(find.text('Editar perfil'), findsNothing);
      expect(find.text('Partilhar'), findsNothing);
      expect(requestedIds, [42, 7]);
    },
  );

  testWidgets('perfil faz scroll sem mover a navbar e mantém a posição', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = testAuth((_) async => jsonResponse({}));
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
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    final navbar = find.byType(BottomNavigationBar);
    final navbarPosition = tester.getRect(navbar);
    final scrollable = find.descendant(
      of: find.byType(ProfileScreen),
      matching: find.byType(Scrollable),
    );
    final scrollState = tester.state<ScrollableState>(scrollable);
    expect(scrollState.position.physics, isA<ClampingScrollPhysics>());

    await tester.drag(scrollable, const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(tester.getRect(navbar), navbarPosition);
    expect(
      find.text('As publicações vão aparecer aqui.').hitTestable(),
      findsOneWidget,
    );
    final offset = scrollState.position.pixels;
    expect(offset, greaterThan(0));
    // Tentar ultrapassar o fim mantém o conteúdo dentro dos seus limites.
    await tester.drag(scrollable, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(scrollState.position.pixels, scrollState.position.maxScrollExtent);
    expect(tester.getRect(navbar), navbarPosition);

    await tester.tap(find.text('Feed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(scrollState.position.pixels, offset);
    expect(tester.takeException(), isNull);

    // Verifica também a disposição em paisagem num ecrã baixo.
    tester.view.physicalSize = const Size(800, 400);
    await tester.pumpAndSettle();
    expect(navbar, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
