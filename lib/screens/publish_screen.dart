import 'package:flutter/material.dart';

class PublishScreen extends StatelessWidget {
  const PublishScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publier une annonce'),
      ),
      body: const Center(
        child: Text('Publish Screen'),
      ),
    );
  }
}