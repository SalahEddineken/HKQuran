#!/usr/bin/env python3
"""
HKQURAN - Automated Quran Recitations Downloader & Compressor
Downloads, compresses, and synchronizes audio for the top 6 most listened Quran reciters:
1. Mishary Rashid Alafasy (id: 7)
2. Mahmoud Khalil Al-Husary (id: 6)
3. Abdul Basit Abdul Samad (id: 2)
4. Mohamed Siddiq al-Minshawi (id: 9)
5. Abdur-Rahman as-Sudais (id: 3)
6. Sa'ud ash-Shuraym (id: 10)

- Audio Compression: 48kbps mono MP3 via FFmpeg (broadcast voice clarity, ~65% size reduction).
- Karaoke Synchronization: Fetches verse & word-by-word timing segments from api.quran.com.
- Stores files directly in local assets directories for zero-latency offline playback.
"""

import os
import sys
import json
import time
import shutil
import argparse
import tempfile
import subprocess
import urllib.request
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

# Set UTF-8 stdout on Windows
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

ROOT_DIR = Path(__file__).resolve().parent.parent
ASSETS_DIR = ROOT_DIR / "assets"
AUDIO_DIR = ASSETS_DIR / "audio"
TIMINGS_DIR = ASSETS_DIR / "quran" / "timings"

# Find FFmpeg binary
FFMPEG_CANDIDATES = [
    r"C:\Users\Salah eddine\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-9.0.2-full_build\bin\ffmpeg.exe",
    shutil.which("ffmpeg") or "ffmpeg"
]

FFMPEG_BIN = None
for cand in FFMPEG_CANDIDATES:
    if cand and (os.path.exists(cand) or shutil.which(cand)):
        FFMPEG_BIN = cand
        break

if not FFMPEG_BIN:
    raise RuntimeError("FFmpeg executable not found! Please ensure FFmpeg is installed.")

# Top 6 most listened reciters configuration
ALL_114_SURAHS = list(range(1, 115))

RECITERS_CONFIG = [
    {
        "id": 7,
        "slug": "alafasy",
        "name": "Mishary Rashid Alafasy",
        "ar_name": "مشاري راشد العفاسي",
        "folder": AUDIO_DIR,
        "url_template": "https://download.quranicaudio.com/qdc/mishari_al_afasy/murattal/{chapter}.mp3",
        "chapters": ALL_114_SURAHS
    },
    {
        "id": 6,
        "slug": "husary",
        "name": "Mahmoud Khalil Al-Husary",
        "ar_name": "محمود خليل الحصري",
        "folder": AUDIO_DIR / "husary",
        "url_template": "https://download.quranicaudio.com/qdc/khalil_al_husary/murattal/{chapter}.mp3",
        "chapters": ALL_114_SURAHS
    },
    {
        "id": 2,
        "slug": "abdul_basit",
        "name": "Abdul Basit Abdul Samad",
        "ar_name": "عبد الباسط عبد الصمد",
        "folder": AUDIO_DIR / "abdul_basit",
        "url_template": "https://download.quranicaudio.com/qdc/abdul_baset/murattal/{chapter}.mp3",
        "chapters": ALL_114_SURAHS
    },
    {
        "id": 9,
        "slug": "minshawi",
        "name": "Mohamed Siddiq al-Minshawi",
        "ar_name": "محمد صديق المنشاوي",
        "folder": AUDIO_DIR / "minshawi",
        "url_template": "https://download.quranicaudio.com/qdc/siddiq_minshawi/murattal/{chapter}.mp3",
        "chapters": ALL_114_SURAHS
    },
    {
        "id": 3,
        "slug": "sudais",
        "name": "Abdur-Rahman as-Sudais",
        "ar_name": "عبد الرحمن السديس",
        "folder": AUDIO_DIR / "sudais",
        "url_template": "https://download.quranicaudio.com/qdc/abdurrahmaan_as_sudais/murattal/{chapter}.mp3",
        "chapters": ALL_114_SURAHS
    },
    {
        "id": 10,
        "slug": "shuraym",
        "name": "Sa'ud ash-Shuraym",
        "ar_name": "سعود الشريم",
        "folder": AUDIO_DIR / "shuraym",
        "url_template": "https://download.quranicaudio.com/qdc/saud_ash-shuraym/murattal/{chapter:03d}.mp3",
        "chapters": ALL_114_SURAHS
    }
]

def ensure_folders():
    AUDIO_DIR.mkdir(parents=True, exist_ok=True)
    for r in RECITERS_CONFIG:
        r["folder"].mkdir(parents=True, exist_ok=True)
    TIMINGS_DIR.mkdir(parents=True, exist_ok=True)

def fetch_json(url, retries=3):
    req = urllib.request.Request(url, headers={'User-Agent': 'HKQuranApp/1.0 (Mozilla/5.0)'})
    for attempt in range(retries):
        try:
            with urllib.request.urlopen(req, timeout=15) as resp:
                return json.loads(resp.read().decode('utf-8'))
        except Exception as e:
            if attempt == retries - 1:
                raise e
            time.sleep(1.0 + attempt * 0.5)

def sync_timing(reciter_id, chapter, target_asset_url):
    timing_file = TIMINGS_DIR / f"{reciter_id}_{chapter}.json"
    remote_audio_url = None

    if timing_file.exists() and timing_file.stat().st_size > 100:
        try:
            with open(timing_file, 'r', encoding='utf-8') as f:
                cached = json.load(f)
                return True, "exists", cached.get('remoteUrl')
        except Exception:
            pass

    url = f"https://api.quran.com/api/v4/chapter_recitations/{reciter_id}?chapter_number={chapter}&segments=true"
    try:
        data = fetch_json(url)
        files = data.get('audio_files', [])
        if not files:
            return False, "no_audio_files", None

        f0 = files[0]
        remote_audio_url = f0.get('audio_url')
        timestamps = f0.get('timestamps', [])
        timing_list = []
        for t in timestamps:
            segs = []
            for seg in t.get('segments', []):
                if len(seg) >= 3:
                    segs.append([int(seg[0]), int(seg[1]), int(seg[2])])
            timing_list.append({
                'key': t.get('verse_key', f'{chapter}:1'),
                'from': int(t.get('timestamp_from', 0)),
                'to': int(t.get('timestamp_to', 0)),
                'segments': segs
            })

        payload = {
            'reciterId': reciter_id,
            'chapter': chapter,
            'url': target_asset_url,
            'remoteUrl': remote_audio_url or '',
            'timings': timing_list
        }

        with open(timing_file, "w", encoding="utf-8") as out:
            json.dump(payload, out, separators=(',', ':'), ensure_ascii=False)

        return True, f"{len(timing_list)} verses", remote_audio_url
    except Exception as e:
        return False, str(e), None

def download_and_compress_audio(reciter_id, chapter, url, dest_file, bitrate="48k"):
    # If destination already exists and is valid size (> 15KB), skip
    if dest_file.exists() and dest_file.stat().st_size > 15000:
        return True, dest_file.stat().st_size, dest_file.stat().st_size, "cached"

    with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as tmp_in:
        tmp_in_path = tmp_in.name

    tmp_out_path = tmp_in_path + ".compressed.mp3"

    try:
        # 1. Download
        req = urllib.request.Request(url, headers={'User-Agent': 'HKQuranApp/1.0'})
        with urllib.request.urlopen(req, timeout=40) as resp, open(tmp_in_path, 'wb') as out_f:
            shutil.copyfileobj(resp, out_f)

        orig_size = os.path.getsize(tmp_in_path)
        if orig_size < 1000:
            raise ValueError(f"Downloaded file too small: {orig_size} bytes")

        # 2. Compress using FFmpeg: mono speech at target bitrate (default 48k)
        cmd = [
            FFMPEG_BIN,
            "-y",
            "-v", "error",
            "-i", tmp_in_path,
            "-codec:a", "libmp3lame",
            "-b:a", bitrate,
            "-ac", "1",
            tmp_out_path
        ]
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if res.returncode != 0:
            raise RuntimeError(f"FFmpeg failed: {res.stderr.decode('utf-8', errors='ignore')}")

        comp_size = os.path.getsize(tmp_out_path)

        # 3. Atomically move to destination
        shutil.move(tmp_out_path, dest_file)
        return True, orig_size, comp_size, "ok"

    finally:
        for p in (tmp_in_path, tmp_out_path):
            if os.path.exists(p):
                try:
                    os.remove(p)
                except OSError:
                    pass

def process_job(reciter_id, reciter_name, chapter, url_template, folder, bitrate="48k"):
    audio_filename = f"{chapter}.mp3"
    dest_file = folder / audio_filename

    # Relative Flutter asset path
    if reciter_id == 7:
        asset_url = f"assets/audio/{chapter}.mp3"
    else:
        folder_name = folder.name
        asset_url = f"assets/audio/{folder_name}/{chapter}.mp3"

    # 1. Timing synchronization & fetch canonical remote URL
    t_ok, t_msg, remote_url = sync_timing(reciter_id, chapter, asset_url)

    # 2. Determine download source URL
    if remote_url and remote_url.startswith('http'):
        source_url = remote_url
    else:
        if "{chapter:03d}" in url_template:
            source_url = url_template.format(chapter=chapter)
        else:
            source_url = url_template.format(chapter=chapter)

    # 3. Audio download & FFmpeg compression
    a_ok, orig_sz, comp_sz, a_msg = download_and_compress_audio(
        reciter_id, chapter, source_url, dest_file, bitrate=bitrate
    )

    return {
        'reciter_id': reciter_id,
        'reciter_name': reciter_name,
        'chapter': chapter,
        'timing_ok': t_ok,
        'timing_msg': t_msg,
        'audio_ok': a_ok,
        'audio_msg': a_msg,
        'orig_size': orig_sz,
        'comp_size': comp_sz,
        'status': a_msg
    }

def main():
    parser = argparse.ArgumentParser(description="Download and compress Quran recitations.")
    parser.add_argument("--reciter", type=int, help="Specific reciter ID to process (default: all)")
    parser.add_argument("--chapters", type=str, help="Chapter range, e.g. '1-114' or '1,2,3' (default: 1-114)")
    parser.add_argument("--workers", type=int, default=6, help="Concurrent worker threads (default: 6)")
    parser.add_argument("--bitrate", type=str, default="48k", help="MP3 bitrate (default: 48k)")
    args = parser.parse_args()

    ensure_folders()

    # Determine chapters
    if args.chapters:
        if '-' in args.chapters:
            start_ch, end_ch = map(int, args.chapters.split('-'))
            target_chapters = list(range(start_ch, end_ch + 1))
        else:
            target_chapters = [int(c.strip()) for c in args.chapters.split(',')]
    else:
        target_chapters = ALL_114_SURAHS

    # Filter reciters if requested
    reciters_to_run = RECITERS_CONFIG
    if args.reciter:
        reciters_to_run = [r for r in RECITERS_CONFIG if r["id"] == args.reciter]
        if not reciters_to_run:
            print(f"Error: Unknown reciter ID {args.reciter}. Valid IDs: {[r['id'] for r in RECITERS_CONFIG]}")
            sys.exit(1)

    jobs = []
    for r in reciters_to_run:
        for ch in target_chapters:
            jobs.append((r["id"], r["name"], ch, r["url_template"], r["folder"], args.bitrate))

    print("=" * 68)
    print("HKQURAN — Downloader & FFmpeg Compressor")
    print(f"Reciters: {[r['name'] for r in reciters_to_run]}")
    print(f"Chapters: {len(target_chapters)} ({target_chapters[0]}..{target_chapters[-1]})")
    print(f"Total jobs: {len(jobs)} audio files")
    print(f"Target Bitrate: {args.bitrate} mono MP3")
    print(f"Worker Threads: {args.workers}")
    print(f"FFmpeg: {FFMPEG_BIN}")
    print("=" * 68)

    total_orig = 0
    total_comp = 0
    success_count = 0
    cached_count = 0
    fail_count = 0

    start_time = time.time()

    with ThreadPoolExecutor(max_workers=args.workers) as executor:
        future_map = {
            executor.submit(process_job, *job): job for job in jobs
        }

        completed_idx = 0
        for future in as_completed(future_map):
            completed_idx += 1
            res = future.result()
            r_name = res['reciter_name']
            ch = res['chapter']

            if res['audio_ok']:
                orig = res['orig_size']
                comp = res['comp_size']
                if res['status'] == 'cached':
                    cached_count += 1
                    status_str = f"CACHED ({comp // 1024} KB)"
                else:
                    success_count += 1
                    total_orig += orig
                    total_comp += comp
                    savings = (1 - (comp / orig)) * 100 if orig > 0 else 0
                    status_str = f"{comp // 1024} KB (-{savings:.0f}%)"

                print(f"[{completed_idx:03d}/{len(jobs)}] Surah {ch:3d} ({r_name[:15]:15s}) -> {status_str} | Timings: {res['timing_msg']}")
            else:
                fail_count += 1
                print(f"[{completed_idx:03d}/{len(jobs)}] FAILED Surah {ch:3d} ({r_name[:15]:15s}): {res['audio_msg']}")

    elapsed = time.time() - start_time
    print("=" * 68)
    print("DOWNLOAD & COMPRESSION SUMMARY")
    print(f"Total processed: {completed_idx}/{len(jobs)}")
    print(f"Newly downloaded & compressed: {success_count}")
    print(f"Already cached: {cached_count}")
    print(f"Failed: {fail_count}")
    if total_comp > 0:
        saved_mb = (total_orig - total_comp) / (1024 * 1024)
        print(f"Total new compressed size: {total_comp / (1024 * 1024):.1f} MB (Saved: {saved_mb:.1f} MB)")
    print(f"Time elapsed: {elapsed:.1f} seconds")
    print("=" * 68)

if __name__ == '__main__':
    main()
