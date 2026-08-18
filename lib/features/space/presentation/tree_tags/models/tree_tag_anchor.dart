enum TreeTagAnchor {
  upperLeft(
    id: 'upperLeft',
    x: 0.29,
    y: 0.27,
  ),

  upperCenter(
    id: 'upperCenter',
    x: 0.50,
    y: 0.18,
  ),

  upperRight(
    id: 'upperRight',
    x: 0.71,
    y: 0.27,
  ),

  middleLeft(
    id: 'middleLeft',
    x: 0.20,
    y: 0.47,
  ),

  middleCenterLeft(
    id: 'middleCenterLeft',
    x: 0.38,
    y: 0.43,
  ),

  middleCenterRight(
    id: 'middleCenterRight',
    x: 0.62,
    y: 0.43,
  ),

  middleRight(
    id: 'middleRight',
    x: 0.80,
    y: 0.47,
  ),

  lowerLeft(
    id: 'lowerLeft',
    x: 0.30,
    y: 0.66,
  ),

  lowerCenter(
    id: 'lowerCenter',
    x: 0.50,
    y: 0.62,
  ),

  lowerRight(
    id: 'lowerRight',
    x: 0.70,
    y: 0.66,
  );

  const TreeTagAnchor({
    required this.id,
    required this.x,
    required this.y,
  });

  final String id;

  /// 相对于树冠区域的横向位置。
  ///
  /// 0 = 最左
  /// 1 = 最右
  final double x;

  /// 相对于树冠区域的纵向位置。
  ///
  /// 0 = 最上
  /// 1 = 最下
  final double y;

  static TreeTagAnchor fromId(
    String id,
  ) {
    return TreeTagAnchor.values.firstWhere(
      (anchor) {
        return anchor.id == id;
      },
      orElse: () {
        return TreeTagAnchor.lowerCenter;
      },
    );
  }
}