import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../services/stt_service.dart';
import '../services/isl_grammar_service.dart';
import '../services/sign_animation_service.dart';
import '../widgets/sign_canvas.dart';

class SpeechToSignScreen extends StatefulWidget {
  final String selectedLanguage;
  const SpeechToSignScreen({super.key, required this.selectedLanguage});

  @override
  State<SpeechToSignScreen> createState() => _SpeechToSignScreenState();
}

class _SpeechToSignScreenState extends State<SpeechToSignScreen>
    with SingleTickerProviderStateMixin {
  bool _isListening = false;
  bool _isAnimating = false;
  String _recognizedText = '';
  String _islOrderedText = '';
  List<String> _signWords = [];
  int _currentSignIndex = 0;
  List<Map<String, dynamic>> _currentFrames = [];

  final SttService _stt = SttService();
  final IslGrammarService _grammar = IslGrammarService();
  final SignAnimationService _animation = SignAnimationService();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 1.0, end: 1.15).animate(_pulseController);
    _initServices();
  }

  Future<void> _initServices() async {
    await _stt.initialize(widget.selectedLanguage);
    await _animation.initialize();
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
      _recognizedText = '';
      _islOrderedText = '';
      _signWords = [];
      _currentFrames = [];
    });

    await _stt.startListening(
      language: widget.selectedLanguage,
      onResult: (text) {
        setState(() => _recognizedText = text);
      },
      onDone: (finalText) {
        _processText(finalText);
      },
    );
  }

  Future<void> _stopListening() async {
    setState(() => _isListening = false);
    await _stt.stopListening();
  }

  Future<void> _processText(String text) async {
    if (text.isEmpty) return;
    setState(() => _isListening = false);

    // ISL grammar reordering
    final islText = _grammar.reorder(text);
    final words = islText.split(' ').where((w) => w.isNotEmpty).toList();

    setState(() {
      _islOrderedText = islText;
      _signWords = words;
    });

    // Play animation for each word
    _playSignAnimation(words);
  }

  Future<void> _playSignAnimation(List<String> words) async {
    setState(() {
      _isAnimating = true;
      _currentSignIndex = 0;
    });

    for (int i = 0; i < words.length; i++) {
      if (!mounted) break;
      setState(() => _currentSignIndex = i);

      final frames = await _animation.getSignFrames(words[i]);
      setState(() => _currentFrames = frames);

      // Wait for animation duration
      final duration = frames.length * (1000 ~/ AppConstants.animationFps);
      await Future.delayed(Duration(milliseconds: duration + 300));
    }

    if (mounted) setState(() => _isAnimating = false);
  }

  Future<void> _replayAnimation() async {
    if (_signWords.isEmpty) return;
    _playSignAnimation(_signWords);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _stt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0A1A),
              Color(0xFF0A1A14),
              Color(0xFF0A0A1A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top Bar ────────────────────────────────────
              _buildTopBar(),

              // ── Sign Animation Canvas ───────────────────────
              Expanded(
                flex: 5,
                child: _buildAnimationCanvas(),
              ),

              // ── Word Progress ───────────────────────────────
              if (_signWords.isNotEmpty) _buildWordProgress(),

              // ── Recognized Text ─────────────────────────────
              _buildTextPanel(),

              // ── Mic Button ──────────────────────────────────
              _buildMicPanel(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppTheme.secondary.withOpacity(0.3), width: 1),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Speech → ISL Signs',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // Replay button
          if (_signWords.isNotEmpty && !_isAnimating)
            GestureDetector(
              onTap: _replayAnimation,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppTheme.secondary.withOpacity(0.4), width: 1),
                ),
                child: const Icon(Icons.replay_rounded,
                    color: AppTheme.secondary, size: 22),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimationCanvas() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.secondary.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondary.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: _currentFrames.isEmpty
            ? _buildEmptyCanvas()
            : SignCanvas(
                frames: _currentFrames,
                isAnimating: _isAnimating,
              ),
      ),
    );
  }

  Widget _buildEmptyCanvas() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pan_tool_rounded,
            size: 80,
            color: AppTheme.secondary.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            _isListening ? 'Listening...' : 'Tap mic to speak',
            style: TextStyle(
              color: _isListening
                  ? AppTheme.secondary
                  : AppTheme.textSecondary,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ISL signs will appear here',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildWordProgress() {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _signWords.length,
        itemBuilder: (context, index) {
          final isActive = index == _currentSignIndex && _isAnimating;
          final isDone = index < _currentSignIndex ||
              (!_isAnimating && index <= _currentSignIndex);
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.secondary
                  : isDone
                      ? AppTheme.secondary.withOpacity(0.2)
                      : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive
                    ? AppTheme.secondary
                    : AppTheme.secondary.withOpacity(0.2),
              ),
            ),
            child: Text(
              _signWords[index],
              style: TextStyle(
                color: isActive ? Colors.black : AppTheme.textPrimary,
                fontSize: 14,
                fontWeight:
                    isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recognizedText.isNotEmpty) ...[
            const Text('You said:',
                style:
                    TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              _recognizedText,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 16),
            ),
          ],
          if (_islOrderedText.isNotEmpty && _islOrderedText != _recognizedText) ...[
            const SizedBox(height: 8),
            const Text('ISL order:',
                style:
                    TextStyle(color: AppTheme.secondary, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              _islOrderedText,
              style: const TextStyle(
                color: AppTheme.secondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (_recognizedText.isEmpty)
            const Text(
              'Your speech will appear here...',
              style:
                  TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            ),
        ],
      ),
    );
  }

  Widget _buildMicPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Instructions
          Expanded(
            child: Text(
              _isListening
                  ? 'Tap to stop'
                  : 'Tap and speak in\n${AppConstants.languageNames[widget.selectedLanguage] ?? 'your language'}',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14),
            ),
          ),

          // Mic Button
          GestureDetector(
            onTap: _isListening ? _stopListening : _startListening,
            child: ScaleTransition(
              scale: _isListening ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _isListening
                        ? [AppTheme.error, const Color(0xFFB71C1C)]
                        : [AppTheme.secondary, const Color(0xFF00A884)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isListening ? AppTheme.error : AppTheme.secondary)
                          .withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
