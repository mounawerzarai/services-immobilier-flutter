import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Affiche un bandeau en haut de l'écran quand l'appli n'arrive pas à joindre Firestore.
///
/// On écoute un document qui n'existe pas (listings/connection-check, lisible par tous ; un id du type __x__ est interdit par Firestore) : tant que
/// le serveur ne répond pas, Firestore répond depuis son cache (`isFromCache`).
/// À placer au-dessus de l'application (dans le `builder` de MaterialApp.router).
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key, required this.child});

  final Widget child;

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  /// On attend un peu avant d'afficher, pour ne pas clignoter au démarrage.
  static const Duration _grace = Duration(seconds: 3);

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  Timer? _timer;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _sub = FirebaseFirestore.instance
        .collection('listings')
        .doc('connection-check')
        .snapshots(includeMetadataChanges: true)
        .listen(
          (snap) => snap.metadata.isFromCache ? _offlineSoon() : _online(),
          // Seule une erreur « service indisponible » veut dire hors ligne ; les autres sont ignorées.
          onError: (Object e) {
            if (e is FirebaseException && e.code == 'unavailable') _offlineSoon();
          },
        );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  void _offlineSoon() {
    _timer ??= Timer(_grace, () {
      if (mounted) setState(() => _offline = true);
    });
  }

  void _online() {
    _timer?.cancel();
    _timer = null;
    if (_offline && mounted) setState(() => _offline = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_offline)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Material(
                color: AppColors.danger,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    MediaQuery.of(context).padding.top + 6,
                    16,
                    8,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off, size: 16, color: Colors.white),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Pas de connexion internet. Les données affichées peuvent être anciennes.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
