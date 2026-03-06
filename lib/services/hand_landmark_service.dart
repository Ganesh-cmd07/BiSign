import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

/// HandLandmarkService
/// Phase B implementation. Extracts 21 hand landmarks per hand
/// from the live camera feed using Google MediaPipe Hand Landmarker via hand_landmarker plugin.
class HandLandmarkService {
  HandLandmarkerPlugin? _landmarker;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Create the hand landmarker plugin.
    // By default it uses GPU and detects up to 2 hands.
    _landmarker = HandLandmarkerPlugin.create(
      numHands: 1, // Phase 1 focus: Single hand signs
      minHandDetectionConfidence: 0.5,
      delegate: HandLandmarkerDelegate.gpu,
    );
    
    _isInitialized = true;
  }

  Future<List<List<double>>> extractLandmarks(CameraImage image, int sensorOrientation) async {
    if (!_isInitialized || _landmarker == null) {
      await initialize();
    }

    try {
      // Detect hands in the frame
      final List<Hand> hands = _landmarker!.detect(image, sensorOrientation);

      if (hands.isEmpty) {
        return [];
      }

      // Return the landmarks for the first detected hand
      // Each landmark is a list of [x, y, z]
      return hands.first.landmarks.map((lm) => [lm.x, lm.y, lm.z]).toList();
    } catch (e) {
      debugPrint('HandLandmarkService error: $e');
      return [];
    }
  }

  void dispose() {
    _landmarker?.dispose();
    _isInitialized = false;
  }
}
