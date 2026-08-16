import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/services/group_service.dart';

class GroupChatSearchPage extends StatefulWidget {
  const GroupChatSearchPage({super.key, required this.groupId});

  final String groupId;

  @override
  State<GroupChatSearchPage> createState() => _GroupChatSearchPageState();
}

class _GroupChatSearchPageState extends State<GroupChatSearchPage> {
  final controller = TextEditingController();
  final service = GroupService();

  _GroupSearchFilter filter = _GroupSearchFilter.all;
  String query = '';

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF9F7FC),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF9F7FC),
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      title: const Text(
        'Search Group Messages',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          child: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: (value) => setState(() => query = value.trim()),
            decoration: InputDecoration(
              hintText: 'Search this group',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear',
                      onPressed: () {
                        controller.clear();
                        setState(() => query = '');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFE8E2ED)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFB49ADF)),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: _GroupSearchFilter.values.map((item) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: filter == item,
                  label: Text(item.label),
                  avatar: Icon(item.icon, size: 17),
                  onSelected: (_) => setState(() => filter = item),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: service.messages(widget.groupId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _SearchState(
                  icon: Icons.cloud_off_rounded,
                  title: 'Unable to search group messages',
                  subtitle: '${snapshot.error}',
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final results = snapshot.data!.docs.where((document) {
                final data = document.data();
                final type = data['type'] as String? ?? 'text';

                if (!filter.matches(type)) return false;
                if (query.isEmpty) return true;

                final needle = query.toLowerCase();
                final haystack = <String>[
                  data['text'] as String? ?? '',
                  data['fileName'] as String? ?? '',
                  data['senderName'] as String? ?? '',
                ].join(' ').toLowerCase();

                return haystack.contains(needle);
              }).toList();

              if (query.isEmpty && filter == _GroupSearchFilter.all) {
                return const _SearchState(
                  icon: Icons.manage_search_rounded,
                  title: 'Search this group',
                  subtitle: 'Type a keyword or choose a message type to begin.',
                );
              }

              if (results.isEmpty) {
                return _SearchState(
                  icon: Icons.search_off_rounded,
                  title: 'No matching messages',
                  subtitle: query.isEmpty
                      ? 'No ${filter.label.toLowerCase()} messages found.'
                      : 'Try another keyword or filter.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                itemCount: results.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final document = results[index];
                  final data = document.data();
                  final type = data['type'] as String? ?? 'text';
                  final sentAt = (data['sentAt'] as Timestamp?)?.toDate();
                  final senderName = data['senderName'] as String? ?? 'Member';

                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.pop(context, document.id),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TypeAvatar(type: type),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          senderName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      if (sentAt != null)
                                        Text(
                                          _time(sentAt),
                                          style: const TextStyle(
                                            color: Color(0xFF8A8290),
                                            fontSize: 11,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  _HighlightedPreview(
                                    text: _preview(data),
                                    query: query,
                                  ),
                                  const SizedBox(height: 7),
                                  _MetaPill(
                                    icon: _typeIcon(type),
                                    text: _typeLabel(type),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF9A92A3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );

  static String _preview(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? 'text';

    if (data['isDeleted'] as bool? ?? false) {
      return 'This message was recalled';
    }
    if (type == 'image') return 'Photo';
    if (type == 'voice') return 'Voice message';
    if (type == 'file') return data['fileName'] as String? ?? 'File';

    final text = (data['text'] as String? ?? '').replaceAll('\n', ' ').trim();
    return text.isEmpty ? 'Message' : text;
  }

  static String _time(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')} '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

enum _GroupSearchFilter {
  all,
  text,
  image,
  file,
  voice;

  String get label => switch (this) {
    _GroupSearchFilter.all => 'All',
    _GroupSearchFilter.text => 'Text',
    _GroupSearchFilter.image => 'Photos',
    _GroupSearchFilter.file => 'Files',
    _GroupSearchFilter.voice => 'Voice',
  };

  IconData get icon => switch (this) {
    _GroupSearchFilter.all => Icons.apps_rounded,
    _GroupSearchFilter.text => Icons.chat_bubble_outline_rounded,
    _GroupSearchFilter.image => Icons.image_outlined,
    _GroupSearchFilter.file => Icons.attach_file_rounded,
    _GroupSearchFilter.voice => Icons.mic_none_rounded,
  };

  bool matches(String type) => switch (this) {
    _GroupSearchFilter.all => true,
    _GroupSearchFilter.text => type == 'text' || type.isEmpty,
    _GroupSearchFilter.image => type == 'image',
    _GroupSearchFilter.file => type == 'file',
    _GroupSearchFilter.voice => type == 'voice',
  };
}

class _HighlightedPreview extends StatelessWidget {
  const _HighlightedPreview({required this.text, required this.query});

  final String text;
  final String query;

  @override
  Widget build(BuildContext context) {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Color(0xFF5F5965), height: 1.3),
      );
    }

    final lowerSource = text.toLowerCase();
    final lowerQuery = cleanQuery.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;

    while (start < text.length) {
      final match = lowerSource.indexOf(lowerQuery, start);
      if (match < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }

      if (match > start) {
        spans.add(TextSpan(text: text.substring(start, match)));
      }

      spans.add(
        TextSpan(
          text: text.substring(match, match + cleanQuery.length),
          style: const TextStyle(
            color: Color(0xFF6E489E),
            backgroundColor: Color(0xFFE8DDF5),
            fontWeight: FontWeight.w800,
          ),
        ),
      );

      start = match + cleanQuery.length;
    }

    return Text.rich(
      TextSpan(
        style: const TextStyle(color: Color(0xFF5F5965), height: 1.3),
        children: spans,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _TypeAvatar extends StatelessWidget {
  const _TypeAvatar({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 21,
    backgroundColor: const Color(0xFFF0E9F8),
    child: Icon(_typeIcon(type), size: 20, color: const Color(0xFF7653A5)),
  );
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFFF4F0F7),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF7A7180)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF6E6673),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _SearchState extends StatelessWidget {
  const _SearchState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: const Color(0xFF805BB3)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF756E7C), height: 1.35),
          ),
        ],
      ),
    ),
  );
}

IconData _typeIcon(String type) {
  if (type == 'image') return Icons.image_outlined;
  if (type == 'voice') return Icons.mic_none_rounded;
  if (type == 'file') return Icons.attach_file_rounded;
  return Icons.chat_bubble_outline_rounded;
}

String _typeLabel(String type) {
  if (type == 'image') return 'Photo';
  if (type == 'voice') return 'Voice';
  if (type == 'file') return 'File';
  return 'Text';
}
