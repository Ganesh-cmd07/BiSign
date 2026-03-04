import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../utils/constants.dart';

/// TtsService — Android Text-To-Speech wrapper
/// Uses flutter_tts which wraps Android's built-in TTS engine.
/// Works 100% offline — no internet required.
class TtsService {
  FlutterTts? _tts;
  bool _isInitialized = false;
  String _currentLanguage = 'te';

  Future<void> initialize(String languageCode) async {
    _currentLanguage = languageCode;
    _tts = FlutterTts();

    try {
      // Set language/locale
      final locale = AppConstants.ttsLocales[languageCode] ?? 'hi-IN';
      await _tts!.setLanguage(locale);

      // Speech rate — slightly slower for accessibility
      await _tts!.setSpeechRate(0.45);

      // Volume & pitch
      await _tts!.setVolume(1.0);
      await _tts!.setPitch(1.0);

      // Use Android TTS engine
      await _tts!.setEngine('com.google.android.tts');

      _isInitialized = true;
      debugPrint('TTS initialized for locale: $locale');
    } catch (e) {
      // Fallback to default engine
      try {
        final locale = AppConstants.ttsLocales[languageCode] ?? 'hi-IN';
        await _tts!.setLanguage(locale);
        _isInitialized = true;
        debugPrint('TTS fallback initialized');
      } catch (e2) {
        debugPrint('TTS init error: $e2');
      }
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized || _tts == null || text.isEmpty) return;
    await _tts!.stop();
    await _tts!.speak(text);
  }

  Future<void> stop() async {
    await _tts?.stop();
  }

  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    final locale = AppConstants.ttsLocales[languageCode] ?? 'hi-IN';
    await _tts?.setLanguage(locale);
  }

  void dispose() {
    _tts?.stop();
  }
}
