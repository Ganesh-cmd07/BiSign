import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

/// SttService
/// Phase C implementation using offline continuous Speech-to-Text via vosk_flutter.
class SttService {
  final VoskFlutterPlugin _vosk = VoskFlutterPlugin.instance();
  Model? _model;
  Recognizer? _recognizer;
  SpeechService? _speechService;
  bool _isListening = false;

  Future<void> initialize(String languageCode) async {
    try {
      // Phase C: Initialize Vosk plugin and load localized acoustic models 
      // from assets/vosk/...
      String modelPath = await ModelLoader()
          .loadFromAssets('assets/vosk/model-hi.zip');
      _model = await _vosk.createModel(modelPath);
      _recognizer = await _vosk.createRecognizer(model: _model!, sampleRate: 16000);
      debugPrint('Vosk Model Init Success!');
    } catch (e) {
      debugPrint('Vosk Error compiling/loading: $e');
    }
  }

  Future<void> startListening({
    required String language,
    required Function(String) onResult,
    required Function(String) onDone,
  }) async {
    if (_isListening || _recognizer == null) return;
    _isListening = true;

    try {
      _speechService = await _vosk.initSpeechService(_recognizer!);
      
      _speechService!.onPartial().listen((event) {
        try {
          final Map<String, dynamic> data = jsonDecode(event.partial);
          if (data.containsKey('partial') && data['partial'].toString().isNotEmpty) {
            onResult(data['partial']);
          }
        } catch (_) {}
      });

      _speechService!.onResult().listen((event) {
        try {
          final Map<String, dynamic> data = jsonDecode(event.result);
          if (data.containsKey('text') && data['text'].toString().isNotEmpty) {
            onDone(data['text']);
          }
        } catch (_) {}
      });

      await _speechService!.start();
    } catch (e) {
      debugPrint("Vosk start listening error: $e");
      _isListening = false;
    }
  }

  Future<void> stopListening() async {
    _isListening = false;
    await _speechService?.stop();
  }

  void dispose() {
    _isListening = false;
    _speechService?.stop();
    _speechService?.dispose();
    _recognizer?.dispose();
    _model?.dispose();
  }
}
