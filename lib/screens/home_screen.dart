import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_nav_bar.dart';
import 'access_screen.dart';
import 'feed_screen.dart';
import 'profile_screen.dart';
import 'publish_screen.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  final AuthService authService;
  final ProfileService profileService;

  const HomeScreen({
    super.key,
    required this.authService,
    required this.profileService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  int _selectedIndex = 0;
  bool _hasOpenedProfile = false;

  static const _titles = ['OnlyFavs', 'Publicar', 'Acessos', 'O meu perfil'];

  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 3) _hasOpenedProfile = true;
    });
  }

  Future<void> _logout() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final result = await widget.authService.logout();
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result['success'] == true) {
      Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result['message'])));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authService.user;
    final sessionUserId = widget.authService.sessionUserId;
    if (user == null || sessionUserId == null) return const WelcomeScreen();

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.black,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        // Mantém cada página e a sua posição de scroll ao mudar de separador.
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            FeedScreen(
              name: user['Name'] as String,
              email: user['Email'] as String,
              isLoading: _isLoading,
              onLogout: _logout,
            ),
            const PublishScreen(),
            const AccessScreen(),
            if (_hasOpenedProfile)
              ProfileScreen(
                userId: sessionUserId,
                sessionUserId: sessionUserId,
                profileService: widget.profileService,
                onTabSelected: _selectTab,
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
      // Fora do scroll: fica sempre visível nas páginas da aplicação.
      bottomNavigationBar: AppNavBar(
        currentIndex: _selectedIndex,
        onTap: _selectTab,
      ),
    );
  }
}
