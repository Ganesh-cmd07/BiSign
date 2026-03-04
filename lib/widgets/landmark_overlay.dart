import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

/// LandmarkOverlay
/// Draws hand skeleton on top of camera preview.
/// Phase A: Draws mock landmarks for UI testing.
/// Phase B: Will draw real MediaPipe landmarks from camera stream.
class LandmarkOverlay extends StatelessWidget {
  final List<List<double>> landmarks;

  const LandmarkOverlay({super.key, required this.landmarks});

  // MediaPipe Hands connections (pairs of landmark indices)
  static const List<List<int>> _connections = [
    [0, 1], [1, 2], [2, 3], [3, 4],       // Thumb
    [0, 5], [5, 6], [6, 7], [7, 8],       // Index
    [0, 9], [9, 10], [10, 11], [11, 12],  // Middle
    [0, 13], [13, 14], [14, 15], [15, 16], // Ring
    [0, 17], [17, 18], [18, 19], [19, 20], // Pinky
    [5, 9], [9, 13], [13, 17],             // Palm
  ];

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LandmarkPainter(landmarks: landmarks),
      size: Size.infinite,
    );
  }
}

class _LandmarkPainter extends CustomPainter {
  final List<List<double>> landmarks;

  _LandmarkPainter({required this.landmarks});

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.isEmpty || landmarks.length < 21) return;

    final connectionPaint = Paint()
      ..color = AppTheme.primary.withOpacity(0.8)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = AppTheme.secondary
      ..style = PaintingStyle.fill;

    final tipPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Fingertip indices (4=thumb, 8=index, 12=middle, 16=ring, 20=pinky)
    const tipIndices = {4, 8, 12, 16, 20};

    // Convert normalized coords to screen coords
    Offset toScreen(List<double> lm) {
      return Offset(lm[0] * size.width, lm[1] * size.height);
    }

    // Draw connections
    for (final conn in LandmarkOverlay._connections) {
      if (conn[0] < landmarks.length && conn[1] < landmarks.length) {
        canvas.drawLine(
          toScreen(landmarks[conn[0]]),
          toScreen(landmarks[conn[1]]),
          connectionPaint,
        );
      }
    }

    // Draw landmark dots
    for (int i = 0; i < landmarks.length; i++) {
      final pos = toScreen(landmarks[i]);
      final isTip = tipIndices.contains(i);
      final radius = isTip ? 7.0 : 4.5;

      // Glow effect for tips
      if (isTip) {
        canvas.drawCircle(
          pos,
          radius + 4,
          Paint()
            ..color = AppTheme.secondary.withOpacity(0.2)
            ..style = PaintingStyle.fill,
        );
      }

      canvas.drawCircle(pos, radius, isTip ? tipPaint : dotPaint);
    }

    // Wrist special marker
    final wristPos = toScreen(landmarks[0]);
    canvas.drawCircle(
      wristPos,
      6,
      Paint()
        ..color = AppTheme.primary
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _LandmarkPainter oldDelegate) {
    return oldDelegate.landmarks != landmarks;
  }
}
