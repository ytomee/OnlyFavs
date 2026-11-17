import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/auth_service.dart';
import 'services/profile_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OnlyFavsApp());
}

class OnlyFavsApp extends StatefulWidget {
  final AuthService? authService;
  final ProfileService? profileService;

  const OnlyFavsApp({super.key, this.authService, this.profileService});

  @override
  State<OnlyFavsApp> createState() => _OnlyFavsAppState();
}

class _OnlyFavsAppState extends State<OnlyFavsApp> {
  late final AuthService _authService;
  late final ProfileService _profileService;
  late final Future<void> _loadUser;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _profileService = widget.profileService ?? ProfileService();
    _loadUser = _authService.restoreUser();
  }

  @override
  void dispose() {
    if (widget.authService == null) _authService.dispose();
    if (widget.profileService == null) _profileService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OnlyFavs',
      theme: AppTheme.lightTheme,
      // Para nos limites do scroll sem esticar o conteúdo.
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        overscroll: false,
        physics: const ClampingScrollPhysics(),
      ),
      home: FutureBuilder<void>(
        future: _loadUser,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (_authService.user != null) {
            return HomeScreen(
              authService: _authService,
              profileService: _profileService,
            );
          }
          return const WelcomeScreen();
        },
      ),
      routes: {
        '/welcome': (_) => const WelcomeScreen(),
        '/login': (_) => LoginScreen(authService: _authService),
        '/register': (_) => RegisterScreen(authService: _authService),
        '/home': (_) => HomeScreen(
          authService: _authService,
          profileService: _profileService,
        ),
      },
    );
  }
}
