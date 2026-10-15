import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class RegisterController {
  final AuthService _authService = AuthService();

  final TextEditingController name = TextEditingController();
  final TextEditingController username = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController confirmPassword = TextEditingController();

  bool isLoading = false;

  bool isValid() {
    return name.text.trim().isNotEmpty &&
        username.text.trim().isNotEmpty &&
        email.text.trim().isNotEmpty &&
        password.text.isNotEmpty &&
        confirmPassword.text.isNotEmpty;
  }

  bool isValidEmail() {
    final emailValue = email.text.trim();

    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(emailValue);
  }

  bool isValidPassword() {
    return password.text.length >= 8;
  }

  bool passwordsMatch() {
    return password.text == confirmPassword.text;
  }

  Future<Map<String, dynamic>> register() async {
    return await _authService.registerUser(
      name: name.text.trim(),
      username: username.text.trim(),
      email: email.text.trim(),
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