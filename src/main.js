import { Hands, HAND_CONNECTIONS } from '@mediapipe/hands';
import { drawConnectors, drawLandmarks } from '@mediapipe/drawing_utils';
import { SignClassifier } from './model.js';
import { ISLGrammarProcessor } from './nlp.js';
import { SpeechSynthesizer } from './tts.js';
import './style.css'; // Standard Vite CSS import

// DOM Elements
const videoElement = document.getElementById('webcam');
const canvasElement = document.getElementById('output_canvas');
const canvasCtx = canvasElement.getContext('2d');
const predictedSignEl = document.getElementById('predicted-sign');
const transcriptBody = document.getElementById('transcript-body');
const clearBtn = document.getElementById('clear-btn');
const langSelect = document.getElementById('language-select');
const autoSpeakToggle = document.getElementById('auto-speak');
const loadingOverlay = document.getElementById('loading-overlay');
const fpsCounter = document.getElementById('fps-counter');
const accuracyValue = document.getElementById('accuracy-value');
const statusDot = document.getElementById('status-indicator');
const statusText = document.getElementById('status-text');

// Initialize Components
const classifier = new SignClassifier();
const nlp = new ISLGrammarProcessor();
const tts = new SpeechSynthesizer();

let lastTimestamp = 0;
let frames = 0;
let isCameraRunning = false;
let currentTranscript = [];

// Hand Landmark Extraction & Processing
let hands;

async function initHands() {
  hands = new Hands({
    locateFile: (file) => {
      // Use CDN for offline-capable (cached after first load) or local assets
      return `https://cdn.jsdelivr.net/npm/@mediapipe/hands/${file}`;
    },
  });

  hands.setOptions({
    maxNumHands: 2,
    modelComplexity: 1,
    minDetectionConfidence: 0.7,
    minTrackingConfidence: 0.7,
  });

  hands.onResults(onResults);

  statusText.textContent = 'Ready';
  statusDot.classList.add('active');
  loadingOverlay.classList.add('hidden');
}

function onResults(results) {
  // Stats
  frames++;
  const now = performance.now();
  if (now > lastTimestamp + 1000) {
    fpsCounter.textContent = frames;
    frames = 0;
    lastTimestamp = now;
  }

  // Draw
  canvasCtx.save();
  canvasCtx.clearRect(0, 0, canvasElement.width, canvasElement.height);

  if (results.multiHandLandmarks) {
    for (const landmarks of results.multiHandLandmarks) {
      drawConnectors(canvasCtx, landmarks, HAND_CONNECTIONS, {
        color: '#6366f1',
        lineWidth: 5,
      });
      drawLandmarks(canvasCtx, landmarks, {
        color: '#f8fafc',
        lineWidth: 2,
        radius: 4,
      });
    }

    // Classification
    processGestures(results.multiHandLandmarks);
  } else {
    predictedSignEl.textContent = 'No hand detected';
  }

  canvasCtx.restore();
}

let lastPredictedSign = '';
let predictionCount = 0;
let CONFIDENCE_THRESHOLD = Number(localStorage.getItem('bisign_confidence')) || 8; // Require N consecutive frames of same sign (tunable)
let runtimeMode = localStorage.getItem('bisign_mode') || 'auto'; // 'auto' or 'demo'

// UI controls (may be absent in some builds)
const confidenceRange = document.getElementById('confidence-range');
const confidenceValueEl = document.getElementById('confidence-value');
const modeSelect = document.getElementById('mode-select');

if (confidenceRange && confidenceValueEl) {
  confidenceRange.value = String(CONFIDENCE_THRESHOLD);
  confidenceValueEl.textContent = String(CONFIDENCE_THRESHOLD);
  confidenceRange.addEventListener('input', (e) => {
    const v = Number(e.target.value);
    CONFIDENCE_THRESHOLD = v;
    confidenceValueEl.textContent = String(v);
    localStorage.setItem('bisign_confidence', String(v));
  });
}

if (modeSelect) {
  modeSelect.value = runtimeMode;
  modeSelect.addEventListener('change', (e) => {
    runtimeMode = e.target.value;
    localStorage.setItem('bisign_mode', runtimeMode);
  });
}

async function processGestures(landmarksList) {
  const result = await classifier.predict(landmarksList);

  // Determine effective result based on runtimeMode or model availability
  let effectiveResult = result;
  if (runtimeMode === 'demo') {
    effectiveResult = classifier.heuristicInference(landmarksList[0]);
  }

  if (effectiveResult && effectiveResult.sign) {
    predictedSignEl.textContent = effectiveResult.sign;
    accuracyValue.textContent = `${Math.round((effectiveResult.confidence || 0) * 100)}%`;

    // Stable prediction logic
    if (effectiveResult.sign === lastPredictedSign) {
      predictionCount++;
    } else {
      lastPredictedSign = effectiveResult.sign;
      predictionCount = 1;
    }

    if (predictionCount >= CONFIDENCE_THRESHOLD) {
      addToTranscript(effectiveResult.sign);
      predictionCount = 0;
    }
  } else {
    predictedSignEl.textContent = 'Wait...';
  }
}

function addToTranscript(word) {
  if (
    currentTranscript.length > 0 &&
    currentTranscript[currentTranscript.length - 1] === word
  )
    return;

  currentTranscript.push(word);

  // Clear placeholder
  if (transcriptBody.querySelector('.placeholder')) {
    transcriptBody.innerHTML = '';
  }

  const pill = document.createElement('div');
  pill.className = 'word-pill';
  pill.textContent = word;
  transcriptBody.appendChild(pill);
  transcriptBody.scrollTop = transcriptBody.scrollHeight;

  // Process Grammar & Speak
  if (autoSpeakToggle.checked) {
    handleSpeechOutput();
  }
}

async function handleSpeechOutput() {
  const sentence = nlp.reorder(currentTranscript);
  const lang = langSelect.value;

  // Real-time translation logic could go here
  // For Phase 1, we assume the signs detected are mapped to ISL vocabulary
  // We speak in the target regional language
  try {
    await tts.speak(sentence, lang);
  } catch (e) {
    console.warn('TTS failed:', e);
  }
}

// System Controls
async function startCamera() {
  try {
    const stream = await navigator.mediaDevices.getUserMedia({
      video: { width: 1280, height: 720 },
    });
    videoElement.srcObject = stream;
    isCameraRunning = true;

    // Adjust canvas size
    videoElement.onloadedmetadata = () => {
      canvasElement.width = videoElement.videoWidth;
      canvasElement.height = videoElement.videoHeight;
      sendToMediaPipe();
    };
  } catch (err) {
    console.error('Camera error:', err);
    statusText.textContent = 'Camera Error';
  }
}

async function sendToMediaPipe() {
  if (isCameraRunning) {
    await hands.send({ image: videoElement });
    requestAnimationFrame(sendToMediaPipe);
  }
}

// Event Listeners
document.getElementById('camera-toggle').addEventListener('click', () => {
  if (isCameraRunning) {
    videoElement.srcObject.getTracks().forEach((t) => t.stop());
    isCameraRunning = false;
    statusText.textContent = 'Stopped';
    statusDot.classList.remove('active');
  } else {
    // Require user consent before activating camera
    if (localStorage.getItem('bisign_camera_consent') !== 'true') {
      const modal = document.getElementById('consent-modal');
      if (modal) modal.classList.remove('hidden');
      return;
    }
    startCamera();
  }
});

clearBtn.addEventListener('click', () => {
  currentTranscript = [];
  transcriptBody.innerHTML =
    '<div class="placeholder">Signs will appear here as you gesture...</div>';
  accuracyValue.textContent = '0%';
});

// Start: initialize MediaPipe and start camera only if consent given
initHands().then(() => {
  const consentGiven = localStorage.getItem('bisign_camera_consent') === 'true';
  if (consentGiven) {
    startCamera();
  } else {
    statusText.textContent = 'Awaiting camera permission';
    window.addEventListener('bisign:consent-granted', () => startCamera(), {
      once: true,
    });
  }
});

// PWA: Service Worker Registration
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/sw.js').then(
      (registration) => {
        console.log('SW Registered with scope:', registration.scope);
      },
      (err) => {
        console.log('SW Registration failed:', err);
      }
    );
  });
}
