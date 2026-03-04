import 'dart:math';
import 'package:camera/camera.dart';

/// HandLandmarkService
/// Phase A: Returns mock landmark data for UI testing.
/// Phase B: Will use MediaPipe Hands via platform channel or tflite.
class HandLandmarkService {
  final Random _rng = Random();

  /// Returns 21 landmarks [x, y, z] for one hand (mock data in Phase A).
  Future<List<List<double>>> extractLandmarks(CameraImage image) async {
    // PHASE A — Mock: return fake hand landmarks for UI smoke testing
    // PHASE B — Replace with MediaPipe Hands inference

    // Simulate occasional "no hand detected" (20% chance)
    if (_rng.nextDouble() < 0.2) return [];

    // Generate 21 normalized landmarks (x: 0-1, y: 0-1, z: -0.1 to 0.1)
    return List.generate(21, (i) {
      return [
        0.3 + _rng.nextDouble() * 0.4, // x
        0.2 + _rng.nextDouble() * 0.6, // y
        (_rng.nextDouble() - 0.5) * 0.2, // z
      ];
    });
  }
}
