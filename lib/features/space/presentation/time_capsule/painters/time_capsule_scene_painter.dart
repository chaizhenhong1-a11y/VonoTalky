import 'dart:math' as math;

import 'package:flutter/material.dart';

class TimeCapsuleScenePainter extends CustomPainter {
  const TimeCapsuleScenePainter({
    required this.animationValue,
    required this.hasCapsules,
    required this.isNight,
    this.viewportWidth,
  });

  final double animationValue;
  final bool hasCapsules;
  final bool isNight;

  /// 一张页面真正的宽度。
  ///
  /// SharedSpaceBackground 是 3 屏长画布，
  /// 不能直接拿整个 size.width 来计算树尺寸。
  final double? viewportWidth;

  double _getTreeScale(Size size) {
  final localWidth =
      viewportWidth ?? size.width;

  final widthScale =
      localWidth / 390.0;

  final heightScale =
      size.height / 800.0;

  /*
   * 所有树的尺寸全部使用同一个比例。
   *
   * 390 × 800 左右：
   * scale ≈ 1
   *
   * 小手机：
   * 整棵树一起缩小
   *
   * 平板 / 大屏：
   * 整棵树一起变大，
   * 但是最多 1.25，防止巨大化。
   */
  return math
      .min(
        widthScale,
        heightScale,
      )
      .clamp(
        0.78,
        1.25,
      )
      .toDouble();
}

  @override
  void paint(Canvas canvas, Size size) {
    final groundY = size.height * 0.72;

    _drawSky(
      canvas,
      size,
    );

    if (isNight) {
      _drawStars(
        canvas,
        size,
      );

      _drawMoon(
        canvas,
        size,
      );
    } else {
      _drawSunGlow(
        canvas,
        size,
      );
    }

    _drawDistantHills(
      canvas,
      size,
      groundY,
    );

    _drawLawn(
      canvas,
      size,
      groundY,
    );

    _drawTreeShadow(
      canvas,
      size,
      groundY,
    );

    _drawTree(
      canvas,
      size,
      groundY,
    );

    _drawGroundDetails(
      canvas,
      size,
      groundY,
    );

    if (hasCapsules) {
      _drawSprout(
        canvas,
        size,
        groundY,
      );
    }

    _drawFloatingLights(
      canvas,
      size,
    );
  }

  void _drawSky(
    Canvas canvas,
    Size size,
  ) {
    final rect = Offset.zero & size;

    final colors = isNight
        ? const [
            Color(0xFF070B18),
            Color(0xFF10182C),
            Color(0xFF24324B),
          ]
        : const [
            Color(0xFFF9F5EB),
            Color(0xFFF3EFE2),
            Color(0xFFE8ECD9),
          ];

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
        stops: const [
          0,
          0.58,
          1,
        ],
      ).createShader(rect);

    canvas.drawRect(
      rect,
      paint,
    );
  }

  void _drawSunGlow(
    Canvas canvas,
    Size size,
  ) {
    final center = Offset(
      size.width * 0.78,
      size.height * 0.16,
    );

    final radius = size.width * 0.28;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0x55FFE9A8),
          const Color(0x00FFE9A8),
        ],
      ).createShader(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
      );

    canvas.drawCircle(
      center,
      radius,
      paint,
    );
  }

  void _drawStars(
    Canvas canvas,
    Size size,
  ) {
    final twinkle =
        (math.sin(animationValue * math.pi * 2) + 1) / 2;

    final stars = <Offset>[
      Offset(size.width * 0.08, size.height * 0.09),
      Offset(size.width * 0.17, size.height * 0.18),
      Offset(size.width * 0.29, size.height * 0.10),
      Offset(size.width * 0.40, size.height * 0.20),
      Offset(size.width * 0.53, size.height * 0.08),
      Offset(size.width * 0.66, size.height * 0.18),
      Offset(size.width * 0.78, size.height * 0.07),
      Offset(size.width * 0.96, size.height * 0.22),
      Offset(size.width * 0.12, size.height * 0.34),
      Offset(size.width * 0.84, size.height * 0.31),
    ];

    for (int i = 0; i < stars.length; i++) {
      final opacity = i.isEven
          ? 0.45 + twinkle * 0.42
          : 0.38 + (1 - twinkle) * 0.36;

      final paint = Paint()
        ..color = Color.fromRGBO(
          242,
          246,
          255,
          opacity,
        );

      canvas.drawCircle(
        stars[i],
        i % 3 == 0 ? 1.8 : 1.2,
        paint,
      );
    }
  }

  void _drawMoon(
    Canvas canvas,
    Size size,
  ) {
    // 固定在右上角留白区，避免遮住树冠。
    final center = Offset(
      size.width * 0.91,
      size.height * 0.085,
    );

    final moonRadius =
        math.min(size.width, size.height) * 0.035;
    final glowRadius = moonRadius * 3.4;

    final glowPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0x55DCE7FF),
          Color(0x22DCE7FF),
          Color(0x00DCE7FF),
        ],
        stops: [
          0,
          0.45,
          1,
        ],
      ).createShader(
        Rect.fromCircle(
          center: center,
          radius: glowRadius,
        ),
      );

    canvas.drawCircle(
      center,
      glowRadius,
      glowPaint,
    );

    final moonRect = Rect.fromCircle(
      center: center,
      radius: moonRadius,
    );

    final moonPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.35, -0.35),
        radius: 1.0,
        colors: [
          Color(0xFFFFFBEA),
          Color(0xFFF1EDCF),
          Color(0xFFD8D5BE),
        ],
        stops: [
          0,
          0.62,
          1,
        ],
      ).createShader(moonRect);

    canvas.drawCircle(
      center,
      moonRadius,
      moonPaint,
    );

    final craterPaint = Paint()
      ..color = const Color(0x1F7C7B73);

    canvas.drawCircle(
      Offset(
        center.dx - moonRadius * 0.28,
        center.dy - moonRadius * 0.10,
      ),
      moonRadius * 0.15,
      craterPaint,
    );

    canvas.drawCircle(
      Offset(
        center.dx + moonRadius * 0.18,
        center.dy + moonRadius * 0.24,
      ),
      moonRadius * 0.11,
      craterPaint,
    );
  }

  void _drawFloatingLights(
    Canvas canvas,
    Size size,
  ) {
    final movement = math.sin(
      animationValue * math.pi * 2,
    );

    final points = [
      Offset(
        size.width * 0.16,
        size.height * 0.20,
      ),
      Offset(
        size.width * 0.27,
        size.height * 0.30,
      ),
      Offset(
        size.width * 0.73,
        size.height * 0.27,
      ),
      Offset(
        size.width * 0.83,
        size.height * 0.36,
      ),
      Offset(
        size.width * 0.14,
        size.height * 0.46,
      ),
      Offset(
        size.width * 0.89,
        size.height * 0.51,
      ),
    ];

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final lightCenter = Offset(
        point.dx + movement * (i.isEven ? 3 : -3),
        point.dy + movement * 2,
      );

      if (isNight) {
        final glowRadius = i.isEven ? 10.0 : 8.0;
        final glowPaint = Paint()
          ..shader = const RadialGradient(
            colors: [
              Color(0x99FFF3A7),
              Color(0x33FFF3A7),
              Color(0x00FFF3A7),
            ],
          ).createShader(
            Rect.fromCircle(
              center: lightCenter,
              radius: glowRadius,
            ),
          );

        canvas.drawCircle(
          lightCenter,
          glowRadius,
          glowPaint,
        );
      }

      final paint = Paint()
        ..color = isNight
            ? const Color(0xEEFFF3A7)
            : const Color(0x66FFF4C4);

      canvas.drawCircle(
        lightCenter,
        i.isEven ? 2.2 : 1.6,
        paint,
      );
    }
  }

  void _drawDistantHills(
    Canvas canvas,
    Size size,
    double groundY,
  ) {
    final backPaint = Paint()
      ..color = isNight
          ? const Color(0xFF33463F)
          : const Color(0xFFDCE2CE);

    final backPath = Path()
      ..moveTo(
        0,
        groundY,
      )
      ..cubicTo(
        size.width * 0.10,
        groundY - 70,
        size.width * 0.28,
        groundY - 70,
        size.width * 0.40,
        groundY - 18,
      )
      ..cubicTo(
        size.width * 0.55,
        groundY - 95,
        size.width * 0.77,
        groundY - 105,
        size.width,
        groundY - 25,
      )
      ..lineTo(
        size.width,
        groundY,
      )
      ..close();

    canvas.drawPath(
      backPath,
      backPaint,
    );

    final frontPaint = Paint()
      ..color = isNight
          ? const Color(0xFF293C34)
          : const Color(0xFFC7D2B4);

    final frontPath = Path()
      ..moveTo(
        0,
        groundY,
      )
      ..cubicTo(
        size.width * 0.18,
        groundY - 42,
        size.width * 0.30,
        groundY - 32,
        size.width * 0.48,
        groundY,
      )
      ..cubicTo(
        size.width * 0.66,
        groundY - 48,
        size.width * 0.82,
        groundY - 39,
        size.width,
        groundY,
      )
      ..close();

    canvas.drawPath(
      frontPath,
      frontPaint,
    );
  }

  void _drawLawn(
    Canvas canvas,
    Size size,
    double groundY,
  ) {
    final lawnRect = Rect.fromLTRB(
      0,
      groundY - 40,
      size.width,
      size.height,
    );

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isNight
            ? const [
                Color(0xFF415942),
                Color(0xFF304535),
                Color(0xFF1E2E25),
              ]
            : const [
                Color(0xFFAFC38C),
                Color(0xFF91AA73),
                Color(0xFF71885A),
              ],
        stops: const [
          0,
          0.52,
          1,
        ],
      ).createShader(lawnRect);

    final path = Path()
      ..moveTo(
        0,
        groundY,
      )
      ..cubicTo(
        size.width * 0.24,
        groundY - 20,
        size.width * 0.34,
        groundY + 4,
        size.width * 0.50,
        groundY - 4,
      )
      ..cubicTo(
        size.width * 0.66,
        groundY - 15,
        size.width * 0.83,
        groundY - 11,
        size.width,
        groundY,
      )
      ..lineTo(
        size.width,
        size.height,
      )
      ..lineTo(
        0,
        size.height,
      )
      ..close();

    canvas.drawPath(
      path,
      paint,
    );

    final lightPaint = Paint()
      ..color = isNight
          ? const Color(0x122E5A43)
          : const Color(0x2291A975);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          size.width * 0.36,
          groundY + 55,
        ),
        width: size.width * 0.58,
        height: 80,
      ),
      lightPaint,
    );
  }

  void _drawTreeShadow(
  Canvas canvas,
  Size size,
  double groundY,
) {
  final scale =
      _getTreeScale(size);

  final centerX =
      size.width * 0.50;

  final softPaint = Paint()
    ..color = isNight
        ? const Color(0x55202A23)
        : const Color(0x26313D2B)
    ..maskFilter =
        const MaskFilter.blur(
      BlurStyle.normal,
      16,
    );

  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(
        centerX + 12 * scale,
        groundY + 20 * scale,
      ),
      width:
          250 * scale,
      height:
          48 * scale,
    ),
    softPaint,
  );

  final contactPaint = Paint()
    ..color = isNight
        ? const Color(0x7A151C18)
        : const Color(0x49303828)
    ..maskFilter =
        const MaskFilter.blur(
      BlurStyle.normal,
      5,
    );

  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(
        centerX,
        groundY + 8 * scale,
      ),
      width:
          120 * scale,
      height:
          20 * scale,
    ),
    contactPaint,
  );
}

  void _drawTree(
  Canvas canvas,
  Size size,
  double groundY,
) {
  final centerX =
      size.width * 0.50;

  final scale =
      _getTreeScale(size);

  /*
   * 树冠唯一的大圆圆心。
   */
  final canopyCenterY =
      groundY - 300 * scale;

  /*
   * 树干顶部深入树冠里面。
   */
  final trunkTopY =
      groundY - 255 * scale;

  /*
   * 树根
   */
  _drawTreeRoots(
    canvas,
    centerX,
    groundY,
    scale,
  );

  /*
   * 树干
   */
  _drawTrunk(
    canvas,
    centerX,
    groundY,
    trunkTopY,
    scale,
  );

  final wind = math.sin(
    animationValue *
        math.pi *
        2,
  );

  final swayAngle =
      wind * 0.006;

  final pivot = Offset(
    centerX,
    groundY - 245 * scale,
  );

  canvas.save();

  canvas.translate(
    pivot.dx,
    pivot.dy,
  );

  canvas.rotate(
    swayAngle,
  );

  canvas.translate(
    -pivot.dx,
    -pivot.dy,
  );

  /*
   * 先画树枝。
   *
   * 等一下树冠覆盖在树枝上，
   * 所以树枝不会浮在圆形树冠表面。
   */
  _drawBranches(
    canvas,
    centerX,
    groundY,
    scale,
  );

  /*
   * 最后画唯一的大圆树冠。
   */
  _drawCanopy(
    canvas,
    centerX,
    canopyCenterY,
    scale,
  );

  canvas.restore();

  _drawBarkDetails(
    canvas,
    centerX,
    groundY,
    scale,
  );
}

  void _drawTrunk(
  Canvas canvas,
  double centerX,
  double groundY,
  double trunkTopY,
  double scale,
) {
  final trunkRect =
      Rect.fromLTRB(
    centerX - 46 * scale,
    trunkTopY,
    centerX + 46 * scale,
    groundY,
  );

  final trunkPaint = Paint()
    ..shader = LinearGradient(
      begin:
          Alignment.centerLeft,
      end:
          Alignment.centerRight,
      colors: isNight
          ? const [
              Color(0xFF2D211D),
              Color(0xFF4B372D),
              Color(0xFF674B39),
              Color(0xFF47342B),
              Color(0xFF251B18),
            ]
          : const [
              Color(0xFF493224),
              Color(0xFF75513A),
              Color(0xFF956D50),
              Color(0xFF76513A),
              Color(0xFF452F23),
            ],
      stops: const [
        0.0,
        0.18,
        0.43,
        0.72,
        1.0,
      ],
    ).createShader(
      trunkRect,
    );

  final path = Path()
    ..moveTo(
      centerX - 36 * scale,
      groundY + 3 * scale,
    )
    ..cubicTo(
      centerX - 28 * scale,
      groundY - 75 * scale,
      centerX - 17 * scale,
      groundY - 145 * scale,
      centerX - 27 * scale,
      trunkTopY + 12 * scale,
    )
    ..cubicTo(
      centerX - 16 * scale,
      trunkTopY - 9 * scale,
      centerX + 1 * scale,
      trunkTopY - 15 * scale,
      centerX + 18 * scale,
      trunkTopY + 5 * scale,
    )
    ..cubicTo(
      centerX + 7 * scale,
      groundY - 135 * scale,
      centerX + 29 * scale,
      groundY - 62 * scale,
      centerX + 42 * scale,
      groundY + 4 * scale,
    )
    ..cubicTo(
      centerX + 15 * scale,
      groundY - 4 * scale,
      centerX - 12 * scale,
      groundY - 3 * scale,
      centerX - 36 * scale,
      groundY + 3 * scale,
    )
    ..close();

  canvas.drawPath(
    path,
    trunkPaint,
  );

  final highlightPaint = Paint()
    ..color = isNight
        ? const Color(
            0x187E8BA0,
          )
        : const Color(
            0x2EFFF0D8,
          )
    ..style =
        PaintingStyle.stroke
    ..strokeWidth =
        5 * scale
    ..strokeCap =
        StrokeCap.round;

  final highlightPath = Path()
    ..moveTo(
      centerX - 8 * scale,
      groundY - 20 * scale,
    )
    ..cubicTo(
      centerX - 15 * scale,
      groundY - 88 * scale,
      centerX - 8 * scale,
      groundY - 155 * scale,
      centerX - 10 * scale,
      trunkTopY + 20 * scale,
    );

  canvas.drawPath(
    highlightPath,
    highlightPaint,
  );
}

  void _drawTreeRoots(
  Canvas canvas,
  double centerX,
  double groundY,
  double scale,
) {
  final shadowPaint = Paint()
    ..color = isNight
        ? const Color(0x66201817)
        : const Color(0x3B3A2B20)
    ..style =
        PaintingStyle.stroke
    ..strokeCap =
        StrokeCap.round
    ..strokeWidth =
        15 * scale;

  final leftRoot = Path()
    ..moveTo(
      centerX - 18 * scale,
      groundY - 2 * scale,
    )
    ..quadraticBezierTo(
      centerX - 50 * scale,
      groundY + 4 * scale,
      centerX - 88 * scale,
      groundY + 14 * scale,
    );

  final rightRoot = Path()
    ..moveTo(
      centerX + 20 * scale,
      groundY - 1 * scale,
    )
    ..quadraticBezierTo(
      centerX + 55 * scale,
      groundY + 5 * scale,
      centerX + 91 * scale,
      groundY + 13 * scale,
    );

  canvas.drawPath(
    leftRoot,
    shadowPaint,
  );

  canvas.drawPath(
    rightRoot,
    shadowPaint,
  );

  final rootPaint = Paint()
    ..color = isNight
        ? const Color(
            0xFF433126,
          )
        : const Color(
            0xFF674936,
          )
    ..style =
        PaintingStyle.stroke
    ..strokeCap =
        StrokeCap.round
    ..strokeWidth =
        10 * scale;

  canvas.drawPath(
    leftRoot,
    rootPaint,
  );

  canvas.drawPath(
    rightRoot,
    rootPaint,
  );

  final rootHighlight = Paint()
    ..color = isNight
        ? const Color(
            0x156F7D8F,
          )
        : const Color(
            0x2AAB8667,
          )
    ..style =
        PaintingStyle.stroke
    ..strokeWidth =
        3 * scale
    ..strokeCap =
        StrokeCap.round;

  canvas.drawPath(
    leftRoot,
    rootHighlight,
  );

  canvas.drawPath(
    rightRoot,
    rootHighlight,
  );
}

  void _drawBranches(
  Canvas canvas,
  double centerX,
  double groundY,
  double scale,
) {
  final darkPaint = Paint()
    ..color = isNight
        ? const Color(
            0xFF2C211D,
          )
        : const Color(
            0xFF4C3528,
          )
    ..strokeCap =
        StrokeCap.round
    ..style =
        PaintingStyle.stroke;

  final lightPaint = Paint()
    ..color = isNight
        ? const Color(
            0xFF503A2E,
          )
        : const Color(
            0xFF77543D,
          )
    ..strokeCap =
        StrokeCap.round
    ..style =
        PaintingStyle.stroke;

  /*
   * 左枝
   */
  final left = Path()
    ..moveTo(
      centerX - 4 * scale,
      groundY - 205 * scale,
    )
    ..cubicTo(
      centerX - 35 * scale,
      groundY - 240 * scale,
      centerX - 65 * scale,
      groundY - 270 * scale,
      centerX - 95 * scale,
      groundY - 320 * scale,
    );

  darkPaint.strokeWidth =
      20 * scale;

  lightPaint.strokeWidth =
      13 * scale;

  canvas.drawPath(
    left,
    darkPaint,
  );

  canvas.drawPath(
    left,
    lightPaint,
  );

  /*
   * 右枝
   */
  final right = Path()
    ..moveTo(
      centerX + 5 * scale,
      groundY - 212 * scale,
    )
    ..cubicTo(
      centerX + 38 * scale,
      groundY - 245 * scale,
      centerX + 68 * scale,
      groundY - 275 * scale,
      centerX + 96 * scale,
      groundY - 325 * scale,
    );

  darkPaint.strokeWidth =
      17 * scale;

  lightPaint.strokeWidth =
      10 * scale;

  canvas.drawPath(
    right,
    darkPaint,
  );

  canvas.drawPath(
    right,
    lightPaint,
  );

  /*
   * 中间向上的枝
   */
  final upper = Path()
    ..moveTo(
      centerX,
      groundY - 225 * scale,
    )
    ..cubicTo(
      centerX - 5 * scale,
      groundY - 270 * scale,
      centerX + 4 * scale,
      groundY - 330 * scale,
      centerX + 15 * scale,
      groundY - 385 * scale,
    );

  darkPaint.strokeWidth =
      14 * scale;

  lightPaint.strokeWidth =
      8 * scale;

  canvas.drawPath(
    upper,
    darkPaint,
  );

  canvas.drawPath(
    upper,
    lightPaint,
  );
}

void _drawCanopy(
  Canvas canvas,
  double centerX,
  double centerY,
  double scale,
) {
  /*
   * ==================================================
   * 唯一的大圆树冠
   * ==================================================
   *
   * 没有 LeafCluster。
   * 没有多个小圆。
   * 没有云朵。
   *
   * 就一个圆。
   */

  final radius =
      150.0 * scale;

  final center = Offset(
    centerX,
    centerY,
  );

  /*
   * 圆下面轻微的整体阴影。
   *
   * 这是树冠阴影，
   * 不是第二团树叶。
   */
  final shadowPaint = Paint()
    ..color = isNight
        ? const Color(
            0x4806100B,
          )
        : const Color(
            0x300D2817,
          );

  canvas.drawCircle(
    Offset(
      center.dx +
          6 * scale,
      center.dy +
          8 * scale,
    ),
    radius,
    shadowPaint,
  );

  /*
   * 真正唯一的树冠。
   */
  final crownRect =
      Rect.fromCircle(
    center:
        center,
    radius:
        radius,
  );

  final crownPaint = Paint()
    ..shader = RadialGradient(
      center:
          const Alignment(
        -0.34,
        -0.38,
      ),
      radius:
          1.16,
      colors: isNight
          ? const [
              Color(
                0xFF71836A,
              ),
              Color(
                0xFF566E54,
              ),
              Color(
                0xFF3D563F,
              ),
              Color(
                0xFF293B30,
              ),
            ]
          : const [
              Color(
                0xFFA2BD82,
              ),
              Color(
                0xFF86A66C,
              ),
              Color(
                0xFF668853,
              ),
              Color(
                0xFF4B6C42,
              ),
            ],
      stops:
          const [
        0.0,
        0.36,
        0.72,
        1.0,
      ],
    ).createShader(
      crownRect,
    );

  canvas.drawCircle(
    center,
    radius,
    crownPaint,
  );

  /*
   * 一个圆形外轮廓。
   */
  final outlinePaint = Paint()
    ..color = isNight
        ? const Color(
            0x77314235,
          )
        : const Color(
            0x66465F39,
          )
    ..style =
        PaintingStyle.stroke
    ..strokeWidth =
        2.2 * scale;

  canvas.drawCircle(
    center,
    radius,
    outlinePaint,
  );
}

  void _drawBarkDetails(
  Canvas canvas,
  double centerX,
  double groundY,
  double scale,
) {
  final paint = Paint()
    ..color =
        const Color(
      0x447F634D,
    )
    ..style =
        PaintingStyle.stroke
    ..strokeWidth =
        3 * scale
    ..strokeCap =
        StrokeCap.round;

  final first = Path()
    ..moveTo(
      centerX - 11 * scale,
      groundY - 140 * scale,
    )
    ..quadraticBezierTo(
      centerX - 19 * scale,
      groundY - 115 * scale,
      centerX - 14 * scale,
      groundY - 90 * scale,
    );

  canvas.drawPath(
    first,
    paint,
  );

  final second = Path()
    ..moveTo(
      centerX + 13 * scale,
      groundY - 95 * scale,
    )
    ..quadraticBezierTo(
      centerX + 20 * scale,
      groundY - 73 * scale,
      centerX + 15 * scale,
      groundY - 48 * scale,
    );

  canvas.drawPath(
    second,
    paint,
  );
}

  void _drawGroundDetails(
    Canvas canvas,
    Size size,
    double groundY,
  ) {
    final grassPaint = Paint()
      ..color = const Color(0xFF71885B)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final grassPositions = [
      size.width * 0.10,
      size.width * 0.17,
      size.width * 0.80,
      size.width * 0.87,
      size.width * 0.92,
    ];

    for (final x in grassPositions) {
      canvas.drawLine(
        Offset(
          x,
          groundY + 5,
        ),
        Offset(
          x - 7,
          groundY - 13,
        ),
        grassPaint,
      );

      canvas.drawLine(
        Offset(
          x,
          groundY + 5,
        ),
        Offset(
          x + 5,
          groundY - 18,
        ),
        grassPaint,
      );
    }

    _drawFlower(
      canvas,
      Offset(
        size.width * 0.23,
        groundY + 8,
      ),
      const Color(0xFFF0D9A0),
    );

    _drawFlower(
      canvas,
      Offset(
        size.width * 0.75,
        groundY + 3,
      ),
      const Color(0xFFE8D6DC),
    );

    final stonePaint = Paint()
      ..color = const Color(0x667B816F);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          size.width * 0.31,
          groundY + 24,
        ),
        width: 23,
        height: 12,
      ),
      stonePaint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          size.width * 0.72,
          groundY + 30,
        ),
        width: 18,
        height: 10,
      ),
      stonePaint,
    );
  }

  void _drawFlower(
    Canvas canvas,
    Offset position,
    Color petalColor,
  ) {
    final stemPaint = Paint()
      ..color = const Color(0xFF6E8458)
      ..strokeWidth = 2;

    canvas.drawLine(
      position,
      Offset(
        position.dx,
        position.dy - 18,
      ),
      stemPaint,
    );

    final petalPaint = Paint()
      ..color = petalColor;

    final flowerCenter = Offset(
      position.dx,
      position.dy - 20,
    );

    canvas.drawCircle(
      Offset(
        flowerCenter.dx - 4,
        flowerCenter.dy,
      ),
      4,
      petalPaint,
    );

    canvas.drawCircle(
      Offset(
        flowerCenter.dx + 4,
        flowerCenter.dy,
      ),
      4,
      petalPaint,
    );

    canvas.drawCircle(
      Offset(
        flowerCenter.dx,
        flowerCenter.dy - 4,
      ),
      4,
      petalPaint,
    );

    canvas.drawCircle(
      Offset(
        flowerCenter.dx,
        flowerCenter.dy + 4,
      ),
      4,
      petalPaint,
    );

    final centerPaint = Paint()
      ..color = const Color(0xFFE0B75E);

    canvas.drawCircle(
      flowerCenter,
      2.5,
      centerPaint,
    );
  }

  void _drawSprout(
    Canvas canvas,
    Size size,
    double groundY,
  ) {
    final base = Offset(
      size.width * 0.57,
      groundY + 5,
    );

    final stemPaint = Paint()
      ..color = const Color(0xFF4E7243)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      base,
      Offset(
        base.dx,
        base.dy - 28,
      ),
      stemPaint,
    );

    final leafPaint = Paint()
      ..color = const Color(0xFF6F945C);

    final leftLeaf = Path()
      ..moveTo(
        base.dx,
        base.dy - 18,
      )
      ..quadraticBezierTo(
        base.dx - 18,
        base.dy - 31,
        base.dx - 22,
        base.dy - 18,
      )
      ..quadraticBezierTo(
        base.dx - 10,
        base.dy - 11,
        base.dx,
        base.dy - 18,
      )
      ..close();

    canvas.drawPath(
      leftLeaf,
      leafPaint,
    );

    final rightLeaf = Path()
      ..moveTo(
        base.dx,
        base.dy - 24,
      )
      ..quadraticBezierTo(
        base.dx + 19,
        base.dy - 39,
        base.dx + 23,
        base.dy - 25,
      )
      ..quadraticBezierTo(
        base.dx + 12,
        base.dy - 17,
        base.dx,
        base.dy - 24,
      )
      ..close();

    canvas.drawPath(
      rightLeaf,
      leafPaint,
    );

    final glowPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0x33FFF1B6),
          Color(0x00FFF1B6),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(
            base.dx,
            base.dy - 22,
          ),
          radius: 42,
        ),
      );

    canvas.drawCircle(
      Offset(
        base.dx,
        base.dy - 22,
      ),
      42,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant TimeCapsuleScenePainter oldDelegate,
  ) {
    return oldDelegate.animationValue !=
        animationValue ||
    oldDelegate.hasCapsules !=
        hasCapsules ||
    oldDelegate.isNight !=
        isNight ||
    oldDelegate.viewportWidth !=
        viewportWidth;
  }
}