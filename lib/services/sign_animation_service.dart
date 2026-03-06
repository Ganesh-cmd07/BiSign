import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

/// SignAnimationService
/// Loads ISL sign JSON landmark data from assets/signs/<word>.json and
/// provides per-word frame lists for the SignCanvas animation renderer.
///
/// ⚠️ Real sign JSON files are required in assets/signs/ for production use.
/// Until then, a procedural fallback animation is generated per word so the
/// UI remains functional during development.
class SignAnimationService {
  bool _isInitialized = false;
  final Map<String, List<Map<String, dynamic>>> _signCache = {};

  Future<void> initialize() async {
    // Mark initialized. Real sign files from assets/signs/ are loaded
    // lazily on first request for each word (see getSignFrames).
    _isInitialized = true;
    debugPrint('SignAnimationService: Ready. Sign files loaded from assets/signs/ on demand.');
  }

  /// Get animation frames for a given word.
  /// Returns list of frame maps: [{right_hand: [...], left_hand: [...]}, ...]
  ///
  /// Loads from assets/signs/<word>.json if available.
  /// Falls back to a procedurally generated animation if the file is missing.
  Future<List<Map<String, dynamic>>> getSignFrames(String word) async {
    if (!_isInitialized) return [];

    final key = word.toLowerCase().trim();
    if (key.isEmpty) return [];

    // Return cached sign if already loaded
    if (_signCache.containsKey(key)) return _signCache[key]!;

    // Try to load real sign data from assets/signs/<word>.json
    try {
      final jsonStr = await rootBundle
          .loadString('${AppConstants.signsAssetPath}$key.json');
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final frames = (data['frames'] as List)
          .map((f) => f as Map<String, dynamic>)
          .toList();
      _signCache[key] = frames;
      debugPrint('SignAnimationService: Loaded real sign for "$key" (${frames.length} frames)');
      return frames;
    } catch (_) {
      // Real sign file not found — use procedural fallback animation
      debugPrint(
        'SignAnimationService: No sign file found for "$key". '
        'Using fallback animation. Add assets/signs/$key.json to fix.',
      );
      final frames = _generateFallbackFrames(key);
      _signCache[key] = frames;
      return frames;
    }
  }

  /// Clears the sign cache. Useful when assets are updated at runtime.
  void clearCache() => _signCache.clear();

  /// Generates a procedural fallback hand animation (30 frames) for a word
  /// that doesn't have a real JSON sign file yet.
  List<Map<String, dynamic>> _generateFallbackFrames(String word) {
    const frameCount = 30;
    return List.generate(frameCount, (frameIdx) {
      final t = frameIdx / frameCount;
      return {
        'frame_number': frameIdx + 1,
        'right_hand': _generateHandLandmarks(t, offset: 0.55, mirror: false),
        'left_hand': _generateHandLandmarks(t, offset: 0.45, mirror: true),
      };
    });
  }

  List<List<double>> _generateHandLandmarks(
      double t, {required double offset, required bool mirror}) {
    // 21 MediaPipe hand landmarks — waving/signing motion
    final wrist = [offset, 0.7 + sin(t * 2 * pi) * 0.05, 0.0];

    return [
      wrist, // 0 - wrist
      // Thumb (4 joints)
      [wrist[0] + (mirror ? 0.08 : -0.08), 0.65, 0.0],
      [wrist[0] + (mirror ? 0.12 : -0.12), 0.60, 0.0],
      [wrist[0] + (mirror ? 0.14 : -0.14), 0.56, 0.0],
      [wrist[0] + (mirror ? 0.15 : -0.15), 0.52, 0.0],
      // Index finger
      [wrist[0] + (mirror ? -0.02 : 0.02), 0.62, 0.0],
      [wrist[0] + (mirror ? -0.02 : 0.02), 0.55, 0.0],
      [wrist[0] + (mirror ? -0.02 : 0.02), 0.50 + sin(t * 2 * pi) * 0.03, 0.0],
      [wrist[0] + (mirror ? -0.02 : 0.02), 0.46, 0.0],
      // Middle finger
      [wrist[0] + (mirror ? -0.06 : 0.06), 0.61, 0.0],
      [wrist[0] + (mirror ? -0.07 : 0.07), 0.53, 0.0],
      [wrist[0] + (mirror ? -0.07 : 0.07), 0.47 + sin(t * 2 * pi + 0.3) * 0.03, 0.0],
      [wrist[0] + (mirror ? -0.07 : 0.07), 0.44, 0.0],
      // Ring finger
      [wrist[0] + (mirror ? -0.10 : 0.10), 0.62, 0.0],
      [wrist[0] + (mirror ? -0.11 : 0.11), 0.54, 0.0],
      [wrist[0] + (mirror ? -0.11 : 0.11), 0.49 + sin(t * 2 * pi + 0.6) * 0.03, 0.0],
      [wrist[0] + (mirror ? -0.11 : 0.11), 0.46, 0.0],
      // Pinky
      [wrist[0] + (mirror ? -0.14 : 0.14), 0.64, 0.0],
      [wrist[0] + (mirror ? -0.15 : 0.15), 0.58, 0.0],
      [wrist[0] + (mirror ? -0.15 : 0.15), 0.54, 0.0],
      [wrist[0] + (mirror ? -0.15 : 0.15), 0.51, 0.0],
    ];
  }
}
