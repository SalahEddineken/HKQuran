import json
import urllib.request
import os

def fetch_json(url):
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req, timeout=15) as res:
        return json.loads(res.read().decode('utf-8'))

surah_list = [1, 108, 109, 110, 112, 113, 114]
reciters = [7, 6, 2, 9, 3, 10]

all_verses = {}
all_timings = {}

print("Fetching verses...")
for s in surah_list:
    url = f"https://api.quran.com/api/v4/verses/by_chapter/{s}?fields=text_uthmani&words=true&word_fields=text_uthmani&translations=20&per_page=50"
    try:
        data = fetch_json(url)
        vlist = []
        for v in data.get('verses', []):
            words = []
            for w in v.get('words', []):
                if w.get('char_type_name') == 'word':
                    words.append({
                        'p': int(w['position']),
                        't': w.get('text_uthmani') or w.get('text') or ''
                    })
            words.sort(key=lambda x: x['p'])
            trans = v.get('translations', [])
            tr_text = trans[0].get('text', '') if trans else ''
            # clean HTML tags from translation if any
            tr_text = tr_text.replace('<sup foot_note=1>1</sup>', '').replace('<sup>1</sup>', '').replace('</sup>', '')
            vlist.append({
                'k': v['verse_key'],
                'n': int(v['verse_number']),
                't': v.get('text_uthmani', ''),
                'tr': tr_text,
                'w': words
            })
        all_verses[s] = vlist
        print(f"Fetched Surah {s}: {len(vlist)} verses")
    except Exception as e:
        print(f"Error fetching Surah {s}: {e}")

print("Fetching timings...")
for s in [1, 108, 112, 113, 114]:
    for r in [7]: # Mishary primary for all, plus others for 1
        url = f"https://api.quran.com/api/v4/chapter_recitations/{r}?chapter_number={s}&segments=true"
        try:
            data = fetch_json(url)
            files = data.get('audio_files', [])
            if files:
                f0 = files[0]
                timestamps = f0.get('timestamps', [])
                timing_list = []
                for t in timestamps:
                    segs = []
                    for seg in t.get('segments', []):
                        if len(seg) >= 3:
                            segs.append([int(seg[0]), int(seg[1]), int(seg[2])])
                    timing_list.append({
                        'k': t['verse_key'],
                        'f': int(t['timestamp_from']),
                        't': int(t['timestamp_to']),
                        's': segs
                    })
                all_timings[f"{r}:{s}"] = {
                    'r': r,
                    'c': s,
                    'u': f"assets/audio/{s}.mp3",
                    'remote': f0.get('audio_url', ''),
                    'timings': timing_list
                }
                print(f"Fetched timing {r}:{s}: {len(timing_list)} verses")
        except Exception as e:
            print(f"Error fetching timing {r}:{s}: {e}")

# Also fetch other reciters for Surah 1
for r in [6, 2, 9, 3, 10]:
    url = f"https://api.quran.com/api/v4/chapter_recitations/{r}?chapter_number=1&segments=true"
    try:
        data = fetch_json(url)
        files = data.get('audio_files', [])
        if files:
            f0 = files[0]
            timestamps = f0.get('timestamps', [])
            timing_list = []
            for t in timestamps:
                segs = []
                for seg in t.get('segments', []):
                    if len(seg) >= 3:
                        segs.append([int(seg[0]), int(seg[1]), int(seg[2])])
                timing_list.append({
                    'k': t['verse_key'],
                    'f': int(t['timestamp_from']),
                    't': int(t['timestamp_to']),
                    's': segs
                })
            all_timings[f"{r}:1"] = {
                'r': r,
                'c': 1,
                'u': f"assets/audio/1.mp3",
                'remote': f0.get('audio_url', ''),
                'timings': timing_list
            }
            print(f"Fetched timing {r}:1: {len(timing_list)} verses")
    except Exception as e:
        print(f"Error fetching timing {r}:1: {e}")

with open("tool/quran_data_temp.json", "w", encoding="utf-8") as out:
    json.dump({'verses': all_verses, 'timings': all_timings}, out, ensure_ascii=False, indent=2)

print("Saved tool/quran_data_temp.json successfully.")
