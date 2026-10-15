import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../controllers/register_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final RegisterController _controller = RegisterController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToLogin() {
    // Deixa apenas a página inicial e a página de login na pilha.
    // Funciona quer tenhas vindo da página inicial ou do login.
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => route.isFirst,
    );
  }

  Future<void> _register() async {
    if (_controller.isLoading) return;

    if (!_controller.isValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preenche todos os campos.')),
      );
      return;
    }

    if (!_controller.isValidEmail()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduz um email válido.')),
      );
      return;
    }

    if (!_controller.passwordsMatch()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As palavras-passe não coincidem.')),
      );
      return;
    }

    setState(() {
      _controller.isLoading = true;
    });

    // Conserva a lógica existente no teu RegisterController.
    final result = await _controller.register();

    if (!mounted) return;

    setState(() {
      _controller.isLoading = false;
    });

    if (result['success'] == true) {
      Fluttertoast.showToast(
        msg: 'Conta criada com sucesso.',
        toastLength: Toast.LENGTH_SHORT,
      );
      _goToLogin();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ?? 'Não foi possível criar a conta.',
          ),
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
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 24,
            ),
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
                    'Criar conta',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Junta-te ao OnlyFavs',
                    style: TextStyle(fontSize: 15, color: AppTheme.grey),
                  ),
                  const SizedBox(height: 32),
                  CustomTextField(
                    controller: _controller.name,
                    label: 'Nome',
                    hintText: 'John Doe',
                    prefixIcon: Icons.person_outline,
                  ),
                  const SizedBox(height: 18),
                  CustomTextField(
                    controller: _controller.username,
                    label: 'Nome de utilizador',
                    hintText: '@username',
                    prefixIcon: Icons.alternate_email,
                  ),
                  const SizedBox(height: 18),
                  CustomTextField(
                    controller: _controller.email,
                    label: 'Email',
                    hintText: 'tu@exemplo.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 18),
                  CustomTextField(
                    controller: _controller.password,
                    label: 'Palavra-passe',
                    hintText: 'Insere a palavra-passe',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                  ),
                  const SizedBox(height: 18),
                  CustomTextField(
                    controller: _controller.confirmPassword,
                    label: 'Confirmar palavra-passe',
                    hintText: 'Repete a palavra-passe',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    text: _controller.isLoading ? 'A criar conta...' : 'Criar conta',
                    onPressed: _controller.isLoading ? () {} : _register,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Já tens conta? ',
                        style: TextStyle(
                          color: AppTheme.grey,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: _goToLogin,
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: AppTheme.primaryRed,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}