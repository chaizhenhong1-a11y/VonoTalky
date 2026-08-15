import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../chat/data/services/chat_file_service.dart';
import '../../../chat/data/models/message_reply.dart';
import '../../../chat/data/services/chat_media_service.dart';
import '../../../chat/data/services/chat_voice_service.dart';
import '../../../chat/data/services/pinned_message_service.dart';
import '../../../chat/presentation/widgets/file_message_bubble.dart';
import '../../../chat/presentation/widgets/message_reply_widgets.dart';
import '../../../chat/presentation/widgets/recording_composer.dart';
import '../../../chat/presentation/widgets/chat_emoji_picker.dart';
import '../../../chat/presentation/widgets/pinned_message_banner.dart';
import '../../../chat/presentation/widgets/voice_message_bubble.dart';
import '../../../chat/presentation/pages/media_viewer_page.dart';
import '../../data/models/chat_group.dart';
import '../../data/services/group_recent_chat_service.dart';
import '../../data/services/group_service.dart';
import 'group_details_page.dart';
import 'group_chat_search_page.dart';
import 'group_message_info_page.dart';

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
  final recentChatService = GroupRecentChatService();
  final pinnedMessageService = PinnedMessageService();
  final mediaService = ChatMediaService();
  final fileService = ChatFileService();
  final voiceService = ChatVoiceService();
  Timer? draftTimer;
  bool sending = false;
  bool uploading = false;
  bool recording = false;
  final voiceWatch = Stopwatch();
  Timer? voiceTimer;
  int voiceSeconds = 0;
  MessageReply? replyingTo;
  bool showEmojiPicker = false;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> latestMessages = const [];

  @override
  void initState() {
    super.initState();
    service.markRead(widget.group.id);
    _restoreDraft();
  }

  @override
  void dispose() {
    draftTimer?.cancel();
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
            IconButton(
              tooltip: 'Search messages',
              onPressed: _openGroupSearch,
              icon: const Icon(Icons.search_rounded),
            ),
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
            PinnedMessageBanner(
              title: 'Pinned Messages',
              preferenceId: 'group_${widget.group.id}',
              stream: pinnedMessageService.groupPreferences(widget.group.id),
              onTap: (messageId) => _jumpToMessage(
                messageId,
                latestMessages,
              ),
              onRemove: (messageId) =>
                  pinnedMessageService.removeGroup(
                    widget.group.id,
                    messageId,
                  ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: service.messages(widget.group.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  WidgetsBinding.instance.addPostFrameCallback((_) => service.markRead(widget.group.id));
                  final messages = snapshot.data!.docs;
                  latestMessages = messages;
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
                      final reactions = Map<String, dynamic>.from(
                        data['reactions'] as Map? ?? const {},
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
                          onDoubleTap: deleted
                              ? null
                              : () => _toggleReaction(document.id, '❤️'),
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
                                    if (data['editedAt'] != null) ...[
                                      const SizedBox(width: 4),
                                      const Text(
                                        'edited',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Color(0xFF8B8293),
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
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
                              if (reactions.isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Wrap(
                                  spacing: 5,
                                  runSpacing: 4,
                                  children: reactions.entries.map((entry) {
                                    final users = List<String>.from(
                                      entry.value as List? ?? const [],
                                    );
                                    final reactedByMe =
                                        users.contains(service.myId);
                                    return InkWell(
                                      onTap: () => _toggleReaction(
                                        document.id,
                                        entry.key,
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: reactedByMe
                                              ? const Color(0xFFE2D4F5)
                                              : const Color(0xFFF4EFF8),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: Text(
                                          '${entry.key} ${users.length}',
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
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
                    Expanded(child: TextField(controller: controller, minLines: 1, maxLines: 4, decoration: const InputDecoration(hintText: 'Message the group...', border: InputBorder.none, isDense: true), onTap: () { if (showEmojiPicker) setState(() => showEmojiPicker = false); }, onChanged: (_) { _scheduleDraftSave(); setState(() {}); }, onSubmitted: (_) => _sendText())),
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

  Future<void> _openGroupSearch() async {
    final messageId = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => GroupChatSearchPage(groupId: widget.group.id),
      ),
    );

    if (messageId != null && mounted) {
      await _jumpToMessage(messageId, latestMessages);
    }
  }

  Future<void> _restoreDraft() async {
    final draft = await recentChatService.loadDraft(widget.group.id);
    if (!mounted || draft.isEmpty || controller.text.isNotEmpty) return;

    controller.value = TextEditingValue(
      text: draft,
      selection: TextSelection.collapsed(offset: draft.length),
    );
    setState(() {});
  }

  void _scheduleDraftSave() {
    draftTimer?.cancel();
    final value = controller.text;
    draftTimer = Timer(const Duration(milliseconds: 350), () {
      recentChatService.setDraft(widget.group.id, value);
    });
  }

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
      draftTimer?.cancel();
      await recentChatService.setDraft(widget.group.id, '');
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
          ListTile(leading: const Icon(Icons.emoji_emotions_outlined), title: const Text('React'), onTap: () => Navigator.pop(context, 'react')),
          ListTile(leading: const Icon(Icons.push_pin_outlined), title: const Text('Pin message'), onTap: () => Navigator.pop(context, 'pin')),
          if (mine && (data['type'] as String? ?? 'text') == 'text')
            ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('Edit message'), onTap: () => Navigator.pop(context, 'edit')),
          if (mine)
            ListTile(leading: const Icon(Icons.info_outline_rounded), title: const Text('Message info'), onTap: () => Navigator.pop(context, 'info')),
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
    } else if (action == 'react') {
      await _showReactionPicker(id);
    } else if (action == 'pin') {
      try {
        await pinnedMessageService.pinGroup(
          groupId: widget.group.id,
          messageId: id,
          data: data,
          senderName: mine
              ? 'You'
              : (data['senderName'] as String? ?? 'Member'),
        );
        _notice('Message pinned');
      } catch (error) {
        _notice('Pin failed: $error');
      }
    } else if (action == 'edit') {
      await _editGroupMessage(id, data);
    } else if (action == 'info') {
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupMessageInfoPage(
              groupId: widget.group.id,
              messageId: id,
              message: data,
            ),
          ),
        );
      }
    } else if (action == 'recall') {
      await service.recall(widget.group.id, id);
    }
  }

  Future<void> _toggleReaction(
    String messageId,
    String emoji,
  ) async {
    final reference = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.group.id)
        .collection('messages')
        .doc(messageId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(reference);
        if (!snapshot.exists) return;

        final data = snapshot.data() ?? const <String, dynamic>{};
        final reactions = Map<String, dynamic>.from(
          data['reactions'] as Map? ?? const {},
        );
        final users = List<String>.from(
          reactions[emoji] as List? ?? const [],
        );

        if (users.contains(service.myId)) {
          users.remove(service.myId);
        } else {
          users.add(service.myId);
        }

        if (users.isEmpty) {
          reactions.remove(emoji);
        } else {
          reactions[emoji] = users;
        }

        transaction.update(reference, {'reactions': reactions});
      });
    } catch (error) {
      if (mounted) _notice('Reaction failed: $error');
    }
  }

  Future<void> _showReactionPicker(String messageId) async {
    const emojis = ['❤️', '👍', '😂', '😮', '😢', '🔥'];

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: 8,
            runSpacing: 8,
            children: emojis.map((emoji) {
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => Navigator.pop(sheetContext, emoji),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );

    if (selected != null) {
      await _toggleReaction(messageId, selected);
    }
  }

  Future<void> _editGroupMessage(
    String messageId,
    Map<String, dynamic> data,
  ) async {
    final original = data['text'] as String? ?? '';
    if (original.trim().isEmpty) return;

    final editController = TextEditingController(text: original);

    final updated = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Edit message',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: editController,
          autofocus: true,
          minLines: 1,
          maxLines: 6,
          textInputAction: TextInputAction.newline,
          decoration: const InputDecoration(
            hintText: 'Edit your message',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = editController.text.trim();
              if (value.isEmpty) return;
              Navigator.pop(dialogContext, value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    editController.dispose();

    if (updated == null || updated == original.trim()) return;

    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.group.id)
          .collection('messages')
          .doc(messageId)
          .update({
        'text': updated,
        'editedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) _notice('Message edited');
    } catch (error) {
      if (mounted) _notice('Edit failed: $error');
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
