import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../chat/data/models/chat_user.dart';
import '../../data/tree_tag_repository.dart';
import '../tree_tags/models/tree_leaf_tag.dart';
import '../tree_tags/widgets/tree_tag_layer.dart';
import '../widgets/shared_space_background.dart';

class FriendTreePage extends StatefulWidget {
  const FriendTreePage({super.key, required this.user});

  final ChatUser user;

  @override
  State<FriendTreePage> createState() => _FriendTreePageState();
}

class _FriendTreePageState extends State<FriendTreePage> {
  final TreeTagRepository _treeTagRepository = TreeTagRepository();

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return const Scaffold(body: Center(child: Text('请先登录')));
    }

    return Scaffold(
      appBar: AppBar(title: Text('${widget.user.name} 的树'), centerTitle: true),
      body: Stack(
        children: [
          const Positioned.fill(
            child: SharedSpaceBackground(
              pageAnimation: AlwaysStoppedAnimation<double>(1.0),
            ),
          ),
          Positioned.fill(
            child: StreamBuilder<List<TreeLeafTag>>(
              stream: _treeTagRepository.watchTags(widget.user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint('friend tree tags error: ${snapshot.error}');
                }

                final tags = snapshot.data ?? const <TreeLeafTag>[];

                return TreeTagLayer(
                  treeOwnerId: widget.user.uid,
                  currentUserId: currentUserId,
                  initialTags: tags,
                  canWrite: true,
                  contentTopOffset: 0,
                  onCreateTag: _treeTagRepository.createTag,
                  watchAuthorName: _treeTagRepository.watchAuthorName,
                  onDeleteTag: _treeTagRepository.deleteTag,
                );
              },
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.86),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x18000000),
                        blurRadius: 16,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_offer_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '轻点树叶，给 ${widget.user.name} 留下一张标签',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
