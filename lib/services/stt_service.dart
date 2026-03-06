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

  /// True when the service fell back to Hindi because the selected language
  /// model was not found in assets.
  bool usingFallback = false;

  /// The language code actually loaded (may differ from requested if fallback used).
  String activeLanguageCode = 'hi';

  /// Maps each supported language code to its Vosk model asset path.
  /// Add new model paths here as language models are added to assets/vosk/.
  static const Map<String, String> _languageModelPaths = {
    'hi': 'assets/vosk/model-hi.zip',   // Hindi       ✅ available
    'te': 'assets/vosk/model-te.zip',   // Telugu      (add when downloaded)
    'ta': 'assets/vosk/model-ta.zip',   // Tamil       (add when downloaded)
    'kn': 'assets/vosk/model-kn.zip',   // Kannada     (add when downloaded)
    'bn': 'assets/vosk/model-bn.zip',   // Bengali     (add when downloaded)
    'ml': 'assets/vosk/model-ml.zip',   // Malayalam   (add when downloaded)
  };

  /// Fallback language if the selected language model is not yet available.
  static const String _fallbackLanguage = 'hi';

  Future<void> initialize(String languageCode) async {
    try {
      // Resolve model path for the given language code.
      // Falls back to Hindi if the language-specific model is not yet available.
      final preferredPath = _languageModelPaths[languageCode];
      final fallbackPath = _languageModelPaths[_fallbackLanguage]!;

      String resolvedPath;
      try {
        // Attempt to load the language-specific model first
        resolvedPath = await ModelLoader().loadFromAssets(preferredPath ?? fallbackPath);
        usingFallback = false;
        activeLanguageCode = languageCode;
        debugPrint('Vosk: Loaded model for language: $languageCode');
      } catch (_) {
        // Language-specific model not found in assets, fall back to Hindi
        usingFallback = languageCode != _fallbackLanguage;
        activeLanguageCode = _fallbackLanguage;
        debugPrint(
          'Vosk: Model for "$languageCode" not found in assets. '
          'Falling back to Hindi (hi). Add assets/vosk/model-$languageCode.zip to fix this.',
        );
        resolvedPath = await ModelLoader().loadFromAssets(fallbackPath);
      }

      _model = await _vosk.createModel(resolvedPath);
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
      
      _speechService!.onPartial().listen((partialJson) {
        try {
          final Map<String, dynamic> data = jsonDecode(partialJson);
          if (data.containsKey('partial') && data['partial'].toString().isNotEmpty) {
            onResult(data['partial']);
          }
        } catch (_) {}
      });

      _speechService!.onResult().listen((resultJson) {
        try {
          final Map<String, dynamic> data = jsonDecode(resultJson);
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
