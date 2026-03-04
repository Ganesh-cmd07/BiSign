/**
 * SpeechSynthesizer handles the conversion of text into
 * audible regional language speech using the Web Speech API.
 */
export class SpeechSynthesizer {
  constructor() {
    this.synth = window.speechSynthesis;
    this.voices = [];
    this.langMap = {
      'te-IN': 'Telugu (India)',
      'hi-IN': 'Hindi (India)',
      'ta-IN': 'Tamil (India)',
      'kn-IN': 'Kannada (India)',
      'en-US': 'English (United States)',
      'bn-IN': 'Bengali (India)',
      'ml-IN': 'Malayalam (India)',
    };

    // Load voices
    this.voicesReady = false;
    this.init();
  }

  init() {
    const populate = () => {
      this.voices = this.synth.getVoices() || [];
      this.voicesReady = true;
      console.log(`Loaded ${this.voices.length} voices.`);
    };

    if (
      typeof speechSynthesis !== 'undefined' &&
      speechSynthesis.onvoiceschanged !== undefined
    ) {
      speechSynthesis.onvoiceschanged = populate;
    }

    // Try to populate immediately as well
    populate();
  }

  /**
   * Speak a given sentence in the target language
   * @param {String} text - Text to speak
   * @param {String} langCode - e.g. 'te-IN'
   */
  async speak(text, langCode) {
    if (!text) return;

    // If another utterance is playing, stop it and replace with new one
    if (this.synth.speaking) {
      try {
        this.synth.cancel();
      } catch (e) {
        console.warn('Failed to cancel ongoing speech:', e);
      }
    }

    // Wait briefly for voices to populate if they are not ready yet
    if (!this.voicesReady) {
      await new Promise((res) => setTimeout(res, 200));
    }

    const utterance = new SpeechSynthesisUtterance(text);

    // 1. Find best matching voice for the language
    const voice = this.voices.find(
      (v) => v.lang && v.lang.startsWith(langCode)
    );

    if (voice) {
      utterance.voice = voice;
      utterance.lang = voice.lang;
    } else {
      // Fallback: Just set the language code directly
      utterance.lang = langCode;
      console.warn(
        `No specific voice found for ${langCode}, using system default.`
      );
    }

    // 2. Adjust speech parameters for clarity
    utterance.pitch = 1.0;
    utterance.rate = 0.95; // Slightly slower for better articulation
    utterance.volume = 1.0;

    // 3. Queue the utterance
    try {
      this.synth.speak(utterance);
      console.log(`Speaking (${langCode}): ${text}`);
    } catch (e) {
      console.warn('Speech synthesis failed:', e);
    }
  }

  /**
   * Stop any ongoing speech
   */
  stop() {
    this.synth.cancel();
  }
}
