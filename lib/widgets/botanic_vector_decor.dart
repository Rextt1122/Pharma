import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Clean, subtle medical botanic vector watermark for card backgrounds.
/// Clean lines, low contrast, zero clutter.
class BotanicVectorCardWatermark extends StatelessWidget {
  final Widget child;
  final Alignment alignment;
  final double opacity;
  final double size;

  const BotanicVectorCardWatermark({
    super.key,
    required this.child,
    this.alignment = Alignment.topRight,
    this.opacity = 0.045,
    this.size = 110,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Align(
            alignment: alignment,
            child: IgnorePointer(
              child: Opacity(
                opacity: opacity,
                child: SizedBox(
                  width: size,
                  height: size,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _BotanicVectorPainter(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _BotanicVectorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = AppColors.pharmaNavy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = AppColors.pharmaTeal
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Elegant arching medical herb stem
    final stem = Path()
      ..moveTo(w * 0.15, h * 0.95)
      ..quadraticBezierTo(w * 0.50, h * 0.55, w * 0.85, h * 0.15);
    canvas.drawPath(stem, strokePaint);

    // Leaf pair 1 (lower)
    _drawLeaf(canvas, w * 0.35, h * 0.72, -0.65, 24, 11, strokePaint, fillPaint);
    _drawLeaf(canvas, w * 0.42, h * 0.65, 0.75, 22, 10, strokePaint, fillPaint);

    // Leaf pair 2 (middle)
    _drawLeaf(canvas, w * 0.56, h * 0.48, -0.70, 26, 12, strokePaint, fillPaint);
    _drawLeaf(canvas, w * 0.64, h * 0.40, 0.68, 24, 11, strokePaint, fillPaint);

    // Top terminal leaf (apical bud)
    _drawLeaf(canvas, w * 0.85, h * 0.15, 0.82, 28, 12, strokePaint, fillPaint);
  }

  void _drawLeaf(
    Canvas canvas,
    double x,
    double y,
    double angle,
    double length,
    double width,
    Paint stroke,
    Paint fill,
  ) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);

    final leaf = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(length * 0.45, -width * 0.85, length, 0)
      ..quadraticBezierTo(length * 0.45, width * 0.85, 0, 0)
      ..close();

    canvas.drawPath(leaf, fill);
    canvas.drawPath(leaf, stroke);

    // Center vein
    canvas.drawLine(
      Offset.zero,
      Offset(length * 0.75, 0),
      stroke..strokeWidth = 1.0,
    );
    stroke.strokeWidth = 1.8; // restore

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
