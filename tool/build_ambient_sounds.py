import os
import sys
import requests
import miniaudio
import numpy as np
import scipy.signal
import lameenc

TARGET_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "assets", "ambient"))
os.makedirs(TARGET_DIR, exist_ok=True)

SOUND_SPECS = [
    {
        "id": "rain",
        "url": "https://raw.githubusercontent.com/remvze/moodist/main/public/sounds/rain/light-rain.mp3",
        "duration": 36.0,
        "crossfade": 4.0,
        "target_rms_db": -21.0,
        "high_shelf_lp": 13000,
    },
    {
        "id": "stream",
        "url": "https://raw.githubusercontent.com/remvze/moodist/main/public/sounds/nature/river.mp3",
        "duration": 36.0,
        "crossfade": 4.0,
        "target_rms_db": -21.0,
        "high_shelf_lp": 13000,
    },
    {
        "id": "ocean",
        "url": "https://raw.githubusercontent.com/remvze/moodist/main/public/sounds/nature/waves.mp3",
        "duration": 36.0,
        "crossfade": 4.0,
        "target_rms_db": -21.0,
        "high_shelf_lp": 13000,
    },
    {
        "id": "droplets",
        "url": "https://raw.githubusercontent.com/remvze/moodist/main/public/sounds/rain/rain-on-window.mp3",
        "duration": 29.0,
        "crossfade": 3.0,
        "target_rms_db": -22.0,
        "high_shelf_lp": 13000,
    },
    {
        "id": "birds",
        "url": "https://raw.githubusercontent.com/remvze/moodist/main/public/sounds/animals/birds.mp3",
        "duration": 36.0,
        "crossfade": 4.0,
        "target_rms_db": -22.0,
        "high_shelf_lp": 13000,
    },
    {
        "id": "fire",
        "url": "https://raw.githubusercontent.com/remvze/moodist/main/public/sounds/nature/campfire.mp3",
        "duration": 36.0,
        "crossfade": 4.0,
        "target_rms_db": -22.0,
        "high_shelf_lp": 13000,
    },
    {
        "id": "wind",
        "url": "https://raw.githubusercontent.com/remvze/moodist/main/public/sounds/nature/wind.mp3",
        "duration": 36.0,
        "crossfade": 4.0,
        "target_rms_db": -22.0,
        "high_shelf_lp": 13000,
    },
    {
        "id": "thunder",
        "url": "https://raw.githubusercontent.com/remvze/moodist/main/public/sounds/rain/thunder.mp3",
        "duration": 36.0,
        "crossfade": 4.0,
        "target_rms_db": -22.0,
        "high_shelf_lp": 13000,
    },
    {
        "id": "night",
        "url": "https://raw.githubusercontent.com/remvze/moodist/main/public/sounds/animals/crickets.mp3",
        "duration": 36.0,
        "crossfade": 4.0,
        "target_rms_db": -23.0,
        "high_shelf_lp": 13000,
    },
    {
        "id": "desert",
        "url": "https://archive.org/download/arabian-desert-sound-effects-library-wind-in-the-sand-dunes-george-vlad-youtube/Arabian%20Desert%20sound%20effects%20library%20-%20Wind%20in%20the%20sand%20dunes%20-%20George%20Vlad%20%28youtube%29.mp3",
        "duration": 36.0,
        "crossfade": 4.0,
        "target_rms_db": -22.0,
        "high_shelf_lp": 13000,
    },
]

def soft_limit(signal, threshold=0.85):
    out = signal.copy()
    over = np.abs(out) > threshold
    if np.any(over):
        excess = np.abs(out[over]) - threshold
        compressed = threshold + (1.0 - threshold) * np.tanh(excess / (1.0 - threshold))
        out[over] = np.sign(out[over]) * compressed
    return out

def create_seamless_loop(audio, sr, target_duration_sec, crossfade_sec):
    total_samples = len(audio)
    target_samples = int(target_duration_sec * sr)
    fade_samples = int(crossfade_sec * sr)

    required_samples = target_samples + fade_samples
    if total_samples < required_samples:
        repeats = int(np.ceil(required_samples / total_samples)) + 1
        audio = np.tile(audio, (repeats, 1))
        total_samples = len(audio)

    start_offset = min(int(2.0 * sr), total_samples - required_samples)
    segment = audio[start_offset:start_offset + required_samples].copy()

    t = np.linspace(0, np.pi / 2, fade_samples, endpoint=False)
    fade_in = np.sin(t).reshape(-1, 1).astype(np.float32)
    fade_out = np.cos(t).reshape(-1, 1).astype(np.float32)

    tail = segment[target_samples:target_samples + fade_samples]
    head = segment[:fade_samples]

    blended_head = head * fade_in + tail * fade_out

    loop = segment[:target_samples].copy()
    loop[:fade_samples] = blended_head
    return loop

def master_audio(loop, sr, target_rms_db, high_shelf_lp):
    # 1. High-pass filter at 35 Hz to remove DC offset and sub-rumble
    sos_hp = scipy.signal.butter(2, 35, 'hp', fs=sr, output='sos')
    loop = scipy.signal.sosfilt(sos_hp, loop, axis=0)

    # 2. Gentle low-pass / de-harshing filter
    if high_shelf_lp:
        sos_lp = scipy.signal.butter(2, high_shelf_lp, 'lp', fs=sr, output='sos')
        loop = scipy.signal.sosfilt(sos_lp, loop, axis=0)

    # 3. RMS normalization
    rms = np.sqrt(np.mean(loop**2) + 1e-12)
    current_rms_db = 20 * np.log10(rms)
    gain_linear = 10 ** ((target_rms_db - current_rms_db) / 20.0)
    loop = loop * gain_linear

    # 4. Soft knee transparent limiter at 0.88 (-1.1 dBFS)
    loop = soft_limit(loop, threshold=0.88)
    return loop.astype(np.float32)

def encode_mp3(audio, sr, bitrate_kbps=192):
    pcm_s16 = np.clip(audio * 32767.0, -32768, 32767).astype(np.int16)
    encoder = lameenc.Encoder()
    encoder.set_bit_rate(bitrate_kbps)
    encoder.set_in_sample_rate(sr)
    encoder.set_channels(audio.shape[1])
    encoder.set_quality(2)
    raw_bytes = pcm_s16.tobytes()
    mp3_data = encoder.encode(raw_bytes)
    mp3_data += encoder.flush()
    return mp3_data

def main():
    headers = {"User-Agent": "HKQuranApp/1.0 (ambient sound curation)"}
    print(f"Mastering 10 ambient soundscapes to: {TARGET_DIR}")

    results = []
    for spec in SOUND_SPECS:
        name = spec["id"]
        out_path = os.path.join(TARGET_DIR, f"{name}.mp3")
        print(f"\nProcessing '{name}' from {spec['url']}...")
        r = requests.get(spec["url"], headers=headers)
        if r.status_code != 200:
            print(f"ERROR: Failed to download {name}, status: {r.status_code}")
            sys.exit(1)

        dec = miniaudio.decode(r.content)
        arr = np.array(dec.samples, dtype=np.float32).reshape(-1, dec.nchannels) / 32768.0
        sr = dec.sample_rate

        # If mono, convert to stereo
        if arr.shape[1] == 1:
            arr = np.repeat(arr, 2, axis=1)

        loop = create_seamless_loop(arr, sr, spec["duration"], spec["crossfade"])
        mastered = master_audio(loop, sr, spec["target_rms_db"], spec["high_shelf_lp"])
        mp3_bytes = encode_mp3(mastered, sr, bitrate_kbps=192)

        with open(out_path, "wb") as f:
            f.write(mp3_bytes)

        rms_final = 20 * np.log10(np.sqrt(np.mean(mastered**2)))
        peak_final = np.max(np.abs(mastered))
        peak_db = 20 * np.log10(peak_final)

        print(f"  [OK] Saved {name}.mp3: {len(mp3_bytes):,} bytes ({len(mp3_bytes)/1024:.1f} KB), dur={spec['duration']}s, RMS={rms_final:.2f} dB, Peak={peak_db:.2f} dBFS")
        results.append({
            "name": name,
            "size_kb": len(mp3_bytes) / 1024,
            "duration": spec["duration"],
            "rms_db": rms_final,
            "peak_db": peak_db,
        })

    total_size_mb = sum(r["size_kb"] for r in results) / 1024
    print(f"\nSuccessfully mastered all 10 ambient soundscapes! Total bundle size: {total_size_mb:.2f} MB")

if __name__ == "__main__":
    main()
