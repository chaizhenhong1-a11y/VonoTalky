import 'package:flutter/material.dart';

import '../pages/pinned_messages_page.dart';

class PinnedMessageBanner extends StatefulWidget {
  const PinnedMessageBanner({
    super.key,
    required this.stream,
    required this.preferenceId,
    required this.onTap,
    required this.onRemove,
    required this.title,
  });

  final Stream<Map<String, dynamic>> stream;
  final String preferenceId;
  final ValueChanged<String> onTap;
  final Future<void> Function(String messageId) onRemove;
  final String title;

  @override
  State<PinnedMessageBanner> createState() => _PinnedMessageBannerState();
}

class _PinnedMessageBannerState extends State<PinnedMessageBanner> {
  int index = 0;

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<Map<String, dynamic>>(
        stream: widget.stream,
        builder: (context, snapshot) {
          final pinned = PinnedMessagesPage.readPinned(snapshot.data);
          if (pinned.isEmpty) {
            index = 0;
            return const SizedBox.shrink();
          }

          if (index >= pinned.length) index = pinned.length - 1;
          final item = pinned[index];
          final messageId = item['messageId'] as String;
          final preview = item['preview'] as String? ?? 'Pinned message';
          final sender = item['sender'] as String? ?? '';
          final type = item['type'] as String? ?? 'text';

          return Material(
            color: const Color(0xFFF3ECFA),
            child: InkWell(
              onTap: () => widget.onTap(messageId),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 7, 6, 7),
                child: Row(
                  children: [
                    const Icon(
                      Icons.push_pin_rounded,
                      size: 19,
                      color: Color(0xFF7653A5),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  sender.isEmpty ? 'Pinned message' : sender,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF7653A5),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (pinned.length > 1)
                                Text(
                                  '${index + 1} / ${pinned.length}',
                                  style: const TextStyle(
                                    color: Color(0xFF8A7D95),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            '${_prefix(type)}$preview',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF5E5865),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (pinned.length > 1)
                      IconButton(
                        tooltip: 'Previous pinned message',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(
                          () => index = (index - 1 + pinned.length) % pinned.length,
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_up_rounded,
                          size: 20,
                        ),
                      ),
                    if (pinned.length > 1)
                      IconButton(
                        tooltip: 'Next pinned message',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(
                          () => index = (index + 1) % pinned.length,
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                        ),
                      ),
                    IconButton(
                      tooltip: 'Pinned messages',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PinnedMessagesPage(
                            title: widget.title,
                            preferenceId: widget.preferenceId,
                            onOpen: widget.onTap,
                            onRemove: widget.onRemove,
                          ),
                        ),
                      ),
                      icon: const Icon(
                        Icons.list_alt_rounded,
                        size: 19,
                        color: Color(0xFF756E7C),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

  static String _prefix(String type) {
    if (type == 'image') return '📷 ';
    if (type == 'voice') return '🎤 ';
    if (type == 'file') return '📎 ';
    return '';
  }
}
