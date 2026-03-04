import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

/// SignAnimationService
/// Loads ISL sign JSON landmark data and provides frames for animation.
/// Phase A: Returns mock frames for testing.
/// Phase C: Will load real JSON landmark files from assets/signs/.
class SignAnimationService {
  bool _isInitialized = false;
  final Map<String, List<Map<String, dynamic>>> _signCache = {};
  final Random _rng = Random();

  Future<void> initialize() async {
    // Phase C: Preload sign index from assets
    // For now, just mark initialized
    _isInitialized = true;
    debugPrint('SignAnimationService: Phase A mock initialized');
  }

  /// Get frames for a given word.
  /// Returns list of frame maps: [{left_hand: [...], right_hand: [...]}, ...]
  Future<List<Map<String, dynamic>>> getSignFrames(String word) async {
    if (!_isInitialized) return [];

    final key = word.toLowerCase();

    // Return cached sign if available
    if (_signCache.containsKey(key)) return _signCache[key]!;

    // Phase C: Try to load from assets/signs/<word>.json
    try {
      final jsonStr = await rootBundle
          .loadString('${AppConstants.signsAssetPath}$key.json');
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final frames = (data['frames'] as List)
          .map((f) => f as Map<String, dynamic>)
          .toList();
      _signCache[key] = frames;
      return frames;
    } catch (_) {
      // Fallback to mock frames for Phase A
      final frames = _generateMockFrames(word);
      _signCache[key] = frames;
      return frames;
    }
  }

  /// Generate mock hand landmark frames for Phase A testing.
  /// Creates a simple wave animation with 30 frames.
  List<Map<String, dynamic>> _generateMockFrames(String word) {
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
