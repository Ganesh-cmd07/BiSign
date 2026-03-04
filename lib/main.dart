import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/sign_to_speech_screen.dart';
import 'screens/speech_to_sign_screen.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Full screen immersive mode
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  final savedLanguage = prefs.getString(AppConstants.prefLanguage) ?? 'te';

  runApp(BiSignApp(initialLanguage: savedLanguage));
}

class BiSignApp extends StatefulWidget {
  final String initialLanguage;
  const BiSignApp({super.key, required this.initialLanguage});

  @override
  State<BiSignApp> createState() => _BiSignAppState();
}

class _BiSignAppState extends State<BiSignApp> {
  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.initialLanguage;
  }

  void _onLanguageChanged(String lang) async {
    setState(() => _selectedLanguage = lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefLanguage, lang);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BiSign',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(
              selectedLanguage: _selectedLanguage,
              onLanguageChanged: _onLanguageChanged,
            ),
        '/sign-to-speech': (context) => SignToSpeechScreen(
              selectedLanguage: _selectedLanguage,
            ),
        '/speech-to-sign': (context) => SpeechToSignScreen(
              selectedLanguage: _selectedLanguage,
            ),
      },
    );
  }
}
