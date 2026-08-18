import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/tree_leaf_tag.dart';

typedef TreeTagAuthorNameStream = Stream<String> Function(
  String authorId,
);

typedef TreeTagDeleteCallback = Future<void> Function({
  required String treeOwnerId,
  required String tagId,
});

class TreeTagLayer extends StatefulWidget {
  const TreeTagLayer({
    super.key,
    required this.treeOwnerId,
    required this.currentUserId,
    this.initialTags = const [],
    this.canWrite = true,
    this.onTagsChanged,
    this.onCreateTag,
    this.watchAuthorName,
    this.onDeleteTag,

    // KongJian 里的 TabBarView 顶部现在让出了 116px。
    // TreeTagLayer 位于 Tab 页面内部，所以要把这个高度补回来，
    // 才能和 SharedSpaceBackground 使用完全相同的坐标系。
    this.contentTopOffset = 116.0,
  });

  final String treeOwnerId;

  final String currentUserId;

  final List<TreeLeafTag> initialTags;

  final bool canWrite;

  final ValueChanged<List<TreeLeafTag>>? onTagsChanged;

  final Future<void> Function(
    TreeLeafTag tag,
  )? onCreateTag;

  final TreeTagAuthorNameStream? watchAuthorName;

  final TreeTagDeleteCallback? onDeleteTag;

  /// TreeTagLayer 相对于 KongJian 整个场景顶部向下偏移了多少。
  ///
  /// 当前 TabBarView:
  ///
  /// padding: EdgeInsets.only(top: 116)
  ///
  /// 所以这里默认也是 116。
  final double contentTopOffset;

  @override
  State<TreeTagLayer> createState() {
    return _TreeTagLayerState();
  }
}

class _TreeTagLayerState extends State<TreeTagLayer> {
  late List<TreeLeafTag> _tags;

  @override
  void initState() {
    super.initState();

    _tags = List<TreeLeafTag>.from(
      widget.initialTags,
    );
  }

  @override
  void didUpdateWidget(
    covariant TreeTagLayer oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialTags !=
        widget.initialTags) {
      _tags = List<TreeLeafTag>.from(
        widget.initialTags,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final viewportWidth =
            constraints.maxWidth;

        final localViewportHeight =
            constraints.maxHeight;

        /*
         * ------------------------------------------------------
         * 重新还原 KongJian 整个场景的高度。
         * ------------------------------------------------------
         *
         * SharedSpaceBackground 是在 KongJian 的整个 Stack 中：
         *
         * viewportHeight = 整个空间页面高度
         *
         * 但是 TreeTagLayer 位于：
         *
         * TabBarView
         *   padding top = 116
         *
         * 所以这里拿到的 constraints.maxHeight
         * 已经少了 116。
         *
         * 补回来之后，树和点击区域才会完全一致。
         */

        final fullViewportHeight =
            localViewportHeight +
            widget.contentTopOffset;

        /*
         * SharedSpaceBackground 当前：
         *
         * Positioned(
         *   top: 50,
         *   height: viewportHeight + 50,
         * )
         */

        const sceneTop = 50.0;

        final painterHeight =
            fullViewportHeight + 50.0;

        /*
 * 必须和 Painter 的 _getTreeScale()
 * 使用完全相同的算法。
 */
final widthScale =
    viewportWidth / 390.0;

final heightScale =
    painterHeight / 800.0;

final treeScale = math
    .min(
      widthScale,
      heightScale,
    )
    .clamp(
      0.78,
      1.25,
    )
    .toDouble();

/*
 * Painter:
 *
 * groundY =
 * painterHeight * 0.72
 *
 * canopyCenterY =
 * groundY - 300 * scale
 */
final crownCenterGlobalY =
    sceneTop +
    painterHeight * 0.72 -
    300 * treeScale;

final crownCenterLocalY =
    crownCenterGlobalY -
    widget.contentTopOffset;

/*
 * Painter:
 *
 * radius = 150 * scale
 */
final crownRadius =
    150.0 * treeScale;

final crownWidth =
    crownRadius * 2;

final crownHeight =
    crownRadius * 2;

final crownLeft =
    viewportWidth / 2 -
    crownRadius;

final crownTop =
    crownCenterLocalY -
    crownRadius;

final localCrownPath =
    _buildLocalCrownPath(
  radius:
      crownRadius,
);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            /*
             * --------------------------------------------------
             * 树叶点击区域
             * --------------------------------------------------
             *
             * 不再 Positioned.fill。
             *
             * 只有树冠这一小块区域参与 HitTest。
             *
             * 所以：
             *
             * 点草地 -> 不影响时间胶囊
             * 点页面其它位置 -> 不拦截
             * 左右滑 Tab -> 仍然正常
             * 点树叶 -> 才处理标签
             */

            Positioned(
              left: crownLeft,
              top: crownTop,
              width: crownWidth,
              height: crownHeight,
              child: GestureDetector(
                behavior:
                    HitTestBehavior.translucent,
                onTapUp: widget.canWrite
                    ? (details) {
                        _handleTreeTap(
                          position:
                              details.localPosition,
                          crownPath:
                              localCrownPath,
                          crownWidth:
                              crownWidth,
                          crownHeight:
                              crownHeight,
                        );
                      }
                    : null,
              ),
            ),

            /*
             * --------------------------------------------------
             * 已经挂在树上的标签
             * --------------------------------------------------
             */

            for (final tag in _tags)
              _buildTag(
                tag: tag,
                crownLeft:
                    crownLeft,
                crownTop:
                    crownTop,
                crownWidth:
                    crownWidth,
                crownHeight:
                    crownHeight,
              ),
          ],
        );
      },
    );
  }

Path _buildLocalCrownPath({
  required double radius,
}) {
  /*
   * GestureDetector 自己就是：
   *
   * radius * 2
   * ×
   * radius * 2
   *
   * 所以局部圆心就是：
   *
   * radius, radius
   */
  return Path()
    ..addOval(
      Rect.fromCircle(
        center: Offset(
          radius,
          radius,
        ),
        radius:
            radius,
      ),
    );
}

  Future<void> _handleTreeTap({
    required Offset position,
    required Path crownPath,
    required double crownWidth,
    required double crownHeight,
  }) async {
    /*
     * 现在 GestureDetector 的矩形范围
     * 已经只覆盖树冠。
     *
     * 这里再进行一次真实 Path 判断，
     * 排除树冠四个角的空白区域。
     */

    if (!crownPath.contains(
      position,
    )) {
      return;
    }

    /*
     * 点击坐标转成 0 ~ 1。
     *
     * 以后不管手机尺寸怎么变化，
     * 标签都会保持在树冠的同一个相对位置。
     */

    final relativeX =
        (position.dx / crownWidth)
            .clamp(
              0.0,
              1.0,
            )
            .toDouble();

    final relativeY =
        (position.dy / crownHeight)
            .clamp(
              0.0,
              1.0,
            )
            .toDouble();

    final content =
        await _showWriteTagSheet();

    if (!mounted ||
        content == null ||
        content.trim().isEmpty) {
      return;
    }

    final now =
        DateTime.now();

    final tag = TreeLeafTag(
      id: now.microsecondsSinceEpoch
          .toString(),
      treeOwnerId:
          widget.treeOwnerId,
      authorId:
          widget.currentUserId,
      content:
          content.trim(),
      x:
          relativeX,
      y:
          relativeY,
      createdAt:
          now,
    );

    try {
  if (widget.onCreateTag != null) {
    // 已经接 Firestore：
    // 只负责写入，显示交给 snapshots。
    await widget.onCreateTag!(
      tag,
    );
  } else {
    // 没接后端时才使用本地状态。
    if (!mounted) {
      return;
    }

    setState(() {
      _tags.add(
        tag,
      );
    });

    widget.onTagsChanged?.call(
      List<TreeLeafTag>.unmodifiable(
        _tags,
      ),
    );
  }
} catch (error) {
  if (!mounted) {
    return;
  }

  ScaffoldMessenger.of(
    context,
  ).showSnackBar(
    const SnackBar(
      content: Text(
        '标签没有挂成功，请稍后再试',
      ),
    ),
  );
}
  }

  Widget _buildTag({
    required TreeLeafTag tag,
    required double crownLeft,
    required double crownTop,
    required double crownWidth,
    required double crownHeight,
  }) {
    final x =
        crownLeft +
        crownWidth * tag.x;

    final y =
        crownTop +
        crownHeight * tag.y;

    const hitWidth =
        48.0;

    const hitHeight =
        52.0;

    return Positioned(
      left:
          x - hitWidth / 2,
      top:
          y - hitHeight / 2,
      width:
          hitWidth,
      height:
          hitHeight,
      child: _TreeTagView(
        tag:
            tag,
        onTap: () {
          _openTag(
            tag,
          );
        },
      ),
    );
  }

  Future<String?> _showWriteTagSheet() {
  return showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return const _WriteTreeTagSheet();
    },
  );
}

  Future<void> _openTag(
    TreeLeafTag tag,
  ) async {
    final canDelete =
        widget.currentUserId == tag.treeOwnerId ||
        widget.currentUserId == tag.authorId;

    final deleted = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (
        sheetContext,
      ) {
        return _TreeTagDetailSheet(
          tag: tag,
          authorNameStream:
              widget.watchAuthorName?.call(
            tag.authorId,
          ),
          canDelete:
              canDelete && widget.onDeleteTag != null,
          onDelete: widget.onDeleteTag == null
              ? null
              : () async {
                  await widget.onDeleteTag!(
                    treeOwnerId: tag.treeOwnerId,
                    tagId: tag.id,
                  );
                },
        );
      },
    );

    if (!mounted || deleted != true) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('标签已删除'),
      ),
    );
  }
}

class _TreeTagView
    extends StatelessWidget {
  const _TreeTagView({
    required this.tag,
    required this.onTap,
  });

  final TreeLeafTag tag;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    /*
     * 每张纸条轻微有一点不同角度，
     * 让它不像完全机械排列。
     */

    final rotation =
        ((tag.id.hashCode % 9) - 4) *
        0.012;

    return Center(
      child: GestureDetector(
        behavior:
            HitTestBehavior.opaque,
        onTap:
            onTap,
        child: Transform.rotate(
          angle:
              rotation,
          child: Stack(
            clipBehavior:
                Clip.none,
            alignment:
                Alignment.topCenter,
            children: [
              /*
               * 小绳子
               */

              Positioned(
                top: -7,
                child: Container(
                  width: 2,
                  height: 10,
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFF705334,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      100,
                    ),
                  ),
                ),
              ),

              /*
               * 标签纸
               */

              Container(
                width: 31,
                height: 36,
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFFFE5A0,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    5,
                  ),
                  border:
                      Border.all(
                    color:
                        const Color(
                      0xFF7D542A,
                    ),
                    width:
                        1.4,
                  ),
                  boxShadow:
                      const [
                    BoxShadow(
                      color:
                          Color(
                        0x30000000,
                      ),
                      blurRadius:
                          5,
                      offset:
                          Offset(
                        0,
                        3,
                      ),
                    ),
                  ],
                ),
                alignment:
                    Alignment.center,
                child:
                    const Icon(
                  Icons
                      .local_offer_rounded,
                  size:
                      17,
                  color:
                      Color(
                    0xFF815728,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WriteTreeTagSheet extends StatefulWidget {
  const _WriteTreeTagSheet();

  @override
  State<_WriteTreeTagSheet> createState() {
    return _WriteTreeTagSheetState();
  }
}

class _WriteTreeTagSheetState
    extends State<_WriteTreeTagSheet> {
  static const int _maxLength = 80;

  final TextEditingController _controller =
      TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset =
        MediaQuery.viewInsetsOf(
      context,
    ).bottom;

    return Padding(
      padding:
          EdgeInsets.only(
        bottom:
            bottomInset,
      ),
      child: Container(
        padding:
            const EdgeInsets.fromLTRB(
          24,
          14,
          24,
          24,
        ),
        decoration:
            const BoxDecoration(
          color:
              Color(
            0xFFFFFCF5,
          ),
          borderRadius:
              BorderRadius.vertical(
            top:
                Radius.circular(
              28,
            ),
          ),
        ),
        child: SafeArea(
          top:
              false,
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width:
                      42,
                  height:
                      4,
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFD5CCBC,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      100,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height:
                    22,
              ),

              const Text(
                '挂一张标签',
                style:
                    TextStyle(
                  fontSize:
                      22,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      Color(
                    0xFF3F4436,
                  ),
                ),
              ),

              const SizedBox(
                height:
                    6,
              ),

              const Text(
                '给这棵树的主人留下一句话。',
                style:
                    TextStyle(
                  fontSize:
                      14,
                  color:
                      Color(
                    0xFF918A7D,
                  ),
                ),
              ),

              const SizedBox(
                height:
                    20,
              ),

              TextField(
                controller:
                    _controller,
                autofocus:
                    true,
                minLines:
                    3,
                maxLines:
                    5,
                maxLength:
                    _maxLength,
                textInputAction:
                    TextInputAction.newline,
                decoration:
                    InputDecoration(
                  hintText:
                      '写点什么……',
                  filled:
                      true,
                  fillColor:
                      const Color(
                    0xFFF5F0E7,
                  ),
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                ),
                onChanged: (_) {
                  setState(() {});
                },
              ),

              const SizedBox(
                height:
                    14,
              ),

              SizedBox(
                width:
                    double.infinity,
                child:
                    FilledButton.icon(
                  onPressed: _controller.text.trim().isEmpty
    ? null
    : () {
        Navigator.of(context).pop(
          _controller.text.trim(),
        );
      },
                  style:
                      FilledButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFF71835E,
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      vertical:
                          15,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                    ),
                  ),
                  icon:
                      const Icon(
                    Icons.local_offer_outlined,
                  ),
                  label:
                      const Text(
                    '挂到这里',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TreeTagDetailSheet extends StatefulWidget {
  const _TreeTagDetailSheet({
    required this.tag,
    required this.authorNameStream,
    required this.canDelete,
    required this.onDelete,
  });

  final TreeLeafTag tag;
  final Stream<String>? authorNameStream;
  final bool canDelete;
  final Future<void> Function()? onDelete;

  @override
  State<_TreeTagDetailSheet> createState() {
    return _TreeTagDetailSheetState();
  }
}

class _TreeTagDetailSheetState extends State<_TreeTagDetailSheet> {
  bool _deleting = false;

  Future<void> _delete() async {
    final onDelete = widget.onDelete;

    if (onDelete == null || _deleting) {
      return;
    }

    setState(() {
      _deleting = true;
    });

    try {
      await onDelete();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _deleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('删除失败，请稍后再试'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFCF5),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD5CCBC),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                Icon(
                  Icons.local_offer_rounded,
                  color: Color(0xFF8B642E),
                ),
                SizedBox(width: 10),
                Text(
                  '树叶上的标签',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF42443B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  size: 18,
                  color: Color(0xFF8D8578),
                ),
                const SizedBox(width: 7),
                if (widget.authorNameStream != null)
                  StreamBuilder<String>(
                    stream: widget.authorNameStream,
                    builder: (context, snapshot) {
                      final name = snapshot.data ?? '读取中…';

                      return Text(
                        '来自 $name',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF797267),
                        ),
                      );
                    },
                  )
                else
                  const Text(
                    '来自 VonoTalky 用户',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF797267),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE9B0),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0x33764F25),
                ),
              ),
              child: Text(
                widget.tag.content,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.65,
                  color: Color(0xFF55462F),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _formatDate(widget.tag.createdAt),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9B9386),
              ),
            ),
            if (widget.canDelete) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _deleting ? null : _delete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                  ),
                  icon: _deleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.delete_outline_rounded,
                        ),
                  label: Text(
                    _deleting ? '正在删除…' : '删除这张标签',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(
    DateTime date,
  ) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}
