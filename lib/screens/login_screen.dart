import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import 'register_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Logo
                  Center(
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

                  const SizedBox(height: 60),

                  // Title
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
                    'Faça login na sua conta OnlyFavs',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.grey,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Email
                  const CustomTextField(
                    label: 'Email',
                    hintText: 'tu@exemplo.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 20),

                  // Password
                  const CustomTextField(
                    label: 'Password',
                    hintText: 'Insira a password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                  ),

                  const SizedBox(height: 12),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'Esqueceu-se da palavra-passe?',
                        style: TextStyle(
                          color: AppTheme.primaryRed,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Login button
                  PrimaryButton(
                    text: 'LOGIN',
                    onPressed: () {
                      // Login será implementado posteriormente.
                    },
                  ),

                  const SizedBox(height: 28),

                  // Register
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Não tem conta? ",
                        style: TextStyle(
                          color: AppTheme.grey,
                          fontSize: 14,
                        ),
                      ),

                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
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