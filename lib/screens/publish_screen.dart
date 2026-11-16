import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme.dart';
import '../services/listing_service.dart';
import '../widgets/ui.dart';

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

  Widget _segment() {
    Widget item(String value, String label, IconData icon) {
      final on = _transaction == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _transaction = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: on ? AppColors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              boxShadow: on ? AppShadows.soft : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 17, color: on ? _green : _muted),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                    color: on ? _green : _muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.segment,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          item('sale', 'Vente', Icons.sell_outlined),
          item('rent', 'Location', Icons.key_outlined),
        ],
      ),
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
      appBar: AppBar(title: Text(title)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            _segment(),
            _Section(
              icon: Icons.description_outlined,
              title: 'Informations',
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
                    decoration: const InputDecoration(
                      hintText: 'Décrivez le bien : état, exposition, équipements…',
                    ),
                    maxLines: 4,
                    validator: _required,
                  ),
                ),
              ],
            ),
            _Section(
              icon: Icons.tune,
              title: 'Caractéristiques',
              children: [
                _Field(
                  label: 'Type de bien',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final e in _types.entries)
                        _pill(e.value, _type == e.key,
                            () => setState(() => _type = e.key)),
                    ],
                  ),
                ),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: _Field(
                      label: _transaction == 'rent'
                          ? 'Loyer (DT / mois)'
                          : 'Prix (DT)',
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
                _Field(
                  label: 'Pièces',
                  child: TextFormField(
                    controller: _rooms,
                    decoration: const InputDecoration(hintText: '0'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            _Section(
              icon: Icons.location_on_outlined,
              title: 'Localisation',
              children: [
                _Field(
                  label: 'Adresse',
                  child: TextFormField(
                    controller: _address,
                    decoration: const InputDecoration(hintText: 'Rue, quartier'),
                    validator: _required,
                  ),
                ),
                _Field(
                  label: 'Ville',
                  child: TextFormField(
                    controller: _city,
                    decoration: const InputDecoration(hintText: 'Ex. Tunis'),
                    validator: _required,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _greenLight.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: _green, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'La position sur la carte est calculée automatiquement '
                          'à partir de l\'adresse.',
                          style: TextStyle(color: AppColors.primaryDark, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            _Section(
              icon: Icons.photo_library_outlined,
              title: 'Photos ($_total/8)',
              children: [
                SizedBox(
                  height: 96,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      if (_total < 8)
                        GestureDetector(
                          onTap: _pickPhotos,
                          child: CustomPaint(
                            painter: _DashedRRectPainter(_green),
                            child: Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_outlined,
                                      color: _green, size: 26),
                                  SizedBox(height: 4),
                                  Text(
                                    'Ajouter',
                                    style: TextStyle(
                                      color: _green,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (_total < 8) const SizedBox(width: 10),
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
                const SizedBox(height: 10),
                const Text(
                  '1 photo minimum, 8 maximum. La première sert de couverture.',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: AppShadows.raised,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: FilledButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(_editing ? Icons.check : Icons.send_outlined),
              label: Text(_editing
                  ? 'Enregistrer les modifications'
                  : 'Publier l\'annonce'),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bloc blanc arrondi avec un titre et une icône.
class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.children});

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon, size: 32),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
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
          Text(label,
              style: const TextStyle(
                  color: _muted, fontSize: 13, fontWeight: FontWeight.w600)),
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
      width: 96,
      margin: const EdgeInsets.only(right: 10),
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