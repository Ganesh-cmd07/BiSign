import '../utils/constants.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/material.dart';

/// SignClassifierService
/// Phase B implementation. Loads the TFLite ISL signature classifier
/// and passes the 42 coordinate array for interpretation.
class SignClassifierService {
  List<String> _labels = [];
  bool _isInitialized = false;
  Interpreter? _interpreter;

  Future<void> initialize() async {
    try {
      _interpreter = await Interpreter.fromAsset(AppConstants.tfliteModelPath);
      String labelData = await rootBundle.loadString('${AppConstants.modelsAssetPath}labels.txt');
      _labels = labelData.split('\n').where((s) => s.trim().isNotEmpty).toList();
      _isInitialized = true;
      debugPrint("TFLite Model Loaded. Labels: ${_labels.length}");
    } catch (e) {
      _isInitialized = false;
      debugPrint('TFLite init error: $e');
    }
  }

  Future<Map<String, dynamic>> classify(List<List<double>> landmarks) async {
    if (!_isInitialized || _interpreter == null || _labels.isEmpty) {
      return {'sign': '', 'confidence': 0.0};
    }

    // Prepare input: 21 landmarks × (x, y) = 42 features
    // Must match normalization in train_isl_classifier.py
    if (landmarks.isEmpty) return {'sign': '', 'confidence': 0.0};

    // Wrist is index 0
    double wristX = landmarks[0][0];
    double wristY = landmarks[0][1];

    List<double> normalized = [];
    double maxSpan = 0.00001;

    // First pass: wrist-relative and find max span
    List<List<double>> relative = [];
    for (var lm in landmarks) {
      double rx = lm[0] - wristX;
      double ry = lm[1] - wristY;
      relative.add([rx, ry]);
      if (rx.abs() > maxSpan) maxSpan = rx.abs();
      if (ry.abs() > maxSpan) maxSpan = ry.abs();
    }

    // Second pass: scale normalize and flatten
    for (var rel in relative) {
      normalized.add(rel[0] / maxSpan);
      normalized.add(rel[1] / maxSpan);
    }

    // Ensure exactly 42 features
    while (normalized.length < 42) {
      normalized.add(0.0);
    }
    if (normalized.length > 42) {
      normalized = normalized.sublist(0, 42);
    }

    var input = [normalized];
    var output = List<double>.filled(_labels.length, 0).reshape([1, _labels.length]);

    try {
      _interpreter!.run(input, output);
      
      List<double> probabilities = (output[0] as List).cast<double>();
      
      double maxProb = 0.0;
      int maxIndex = -1;
      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          maxIndex = i;
        }
      }
      
      if (maxIndex != -1) {
        return {
          'sign': _labels[maxIndex],
          'confidence': maxProb,
        };
      }
    } catch (e) {
      debugPrint('Classification error: $e');
    }

    return {'sign': '', 'confidence': 0.0};
  }
}
