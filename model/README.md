This folder is for hosting a TensorFlow.js model for the SignClassifier.

Place your converted model files here (e.g. `model.json` and weight shard files like `group1-shard1of1.bin`).

How to convert a Keras `.h5` model to TFJS:

1. Install TensorFlow.js converter (requires Python):

```bash
pip install tensorflowjs
```

2. Convert a Keras model:

```bash
tensorflowjs_converter --input_format=keras path/to/model.h5 model/
```

3. Convert a TensorFlow SavedModel:

```bash
tensorflowjs_converter --input_format=tf_saved_model /path/to/saved_model model/
```

After conversion, ensure `model/model.json` is accessible from your dev server. The app will attempt to load `/model/model.json` at runtime; if not present, the app uses heuristic fallback mode.
