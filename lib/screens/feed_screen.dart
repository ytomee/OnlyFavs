import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

class FeedScreen extends StatelessWidget {
  final String name;
  final String email;
  final bool isLoading;
  final VoidCallback onLogout;

  const FeedScreen({
    super.key,
    required this.name,
    required this.email,
    required this.isLoading,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.account_circle_outlined,
                size: 80,
                color: AppTheme.primaryRed,
              ),
              const SizedBox(height: 20),
              Text(
                'Olá, $name!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(email, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              const Text(
                'Já tens sessão iniciada.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: isLoading ? 'A aguardar...' : 'Sair da conta',
                onPressed: isLoading ? null : onLogout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
