import 'package:flutter/material.dart';

import '../core/theme.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Connexion')),
      body: const Center(
        child: Text('Connexion', style: TextStyle(color: AppColors.text)),
      ),
    );
  }
}
