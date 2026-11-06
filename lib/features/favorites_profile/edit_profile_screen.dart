import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/user_profile.dart';
import '../../data/services/profile_service.dart';
import 'profile_avatar.dart';

/// Taille maximale de la photo une fois réduite (Firestore limite un document à 1 Mo).
const int _maxPhotoBytes = 500 * 1024;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ProfileService _service = ProfileService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();

  UserProfile? _profile;
  String? _newPhotoBase64; // photo choisie, pas encore enregistrée
  bool _removePhoto = false;
  bool _loading = true;
  bool _saving = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final profile = await _service.watchProfile().first;
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _name.text = profile?.name ?? '';
        _phone.text = profile?.phone ?? '';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger le profil.';
        _loading = false;
      });
    }
  }

  /// Photo affichée : la nouvelle si elle existe, sinon l'actuelle.
  Uint8List? get _previewBytes {
    if (_removePhoto) return null;
    if (_newPhotoBase64 != null) return base64Decode(_newPhotoBase64!);
    return _profile?.photoBytes;
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 70,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      if (bytes.length > _maxPhotoBytes) {
        setState(() => _error = 'Photo trop lourde. Choisissez une image plus petite.');
        return;
      }
      setState(() {
        _newPhotoBase64 = base64Encode(bytes);
        _removePhoto = false;
        _error = '';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = "Impossible d'ouvrir la photo.");
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir dans la galerie'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Prendre une photo'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickPhoto(ImageSource.camera);
                },
              ),
            if (_previewBytes != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Supprimer la photo'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() {
                    _newPhotoBase64 = null;
                    _removePhoto = true;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  String? _validateName(String? value) {
    if ((value ?? '').trim().length < 2) return 'Entrez votre nom.';
    return null;
  }

  String? _validatePhone(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null; // le téléphone est facultatif
    if (!RegExp(r'^\+?[0-9 ]{8,15}$').hasMatch(v)) {
      return 'Numéro invalide (8 à 15 chiffres).';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = '';
    });
    try {
      await _service.updateProfile(
        name: _name.text,
        phone: _phone.text,
        photoBase64: _newPhotoBase64,
        removePhoto: _removePhoto,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour.')),
      );
      context.pop();
    } on ProfileException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = "Impossible d'enregistrer. Réessayez.");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier le profil')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          ProfileAvatar(
                            name: _name.text,
                            photoBytes: _previewBytes,
                            radius: 56,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                iconSize: 18,
                                color: Colors.white,
                                tooltip: 'Changer la photo',
                                icon: const Icon(Icons.camera_alt),
                                onPressed: _saving ? null : _showPhotoOptions,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text('Nom'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(hintText: 'Votre nom'),
                      validator: _validateName,
                    ),
                    const SizedBox(height: 16),
                    const Text('Téléphone'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration:
                          const InputDecoration(hintText: '+216 20 123 456'),
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 16),
                    const Text('Email'),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: _profile?.email ?? '',
                      enabled: false,
                    ),
                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(_error, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Enregistrer'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}