import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _controller = MapController();
  LatLng? _me;
  QueryDocumentSnapshot<Map<String, dynamic>>? _selected;

  @override
  void initState() {
    super.initState();
    _locate();
  }

  Future<void> _locate() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      // L'app reste utilisable si la permission est refusée (US19)
      if (!enabled ||
          perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final p = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _me = LatLng(p.latitude, p.longitude));
      _controller.move(_me!, 13);
    } catch (_) {
      // localisation indisponible : on ignore
    }
  }

  String _label(Map<String, dynamic> d) {
    final price = (d['price'] as num).toDouble();
    if (d['transactionType'] == 'rent') return '${price.toInt()} €';
    return price >= 1000 ? '${(price / 1000).round()} k€' : '${price.toInt()} €';
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF0B6B5C);
    return Scaffold(
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('listings')
            .where('status', isEqualTo: 'available')
            .orderBy('createdAt', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Erreur : ${snap.error}'));
          }
          final docs = (snap.data?.docs ?? []).where((d) {
            final m = d.data();
            return m['latitude'] is num && m['longitude'] is num && m['price'] is num;
          }).toList();

          return Stack(children: [
            FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: const LatLng(36.8065, 10.1815), // Tunis
                initialZoom: 12,
                onTap: (_, __) => setState(() => _selected = null),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.services_immobilier',
                ),
                if (_me != null)
                  MarkerLayer(markers: [
                    Marker(
                      point: _me!,
                      width: 22,
                      height: 22,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  ]),
                MarkerLayer(markers: [
                  for (final doc in docs)
                    Marker(
                      point: LatLng(
                        (doc['latitude'] as num).toDouble(),
                        (doc['longitude'] as num).toDouble(),
                      ),
                      width: 80,
                      height: 36,
                      child: GestureDetector(
                        onTap: () => setState(() => _selected = doc),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _selected?.id == doc.id ? green : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: green, width: 2),
                          ),
                          child: Text(
                            _label(doc.data()),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _selected?.id == doc.id ? Colors.white : green,
                            ),
                          ),
                        ),
                      ),
                    ),
                ]),
              ],
            ),
            if (_selected != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: GestureDetector(
                  onTap: () => context.push('/listing/${_selected!.id}'),
                  child: Card(
                    child: ListTile(
                      leading: (_selected!.data()['photos'] is List &&
                              (_selected!.data()['photos'] as List).isNotEmpty)
                          ? Image.network(
                              (_selected!.data()['photos'] as List)[0],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            )
                          : null,
                      title: Text('${_selected!.data()['price']} €'),
                      subtitle: Text(
                        '${_selected!.data()['title']}\n'
                        '${_selected!.data()['city']} · ${_selected!.data()['surface']} m²',
                      ),
                      isThreeLine: true,
                    ),
                  ),
                ),
              ),
          ]);
        },
      ),
    );
  }
}