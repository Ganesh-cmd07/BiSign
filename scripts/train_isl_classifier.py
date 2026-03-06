"""
train_isl_classifier.py
Trains a real ISL sign classifier from the generated sign JSON files.

Pipeline:
  1. Load all assets/signs/<word>.json files
  2. Extract 42 features per frame (21 landmarks × x,y only — matching the app)
  3. Augment data (noise, scale, mirror) to build robust training set
  4. Train a small dense neural network (MobileNet-style via Keras)
  5. Export to TFLite (float32 + int8 quantized)
  6. Save to assets/models/sign_classifier.tflite + labels.txt

Output:
  assets/models/sign_classifier.tflite   (~2-5 MB)
  assets/models/labels.txt               (one label per line)
"""

import os
import json
import numpy as np
import random

# ─────────────────────────────────────────────────────────────────────────────
SIGNS_DIR  = os.path.join(os.path.dirname(__file__), '..', 'assets', 'signs')
MODELS_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'models')
TFLITE_OUT = os.path.join(MODELS_DIR, 'sign_classifier.tflite')
LABELS_OUT = os.path.join(MODELS_DIR, 'labels.txt')

INPUT_SIZE   = 42      # 21 landmarks × (x, y) — matches app's sign_classifier_service.dart
EPOCHS       = 60
BATCH_SIZE   = 32
AUGMENT_MULT = 20      # Generate N augmented samples per real frame
NOISE_SCALE  = 0.015   # Jitter magnitude for augmentation
VAL_SPLIT    = 0.15
RANDOM_SEED  = 42

np.random.seed(RANDOM_SEED)
random.seed(RANDOM_SEED)

# ─────────────────────────────────────────────────────────────────────────────
# Step 1: Load sign JSON files and extract features
# ─────────────────────────────────────────────────────────────────────────────

def extract_features(hand_landmarks):
    """
    Extract normalized 42-d feature vector from one hand's 21 landmarks.
    Uses x,y only (matches sign_classifier_service.dart).
    Features are wrist-normalized so position in frame doesn't matter.
    """
    if not hand_landmarks or all(all(v == 0 for v in lm) for lm in hand_landmarks):
        return np.zeros(INPUT_SIZE, dtype=np.float32)

    lms = np.array(hand_landmarks, dtype=np.float32)  # (21, 3)

    # Normalize relative to wrist (landmark 0)
    wrist = lms[0, :2]
    lms_xy = lms[:, :2] - wrist   # (21, 2) relative to wrist

    # Scale normalize by hand span
    span = np.max(np.abs(lms_xy)) + 1e-6
    lms_xy = lms_xy / span

    return lms_xy.flatten()   # (42,)


def load_dataset():
    sign_files = sorted([
        f for f in os.listdir(SIGNS_DIR)
        if f.endswith('.json')
    ])

    if not sign_files:
        raise RuntimeError(f'No sign JSON files found in {SIGNS_DIR}. '
                           'Run generate_isl_signs.py first.')

    labels = [os.path.splitext(f)[0] for f in sign_files]
    label_to_idx = {label: i for i, label in enumerate(labels)}

    X, y = [], []

    print(f'\n📂 Loading {len(sign_files)} sign files...')
    for sign_file in sign_files:
        label = os.path.splitext(sign_file)[0]
        idx   = label_to_idx[label]
        path  = os.path.join(SIGNS_DIR, sign_file)

        with open(path, 'r', encoding='utf-8') as f:
            data = json.load(f)

        frames = data.get('frames', [])
        for frame in frames:
            rh = frame.get('right_hand', [])
            lh = frame.get('left_hand', [])

            # Prefer right hand; fall back to left; combine if both present
            rh_feat = extract_features(rh)
            lh_feat = extract_features(lh)

            # If both hands present, add them (right hand features dominate)
            has_rh = not np.allclose(rh_feat, 0)
            has_lh = not np.allclose(lh_feat, 0)

            if has_rh:
                feat = rh_feat
            elif has_lh:
                feat = lh_feat
            else:
                continue

            X.append(feat)
            y.append(idx)

    return np.array(X, dtype=np.float32), np.array(y, dtype=np.int32), labels


# ─────────────────────────────────────────────────────────────────────────────
# Step 2: Augmentation
# ─────────────────────────────────────────────────────────────────────────────

def augment_dataset(X, y, multiplier=AUGMENT_MULT):
    """
    Expand dataset by adding noise, scaling, and mirroring.
    """
    X_aug, y_aug = [X.copy()], [y.copy()]

    for _ in range(multiplier - 1):
        noise  = np.random.normal(0, NOISE_SCALE, X.shape).astype(np.float32)
        scale  = np.random.uniform(0.85, 1.15, (X.shape[0], 1)).astype(np.float32)
        X_new  = X * scale + noise
        X_aug.append(X_new)
        y_aug.append(y.copy())

    X_out = np.concatenate(X_aug, axis=0)
    y_out = np.concatenate(y_aug, axis=0)

    # Shuffle
    perm   = np.random.permutation(len(X_out))
    return X_out[perm], y_out[perm]


# ─────────────────────────────────────────────────────────────────────────────
# Step 3: Build model
# ─────────────────────────────────────────────────────────────────────────────

def build_model(num_classes):
    import tensorflow as tf

    model = tf.keras.Sequential([
        tf.keras.layers.Input(shape=(INPUT_SIZE,)),

        # Block 1
        tf.keras.layers.Dense(256, activation='relu'),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.Dropout(0.3),

        # Block 2
        tf.keras.layers.Dense(128, activation='relu'),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.Dropout(0.3),

        # Block 3
        tf.keras.layers.Dense(64, activation='relu'),
        tf.keras.layers.Dropout(0.2),

        # Output
        tf.keras.layers.Dense(num_classes, activation='softmax'),
    ], name='isl_sign_classifier')

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=1e-3),
        loss='sparse_categorical_crossentropy',
        metrics=['accuracy'],
    )

    return model


# ─────────────────────────────────────────────────────────────────────────────
# Step 4: Train
# ─────────────────────────────────────────────────────────────────────────────

def train(model, X, y):
    import tensorflow as tf

    callbacks = [
        tf.keras.callbacks.EarlyStopping(
            monitor='val_accuracy', patience=10,
            restore_best_weights=True, verbose=1,
        ),
        tf.keras.callbacks.ReduceLROnPlateau(
            monitor='val_loss', factor=0.5, patience=5,
            min_lr=1e-5, verbose=1,
        ),
    ]

    history = model.fit(
        X, y,
        epochs=EPOCHS,
        batch_size=BATCH_SIZE,
        validation_split=VAL_SPLIT,
        callbacks=callbacks,
        verbose=1,
    )
    return history


# ─────────────────────────────────────────────────────────────────────────────
# Step 5: Export to TFLite
# ─────────────────────────────────────────────────────────────────────────────

def export_tflite(model, X_sample):
    import tensorflow as tf

    os.makedirs(MODELS_DIR, exist_ok=True)

    # Float32 conversion
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]

    # Representative dataset for int8 quantization
    def representative_data_gen():
        for i in range(0, min(500, len(X_sample)), 1):
            yield [X_sample[i:i+1]]

    converter.representative_dataset = representative_data_gen
    converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
    converter.inference_input_type  = tf.float32
    converter.inference_output_type = tf.float32

    try:
        tflite_model = converter.convert()
        print('\n✅ Int8 quantized TFLite export successful.')
    except Exception as e:
        print(f'\n⚠️  Int8 quantization failed ({e}), falling back to float32...')
        conv2 = tf.lite.TFLiteConverter.from_keras_model(model)
        conv2.optimizations = [tf.lite.Optimize.DEFAULT]
        tflite_model = conv2.convert()

    with open(TFLITE_OUT, 'wb') as f:
        f.write(tflite_model)

    size_kb = len(tflite_model) / 1024
    print(f'   Saved: {TFLITE_OUT}')
    print(f'   Size:  {size_kb:.1f} KB  ({size_kb/1024:.2f} MB)')

    return tflite_model


def verify_tflite(tflite_model, labels, X_sample, y_sample):
    import tensorflow as tf

    print('\n🔍 Verifying TFLite model...')
    interpreter = tf.lite.Interpreter(model_content=tflite_model)
    interpreter.allocate_tensors()

    input_details  = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    correct = 0
    total   = min(200, len(X_sample))

    for i in range(total):
        inp = X_sample[i:i+1]
        interpreter.set_tensor(input_details[0]['index'], inp)
        interpreter.invoke()
        out  = interpreter.get_tensor(output_details[0]['index'])
        pred = np.argmax(out[0])
        if pred == y_sample[i]:
            correct += 1

    acc = correct / total * 100
    print(f'   TFLite accuracy on {total} samples: {acc:.1f}%')
    return acc


# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────

if __name__ == '__main__':
    print('=' * 60)
    print('  BiSign ISL Classifier — Training Pipeline')
    print('=' * 60)

    # 1. Load
    X_raw, y_raw, labels = load_dataset()
    print(f'\n   Raw samples : {len(X_raw)}')
    print(f'   Classes     : {len(labels)}')
    print(f'   Input size  : {INPUT_SIZE} features')

    # 2. Augment
    print(f'\n⚙️  Augmenting dataset (×{AUGMENT_MULT})...')
    X, y = augment_dataset(X_raw, y_raw)
    print(f'   Augmented   : {len(X)} samples')

    # 3. Build
    print(f'\n🧠 Building model...')
    model = build_model(len(labels))
    model.summary()

    # 4. Train
    print(f'\n🚀 Training for up to {EPOCHS} epochs...')
    history = train(model, X, y)

    final_val_acc = max(history.history.get('val_accuracy', [0])) * 100
    print(f'\n   Best validation accuracy: {final_val_acc:.1f}%')

    # 5. Export
    print('\n📦 Exporting to TFLite...')
    tflite_model = export_tflite(model, X_raw)

    # 6. Verify
    verify_tflite(tflite_model, labels, X_raw, y_raw)

    # 7. Save labels
    with open(LABELS_OUT, 'w', encoding='utf-8') as f:
        f.write('\n'.join(labels))
    print(f'\n📝 Labels saved: {LABELS_OUT}  ({len(labels)} classes)')

    print('\n' + '=' * 60)
    print('  ✅ Training complete! Files ready for Flutter app.')
    print(f'     TFLite : {TFLITE_OUT}')
    print(f'     Labels : {LABELS_OUT}')
    print('=' * 60)
