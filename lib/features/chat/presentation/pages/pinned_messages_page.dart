import 'package:flutter/material.dart';

import '../../data/services/pinned_message_service.dart';

class PinnedMessagesPage extends StatelessWidget {
  const PinnedMessagesPage({
    super.key,
    required this.title,
    required this.preferenceId,
    required this.onOpen,
    required this.onRemove,
  });

  final String title;
  final String preferenceId;
  final ValueChanged<String> onOpen;
  final Future<void> Function(String messageId) onRemove;

  static List<Map<String, dynamic>> readPinned(
    Map<String, dynamic>? data,
  ) =>
      PinnedMessageService.parsePinned(data);

  @override
  Widget build(BuildContext context) {
    final service = PinnedMessageService();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F7FC),
        surfaceTintColor: Colors.transparent,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: service.preferencesById(preferenceId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _PinnedState(
              icon: Icons.cloud_off_rounded,
              title: 'Unable to load pinned messages',
              subtitle: '${snapshot.error}',
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final pinned = readPinned(snapshot.data);

          if (pinned.isEmpty) {
            return const _PinnedState(
              icon: Icons.push_pin_outlined,
              title: 'No pinned messages',
              subtitle: 'Pinned messages from this chat will appear here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
            itemCount: pinned.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = pinned[index];
              final id = item['messageId']?.toString() ?? '';
              final preview =
                  item['preview']?.toString() ?? 'Pinned message';
              final sender = item['sender']?.toString() ?? '';
              final type = item['type']?.toString() ?? 'text';

              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF0E9F8),
                    child: Icon(
                      Icons.push_pin_rounded,
                      color: Color(0xFF7653A5),
                    ),
                  ),
                  title: Text(
                    sender.isEmpty ? 'Pinned message' : sender,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${_prefix(type)}$preview',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    tooltip: 'Unpin',
                    onPressed: id.isEmpty
                        ? null
                        : () async {
                            try {
                              await onRemove(id);
                            } catch (error) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Unable to unpin: $error'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                    icon: const Icon(Icons.close_rounded),
                  ),
                  onTap: id.isEmpty
                      ? null
                      : () {
                          Navigator.pop(context);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            onOpen(id);
                          });
                        },
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _prefix(String type) {
    if (type == 'image') return '📷 ';
    if (type == 'voice') return '🎤 ';
    if (type == 'file') return '📎 ';
    return '';
  }
}

class _PinnedState extends StatelessWidget {
  const _PinnedState({
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
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 52,
                color: const Color(0xFF805BB3),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF756E7C),
                ),
              ),
            ],
          ),
        ),
      );
}
