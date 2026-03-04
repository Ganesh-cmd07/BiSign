import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/language_selector.dart';
import '../widgets/direction_button.dart';

class HomeScreen extends StatelessWidget {
  final String selectedLanguage;
  final ValueChanged<String> onLanguageChanged;

  const HomeScreen({
    super.key,
    required this.selectedLanguage,
    required this.onLanguageChanged,
  });

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
              Color(0xFF12122A),
              Color(0xFF0A0A1A),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // ── Logo & Tagline ──────────────────────────────
                _buildHeader()
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: -0.2, end: 0),

                const SizedBox(height: 16),

                // ── Language Selector ───────────────────────────
                LanguageSelector(
                  selectedLanguage: selectedLanguage,
                  onChanged: onLanguageChanged,
                ).animate().fadeIn(duration: 600.ms, delay: 200.ms),

                const SizedBox(height: 40),

                // ── Connection Line ─────────────────────────────
                _buildDivider(),

                const SizedBox(height: 40),

                // ── Direction 1: Sign to Speech ─────────────────
                DirectionButton(
                  icon: Icons.sign_language_rounded,
                  title: 'Start Signing',
                  subtitle: 'Gesture → Regional Speech',
                  color: AppTheme.direction1,
                  onTap: () => Navigator.pushNamed(context, '/sign-to-speech'),
                  tag: 'मूक | Mute',
                )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 400.ms)
                    .slideX(begin: -0.1, end: 0),

                const SizedBox(height: 20),

                // ── Direction 2: Speech to Sign ─────────────────
                DirectionButton(
                  icon: Icons.hearing_rounded,
                  title: 'Speak to Sign',
                  subtitle: 'Speech → ISL Animation',
                  color: AppTheme.direction2,
                  onTap: () => Navigator.pushNamed(context, '/speech-to-sign'),
                  tag: 'बधिर | Deaf',
                )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 600.ms)
                    .slideX(begin: 0.1, end: 0),

                const Spacer(),

                // ── Footer ──────────────────────────────────────
                _buildFooter()
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 800.ms),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo container with glow
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.secondary],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'BS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'BiSign',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 42,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppTheme.primary, AppTheme.secondary],
          ).createShader(bounds),
          child: const Text(
            'Giving Voice to the Voiceless',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.primary.withOpacity(0.4),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Choose Mode',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.secondary.withOpacity(0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '100% Offline  •  Free Forever  •  No Login',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Telugu • Hindi • Tamil • Kannada • Bengali • Malayalam',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
