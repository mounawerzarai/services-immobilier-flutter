
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(child: Text('Accueil')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/listing/new'),
        icon: const Icon(Icons.add),
        label: const Text('Publier'),
      ),
    );
  }
}
