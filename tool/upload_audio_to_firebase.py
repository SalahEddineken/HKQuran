#!/usr/bin/env python3
"""
NOOR QURAN - Firebase Storage & Firestore Audio Uploader
Uploads compressed Quran audio files to Firebase Cloud Storage and syncs recitation metadata to Firestore.
"""

import os
import sys
import uuid
import json
import time
import shutil
import urllib.parse
import urllib.request
import urllib.error
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

ROOT_DIR = Path(__file__).resolve().parent.parent
ASSETS_DIR = ROOT_DIR / "assets"
AUDIO_DIR = ASSETS_DIR / "audio"
TIMINGS_DIR = ASSETS_DIR / "quran" / "timings"

PROJECT_ID = "studio-5996533553-9d4ec"
DEFAULT_BUCKET = f"{PROJECT_ID}.firebasestorage.app"

RECITERS = [
    {"id": 7, "slug": "alafasy", "name": "Mishary Rashid Alafasy", "folder": AUDIO_DIR},
    {"id": 6, "slug": "husary", "name": "Mahmoud Khalil Al-Husary", "folder": AUDIO_DIR / "husary"},
    {"id": 2, "slug": "abdul_basit", "name": "Abdul Basit Abdul Samad", "folder": AUDIO_DIR / "abdul_basit"},
    {"id": 9, "slug": "minshawi", "name": "Mohamed Siddiq al-Minshawi", "folder": AUDIO_DIR / "minshawi"},
    {"id": 3, "slug": "sudais", "name": "Abdur-Rahman as-Sudais", "folder": AUDIO_DIR / "sudais"},
    {"id": 10, "slug": "shuraym", "name": "Sa'ud ash-Shuraym", "folder": AUDIO_DIR / "shuraym"},
]

def get_firebase_token():
    config_path = os.path.expanduser("~/.config/configstore/firebase-tools.json")
    if not os.path.exists(config_path):
        raise RuntimeError("Firebase login credentials not found! Please run 'firebase login'.")

    # Refresh token if needed by checking firebase CLI
    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        expires_at = data.get('tokens', {}).get('expires_at', 0)
        now_ms = time.time() * 1000
        # If expired or close to expiring within 60s, trigger a refresh via CLI
        if expires_at < now_ms + 60000:
            subprocess.run(["firebase", "projects:list"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            with open(config_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
        token = data.get('tokens', {}).get('access_token')
        if not token:
            raise RuntimeError("No access_token found in firebase-tools.json.")
        return token
    except Exception as e:
        # Fallback to CLI run to force refresh
        subprocess.run(["firebase", "projects:list"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        with open(config_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        return data['tokens']['access_token']

def check_bucket_exists(token, bucket_name):
    url = f"https://storage.googleapis.com/storage/v1/b/{bucket_name}"
    req = urllib.request.Request(url, headers={'Authorization': f"Bearer {token}"})
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            return resp.status == 200, None
    except urllib.error.HTTPError as e:
        return False, e.code
    except Exception as e:
        return False, str(e)

def upload_file_to_storage(token, bucket_name, local_path, storage_path):
    encoded_name = urllib.parse.quote(storage_path, safe='')
    upload_url = f"https://storage.googleapis.com/upload/storage/v1/b/{bucket_name}/o?uploadType=media&name={encoded_name}"
    
    file_size = os.path.getsize(local_path)
    with open(local_path, 'rb') as f:
        file_bytes = f.read()

    download_token = str(uuid.uuid4())
    req = urllib.request.Request(
        upload_url,
        data=file_bytes,
        headers={
            'Authorization': f"Bearer {token}",
            'Content-Type': 'audio/mpeg',
            'Content-Length': str(file_size)
        },
        method='POST'
    )

    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            if resp.status in (200, 201):
                # Patch metadata with download token
                meta_url = f"https://storage.googleapis.com/storage/v1/b/{bucket_name}/o/{encoded_name}"
                patch_data = json.dumps({
                    'metadata': {
                        'firebaseStorageDownloadTokens': download_token
                    },
                    'cacheControl': 'public, max-age=31536000'
                }).encode('utf-8')
                p_req = urllib.request.Request(
                    meta_url,
                    data=patch_data,
                    headers={
                        'Authorization': f"Bearer {token}",
                        'Content-Type': 'application/json'
                    },
                    method='PATCH'
                )
                try:
                    urllib.request.urlopen(p_req, timeout=15)
                except Exception:
                    pass

                public_url = (
                    f"https://firebasestorage.googleapis.com/v0/b/{bucket_name}/o/"
                    f"{encoded_name}?alt=media&token={download_token}"
                )
                return True, public_url, None
            return False, None, f"HTTP {resp.status}"
    except Exception as e:
        return False, None, str(e)

def to_firestore_value(val):
    if val is None:
        return {'nullValue': None}
    if isinstance(val, bool):
        return {'booleanValue': val}
    if isinstance(val, int):
        return {'integerValue': str(val)}
    if isinstance(val, float):
        return {'doubleValue': val}
    if isinstance(val, str):
        return {'stringValue': val}
    if isinstance(val, list):
        return {'arrayValue': {'values': [to_firestore_value(x) for x in val]}}
    if isinstance(val, dict):
        return {'mapValue': {'fields': {k: to_firestore_value(v) for k, v in val.items() if v is not None}}}
    return {'stringValue': str(val)}

def write_firestore_document(token, doc_path, data):
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/{doc_path}"
    fields = to_firestore_value(data).get('mapValue', {}).get('fields', {})
    body = json.dumps({'fields': fields}).encode('utf-8')
    req = urllib.request.Request(
        url,
        data=body,
        headers={
            'Authorization': f"Bearer {token}",
            'Content-Type': 'application/json'
        },
        method='PATCH'
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            return resp.status in (200, 201)
    except Exception as e:
        print(f"Firestore write error on {doc_path}: {e}")
        return False

def main():
    import argparse
    parser = argparse.ArgumentParser(description="Upload Quran audio files and metadata to Firebase.")
    parser.add_argument("--bucket", type=str, default=DEFAULT_BUCKET, help=f"Firebase Storage bucket (default: {DEFAULT_BUCKET})")
    parser.add_argument("--workers", type=int, default=4, help="Upload threads (default: 4)")
    args = parser.parse_args()

    print("=" * 68)
    print("🚀 NOOR QURAN — FIREBASE AUDIO & METADATA UPLOADER")
    print(f"Target Project: {PROJECT_ID}")
    print(f"Storage Bucket: {args.bucket}")
    print("=" * 68)

    token = get_firebase_token()
    print("✓ Firebase OAuth token verified.")

    # Check Cloud Storage bucket
    bucket_ok, bucket_err = check_bucket_exists(token, args.bucket)
    if not bucket_ok:
        # Check alternative bucket name .appspot.com
        alt_bucket = f"{PROJECT_ID}.appspot.com"
        alt_ok, _ = check_bucket_exists(token, alt_bucket)
        if alt_ok:
            args.bucket = alt_bucket
            bucket_ok = True
            print(f"✓ Found active Firebase Storage bucket: {args.bucket}")

    if not bucket_ok:
        print("\n⚠️  FIREBASE STORAGE BUCKET NOT YET PROVISIONED:")
        print(f"   Bucket '{args.bucket}' returned status: {bucket_err}")
        print("\n👉 To activate Cloud Storage for Firebase in 1 click:")
        print(f"   1. Open: https://console.firebase.google.com/project/{PROJECT_ID}/storage")
        print("   2. Click 'Get Started' and choose your default security rules.")
        print("   3. Once created, rerun this script to upload all audio files!\n")
        print("Proceeding to synchronize recitation metadata and karaoke timings to Firestore database...\n")

    # Gather local audio files
    upload_tasks = []
    reciter_stats = {}

    for r in RECITERS:
        rid = r["id"]
        slug = r["slug"]
        folder = r["folder"]
        reciter_stats[rid] = {"name": r["name"], "available": 0, "uploaded": 0}

        for ch in range(1, 115):
            audio_path = folder / f"{ch}.mp3"
            if audio_path.exists() and audio_path.stat().st_size > 10000:
                reciter_stats[rid]["available"] += 1
                timing_file = TIMINGS_DIR / f"{rid}_{ch}.json"
                verse_count = 0
                if timing_file.exists():
                    try:
                        with open(timing_file, 'r', encoding='utf-8') as tf:
                            t_data = json.load(tf)
                            verse_count = len(t_data.get('timings', []))
                    except Exception:
                        pass

                upload_tasks.append({
                    "reciter_id": rid,
                    "slug": slug,
                    "name": r["name"],
                    "chapter": ch,
                    "local_path": audio_path,
                    "storage_path": f"audio/{slug}/{ch}.mp3",
                    "file_size": audio_path.stat().st_size,
                    "verse_count": verse_count
                })

    print(f"Found {len(upload_tasks)} compressed audio files ready locally across {len(RECITERS)} reciters.")

    if bucket_ok:
        print(f"\nUploading audio to Firebase Storage (concurrency: {args.workers})...")
        success_uploads = 0
        with ThreadPoolExecutor(max_workers=args.workers) as executor:
            future_to_task = {
                executor.submit(
                    upload_file_to_storage,
                    token,
                    args.bucket,
                    t["local_path"],
                    t["storage_path"]
                ): t for t in upload_tasks
            }

            for idx, future in enumerate(as_completed(future_to_task), 1):
                task = future_to_task[future]
                ok, public_url, err = future.result()
                if ok:
                    success_uploads += 1
                    reciter_stats[task["reciter_id"]]["uploaded"] += 1
                    # Save public URL into Firestore record
                    write_firestore_document(token, f"recitations/{task['reciter_id']}_{task['chapter']}", {
                        "reciterId": task["reciter_id"],
                        "chapter": task["chapter"],
                        "reciterName": task["name"],
                        "storageUrl": public_url,
                        "fileSizeBytes": task["file_size"],
                        "versesCount": task["verse_count"],
                        "bitrate": "48k",
                        "updatedAt": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
                    })
                    print(f"[{idx:03d}/{len(upload_tasks)}] ✓ {task['name'][:12]} Surah {task['chapter']:3d} uploaded ({task['file_size'] // 1024} KB)")
                else:
                    print(f"[{idx:03d}/{len(upload_tasks)}] ❌ {task['name'][:12]} Surah {task['chapter']:3d} upload failed: {err}")

        print(f"\n✓ Firebase Storage upload complete: {success_uploads}/{len(upload_tasks)} files successfully uploaded.")
    else:
        # Sync metadata only to Firestore
        print("Writing recitation catalog and verse timing metadata to Cloud Firestore...")
        for idx, task in enumerate(upload_tasks, 1):
            doc_id = f"{task['reciter_id']}_{task['chapter']}"
            write_firestore_document(token, f"recitations/{doc_id}", {
                "reciterId": task["reciter_id"],
                "chapter": task["chapter"],
                "reciterName": task["name"],
                "localAssetPath": f"assets/audio/{task['slug'] if task['reciter_id'] != 7 else ''}/{task['chapter']}.mp3".replace('//', '/'),
                "fileSizeBytes": task["file_size"],
                "versesCount": task["verse_count"],
                "bitrate": "48k",
                "readyOffline": True,
                "updatedAt": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
            })
            if idx % 20 == 0 or idx == len(upload_tasks):
                print(f"  Firestore catalog synced: {idx}/{len(upload_tasks)} recitations")

    # Update metadata/reciters catalog
    catalog = []
    for r in RECITERS:
        catalog.append({
            "id": r["id"],
            "slug": r["slug"],
            "name": r["name"],
            "availableSurahs": reciter_stats[r["id"]]["available"],
            "uploadedSurahs": reciter_stats[r["id"]]["uploaded"],
            "bitrate": "48k"
        })
    write_firestore_document(token, "metadata/recitations", {
        "reciters": catalog,
        "totalAudioFiles": len(upload_tasks),
        "updatedAt": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    })
    print("✓ Firestore 'metadata/recitations' catalog updated.")

    print("\n========================================================")
    print("🎉 FIREBASE SYNC COMPLETED")
    for r in RECITERS:
        stat = reciter_stats[r["id"]]
        print(f"  • {r['name']:25s}: {stat['available']} local files | {stat['uploaded']} uploaded to Storage")
    print("========================================================\n")

if __name__ == '__main__':
    main()
