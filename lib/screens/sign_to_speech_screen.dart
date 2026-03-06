import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../services/sign_classifier_service.dart';
import '../services/tts_service.dart';
import '../services/hand_landmark_service.dart';
import '../widgets/landmark_overlay.dart';

class SignToSpeechScreen extends StatefulWidget {
  final String selectedLanguage;
  const SignToSpeechScreen({super.key, required this.selectedLanguage});

  @override
  State<SignToSpeechScreen> createState() => _SignToSpeechScreenState();
}

class _SignToSpeechScreenState extends State<SignToSpeechScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;

  String _recognizedSign = '';
  String _recognizedSentence = '';
  double _confidence = 0.0;
  List<List<double>> _currentLandmarks = [];
  int _stableFrameCount = 0;
  String _lastSign = '';

  final SignClassifierService _classifier = SignClassifierService();
  final TtsService _tts = TtsService();
  final HandLandmarkService _landmarkService = HandLandmarkService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _initServices();
  }

  Future<void> _initServices() async {
    await _classifier.initialize();
    await _tts.initialize(widget.selectedLanguage);
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) return;

      // Prefer front camera
      CameraDescription camera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() => _isCameraInitialized = true);
        _startImageStream();
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  void _startImageStream() {
    _cameraController?.startImageStream((CameraImage image) async {
      if (_isProcessing) return;
      _isProcessing = true;

      try {
        // Extract landmarks using HandLandmarkService
        final landmarks = await _landmarkService.extractLandmarks(
          image,
          _cameraController!.description.sensorOrientation,
        );

        if (landmarks.isNotEmpty) {
          // Classify the sign
          final result = await _classifier.classify(landmarks);

          if (mounted) {
            setState(() {
              _currentLandmarks = landmarks;
              _confidence = result['confidence'] as double;
              final sign = result['sign'] as String;

              // Stability check — same sign for N frames
              if (sign == _lastSign) {
                _stableFrameCount++;
                if (_stableFrameCount >= AppConstants.predictionStabilityFrames &&
                    _confidence >= AppConstants.confidenceThreshold) {
                  _recognizedSign = sign;
                  if (!_recognizedSentence.endsWith(sign)) {
                    _recognizedSentence = '$_recognizedSentence $sign'.trim();
                  }
                }
              } else {
                _stableFrameCount = 0;
                _lastSign = sign;
              }
            });
          }
        }
      } catch (e) {
        debugPrint('Frame processing error: $e');
      } finally {
        _isProcessing = false;
      }
    });
  }

  Future<void> _speakRecognizedText() async {
    if (_recognizedSentence.isEmpty) return;
    setState(() => _isSpeaking = true);
    await _tts.speak(_recognizedSentence);
    setState(() => _isSpeaking = false);
  }

  void _clearSentence() {
    setState(() {
      _recognizedSentence = '';
      _recognizedSign = '';
      _confidence = 0.0;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _tts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Camera View ──────────────────────────────────
          _buildCameraView(),

          // ── Dark gradient overlay (top) ──────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Dark gradient overlay (bottom) ───────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 300,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.95),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Top Bar ──────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildBackButton(),
                  const Spacer(),
                  _buildStatusBadge(),
                ],
              ),
            ),
          ),

          // ── Landmark Overlay ─────────────────────────────
          if (_currentLandmarks.isNotEmpty && _isCameraInitialized)
            LandmarkOverlay(landmarks: _currentLandmarks),

          // ── Bottom Panel ─────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: _buildBottomPanel(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    if (!_isCameraInitialized || _cameraController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primary),
              SizedBox(height: 16),
              Text(
                'Starting Camera...',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraController!.value.previewSize!.height,
          height: _cameraController!.value.previewSize!.width,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border:
              Border.all(color: AppTheme.primary.withValues(alpha: 0.5), width: 1),
        ),
        child: const Icon(Icons.arrow_back_rounded,
            color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final isActive = _recognizedSign.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? AppTheme.success.withValues(alpha: 0.7)
              : AppTheme.primary.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppTheme.success : AppTheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isActive ? 'Detecting' : 'Scanning...',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Current sign detected
          if (_recognizedSign.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.4), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '👋  $_recognizedSign',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${(_confidence * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppTheme.secondary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.2, end: 0),

          // Formed sentence
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppTheme.surfaceLight.withValues(alpha: 0.5), width: 1),
            ),
            child: Text(
              _recognizedSentence.isEmpty
                  ? 'Show hands to camera...'
                  : _recognizedSentence,
              style: TextStyle(
                color: _recognizedSentence.isEmpty
                    ? AppTheme.textSecondary
                    : AppTheme.textPrimary,
                fontSize: 18,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              // Clear button
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: _clearSentence,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: AppTheme.textSecondary, size: 28),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Speak button
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTap: _recognizedSentence.isNotEmpty
                      ? _speakRecognizedText
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _recognizedSentence.isNotEmpty
                            ? [AppTheme.primary, AppTheme.primaryDark]
                            : [
                                AppTheme.surfaceLight,
                                AppTheme.surfaceLight
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _recognizedSentence.isNotEmpty
                          ? [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isSpeaking
                              ? Icons.volume_up_rounded
                              : Icons.record_voice_over_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _isSpeaking ? 'Speaking...' : 'Speak',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
