import 'package:flutter/material.dart';

class ListingDetailScreen extends StatelessWidget {
  final String id;

  const ListingDetailScreen({
    super.key,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail'),
      ),
      body: Center(
        child: Text('Annonce $id'),
      ),
    );
  }
}