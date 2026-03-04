import '../utils/constants.dart';

/// IslGrammarService
/// Phase D implementation. Converts continuous vernacular sentences
/// into proper ISL Subject-Object-Verb (SOV) structural order.
class IslGrammarService {
  /// Common action verbs used in ISL
  static const List<String> verbs = [
    'want', 'drink', 'eat', 'go', 'come', 'help', 'need',
    'see', 'look', 'make', 'know', 'think', 'take', 'give', 'use',
    'speak', 'talk', 'walk', 'stop', 'play', 'work', 'buy', 'please'
  ];

  String reorder(String sentence) {
    if (sentence.isEmpty) return '';

    // Clean punctuation and lowercase
    String cleanSentence = sentence.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    List<String> words = cleanSentence.split(' ').where((w) => w.isNotEmpty).toList();

    // 1. Remove articles (Rule 2)
    words.removeWhere((word) => AppConstants.articles.contains(word));

    // 2. Remove helping verbs (Rule 3)
    words.removeWhere((word) => AppConstants.helpingVerbs.contains(word));

    if (words.isEmpty) return '';

    // 3. Move verbs to end (Rule 1)
    List<String> verbsInSentence = [];
    List<String> otherWords = [];

    for (String word in words) {
      if (verbs.contains(word)) {
        verbsInSentence.add(word);
      } else {
        otherWords.add(word);
      }
    }

    // 4. Keep question words at the beginning (Rule 4)
    List<String> questions = [];
    List<String> remaining = [];

    for (String word in otherWords) {
      if (AppConstants.questionWords.contains(word)) {
        questions.add(word);
      } else {
        remaining.add(word);
      }
    }

    // Assemble final SOV sentence
    List<String> finalSentence = [];
    finalSentence.addAll(questions);       // Question words first
    finalSentence.addAll(remaining);       // Subjects / Objects middle
    finalSentence.addAll(verbsInSentence); // Verbs last

    return finalSentence.join(' ').trim();
  }
}
