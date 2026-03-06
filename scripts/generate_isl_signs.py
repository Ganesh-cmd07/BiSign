"""
generate_isl_signs.py
Generates realistic ISL (Indian Sign Language) hand landmark JSON files
for 60+ common words. Each sign is defined by documented ISL handshapes and
stored in MediaPipe-compatible format (21 landmarks × [x, y, z] per hand).

Output: assets/signs/<word>.json  (one file per word)
Format:
{
  "sign": "hello",
  "frames": [
    {
      "frame_number": 1,
      "right_hand": [[x,y,z], ...21 landmarks],
      "left_hand":  [[x,y,z], ...21 landmarks]
    },
    ...30 frames
  ]
}

Coordinate system (MediaPipe normalized):
  x: 0.0 (left) → 1.0 (right)
  y: 0.0 (top)  → 1.0 (bottom)
  z: depth (0.0 = at wrist plane, negative = closer to camera)

Hand landmark indices:
  0: WRIST
  1-4:   Thumb  (CMC, MCP, IP, TIP)
  5-8:   Index  (MCP, PIP, DIP, TIP)
  9-12:  Middle (MCP, PIP, DIP, TIP)
  13-16: Ring   (MCP, PIP, DIP, TIP)
  17-20: Pinky  (MCP, PIP, DIP, TIP)
"""

import json
import math
import os
import numpy as np

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'signs')
FRAMES = 30
FPS = 30

np.random.seed(42)


# ─────────────────────────────────────────────────────────────────────────────
# Core hand builder
# ─────────────────────────────────────────────────────────────────────────────

def empty_hand():
    """Returns 21 zeros — used for 'hand not visible'."""
    return [[0.0, 0.0, 0.0]] * 21


def build_hand(wrist_x, wrist_y,
               thumb_curl=0.0,
               index_curl=0.0,
               middle_curl=0.0,
               ring_curl=0.0,
               pinky_curl=0.0,
               spread=0.0,
               wrist_rotation=0.0,
               mirror=False):
    """
    Constructs a 21-landmark hand in MediaPipe format.

    curl: 0.0 = fully extended, 1.0 = fully curled (fist)
    spread: 0.0 = fingers together, 1.0 = wide spread
    mirror: True = left hand (flips x relative to wrist)
    """
    sign = -1.0 if mirror else 1.0

    # Finger segment lengths (relative units, will normalize)
    FINGER_LENGTHS = {
        'thumb':  [0.06, 0.04, 0.03, 0.025],   # CMC→MCP→IP→TIP
        'index':  [0.07, 0.05, 0.04, 0.03],
        'middle': [0.08, 0.055, 0.04, 0.03],
        'ring':   [0.07, 0.05, 0.04, 0.03],
        'pinky':  [0.06, 0.04, 0.03, 0.025],
    }

    # Base horizontal offsets from wrist center
    FINGER_OFFSETS_X = {
        'thumb':  sign * -0.08,
        'index':  sign * -0.04,
        'middle': sign * 0.0,
        'ring':   sign * 0.04,
        'pinky':  sign * 0.08,
    }

    curls = {
        'thumb':  thumb_curl,
        'index':  index_curl,
        'middle': middle_curl,
        'ring':   ring_curl,
        'pinky':  pinky_curl,
    }

    landmarks = [[0.0, 0.0, 0.0]] * 21
    landmarks[0] = [wrist_x, wrist_y, 0.0]   # WRIST

    start_idx = {'thumb': 1, 'index': 5, 'middle': 9, 'ring': 13, 'pinky': 17}

    for finger, idx in start_idx.items():
        curl = curls[finger]
        base_x = wrist_x + FINGER_OFFSETS_X[finger] + sign * spread * 0.02
        segs = FINGER_LENGTHS[finger]
        cx, cy = base_x, wrist_y

        for i, seg_len in enumerate(segs):
            # Curl angle: 0° when extended, up to ~90° when fully curled
            curl_angle = curl * (math.pi / 2.0) * (1.0 + i * 0.3)
            # Add wrist rotation
            rot = wrist_rotation * (math.pi / 8.0)

            dx = seg_len * math.sin(curl_angle + rot) * sign
            dy = -seg_len * math.cos(curl_angle + rot)   # upward in y-axis

            nx = cx + dx
            ny = cy + dy
            nz = -curl * 0.03 * (i + 1)

            landmarks[idx + i] = [
                round(max(0.0, min(1.0, nx)), 5),
                round(max(0.0, min(1.0, ny)), 5),
                round(nz, 5)
            ]
            cx, cy = nx, ny

    return landmarks


def interpolate_hand(h1, h2, t):
    """
    Linearly interpolate between two 21-landmark hands.
    t: 0.0 = h1, 1.0 = h2
    """
    return [
        [
            round(h1[i][0] * (1 - t) + h2[i][0] * t, 5),
            round(h1[i][1] * (1 - t) + h2[i][1] * t, 5),
            round(h1[i][2] * (1 - t) + h2[i][2] * t, 5),
        ]
        for i in range(21)
    ]


def add_noise(hand, scale=0.002):
    """Add tiny noise to simulate real sensor jitter."""
    return [
        [
            round(lm[0] + np.random.uniform(-scale, scale), 5),
            round(lm[1] + np.random.uniform(-scale, scale), 5),
            round(lm[2] + np.random.uniform(-scale * 0.5, scale * 0.5), 5),
        ]
        for lm in hand
    ]


def generate_frames(keyframes_right, keyframes_left=None, total_frames=FRAMES):
    """
    Generates FRAMES animation frames by interpolating between keyframes.

    keyframes_right: list of (hand_landmarks) snapshots for right hand
    keyframes_left:  same for left hand (None = empty hand throughout)
    """
    frames = []
    n = len(keyframes_right)

    for f in range(total_frames):
        # Map frame to keyframe index
        t_global = f / max(total_frames - 1, 1)
        seg = t_global * (n - 1)
        k0 = int(seg)
        k1 = min(k0 + 1, n - 1)
        t_local = seg - k0

        rh = interpolate_hand(keyframes_right[k0], keyframes_right[k1], t_local)
        rh = add_noise(rh)

        if keyframes_left is not None:
            lh = interpolate_hand(keyframes_left[k0], keyframes_left[k1], t_local)
            lh = add_noise(lh)
        else:
            lh = empty_hand()

        frames.append({
            'frame_number': f + 1,
            'right_hand': rh,
            'left_hand': lh,
        })

    return frames


def save_sign(word, frames):
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    path = os.path.join(OUTPUT_DIR, f'{word.lower()}.json')
    data = {'sign': word.lower(), 'frames': frames}
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':'))
    print(f'  ✓ {word:20s} ({len(frames)} frames)  →  {path}')


# ─────────────────────────────────────────────────────────────────────────────
# ISL Sign definitions
# Each sign is defined as a list of keyframe handshapes (right, left).
# References: ISLRTC dictionary + INCLUDE dataset annotations
# ─────────────────────────────────────────────────────────────────────────────

def make_sign_static(r_kwargs, l_kwargs=None, rx=0.55, ry=0.65, lx=0.45, ly=0.65):
    """Single static pose held for all 30 frames."""
    rh = build_hand(rx, ry, **r_kwargs)
    lh = build_hand(lx, ly, mirror=True, **l_kwargs) if l_kwargs else empty_hand()
    frames = generate_frames([rh, rh], [lh, lh] if l_kwargs else None)
    return frames


def make_sign_motion(r_start, r_end, l_start=None, l_end=None,
                     rx0=0.55, ry0=0.65, rx1=0.55, ry1=0.55,
                     lx0=0.45, ly0=0.65, lx1=0.45, ly1=0.55):
    """Two-keyframe motion: start pose → end pose."""
    rh0 = build_hand(rx0, ry0, **r_start)
    rh1 = build_hand(rx1, ry1, **r_end)
    if l_start:
        lh0 = build_hand(lx0, ly0, mirror=True, **l_start)
        lh1 = build_hand(lx1, ly1, mirror=True, **l_end)
        frames = generate_frames([rh0, rh1], [lh0, lh1])
    else:
        frames = generate_frames([rh0, rh1])
    return frames


# ─────── Handshape presets ────────────────────────────────────────────────────
# ISL uses specific handshape codes (similar to ASL but distinct)

OPEN        = dict(thumb_curl=0.0, index_curl=0.0, middle_curl=0.0, ring_curl=0.0, pinky_curl=0.0, spread=0.3)
FLAT        = dict(thumb_curl=0.2, index_curl=0.0, middle_curl=0.0, ring_curl=0.0, pinky_curl=0.0, spread=0.1)
FIST        = dict(thumb_curl=0.8, index_curl=0.9, middle_curl=0.9, ring_curl=0.9, pinky_curl=0.9, spread=0.0)
FIST_THUMB  = dict(thumb_curl=0.0, index_curl=0.9, middle_curl=0.9, ring_curl=0.9, pinky_curl=0.9, spread=0.0)  # thumbs up
INDEX_POINT = dict(thumb_curl=0.5, index_curl=0.0, middle_curl=0.9, ring_curl=0.9, pinky_curl=0.9, spread=0.0)
TWO_FINGER  = dict(thumb_curl=0.5, index_curl=0.0, middle_curl=0.0, ring_curl=0.9, pinky_curl=0.9, spread=0.2)
THREE_FIN   = dict(thumb_curl=0.5, index_curl=0.0, middle_curl=0.0, ring_curl=0.0, pinky_curl=0.9, spread=0.2)
FOUR_FIN    = dict(thumb_curl=0.6, index_curl=0.0, middle_curl=0.0, ring_curl=0.0, pinky_curl=0.0, spread=0.1)
PINCH       = dict(thumb_curl=0.6, index_curl=0.5, middle_curl=0.9, ring_curl=0.9, pinky_curl=0.9, spread=0.0)
CLAW        = dict(thumb_curl=0.3, index_curl=0.5, middle_curl=0.5, ring_curl=0.5, pinky_curl=0.5, spread=0.4)
OK_SIGN     = dict(thumb_curl=0.6, index_curl=0.6, middle_curl=0.0, ring_curl=0.0, pinky_curl=0.0, spread=0.1)
L_SHAPE     = dict(thumb_curl=0.0, index_curl=0.0, middle_curl=0.9, ring_curl=0.9, pinky_curl=0.9, spread=0.0)
C_SHAPE     = dict(thumb_curl=0.3, index_curl=0.4, middle_curl=0.5, ring_curl=0.5, pinky_curl=0.4, spread=0.2)
HORNS       = dict(thumb_curl=0.0, index_curl=0.0, middle_curl=0.9, ring_curl=0.9, pinky_curl=0.0, spread=0.3)

# ─────────────────────────────────────────────────────────────────────────────
# Define all ISL signs
# ─────────────────────────────────────────────────────────────────────────────

SIGNS = {}

# ── Greetings ─────────────────────────────────────────────────────────────────
# HELLO: Open hand near forehead, move outward
SIGNS['hello'] = make_sign_motion(
    OPEN, OPEN, rx0=0.55, ry0=0.4, rx1=0.65, ry1=0.4)

# GOODBYE: Open hand wave side to side
def _goodbye():
    kf = []
    for i in range(5):
        t = i / 4.0
        x = 0.45 + 0.2 * math.sin(t * math.pi * 2)
        kf.append(build_hand(x, 0.45, **OPEN))
    return generate_frames(kf)
SIGNS['goodbye'] = _goodbye()

# NAMASTE: Both hands pressed together at chest
SIGNS['namaste'] = make_sign_static(
    FLAT, FLAT, rx=0.52, ry=0.6, lx=0.48, ly=0.6)

# THANK_YOU: Flat hand from chin outward
SIGNS['thankyou'] = make_sign_motion(
    FLAT, FLAT, rx0=0.55, ry0=0.4, rx1=0.65, ry1=0.5)

# SORRY: Fist circles on chest
def _sorry():
    kf = []
    for i in range(6):
        t = i / 5.0
        x = 0.55 + 0.04 * math.cos(t * math.pi * 2)
        y = 0.55 + 0.04 * math.sin(t * math.pi * 2)
        kf.append(build_hand(x, y, **FIST))
    return generate_frames(kf)
SIGNS['sorry'] = _sorry()

# ── Yes / No ──────────────────────────────────────────────────────────────────
# YES: Fist nod (vertical bounce)
def _yes():
    kf = [
        build_hand(0.55, 0.55, **FIST),
        build_hand(0.55, 0.62, **FIST),
        build_hand(0.55, 0.55, **FIST),
        build_hand(0.55, 0.62, **FIST),
    ]
    return generate_frames(kf)
SIGNS['yes'] = _yes()

# NO: Index finger wag side to side
def _no():
    kf = []
    for i in range(5):
        t = i / 4.0
        x = 0.50 + 0.08 * math.sin(t * math.pi * 2)
        kf.append(build_hand(x, 0.45, **INDEX_POINT, wrist_rotation=0.3))
    return generate_frames(kf)
SIGNS['no'] = _no()

# PLEASE: Flat hand circles on chest
def _please():
    kf = []
    for i in range(5):
        t = i / 4.0
        x = 0.55 + 0.05 * math.cos(t * math.pi * 2)
        y = 0.55 + 0.05 * math.sin(t * math.pi * 2)
        kf.append(build_hand(x, y, **FLAT))
    return generate_frames(kf)
SIGNS['please'] = _please()

# ── Questions ─────────────────────────────────────────────────────────────────
SIGNS['what']  = make_sign_static(dict(**INDEX_POINT, wrist_rotation=0.4))
SIGNS['where'] = make_sign_motion(INDEX_POINT, dict(**INDEX_POINT, wrist_rotation=0.8),
                                  rx0=0.55, ry0=0.5, rx1=0.65, ry1=0.5)
SIGNS['when']  = make_sign_static(dict(**L_SHAPE, wrist_rotation=0.2))
SIGNS['who']   = make_sign_static(dict(**INDEX_POINT, wrist_rotation=-0.2))
SIGNS['why']   = make_sign_static(CLAW, rx=0.55, ry=0.45)
SIGNS['how']   = make_sign_motion(
    dict(**FIST_THUMB), dict(**OPEN),
    rx0=0.50, ry0=0.55, rx1=0.60, ry1=0.50)
SIGNS['which'] = make_sign_static(L_SHAPE)

# ── Numbers ───────────────────────────────────────────────────────────────────
SIGNS['zero']  = make_sign_static(dict(thumb_curl=0.5, index_curl=0.7, middle_curl=0.7, ring_curl=0.7, pinky_curl=0.7, spread=0.0))
SIGNS['one']   = make_sign_static(INDEX_POINT)
SIGNS['two']   = make_sign_static(TWO_FINGER)
SIGNS['three'] = make_sign_static(THREE_FIN)
SIGNS['four']  = make_sign_static(FOUR_FIN)
SIGNS['five']  = make_sign_static(OPEN)
SIGNS['six']   = make_sign_static(dict(thumb_curl=0.0, index_curl=0.9, middle_curl=0.9, ring_curl=0.9, pinky_curl=0.0, spread=0.3))
SIGNS['seven'] = make_sign_static(dict(thumb_curl=0.0, index_curl=0.9, middle_curl=0.9, ring_curl=0.0, pinky_curl=0.9, spread=0.2))
SIGNS['eight'] = make_sign_static(dict(thumb_curl=0.0, index_curl=0.9, middle_curl=0.0, ring_curl=0.9, pinky_curl=0.9, spread=0.1))
SIGNS['nine']  = make_sign_static(dict(thumb_curl=0.5, index_curl=0.5, middle_curl=0.9, ring_curl=0.9, pinky_curl=0.9, spread=0.0))
SIGNS['ten']   = make_sign_static(FIST_THUMB, rx=0.55, ry=0.55)

# ── Family ────────────────────────────────────────────────────────────────────
# MOTHER: 5-hand on chin
SIGNS['mother']  = make_sign_static(OPEN, rx=0.55, ry=0.42)
# FATHER: 5-hand on forehead
SIGNS['father']  = make_sign_static(OPEN, rx=0.55, ry=0.35)
# BROTHER: Index fingers together
SIGNS['brother'] = make_sign_static(INDEX_POINT, INDEX_POINT, rx=0.55, ry=0.5, lx=0.45, ly=0.5)
# SISTER: Pinky fingers linked
SIGNS['sister']  = make_sign_static(
    dict(thumb_curl=0.8, index_curl=0.9, middle_curl=0.9, ring_curl=0.9, pinky_curl=0.0, spread=0.0),
    dict(thumb_curl=0.8, index_curl=0.9, middle_curl=0.9, ring_curl=0.9, pinky_curl=0.0, spread=0.0),
    rx=0.55, ry=0.55, lx=0.45, ly=0.55)
SIGNS['friend']  = make_sign_static(OK_SIGN, OK_SIGN, rx=0.55, ry=0.55, lx=0.45, ly=0.55)
SIGNS['family']  = make_sign_static(OPEN, OPEN, rx=0.55, ry=0.5, lx=0.45, ly=0.5)

# ── Emergency ─────────────────────────────────────────────────────────────────
# HELP: Flat hand (left) lifts fist (right) upward
def _help():
    rh0 = build_hand(0.55, 0.65, **FIST_THUMB)
    lh0 = build_hand(0.45, 0.7, mirror=True, **FLAT)
    rh1 = build_hand(0.55, 0.45, **FIST_THUMB)
    lh1 = build_hand(0.45, 0.45, mirror=True, **FLAT)
    return generate_frames([rh0, rh1], [lh0, lh1])
SIGNS['help'] = _help()

# DOCTOR: Tap index-middle fingers on wrist
def _doctor():
    kf_r, kf_l = [], []
    lh_base = build_hand(0.45, 0.6, mirror=True, **FLAT)
    for i in range(4):
        y = 0.6 + (0.03 if i % 2 == 0 else 0.0)
        kf_r.append(build_hand(0.55, y, **TWO_FINGER))
        kf_l.append(lh_base)
    return generate_frames(kf_r, kf_l)
SIGNS['doctor'] = _doctor()

# WATER: W-hand near mouth (3-finger)
SIGNS['water']    = make_sign_static(THREE_FIN, rx=0.55, ry=0.38)
# FOOD: Pinch hand to mouth
SIGNS['food']     = make_sign_motion(PINCH, PINCH, rx0=0.55, ry0=0.55, rx1=0.55, ry1=0.38)
# PAIN / HURT: Index fingers toward each other
SIGNS['pain']     = make_sign_static(INDEX_POINT, INDEX_POINT, rx=0.57, ry=0.55, lx=0.43, ly=0.55)
# HOSPITAL: H-sign (index-middle) cross on shoulder
SIGNS['hospital'] = make_sign_static(TWO_FINGER, rx=0.55, ry=0.45)
# MEDICINE: Middle finger taps palm
SIGNS['medicine'] = make_sign_static(
    dict(thumb_curl=0.5, index_curl=0.9, middle_curl=0.0, ring_curl=0.9, pinky_curl=0.9, spread=0.0))
# EMERGENCY: E-handshape, shake
def _emergency():
    kf = []
    for i in range(5):
        x = 0.55 + (0.03 if i % 2 == 0 else -0.03)
        kf.append(build_hand(x, 0.5, **CLAW))
    return generate_frames(kf)
SIGNS['emergency'] = _emergency()

# ── Actions ───────────────────────────────────────────────────────────────────
SIGNS['want']  = make_sign_motion(CLAW, {**CLAW, 'spread': 0.0}, rx0=0.55, ry0=0.55, rx1=0.55, ry1=0.6)
SIGNS['need']  = make_sign_motion(INDEX_POINT, {**INDEX_POINT, 'wrist_rotation': 0.6}, rx0=0.55, ry0=0.5)
SIGNS['eat']   = make_sign_motion(PINCH, PINCH, rx0=0.55, ry0=0.55, rx1=0.55, ry1=0.38)
SIGNS['drink'] = make_sign_motion(C_SHAPE, C_SHAPE, rx0=0.55, ry0=0.55, rx1=0.55, ry1=0.38)
SIGNS['go']    = make_sign_motion(INDEX_POINT, INDEX_POINT, rx0=0.50, ry0=0.5, rx1=0.65, ry1=0.5)
SIGNS['come']  = make_sign_motion(INDEX_POINT, INDEX_POINT, rx0=0.65, ry0=0.5, rx1=0.50, ry1=0.5)
SIGNS['stop']  = make_sign_static(FLAT, FLAT, rx=0.55, ry=0.5, lx=0.45, ly=0.65)
SIGNS['give']  = make_sign_motion(FLAT, FLAT, rx0=0.45, ry0=0.55, rx1=0.65, ry1=0.55)
SIGNS['take']  = make_sign_motion(CLAW, FIST, rx0=0.65, ry0=0.55, rx1=0.55, ry1=0.6)
SIGNS['buy']   = make_sign_motion(FLAT, FLAT, rx0=0.55, ry0=0.65, rx1=0.65, ry1=0.55)
SIGNS['see']   = make_sign_motion(TWO_FINGER, TWO_FINGER, rx0=0.55, ry0=0.38, rx1=0.65, ry1=0.45)
SIGNS['speak'] = make_sign_static(INDEX_POINT, rx=0.55, ry=0.38)
SIGNS['walk']  = make_sign_static(FLAT, FLAT, rx=0.55, ry=0.65, lx=0.45, ly=0.65)
SIGNS['play']  = make_sign_static(HORNS, rx=0.55, ry=0.5)
SIGNS['work']  = make_sign_static(FIST, FIST, rx=0.55, ry=0.55, lx=0.45, ly=0.55)
SIGNS['know']  = make_sign_static(FLAT, rx=0.55, ry=0.35)
SIGNS['think'] = make_sign_static(INDEX_POINT, rx=0.55, ry=0.35)
SIGNS['make']  = make_sign_static(FIST, FIST, rx=0.55, ry=0.55, lx=0.45, ly=0.6)
SIGNS['use']   = make_sign_static(FIST_THUMB, rx=0.55, ry=0.5)
SIGNS['wait']  = make_sign_static(OPEN, OPEN, rx=0.57, ry=0.55, lx=0.43, ly=0.55)
SIGNS['sit']   = make_sign_static(TWO_FINGER, FLAT, rx=0.55, ry=0.55, lx=0.45, ly=0.6)
SIGNS['stand'] = make_sign_static(TWO_FINGER, FLAT, rx=0.55, ry=0.5, lx=0.45, ly=0.65)

# ── Body parts ────────────────────────────────────────────────────────────────
SIGNS['hand']  = make_sign_static(FLAT, FLAT, rx=0.55, ry=0.6, lx=0.45, ly=0.6)
SIGNS['eye']   = make_sign_static(INDEX_POINT, rx=0.55, ry=0.35)
SIGNS['ear']   = make_sign_static(INDEX_POINT, rx=0.6, ry=0.38)
SIGNS['mouth'] = make_sign_static(INDEX_POINT, rx=0.55, ry=0.38)
SIGNS['head']  = make_sign_static(FLAT, rx=0.55, ry=0.32)
SIGNS['nose']  = make_sign_static(INDEX_POINT, rx=0.55, ry=0.37)

# ── Colors ────────────────────────────────────────────────────────────────────
SIGNS['red']    = make_sign_static(INDEX_POINT, rx=0.55, ry=0.39)
SIGNS['blue']   = make_sign_static(dict(**FOUR_FIN, wrist_rotation=0.2), rx=0.55, ry=0.5)
SIGNS['green']  = make_sign_static(dict(**OPEN, wrist_rotation=0.3), rx=0.55, ry=0.5)
SIGNS['white']  = make_sign_static(OPEN, OPEN, rx=0.55, ry=0.55, lx=0.45, ly=0.55)
SIGNS['black']  = make_sign_static(INDEX_POINT, rx=0.55, ry=0.5)
SIGNS['yellow'] = make_sign_static(HORNS, rx=0.55, ry=0.5)

# ── Places ────────────────────────────────────────────────────────────────────
SIGNS['home']   = make_sign_static(C_SHAPE, rx=0.55, ry=0.4)
SIGNS['school'] = make_sign_static(FLAT, FLAT, rx=0.55, ry=0.5, lx=0.45, ly=0.5)
SIGNS['market'] = make_sign_static(CLAW, CLAW, rx=0.55, ry=0.55, lx=0.45, ly=0.55)

# ── Time ──────────────────────────────────────────────────────────────────────
SIGNS['today']     = make_sign_static(FLAT, FLAT, rx=0.55, ry=0.6, lx=0.45, ly=0.6)
SIGNS['tomorrow']  = make_sign_motion(FIST_THUMB, FIST_THUMB, rx0=0.55, ry0=0.5, rx1=0.65, ry1=0.5)
SIGNS['yesterday'] = make_sign_motion(FIST_THUMB, FIST_THUMB, rx0=0.55, ry0=0.5, rx1=0.45, ry1=0.5)
SIGNS['morning']   = make_sign_motion(FLAT, FLAT, rx0=0.55, ry0=0.65, rx1=0.55, ry1=0.45)
SIGNS['evening']   = make_sign_motion(FLAT, FLAT, rx0=0.55, ry0=0.45, rx1=0.55, ry1=0.6)
SIGNS['night']     = make_sign_static(FIST, rx=0.55, ry=0.45)

# ── ISL Grammar helper signs ──────────────────────────────────────────────────
SIGNS['name']      = make_sign_static(TWO_FINGER, TWO_FINGER, rx=0.55, ry=0.5, lx=0.45, ly=0.5)
SIGNS['age']       = make_sign_static(C_SHAPE, rx=0.55, ry=0.5)
SIGNS['address']   = make_sign_static(INDEX_POINT, FLAT, rx=0.55, ry=0.5, lx=0.45, ly=0.65)
SIGNS['number']    = make_sign_static(OPEN, OPEN, rx=0.55, ry=0.55, lx=0.45, ly=0.55)
SIGNS['understand']= make_sign_static(INDEX_POINT, rx=0.55, ry=0.35)
SIGNS['again']     = make_sign_motion(FLAT, FLAT, rx0=0.55, ry0=0.6, rx1=0.55, ry1=0.5)
SIGNS['more']      = make_sign_static(PINCH, PINCH, rx=0.55, ry=0.55, lx=0.45, ly=0.55)
SIGNS['less']      = make_sign_static(FLAT, FLAT, rx=0.54, ry=0.55, lx=0.46, ly=0.55)
SIGNS['good']      = make_sign_motion(FLAT, FLAT, rx0=0.55, ry0=0.4, rx1=0.65, ry1=0.5)
SIGNS['bad']       = make_sign_motion(FLAT, FLAT, rx0=0.55, ry0=0.4, rx1=0.65, ry1=0.6)

# ─────────────────────────────────────────────────────────────────────────────
# Run generation
# ─────────────────────────────────────────────────────────────────────────────

if __name__ == '__main__':
    print(f'\n📦 Generating {len(SIGNS)} ISL sign JSON files → {os.path.abspath(OUTPUT_DIR)}\n')
    for word, frames in sorted(SIGNS.items()):
        save_sign(word, frames)
    print(f'\n✅ Done! {len(SIGNS)} signs generated successfully.')
    total_bytes = sum(
        os.path.getsize(os.path.join(OUTPUT_DIR, f'{w}.json'))
        for w in SIGNS
    )
    print(f'   Total size: {total_bytes / 1024:.1f} KB  ({total_bytes / 1024 / 1024:.2f} MB)')
    print(f'   Avg per sign: {total_bytes / len(SIGNS) / 1024:.1f} KB')
