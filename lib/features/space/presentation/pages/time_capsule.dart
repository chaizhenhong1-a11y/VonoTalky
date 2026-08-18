import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/tree_tag_repository.dart';
import '../time_capsule/models/time_capsule_item.dart';
import '../time_capsule/sheets/create_time_capsule_sheet.dart';
import '../time_capsule/sheets/locked_time_capsule_sheet.dart';
import '../time_capsule/sheets/open_time_capsule_sheet.dart';
import '../time_capsule/sheets/time_capsule_collection_sheet.dart';
import '../time_capsule/utils/time_capsule_date.dart';
import '../time_capsule/widgets/time_capsule_scene.dart';
import '../tree_tags/models/tree_leaf_tag.dart';
import '../tree_tags/sheets/friend_tree_list_sheet.dart';
import '../tree_tags/widgets/tree_tag_layer.dart';

class TimeCapsule extends StatefulWidget {
  const TimeCapsule({super.key});

  @override
  State<TimeCapsule> createState() => _ShiJianJiaoNangState();
}

class _ShiJianJiaoNangState extends State<TimeCapsule> {
  final List<TimeCapsuleItem> _capsules = [];
  final TreeTagRepository _treeTagRepository = TreeTagRepository();

  Future<void> _openCapsuleCollection() async {
    final result = await showTimeCapsuleCollectionSheet(
      context: context,
      capsules: _capsules,
    );

    if (!mounted || result == null) return;

    if (result.type == TimeCapsuleCollectionActionType.create) {
      await _createCapsule();
      return;
    }

    final capsule = result.capsule;
    if (capsule != null) await _handleCapsuleTap(capsule);
  }

  Future<void> _createCapsule() async {
    final draft = await showCreateTimeCapsuleSheet(context: context);
    if (!mounted || draft == null) return;

    final now = DateTime.now();
    final capsule = TimeCapsuleItem(
      id: now.microsecondsSinceEpoch.toString(),
      title: draft.title,
      content: draft.content,
      createdAt: now,
      unlockDate: draft.unlockDate,
    );

    setState(() {
      _capsules.insert(0, capsule);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '时间胶囊已经埋下，${formatTimeCapsuleDate(capsule.unlockDate)} 才能打开',
        ),
      ),
    );
  }

  Future<void> _handleCapsuleTap(TimeCapsuleItem capsule) async {
    if (!capsule.isUnlocked()) {
      await showLockedTimeCapsuleSheet(
        context: context,
        capsule: capsule,
      );
      return;
    }

    await showOpenTimeCapsuleSheet(
      context: context,
      capsule: capsule,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        Positioned.fill(
          child: TimeCapsuleScene(
            hasCapsules: _capsules.isNotEmpty,
            capsuleCount: _capsules.length,
            onGroundTap: _openCapsuleCollection,
          ),
        ),
        Positioned.fill(
          child: StreamBuilder<List<TreeLeafTag>>(
            stream: _treeTagRepository.watchTags(currentUserId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint('treeTags listen error: ${snapshot.error}');
              }

              final tags = snapshot.data ?? const <TreeLeafTag>[];

              return TreeTagLayer(
                treeOwnerId: currentUserId,
                currentUserId: currentUserId,
                initialTags: tags,
                canWrite: true,
                onCreateTag: _treeTagRepository.createTag,
                watchAuthorName: _treeTagRepository.watchAuthorName,
                onDeleteTag: _treeTagRepository.deleteTag,
              );
            },
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: const Alignment(1.0, 0.18),
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Material(
                color: Theme.of(context)
                    .colorScheme
                    .surface
                    .withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(100),
                elevation: 2,
                child: InkWell(
                  borderRadius: BorderRadius.circular(100),
                  onTap: () {
                    showFriendTreeListSheet(context);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.group_outlined, size: 19),
                        SizedBox(width: 7),
                        Text(
                          '好友的树',
                          style: TextStyle(
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
          ),
        ),
      ],
    );
  }
}
