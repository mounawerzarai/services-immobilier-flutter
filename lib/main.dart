import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/router.dart';
import 'core/theme.dart';
import 'features/notifications/message_alerts.dart';
import 'features/offline/offline_banner.dart';
import 'firebase_options.dart';
import 'widgets/app_splash.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Attend que Firebase ait restauré la session (important sur le web)
  // avant de décider quel écran afficher.
  await FirebaseAuth.instance.authStateChanges().first;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // La navigation (onglets + écran de connexion) est gérée par go_router.
    return MaterialApp.router(
      title: 'Services Immobilier',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      routerConfig: router,
      // Écran de démarrage animé au-dessus de l'application (core/router reste inchangé).
      // Alertes de nouveaux messages (T9.1) sous l'écran de démarrage.
      builder: (context, child) => AppSplash(
        child: OfflineBanner(
          child: MessageAlerts(child: child ?? const SizedBox()),
        ),
      ),
    );
  }
}
