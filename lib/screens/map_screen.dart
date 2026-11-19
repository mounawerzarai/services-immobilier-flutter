import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme.dart';
import '../data/models/listing.dart';
import '../features/listings/format.dart';
import '../features/map/geo.dart';
import '../widgets/ui.dart';

enum _LocateStatus { locating, ok, denied, unavailable }

/// Carte des annonces + « Recherche autour de moi » (T6.2) avec rayon en km.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _tunis = LatLng(36.8065, 10.1815);

  final _controller = MapController();
  late final StreamSubscription<QuerySnapshot<Map<String, dynamic>>> _sub;

  List<Listing> _listings = [];
  String? _error;
  LatLng? _me;
  _LocateStatus _status = _LocateStatus.locating;
  bool _active = false;
  int _radiusKm = kDefaultRadiusKm;
  Listing? _selected;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _sub = FirebaseFirestore.instance
        .collection('listings')
        .where('status', isEqualTo: 'available')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .listen(
      (snap) {
        if (!mounted) return;
        setState(() {
          _error = null;
          _listings = snap.docs
              .map((d) => Listing.fromMap(d.id, d.data()))
              .where((l) => l.latitude != null && l.longitude != null)
              .toList();
        });
      },
      onError: (Object e) {
        if (mounted) setState(() => _error = '$e');
      },
    );
    _locate();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  LatLng? _pos(Listing l) => l.latitude == null || l.longitude == null
      ? null
      : LatLng(l.latitude!, l.longitude!);

  void _moveTo(LatLng center, double zoom) {
    if (_mapReady) _controller.move(center, zoom);
  }

  void _fitToSearch() {
    final me = _me;
    if (me == null) return;
    _moveTo(me, _active ? zoomForRadius(_radiusKm) : 13);
  }

  /// Demande la position. L'app reste utilisable si la permission est refusée (US19).
  Future<LatLng?> _locate() async {
    setState(() => _status = _LocateStatus.locating);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _status = _LocateStatus.denied);
        return null;
      }
      if (!enabled) {
        if (mounted) setState(() => _status = _LocateStatus.unavailable);
        return null;
      }
      final p = await Geolocator.getCurrentPosition();
      if (!mounted) return null;
      final me = LatLng(p.latitude, p.longitude);
      setState(() {
        _me = me;
        _status = _LocateStatus.ok;
      });
      _fitToSearch();
      return me;
    } catch (_) {
      if (mounted) setState(() => _status = _LocateStatus.unavailable);
      return null;
    }
  }

  Future<void> _toggle() async {
    if (_active) {
      setState(() => _active = false);
      _fitToSearch();
      return;
    }
    final me = _me ?? await _locate();
    if (me == null || !mounted) return;
    setState(() {
      _active = true;
      _selected = null;
    });
    _fitToSearch();
  }

  void _setRadius(int km) {
    setState(() => _radiusKm = km);
    _fitToSearch();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: EmptyState(
          icon: Icons.cloud_off_outlined,
          danger: true,
          title: 'Impossible de charger la carte',
          text: _error,
        ),
      );
    }

    final me = _me;
    final results = _active && me != null
        ? withinRadius<Listing>(_listings, me, _radiusKm, _pos)
        : const <WithDistance<Listing>>[];
    final nearIds = results.map((r) => r.item.id).toSet();
    final shown = _active ? results.map((r) => r.item).toList() : _listings;
    final selected = _selected;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const listBottom = 16.0;
    final previewBottom = _active ? 116.0 : 16.0;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: _tunis,
              initialZoom: 12,
              onMapReady: () {
                _mapReady = true;
                _fitToSearch();
              },
              onTap: (_, _) => setState(() => _selected = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.servicesimmobilier.services_immobilier',
              ),
              if (me != null && _active)
                CircleLayer(circles: [
                  CircleMarker(
                    point: me,
                    radius: _radiusKm * 1000.0,
                    useRadiusInMeter: true,
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderColor: AppColors.primary,
                    borderStrokeWidth: 2,
                  ),
                ]),
              if (me != null)
                MarkerLayer(markers: [
                  Marker(
                    point: me,
                    width: 24,
                    height: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F6FE4),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2F6FE4).withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ]),
              MarkerLayer(markers: [
                for (final l in shown)
                  Marker(
                    point: _pos(l)!,
                    width: 96,
                    height: 34,
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = l),
                      child: _PricePin(
                        label: shortPrice(l.price, l.transactionType),
                        active: selected?.id == l.id,
                        near: nearIds.contains(l.id),
                      ),
                    ),
                  ),
              ]),
            ],
          ),

          // Bandeau « Autour de moi » + rayon.
          Positioned(
            left: 16,
            right: 16,
            top: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _NearbyPanel(
                  active: _active,
                  status: _status,
                  radiusKm: _radiusKm,
                  count: results.length,
                  onToggle: _toggle,
                  onRadius: _setRadius,
                ),
              ),
            ),
          ),

          if (me != null)
            Positioned(
              right: 16,
              bottom: bottomInset + previewBottom + (selected != null ? 96 : 0) + 8,
              child: RoundIconButton(
                icon: Icons.my_location,
                tooltip: 'Me localiser',
                color: AppColors.primary,
                onPressed: _fitToSearch,
              ),
            ),

          if (selected != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: bottomInset + previewBottom,
              child: _ListingTile(
                listing: selected,
                distanceKm: me == null ? null : distanceKm(me, _pos(selected)!),
                onTap: () => context.push('/listing/${selected.id}'),
                onClose: () => setState(() => _selected = null),
              ),
            ),

          if (_active)
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomInset + listBottom,
              child: results.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: AppCard(
                        padding: const EdgeInsets.all(14),
                        child: const Row(
                          children: [
                            Icon(Icons.search_off, color: AppColors.muted, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Aucune annonce dans ce rayon. Essayez un rayon plus grand.',
                                style: TextStyle(color: AppColors.muted, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SizedBox(
                      height: 88,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: results.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final r = results[i];
                          return SizedBox(
                            width: 290,
                            child: _ListingTile(
                              listing: r.item,
                              distanceKm: r.distanceKm,
                              onTap: () => context.push('/listing/${r.item.id}'),
                              onLongPress: () {
                                setState(() => _selected = r.item);
                                _moveTo(_pos(r.item)!, 15);
                              },
                            ),
                          );
                        },
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

class _PricePin extends StatelessWidget {
  const _PricePin({required this.label, required this.active, required this.near});

  final String label;
  final bool active;
  final bool near;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary
              : (near ? AppColors.primarySoft : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary, width: 2),
          boxShadow: AppShadows.soft,
        ),
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: active ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _NearbyPanel extends StatelessWidget {
  const _NearbyPanel({
    required this.active,
    required this.status,
    required this.radiusKm,
    required this.count,
    required this.onToggle,
    required this.onRadius,
  });

  final bool active;
  final _LocateStatus status;
  final int radiusKm;
  final int count;
  final VoidCallback onToggle;
  final ValueChanged<int> onRadius;

  @override
  Widget build(BuildContext context) {
    final locating = status == _LocateStatus.locating;
    final String subtitle;
    if (status == _LocateStatus.denied) {
      subtitle = 'Localisation refusée : autorisez-la pour utiliser cette recherche.';
    } else if (status == _LocateStatus.unavailable) {
      subtitle = 'Position indisponible pour le moment.';
    } else if (active) {
      subtitle = '$count annonce${count > 1 ? 's' : ''} à moins de $radiusKm km';
    } else {
      subtitle = 'Trouvez les biens proches de votre position.';
    }

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Autour de moi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: active ? AppColors.primary : AppColors.primarySoft,
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: locating ? null : onToggle,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (locating)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: active ? Colors.white : AppColors.primary,
                            ),
                          )
                        else
                          Icon(
                            active ? Icons.near_me : Icons.near_me_outlined,
                            size: 18,
                            color: active ? Colors.white : AppColors.primary,
                          ),
                        const SizedBox(width: 6),
                        Text(
                          active ? 'Activé' : 'Activer',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: active ? Colors.white : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (active) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Text(
                        'Rayon',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                  for (final km in kRadiusChoices)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('$km km'),
                        selected: radiusKm == km,
                        onSelected: (_) => onRadius(km),
                        showCheckmark: false,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: radiusKm == km ? Colors.white : AppColors.text,
                        ),
                        side: BorderSide(
                          color: radiusKm == km ? AppColors.primary : AppColors.border,
                        ),
                        shape: const StadiumBorder(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Petite carte d'annonce (aperçu sur la carte et liste des résultats).
class _ListingTile extends StatelessWidget {
  const _ListingTile({
    required this.listing,
    required this.onTap,
    this.distanceKm,
    this.onClose,
    this.onLongPress,
  });

  final Listing listing;
  final double? distanceKm;
  final VoidCallback onTap;
  final VoidCallback? onClose;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final photo = listing.photos.isEmpty ? null : listing.photos.first;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: photo == null
                        ? Container(
                            color: AppColors.primarySoft,
                            child: const Icon(Icons.image_outlined, color: AppColors.subtle),
                          )
                        : Image.network(
                            photo,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) =>
                                Container(color: AppColors.primarySoft),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatPrice(listing),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        listing.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (distanceKm != null) ...[
                            Pill(formatDistance(distanceKm!), icon: Icons.near_me),
                            const SizedBox(width: 6),
                          ],
                          if (listing.city.isNotEmpty)
                            Flexible(
                              child: IconText(
                                Icons.location_on_outlined,
                                listing.city,
                                size: 12,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    tooltip: 'Fermer',
                    onPressed: onClose,
                    icon: const Icon(Icons.close, color: AppColors.muted, size: 20),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
