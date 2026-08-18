import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'pet_animation_state.dart';

class PetActor extends StatefulWidget {
  const PetActor({
    super.key,
    this.visualSize = 92,
    this.hitSize = 108,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onTap,
  });

  final double visualSize;
  final double hitSize;
  final ValueChanged<Offset> onDragUpdate;
  final VoidCallback onDragEnd;
  final VoidCallback onTap;

  @override
  State<PetActor> createState() => _PetActorState();
}

class _PetActorState extends State<PetActor>
    with SingleTickerProviderStateMixin {
  final _random = math.Random();
  late final AnimationController _controller;

  PetAnimationState _state = PetAnimationState.idle;
  Timer? _behaviorTimer;
  Timer? _sleepTimer;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _scheduleBehavior();
  }

  @override
  void dispose() {
    _behaviorTimer?.cancel();
    _sleepTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleBehavior() {
    _behaviorTimer?.cancel();
    _behaviorTimer = Timer(Duration(seconds: 3 + _random.nextInt(4)), () {
      if (!mounted || _dragging) return;

      final next = _random.nextInt(4);
      if (next == 0) {
        _playTransient(
          PetAnimationState.blink,
          const Duration(milliseconds: 500),
        );
      } else if (next == 1) {
        _playTransient(
          PetAnimationState.happy,
          const Duration(milliseconds: 900),
        );
      } else {
        _setActorState(PetAnimationState.idle);
      }

      _scheduleBehavior();
    });

    _sleepTimer?.cancel();
    _sleepTimer = Timer(const Duration(seconds: 24), () {
      if (!mounted || _dragging) return;
      _setActorState(PetAnimationState.sleep);
    });
  }

  void _setActorState(PetAnimationState value) {
    if (!mounted) return;
    setState(() => _state = value);
  }

  void _playTransient(PetAnimationState value, Duration duration) {
    _setActorState(value);

    Future<void>.delayed(duration, () {
      if (!mounted || _dragging) return;
      _setActorState(PetAnimationState.idle);
    });
  }

  void _startDrag(DragStartDetails details) {
    _behaviorTimer?.cancel();
    _sleepTimer?.cancel();

    setState(() {
      _dragging = true;
      _state = PetAnimationState.drag;
    });
  }

  void _updateDrag(DragUpdateDetails details) {
    widget.onDragUpdate(details.delta);
  }

  void _finishDrag() {
    if (!_dragging) return;

    setState(() {
      _dragging = false;
      _state = PetAnimationState.land;
    });

    widget.onDragEnd();

    Future<void>.delayed(const Duration(milliseconds: 550), () {
      if (!mounted || _dragging) return;
      _setActorState(PetAnimationState.idle);
    });

    _scheduleBehavior();
  }

  void _tapPet() {
    if (_dragging) return;

    _playTransient(
      PetAnimationState.touched,
      const Duration(milliseconds: 900),
    );
    widget.onTap();
    _scheduleBehavior();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: widget.hitSize,
    height: widget.hitSize,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      dragStartBehavior: DragStartBehavior.down,
      onTap: _tapPet,
      onPanStart: _startDrag,
      onPanUpdate: _updateDrag,
      onPanEnd: (_) => _finishDrag(),
      onPanCancel: _finishDrag,
      child: Center(
        child: SizedBox(
          width: widget.visualSize,
          height: widget.visualSize,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _MochiPainter(
                state: _state,
                phase: _controller.value * math.pi * 2,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _MochiPainter extends CustomPainter {
  const _MochiPainter({required this.state, required this.phase});

  final PetAnimationState state;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final breath = math.sin(phase) * 0.018;
    final tailSwing = math.sin(phase * 1.15) * 0.22;

    final blink =
        state == PetAnimationState.blink || state == PetAnimationState.sleep;
    final happy =
        state == PetAnimationState.happy || state == PetAnimationState.touched;
    final dragging = state == PetAnimationState.drag;
    final sleeping = state == PetAnimationState.sleep;

    canvas.save();

    if (dragging) {
      canvas.translate(s * 0.02, s * 0.03);
      canvas.rotate(-0.08);
    } else if (state == PetAnimationState.land) {
      canvas.scale(1.03, 0.97);
      canvas.translate(-s * 0.015, s * 0.02);
    }

    final shadow = Paint()
      ..color = const Color(0x22000000)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.04);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s * 0.52, s * 0.88),
        width: s * 0.54,
        height: s * 0.10,
      ),
      shadow,
    );

    canvas.save();
    canvas.translate(s * 0.72, s * 0.64);
    canvas.rotate(tailSwing + (sleeping ? 0.25 : 0));

    final tailRect = Rect.fromCenter(
      center: Offset(s * 0.08, 0),
      width: s * 0.42,
      height: s * 0.62,
    );

    final tailPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFFFF), Color(0xFFE8D7FF), Color(0xFFC4A2F4)],
      ).createShader(tailRect);

    canvas.drawOval(tailRect, tailPaint);

    canvas.drawOval(
      tailRect.deflate(s * 0.045),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.025
        ..color = const Color(0x55FFFFFF),
    );

    canvas.restore();

    final bodyCenter = sleeping
        ? Offset(s * 0.48, s * 0.68)
        : Offset(s * 0.48, s * (0.69 + breath));

    final bodyRect = Rect.fromCenter(
      center: bodyCenter,
      width: s * 0.52,
      height: sleeping ? s * 0.28 : s * 0.42,
    );

    final fur = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFF9F6FF), Color(0xFFE5D5FA)],
      ).createShader(bodyRect);

    canvas.drawOval(bodyRect, fur);

    if (!sleeping) {
      for (final dx in [-0.12, 0.12]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(s * (0.48 + dx), s * 0.84),
            width: s * 0.16,
            height: s * 0.12,
          ),
          fur,
        );
      }
    }

    final headCenter = sleeping
        ? Offset(s * 0.38, s * 0.60)
        : Offset(s * 0.42, s * (0.39 + breath));

    final headRect = Rect.fromCenter(
      center: headCenter,
      width: s * 0.58,
      height: s * 0.54,
    );

    canvas.drawOval(headRect, fur);

    final earPaint = Paint()..color = const Color(0xFFFFFAFF);
    final innerEar = Paint()..color = const Color(0xFFFFB7D1);

    Path ear(double side) => Path()
      ..moveTo(s * (0.42 + side * 0.16), s * 0.19)
      ..lineTo(s * (0.42 + side * 0.34), s * 0.03)
      ..lineTo(s * (0.42 + side * 0.28), s * 0.34)
      ..close();

    Path inner(double side) => Path()
      ..moveTo(s * (0.42 + side * 0.17), s * 0.19)
      ..lineTo(s * (0.42 + side * 0.29), s * 0.08)
      ..lineTo(s * (0.42 + side * 0.25), s * 0.28)
      ..close();

    canvas.drawPath(ear(-1), earPaint);
    canvas.drawPath(ear(1), earPaint);
    canvas.drawPath(inner(-1), innerEar);
    canvas.drawPath(inner(1), innerEar);

    final eyeY = s * (sleeping ? 0.61 : 0.39);

    for (final side in [-1.0, 1.0]) {
      final eyeX = s * (0.42 + side * 0.12);

      if (blink || sleeping) {
        final eyePaint = Paint()
          ..color = const Color(0xFF5A347A)
          ..strokeWidth = s * 0.022
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(eyeX, eyeY),
            width: s * 0.10,
            height: s * 0.06,
          ),
          0.12,
          math.pi - 0.24,
          false,
          eyePaint,
        );
      } else {
        canvas.drawCircle(
          Offset(eyeX, eyeY),
          s * 0.065,
          Paint()
            ..shader =
                RadialGradient(
                  colors: const [
                    Color(0xFFB87CFF),
                    Color(0xFF6736A8),
                    Color(0xFF2C174C),
                  ],
                ).createShader(
                  Rect.fromCircle(
                    center: Offset(eyeX, eyeY),
                    radius: s * 0.065,
                  ),
                ),
        );

        canvas.drawCircle(
          Offset(eyeX - s * 0.018, eyeY - s * 0.022),
          s * 0.018,
          Paint()..color = Colors.white,
        );
      }
    }

    final noseY = s * (sleeping ? 0.66 : 0.49);

    canvas.drawCircle(
      Offset(s * 0.42, noseY),
      s * 0.018,
      Paint()..color = const Color(0xFFFF8FAE),
    );

    if (happy && !sleeping) {
      final mouth = Paint()
        ..color = const Color(0xFF9C4A72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.018
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(s * 0.42, s * 0.535),
          width: s * 0.11,
          height: s * 0.08,
        ),
        0,
        math.pi,
        false,
        mouth,
      );
    }

    canvas.drawCircle(
      Offset(s * 0.26, s * 0.50),
      s * 0.034,
      Paint()..color = const Color(0x33FF7FA8),
    );

    canvas.drawCircle(
      Offset(s * 0.58, s * 0.50),
      s * 0.034,
      Paint()..color = const Color(0x33FF7FA8),
    );

    final collarY = sleeping ? s * 0.72 : s * 0.60;

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(s * 0.42, collarY),
        width: s * 0.30,
        height: s * 0.12,
      ),
      0.10,
      math.pi - 0.20,
      false,
      Paint()
        ..color = const Color(0xFF8150D5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.035,
    );

    canvas.drawCircle(
      Offset(s * 0.42, collarY + s * 0.05),
      s * 0.033,
      Paint()..color = const Color(0xFFFFC94B),
    );

    if (happy && !sleeping) {
      final heart = Path()
        ..moveTo(s * 0.68, s * 0.18)
        ..cubicTo(s * 0.62, s * 0.12, s * 0.54, s * 0.20, s * 0.68, s * 0.30)
        ..cubicTo(s * 0.82, s * 0.20, s * 0.74, s * 0.12, s * 0.68, s * 0.18)
        ..close();

      canvas.drawPath(heart, Paint()..color = const Color(0xFFFF6FA1));
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MochiPainter oldDelegate) =>
      oldDelegate.state != state || oldDelegate.phase != phase;
}
