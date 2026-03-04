# BiSign

BiSign is a client-side Progressive Web App that detects hand gestures (Indian Sign Language) and speaks them in regional languages.

## Run (development)

Requires Node.js and npm.

```bash
npm install
npm run dev
```

Open http://localhost:5173 (Vite default) and allow camera access.

## Notes

- The project uses MediaPipe Hands and TensorFlow.js. To enable accurate classification, place a trained TF.js model at `/model/model.json` (and supporting files in `/model/`). If not present, the app uses geometric heuristics as a demo fallback.
- Service worker caches only the local app shell and caches large CDN assets at runtime.
- Speech uses the Web Speech API; availability of regional voices depends on the platform/browser.

## Code quality & tests

Run lint and tests (after `npm install`):

```bash
npm run lint
npm test
```

I added basic ESLint/Prettier and a Jest test for `src/nlp.js` as a smoke test. Install dev dependencies with `npm install` before running.

## Runtime Configuration

The app stores user preferences in browser `localStorage`:
- `bisign_camera_consent`: camera permission acknowledgment (true/false).
- `bisign_confidence`: prediction stability threshold (1–20 frames; default 8). Adjust via the **Prediction Stability** slider.
- `bisign_mode`: classification mode (`auto` for model or heuristic fallback, `demo` for heuristics only). Adjust via the **Mode** dropdown.

## Model Setup

### Using Heuristics (default)

The app detects basic gestures (Hello, Peace, Call Help) using geometric heuristics. No model file required.

### Using a Trained TensorFlow.js Model

1. **Prepare your model** (Keras `.h5`, TensorFlow SavedModel, or already-converted TFJS):

   - If Keras `.h5`:
     ```bash
     pip install tensorflowjs
     tensorflowjs_converter --input_format=keras model.h5 model/
     ```
   - If TensorFlow SavedModel:
     ```bash
     tensorflowjs_converter --input_format=tf_saved_model /path/to/saved_model model/
     ```
   - If already TFJS: Copy `model.json` and weight shard files to `model/`.

2. **Verify** your `model/` folder contains `model.json` and `.bin` weight shard files.

3. **Restart** the dev server or reload the app. The classifier will attempt to load `/model/model.json` on startup.

4. **Check** browser console for `Sign Classifier: TF model loaded.` (success) or fallback warning.

## CI/CD with GitHub Actions

A GitHub Actions workflow runs automatically on push/PR (`.github/workflows/ci.yml`):
- Installs dependencies
- Runs ESLint
- Runs Jest tests
- Builds production bundle

View results in the **Actions** tab on GitHub.

## Build & Deploy

### Build for production:

```bash
npm run build
```

Output is in `dist/`. Files can be deployed to:
- **Netlify**: Drag `dist/` to Netlify drop zone, or connect Git repo.
- **Vercel**: Connect Git repo; auto-deploys on push.
- **GitHub Pages**: Push `dist/` to `gh-pages` branch or use GitHub Actions to build & deploy.
- **Static host** (AWS S3, Firebase Hosting, etc.): Upload `dist/` contents.

### HTTPS requirement

- Camera access (`getUserMedia`) requires **HTTPS** (or `localhost` for dev). Ensure your hosting provider supports HTTPS.

### Service Worker

- The PWA installs a service worker (`sw.js`) to cache app shell and CDN assets at runtime.
- Users can work offline after the first visit.
- To update the app, increment `CACHE_NAME` in `sw.js` and redeploy.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Camera not starting | Check HTTPS (or localhost), browser permissions, console errors. |
| No predictions | Ensure good lighting; try adjusting **Prediction Stability** slider. |
| Model not loading | Verify `model/model.json` exists; check browser console. Falls back to heuristics if missing. |
| Speech not working | Check if browser/OS has regional voices available; some browsers/languages have limited support. |
| Service worker issues | Clear browser cache (`Ctrl+Shift+Delete`), reload page. |

## Project Structure

```
BiSign/
├── src/
│   ├── main.js           # App entry, camera, gesture processing
│   ├── model.js          # SignClassifier (TF.js or heuristics)
│   ├── nlp.js            # ISL grammar processor
│   ├── tts.js            # Speech synthesis (Web Speech API)
│   └── style.css         # UI styles (glassmorphism design)
├── tests/
│   └── nlp.test.js       # Jest smoke test
├── model/                # TF.js model files (if any)
├── public/               # Static assets (if any)
├── index.html            # App shell + consent modal
├── sw.js                 # Service worker (PWA)
├── manifest.json         # PWA metadata
├── .github/workflows/ci.yml  # GitHub Actions CI
├── .eslintrc.json        # ESLint config
├── .prettierrc           # Prettier config
├── jest.config.cjs       # Jest config
├── package.json          # Dependencies & scripts
└── README.md             # This file
```

## Next Steps

- Bundle or host a trained TF.js model and wire training artifacts
- Improve grammar mapping and translation integration
- Expand gestures and vocabulary in `src/model.js` heuristics or real model
