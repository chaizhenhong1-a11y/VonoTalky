import 'package:flutter/material.dart';

import 'package:vonotalky/features/chat/data/models/chat_user.dart';
import 'package:vonotalky/features/contacts/data/services/contact_service.dart';
import 'package:vonotalky/features/space/presentation/pages/friend_tree_page.dart';

Future<void> showFriendTreeListSheet(
  BuildContext context,
) async {
  final friend = await showModalBottomSheet<ChatUser>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return const FriendTreeListSheet();
    },
  );

  if (friend == null || !context.mounted) {
    return;
  }

  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) {
        return FriendTreePage(
          user: friend,
        );
      },
    ),
  );
}

class FriendTreeListSheet extends StatefulWidget {
  const FriendTreeListSheet({
    super.key,
  });

  @override
  State<FriendTreeListSheet> createState() {
    return _FriendTreeListSheetState();
  }
}

class _FriendTreeListSheetState
    extends State<FriendTreeListSheet> {
  final ContactService _contactService =
      ContactService();

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    final colorScheme =
        theme.colorScheme;

    final screenHeight =
        MediaQuery.sizeOf(context).height;

    return Material(
      color: colorScheme.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(28),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: screenHeight * 0.68,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(
                height: 12,
              ),

              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius:
                      BorderRadius.circular(
                    100,
                  ),
                ),
              ),

              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  18,
                  12,
                  12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorScheme
                            .primaryContainer,
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.park_rounded,
                        color: colorScheme
                            .onPrimaryContainer,
                      ),
                    ),

                    const SizedBox(
                      width: 13,
                    ),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            '好友的树',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                          SizedBox(
                            height: 2,
                          ),
                          Text(
                            '选择一个好友去看看 TA 的树',
                            style: TextStyle(
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(
                height: 1,
              ),

              Expanded(
                child: StreamBuilder<List<ChatUser>>(
                  stream:
                      _contactService.contacts(),
                  builder: (
                    context,
                    snapshot,
                  ) {
                    if (snapshot.connectionState ==
                            ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(
                        child:
                            CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return _FriendTreeError(
                        onRetry: () {
                          setState(() {});
                        },
                      );
                    }

                    final friends =
                        snapshot.data ??
                        const <ChatUser>[];

                    if (friends.isEmpty) {
                      return const _EmptyFriendTrees();
                    }

                    return ListView.separated(
                      padding:
                          const EdgeInsets.fromLTRB(
                        16,
                        14,
                        16,
                        24,
                      ),
                      itemCount:
                          friends.length,
                      separatorBuilder:
                          (
                            context,
                            index,
                          ) {
                        return const SizedBox(
                          height: 10,
                        );
                      },
                      itemBuilder:
                          (
                            context,
                            index,
                          ) {
                        final friend =
                            friends[index];

                        return _FriendTreeTile(
                          friend:
                              friend,
                          onTap:
                              () {
                            Navigator.of(
                              context,
                            ).pop(
                              friend,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendTreeTile
    extends StatelessWidget {
  const _FriendTreeTile({
    required this.friend,
    required this.onTap,
  });

  final ChatUser friend;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    final colorScheme =
        theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius:
          BorderRadius.circular(
        20,
      ),
      clipBehavior:
          Clip.antiAlias,
      child: InkWell(
        onTap:
            onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal:
                14,
            vertical:
                12,
          ),
          child: Row(
            children: [
              _FriendAvatar(
                friend:
                    friend,
              ),

              const SizedBox(
                width:
                    14,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.name,
                      maxLines:
                          1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontSize:
                            16,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height:
                          4,
                    ),

                    Text(
                      friend.isOnline
                          ? '在线'
                          : '访问 TA 的树',
                      style:
                          TextStyle(
                        fontSize:
                            13,
                        color:
                            friend.isOnline
                                ? colorScheme.primary
                                : colorScheme
                                    .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width:
                    38,
                height:
                    38,
                decoration:
                    BoxDecoration(
                  color:
                      colorScheme
                          .primaryContainer,
                  shape:
                      BoxShape.circle,
                ),
                alignment:
                    Alignment.center,
                child:
                    Icon(
                  Icons
                      .park_outlined,
                  size:
                      20,
                  color:
                      colorScheme
                          .onPrimaryContainer,
                ),
              ),

              const SizedBox(
                width:
                    4,
              ),

              Icon(
                Icons
                    .chevron_right_rounded,
                color:
                    colorScheme
                        .onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendAvatar
    extends StatelessWidget {
  const _FriendAvatar({
    required this.friend,
  });

  final ChatUser friend;

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final photoUrl =
        friend.photoUrl?.trim();

    final firstCharacter =
        friend.name.trim().isEmpty
            ? '?'
            : friend.name
                .trim()
                .characters
                .first
                .toUpperCase();

    return Container(
      width:
          52,
      height:
          52,
      decoration:
          BoxDecoration(
        shape:
            BoxShape.circle,
        color:
            colorScheme
                .secondaryContainer,
      ),
      clipBehavior:
          Clip.antiAlias,
      child:
          photoUrl != null &&
                  photoUrl.isNotEmpty
              ? Image.network(
                  photoUrl,
                  fit:
                      BoxFit.cover,
                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return _AvatarFallback(
                      text:
                          firstCharacter,
                    );
                  },
                )
              : _AvatarFallback(
                  text:
                      firstCharacter,
                ),
    );
  }
}

class _AvatarFallback
    extends StatelessWidget {
  const _AvatarFallback({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Center(
      child: Text(
        text,
        style:
            TextStyle(
          fontSize:
              20,
          fontWeight:
              FontWeight.w700,
          color:
              colorScheme
                  .onSecondaryContainer,
        ),
      ),
    );
  }
}

class _EmptyFriendTrees
    extends StatelessWidget {
  const _EmptyFriendTrees();

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          32,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Container(
              width:
                  76,
              height:
                  76,
              decoration:
                  BoxDecoration(
                color:
                    colorScheme
                        .surfaceContainerHighest,
                shape:
                    BoxShape.circle,
              ),
              alignment:
                  Alignment.center,
              child:
                  Icon(
                Icons
                    .groups_2_outlined,
                size:
                    34,
                color:
                    colorScheme
                        .onSurfaceVariant,
              ),
            ),

            const SizedBox(
              height:
                  18,
            ),

            const Text(
              '还没有好友',
              style:
                  TextStyle(
                fontSize:
                    18,
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            const SizedBox(
              height:
                  6,
            ),

            Text(
              '添加好友以后，就可以从这里访问对方的树。',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                height:
                    1.5,
                color:
                    colorScheme
                        .onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendTreeError
    extends StatelessWidget {
  const _FriendTreeError({
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          32,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              Icons
                  .cloud_off_outlined,
              size:
                  42,
              color:
                  colorScheme.error,
            ),

            const SizedBox(
              height:
                  14,
            ),

            const Text(
              '好友列表加载失败',
              style:
                  TextStyle(
                fontSize:
                    17,
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            const SizedBox(
              height:
                  12,
            ),

            OutlinedButton.icon(
              onPressed:
                  onRetry,
              icon:
                  const Icon(
                Icons.refresh_rounded,
              ),
              label:
                  const Text(
                '重试',
              ),
            ),
          ],
        ),
      ),
    );
  }
}