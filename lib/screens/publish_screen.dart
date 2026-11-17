import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PublishScreen extends StatelessWidget {
  const PublishScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 56,
              color: AppTheme.grey,
            ),
            SizedBox(height: 16),
            Text(
              'As tuas próximas publicações começam aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppTheme.grey),
            ),
          ],
        ),
      ),
    );
  }
}
