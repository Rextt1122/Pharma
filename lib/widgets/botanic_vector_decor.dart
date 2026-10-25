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
    this.opacity = 0.08,
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

/// Mini brand stamp with pharmaceutical potted plant illustration and caption.
/// Perfect footer for Settings and About pages to create pleasant breathing room.
class PharmaBrandStamp extends StatelessWidget {
  const PharmaBrandStamp({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.md),
      child: Center(
        child: Opacity(
          opacity: 0.75,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: CustomPaint(
                  painter: _MiniPotPlantPainter(),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'PHARMA MEDIC',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.pharmaNavy,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Smart Cold Storage Monitoring',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniPotPlantPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Center Leaf
    final leafPaintCenter = Paint()
      ..color = const Color(0xFF3D8063)
      ..style = PaintingStyle.fill;
    final centerLeaf = Path()
      ..moveTo(w * 0.50, h * 0.58)
      ..quadraticBezierTo(w * 0.36, h * 0.26, w * 0.50, h * 0.06)
      ..quadraticBezierTo(w * 0.64, h * 0.26, w * 0.50, h * 0.58)
      ..close();
    canvas.drawPath(centerLeaf, leafPaintCenter);

    // Left Leaf
    final leafPaintLeft = Paint()
      ..color = const Color(0xFF56796C)
      ..style = PaintingStyle.fill;
    final leftLeaf = Path()
      ..moveTo(w * 0.46, h * 0.58)
      ..quadraticBezierTo(w * 0.16, h * 0.44, w * 0.20, h * 0.20)
      ..quadraticBezierTo(w * 0.42, h * 0.28, w * 0.48, h * 0.54)
      ..close();
    canvas.drawPath(leftLeaf, leafPaintLeft);

    // Right Leaf
    final leafPaintRight = Paint()
      ..color = const Color(0xFF6A9986)
      ..style = PaintingStyle.fill;
    final rightLeaf = Path()
      ..moveTo(w * 0.54, h * 0.58)
      ..quadraticBezierTo(w * 0.84, h * 0.44, w * 0.80, h * 0.20)
      ..quadraticBezierTo(w * 0.58, h * 0.28, w * 0.52, h * 0.54)
      ..close();
    canvas.drawPath(rightLeaf, leafPaintRight);

    // Pot
    final potPaint = Paint()
      ..color = AppColors.pharmaNavy.withAlpha(25)
      ..style = PaintingStyle.fill;
    final potStroke = Paint()
      ..color = AppColors.pharmaNavy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final potPath = Path()
      ..moveTo(w * 0.28, h * 0.56)
      ..lineTo(w * 0.72, h * 0.56)
      ..lineTo(w * 0.65, h * 0.88)
      ..quadraticBezierTo(w * 0.50, h * 0.94, w * 0.35, h * 0.88)
      ..close();
    canvas.drawPath(potPath, potPaint);
    canvas.drawPath(potPath, potStroke);

    // Rim
    canvas.drawLine(
      Offset(w * 0.25, h * 0.56),
      Offset(w * 0.75, h * 0.56),
      potStroke..strokeWidth = 1.5,
    );
    potStroke.strokeWidth = 1.3;

    // Cross on Pot
    final crossPaint = Paint()
      ..color = AppColors.pharmaNavy
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.50, h * 0.73), width: 2.2, height: 7.0),
        const Radius.circular(1.0),
      ),
      crossPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.50, h * 0.73), width: 7.0, height: 2.2),
        const Radius.circular(1.0),
      ),
      crossPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Subtle organic corner leaf accent for dialog sheets.
class ModalSheetTopDecor extends StatelessWidget {
  final Widget child;

  const ModalSheetTopDecor({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          right: 0,
          child: IgnorePointer(
            child: SizedBox(
              width: 80,
              height: 80,
              child: CustomPaint(
                painter: _CornerLeavesPainter(),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _CornerLeavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final leafPaint = Paint()
      ..color = AppColors.pharmaTeal.withAlpha(24)
      ..style = PaintingStyle.fill;

    final leafPaint2 = Paint()
      ..color = AppColors.pharmaNavy.withAlpha(16)
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(size.width, 0)
      ..quadraticBezierTo(size.width * 0.40, size.height * 0.12, size.width * 0.35, size.height * 0.65)
      ..quadraticBezierTo(size.width * 0.70, size.height * 0.40, size.width, 0)
      ..close();
    canvas.drawPath(path1, leafPaint);

    final path2 = Path()
      ..moveTo(size.width, size.height * 0.18)
      ..quadraticBezierTo(size.width * 0.60, size.height * 0.42, size.width * 0.55, size.height * 0.85)
      ..quadraticBezierTo(size.width * 0.82, size.height * 0.68, size.width, size.height * 0.18)
      ..close();
    canvas.drawPath(path2, leafPaint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
