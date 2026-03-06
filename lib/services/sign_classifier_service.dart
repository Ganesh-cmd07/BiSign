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
      _interpreter = await Interpreter.fromAsset('assets/models/sign_classifier.tflite');
      String labelData = await rootBundle.loadString('assets/models/labels.txt');
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

    // Flatten landmarks. Assuming landmarks list has 21 points with x, y, z.
    // Our TFLite model accepts 42 floats.
    List<double> inputFeatures = [];
    for (var lm in landmarks) {
      if (inputFeatures.length < 42) {
         inputFeatures.add(lm[0]); // x
         inputFeatures.add(lm[1]); // y
      }
    }
    
    // Pad if not 42
    while(inputFeatures.length < 42) {
      inputFeatures.add(0.0);
    }

    var input = [inputFeatures];
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
