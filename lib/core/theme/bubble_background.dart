import 'dart:math';
import 'package:flutter/material.dart';
import 'colors.dart';

class BubbleBackground extends StatefulWidget {
  const BubbleBackground({Key? key}) : super(key: key);

  @override
  State<BubbleBackground> createState() => _BubbleBackgroundState();
}

class _BubbleBackgroundState extends State<BubbleBackground> with TickerProviderStateMixin {
  final Random _random = Random();
  final List<BubbleInfo> _bubbles = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 18; i++) {
      _bubbles.add(BubbleInfo(
        x: _random.nextDouble(),
        size: _random.nextDouble() * 24 + 6,
        duration: Duration(seconds: _random.nextInt(14) + 10),
        delay: Duration(seconds: _random.nextInt(12)),
        opacity: _random.nextDouble() * 0.4 + 0.05,
        vsync: this,
      ));
      _bubbles[i].controller.forward();
    }
  }

  @override
  void dispose() {
    for (var b in _bubbles) {
      b.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DoryColors.bg,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _GradientsPainter(),
            ),
          ),
          ..._bubbles.map((b) {
            return AnimatedBuilder(
              animation: b.controller,
              builder: (context, child) {
                final progress = b.controller.value;
                final y = 1.2 - (progress * 1.5);
                final x = b.x + (progress * 0.1);
                return Positioned(
                  left: MediaQuery.of(context).size.width * x,
                  top: MediaQuery.of(context).size.height * y,
                  child: Opacity(
                    opacity: b.opacity,
                    child: Container(
                      width: b.size,
                      height: b.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: DoryColors.surface,
                        border: Border.all(color: DoryColors.surface2),
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _GradientsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [DoryColors.primary.withOpacity(0.07), Colors.transparent],
        stops: const [0.0, 0.6],
        center: const Alignment(-0.6, 0.6),
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint1);

    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [DoryColors.accent.withOpacity(0.04), Colors.transparent],
        stops: const [0.0, 0.6],
        center: const Alignment(0.6, -0.6),
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint2);

    final paint3 = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF000514).withOpacity(0.8), Colors.transparent],
        stops: const [0.0, 0.7],
        center: const Alignment(0.0, 1.0),
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BubbleInfo {
  final double x;
  final double size;
  final Duration duration;
  final Duration delay;
  final double opacity;
  late final AnimationController controller;
  bool isDisposed = false;

  BubbleInfo({
    required this.x,
    required this.size,
    required this.duration,
    required this.delay,
    required this.opacity,
    required TickerProvider vsync,
  }) {
    controller = AnimationController(vsync: vsync, duration: duration);
    Future.delayed(delay, () {
      if (!isDisposed) {
        controller.repeat();
      }
    });
  }

  void dispose() {
    isDisposed = true;
    controller.dispose();
  }
}
