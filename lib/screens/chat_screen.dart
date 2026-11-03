import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  final String id;

  const ChatScreen({
    super.key,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discussion'),
      ),
      body: Center(
        child: Text('Conversation $id'),
      ),
    );
  }
}