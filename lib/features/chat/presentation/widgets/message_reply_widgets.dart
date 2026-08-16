import 'package:flutter/material.dart';

import '../../data/models/message_reply.dart';

class MessageReplyCard extends StatelessWidget {
  const MessageReplyCard({super.key, required this.reply, this.onTap});
  final MessageReply reply;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(9),
    child: Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.fromLTRB(9, 6, 9, 6),
      decoration: BoxDecoration(
        color: const Color(0x16000000),
        borderRadius: BorderRadius.circular(9),
        border: const Border(
          left: BorderSide(color: Color(0xFF9A969E), width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reply.senderName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF4F4B52),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            reply.preview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Color(0xFF5F5865)),
          ),
        ],
      ),
    ),
  );
}

class ReplyComposerBar extends StatelessWidget {
  const ReplyComposerBar({
    super.key,
    required this.reply,
    required this.onClose,
  });

  final MessageReply reply;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 8),
    padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F1F3),
      borderRadius: BorderRadius.circular(7),
      border: const Border(
        left: BorderSide(color: Color(0xFF9A969E), width: 2),
      ),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Replying to ${reply.senderName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF4F4B52),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                reply.preview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: onClose,
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.all(5),
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: Color(0xFF77737B),
            ),
          ),
        ),
      ],
    ),
  );
}
