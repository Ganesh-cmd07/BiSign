/**
 * ISLGrammarProcessor transforms the sequence of recognized signs
 * into natural regional language sentences with correct ISL grammar reordering.
 */
export class ISLGrammarProcessor {
  constructor() {
    this.history = [];
    this.lastProcessedSentence = '';

    // Simple ISL to English/Regional Grammar Map
    this.grammMap = {
      'I GO SCHOOL': 'I am going to school',
      'NAME MY': 'My name is...',
      'YOU HELP': 'Could you please help me?',
      'WATER I WANT': 'I would like some water',
      'FOOD I EAT': 'I am eating food',
      'DOCTOR WHERE': 'Where is the doctor?',
      'I HUNGRY': 'I am hungry',
      'I THIRSTY': 'I am thirsty',
      'I GO HOME': 'I am going home',
      'CALL HELP': 'Please call for help',
      'THANK YOU': 'Thank you',
    };
  }

  /**
   * Reorder a list of signs into a natural sentence.
   * @param {Array} words - List of recognized signs
   * @returns {String} - Natural language sentence
   */
  reorder(words) {
    if (!words || words.length === 0) return '';

    // Normalize spacing and casing
    const raw = words.join(' ').toUpperCase().trim().replace(/\s+/g, ' ');

    // Direct mapping for common ISL phrases
    if (this.grammMap[raw]) return this.grammMap[raw];

    // Heuristic rules
    // 1) QUESTIONS: patterns with WHERE
    const whereEnd = raw.match(/^(.+)\s+WHERE$/);
    if (whereEnd) {
      return `Where is ${this._humanize(whereEnd[1])}?`;
    }

    const whereStart = raw.match(/^WHERE\s+(.+)$/);
    if (whereStart) {
      return `Where is ${this._humanize(whereStart[1])}?`;
    }

    // 2) I WANT / WANT patterns
    const wantMatch = raw.match(/^(I\s+)?WANT\s+(.+)$/);
    if (wantMatch) {
      const obj = this._humanize(wantMatch[2]);
      return wantMatch[1] ? `I want ${obj}` : `I want ${obj}`;
    }

    // 3) Simple subject-verb-object rejoin (best-effort)
    return this._humanize(raw);
  }

  _humanize(text) {
    const s = text.toLowerCase().replace(/\s+/g, ' ').trim();
    return s.charAt(0).toUpperCase() + s.slice(1);
  }
}
