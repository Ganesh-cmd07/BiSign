import 'dart:async';

/// SttService
/// Phase C implementation using offline continuous Speech-to-Text.
class SttService {
  bool _isListening = false;
  Timer? _simulationTimer;

  Future<void> initialize(String languageCode) async {
    // Phase C: Initialize Vosk plugin and load localized acoustic models 
    // from assets/vosk/...
  }

  Future<void> startListening({
    required String language,
    required Function(String) onResult,
    required Function(String) onDone,
  }) async {
    if (_isListening) return;
    _isListening = true;

    // Phase C - Vosk internal structure:
    // _speechService = await _vosk.createSpeechService(_recognizer!);
    // _speechService!.onPartial().listen((e) => onResult(e.partial));
    // _speechService!.onResult().listen((e) => onDone(e.text));

    // Simulation for offline testing UI logic
    int ticks = 0;
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (!_isListening) {
        timer.cancel();
        return;
      }
      ticks++;
      if (ticks == 1) {
        onResult("i");
      } else if (ticks == 2) {
        onResult("i need");
      } else if (ticks == 3) {
        onResult("i need water");
      } else if (ticks == 4) {
        onDone("i need water please");
        _isListening = false;
        timer.cancel();
      }
    });
  }

  Future<void> stopListening() async {
    _isListening = false;
    _simulationTimer?.cancel();
  }

  void dispose() {
    _isListening = false;
    _simulationTimer?.cancel();
  }
}
