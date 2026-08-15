import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/services/chat_service.dart';

class ChatSearchPage extends StatefulWidget {
  const ChatSearchPage({super.key, required this.otherId});
  final String otherId;

  @override
  State<ChatSearchPage> createState() => _ChatSearchPageState();
}

class _ChatSearchPageState extends State<ChatSearchPage> {
  final service = ChatService();
  final searchController = TextEditingController();
  String query = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF7F4F9),
        appBar: AppBar(
          titleSpacing: 0,
          title: TextField(
            controller: searchController,
            autofocus: true,
            onChanged: (value) => setState(() => query = value.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search messages...',
              border: InputBorder.none,
              filled: false,
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        searchController.clear();
                        setState(() => query = '');
                      },
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.cancel_rounded, size: 19),
                    ),
            ),
          ),
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: service.messages(widget.otherId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final results = snapshot.data!.docs.where((document) {
              final data = document.data();
              if (data['isDeleted'] == true) return false;
              final text = (data['text'] as String? ?? '').toLowerCase();
              final file = (data['fileName'] as String? ?? '').toLowerCase();
              return query.isNotEmpty && (text.contains(query) || file.contains(query));
            }).toList();
            if (query.isEmpty) {
              return const _SearchHint();
            }
            if (results.isEmpty) {
              return const Center(child: Text('No matching messages'));
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Text(
                    '${results.length} ${results.length == 1 ? 'result' : 'results'}',
                    style: const TextStyle(
                      color: Color(0xFF796E82),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final document = results[index];
                      final data = document.data();
                      final value =
                          (data['text'] as String?)?.trim().isNotEmpty == true
                              ? data['text'] as String
                              : data['fileName'] as String? ??
                                  _label(data['type'] as String?);
                      final sentAt =
                          (data['sentAt'] as Timestamp?)?.toDate();
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFF0E8FC),
                          child: Icon(
                            Icons.search_rounded,
                            color: Color(0xFF7653A5),
                          ),
                        ),
                        title: Text(
                          value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(_date(sentAt)),
                        onTap: () => Navigator.pop(context, document.id),
                      );
                    },
                  ),
                ),
              ],
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

  static String _date(DateTime? value) => value == null
      ? ''
      : '${value.day}/${value.month}/${value.year}  ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _SearchHint extends StatelessWidget {
  const _SearchHint();
  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.manage_search_rounded, size: 58, color: Color(0xFF9C7AC8)),
            SizedBox(height: 10),
            Text('Search this conversation', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
