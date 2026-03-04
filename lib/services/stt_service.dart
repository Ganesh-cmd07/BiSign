import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

/// SttService — Speech To Text using Vosk offline ASR
/// Phase A: Returns mock text for UI testing.
/// Phase C: Will use vosk_flutter with downloaded Vosk model.
class SttService {
  bool _isInitialized = false;
  bool _isListening = false;
  String _language = 'te';

  Future<void> initialize(String languageCode) async {
    _language = languageCode;

    // Phase C: Initialize Vosk model
    // final modelPath = await _getModelPath();
    // _model = VoskFlutterPlugin.instance();
    // await _model.initModel(modelPath);

    _isInitialized = true;
    debugPrint('SttService: Phase A mock initialized for $_language');
  }

  Future<void> startListening({
    required String language,
    required Function(String) onResult,
    required Function(String) onDone,
  }) async {
    if (!_isInitialized || _isListening) return;
    _isListening = true;
    _language = language;

    // Phase A: Simulate STT with mock text after 2 seconds
    // Phase C: Use Vosk real-time recognition
    await Future.delayed(const Duration(milliseconds: 500));

    // Simulate partial results
    final mockResults = _getMockResults(language);
    for (int i = 0; i < mockResults.length; i++) {
      if (!_isListening) break;
      await Future.delayed(const Duration(milliseconds: 600));
      onResult(mockResults.sublist(0, i + 1).join(' '));
    }

    if (_isListening) {
      final finalText = mockResults.join(' ');
      onDone(finalText);
      _isListening = false;
    }
  }

  Future<void> stopListening() async {
    _isListening = false;
    // Phase C: await _vosk.stop();
  }

  List<String> _getMockResults(String lang) {
    // Return mock phrases per language for Phase A testing
    switch (lang) {
      case 'te':
        return ['నాకు', 'నీళ్ళు', 'కావాలి']; // I want water
      case 'hi':
        return ['मुझे', 'पानी', 'चाहिए']; // I want water
      case 'ta':
        return ['எனக்கு', 'தண்ணீர்', 'வேண்டும்']; // I want water
      case 'kn':
        return ['ನನಗೆ', 'ನೀರು', 'ಬೇಕು']; // I want water
      default:
        return ['I', 'want', 'water']; // English fallback
    }
  }

  void dispose() {
    _isListening = false;
    // Phase C: _vosk?.dispose();
  }
}
