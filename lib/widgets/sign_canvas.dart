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
            frameData: frames.first as Map<String, dynamic>,
            isAnimating: isAnimating,
          ),
        );
      },
    );
  }
}

class _SignPainter extends CustomPainter {
  final Map<String, dynamic> frameData;
  final bool isAnimating;

  _SignPainter({required this.frameData, required this.isAnimating});

  // MediaPipe hand connection pairs for drawing the 3D skeleton mapping
  static const List<List<int>> connections = [
    [0, 1], [1, 2], [2, 3], [3, 4],       // Thumb
    [0, 5], [5, 6], [6, 7], [7, 8],       // Index
    [9, 10], [10, 11], [11, 12],          // Middle
    [13, 14], [14, 15], [15, 16],         // Ring
    [17, 18], [18, 19], [19, 20],         // Pinky
    [5, 9], [9, 13], [13, 17], [0, 17]    // Palm base
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    final bgPaint = Paint()..color = AppTheme.surface;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Render left hand skeleton if available
    if (frameData.containsKey('left_hand') && frameData['left_hand'] != null) {
      _drawHandSkeleton(canvas, size, frameData['left_hand'] as List, true);
    }
    
    // Render right hand skeleton if available
    if (frameData.containsKey('right_hand') && frameData['right_hand'] != null) {
      _drawHandSkeleton(canvas, size, frameData['right_hand'] as List, false);
    }
  }

  void _drawHandSkeleton(Canvas canvas, Size size, List landmarks, bool isLeft) {
    if (landmarks.isEmpty || landmarks.length < 21) return;

    final color = isLeft ? AppTheme.direction2 : AppTheme.direction1;
    
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Scale 0.0-1.0 normalized JSON coordinates to physical canvas size
    List<Offset> points = [];
    for (var lm in landmarks) {
      double x = (lm[0] as num).toDouble() * size.width;
      double y = (lm[1] as num).toDouble() * size.height;
      points.add(Offset(x, y));
    }

    // Draw connecting skeleton bones
    for (var connection in connections) {
      if (connection[0] < points.length && connection[1] < points.length) {
        final p1 = points[connection[0]];
        final p2 = points[connection[1]];
        canvas.drawLine(p1, p2, linePaint);
      }
    }

    // Draw individual joint nodes
    for (var point in points) {
      canvas.drawCircle(point, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignPainter oldDelegate) {
    return isAnimating; 
  }
}
