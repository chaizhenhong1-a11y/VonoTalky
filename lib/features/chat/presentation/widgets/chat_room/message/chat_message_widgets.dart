part of '../../../pages/real_chat_room_page.dart';

class _LinkPreviewButton extends StatelessWidget {
  const _LinkPreviewButton({required this.url, required this.onTap});

  final String url;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url);
    final host = uri?.host.isNotEmpty == true ? uri!.host : url;
    return Material(
      color: const Color(0x26FFFFFF),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: () => onTap(url),
        borderRadius: BorderRadius.circular(11),
        child: Container(
          constraints: const BoxConstraints(minHeight: 38),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: const Color(0x337653A5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.link_rounded,
                size: 18,
                color: Color(0xFF7653A5),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  host,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7653A5),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.open_in_new_rounded,
                size: 15,
                color: Color(0xFF7653A5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageActionButton extends StatelessWidget {
  const _MessageActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFEDE5F8),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF7653A5), size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
}

class _OriginalMessagePreview extends StatelessWidget {
  const _OriginalMessagePreview({
    required this.data,
    required this.mine,
    required this.otherName,
  });

  final Map<String, dynamic> data;
  final bool mine;
  final String otherName;

  @override
  Widget build(BuildContext context) {
    final deleted = data['isDeleted'] as bool? ?? false;
    final type = data['type'] as String? ?? 'text';
    final sentAt = (data['sentAt'] as Timestamp?)?.toDate();

    final content = deleted
        ? 'This message was deleted'
        : switch (type) {
            'image' => '📷 Photo',
            'voice' || 'audio' => '🎤 Voice message',
            'file' => '📎 ${(data['fileName'] as String? ?? 'File').trim()}',
            _ =>
              (data['text'] as String? ?? '').trim().isEmpty
                  ? 'Message'
                  : (data['text'] as String).trim(),
          };

    final sender = mine ? 'You' : otherName;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Original message',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Color(0xFF4D4652),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: mine ? const Color(0xFFF0E5FF) : const Color(0xFFFFFBF3),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE6DEE9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      sender,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF7653A5),
                      ),
                    ),
                  ),
                  if (sentAt != null)
                    Text(
                      _formatPreviewTime(sentAt),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF9B919E),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: deleted
                      ? const Color(0xFF9A919B)
                      : const Color(0xFF403942),
                  fontStyle: deleted ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'This message is older than the currently loaded chat window.',
          style: TextStyle(fontSize: 10, color: Color(0xFF9B919E)),
        ),
      ],
    );
  }

  static String _formatPreviewTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final month = time.month.toString().padLeft(2, '0');
    return '$day/$month  $hour:$minute';
  }
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFD9DEE6))),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xD9FFFFFF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF716A78),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFD9DEE6))),
      ],
    ),
  );
}

class _MessageDetailRow extends StatelessWidget {
  const _MessageDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, size: 21, color: const Color(0xFF7653A5)),
        const SizedBox(width: 12),
        SizedBox(
          width: 62,
          child: Text(label, style: const TextStyle(color: Color(0xFF716A78))),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
