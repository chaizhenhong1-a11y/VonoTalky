import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/services/chat_service.dart';
import 'media_viewer_page.dart';

class SharedMediaPage extends StatelessWidget {
  SharedMediaPage({super.key, required this.otherId});
  final String otherId;
  final ChatService service = ChatService();

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: const Color(0xFFF7F4F9),
          appBar: AppBar(
            title: const Text('Shared Content', style: TextStyle(fontWeight: FontWeight.w800)),
            bottom: const TabBar(tabs: [Tab(text: 'Photos'), Tab(text: 'Files'), Tab(text: 'Voice')]),
          ),
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: service.messages(otherId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final documents = snapshot.data!.docs.where((doc) => doc.data()['isDeleted'] != true).toList();
              return TabBarView(
                children: [
                  _Photos(documents: documents),
                  _ContentList(documents: documents, type: 'file'),
                  _ContentList(documents: documents, type: 'voice'),
                ],
              );
            },
          ),
        ),
      );
}

class _Photos extends StatelessWidget {
  const _Photos({required this.documents});
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> documents;
  @override
  Widget build(BuildContext context) {
    final photos = documents.where((doc) => doc.data()['type'] == 'image').toList();
    if (photos.isEmpty) return const _Empty(text: 'No shared photos');
    return GridView.builder(
      padding: const EdgeInsets.all(3),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 3, mainAxisSpacing: 3),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final url = photos[index].data()['imageUrl'] as String;
        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MediaViewerPage(url: url))),
          child: Image.network(url, fit: BoxFit.cover),
        );
      },
    );
  }
}

class _ContentList extends StatelessWidget {
  const _ContentList({required this.documents, required this.type});
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> documents;
  final String type;
  @override
  Widget build(BuildContext context) {
    final values = documents.where((doc) => doc.data()['type'] == type).toList();
    if (values.isEmpty) return _Empty(text: type == 'file' ? 'No shared files' : 'No voice messages');
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: values.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final data = values[index].data();
        final title = type == 'file'
            ? data['fileName'] as String? ?? 'File'
            : 'Voice message · ${((data['durationMs'] as num? ?? 0) / 1000).ceil()}s';
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFF0E8FC),
            child: Icon(type == 'file' ? Icons.insert_drive_file_rounded : Icons.mic_rounded, color: const Color(0xFF7653A5)),
          ),
          title: Text(title),
          subtitle: Text(_date((data['sentAt'] as Timestamp?)?.toDate())),
        );
      },
    );
  }

  static String _date(DateTime? value) => value == null ? '' : '${value.day}/${value.month}/${value.year}';
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Center(child: Text(text));
}
