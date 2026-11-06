import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/services/auth_service.dart';
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

    if (!_isLogin && _name.text.trim().length < 2) {
      setState(() => _error = 'Entrez votre nom.');
      return;
    }
    if (!isValidEmail(_email.text)) {
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
        await _service.login(_email.text, _password.text);
      } else {
        await _service.register(
          _name.text.trim(),
          _email.text,
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
    if (!isValidEmail(_email.text)) {
      setState(() => _error = "Entrez d'abord votre email.");
      return;
    }
    try {
      await _service.resetPassword(_email.text);
      setState(() => _info = 'Email envoyé. Consultez votre boîte mail.');
    } on FirebaseAuthException catch (e) {
      setState(() => _error = AuthService.errorMessage(e.code));
    }
  }

  Widget _tab(String label, bool login) {
    final bool active = _isLogin == login;
    return Expanded(
      child: InkWell(
        onTap: () => _switchMode(login),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? kGreen : Colors.grey.shade300,
                width: active ? 3 : 1,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: active ? kGreen : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kGreen, width: 2),
        ),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Text(text, style: TextStyle(color: Colors.grey.shade700)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Services Immobilier',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: kGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Trouvez, publiez et échangez des biens près de chez vous.',
                    style: TextStyle(fontSize: 17, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      _tab('Connexion', true),
                      _tab('Inscription', false),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (!_isLogin) ...[
                    _label('Nom'),
                    TextField(
                      controller: _name,
                      decoration: _decoration('Votre nom'),
                    ),
                  ],
                  _label('Email'),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _decoration('nom@exemple.com'),
                  ),
                  _label('Mot de passe'),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: _decoration('6 caractères minimum'),
                    onSubmitted: (_) => _submit(),
                  ),
                  if (_isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _forgot,
                        child: const Text(
                          'Mot de passe oublié ?',
                          style: TextStyle(
                            color: kGreen,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 18),
                  if (_error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (_info.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _info,
                        style: const TextStyle(color: kGreen),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isLogin ? 'Se connecter' : "S'inscrire",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}