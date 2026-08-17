import 'package:flutter/material.dart';

class ChatEmojiPicker extends StatefulWidget {
  const ChatEmojiPicker({super.key, required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  State<ChatEmojiPicker> createState() => _ChatEmojiPickerState();
}

class _ChatEmojiPickerState extends State<ChatEmojiPicker> {
  static final List<String> _recentEmojis = <String>[];

  static const Map<_EmojiCategory, List<String>> _emojiGroups = {
    _EmojiCategory.smileys: <String>[
      '😀',
      '😃',
      '😄',
      '😁',
      '😆',
      '🥹',
      '😂',
      '🤣',
      '😊',
      '😇',
      '🙂',
      '🙃',
      '😉',
      '😍',
      '🥰',
      '😘',
      '😋',
      '😜',
      '🤪',
      '🤗',
      '🤭',
      '🫢',
      '🤔',
      '🫡',
      '😎',
      '🥳',
      '😏',
      '😒',
      '🥺',
      '😢',
      '😭',
      '😤',
      '😡',
      '🤯',
      '😳',
      '🥶',
      '😴',
      '🤢',
      '😈',
      '👻',
      '🤠',
      '🤓',
      '🧐',
      '🤩',
      '😬',
      '🫠',
      '🫣',
      '🤫',
    ],
    _EmojiCategory.gestures: <String>[
      '👍',
      '👎',
      '👏',
      '🙌',
      '🤝',
      '🙏',
      '💪',
      '✌️',
      '👌',
      '🤞',
      '🫶',
      '👋',
      '🤟',
      '🤘',
      '🤙',
      '👊',
      '✊',
      '🤛',
      '🤜',
      '🫰',
      '👉',
      '👈',
      '👆',
      '👇',
      '☝️',
      '✋',
      '🤚',
      '🖐️',
      '🖖',
      '💅',
      '🙆',
      '🙅',
      '🤷',
      '🤦',
      '🙋',
      '🫂',
    ],
    _EmojiCategory.hearts: <String>[
      '❤️',
      '🩷',
      '💜',
      '💙',
      '💚',
      '💛',
      '🧡',
      '🖤',
      '🤍',
      '🤎',
      '💔',
      '❤️‍🔥',
      '❤️‍🩹',
      '💕',
      '💞',
      '💓',
      '💗',
      '💖',
      '💘',
      '💝',
      '💟',
      '❣️',
      '💋',
      '💌',
      '🌹',
      '🌷',
      '🌸',
      '🌺',
      '🌻',
      '🌼',
      '🪻',
      '🪷',
    ],
    _EmojiCategory.symbols: <String>[
      '🔥',
      '✨',
      '🎉',
      '💯',
      '✅',
      '⭐',
      '🌙',
      '☀️',
      '⚡',
      '💥',
      '💫',
      '🎊',
      '🎂',
      '🎁',
      '🏆',
      '🥇',
      '🎯',
      '🚀',
      '💡',
      '📌',
      '📍',
      '🔔',
      '💬',
      '💭',
      '☕',
      '🍕',
      '🍔',
      '🍟',
      '🍿',
      '🍰',
      '🍓',
      '🍉',
      '🐶',
      '🐱',
      '🐼',
      '🦋',
      '🌈',
      '☁️',
      '❄️',
      '🌊',
      '🌍',
      '🎵',
      '🎧',
      '📱',
      '💻',
      '⌚',
      '📷',
      '🎮',
    ],
  };

  _EmojiCategory _category = _EmojiCategory.smileys;

  List<String> get _visibleEmojis {
    if (_category == _EmojiCategory.recent) {
      return _recentEmojis.isEmpty
          ? _emojiGroups[_EmojiCategory.smileys]!.take(16).toList()
          : List<String>.unmodifiable(_recentEmojis);
    }
    return _emojiGroups[_category]!;
  }

  void _selectEmoji(String emoji) {
    setState(() {
      _recentEmojis.remove(emoji);
      _recentEmojis.insert(0, emoji);
      if (_recentEmojis.length > 24) {
        _recentEmojis.removeRange(24, _recentEmojis.length);
      }
    });
    widget.onSelected(emoji);
  }

  @override
  Widget build(BuildContext context) => Container(
    height: 286,
    margin: const EdgeInsets.only(top: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFF9F7FC),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE1DCE8)),
    ),
    child: Column(
      children: [
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            children: _EmojiCategory.values
                .map(
                  (category) => _CategoryButton(
                    category: category,
                    selected: category == _category,
                    onTap: () => setState(() => _category = category),
                  ),
                )
                .toList(),
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE9E4EE)),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(8, 9, 8, 8),
            itemCount: _visibleEmojis.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
            ),
            itemBuilder: (_, index) {
              final emoji = _visibleEmojis[index];
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _selectEmoji(emoji),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 25)),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

enum _EmojiCategory { recent, smileys, gestures, hearts, symbols }

extension on _EmojiCategory {
  IconData get icon => switch (this) {
    _EmojiCategory.recent => Icons.history_rounded,
    _EmojiCategory.smileys => Icons.sentiment_satisfied_alt_rounded,
    _EmojiCategory.gestures => Icons.pan_tool_alt_rounded,
    _EmojiCategory.hearts => Icons.favorite_rounded,
    _EmojiCategory.symbols => Icons.auto_awesome_rounded,
  };

  String get label => switch (this) {
    _EmojiCategory.recent => 'Recent',
    _EmojiCategory.smileys => 'Smileys',
    _EmojiCategory.gestures => 'Gestures',
    _EmojiCategory.hearts => 'Hearts',
    _EmojiCategory.symbols => 'More',
  };
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final _EmojiCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: category.label,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 46,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE7DDF5) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          category.icon,
          size: 21,
          color: selected ? const Color(0xFF7653A5) : const Color(0xFF756D7C),
        ),
      ),
    ),
  );
}
