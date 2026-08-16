import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/chat_user.dart';
import '../../data/models/message_reply.dart';
import '../../data/services/chat_media_service.dart';
import '../../data/services/chat_file_service.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/chat_voice_service.dart';
import '../../data/services/message_management_service.dart';
import '../../data/services/pinned_message_service.dart';
import '../widgets/pinned_message_banner.dart';
import '../widgets/voice_message_bubble.dart';
import '../widgets/file_message_bubble.dart';
import '../widgets/message_reply_widgets.dart';
import '../widgets/recording_composer.dart';
import '../widgets/chat_emoji_picker.dart';
import '../../../contacts/presentation/pages/contact_detail_page.dart';
import '../../../contacts/data/services/contact_detail_service.dart';
import 'advanced_chat_search_page.dart';
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
  final contactDetailService = ContactDetailService();
  final pinnedMessageService = PinnedMessageService();
  List<QueryDocumentSnapshot<Map<String, dynamic>>> latestMessages = const [];
  final Set<String> selectedMessageIds = {};
  bool selectionMode = false;
  final Set<String> knownMessageIds = {};
  bool messageSnapshotInitialized = false;
  Timer? typingTimer;
  Timer? draftTimer;
  Timer? highlightTimer;
  bool sending = false;
  bool uploading = false;
  bool recording = false;
  final voiceWatch = Stopwatch();
  Timer? voiceTimer;
  int voiceSeconds = 0;
  MessageReply? replyingTo;
  String? failedMessageText;
  MessageReply? failedMessageReply;
  bool showEmojiPicker = false;
  bool showJumpToLatest = false;
  int newerMessagesBelow = 0;
  final Set<String> heartAnimations = {};
  String chatBackground = 'blue';
  String? highlightedMessageId;

  @override
  void initState() {
    super.initState();
    service.markRead(widget.user.uid);
    service.ensureConversation(widget.user.uid);
    controller.addListener(_typingChanged);
    messageScrollController.addListener(_handleMessageScroll);
    _restoreDraft();
  }

  Future<void> _restoreDraft() async {
    try {
      final preferences = await contactDetailService
          .preferences(widget.user.uid)
          .first;
      final draft = preferences['draft'] as String? ?? '';
      final savedBackground =
          preferences['chatBackground'] as String? ?? 'blue';
      if (!mounted) return;
      setState(() => chatBackground = savedBackground);
      if (draft.isEmpty || controller.text.isNotEmpty) return;
      controller.value = TextEditingValue(
        text: draft,
        selection: TextSelection.collapsed(offset: draft.length),
      );
    } catch (_) {
      // Draft recovery should never prevent the chat room from opening.
    }
  }

  void _handleMessageScroll() {
    if (!messageScrollController.hasClients) return;
    final shouldShow = messageScrollController.offset > 240;
    if ((shouldShow != showJumpToLatest ||
            (!shouldShow && newerMessagesBelow != 0)) &&
        mounted) {
      setState(() {
        showJumpToLatest = shouldShow;
        if (!shouldShow) newerMessagesBelow = 0;
      });
    }
  }

  Future<void> _jumpToLatest() async {
    if (!messageScrollController.hasClients) return;
    if (newerMessagesBelow != 0 && mounted) {
      setState(() => newerMessagesBelow = 0);
    }
    await messageScrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _jumpToDate() async {
    if (latestMessages.isEmpty) {
      _notice('No messages to jump to');
      return;
    }

    final datedMessages = latestMessages
        .where((message) => message.data()['sentAt'] is Timestamp)
        .toList();
    if (datedMessages.isEmpty) {
      _notice('No dated messages are loaded');
      return;
    }

    final dates = datedMessages
        .map((message) => (message.data()['sentAt'] as Timestamp).toDate())
        .toList()
      ..sort();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: dates.last,
      firstDate: DateTime(dates.first.year, dates.first.month, dates.first.day),
      lastDate: DateTime(dates.last.year, dates.last.month, dates.last.day),
      helpText: 'Jump to date',
    );
    if (selectedDate == null || !mounted) return;

    QueryDocumentSnapshot<Map<String, dynamic>>? closest;
    Duration? closestDistance;
    for (final message in datedMessages) {
      final sentAt = (message.data()['sentAt'] as Timestamp).toDate();
      final messageDay = DateTime(sentAt.year, sentAt.month, sentAt.day);
      final distance = messageDay.difference(selectedDate).abs();
      if (closestDistance == null || distance < closestDistance) {
        closest = message;
        closestDistance = distance;
      }
    }

    if (closest == null) {
      _notice('No message found near that date');
      return;
    }

    await _jumpToMessage(closest.id, latestMessages);
  }

  Future<void> _quickHeart(String messageId) async {
    setState(() => heartAnimations.add(messageId));
    Timer(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => heartAnimations.remove(messageId));
    });
    try {
      await service.toggleReaction(widget.user.uid, messageId, '❤️');
    } catch (_) {
      if (mounted) _notice('Reaction could not be updated');
    }
  }

  void _replyToMessage(String messageId, Map<String, dynamic> data, bool mine) {
    setState(() {
      replyingTo = MessageReply.fromMessage(
        messageId: messageId,
        data: data,
        senderName: mine ? 'You' : widget.user.name,
      );
      showEmojiPicker = false;
    });
  }

  void _typingChanged() {
    if (mounted) setState(() {});
    typingTimer?.cancel();
    draftTimer?.cancel();
    highlightTimer?.cancel();
    draftTimer = Timer(const Duration(milliseconds: 700), () {
      contactDetailService.setDraft(widget.user.uid, controller.text);
    });
    service.setTyping(widget.user.uid, controller.text.trim().isNotEmpty);
    typingTimer = Timer(const Duration(seconds: 2), () {
      service.setTyping(widget.user.uid, false);
    });
  }

  @override
  void dispose() {
    typingTimer?.cancel();
    draftTimer?.cancel();
    contactDetailService.setDraft(widget.user.uid, controller.text);
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
      if (mounted) {
        setState(() {
          failedMessageText = text;
          failedMessageReply = reply;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message could not be sent')),
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> _retryFailedMessage() async {
    final text = failedMessageText;
    if (text == null || sending) return;
    final reply = failedMessageReply;
    setState(() {
      sending = true;
      failedMessageText = null;
      failedMessageReply = null;
    });
    try {
      await service.send(widget.user.uid, text, reply: reply);
    } catch (_) {
      if (mounted) {
        setState(() {
          failedMessageText = text;
          failedMessageReply = reply;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Retry failed. Check your connection.')),
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> _pickImage(
    ImageSource source, {
    bool closeSourceSheet = true,
  }) async {
    if (closeSourceSheet) Navigator.pop(context);
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Image upload failed')));
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

  void _handleBackPressed() {
    if (selectionMode) {
      _exitSelectionMode();
      return;
    }
    if (showEmojiPicker) {
      setState(() => showEmojiPicker = false);
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: 82,
      backgroundColor: const Color(0xFFE9E3FA),
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: _handleBackPressed,
        tooltip: selectionMode
            ? 'Exit selection'
            : showEmojiPicker
                ? 'Close emoji picker'
                : 'Back',
        icon: Icon(
          selectionMode
              ? Icons.close_rounded
              : Icons.arrow_back_rounded,
        ),
      ),
      actions: selectionMode
          ? [
              IconButton(
                onPressed: _selectableMessageIds.isEmpty
                    ? null
                    : () {
                        final allSelected =
                            selectedMessageIds.length ==
                                _selectableMessageIds.length &&
                            selectedMessageIds.containsAll(
                              _selectableMessageIds,
                            );
                        if (allSelected) {
                          setState(selectedMessageIds.clear);
                        } else {
                          _selectAllMessages();
                        }
                      },
                tooltip:
                    _selectableMessageIds.isNotEmpty &&
                        selectedMessageIds.length ==
                            _selectableMessageIds.length &&
                        selectedMessageIds.containsAll(_selectableMessageIds)
                    ? 'Clear selection'
                    : 'Select all messages',
                icon: Icon(
                  _selectableMessageIds.isNotEmpty &&
                          selectedMessageIds.length ==
                              _selectableMessageIds.length &&
                          selectedMessageIds.containsAll(
                            _selectableMessageIds,
                          )
                      ? Icons.deselect_rounded
                      : Icons.select_all_rounded,
                ),
              ),
            ]
          : [
              IconButton(
                onPressed: _openSearch,
                tooltip: 'Search messages',
                icon: const Icon(Icons.search_rounded),
              ),
              IconButton(
                onPressed: _openSharedMedia,
                tooltip: 'Photos, files and voice',
                icon: const Icon(Icons.perm_media_outlined),
              ),
              IconButton(
                onPressed: _showChatMenu,
                tooltip: 'More options',
                icon: const Icon(Icons.more_vert_rounded),
              ),
            ],
      titleSpacing: 0,
      title: selectionMode
          ? Text(
              '${selectedMessageIds.length} selected',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            )
          : InkWell(
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
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
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF605968),
                        ),
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
    body: Stack(
      children: [
        Container(
          color: _chatBackgroundColor,
          child: Column(
            children: [
              PinnedMessageBanner(
                title: 'Pinned Messages',
                preferenceId: widget.user.uid,
                stream: pinnedMessageService.directPreferences(widget.user.uid),
                onTap: (messageId) => _jumpToMessage(messageId, latestMessages),
                onRemove: (messageId) => pinnedMessageService.removeDirect(
                  widget.user.uid,
                  messageId,
                ),
              ),
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
                    final currentMessageIds = docs.map((doc) => doc.id).toSet();
                    final newMessageIds = messageSnapshotInitialized
                        ? currentMessageIds.difference(knownMessageIds)
                        : <String>{};
                    final shouldCountNewMessages =
                        messageSnapshotInitialized && newMessageIds.isNotEmpty;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      knownMessageIds
                        ..clear()
                        ..addAll(currentMessageIds);
                      messageSnapshotInitialized = true;
                      if (shouldCountNewMessages &&
                          mounted &&
                          messageScrollController.hasClients &&
                          messageScrollController.offset > 240) {
                        setState(() {
                          newerMessagesBelow += newMessageIds.length;
                          showJumpToLatest = true;
                        });
                      }
                      service.markRead(widget.user.uid);
                    });
                    if (docs.isEmpty) {
                      return Center(
                        child: Text('Say hello to ${widget.user.name}'),
                      );
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
                        final highlighted = highlightedMessageId == doc.id;
                        final olderSentAt = i == docs.length - 1
                            ? null
                            : (docs[i + 1].data()['sentAt'] as Timestamp?)
                                  ?.toDate();
                        final showDate =
                            i == docs.length - 1 ||
                            !_isSameDay(sentAt, olderSentAt);
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (showDate)
                              _DateDivider(label: _dateLabel(sentAt)),
                            TweenAnimationBuilder<double>(
                              key: ValueKey('entry-${doc.id}'),
                              tween: Tween<double>(
                                begin: newMessageIds.contains(doc.id) ? 0 : 1,
                                end: 1,
                              ),
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeOutCubic,
                              child: Dismissible(
                                key: ValueKey('swipe-${doc.id}'),
                                direction:
                                    deleted || selectionMode
                                    ? DismissDirection.none
                                    : DismissDirection.endToStart,
                                confirmDismiss: (_) async {
                                  _replyToMessage(doc.id, data, mine);
                                  return false;
                                },
                                background: const SizedBox.shrink(),
                                secondaryBackground: const Align(
                                  alignment: Alignment.centerRight,
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: 12,
                                      bottom: 10,
                                    ),
                                    child: CircleAvatar(
                                      radius: 19,
                                      backgroundColor: Color(0xFFE0D3F3),
                                      child: Icon(
                                        Icons.reply_rounded,
                                        color: Color(0xFF7653A5),
                                      ),
                                    ),
                                  ),
                                ),
                                child: GestureDetector(
                                  onTap: !selectionMode
                                      ? null
                                      : () => _toggleSelection(doc.id),
                                  onDoubleTap:
                                      deleted || selectionMode
                                      ? null
                                      : () => _quickHeart(doc.id),
                                  onLongPress: deleted
                                      ? null
                                      : selectionMode
                                          ? () => _toggleSelection(doc.id)
                                          : () => _showActions(doc.id, data, mine),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (selectionMode) ...[
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            right: 10,
                                            bottom: 18,
                                          ),
                                          child: InkWell(
                                            onTap: () => _toggleSelection(doc.id),
                                            customBorder: const CircleBorder(),
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 160,
                                              ),
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: selected
                                                    ? const Color(0xFF7653A5)
                                                    : Colors.transparent,
                                                border: Border.all(
                                                  color: selected
                                                      ? const Color(0xFF7653A5)
                                                      : const Color(0xFF9B93A0),
                                                  width: 2,
                                                ),
                                              ),
                                              child: selected
                                                  ? const Icon(
                                                      Icons.check_rounded,
                                                      size: 17,
                                                      color: Colors.white,
                                                    )
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ],
                                      Expanded(
                                        child: Stack(
                                          children: [
                                            Align(
                                              alignment: mine
                                                  ? Alignment.centerRight
                                                  : Alignment.centerLeft,
                                              child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 240,
                                          ),
                                          curve: Curves.easeOut,
                                          constraints: BoxConstraints(
                                            maxWidth:
                                                MediaQuery.sizeOf(
                                                  context,
                                                ).width *
                                                0.76,
                                          ),
                                          margin: const EdgeInsets.only(
                                            bottom: 10,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 15,
                                            vertical: 9,
                                          ),
                                          decoration: BoxDecoration(
                                            color: mine
                                                ? const Color(0xFFCDBCEB)
                                                : const Color(0xFFFFFCF3),
                                            borderRadius: BorderRadius.only(
                                              topLeft: const Radius.circular(
                                                17,
                                              ),
                                              topRight: const Radius.circular(
                                                17,
                                              ),
                                              bottomLeft: Radius.circular(
                                                mine ? 17 : 5,
                                              ),
                                              bottomRight: Radius.circular(
                                                mine ? 5 : 17,
                                              ),
                                            ),
                                            boxShadow: [
                                              const BoxShadow(
                                                color: Color(0x0D000000),
                                                blurRadius: 5,
                                                offset: Offset(0, 2),
                                              ),
                                              if (highlighted)
                                                const BoxShadow(
                                                  color: Color(0x557653A5),
                                                  blurRadius: 16,
                                                  spreadRadius: 3,
                                                ),
                                            ],
                                            border: selected
                                                ? Border.all(
                                                    color: const Color(
                                                      0xFF7653A5,
                                                    ),
                                                    width: 2,
                                                  )
                                                : highlighted
                                                ? Border.all(
                                                    color: const Color(
                                                      0xFF8D6BB8,
                                                    ),
                                                    width: 2,
                                                  )
                                                : null,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              if (reply != null)
                                                MessageReplyCard(
                                                  reply: reply,
                                                  onTap: () => _jumpToMessage(
                                                    reply.messageId,
                                                    docs,
                                                  ),
                                                ),
                                              if (!deleted &&
                                                  data['type'] == 'file')
                                                FileMessageBubble(
                                                  name:
                                                      data['fileName']
                                                          as String? ??
                                                      'File',
                                                  url:
                                                      data['fileUrl'] as String,
                                                  size:
                                                      data['fileSize']
                                                          as int? ??
                                                      0,
                                                  mine: mine,
                                                )
                                              else if (!deleted &&
                                                  data['type'] == 'voice')
                                                VoiceMessageBubble(
                                                  url:
                                                      data['audioUrl']
                                                          as String,
                                                  durationMs:
                                                      data['durationMs']
                                                          as int? ??
                                                      0,
                                                  mine: mine,
                                                )
                                              else if (!deleted &&
                                                  data['type'] == 'image')
                                                GestureDetector(
                                                  onTap: () => Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          MediaViewerPage(
                                                            url:
                                                                data['imageUrl']
                                                                    as String,
                                                            name:
                                                                'VonoTalky_${doc.id}.jpg',
                                                          ),
                                                    ),
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          13,
                                                        ),
                                                    child: Image.network(
                                                      data['imageUrl']
                                                          as String,
                                                      width: 230,
                                                      height: 230,
                                                      fit: BoxFit.cover,
                                                      loadingBuilder:
                                                          (
                                                            _,
                                                            child,
                                                            loading,
                                                          ) => loading == null
                                                          ? child
                                                          : const Center(
                                                              child:
                                                                  CircularProgressIndicator(
                                                                    color: Color(
                                                                      0xFFB49ADF,
                                                                    ),
                                                                  ),
                                                            ),
                                                      errorBuilder: (_, _, _) =>
                                                          const SizedBox(
                                                            width: 230,
                                                            height: 230,
                                                            child: Center(
                                                              child: Icon(
                                                                Icons
                                                                    .broken_image_outlined,
                                                                size: 42,
                                                              ),
                                                            ),
                                                          ),
                                                    ),
                                                  ),
                                                )
                                              else
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      deleted
                                                          ? 'This message was recalled'
                                                          : data['text']
                                                                    as String? ??
                                                                '',
                                                      style: TextStyle(
                                                        color: const Color(
                                                          0xFF24202A,
                                                        ),
                                                        fontStyle: deleted
                                                            ? FontStyle.italic
                                                            : FontStyle.normal,
                                                      ),
                                                    ),
                                                    if (!deleted &&
                                                        _firstUrl(
                                                              data['text']
                                                                      as String? ??
                                                                  '',
                                                            ) !=
                                                            null) ...[
                                                      const SizedBox(height: 8),
                                                      _LinkPreviewButton(
                                                        url: _firstUrl(
                                                          data['text']
                                                                  as String? ??
                                                              '',
                                                        )!,
                                                        onTap: _openLink,
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              const SizedBox(height: 3),
                                              Tooltip(
                                                message: 'Message details',
                                                child: InkWell(
                                                  onTap: () =>
                                                      _showMessageDetails(
                                                        data,
                                                        mine,
                                                      ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 3,
                                                          vertical: 2,
                                                        ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          sentAt == null
                                                              ? 'Sending…'
                                                              : _messageTime(
                                                                  sentAt,
                                                                ),
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 10,
                                                                color: Color(
                                                                  0xFF716A78,
                                                                ),
                                                              ),
                                                        ),
                                                        if (data['editedAt'] !=
                                                            null) ...[
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          const Text(
                                                            'edited',
                                                            style: TextStyle(
                                                              fontSize: 9,
                                                              color: Color(
                                                                0xFF716A78,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                        if (mine) ...[
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Icon(
                                                            sentAt == null
                                                                ? Icons
                                                                      .schedule_rounded
                                                                : read
                                                                ? Icons
                                                                      .done_all_rounded
                                                                : Icons
                                                                      .done_rounded,
                                                            size: 14,
                                                            color:
                                                                sentAt == null
                                                                ? const Color(
                                                                    0xFF8C8296,
                                                                  )
                                                                : read
                                                                ? const Color(
                                                                    0xFF7150A1,
                                                                  )
                                                                : const Color(
                                                                    0xFF8C8296,
                                                                  ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              if (reactions.isNotEmpty) ...[
                                                const SizedBox(height: 5),
                                                Wrap(
                                                  spacing: 5,
                                                  runSpacing: 4,
                                                  children: reactions.entries.map((
                                                    entry,
                                                  ) {
                                                    final users =
                                                        List<String>.from(
                                                          entry.value
                                                                  as List? ??
                                                              const [],
                                                        );
                                                    final mine = users.contains(
                                                      service.myId,
                                                    );
                                                    return InkWell(
                                                      onTap: () => service
                                                          .toggleReaction(
                                                            widget.user.uid,
                                                            doc.id,
                                                            entry.key,
                                                          ),
                                                      onLongPress: () =>
                                                          _showReactionDetails(
                                                            entry.key,
                                                            users,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            14,
                                                          ),
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 7,
                                                              vertical: 3,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: mine
                                                              ? const Color(
                                                                  0xFFE2D4F5,
                                                                )
                                                              : const Color(
                                                                  0xFFF4EFF8,
                                                                ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                14,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          '${entry.key} ${users.length}',
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (heartAnimations.contains(doc.id))
                                        Positioned.fill(
                                          child: IgnorePointer(
                                            child: Center(
                                              child:
                                                  TweenAnimationBuilder<double>(
                                                    key: ValueKey(
                                                      'heart-${doc.id}',
                                                    ),
                                                    tween: Tween(
                                                      begin: 0.35,
                                                      end: 1.25,
                                                    ),
                                                    duration: const Duration(
                                                      milliseconds: 430,
                                                    ),
                                                    curve: Curves.elasticOut,
                                                    builder:
                                                        (_, scale, child) =>
                                                            Transform.scale(
                                                              scale: scale,
                                                              child: child,
                                                            ),
                                                    child: const Text(
                                                      '❤️',
                                                      style: TextStyle(
                                                        fontSize: 42,
                                                        shadows: [
                                                          Shadow(
                                                            color: Color(
                                                              0x33000000,
                                                            ),
                                                            blurRadius: 8,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                            ),
                                          ),
                                        ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              builder: (_, value, child) => Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - value) * 14),
                                  child: child,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              if (!selectionMode)
                SafeArea(
                  top: false,
                  child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (failedMessageText != null) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE9EB),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFF3BBC0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 19,
                                color: Color(0xFFC24E58),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  failedMessageText!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF74363C),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: sending ? null : _retryFailedMessage,
                                tooltip: 'Retry message',
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  color: Color(0xFFC24E58),
                                ),
                              ),
                              IconButton(
                                onPressed: () => setState(() {
                                  failedMessageText = null;
                                  failedMessageReply = null;
                                }),
                                tooltip: 'Dismiss failed message',
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: Color(0xFF8D6266),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (replyingTo != null)
                        ReplyComposerBar(
                          reply: replyingTo!,
                          onClose: () => setState(() => replyingTo = null),
                        ),
                      if (replyingTo != null) const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: const Color(0xFFE1DCE8)),
                        ),
                        child: recording
                            ? RecordingComposer(
                                seconds: voiceSeconds,
                                uploading: uploading,
                                onCancel: _cancelRecording,
                                onSend: _sendRecording,
                              )
                            : Row(
                                children: [
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: _toggleEmojiPicker,
                                    tooltip: showEmojiPicker
                                        ? 'Close emoji picker'
                                        : 'Open emoji picker',
                                    style: IconButton.styleFrom(
                                      backgroundColor: showEmojiPicker
                                          ? const Color(0xFFE8DDF6)
                                          : Colors.transparent,
                                      foregroundColor: showEmojiPicker
                                          ? const Color(0xFF7653A5)
                                          : const Color(0xFF625B68),
                                    ),
                                    icon: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 160,
                                      ),
                                      child: Icon(
                                        showEmojiPicker
                                            ? Icons
                                                  .sentiment_satisfied_alt_rounded
                                            : Icons
                                                  .sentiment_satisfied_alt_outlined,
                                        key: ValueKey(showEmojiPicker),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: uploading
                                        ? null
                                        : _showImageSource,
                                    tooltip: 'Attach',
                                    icon: uploading
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.attach_file_rounded),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: uploading
                                        ? null
                                        : () => _pickImage(
                                            ImageSource.camera,
                                            closeSourceSheet: false,
                                          ),
                                    tooltip: 'Camera',
                                    icon: const Icon(
                                      Icons.photo_camera_outlined,
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: controller,
                                      onTap: () {
                                        if (showEmojiPicker) {
                                          setState(
                                            () => showEmojiPicker = false,
                                          );
                                        }
                                      },
                                      maxLines: 4,
                                      minLines: 1,
                                      maxLength: 2000,
                                      buildCounter:
                                          (
                                            context, {
                                            required currentLength,
                                            required isFocused,
                                            required maxLength,
                                          }) {
                                            if (currentLength < 1800) {
                                              return const SizedBox.shrink();
                                            }
                                            final nearlyFull =
                                                currentLength >= 1950;
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                right: 4,
                                                top: 2,
                                              ),
                                              child: Text(
                                                '${2000 - currentLength} characters left',
                                                style: TextStyle(
                                                  color: nearlyFull
                                                      ? const Color(0xFFC24E58)
                                                      : const Color(0xFF8B7B98),
                                                  fontSize: 10,
                                                  fontWeight: nearlyFull
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                ),
                                              ),
                                            );
                                          },
                                      decoration: InputDecoration(
                                        hintText: 'Type a message...',
                                        border: InputBorder.none,
                                        isDense: true,
                                        suffixIcon: controller.text.isEmpty
                                            ? null
                                            : IconButton(
                                                onPressed: controller.clear,
                                                tooltip: 'Clear message',
                                                visualDensity:
                                                    VisualDensity.compact,
                                                icon: const Icon(
                                                  Icons.cancel_rounded,
                                                  size: 18,
                                                  color: Color(0xFF9A92A3),
                                                ),
                                              ),
                                        suffixIconConstraints:
                                            const BoxConstraints(
                                              minWidth: 34,
                                              minHeight: 34,
                                            ),
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
                                    tooltip: sending
                                        ? 'Sending message'
                                        : controller.text.trim().isNotEmpty
                                        ? 'Send message'
                                        : 'Record voice message',
                                    icon: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      transitionBuilder: (child, animation) =>
                                          ScaleTransition(
                                            scale: animation,
                                            child: child,
                                          ),
                                      child: sending
                                          ? const SizedBox(
                                              key: ValueKey('sending'),
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Icon(
                                              controller.text.trim().isNotEmpty
                                                  ? Icons.send_rounded
                                                  : Icons.mic_rounded,
                                              key: ValueKey(
                                                controller.text
                                                        .trim()
                                                        .isNotEmpty
                                                    ? 'send'
                                                    : 'voice',
                                              ),
                                              size: 19,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      if (showEmojiPicker)
                        ChatEmojiPicker(onSelected: _insertEmoji),
                    ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          right: 18,
          bottom: 92,
          child: AnimatedScale(
            scale: showJumpToLatest ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            child: Material(
              color: Colors.white,
              elevation: 4,
              shadowColor: const Color(0x33000000),
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                onTap: _jumpToLatest,
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF7653A5),
                      ),
                      if (newerMessagesBelow > 0) ...[
                        const SizedBox(width: 2),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: Text(
                            newerMessagesBelow > 99
                                ? '99+'
                                : '$newerMessagesBelow',
                            key: ValueKey(newerMessagesBelow),
                            style: const TextStyle(
                              color: Color(0xFF7653A5),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
    bottomNavigationBar: !selectionMode
        ? null
        : _SelectionToolbar(
            count: selectedMessageIds.length,
            hasSelection: selectedMessageIds.isNotEmpty,
            hasTextSelection: _selectedDocuments.any(
              (document) =>
                  (document.data()['text'] as String? ?? '').trim().isNotEmpty,
            ),
            onClose: _exitSelectionMode,
            onSelectAll: _selectAllMessages,
            onReply: _replyToSelected,
            onCopy: _copySelected,
            onCopyWithTime: _copySelectedWithTime,
            onSave: _saveSelected,
            onPin: _pinSelected,
            onForward: _forwardSelected,
            onDelete: _showSelectedDeleteOptions,
          ),
  );

  void _toggleEmojiPicker() {
    if (!showEmojiPicker) FocusScope.of(context).unfocus();
    setState(() => showEmojiPicker = !showEmojiPicker);
  }

  void _insertEmoji(String emoji) {
    final value = controller.value;
    final start = value.selection.isValid
        ? value.selection.start
        : value.text.length;
    final end = value.selection.isValid
        ? value.selection.end
        : value.text.length;
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
        builder: (_) => AdvancedChatSearchPage(otherId: widget.user.uid),
      ),
    );
    if (messageId != null && mounted) {
      await _jumpToMessage(messageId, latestMessages);
    }
  }

  void _showChatMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => StreamBuilder<Map<String, dynamic>>(
        stream: contactDetailService.preferences(widget.user.uid),
        builder: (_, snapshot) {
          final muted = snapshot.data?['muted'] as bool? ?? false;
          final pinned = snapshot.data?['pinned'] as bool? ?? false;
          return SafeArea(
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
                    _openSharedMedia();
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
                SwitchListTile(
                  secondary: Icon(
                    pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                  ),
                  title: const Text('Pin conversation'),
                  subtitle: Text(pinned ? 'Pinned to the top' : 'Not pinned'),
                  value: pinned,
                  activeTrackColor: const Color(0xFFB593E4),
                  onChanged: (value) => contactDetailService.setPreference(
                    widget.user.uid,
                    'pinned',
                    value,
                  ),
                ),
                SwitchListTile(
                  secondary: Icon(
                    muted
                        ? Icons.notifications_off_rounded
                        : Icons.notifications_none_rounded,
                  ),
                  title: const Text('Mute notifications'),
                  subtitle: Text(muted ? 'Muted' : 'Notifications are on'),
                  value: muted,
                  activeTrackColor: const Color(0xFFB593E4),
                  onChanged: (value) => contactDetailService.setPreference(
                    widget.user.uid,
                    'muted',
                    value,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.mark_chat_unread_outlined),
                  title: const Text('Mark as unread'),
                  subtitle: const Text('Show this chat in the unread list'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _markConversationUnread();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.first_page_rounded),
                  title: const Text('Jump to first message'),
                  subtitle: const Text('Go to the oldest loaded message'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    if (!messageScrollController.hasClients) return;
                    messageScrollController.animateTo(
                      messageScrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_month_outlined),
                  title: const Text('Jump to date'),
                  subtitle: const Text('Find a message around a loaded date'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _jumpToDate();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Chat background'),
                  subtitle: const Text('Choose a color for this conversation'),
                  trailing: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _chatBackgroundColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD5CFDA)),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showBackgroundPicker();
                  },
                ),
                const Divider(height: 8),
                ListTile(
                  leading: const Icon(
                    Icons.delete_sweep_outlined,
                    color: Color(0xFFB14E68),
                  ),
                  title: const Text(
                    'Clear chat history',
                    style: TextStyle(color: Color(0xFFB14E68)),
                  ),
                  subtitle: const Text('Only clears messages for you'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _clearChatHistory();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color get _chatBackgroundColor => switch (chatBackground) {
    'lavender' => const Color(0xFFF0EAF8),
    'pink' => const Color(0xFFF9EAF0),
    'cream' => const Color(0xFFFFF7E8),
    _ => const Color(0xFFEDF2F8),
  };

  void _showBackgroundPicker() {
    const choices = <(String, String, Color)>[
      ('blue', 'Soft blue', Color(0xFFEDF2F8)),
      ('lavender', 'Lavender', Color(0xFFF0EAF8)),
      ('pink', 'Blush pink', Color(0xFFF9EAF0)),
      ('cream', 'Warm cream', Color(0xFFFFF7E8)),
    ];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chat background',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: choices
                    .map(
                      (choice) => _BackgroundChoice(
                        label: choice.$2,
                        color: choice.$3,
                        selected: chatBackground == choice.$1,
                        onTap: () async {
                          setState(() => chatBackground = choice.$1);
                          Navigator.pop(sheetContext);
                          await contactDetailService.setChatBackground(
                            widget.user.uid,
                            choice.$1,
                          );
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markConversationUnread() async {
    try {
      await service.markUnread(widget.user.uid);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) _notice('Conversation could not be marked as unread');
    }
  }

  Future<void> _clearChatHistory() async {
    final confirmed = await _confirmMessageAction(
      title: 'Clear chat history?',
      message: 'All messages will disappear from this chat only for you.',
      confirmLabel: 'Clear',
    );
    if (!confirmed) return;
    try {
      await service.clearForMe(widget.user.uid);
      if (mounted) _notice('Chat history cleared');
    } catch (_) {
      if (mounted) _notice('Chat history could not be cleared');
    }
  }

  void _openSharedMedia() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SharedMediaPage(otherId: widget.user.uid),
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
    final target = (index * 82.0)
        .clamp(0.0, messageScrollController.position.maxScrollExtent)
        .toDouble();
    highlightTimer?.cancel();
    setState(() => highlightedMessageId = messageId);
    highlightTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted && highlightedMessageId == messageId) {
        setState(() => highlightedMessageId = null);
      }
    });
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
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const ['👍', '❤️', '😂', '😮', '😢', '🙏']
                      .map(
                        (emoji) => InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () =>
                              Navigator.pop(sheetContext, 'react:$emoji'),
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(emoji, style: TextStyle(fontSize: 24)),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _MessageActionButton(
                      icon: Icons.reply_rounded,
                      label: 'Reply',
                      onTap: () => Navigator.pop(sheetContext, 'reply'),
                    ),
                    if ((data['text'] as String? ?? '').isNotEmpty)
                      _MessageActionButton(
                        icon: Icons.copy_rounded,
                        label: 'Copy',
                        onTap: () => Navigator.pop(sheetContext, 'copy'),
                      ),
                    _MessageActionButton(
                      icon: Icons.bookmark_add_outlined,
                      label: 'Save',
                      onTap: () => Navigator.pop(sheetContext, 'save'),
                    ),
                    _MessageActionButton(
                      icon: Icons.forward_rounded,
                      label: 'Forward',
                      onTap: () => Navigator.pop(sheetContext, 'forward'),
                    ),
                  ],
                ),
                const Divider(height: 22),
                ListTile(
                  leading: const Icon(Icons.push_pin_outlined),
                  title: const Text('Pin message'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pop(sheetContext, 'pin'),
                ),
                ListTile(
                  leading: const Icon(Icons.check_circle_outline_rounded),
                  title: const Text('Select messages'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pop(sheetContext, 'select'),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('Message details'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pop(sheetContext, 'details'),
                ),
                if (mine && (data['text'] as String? ?? '').isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.edit_rounded),
                    title: const Text('Edit message'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.pop(sheetContext, 'edit'),
                  ),
                const Divider(height: 12),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFB14E68),
                  ),
                  title: const Text(
                    'Delete',
                    style: TextStyle(color: Color(0xFFB14E68)),
                  ),
                  subtitle: const Text('Choose how to remove this message'),
                  onTap: () => Navigator.pop(sheetContext, 'delete'),
                ),
              ],
            ),
          ),
        ),
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
        MaterialPageRoute(builder: (_) => ForwardMessagePage(messages: [data])),
      );
      if (contactName != null) _notice('Forwarded to $contactName');
    } else if (action == 'pin') {
      try {
        await pinnedMessageService.pinDirect(
          otherId: widget.user.uid,
          messageId: id,
          data: data,
          senderName: mine ? 'You' : widget.user.name,
        );
        _notice('Message pinned');
      } catch (error) {
        _notice('Pin failed: $error');
      }
    } else if (action == 'select') {
      _toggleSelection(id);
    } else if (action == 'details') {
      _showMessageDetails(data, mine);
    } else if (action == 'edit') {
      await _editMessage(id, data['text'] as String? ?? '');
    } else if (action == 'delete') {
      final deleteAction = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (deleteContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFB14E68),
                  ),
                  title: const Text('Delete for me'),
                  subtitle: const Text('Remove this message only from your chat'),
                  onTap: () => Navigator.pop(deleteContext, 'hide'),
                ),
                if (mine)
                  ListTile(
                    leading: const Icon(
                      Icons.undo_rounded,
                      color: Color(0xFFB14E68),
                    ),
                    title: const Text('Recall for everyone'),
                    subtitle: const Text('Remove this message for everyone'),
                    onTap: () => Navigator.pop(deleteContext, 'recall'),
                  ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.close_rounded),
                  title: const Text('Cancel'),
                  onTap: () => Navigator.pop(deleteContext),
                ),
              ],
            ),
          ),
        ),
      );

      if (!mounted || deleteAction == null) return;

      if (deleteAction == 'hide') {
        final confirmed = await _confirmMessageAction(
          title: 'Delete this message?',
          message: 'It will only be removed from your chat.',
          confirmLabel: 'Delete',
        );
        if (confirmed) await service.hideForMe(widget.user.uid, [id]);
      } else if (deleteAction == 'recall') {
        final confirmed = await _confirmMessageAction(
          title: 'Recall this message?',
          message: 'The message will be replaced for everyone in this chat.',
          confirmLabel: 'Recall',
        );
        if (confirmed) await service.recall(widget.user.uid, id);
      }
    }
  }

  Future<bool> _confirmMessageAction({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB14E68),
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showReactionDetails(String emoji, List<String> userIds) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Text(
                    '${userIds.length} reaction${userIds.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...userIds.map((userId) {
                final isMe = userId == service.myId;
                final isContact = userId == widget.user.uid;
                final name = isMe
                    ? 'You'
                    : isContact
                    ? widget.user.name
                    : 'User';
                final photoUrl = isContact ? widget.user.photoUrl : null;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFEDE5F8),
                    backgroundImage: photoUrl == null
                        ? null
                        : NetworkImage(photoUrl),
                    child: photoUrl == null
                        ? Text(name.substring(0, 1).toUpperCase())
                        : null,
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: Text(emoji, style: const TextStyle(fontSize: 21)),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageDetails(Map<String, dynamic> data, bool mine) {
    final sentAt = (data['sentAt'] as Timestamp?)?.toDate();
    final readAt = (data['readAt'] as Timestamp?)?.toDate();
    final editedAt = (data['editedAt'] as Timestamp?)?.toDate();
    final type = data['type'] as String? ?? 'text';
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Message details',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              _MessageDetailRow(
                icon: Icons.person_outline_rounded,
                label: 'From',
                value: mine ? 'You' : widget.user.name,
              ),
              _MessageDetailRow(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Type',
                value: type[0].toUpperCase() + type.substring(1),
              ),
              _MessageDetailRow(
                icon: Icons.schedule_rounded,
                label: 'Sent',
                value: _fullDateTime(sentAt),
              ),
              if (mine)
                _MessageDetailRow(
                  icon: readAt == null
                      ? Icons.done_rounded
                      : Icons.done_all_rounded,
                  label: readAt == null ? 'Status' : 'Read',
                  value: readAt == null ? 'Delivered' : _fullDateTime(readAt),
                ),
              if (editedAt != null)
                _MessageDetailRow(
                  icon: Icons.edit_outlined,
                  label: 'Edited',
                  value: _fullDateTime(editedAt),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleSelection(String messageId) {
    setState(() {
      selectionMode = true;
      selectedMessageIds.contains(messageId)
          ? selectedMessageIds.remove(messageId)
          : selectedMessageIds.add(messageId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      selectionMode = false;
      selectedMessageIds.clear();
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
    if (documents.isEmpty) return;

    var savedCount = 0;
    for (final document in documents) {
      try {
        await managementService.save(
          conversationId: service.roomId(widget.user.uid),
          messageId: document.id,
          contactName: widget.user.name,
          message: document.data(),
        );
        savedCount++;
      } catch (_) {
        // Continue saving the remaining selected messages.
      }
    }

    if (!mounted) return;
    _exitSelectionMode();
    if (savedCount == documents.length) {
      _notice('$savedCount message(s) saved');
    } else if (savedCount > 0) {
      _notice('$savedCount of ${documents.length} messages saved');
    } else {
      _notice('Selected messages could not be saved');
    }
  }

  Future<void> _pinSelected() async {
    final selectedDocuments = _selectedDocuments;
    final documents = selectedDocuments
        .where((document) => !(document.data()['isDeleted'] as bool? ?? false))
        .toList();

    if (documents.isEmpty) {
      _notice('No pinnable messages selected');
      return;
    }

    final skippedCount = selectedDocuments.length - documents.length;
    var pinnedCount = 0;
    for (final document in documents) {
      final data = document.data();
      final mine = data['senderId'] == service.myId;
      try {
        await pinnedMessageService.pinDirect(
          otherId: widget.user.uid,
          messageId: document.id,
          data: data,
          senderName: mine ? 'You' : widget.user.name,
        );
        pinnedCount++;
      } catch (_) {
        // Continue pinning the remaining selected messages.
      }
    }

    if (!mounted) return;
    _exitSelectionMode();

    if (pinnedCount == documents.length) {
      if (skippedCount > 0) {
        _notice(
          '$pinnedCount message(s) pinned; '
          '$skippedCount recalled message(s) skipped',
        );
      } else {
        _notice('$pinnedCount message(s) pinned');
      }
    } else if (pinnedCount > 0) {
      _notice(
        '$pinnedCount of ${documents.length} pinnable messages pinned'
        '${skippedCount > 0 ? '; $skippedCount recalled skipped' : ''}',
      );
    } else {
      _notice('Selected messages could not be pinned');
    }
  }

  Future<void> _forwardSelected() async {
    final documents = _selectedDocuments
        .where((document) => !(document.data()['isDeleted'] as bool? ?? false))
        .toList();

    if (documents.isEmpty) {
      _notice('No forwardable messages selected');
      return;
    }

    final messages = documents.map((document) => document.data()).toList();
    final skippedCount = selectedMessageIds.length - documents.length;

    final contactName = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => ForwardMessagePage(messages: messages)),
    );
    if (contactName != null && mounted) {
      _exitSelectionMode();
      if (skippedCount > 0) {
        _notice(
          'Forwarded ${documents.length} message(s) to $contactName; '
          '$skippedCount recalled message(s) skipped',
        );
      } else {
        _notice('Forwarded to $contactName');
      }
    }
  }

  Set<String> get _selectableMessageIds => latestMessages
      .where((document) => !(document.data()['isDeleted'] as bool? ?? false))
      .map((document) => document.id)
      .toSet();

  void _selectAllMessages() {
    final selectableIds = _selectableMessageIds;
    setState(() {
      if (selectedMessageIds.length == selectableIds.length &&
          selectedMessageIds.containsAll(selectableIds)) {
        selectedMessageIds.clear();
      } else {
        selectedMessageIds
          ..clear()
          ..addAll(selectableIds);
      }
    });
  }

  void _replyToSelected() {
    if (selectedMessageIds.length != 1) return;
    final document = _selectedDocuments.single;
    final data = document.data();
    final mine = data['senderId'] == service.myId;
    setState(() {
      selectionMode = false;
      selectedMessageIds.clear();
      replyingTo = MessageReply.fromMessage(
        messageId: document.id,
        data: data,
        senderName: mine ? 'You' : widget.user.name,
      );
      showEmojiPicker = false;
    });
  }

  Future<void> _copySelected() async {
    final text = _selectedDocuments.reversed
        .map((document) => document.data()['text'] as String? ?? '')
        .where((value) => value.trim().isNotEmpty)
        .join('\n');
    if (text.isEmpty) {
      _notice('Selected messages contain no text');
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    _exitSelectionMode();
    _notice('Selected messages copied');
  }

  Future<void> _copySelectedWithTime() async {
    final lines = <String>[];
    for (final document in _selectedDocuments.reversed) {
      final data = document.data();
      final text = (data['text'] as String? ?? '').trim();
      if (text.isEmpty) continue;

      final mine = data['senderId'] == service.myId;
      final sender = mine ? 'You' : widget.user.name;
      final sentAt = (data['sentAt'] as Timestamp?)?.toDate();
      final time = sentAt == null
          ? 'Sending'
          : '${sentAt.year.toString().padLeft(4, '0')}-'
                '${sentAt.month.toString().padLeft(2, '0')}-'
                '${sentAt.day.toString().padLeft(2, '0')} '
                '${sentAt.hour.toString().padLeft(2, '0')}:'
                '${sentAt.minute.toString().padLeft(2, '0')}';
      lines.add('[$time] $sender: $text');
    }

    if (lines.isEmpty) {
      _notice('Selected messages contain no text');
      return;
    }

    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (!mounted) return;
    _exitSelectionMode();
    _notice('Messages copied with time');
  }

  Future<void> _recallSelected() async {
    final selectedDocuments = _selectedDocuments;
    final documents = selectedDocuments
        .where((document) => document.data()['senderId'] == service.myId)
        .toList();
    if (documents.isEmpty ||
        documents.any((document) => document.data()['senderId'] != service.myId)) {
      _notice('Only your own messages can be recalled');
      return;
    }

    final confirmed = await _confirmMessageAction(
      title:
          'Recall ${documents.length} message${documents.length == 1 ? '' : 's'}?',
      message: 'The selected messages will be replaced for everyone in this chat.',
      confirmLabel: 'Recall',
    );
    if (!confirmed) return;

    var recalledCount = 0;
    for (final document in documents) {
      try {
        await service.recall(widget.user.uid, document.id);
        recalledCount++;
      } catch (_) {
        // Continue recalling the remaining selected messages.
      }
    }

    if (!mounted) return;
    _exitSelectionMode();
    if (recalledCount == documents.length) {
      _notice('$recalledCount message(s) recalled');
    } else if (recalledCount > 0) {
      _notice('$recalledCount of ${documents.length} messages recalled');
    } else {
      _notice('Selected messages could not be recalled');
    }
  }

  Future<void> _showSelectedDeleteOptions() async {
    final documents = _selectedDocuments;
    if (documents.isEmpty) return;

    final recallableCount = documents
        .where((document) => document.data()['senderId'] == service.myId)
        .length;
    final canRecall = recallableCount > 0;

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 2, 8, 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_sweep_outlined,
                      color: Color(0xFFB14E68),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Delete ${documents.length} selected message${documents.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFB14E68),
                ),
                title: const Text('Delete for me'),
                subtitle: const Text('Remove selected messages only for you'),
                onTap: () => Navigator.pop(sheetContext, 'deleteForMe'),
              ),
              const Divider(height: 1),
              ListTile(
                enabled: canRecall,
                leading: Icon(
                  Icons.undo_rounded,
                  color: canRecall
                      ? const Color(0xFFB14E68)
                      : const Color(0xFFB8B1BC),
                ),
                title: const Text('Recall for everyone'),
                subtitle: Text(
                  canRecall
                      ? recallableCount == documents.length
                          ? 'Remove selected messages for everyone'
                          : 'Recall $recallableCount of ${documents.length} selected messages you sent'
                      : 'None of the selected messages were sent by you',
                ),
                onTap: canRecall
                    ? () => Navigator.pop(sheetContext, 'recall')
                    : null,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.close_rounded),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted || action == null) return;
    if (action == 'deleteForMe') {
      await _deleteSelected();
    } else if (action == 'recall') {
      await _recallSelected();
    }
  }

  Future<void> _deleteSelected() async {
    final ids = selectedMessageIds.toList();
    final confirmed = await _confirmMessageAction(
      title: 'Delete ${ids.length} message${ids.length == 1 ? '' : 's'}?',
      message: 'The selected messages will only be removed for you.',
      confirmLabel: 'Delete',
    );
    if (!confirmed) return;
    await service.hideForMe(widget.user.uid, ids);
    if (mounted) _exitSelectionMode();
  }

  void _showImageSource() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Share',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _AttachmentAction(
                    icon: Icons.photo_library_outlined,
                    label: 'Gallery',
                    color: const Color(0xFF9B7BD3),
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                  _AttachmentAction(
                    icon: Icons.camera_alt_outlined,
                    label: 'Camera',
                    color: const Color(0xFFE978A6),
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                  _AttachmentAction(
                    icon: Icons.insert_drive_file_outlined,
                    label: 'File',
                    color: const Color(0xFF62A8D8),
                    onTap: _pickFile,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Center(
                child: Text(
                  'Files up to 25 MB',
                  style: TextStyle(fontSize: 11, color: Color(0xFF8B8492)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _messageTime(DateTime? value) {
    if (value == null) return '';
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  String? _firstUrl(String text) {
    final match = RegExp(
      r'https?://[^\s<>()]+',
      caseSensitive: false,
    ).firstMatch(text);
    return match?.group(0)?.replaceFirst(RegExp(r'[.,!?;:]+$'), '');
  }

  Future<void> _openLink(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || !await launchUrl(uri)) {
      if (mounted) _notice('Link could not be opened');
    }
  }

  String _lastSeen(DateTime? value) {
    if (value == null) return 'Offline';
    return 'Last seen ${_messageTime(value)}';
  }

  String _fullDateTime(DateTime? value) {
    if (value == null) return 'Pending';
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year}  $hour:$minute';
  }

  bool _isSameDay(DateTime? first, DateTime? second) {
    if (first == null || second == null) return false;
    final a = first.toLocal();
    final b = second.toLocal();
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _dateLabel(DateTime? value) {
    if (value == null) return 'Sending…';
    final date = value.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(date.year, date.month, date.day);
    final difference = today.difference(messageDay).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

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

class _BackgroundChoice extends StatelessWidget {
  const _BackgroundChoice({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? const Color(0xFF7653A5)
                    : const Color(0xFFD7D1DC),
                width: selected ? 3 : 1,
              ),
            ),
            child: selected
                ? const Icon(Icons.check_rounded, color: Color(0xFF7653A5))
                : null,
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
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

class _AttachmentAction extends StatelessWidget {
  const _AttachmentAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 27),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
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
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
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
