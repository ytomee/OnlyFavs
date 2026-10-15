
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 700;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 488),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    isCompact ? 12 : 24,
                    24,
                    isCompact ? 12 : 20,
                  ),
                  child: Column(
                    children: [
                      // Logótipo no topo
                      Image.asset(
                        'assets/images/logo.png',
                        height: isCompact ? 42 : 52,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Text(
                            'OnlyFavs',
                            style: TextStyle(
                              color: AppTheme.primaryRed,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.5,
                            ),
                          );
                        },
                      ),

                      // Espaço flexível entre o logótipo e o conteúdo
                      const Spacer(flex: 2),

                      // Conteúdo central
                      Flexible(
                        flex: 8,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'O teu conteúdo.\nA tua comunidade.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.black,
                                  fontSize: 30,
                                  height: 1.15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.8,
                                ),
                              ),

                              const SizedBox(height: 12),

                              const Text(
                                'Cria, partilha os teus momentos e aproxima-te '
                                'das pessoas que mais gostam do teu conteúdo.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.grey,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),

                              SizedBox(height: isCompact ? 20 : 28),

                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: AspectRatio(
                                  aspectRatio: 1440 / 840,
                                  child: Image.asset(
                                    'assets/images/welcome.jpg',
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                      return Container(
                                        color: AppTheme.fieldBackground,
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.landscape_outlined,
                                          size: 64,
                                          color: AppTheme.grey,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Espaço flexível entre o conteúdo e os botões
                      const Spacer(flex: 2),

                      // Botões no fundo
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PrimaryButton(
                            text: 'Criar conta',
                            onPressed: () {
                              Navigator.pushNamed(context, '/register');
                            },
                          ),

                          const SizedBox(height: 12),

                          OutlinedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/login');
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              side: const BorderSide(
                                color: AppTheme.primaryRed,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Já tenho conta',
                              style: TextStyle(
                                color: AppTheme.primaryRed,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
