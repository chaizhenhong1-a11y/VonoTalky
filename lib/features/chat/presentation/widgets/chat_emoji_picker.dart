import 'package:flutter/material.dart';

class ChatEmojiPicker extends StatelessWidget {
  const ChatEmojiPicker({super.key, required this.onSelected});

  final ValueChanged<String> onSelected;

  static const emojis = <String>[
    '😀', '😃', '😄', '😁', '😆', '🥹', '😂', '🤣',
    '😊', '😇', '🙂', '🙃', '😉', '😍', '🥰', '😘',
    '😋', '😜', '🤪', '🤗', '🤭', '🫢', '🤔', '🫡',
    '😎', '🥳', '😏', '😒', '🥺', '😢', '😭', '😤',
    '😡', '🤯', '😳', '🥶', '😴', '🤢', '😈', '👻',
    '👍', '👎', '👏', '🙌', '🤝', '🙏', '💪', '✌️',
    '👌', '🤞', '🫶', '❤️', '🩷', '💜', '💙', '💚',
    '🔥', '✨', '🎉', '💯', '✅', '⭐', '🌙', '☀️',
  ];

  @override
  Widget build(BuildContext context) => Container(
        height: 218,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F7FC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE1DCE8)),
        ),
        child: GridView.builder(
          itemCount: emojis.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemBuilder: (_, index) => InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onSelected(emojis[index]),
            child: Center(
              child: Text(emojis[index], style: const TextStyle(fontSize: 25)),
            ),
          ),
        ),
      );
}
