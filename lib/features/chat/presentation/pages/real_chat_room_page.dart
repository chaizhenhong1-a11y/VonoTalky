import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/chat_user.dart';
import '../../data/models/message_reply.dart';
import '../../data/services/chat_media_service.dart';
import '../../data/services/chat_file_service.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/chat_voice_service.dart';
import '../../data/services/message_management_service.dart';
import '../widgets/voice_message_bubble.dart';
import '../widgets/file_message_bubble.dart';
import '../widgets/message_reply_widgets.dart';
import '../widgets/recording_composer.dart';
import '../widgets/chat_emoji_picker.dart';
import '../../../contacts/presentation/pages/contact_detail_page.dart';
import 'chat_search_page.dart';
import 'forward_message_page.dart';
import 'media_viewer_page.dart';
import 'saved_messages_page.dart';
import 'shared_media_page.dart';

class RealChatRoomPage extends StatefulWidget {
  const RealChatRoomPage({super.key, required this.user});
  final ChatUser user;
  @override
  State<RealChatRoomPage> createState() => _RealChatRoomPageState();
}

class _RealChatRoomPageState extends State<RealChatRoomPage> {
  final controller = TextEditingController();
  final messageScrollController = ScrollController();
  final service = ChatService();
  final mediaService = ChatMediaService();
  final fileService = ChatFileService();
  final voiceService = ChatVoiceService();
  final managementService = MessageManagementService();
  List<QueryDocumentSnapshot<Map<String, dynamic>>> latestMessages = const [];
  final Set<String> selectedMessageIds = {};
  Timer? typingTimer;
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
    service.markRead(widget.user.uid);
    service.ensureConversation(widget.user.uid);
    controller.addListener(_typingChanged);
  }

  void _typingChanged() {
    if (mounted) setState(() {});
    typingTimer?.cancel();
    service.setTyping(widget.user.uid, controller.text.trim().isNotEmpty);
    typingTimer = Timer(const Duration(seconds: 2), () {
      service.setTyping(widget.user.uid, false);
    });
  }

  @override
  void dispose() {
    typingTimer?.cancel();
    service.setTyping(widget.user.uid, false);
    voiceTimer?.cancel();
    voiceService.dispose();
    controller.dispose();
    messageScrollController.dispose();
    super.dispose();
  }

  Future<void> send() async {
    final text = controller.text;
    if (text.trim().isEmpty || sending) return;
    final reply = replyingTo;
    controller.clear();
    setState(() {
      sending = true;
      replyingTo = null;
      showEmojiPicker = false;
    });
    try {
      await service.send(widget.user.uid, text, reply: reply);
    } catch (_) {
      controller.text = text;
      replyingTo = reply;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Message could not be sent'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () {
                controller.text = text;
                send();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    final file = await mediaService.pick(source);
    if (file == null || !mounted) return;
    setState(() => uploading = true);
    try {
      await service.ensureConversation(widget.user.uid);
      final uploaded = await mediaService.upload(
        file: file,
        roomId: service.roomId(widget.user.uid),
        userId: service.myId,
      );
      await service.sendImage(
        otherId: widget.user.uid,
        imageUrl: uploaded.url,
        storagePath: uploaded.storagePath,
        reply: replyingTo,
      );
      if (mounted) setState(() => replyingTo = null);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image upload failed')),
        );
      }
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  Future<void> _startRecording() async {
    final allowed = await voiceService.start();
    if (!allowed || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required')),
        );
      }
      return;
    }
    voiceWatch
      ..reset()
      ..start();
    voiceTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => voiceSeconds = voiceWatch.elapsed.inSeconds);
    });
    setState(() {
      recording = true;
      voiceSeconds = 0;
    });
  }

  Future<void> _sendRecording() async {
    if (!recording) return;
    final sourcePath = await voiceService.stop();
    voiceWatch.stop();
    voiceTimer?.cancel();
    final durationMs = voiceWatch.elapsedMilliseconds;
    if (mounted) setState(() => recording = false);
    if (sourcePath == null || durationMs < 500) return;
    setState(() => uploading = true);
    try {
      final upload = await voiceService.upload(
        sourcePath: sourcePath,
        roomId: service.roomId(widget.user.uid),
        userId: service.myId,
      );
      await service.sendVoice(
        otherId: widget.user.uid,
        audioUrl: upload.url,
        storagePath: upload.path,
        durationMs: durationMs,
        reply: replyingTo,
      );
      if (mounted) setState(() => replyingTo = null);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice message upload failed')),
        );
      }
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  Future<void> _cancelRecording() async {
    if (!recording) return;
    await voiceService.cancel();
    voiceWatch
      ..stop()
      ..reset();
    voiceTimer?.cancel();
    if (mounted) {
      setState(() {
        recording = false;
        voiceSeconds = 0;
      });
    }
  }

  Future<void> _pickFile() async {
    Navigator.pop(context);
    final file = await fileService.pick();
    if (file == null || !mounted) return;
    setState(() => uploading = true);
    try {
      await service.ensureConversation(widget.user.uid);
      final uploaded = await fileService.upload(
        file: file,
        roomId: service.roomId(widget.user.uid),
        userId: service.myId,
      );
      await service.sendFile(
        otherId: widget.user.uid,
        fileUrl: uploaded.url,
        storagePath: uploaded.path,
        fileName: uploaded.name,
        extension: uploaded.extension,
        fileSize: uploaded.size,
        reply: replyingTo,
      );
      if (mounted) setState(() => replyingTo = null);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File upload failed or exceeds 25 MB')),
        );
      }
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          toolbarHeight: 82,
          backgroundColor: const Color(0xFFE9E3FA),
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          actions: [
            IconButton(
              onPressed: _openSearch,
              icon: const Icon(Icons.search_rounded),
            ),
            IconButton(
              onPressed: () => _notice('Voice call is coming next.'),
              icon: const Icon(Icons.call_outlined),
            ),
            IconButton(
              onPressed: _showChatMenu,
              icon: const Icon(Icons.more_vert_rounded),
            ),
          ],
          titleSpacing: 0,
          title: InkWell(
            onTap: _openContactDetails,
            borderRadius: BorderRadius.circular(14),
            child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 23,
                    backgroundColor: Colors.white,
                    backgroundImage: widget.user.photoUrl == null
                        ? null
                        : NetworkImage(widget.user.photoUrl!),
                    child: widget.user.photoUrl == null
                        ? Text(widget.user.name[0].toUpperCase())
                        : null,
                  ),
                  if (widget.user.isOnline)
                    Positioned(
                      right: -1,
                      bottom: 1,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: const Color(0xFF24C77A),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    StreamBuilder<bool>(
                      stream: service.typing(widget.user.uid),
                      builder: (_, snapshot) {
                        final text = snapshot.data == true
                            ? 'Typing…'
                            : widget.user.isOnline
                                ? 'Online'
                                : _lastSeen(widget.user.lastSeen);
                        return Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF605968)),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
            ),
          ),
          centerTitle: false,
        ),
        body: Container(
          color: const Color(0xFFEDF2F8),
          child: Column(children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: service.messages(widget.user.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs.where((document) {
                  final hiddenFor = List<String>.from(
                    document.data()['hiddenFor'] as List? ?? const [],
                  );
                  return !hiddenFor.contains(service.myId);
                }).toList();
                latestMessages = docs;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  service.markRead(widget.user.uid);
                });
                if (docs.isEmpty) {
                  return Center(child: Text('Say hello to ${widget.user.name}'));
                }
                return ListView.builder(
                  controller: messageScrollController,
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final doc = docs[i];
                    final data = doc.data();
                    final mine = data['senderId'] == service.myId;
                    final deleted = data['isDeleted'] as bool? ?? false;
                    final sentAt = (data['sentAt'] as Timestamp?)?.toDate();
                    final read = data['readAt'] != null;
                    final replyData = data['replyTo'];
                    final reply = replyData is Map
                        ? MessageReply.fromMap(
                            Map<String, dynamic>.from(replyData),
                          )
                        : null;
                    final reactions = Map<String, dynamic>.from(
                      data['reactions'] as Map? ?? const {},
                    );
                    final selected = selectedMessageIds.contains(doc.id);
                    return GestureDetector(
                      onTap: selectedMessageIds.isEmpty
                          ? null
                          : () => _toggleSelection(doc.id),
                      onLongPress: deleted
                          ? null
                          : () => _showActions(doc.id, data, mine),
                      child: Align(
                        alignment:
                            mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.76,
                          ),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: mine
                                ? const Color(0xFFCDBCEB)
                                : const Color(0xFFFFFCF3),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(17),
                              topRight: const Radius.circular(17),
                              bottomLeft: Radius.circular(mine ? 17 : 5),
                              bottomRight: Radius.circular(mine ? 5 : 17),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0D000000),
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              ),
                            ],
                            border: selected
                                ? Border.all(
                                    color: const Color(0xFF7653A5),
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (reply != null)
                                MessageReplyCard(
                                  reply: reply,
                                  onTap: () => _jumpToMessage(
                                    reply.messageId,
                                    docs,
                                  ),
                                ),
                              if (!deleted && data['type'] == 'file')
                                FileMessageBubble(
                                  name: data['fileName'] as String? ?? 'File',
                                  url: data['fileUrl'] as String,
                                  size: data['fileSize'] as int? ?? 0,
                                  mine: mine,
                                )
                              else if (!deleted && data['type'] == 'voice')
                                VoiceMessageBubble(
                                  url: data['audioUrl'] as String,
                                  durationMs: data['durationMs'] as int? ?? 0,
                                  mine: mine,
                                )
                              else if (!deleted && data['type'] == 'image')
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MediaViewerPage(
                                        url: data['imageUrl'] as String,
                                        name: 'VonoTalky_${doc.id}.jpg',
                                      ),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(13),
                                    child: Image.network(
                                      data['imageUrl'] as String,
                                      width: 230,
                                      height: 230,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (_, child, loading) =>
                                          loading == null
                                              ? child
                                              : const Center(
                                                  child: CircularProgressIndicator(
                                                    color: Color(0xFFB49ADF),
                                                  ),
                                                ),
                                      errorBuilder: (_, __, ___) => const SizedBox(
                                        width: 230,
                                        height: 230,
                                        child: Center(
                                          child: Icon(Icons.broken_image_outlined, size: 42),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  deleted
                                      ? 'This message was recalled'
                                      : data['text'] as String? ?? '',
                                  style: TextStyle(
                                    color: const Color(0xFF24202A),
                                    fontStyle: deleted
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                  ),
                                ),
                              const SizedBox(height: 3),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _messageTime(sentAt),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: const Color(0xFF716A78),
                                    ),
                                  ),
                                  if (data['editedAt'] != null) ...[
                                    const SizedBox(width: 4),
                                    const Text(
                                      'edited',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFF716A78),
                                      ),
                                    ),
                                  ],
                                  if (mine) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      read
                                          ? Icons.done_all_rounded
                                          : Icons.done_rounded,
                                      size: 14,
                                      color: read
                                          ? const Color(0xFF7150A1)
                                          : const Color(0xFF8C8296),
                                    ),
                                  ],
                                ],
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
                                    final mine = users.contains(service.myId);
                                    return InkWell(
                                      onTap: () => service.toggleReaction(
                                        widget.user.uid,
                                        doc.id,
                                        entry.key,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: mine
                                              ? const Color(0xFFE2D4F5)
                                              : const Color(0xFFF4EFF8),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Text('${entry.key} ${users.length}'),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
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
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (replyingTo != null)
                    ReplyComposerBar(
                      reply: replyingTo!,
                      onClose: () => setState(() => replyingTo = null),
                    ),
                  if (replyingTo != null) const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: const Color(0xFFE1DCE8)),
                    ),
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
                    visualDensity: VisualDensity.compact,
                    onPressed: _toggleEmojiPicker,
                    icon: const Icon(Icons.sentiment_satisfied_alt_outlined),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: uploading ? null : _showImageSource,
                    icon: uploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.attach_file_rounded),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      onTap: () {
                        if (showEmojiPicker) {
                          setState(() => showEmojiPicker = false);
                        }
                      },
                      maxLines: 4,
                      minLines: 1,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: (_) => send(),
                    ),
                  ),
                  IconButton.filled(
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFB49ADF),
                    ),
                    onPressed: uploading || sending
                        ? null
                        : controller.text.trim().isNotEmpty
                            ? send
                            : _startRecording,
                    icon: Icon(controller.text.trim().isNotEmpty
                        ? Icons.send_rounded
                        : Icons.mic_rounded, size: 19),
                  ),
                ]),
                  ),
                  if (showEmojiPicker)
                    ChatEmojiPicker(onSelected: _insertEmoji),
                ],
                ),
            ),
          ),
        ]),
        ),
        bottomNavigationBar: selectedMessageIds.isEmpty
            ? null
            : _SelectionToolbar(
                count: selectedMessageIds.length,
                onClose: () => setState(selectedMessageIds.clear),
                onSave: _saveSelected,
                onForward: _forwardSelected,
                onDelete: _deleteSelected,
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
  }

  void _openContactDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContactDetailPage(
          user: widget.user,
          onMessage: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Future<void> _openSearch() async {
    final messageId = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => ChatSearchPage(otherId: widget.user.uid),
      ),
    );
    if (messageId != null && mounted) {
      await _jumpToMessage(messageId, latestMessages);
    }
  }

  void _showChatMenu() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.person_rounded),
              title: const Text('Contact info'),
              onTap: () {
                Navigator.pop(sheetContext);
                _openContactDetails();
              },
            ),
            ListTile(
              leading: const Icon(Icons.perm_media_rounded),
              title: const Text('Photos, files and voice'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SharedMediaPage(otherId: widget.user.uid),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_rounded),
              title: const Text('Saved messages'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SavedMessagesPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _notice(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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

  Future<void> _showActions(
    String id,
    Map<String, dynamic> data,
    bool mine,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const ['👍', '❤️', '😂', '😮', '😢', '🙏']
                  .map(
                    (emoji) => InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => Navigator.pop(context, 'react:$emoji'),
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(emoji, style: TextStyle(fontSize: 24)),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.reply_rounded),
            title: const Text('Reply'),
            onTap: () => Navigator.pop(context, 'reply'),
          ),
          if ((data['text'] as String? ?? '').isNotEmpty)
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy'),
              onTap: () => Navigator.pop(context, 'copy'),
            ),
          ListTile(
            leading: const Icon(Icons.bookmark_add_outlined),
            title: const Text('Save message'),
            onTap: () => Navigator.pop(context, 'save'),
          ),
          ListTile(
            leading: const Icon(Icons.forward_rounded),
            title: const Text('Forward'),
            onTap: () => Navigator.pop(context, 'forward'),
          ),
          ListTile(
            leading: const Icon(Icons.check_circle_outline_rounded),
            title: const Text('Select messages'),
            onTap: () => Navigator.pop(context, 'select'),
          ),
          if (mine && (data['text'] as String? ?? '').isNotEmpty)
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Edit message'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded),
            title: const Text('Delete for me'),
            onTap: () => Navigator.pop(context, 'hide'),
          ),
          if (mine)
            ListTile(
              leading: const Icon(Icons.undo_rounded),
              title: const Text('Recall message'),
              onTap: () => Navigator.pop(context, 'recall'),
            ),
        ]),
      ),
    );
    if (!mounted || action == null) return;
    if (action.startsWith('react:')) {
      await service.toggleReaction(widget.user.uid, id, action.substring(6));
    } else if (action == 'reply') {
      setState(() {
        replyingTo = MessageReply.fromMessage(
          messageId: id,
          data: data,
          senderName: mine ? 'You' : widget.user.name,
        );
      });
    } else if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: data['text'] as String));
      _notice('Message copied');
    } else if (action == 'save') {
      await managementService.save(
        conversationId: service.roomId(widget.user.uid),
        messageId: id,
        contactName: widget.user.name,
        message: data,
      );
      _notice('Message saved');
    } else if (action == 'forward') {
      final contactName = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => ForwardMessagePage(messages: [data]),
        ),
      );
      if (contactName != null) _notice('Forwarded to $contactName');
    } else if (action == 'select') {
      _toggleSelection(id);
    } else if (action == 'edit') {
      await _editMessage(id, data['text'] as String? ?? '');
    } else if (action == 'hide') {
      await service.hideForMe(widget.user.uid, [id]);
    } else if (action == 'recall') {
      await service.recall(widget.user.uid, id);
    }
  }

  void _toggleSelection(String messageId) {
    setState(() {
      selectedMessageIds.contains(messageId)
          ? selectedMessageIds.remove(messageId)
          : selectedMessageIds.add(messageId);
    });
  }

  Future<void> _editMessage(String messageId, String original) async {
    final editor = TextEditingController(text: original);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit message'),
        content: TextField(
          controller: editor,
          autofocus: true,
          maxLines: 4,
          maxLength: 2000,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, editor.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    editor.dispose();
    if (value == null || value.isEmpty || value == original) return;
    await service.editMessage(widget.user.uid, messageId, value);
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> get _selectedDocuments =>
      latestMessages
          .where((document) => selectedMessageIds.contains(document.id))
          .toList();

  Future<void> _saveSelected() async {
    final documents = _selectedDocuments;
    await Future.wait(
      documents.map(
        (document) => managementService.save(
          conversationId: service.roomId(widget.user.uid),
          messageId: document.id,
          contactName: widget.user.name,
          message: document.data(),
        ),
      ),
    );
    if (!mounted) return;
    setState(selectedMessageIds.clear);
    _notice('${documents.length} message(s) saved');
  }

  Future<void> _forwardSelected() async {
    final messages = _selectedDocuments.map((document) => document.data()).toList();
    final contactName = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => ForwardMessagePage(messages: messages),
      ),
    );
    if (contactName != null && mounted) {
      setState(selectedMessageIds.clear);
      _notice('Forwarded to $contactName');
    }
  }

  Future<void> _deleteSelected() async {
    final ids = selectedMessageIds.toList();
    await service.hideForMe(widget.user.uid, ids);
    if (mounted) setState(selectedMessageIds.clear);
  }

  void _showImageSource() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Photo library'),
            onTap: () => _pickImage(ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Camera'),
            onTap: () => _pickImage(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.attach_file_rounded),
            title: const Text('File'),
            subtitle: const Text('PDF, Office, text or ZIP · max 25 MB'),
            onTap: _pickFile,
          ),
        ]),
      ),
    );
  }

  String _messageTime(DateTime? value) {
    if (value == null) return '';
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  String _lastSeen(DateTime? value) {
    if (value == null) return 'Offline';
    return 'Last seen ${_messageTime(value)}';
  }
}

class _SelectionToolbar extends StatelessWidget {
  const _SelectionToolbar({
    required this.count,
    required this.onClose,
    required this.onSave,
    required this.onForward,
    required this.onDelete,
  });

  final int count;
  final VoidCallback onClose;
  final VoidCallback onSave;
  final VoidCallback onForward;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE5DFEA))),
          ),
          child: Row(
            children: [
              IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded)),
              Text('$count selected', style: const TextStyle(fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton(
                tooltip: 'Save',
                onPressed: onSave,
                icon: const Icon(Icons.bookmark_add_outlined),
              ),
              IconButton(
                tooltip: 'Forward',
                onPressed: onForward,
                icon: const Icon(Icons.forward_rounded),
              ),
              IconButton(
                tooltip: 'Delete for me',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFB14E68)),
              ),
            ],
          ),
        ),
      );
}
