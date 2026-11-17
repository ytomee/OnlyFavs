import 'package:flutter/material.dart';

import '../controllers/login_controller.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;

  const LoginScreen({super.key, required this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LoginController(authService: widget.authService);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_controller.isLoading) return;
    final error = _controller.validate();
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _controller.isLoading = true);
    final result = await _controller.login();
    if (!mounted) return;
    setState(() => _controller.isLoading = false);

    if (result['success'] == true) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Não foi possível entrar.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    tooltip: 'Voltar',
                  ),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      'OnlyFavs',
                      style: TextStyle(
                        color: AppTheme.primaryRed,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  const Text(
                    'Bem-vindo outra vez!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Inicia sessão na tua conta OnlyFavs',
                    style: TextStyle(fontSize: 15, color: AppTheme.grey),
                  ),
                  const SizedBox(height: 36),
                  CustomTextField(
                    controller: _controller.email,
                    label: 'Email',
                    hintText: 'tu@exemplo.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _controller.password,
                    label: 'Palavra-passe',
                    hintText: 'Insere a palavra-passe',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'A recuperação de palavra-passe ainda não está disponível.',
                            ),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Text(
                        'Esqueceste-te da palavra-passe?',
                        style: TextStyle(
                          color: AppTheme.primaryRed,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    text: _controller.isLoading ? 'A entrar...' : 'LOGIN',
                    onPressed: _controller.isLoading ? null : _login,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Não tens conta? ',
                        style: TextStyle(color: AppTheme.grey, fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: const Text(
                          'Criar conta',
                          style: TextStyle(
                            color: AppTheme.primaryRed,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
