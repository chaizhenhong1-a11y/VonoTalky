import 'package:flutter/material.dart';

import '../../data/services/chat_background_service.dart';

class ChatBackgroundPage extends StatefulWidget {
  const ChatBackgroundPage({
    super.key,
    required this.otherId,
    required this.otherName,
  });

  final String otherId;
  final String otherName;

  @override
  State<ChatBackgroundPage> createState() =>
      _ChatBackgroundPageState();
}

class _ChatBackgroundPageState
    extends State<ChatBackgroundPage> {
  final ChatBackgroundService _service =
      ChatBackgroundService();

  bool uploading = false;
  bool removing = false;
  bool changingShare = false;

  Future<void> _chooseBackground() async {
    if (uploading) return;

    setState(() {
      uploading = true;
    });

    try {
      await _service.pickAndUpload(
        widget.otherId,
      );

      if (!mounted) return;

      _notice(
        'Background updated for this chat',
      );
    } on ChatBackgroundException catch (error) {
      if (!mounted) return;

      _notice(
        error.message,
      );
    } catch (_) {
      if (!mounted) return;

      _notice(
        'Background could not be uploaded',
      );
    } finally {
      if (mounted) {
        setState(() {
          uploading = false;
        });
      }
    }
  }

  Future<void> _setShared(
    bool value,
  ) async {
    if (changingShare) return;

    setState(() {
      changingShare = true;
    });

    try {
      await _service.setShared(
        otherId: widget.otherId,
        shared: value,
      );

      if (!mounted) return;

      _notice(
        value
            ? '${widget.otherName} can now view this background'
            : '${widget.otherName} can no longer view this background',
      );
    } on ChatBackgroundException catch (error) {
      if (!mounted) return;

      _notice(
        error.message,
      );
    } catch (_) {
      if (!mounted) return;

      _notice(
        'Sharing setting could not be changed',
      );
    } finally {
      if (mounted) {
        setState(() {
          changingShare = false;
        });
      }
    }
  }

  Future<void> _removeBackground() async {
    if (removing) return;

    final confirmed =
        await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              0,
              20,
              20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Remove background?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  'This only removes the background from your chat with ${widget.otherName}.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(
                      sheetContext,
                    ).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(
                            sheetContext,
                            false,
                          );
                        },
                        child: const Text(
                          'Cancel',
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(
                            sheetContext,
                            true,
                          );
                        },
                        child: const Text(
                          'Remove',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true ||
        !mounted) {
      return;
    }

    setState(() {
      removing = true;
    });

    try {
      await _service.remove(
        widget.otherId,
      );

      if (!mounted) return;

      _notice(
        'Background removed',
      );
    } catch (_) {
      if (!mounted) return;

      _notice(
        'Background could not be removed',
      );
    } finally {
      if (mounted) {
        setState(() {
          removing = false;
        });
      }
    }
  }

  void _notice(
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chat Background',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: StreamBuilder<ChatBackgroundInfo>(
        stream: _service.watchMine(
          widget.otherId,
        ),
        builder: (
          context,
          snapshot,
        ) {
          if (!snapshot.hasData &&
              snapshot.connectionState ==
                  ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Background settings could not be loaded',
              ),
            );
          }

          final info =
              snapshot.data ??
              const ChatBackgroundInfo(
                imageUrl: null,
                shared: false,
              );

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              32,
            ),
            children: [
              Text(
                'ONLY THIS CHAT',
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(
                height: 7,
              ),
              Text(
                'This background is only used in your conversation with ${widget.otherName}.',
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(
                height: 18,
              ),

              _BackgroundPreview(
                imageUrl: info.imageUrl,
                otherName: widget.otherName,
              ),

              const SizedBox(
                height: 18,
              ),

              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed:
                      uploading || removing
                      ? null
                      : _chooseBackground,
                  icon: uploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons
                              .add_photo_alternate_outlined,
                        ),
                  label: Text(
                    uploading
                        ? 'Uploading...'
                        : info.hasImage
                        ? 'Change background'
                        : 'Choose background',
                  ),
                ),
              ),

              if (info.hasImage) ...[
                const SizedBox(
                  height: 8,
                ),
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed:
                        uploading || removing
                        ? null
                        : _removeBackground,
                    icon: removing
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons
                                .delete_outline_rounded,
                          ),
                    label: Text(
                      removing
                          ? 'Removing...'
                          : 'Remove background',
                    ),
                  ),
                ),
              ],

              const SizedBox(
                height: 30,
              ),

              Text(
                'SHARING',
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              _SharingCard(
                otherName: widget.otherName,
                shared: info.shared,
                hasImage: info.hasImage,
                loading: changingShare,
                onChanged: _setShared,
              ),

              const SizedBox(
                height: 14,
              ),

              Text(
                !info.hasImage
                    ? 'Choose a background before sharing it.'
                    : info.shared
                    ? '${widget.otherName} can switch to your background while chatting with you.'
                    : 'Only you can currently use this background.',
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BackgroundPreview
    extends StatelessWidget {
  const _BackgroundPreview({
    required this.imageUrl,
    required this.otherName,
  });

  final String? imageUrl;
  final String otherName;

  @override
  Widget build(
    BuildContext context,
  ) {
    final colors =
        Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(
        24,
      ),
      child: AspectRatio(
        aspectRatio: .82,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null)
              Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (
                  context,
                  child,
                  loading,
                ) {
                  if (loading == null) {
                    return child;
                  }

                  return Container(
                    color:
                        colors.surfaceContainerHighest,
                    alignment:
                        Alignment.center,
                    child:
                        const CircularProgressIndicator(),
                  );
                },
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return _DefaultBackground(
                    colors: colors,
                  );
                },
              )
            else
              _DefaultBackground(
                colors: colors,
              ),

            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin:
                        Alignment.topCenter,
                    end:
                        Alignment.bottomCenter,
                    colors: [
                      Colors.black
                          .withValues(
                        alpha: .04,
                      ),
                      Colors.black
                          .withValues(
                        alpha: .18,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets.all(
                18,
              ),
              child: Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration:
                        BoxDecoration(
                      color: Colors.white
                          .withValues(
                        alpha: .92,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 17,
                          backgroundColor:
                              colors.primaryContainer,
                          child: Text(
                            otherName
                                .substring(
                                  0,
                                  1,
                                )
                                .toUpperCase(),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Text(
                            otherName,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style:
                                const TextStyle(
                              color:
                                  Color(
                                0xFF27222B,
                              ),
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  const Align(
                    alignment:
                        Alignment.centerLeft,
                    child: _PreviewBubble(
                      text: 'Hey 👋',
                      mine: false,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  const Align(
                    alignment:
                        Alignment.centerRight,
                    child: _PreviewBubble(
                      text:
                          'I changed our chat background.',
                      mine: true,
                    ),
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  Container(
                    height: 48,
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 16,
                    ),
                    decoration:
                        BoxDecoration(
                      color: Colors.white
                          .withValues(
                        alpha: .94,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        24,
                      ),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Type a message...',
                            style:
                                TextStyle(
                              color:
                                  Color(
                                0xFF827A86,
                              ),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.send_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DefaultBackground
    extends StatelessWidget {
  const _DefaultBackground({
    required this.colors,
  });

  final ColorScheme colors;

  @override
  Widget build(
    BuildContext context,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            colors.primaryContainer,
            colors.secondaryContainer,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.wallpaper_rounded,
          size: 80,
          color: colors.primary
              .withValues(
            alpha: .22,
          ),
        ),
      ),
    );
  }
}

class _PreviewBubble
    extends StatelessWidget {
  const _PreviewBubble({
    required this.text,
    required this.mine,
  });

  final String text;
  final bool mine;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      constraints:
          const BoxConstraints(
        maxWidth: 240,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: mine
            ? const Color(
                0xFFE1D3F4,
              )
            : Colors.white
                .withValues(
                alpha: .94,
              ),
        borderRadius:
            BorderRadius.only(
          topLeft:
              const Radius.circular(
            17,
          ),
          topRight:
              const Radius.circular(
            17,
          ),
          bottomLeft:
              Radius.circular(
            mine ? 17 : 5,
          ),
          bottomRight:
              Radius.circular(
            mine ? 5 : 17,
          ),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(
            0xFF28232C,
          ),
        ),
      ),
    );
  }
}

class _SharingCard
    extends StatelessWidget {
  const _SharingCard({
    required this.otherName,
    required this.shared,
    required this.hasImage,
    required this.loading,
    required this.onChanged,
  });

  final String otherName;
  final bool shared;
  final bool hasImage;
  final bool loading;
  final ValueChanged<bool>
  onChanged;

  @override
  Widget build(
    BuildContext context,
  ) {
    final colors =
        Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: colors.outlineVariant
              .withValues(
            alpha: .55,
          ),
        ),
      ),
      child: SwitchListTile(
        value: shared,
        onChanged:
            hasImage && !loading
            ? onChanged
            : null,
        activeTrackColor:
            colors.primary,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 4,
        ),
        secondary: loading
            ? const SizedBox(
                width: 40,
                height: 40,
                child: Padding(
                  padding:
                      EdgeInsets.all(
                    10,
                  ),
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              )
            : Container(
                width: 40,
                height: 40,
                decoration:
                    BoxDecoration(
                  color: colors.primary
                      .withValues(
                    alpha: .10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    11,
                  ),
                ),
                child: Icon(
                  shared
                      ? Icons
                            .visibility_rounded
                      : Icons
                            .visibility_off_outlined,
                  color:
                      colors.primary,
                ),
              ),
        title: Text(
          'Share with $otherName',
          style: const TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
        subtitle: Text(
          shared
              ? '$otherName can use your background'
              : 'Keep this background private',
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}