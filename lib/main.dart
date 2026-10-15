import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const OnlyFavsApp());
}

class OnlyFavsApp extends StatelessWidget {
  const OnlyFavsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OnlyFavs',
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}