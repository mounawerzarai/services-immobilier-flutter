import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/listing_service.dart';

class PublishScreen extends StatefulWidget {
  const PublishScreen({super.key});

  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _surface = TextEditingController();
  final _rooms = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();

  String _type = 'apartment';
  String _transaction = 'sale';
  final List<XFile> _photos = [];
  bool _loading = false;

  static const _types = {
    'apartment': 'Appartement',
    'house': 'Maison',
    'land': 'Terrain',
    'commercial': 'Local commercial',
  };

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null;

  String? _positive(String? v) {
    final n = double.tryParse((v ?? '').replaceAll(',', '.'));
    return (n == null || n <= 0) ? 'Nombre positif requis' : null;
  }

  Future<void> _pickPhotos() async {
    final picked =
        await ImagePicker().pickMultiImage(imageQuality: 70, maxWidth: 1280);
    setState(() {
      _photos.addAll(picked);
      if (_photos.length > 8) _photos.removeRange(8, _photos.length);
    });
  }

  void _msg(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photos.isEmpty) return _msg('Ajoutez au moins 1 photo.');
    if (FirebaseAuth.instance.currentUser == null) {
      _msg('Connectez-vous pour publier.');
      context.push('/login');
      return;
    }
    setState(() => _loading = true);
    try {
      await ListingService().createListing(
        title: _title.text.trim(),
        description: _description.text.trim(),
        price: double.parse(_price.text.replaceAll(',', '.')),
        surface: double.parse(_surface.text.replaceAll(',', '.')),
        rooms: int.tryParse(_rooms.text),
        propertyType: _type,
        transactionType: _transaction,
        address: _address.text.trim(),
        city: _city.text.trim(),
        photos: _photos,
      );
      if (!mounted) return;
      _msg('Annonce publiée');
      context.pop();
    } catch (e) {
      if (mounted) _msg('Erreur : $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publier une annonce')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Titre'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
              validator: _required,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _price,
                  decoration: const InputDecoration(labelText: 'Prix'),
                  keyboardType: TextInputType.number,
                  validator: _positive,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _surface,
                  decoration: const InputDecoration(labelText: 'Surface (m²)'),
                  keyboardType: TextInputType.number,
                  validator: _positive,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Type de bien'),
                  items: _types.entries
                      .map((e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => setState(() => _type = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _rooms,
                  decoration: const InputDecoration(labelText: 'Pièces'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
              ChoiceChip(
                label: const Text('Vente'),
                selected: _transaction == 'sale',
                onSelected: (_) => setState(() => _transaction = 'sale'),
              ),
              ChoiceChip(
                label: const Text('Location'),
                selected: _transaction == 'rent',
                onSelected: (_) => setState(() => _transaction = 'rent'),
              ),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Adresse (rue)'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'Ville'),
              validator: _required,
            ),
            const SizedBox(height: 16),
            Text('Photos (${_photos.length}/8, 1 minimum)'),
            const SizedBox(height: 8),
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (_photos.length < 8)
                    InkWell(
                      onTap: _pickPhotos,
                      child: Container(
                        width: 90,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Theme.of(context).colorScheme.primary),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.add),
                      ),
                    ),
                  for (final p in _photos)
                    _Thumb(
                      file: p,
                      onRemove: () => setState(() => _photos.remove(p)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Publier'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final XFile file;
  final VoidCallback onRemove;
  const _Thumb({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: FutureBuilder<Uint8List>(
              future: file.readAsBytes(),
              builder: (context, snapshot) => snapshot.hasData
                  ? Image.memory(snapshot.data!, fit: BoxFit.cover)
                  : const SizedBox(),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ]),
    );
  }
}