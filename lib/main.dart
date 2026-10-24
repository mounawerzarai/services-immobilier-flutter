import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Services Immobilier',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
      home: const FirebaseCheckScreen(),
    );
  }
}

/// Temporary screen for the T2.2 smoke test: proves that the app reaches
/// Firebase Auth and that the Firestore rules let visitors read listings.
/// It is replaced by the real home screen in Sprint 2.
class FirebaseCheckScreen extends StatelessWidget {
  const FirebaseCheckScreen({super.key});

  Future<String> _check() async {
    final user = FirebaseAuth.instance.currentUser;
    final snapshot =
        await FirebaseFirestore.instance.collection('listings').limit(1).get();
    return 'Firebase connected\n'
        'Project: ${Firebase.app().options.projectId}\n'
        'User: ${user?.uid ?? 'not signed in'}\n'
        'Listings readable: ${snapshot.docs.length} found';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Services Immobilier')),
      body: Center(
        child: FutureBuilder<String>(
          future: _check(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const CircularProgressIndicator();
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error: ${snapshot.error}'),
              );
            }
            return Text(snapshot.data!, textAlign: TextAlign.center);
          },
        ),
      ),
    );
  }
}