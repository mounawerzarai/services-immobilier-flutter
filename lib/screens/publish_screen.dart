import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../services/listing_service.dart';

const _green = Color(0xFF0B6B5B);
const _greenLight = Color(0xFFD4E4DE);
const _muted = Color(0xFF5F6B76);

class PublishScreen extends StatefulWidget {
  final String? listingId; // null = nouvelle annonce
  const PublishScreen({super.key, this.listingId});

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
  List<String> _kept = [];
  Map<String, dynamic>? _original;
  bool _loading = false;
  bool _loadingDoc = false;

  bool get _editing => widget.listingId != null;
  int get _total => _kept.length + _photos.length;

  static const _types = {
    'apartment': 'Appartement',
    'house': 'Maison',
    'land': 'Terrain',
    'commercial': 'Local commercial',
  };

  @override
  void initState() {
    super.initState();
    if (_editing) _load();
  }

  Future<void> _load() async {
    setState(() => _loadingDoc = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('listings')
          .doc(widget.listingId)
          .get();
      final d = snap.data();
      if (d == null) throw Exception('Annonce introuvable.');
      if (d['sellerId'] != FirebaseAuth.instance.currentUser?.uid) {
        throw Exception('Vous ne pouvez modifier que vos annonces.');
      }
      _original = d;
      _title.text = d['title'] ?? '';
      _description.text = d['description'] ?? '';
      _price.text = '${d['price'] ?? ''}';
      _surface.text = '${d['surface'] ?? ''}';
      _rooms.text = d['rooms'] != null ? '${d['rooms']}' : '';
      _address.text = d['address'] ?? '';
      _city.text = d['city'] ?? '';
      final t = d['propertyType'] as String?;
      _type = _types.containsKey(t) ? t! : 'apartment';
      _transaction = d['transactionType'] == 'rent' ? 'rent' : 'sale';
      _kept = List<String>.from(d['photos'] ?? []);
    } catch (e) {
      if (mounted) {
        _msg('Erreur : $e');
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _loadingDoc = false);
    }
  }

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
      final extra = _total - 8;
      if (extra > 0) _photos.removeRange(_photos.length - extra, _photos.length);
    });
  }

  void _msg(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_total == 0) return _msg('Ajoutez au moins 1 photo.');
    if (FirebaseAuth.instance.currentUser == null) {
      _msg('Connectez-vous pour publier.');
      context.push('/login');
      return;
    }
    setState(() => _loading = true);
    try {
      final service = ListingService();
      final price = double.parse(_price.text.replaceAll(',', '.'));
      final surface = double.parse(_surface.text.replaceAll(',', '.'));
      final rooms = int.tryParse(_rooms.text);
      final address = _address.text.trim();
      final city = _city.text.trim();

      if (_editing) {
        final o = _original!;
        final changed =
            address != (o['address'] ?? '') || city != (o['city'] ?? '');
        await service.updateListing(
          id: widget.listingId!,
          title: _title.text.trim(),
          description: _description.text.trim(),
          price: price,
          surface: surface,
          rooms: rooms,
          propertyType: _type,
          transactionType: _transaction,
          address: address,
          city: city,
          keptPhotos: _kept,
          newPhotos: _photos,
          addressChanged: changed,
        );
      } else {
        await service.createListing(
          title: _title.text.trim(),
          description: _description.text.trim(),
          price: price,
          surface: surface,
          rooms: rooms,
          propertyType: _type,
          transactionType: _transaction,
          address: address,
          city: city,
          photos: _photos,
        );
      }
      if (!mounted) return;
      _msg(_editing ? 'Annonce modifiée' : 'Annonce publiée');
      context.pop();
    } catch (e) {
      if (mounted) _msg('Erreur : $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _pill(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      shape: const StadiumBorder(),
      selectedColor: _green,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? _green : const Color(0xFFD0D5D9)),
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _editing ? 'Modifier l\'annonce' : 'Publier une annonce';

    if (_loadingDoc) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: const Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Field(
              label: 'Titre',
              child: TextFormField(
                controller: _title,
                decoration:
                    const InputDecoration(hintText: 'Ex. Appartement lumineux'),
                validator: _required,
              ),
            ),
            _Field(
              label: 'Description',
              child: TextFormField(
                controller: _description,
                decoration: const InputDecoration(hintText: 'Décrivez le bien'),
                maxLines: 3,
                validator: _required,
              ),
            ),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: _Field(
                  label: 'Prix',
                  child: TextFormField(
                    controller: _price,
                    decoration: const InputDecoration(hintText: '0'),
                    keyboardType: TextInputType.number,
                    validator: _positive,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Field(
                  label: 'Surface (m²)',
                  child: TextFormField(
                    controller: _surface,
                    decoration: const InputDecoration(hintText: '0'),
                    keyboardType: TextInputType.number,
                    validator: _positive,
                  ),
                ),
              ),
            ]),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: _Field(
                  label: 'Type de bien',
                  child: DropdownButtonFormField<String>(
                    initialValue: _type,
                    isExpanded: true,
                    items: _types.entries
                        .map((e) => DropdownMenuItem(
                            value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Field(
                  label: 'Pièces',
                  child: TextFormField(
                    controller: _rooms,
                    decoration: const InputDecoration(hintText: '0'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Wrap(spacing: 8, children: [
                _pill('Vente', _transaction == 'sale',
                    () => setState(() => _transaction = 'sale')),
                _pill('Location', _transaction == 'rent',
                    () => setState(() => _transaction = 'rent')),
              ]),
            ),
            _Field(
              label: 'Adresse',
              child: TextFormField(
                controller: _address,
                decoration: const InputDecoration(hintText: 'Rue'),
                validator: _required,
              ),
            ),
            _Field(
              label: 'Ville',
              child: TextFormField(
                controller: _city,
                decoration: const InputDecoration(hintText: 'Ville'),
                validator: _required,
              ),
            ),
            _Field(
              label: 'Photos (1 minimum, 8 maximum)',
              child: SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (_total < 8)
                      GestureDetector(
                        onTap: _pickPhotos,
                        child: CustomPaint(
                          painter: _DashedRRectPainter(_green),
                          child: const SizedBox(
                            width: 90,
                            height: 90,
                            child: Icon(Icons.add, color: _green, size: 28),
                          ),
                        ),
                      ),
                    if (_total < 8) const SizedBox(width: 8),
                    for (final url in _kept)
                      _Thumb(
                        image: Image.network(url, fit: BoxFit.cover),
                        onRemove: () => setState(() => _kept.remove(url)),
                      ),
                    for (final p in _photos)
                      _Thumb(
                        image: FutureBuilder<Uint8List>(
                          future: p.readAsBytes(),
                          builder: (c, s) => s.hasData
                              ? Image.memory(s.data!, fit: BoxFit.cover)
                              : const SizedBox(),
                        ),
                        onRemove: () => setState(() => _photos.remove(p)),
                      ),
                  ],
                ),
              ),
            ),
            _Field(
              label: 'Position sur la carte',
              child: Container(
                height: 110,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6ECEA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'La position est calculée à partir de l\'adresse.\n'
                  'Le marqueur déplaçable viendra avec la carte (T6.1).',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_editing ? 'Enregistrer' : 'Publier'),
            ),
          ),
        ),
      ),
    );
  }
}

/// Libellé gris au-dessus du champ, comme dans la maquette.
class _Field extends StatelessWidget {
  final String label;
  final Widget child;
  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _muted, fontSize: 13)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final Widget image;
  final VoidCallback onRemove;
  const _Thumb({required this.image, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: ColoredBox(color: _greenLight, child: image),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: const CircleAvatar(
              radius: 11,
              backgroundColor: Colors.black54,
              child: Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Bordure en pointillés du bouton « + ».
class _DashedRRectPainter extends CustomPainter {
  final Color color;
  _DashedRRectPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, const Radius.circular(14)));
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}