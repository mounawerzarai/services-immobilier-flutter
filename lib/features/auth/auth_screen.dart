import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/services/auth_service.dart';
import '../../widgets/ui.dart';
import 'validation.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _service = AuthService();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  bool _isLogin = true;
  bool _showPassword = false;
  bool _loading = false;
  String _error = '';
  String _info = '';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // Email sans espaces ni caractères invisibles (le clavier de l'émulateur en glisse parfois).
  String _cleanEmail() =>
      _email.text.replaceAll(RegExp(r'[\s​-‍﻿]'), '').toLowerCase();

  void _switchMode(bool login) {
    setState(() {
      _isLogin = login;
      _error = '';
      _info = '';
    });
  }

  Future<void> _submit() async {
    setState(() {
      _error = '';
      _info = '';
    });

    final email = _cleanEmail();

    if (!_isLogin && _name.text.trim().length < 2) {
      setState(() => _error = 'Entrez votre nom.');
      return;
    }
    if (!isValidEmail(email)) {
      setState(() => _error = 'Adresse email invalide.');
      return;
    }
    if (!isValidPassword(_password.text)) {
      setState(() => _error = '6 caractères minimum.');
      return;
    }

    setState(() => _loading = true);
    try {
      if (_isLogin) {
        await _service.login(email, _password.text);
      } else {
        await _service.register(
          _name.text.trim(),
          email,
          _password.text,
        );
      }
      // La redirection se fait automatiquement via go_router (core/router.dart).
    } on FirebaseAuthException catch (e) {
      setState(() => _error = AuthService.errorMessage(e.code));
    } catch (_) {
      setState(() => _error = AuthService.errorMessage(''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgot() async {
    setState(() {
      _error = '';
      _info = '';
    });
    final email = _cleanEmail();
    if (!isValidEmail(email)) {
      setState(() => _error = "Entrez d'abord votre email.");
      return;
    }
    try {
      await _service.resetPassword(email);
      setState(() => _info = 'Email envoyé. Consultez votre boîte mail.');
    } on FirebaseAuthException catch (e) {
      setState(() => _error = AuthService.errorMessage(e.code));
    }
  }

  Widget _tab(String label, bool login) {
    final bool active = _isLogin == login;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchMode(login),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            boxShadow: active ? AppShadows.soft : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              color: active ? AppColors.primary : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint, IconData icon, {Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.muted),
        suffixIcon: suffix,
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      );

  Widget _notice(String text, {required bool error}) => Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: error ? AppColors.dangerSoft : AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            Icon(
              error ? Icons.error : Icons.check_circle,
              size: 18,
              color: error ? AppColors.danger : AppColors.success,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: error ? AppColors.danger : AppColors.success,
                ),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Bandeau de marque.
            SizedBox(
              width: double.infinity,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    top: -90,
                    right: -80,
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -60,
                    left: -50,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent.withValues(alpha: 0.14),
                      ),
                    ),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 36, 28, 48),
                      child: Column(
                        children: [
                          const BrandMark(size: 72, light: true, withName: true),
                          const SizedBox(height: 10),
                          Text(
                            'Trouvez, publiez et échangez des biens près de chez vous.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.4,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Formulaire.
            Container(
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight: MediaQuery.sizeOf(context).height * 0.6,
              ),
              decoration: const BoxDecoration(
                color: AppColors.canvas,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(AppRadius.xl + 4)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.segment,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          children: [
                            _tab('Connexion', true),
                            _tab('Inscription', false),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        _isLogin ? 'Bon retour parmi nous' : 'Créez votre compte',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      if (!_isLogin) ...[
                        _label('Nom'),
                        TextField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration: _decoration('Votre nom', Icons.person_outline),
                        ),
                      ],
                      _label('Email'),
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        enableSuggestions: false,
                        textCapitalization: TextCapitalization.none,
                        decoration: _decoration('nom@exemple.com', Icons.mail_outline),
                      ),
                      _label('Mot de passe'),
                      TextField(
                        controller: _password,
                        obscureText: !_showPassword,
                        decoration: _decoration(
                          '6 caractères minimum',
                          Icons.lock_outline,
                          suffix: IconButton(
                            tooltip: _showPassword
                                ? 'Masquer le mot de passe'
                                : 'Afficher le mot de passe',
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.muted,
                            ),
                            onPressed: () =>
                                setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                      if (_isLogin)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _forgot,
                            child: const Text('Mot de passe oublié ?'),
                          ),
                        ),
                      if (_error.isNotEmpty) _notice(_error, error: true),
                      if (_info.isNotEmpty) _notice(_info, error: false),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: _loading ? null : _submit,
                        icon: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(_isLogin ? Icons.login : Icons.person_add_alt_1),
                        label: Text(_isLogin ? 'Se connecter' : "S'inscrire"),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: TextButton(
                          onPressed: () => _switchMode(!_isLogin),
                          child: Text.rich(
                            TextSpan(
                              text: _isLogin
                                  ? 'Pas encore de compte ? '
                                  : 'Déjà inscrit ? ',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontWeight: FontWeight.w500,
                              ),
                              children: [
                                TextSpan(
                                  text: _isLogin ? 'Inscrivez-vous' : 'Connectez-vous',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
