import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class RegisterController {
  final AuthService authService;

  final TextEditingController name = TextEditingController();
  final TextEditingController username = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController confirmPassword = TextEditingController();

  bool isLoading = false;

  RegisterController({required this.authService});

  String? validate() {
    if (name.text.trim().isEmpty ||
        username.text.trim().isEmpty ||
        email.text.trim().isEmpty ||
        password.text.isEmpty ||
        confirmPassword.text.isEmpty) {
      return 'Preenche todos os campos.';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.text.trim())) {
      return 'Introduz um email válido.';
    }
    if (password.text != confirmPassword.text) {
      return 'As palavras-passe não coincidem.';
    }
    return null;
  }

  Future<Map<String, dynamic>> register() {
    return authService.registerUser(
      name: name.text.trim(),
      username: username.text.trim(),
      email: email.text,
      password: password.text,
    );
  }

  void dispose() {
    name.dispose();
    username.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
  }
}
