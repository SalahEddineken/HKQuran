#!/usr/bin/env python3
"""
Sync and export Quran database from gaitco/quran-database.
Provenance:
  Arabic Text: Tanzil Uthmani transcription verified against KFGQPC Madinah Mushaf
  Translation: Saheeh International (en.sahih, edition 20)
  Tafsir: King Fahad Quran Complex (ar.muyassar, edition 1)
  Source Repository: https://github.com/gaitco/quran-database
"""

import os
import sys
import gzip
import json
import sqlite3
import urllib.request
from pathlib import Path

# Set stdout to UTF-8
sys.stdout.reconfigure(encoding='utf-8')

ROOT_DIR = Path(__file__).resolve().parent.parent
ASSETS_DIR = ROOT_DIR / "assets" / "quran"
SURAHS_DIR = ASSETS_DIR / "surahs"
SCRATCH_DIR = Path(r"C:\Users\Salah eddine\.gemini\antigravity-ide\brain\3c9e845b-3567-4669-b30f-1766fbf1b684\scratch")
SOURCE_DB = SCRATCH_DIR / "scratch_quran.db"

ASSETS_DIR.mkdir(parents=True, exist_ok=True)
SURAHS_DIR.mkdir(parents=True, exist_ok=True)

if not SOURCE_DB.exists():
    url = "https://raw.githubusercontent.com/gaitco/quran-database/main/quran.db.gz"
    gz_file = SCRATCH_DIR / "quran.db.gz"
    print(f"Downloading source quran.db.gz from {url}...")
    urllib.request.urlretrieve(url, gz_file)
    print("Decompressing quran.db.gz...")
    with gzip.open(gz_file, "rb") as f_in, open(SOURCE_DB, "wb") as f_out:
        while chunk := f_in.read(1024 * 1024):
            f_out.write(chunk)

print(f"Reading source database from {SOURCE_DB}...")
src = sqlite3.connect(SOURCE_DB)
c = src.cursor()

# 1. Export Compact SQLite Database (assets/quran/quran.db)
target_db = ASSETS_DIR / "quran.db"
if target_db.exists():
    target_db.unlink()

print(f"Generating optimized SQLite database at {target_db}...")
dst = sqlite3.connect(target_db)
dst.executescript("""
    PRAGMA journal_mode = MEMORY;
    PRAGMA foreign_keys = ON;
    PRAGMA encoding = 'UTF-8';

    CREATE TABLE surahs (
        id INTEGER PRIMARY KEY,
        number INTEGER NOT NULL,
        name_ar TEXT NOT NULL,
        name_en TEXT NOT NULL,
        name_en_translation TEXT NOT NULL,
        type TEXT NOT NULL
    );

    CREATE TABLE juzs (
        id INTEGER PRIMARY KEY,
        juz_number INTEGER NOT NULL UNIQUE,
        name_ar TEXT NOT NULL,
        start_ayah_id INTEGER NOT NULL,
        end_ayah_id INTEGER NOT NULL
    );

    CREATE TABLE hizbs (
        id INTEGER PRIMARY KEY,
        hizb_number INTEGER NOT NULL UNIQUE,
        juz_id INTEGER NOT NULL,
        name_ar TEXT NOT NULL,
        start_ayah_id INTEGER NOT NULL,
        end_ayah_id INTEGER NOT NULL
    );

    CREATE TABLE ayahs (
        id INTEGER PRIMARY KEY,
        number INTEGER NOT NULL,
        text TEXT NOT NULL,
        number_in_surah INTEGER NOT NULL,
        page INTEGER NOT NULL,
        surah_id INTEGER NOT NULL REFERENCES surahs(id),
        rub_id INTEGER NOT NULL,
        juz_id INTEGER NOT NULL,
        sajda INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE editions (
        id INTEGER PRIMARY KEY,
        identifier TEXT NOT NULL UNIQUE,
        language TEXT NOT NULL,
        name TEXT NOT NULL,
        english_name TEXT NOT NULL,
        type TEXT NOT NULL
    );

    CREATE TABLE ayah_edition (
        id INTEGER PRIMARY KEY,
        ayah_id INTEGER NOT NULL REFERENCES ayahs(id),
        edition_id INTEGER NOT NULL REFERENCES editions(id),
        data TEXT NOT NULL
    );

    CREATE INDEX idx_ayahs_surah_id ON ayahs(surah_id);
    CREATE INDEX idx_ayahs_number_in_surah ON ayahs(surah_id, number_in_surah);
    CREATE INDEX idx_ayah_edition_lookup ON ayah_edition(ayah_id, edition_id);
""")

surahs = src.execute("SELECT id, number, name_ar, name_en, name_en_translation, type FROM surahs").fetchall()
dst.executemany("INSERT INTO surahs VALUES (?, ?, ?, ?, ?, ?)", surahs)

juzs = src.execute("SELECT id, juz_number, name_ar, start_ayah_id, end_ayah_id FROM juzs").fetchall()
dst.executemany("INSERT INTO juzs VALUES (?, ?, ?, ?, ?)", juzs)

hizbs = src.execute("SELECT id, hizb_number, juz_id, name_ar, start_ayah_id, end_ayah_id FROM hizbs").fetchall()
dst.executemany("INSERT INTO hizbs VALUES (?, ?, ?, ?, ?, ?)", hizbs)

ayahs = src.execute("SELECT id, number, text, number_in_surah, page, surah_id, rub_id, juz_id, sajda FROM ayahs").fetchall()
dst.executemany("INSERT INTO ayahs VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", ayahs)

core_edition_ids = [20, 1]  # Saheeh International (20), Tafsir Al-Muyassar (1)
editions = src.execute(f"SELECT id, identifier, language, name, english_name, type FROM editions WHERE id IN ({','.join(map(str, core_edition_ids))})").fetchall()
dst.executemany("INSERT INTO editions VALUES (?, ?, ?, ?, ?, ?)", editions)

ayah_editions = src.execute(f"SELECT id, ayah_id, edition_id, data FROM ayah_edition WHERE edition_id IN ({','.join(map(str, core_edition_ids))})").fetchall()
dst.executemany("INSERT INTO ayah_edition VALUES (?, ?, ?, ?)", ayah_editions)

dst.commit()
dst.execute("VACUUM;")
dst.close()
print(f"Generated {target_db} ({target_db.stat().st_size / (1024*1024):.2f} MB).")

# 2. Export Metadata JSONs
print("Exporting metadata JSONs...")
surahs_meta = []
for row in surahs:
    surahs_meta.append({
        "id": row[0],
        "n": row[1],
        "ar": row[2],
        "en": row[3],
        "enTranslation": row[4],
        "type": row[5].capitalize()
    })

with open(ASSETS_DIR / "surahs.json", "w", encoding="utf-8") as f:
    json.dump(surahs_meta, f, ensure_ascii=False, indent=2)

juzs_meta = [{
    "id": r[0],
    "number": r[1],
    "nameAr": r[2],
    "startAyah": r[3],
    "endAyah": r[4]
} for r in juzs]

with open(ASSETS_DIR / "juzs.json", "w", encoding="utf-8") as f:
    json.dump(juzs_meta, f, ensure_ascii=False, indent=2)

# 3. Export 114 Surahs JSON files with words, translations, and tafsir
print("Exporting 114 surah JSON files...")
total_bytes = 0
for s_num in range(1, 115):
    c.execute("""
        SELECT a.id, a.number_in_surah, a.text, e_en.data, e_ar.data, a.page, a.juz_id, a.rub_id, a.sajda
        FROM ayahs a
        LEFT JOIN ayah_edition e_en ON e_en.ayah_id = a.id AND e_en.edition_id = 20
        LEFT JOIN ayah_edition e_ar ON e_ar.ayah_id = a.id AND e_ar.edition_id = 1
        WHERE a.surah_id = ?
        ORDER BY a.number_in_surah
    """, (s_num,))
    
    verses = []
    for row in c.fetchall():
        ayah_id, num_in_surah, text, en_tr, tafsir, page, juz_id, rub_id, sajda = row
        words = [{"p": i + 1, "t": w} for i, w in enumerate(text.split()) if w.strip()]
        verses.append({
            "k": f"{s_num}:{num_in_surah}",
            "n": num_in_surah,
            "t": text,
            "tr": en_tr or "",
            "tf": tafsir or "",
            "pg": page,
            "j": juz_id,
            "rb": rub_id,
            "s": bool(sajda),
            "w": words
        })
    
    path = SURAHS_DIR / f"{s_num}.json"
    with open(path, "w", encoding="utf-8") as f:
        json.dump(verses, f, ensure_ascii=False, separators=(',', ':'))
    total_bytes += path.stat().st_size

print(f"Successfully exported 114 surahs to {SURAHS_DIR} ({total_bytes / (1024*1024):.2f} MB total).")
src.close()
print("Done!")
