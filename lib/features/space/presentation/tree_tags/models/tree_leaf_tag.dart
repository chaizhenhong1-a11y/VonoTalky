class TreeLeafTag {
  const TreeLeafTag({
    required this.id,
    required this.treeOwnerId,
    required this.authorId,
    required this.content,
    required this.x,
    required this.y,
    required this.createdAt,
  });

  final String id;

  /// 这棵树属于谁。
  final String treeOwnerId;

  /// 谁留下这个标签。
  final String authorId;

  final String content;

  /// 标签在树冠内部的相对横坐标。
  ///
  /// 0 = 最左
  /// 1 = 最右
  final double x;

  /// 标签在树冠内部的相对纵坐标。
  ///
  /// 0 = 最上
  /// 1 = 最下
  final double y;

  final DateTime createdAt;

  TreeLeafTag copyWith({
    String? id,
    String? treeOwnerId,
    String? authorId,
    String? content,
    double? x,
    double? y,
    DateTime? createdAt,
  }) {
    return TreeLeafTag(
      id: id ?? this.id,
      treeOwnerId: treeOwnerId ?? this.treeOwnerId,
      authorId: authorId ?? this.authorId,
      content: content ?? this.content,
      x: x ?? this.x,
      y: y ?? this.y,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'treeOwnerId': treeOwnerId,
      'authorId': authorId,
      'content': content,
      'x': x,
      'y': y,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TreeLeafTag.fromMap(
    Map<String, dynamic> map,
  ) {
    return TreeLeafTag(
      id: map['id'] as String,
      treeOwnerId: map['treeOwnerId'] as String,
      authorId: map['authorId'] as String,
      content: map['content'] as String,
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      createdAt: DateTime.parse(
        map['createdAt'] as String,
      ),
    );
  }
}