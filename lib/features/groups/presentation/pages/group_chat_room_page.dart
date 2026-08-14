import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../chat/data/services/chat_file_service.dart';
import '../../../chat/data/models/message_reply.dart';
import '../../../chat/data/services/chat_media_service.dart';
import '../../../chat/data/services/chat_voice_service.dart';
import '../../../chat/presentation/widgets/file_message_bubble.dart';
import '../../../chat/presentation/widgets/message_reply_widgets.dart';
import '../../../chat/presentation/widgets/recording_composer.dart';
import '../../../chat/presentation/widgets/chat_emoji_picker.dart';
import '../../../chat/presentation/widgets/voice_message_bubble.dart';
import '../../../chat/presentation/pages/media_viewer_page.dart';
import '../../data/models/chat_group.dart';
import '../../data/services/group_service.dart';
import 'group_details_page.dart';

class GroupChatRoomPage extends StatefulWidget {
  const GroupChatRoomPage({super.key, required this.group});
  final ChatGroup group;
  @override
  State<GroupChatRoomPage> createState() => _GroupChatRoomPageState();
}

class _GroupChatRoomPageState extends State<GroupChatRoomPage> {
  final controller = TextEditingController();
  final messageScrollController = ScrollController();
  final service = GroupService();
  final mediaService = ChatMediaService();
  final fileService = ChatFileService();
  final voiceService = ChatVoiceService();
  bool sending = false;
  bool uploading = false;
  bool recording = false;
  final voiceWatch = Stopwatch();
  Timer? voiceTimer;
  int voiceSeconds = 0;
  MessageReply? replyingTo;
  bool showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    service.markRead(widget.group.id);
  }

  @override
  void dispose() {
    voiceTimer?.cancel();
    voiceService.dispose();
    controller.dispose();
    messageScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          toolbarHeight: 82,
          backgroundColor: const Color(0xFFE9E3FA),
          surfaceTintColor: Colors.transparent,
          title: Row(children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: const Color(0xFFDCCFF3),
              backgroundImage: widget.group.photoUrl == null ? null : NetworkImage(widget.group.photoUrl!),
              child: widget.group.photoUrl == null ? Text(widget.group.name[0].toUpperCase()) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.group.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Text('${widget.group.memberCount} members', style: const TextStyle(fontSize: 11, color: Color(0xFF605968))),
              ]),
            ),
          ]),
          actions: [
            IconButton(onPressed: () => _notice('Group video call is coming next.'), icon: const Icon(Icons.videocam_outlined)),
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupDetailsPage(groupId: widget.group.id),
                ),
              ),
              icon: const Icon(Icons.info_outline_rounded),
            ),
          ],
        ),
        body: Container(
          color: const Color(0xFFEDF2F8),
          child: Column(children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: service.messages(widget.group.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  WidgetsBinding.instance.addPostFrameCallback((_) => service.markRead(widget.group.id));
                  final messages = snapshot.data!.docs;
                  if (messages.isEmpty) return Center(child: Text('Start chatting in ${widget.group.name}'));
                  return ListView.builder(
                    controller: messageScrollController,
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                    itemCount: messages.length,
                    itemBuilder: (_, index) {
                      final document = messages[index];
                      final data = document.data();
                      final mine = data['senderId'] == service.myId;
                      final deleted = data['isDeleted'] as bool? ?? false;
                      final sentAt = (data['sentAt'] as Timestamp?)?.toDate();
                      final readBy = List<String>.from(
                        data['readBy'] as List? ?? const [],
                      );
                      final replyData = data['replyTo'];
                      final reply = replyData is Map
                          ? MessageReply.fromMap(
                              Map<String, dynamic>.from(replyData),
                            )
                          : null;
                      return Align(
                        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: GestureDetector(
                          onLongPress: deleted
                              ? null
                              : () => _showActions(document.id, data, mine),
                          child: Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .78),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                            decoration: BoxDecoration(
                              color: mine ? const Color(0xFFCDBCEB) : const Color(0xFFFFFCF3),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(17),
                                topRight: const Radius.circular(17),
                                bottomLeft: Radius.circular(mine ? 17 : 5),
                                bottomRight: Radius.circular(mine ? 5 : 17),
                              ),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              if (!mine)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(data['senderName'] as String? ?? 'Member', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF7150A1))),
                                ),
                              if (reply != null)
                                MessageReplyCard(
                                  reply: reply,
                                  onTap: () => _jumpToMessage(
                                    reply.messageId,
                                    messages,
                                  ),
                                ),
                              if (deleted)
                                const Text('This message was recalled', style: TextStyle(fontStyle: FontStyle.italic))
                              else if (data['type'] == 'image')
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MediaViewerPage(
                                        url: data['imageUrl'] as String,
                                        name: 'VonoTalky_${document.id}.jpg',
                                      ),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      data['imageUrl'] as String,
                                      width: 230,
                                      height: 230,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (_, child, loading) => loading == null
                                          ? child
                                          : const Center(child: CircularProgressIndicator(color: Color(0xFFB49ADF))),
                                      errorBuilder: (_, __, ___) => const SizedBox(
                                        width: 230,
                                        height: 230,
                                        child: Center(child: Icon(Icons.broken_image_outlined, size: 42)),
                                      ),
                                    ),
                                  ),
                                )
                              else if (data['type'] == 'file')
                                FileMessageBubble(name: data['fileName'] as String? ?? 'File', url: data['fileUrl'] as String, size: data['fileSize'] as int? ?? 0, mine: mine)
                              else if (data['type'] == 'voice')
                                VoiceMessageBubble(url: data['audioUrl'] as String, durationMs: data['durationMs'] as int? ?? 0, mine: mine)
                              else
                                Text(data['text'] as String? ?? ''),
                              const SizedBox(height: 3),
                              Align(
                                alignment: Alignment.centerRight,
                                widthFactor: 1,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(_time(sentAt), style: const TextStyle(fontSize: 10, color: Color(0xFF716A78))),
                                    if (mine) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        readBy.length > 1
                                            ? Icons.done_all_rounded
                                            : Icons.done_rounded,
                                        size: 14,
                                        color: readBy.length > 1
                                            ? const Color(0xFF7150A1)
                                            : const Color(0xFF8C8296),
                                      ),
                                      if (readBy.length > 1) ...[
                                        const SizedBox(width: 2),
                                        Text(
                                          '${readBy.length - 1}',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            color: Color(0xFF7150A1),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ],
                                ),
                              ),
                            ]),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                    if (replyingTo != null)
                      ReplyComposerBar(
                        reply: replyingTo!,
                        onClose: () => setState(() => replyingTo = null),
                      ),
                    if (replyingTo != null) const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), border: Border.all(color: const Color(0xFFE1DCE8))),
                      child: recording
                        ?
                      RecordingComposer(
                        seconds: voiceSeconds,
                        uploading: uploading,
                        onCancel: _cancelRecording,
                        onSend: _sendRecording,
                      )
                        : Row(children: [
                    IconButton(
                      onPressed: _toggleEmojiPicker,
                      icon: const Icon(Icons.sentiment_satisfied_alt_outlined),
                    ),
                    IconButton(onPressed: uploading ? null : _showAttachmentMenu, icon: uploading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.attach_file_rounded)),
                    Expanded(child: TextField(controller: controller, minLines: 1, maxLines: 4, decoration: const InputDecoration(hintText: 'Message the group...', border: InputBorder.none, isDense: true), onTap: () { if (showEmojiPicker) setState(() => showEmojiPicker = false); }, onChanged: (_) => setState(() {}), onSubmitted: (_) => _sendText())),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFB49ADF),
                      ),
                      onPressed: uploading || sending
                          ? null
                          : controller.text.trim().isNotEmpty
                              ? _sendText
                              : _startRecording,
                      icon: Icon(
                        controller.text.trim().isNotEmpty
                            ? Icons.send_rounded
                            : Icons.mic_rounded,
                        size: 19,
                      ),
                    ),
                  ]),
                    ),
                    if (showEmojiPicker)
                      ChatEmojiPicker(onSelected: _insertEmoji),
                  ]),
              ),
            ),
          ]),
        ),
      );

  void _toggleEmojiPicker() {
    if (!showEmojiPicker) FocusScope.of(context).unfocus();
    setState(() => showEmojiPicker = !showEmojiPicker);
  }

  void _insertEmoji(String emoji) {
    final value = controller.value;
    final start = value.selection.isValid ? value.selection.start : value.text.length;
    final end = value.selection.isValid ? value.selection.end : value.text.length;
    final updated = value.text.replaceRange(start, end, emoji);
    controller.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
    setState(() {});
  }

  Future<void> _sendText() async {
    final text = controller.text.trim();
    if (text.isEmpty || sending) return;
    final reply = replyingTo;
    controller.clear();
    setState(() {
      showEmojiPicker = false;
      sending = true;
      replyingTo = null;
    });
    try {
      await service.sendText(widget.group, text, reply: reply);
    } catch (_) {
      controller.text = text;
      replyingTo = reply;
      if (mounted) _notice('Message could not be sent');
    } finally { if (mounted) setState(() => sending = false); }
  }

  void _showAttachmentMenu() => showModalBottomSheet<void>(
        context: context,
        builder: (_) => SafeArea(child: Wrap(children: [
          ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Photo library'), onTap: () => _pickImage(ImageSource.gallery)),
          ListTile(leading: const Icon(Icons.camera_alt_outlined), title: const Text('Camera'), onTap: () => _pickImage(ImageSource.camera)),
          ListTile(leading: const Icon(Icons.attach_file_rounded), title: const Text('File'), subtitle: const Text('Max 25 MB'), onTap: _pickFile),
        ])),
      );

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    final file = await mediaService.pick(source);
    if (file == null || !mounted) return;
    setState(() => uploading = true);
    try {
      final upload = await mediaService.upload(file: file, roomId: widget.group.id, userId: service.myId, root: 'group_media');
      await service.sendImage(widget.group, upload.url, upload.storagePath, reply: replyingTo);
      if (mounted) setState(() => replyingTo = null);
    } finally { if (mounted) setState(() => uploading = false); }
  }

  Future<void> _pickFile() async {
    Navigator.pop(context);
    final file = await fileService.pick();
    if (file == null || !mounted) return;
    setState(() => uploading = true);
    try {
      final upload = await fileService.upload(file: file, roomId: widget.group.id, userId: service.myId, root: 'group_media');
      await service.sendFile(widget.group, url: upload.url, path: upload.path, name: upload.name, extension: upload.extension, size: upload.size, reply: replyingTo);
      if (mounted) setState(() => replyingTo = null);
    } finally { if (mounted) setState(() => uploading = false); }
  }

  Future<void> _startRecording() async {
    if (!await voiceService.start() || !mounted) {
      if (mounted) _notice('Microphone permission is required');
      return;
    }
    voiceWatch..reset()..start();
    voiceTimer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() => voiceSeconds = voiceWatch.elapsed.inSeconds); });
    setState(() { recording = true; voiceSeconds = 0; });
  }

  Future<void> _sendRecording() async {
    if (!recording) return;
    final path = await voiceService.stop();
    voiceWatch.stop();
    voiceTimer?.cancel();
    final duration = voiceWatch.elapsedMilliseconds;
    if (mounted) setState(() => recording = false);
    if (path == null || duration < 500) return;
    setState(() => uploading = true);
    try {
      final upload = await voiceService.upload(sourcePath: path, roomId: widget.group.id, userId: service.myId, root: 'group_media');
      await service.sendVoice(widget.group, url: upload.url, path: upload.path, durationMs: duration, reply: replyingTo);
      if (mounted) setState(() => replyingTo = null);
    } finally { if (mounted) setState(() => uploading = false); }
  }

  Future<void> _cancelRecording() async {
    if (!recording) return;
    await voiceService.cancel();
    voiceWatch..stop()..reset();
    voiceTimer?.cancel();
    if (mounted) setState(() { recording = false; voiceSeconds = 0; });
  }

  Future<void> _showActions(String id, Map<String, dynamic> data, bool mine) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(children: [
          ListTile(leading: const Icon(Icons.reply_rounded), title: const Text('Reply'), onTap: () => Navigator.pop(context, 'reply')),
          if ((data['text'] as String? ?? '').isNotEmpty)
            ListTile(leading: const Icon(Icons.copy_rounded), title: const Text('Copy'), onTap: () => Navigator.pop(context, 'copy')),
          if (mine)
            ListTile(leading: const Icon(Icons.undo_rounded), title: const Text('Recall message'), onTap: () => Navigator.pop(context, 'recall')),
        ]),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'reply') {
      setState(() {
        replyingTo = MessageReply.fromMessage(
          messageId: id,
          data: data,
          senderName: mine
              ? 'You'
              : (data['senderName'] as String? ?? 'Member'),
        );
      });
    } else if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: data['text'] as String));
      _notice('Message copied');
    } else if (action == 'recall') {
      await service.recall(widget.group.id, id);
    }
  }

  Future<void> _jumpToMessage(
    String messageId,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> messages,
  ) async {
    final index = messages.indexWhere((message) => message.id == messageId);
    if (index < 0 || !messageScrollController.hasClients) {
      _notice('Original message is outside the loaded history');
      return;
    }
    final target = (index * 82.0).clamp(
      0.0,
      messageScrollController.position.maxScrollExtent,
    ).toDouble();
    await messageScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  String _time(DateTime? value) => value == null ? '' : '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  void _notice(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
