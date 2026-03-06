class AppConstants {
  // SharedPreferences keys
  static const String prefLanguage = 'bisign_language';
  static const String prefFirstLaunch = 'bisign_first_launch';

  // Supported languages
  static const Map<String, String> languages = {
    'te': 'తెలుగు',     // Telugu
    'hi': 'हिन्दी',    // Hindi
    'ta': 'தமிழ்',     // Tamil
    'kn': 'ಕನ್ನಡ',    // Kannada
    'bn': 'বাংলা',     // Bengali
    'ml': 'മലയാളം',   // Malayalam
  };

  static const Map<String, String> languageNames = {
    'te': 'Telugu',
    'hi': 'Hindi',
    'ta': 'Tamil',
    'kn': 'Kannada',
    'bn': 'Bengali',
    'ml': 'Malayalam',
  };

  // TTS locale codes for Android TTS
  static const Map<String, String> ttsLocales = {
    'te': 'te-IN',
    'hi': 'hi-IN',
    'ta': 'ta-IN',
    'kn': 'kn-IN',
    'bn': 'bn-IN',
    'ml': 'ml-IN',
  };

  // Asset paths
  static const String signsAssetPath = 'assets/signs/';
  static const String modelsAssetPath = 'assets/models/';
  static const String tfliteModelPath = 'assets/models/sign_classifier.tflite';

  // Model parameters
  static const int numLandmarks = 21;       // Per hand (MediaPipe)
  static const int landmarkDimensions = 3;  // x, y, z
  static const int inputFeatureSize = 42;    // 21 points * 2 (x, y)
  static const int numClasses = 93;        // Validated ISL signs in assets/signs/

  // Animation
  static const int animationFps = 30;
  static const double canvasWidth = 360.0;
  static const double canvasHeight = 480.0;

  // ISL Grammar
  // Helping verbs to remove in ISL
  static const List<String> helpingVerbs = [
    'is', 'are', 'was', 'were', 'am', 'be', 'been', 'being',
    'has', 'have', 'had', 'do', 'does', 'did',
    'will', 'would', 'shall', 'should', 'may', 'might',
    'must', 'can', 'could',
  ];

  // Articles to remove in ISL
  static const List<String> articles = ['a', 'an', 'the'];

  // Question words (kept at beginning)
  static const List<String> questionWords = [
    'what', 'when', 'where', 'who', 'why', 'how', 'which',
  ];

  // Common ISL sign categories
  static const List<String> signCategories = [
    'greetings',
    'family',
    'food',
    'numbers',
    'colors',
    'body',
    'actions',
    'places',
    'time',
    'emergency',
  ];

  // Performance
  static const int predictionStabilityFrames = 8;
  static const double confidenceThreshold = 0.75;
  static const int maxResponseTimeMs = 2000;
}
