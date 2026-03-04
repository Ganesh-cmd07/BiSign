import * as tf from '@tensorflow/tfjs';

/**
 * SignClassifier handles the transformation of 42 hand landmarks
 * into recognized Indian Sign Language (ISL) gestures.
 * Designed for the INCLUDE dataset architecture.
 */
export class SignClassifier {
  constructor() {
    this.model = null;
    this.labels = [
      'Hello',
      'Thank You',
      'Good',
      'Bad',
      'Help',
      'Emergency',
      'Doctor',
      'Water',
      'Food',
      'School',
      'Home',
      'Indian Sign Language',
      'India',
    ];
    this.isModelLoaded = false;
    this.demoMode = true; // Use heuristics for initial demo

    // Start async initialization but do not block construction
    this.init();
  }

  async init() {
    try {
      // Attempt to fetch a local/model-hosted TF.js model at runtime.
      // If not present, remain in demoMode and use heuristics.
      const modelUrl = '/model/model.json';
      const resp = await fetch(modelUrl, { method: 'HEAD' });
      if (resp.ok) {
        this.model = await tf.loadLayersModel(modelUrl);
        this.isModelLoaded = true;
        this.demoMode = false;
        console.log('Sign Classifier: TF model loaded.');
      } else {
        console.log('Sign Classifier: No TF model found, using heuristics.');
      }
    } catch (e) {
      console.warn('Model loading failed, staying in demo mode.', e);
    }
  }

  /**
   * Predict the sign based on hand landmarks
   * @param {Array} landmarksList - List of MediaPipe landmarks
   * @returns {Object} { sign: string, confidence: float }
   */
  async predict(landmarksList) {
    if (!landmarksList || landmarksList.length === 0)
      return { sign: null, confidence: 0 };

    if (this.isModelLoaded) {
      // 1. Preprocess landmarks (Normalize, Flatten)
      const input = this.preprocess(landmarksList[0]);

      // 2. Inference
      try {
        const prediction = this.model.predict(input);
        const data = await prediction.data();
        const maxIndex = data.indexOf(Math.max(...data));

        // Dispose model input to avoid memory leaks
        if (input.dispose) input.dispose();

        return {
          sign: this.labels[maxIndex] || null,
          confidence: data[maxIndex] || 0,
        };
      } catch (err) {
        console.warn(
          'Model inference failed, falling back to heuristics.',
          err
        );
        return this.heuristicInference(landmarksList[0]);
      }
    } else {
      // 3. Fallback: Demo Heuristics for "Hello", "Thank You", "OK"
      return this.heuristicInference(landmarksList[0]);
    }
  }

  preprocess(landmarks) {
    // MediaPipe hands landmarks are x, y, z.
    // Normalized to range [0, 1].
    // Shift relative to wrist (landmark 0).
    const wrist = landmarks[0];
    const flattened = landmarks.flatMap((l) => [
      l.x - wrist.x,
      l.y - wrist.y,
      l.z - wrist.z,
    ]);

    // Ensure a 2D tensor with shape [1, N]
    return tf.tensor2d([flattened], [1, flattened.length]);
  }

  /**
   * Basic geometric heuristics to detect gestures for immediate 'WOW' effect
   * Detects distance between fingertips.
   */
  heuristicInference(hand) {
    const thumbTip = hand[4];
    const indexTip = hand[8];
    const middleTip = hand[12];
    const pinkyTip = hand[20];
    const wrist = hand[0];

    // Distance calculation
    const dist = (p1, p2) => Math.sqrt((p1.x - p2.x) ** 2 + (p1.y - p2.y) ** 2);

    // 1. Gesture: OK (Thumb and Index tips close, others extended)
    const thumbIndexDist = dist(thumbTip, indexTip);

        if (thumbIndexDist < 0.05 && dist(middleTip, wrist) > 0.15) {
      return { sign: 'I Understand', confidence: 0.95 };
    }

    // 2. Gesture: Hello / Wave (All fingers extended and far from palm)
    const allExtended = [8, 12, 16, 20].every(
      (i) => dist(hand[i], wrist) > 0.2
    );
    if (allExtended) {
      return { sign: 'Namaste / Hello', confidence: 0.92 };
    }

    // 3. Gesture: Peace / V-Sign
    const indexExt = dist(indexTip, wrist) > 0.2;
    const middleExt = dist(middleTip, wrist) > 0.2;
    const othersClosed = [16, 20].every((i) => dist(hand[i], wrist) < 0.15);

    if (indexExt && middleExt && othersClosed) {
      return { sign: 'Peace / Victory', confidence: 0.88 };
    }

    // 4. Gesture: Call Me (Thumb and Pinky extended)
    const thumbExt = dist(thumbTip, wrist) > 0.15;
    const pinkyExt = dist(pinkyTip, wrist) > 0.15;
    const midClosed = [8, 12, 16].every((i) => dist(hand[i], wrist) < 0.1);

    if (thumbExt && pinkyExt && midClosed) {
      return { sign: 'Call Help / SOS', confidence: 0.85 };
    }

    return { sign: null, confidence: 0 };
  }
}
