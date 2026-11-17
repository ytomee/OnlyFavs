import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class LoginController {
  final AuthService authService;
  final email = TextEditingController();
  final password = TextEditingController();
  bool isLoading = false;

  LoginController({required this.authService});

  String? validate() {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      return 'Preenche o email e a palavra-passe.';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.text.trim())) {
      return 'Introduz um email válido.';
    }
    return null;
  }

  Future<Map<String, dynamic>> login() {
    return authService.login(email: email.text, password: password.text);
  }

  void dispose() {
    email.dispose();
    password.dispose();
  }
}
