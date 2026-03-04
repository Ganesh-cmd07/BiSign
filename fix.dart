import 'dart:io';

void main() {
  final fileFixes = {
    'home_screen.dart': (String content) {
      return content.replaceAll("import '../utils/constants.dart';\r\n", "")
                    .replaceAll("import '../utils/constants.dart';\n", "");
    },
    'speech_to_sign_screen.dart': (String content) {
      return content.replaceAll("import 'package:flutter_animate/flutter_animate.dart';\r\n", "")
                    .replaceAll("import 'package:flutter_animate/flutter_animate.dart';\n", "");
    },
    'hand_landmark_service.dart': (String content) {
      return content.replaceAll("import 'package:flutter/material.dart';\r\n", "")
                    .replaceAll("import 'package:flutter/material.dart';\n", "");
    },
    'isl_grammar_service.dart': (String content) {
      return content.replaceAll("import 'package:flutter/material.dart';\r\n", "")
                    .replaceAll("import 'package:flutter/material.dart';\n", "");
    },
    'sign_animation_service.dart': (String content) {
      return content.replaceAll(RegExp(r'final _rng = [^;]+;\r?\n?'), "");
    },
    'stt_service.dart': (String content) {
      content = content.replaceAll("import '../utils/app_theme.dart';\r\n", "")
                       .replaceAll("import '../utils/app_theme.dart';\n", "");
      content = content.replaceAll("import '../utils/constants.dart';\r\n", "")
                       .replaceAll("import '../utils/constants.dart';\n", "");
      return content;
    },
    'tts_service.dart': (String content) {
      return content.replaceAll(RegExp(r'String _currentLanguage = [^;]+;\r?\n?'), "");
    },
    'landmark_overlay.dart': (String content) {
      return content.replaceAll("import '../utils/constants.dart';\r\n", "")
                    .replaceAll("import '../utils/constants.dart';\n", "");
    },
  };

  final dir = Directory('c:/dev/BiSign/lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (var file in files) {
    var content = file.readAsStringSync();
    var originalContent = content;

    // Fix withOpacity
    if (content.contains('.withOpacity(')) {
      content = content.replaceAllMapped(
        RegExp(r'\.withOpacity\(([^)]+)\)'), 
        (m) => '.withValues(alpha: ${m.group(1)})'
      );
    }
    
    final filename = file.uri.pathSegments.last;
    if (fileFixes.containsKey(filename)) {
      content = fileFixes[filename]!(content);
    }

    if (content != originalContent) {
      file.writeAsStringSync(content);
    }
  }
}
