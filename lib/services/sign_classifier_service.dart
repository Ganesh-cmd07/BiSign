import 'dart:math';
import 'package:flutter/material.dart';

/// SignClassifierService
/// Phase A: Returns mock sign classifications for UI testing.
/// Phase B: Will load and run a real TFLite model on landmarks.
class SignClassifierService {
  bool _isInitialized = false;
  final Random _rng = Random();

  // Mock ISL signs for Phase A testing
  static const List<String> _mockSigns = [
    'Hello', 'Water', 'Food', 'Help',
    'Yes', 'No', 'Thank You', 'Please',
    'Mother', 'Father', 'Doctor', 'Pain',
    'Home', 'School', 'Bus', 'Money',
    'Good', 'Bad', 'Stop', 'Come',
  ];

  Future<void> initialize() async {
    // PHASE A — No model loaded yet
    // PHASE B — Load TFLite model:
    //   _interpreter = await Interpreter.fromAsset('assets/models/isl_classifier.tflite');
    _isInitialized = true;
    debugPrint('SignClassifier: Phase A mock initialized');
  }

  /// Returns {sign: String, confidence: double}
  Future<Map<String, dynamic>> classify(List<List<double>> landmarks) async {
    if (!_isInitialized) {
      return {'sign': '', 'confidence': 0.0};
    }

    // PHASE A — return random sign with moderate confidence
    // PHASE B — Run TFLite inference on flattened landmark vector

    // Simulate processing delay (real model is ~5-15ms)
    await Future.delayed(const Duration(milliseconds: 10));

    final sign = _mockSigns[_rng.nextInt(_mockSigns.length)];
    final confidence = 0.70 + _rng.nextDouble() * 0.25;

    return {
      'sign': sign,
      'confidence': confidence,
    };
  }

  void dispose() {
    // PHASE B: _interpreter?.close();
  }
}
