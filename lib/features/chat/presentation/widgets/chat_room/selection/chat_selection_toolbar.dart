part of '../../../pages/real_chat_room_page.dart';

class _SelectionToolbar extends StatelessWidget {
  const _SelectionToolbar({
    required this.count,
    required this.hasSelection,
    required this.hasTextSelection,
    required this.onClose,
    required this.onSelectAll,
    required this.onReply,
    required this.onCopy,
    required this.onCopyWithTime,
    required this.onSave,
    required this.onPin,
    required this.onForward,
    required this.onDelete,
  });

  final int count;
  final bool hasSelection;
  final bool hasTextSelection;
  final VoidCallback onClose;
  final VoidCallback onSelectAll;
  final VoidCallback onReply;
  final VoidCallback onCopy;
  final VoidCallback onCopyWithTime;
  final VoidCallback onSave;
  final VoidCallback onPin;
  final VoidCallback onForward;
  final VoidCallback onDelete;

  void _runMoreAction(String action) {
    switch (action) {
      case 'copy':
        onCopy();
      case 'copyTime':
        onCopyWithTime();
      case 'pin':
        onPin();
    }
  }

  Widget _action({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    final enabled = onPressed != null;
    final foreground = enabled
        ? (color ?? const Color(0xFF514A58))
        : const Color(0xFFB8B1BC);

    return SizedBox(
      width: 54,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: foreground),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5DFEA))),
      ),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Close selection',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
          const Spacer(),
          _action(
            icon: Icons.reply_rounded,
            label: 'Reply',
            onPressed: count == 1 ? onReply : null,
          ),
          _action(
            icon: Icons.forward_rounded,
            label: 'Forward',
            onPressed: hasSelection ? onForward : null,
          ),
          _action(
            icon: Icons.bookmark_add_outlined,
            label: 'Save',
            onPressed: hasSelection ? onSave : null,
          ),
          _action(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            onPressed: hasSelection ? onDelete : null,
            color: const Color(0xFFB14E68),
          ),
          SizedBox(
            width: 54,
            child: PopupMenuButton<String>(
              tooltip: 'More actions',
              enabled: hasSelection,
              onSelected: _runMoreAction,
              padding: EdgeInsets.zero,
              itemBuilder: (context) => [
                if (hasTextSelection)
                  const PopupMenuItem(
                    value: 'copy',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.copy_rounded),
                      title: Text('Copy text'),
                    ),
                  ),
                if (hasTextSelection)
                  const PopupMenuItem(
                    value: 'copyTime',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.content_paste_search_rounded),
                      title: Text('Copy with time'),
                    ),
                  ),
                const PopupMenuItem(
                  value: 'pin',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.push_pin_outlined),
                    title: Text('Pin'),
                  ),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.more_horiz_rounded,
                      size: 22,
                      color: hasSelection
                          ? const Color(0xFF514A58)
                          : const Color(0xFFB8B1BC),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'More',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: hasSelection
                            ? const Color(0xFF514A58)
                            : const Color(0xFFB8B1BC),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
