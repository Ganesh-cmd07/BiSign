import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class SignCanvas extends StatelessWidget {
  final List<dynamic> frames;
  final bool isAnimating;

  const SignCanvas({
    super.key,
    required this.frames,
    required this.isAnimating,
  });

  @override
  Widget build(BuildContext context) {
    if (frames.isEmpty) {
      return Container();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _SignPainter(
            frameData: frames.first, // Just drawing first frame for now
          ),
        );
      },
    );
  }
}

class _SignPainter extends CustomPainter {
  final Map<String, dynamic> frameData;

  _SignPainter({required this.frameData});

  @override
  void paint(Canvas canvas, Size size) {
    // Basic mock painter for now. Real implementation will draw 42 landmarks
    final paint = Paint()
      ..color = AppTheme.secondary
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final outlinePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw a placeholder circle in the middle to confirm it's working
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, 50, paint);
    canvas.drawCircle(center, 50, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
