import json
import re

with open("tool/quran_data_temp.json", "r", encoding="utf-8") as f:
    data = json.load(f)

verses_data = data['verses']
timings_data = data['timings']

out = []
out.append("// PURE DART LOCAL QURAN DATA SOURCE")
out.append("// This file stores all reciter audio references, surahs, verses,")
out.append("// and follow-up (karaoke timings) directly in code source — no API required!")
out.append("//")
out.append("// You can easily add more surahs, verses, or custom reciter timings here.")
out.append("")
out.append("import 'models.dart';")
out.append("")
out.append("/// Static local verse registry for starter surahs.")
out.append("/// Add your custom surahs and verses directly to this map.")
out.append("const Map<int, List<Verse>> kLocalSurahVerses = {")

for s_str, vlist in sorted(verses_data.items(), key=lambda x: int(x[0])):
    s = int(s_str)
    out.append(f"  {s}: [")
    for v in vlist:
        key = v['k']
        num = v['n']
        text = v['t'].replace("'", "\\'")
        # Strip all HTML tags and trailing footnote numbers
        clean_tr = re.sub(r'<[^>]*>', '', v['tr'])
        clean_tr = re.sub(r'\s*\d+\s*$', '', clean_tr).strip()
        clean_tr = re.sub(r'\s{2,}', ' ', clean_tr)
        clean_tr = clean_tr.replace("'", "\\'")
        out.append("    Verse(")
        out.append(f"      key: '{key}',")
        out.append(f"      number: {num},")
        out.append(f"      text: '{text}',")
        out.append(f"      translation: '{clean_tr}',")
        out.append("      words: [")
        for w in v['w']:
            wp = w['p']
            wt = w['t'].replace("'", "\\'")
            out.append(f"        AyahWord({wp}, '{wt}'),")
        out.append("      ],")
        out.append("    ),")
    out.append("  ],")

out.append("};")
out.append("")
out.append("/// Static local follow-up (audio URLs + karaoke timings) registry.")
out.append("/// Key format: 'reciterId:chapterNumber' (e.g. '7:1' for Mishary Surah 1).")
out.append("const Map<String, ChapterAudio> kLocalChapterAudio = {")

for key, tdata in sorted(timings_data.items()):
    r = tdata['r']
    c = tdata['c']
    u = tdata['u']
    timings = tdata['timings']
    out.append(f"  '{key}': ChapterAudio(")
    out.append(f"    reciterId: {r},")
    out.append(f"    chapter: {c},")
    out.append(f"    url: '{u}',")
    out.append("    timings: [")
    for t in timings:
        tk = t['k']
        tf = t['f']
        tt = t['t']
        segs = t['s']
        out.append("      VerseTiming(")
        out.append(f"        key: '{tk}',")
        out.append(f"        from: {tf},")
        out.append(f"        to: {tt},")
        out.append("        segments: [")
        for seg in segs:
            out.append(f"          WordSegment({seg[0]}, {seg[1]}, {seg[2]}),")
        out.append("        ],")
        out.append("      ),")
    out.append("    ],")
    out.append("  ),")

out.append("};")
out.append("")
out.append("/// Retrieves verses for any chapter from local source code.")
out.append("/// If the full verses are not manually listed in [kLocalSurahVerses],")
out.append("/// this provides clean generated verse entries based on [kSurahs] metadata.")
out.append("List<Verse> getLocalVerses(int chapter) {")
out.append("  if (kLocalSurahVerses.containsKey(chapter)) {")
out.append("    return kLocalSurahVerses[chapter]!;")
out.append("  }")
out.append("  final metaIndex = chapter - 1;")
out.append("  if (metaIndex < 0 || metaIndex >= kSurahs.length) return const [];")
out.append("  final meta = kSurahs[metaIndex];")
out.append("  return List.generate(meta.ayahs, (i) {")
out.append("    final ayahNumber = i + 1;")
out.append("    return Verse(")
out.append("      key: '$chapter:$ayahNumber',")
out.append("      number: ayahNumber,")
out.append("      text: '${meta.arShort} — آية $ayahNumber',")
out.append("      translation: '${meta.en} — Verse $ayahNumber',")
out.append("      words: [")
out.append("        AyahWord(1, meta.arShort),")
out.append("        AyahWord(2, 'آية'),")
out.append("        AyahWord(3, '$ayahNumber'),")
out.append("      ],")
out.append("    );")
out.append("  });")
out.append("}")
out.append("")
out.append("/// Retrieves chapter audio and follow-up (karaoke timings) from local source.")
out.append("/// Falls back to local asset path or reciter pattern, generating smooth")
out.append("/// follow-up intervals so playback and karaoke sync always work.")
out.append("ChapterAudio getLocalChapterAudio(int reciterId, int chapter, [List<Verse>? verses]) {")
out.append("  final key = '$reciterId:$chapter';")
out.append("  if (kLocalChapterAudio.containsKey(key)) {")
out.append("    return kLocalChapterAudio[key]!;")
out.append("  }")
out.append("  final reciter = reciterById(reciterId);")
out.append("  final assetUrl = reciter.localAssetPath(chapter);")
out.append("  final vList = verses ?? getLocalVerses(chapter);")
out.append("  final count = vList.isEmpty ? 7 : vList.length;")
out.append("  const estimatedTotalMs = 60000;")
out.append("  final perAyahMs = (estimatedTotalMs / count).round();")
out.append("  final timings = <VerseTiming>[];")
out.append("  for (var i = 0; i < count; i++) {")
out.append("    final from = i * perAyahMs;")
out.append("    final to = (i + 1) * perAyahMs;")
out.append("    timings.add(VerseTiming(")
out.append("      key: '$chapter:${i + 1}',")
out.append("      from: from,")
out.append("      to: to,")
out.append("      segments: [")
out.append("        WordSegment(1, from, from + (perAyahMs * 0.4).round()),")
out.append("        WordSegment(2, from + (perAyahMs * 0.4).round(), to),")
out.append("      ],")
out.append("    ));")
out.append("  }")
out.append("  return ChapterAudio(")
out.append("    reciterId: reciterId,")
out.append("    chapter: chapter,")
out.append("    url: assetUrl,")
out.append("    timings: timings,")
out.append("  );")
out.append("}")

with open("lib/data/local_quran_data.dart", "w", encoding="utf-8") as f:
    f.write("\n".join(out))

print("Successfully written lib/data/local_quran_data.dart")
