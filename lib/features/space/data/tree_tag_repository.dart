import 'package:cloud_firestore/cloud_firestore.dart';

import '../presentation/tree_tags/models/tree_leaf_tag.dart';

class TreeTagRepository {
  TreeTagRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _treeTagsRef(String treeOwnerId) {
    return _firestore
        .collection('users')
        .doc(treeOwnerId)
        .collection('treeTags');
  }

  Stream<List<TreeLeafTag>> watchTags(String treeOwnerId) {
    return _treeTagsRef(treeOwnerId).snapshots().map((snapshot) {
      final tags = snapshot.docs.map((doc) {
        final data = doc.data();

        final createdAt = data['createdAt'];

        return TreeLeafTag(
          id: doc.id,
          treeOwnerId: data['treeOwnerId'] as String,
          authorId: data['authorId'] as String,
          content: data['content'] as String,
          x: (data['x'] as num).toDouble(),
          y: (data['y'] as num).toDouble(),
          createdAt: createdAt is Timestamp
              ? createdAt.toDate()
              : DateTime.now(),
        );
      }).toList();

      tags.sort((a, b) {
        return a.createdAt.compareTo(b.createdAt);
      });

      return tags;
    });
  }

  /// 实时取得标签作者名字。
  ///
  /// treeTags 里面只保存 authorId，
  /// 真正显示名字时再去 users/{uid} 读取。
  Stream<String> watchAuthorName(String authorId) {
    return _firestore.collection('users').doc(authorId).snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data();

      if (data == null) {
        return 'VonoTalky 用户';
      }

      final displayName = (data['displayName'] as String? ?? '').trim();

      if (displayName.isNotEmpty) {
        return displayName;
      }

      final username = (data['username'] as String? ?? '').trim();

      if (username.isNotEmpty) {
        return username;
      }

      return 'VonoTalky 用户';
    });
  }

  Future<void> createTag(TreeLeafTag tag) async {
    await _treeTagsRef(tag.treeOwnerId).doc(tag.id).set({
      'treeOwnerId': tag.treeOwnerId,
      'authorId': tag.authorId,
      'content': tag.content,
      'x': tag.x,
      'y': tag.y,
      'createdAt': Timestamp.fromDate(tag.createdAt),
    });
  }

  Future<void> deleteTag({
    required String treeOwnerId,
    required String tagId,
  }) async {
    await _treeTagsRef(treeOwnerId).doc(tagId).delete();
  }
}
