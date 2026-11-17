import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AccessScreen extends StatelessWidget {
  const AccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.credit_card_outlined, size: 56, color: AppTheme.grey),
            SizedBox(height: 16),
            Text(
              'Os teus acessos vão aparecer aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppTheme.grey),
            ),
          ],
        ),
      ),
    );
  }
}
