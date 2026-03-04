import '../utils/constants.dart';

/// IslGrammarService
/// Converts English/regional language sentences to ISL word order.
/// ISL grammar: Subject → Object → Verb (SOV)
class IslGrammarService {
  /// Main entry: reorder sentence for ISL
  String reorder(String text) {
    if (text.isEmpty) return text;

    // Lowercase and split
    final words = text.toLowerCase().trim().split(RegExp(r'\s+'));

    // Step 1: Remove articles (a, an, the)
    final noArticles =
        words.where((w) => !AppConstants.articles.contains(w)).toList();

    // Step 2: Remove helping verbs (is, are, was, etc.)
    final noHelpingVerbs = noArticles
        .where((w) => !AppConstants.helpingVerbs.contains(w))
        .toList();

    // Step 3: Check if question
    final isQuestion = noHelpingVerbs.isNotEmpty &&
        AppConstants.questionWords.contains(noHelpingVerbs.first);

    if (isQuestion) {
      // Keep question word at beginning, reorder rest
      final qWord = noHelpingVerbs.first;
      final rest = noHelpingVerbs.sublist(1);
      final reordered = _applySOV(rest);
      return ([qWord] + reordered).join(' ');
    }

    return _applySOV(noHelpingVerbs).join(' ');
  }

  /// Apply SOV reordering:
  /// Heuristic: identify verb candidates (last meaningful word after removing
  /// articles/helping verbs is likely the main verb or action word).
  List<String> _applySOV(List<String> words) {
    if (words.length <= 2) return words;

    // Common ISL verbs / action words to move to end
    final verbCandidates = {
      'want', 'need', 'like', 'eat', 'drink', 'go', 'come', 'give',
      'take', 'see', 'hear', 'speak', 'write', 'read', 'help', 'buy',
      'sell', 'work', 'study', 'learn', 'teach', 'play', 'run', 'walk',
      'sit', 'stand', 'sleep', 'wake', 'wash', 'cook', 'feel', 'know',
      'understand', 'wait', 'open', 'close', 'start', 'stop', 'show',
    };

    // Find first verb in the list
    int verbIndex = -1;
    for (int i = 0; i < words.length; i++) {
      if (verbCandidates.contains(words[i])) {
        verbIndex = i;
        break;
      }
    }

    if (verbIndex < 0) return words; // No verb found, keep as is

    // Move verb to end: [before_verb] + [after_verb] + [verb]
    final verb = words[verbIndex];
    final rest = [...words.sublist(0, verbIndex), ...words.sublist(verbIndex + 1)];
    return [...rest, verb];
  }

  /// Get individual signs/words for animation
  List<String> getSignWords(String islText) {
    return islText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  }
}
