import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/services/message_management_service.dart';

class SavedMessagesPage extends StatelessWidget {
  SavedMessagesPage({super.key});
  final MessageManagementService service = MessageManagementService();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF7F4F9),
        appBar: AppBar(title: const Text('Saved Messages', style: TextStyle(fontWeight: FontWeight.w800))),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: service.savedMessages(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final documents = snapshot.data!.docs;
            if (documents.isEmpty) return const Center(child: Text('No saved messages yet'));
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: documents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 9),
              itemBuilder: (context, index) {
                final document = documents[index];
                final data = document.data();
                final message = Map<String, dynamic>.from(data['message'] as Map? ?? {});
                final text = message['text'] as String?;
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.bookmark_rounded, color: Color(0xFF7653A5)),
                    title: Text(text?.trim().isNotEmpty == true ? text! : _label(message['type'] as String?)),
                    subtitle: Text('From ${data['contactName'] ?? 'conversation'}'),
                    trailing: IconButton(
                      onPressed: () => service.remove(document.id),
                      icon: const Icon(Icons.bookmark_remove_outlined),
                    ),
                  ),
                );
              },
            );
          },
        ),
      );

  static String _label(String? type) => switch (type) {
        'image' => 'Photo',
        'voice' => 'Voice message',
        'file' => 'File',
        _ => 'Message',
      };
}
