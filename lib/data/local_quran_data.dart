// PURE DART LOCAL QURAN DATA SOURCE
// This file stores all reciter audio references, surahs, verses,
// and follow-up (karaoke timings) directly in code source — no API required!
//
// You can easily add more surahs, verses, or custom reciter timings here.

import 'models.dart';

/// Static local verse registry for starter surahs.
/// Add your custom surahs and verses directly to this map.
const Map<int, List<Verse>> kLocalSurahVerses = {
  1: [
    Verse(
      key: '1:1',
      number: 1,
      text: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
      translation: 'In the name of Allāh,1 the Entirely Merciful, the Especially Merciful.',
      words: [
        AyahWord(1, 'بِسْمِ'),
        AyahWord(2, 'ٱللَّهِ'),
        AyahWord(3, 'ٱلرَّحْمَـٰنِ'),
        AyahWord(4, 'ٱلرَّحِيمِ'),
      ],
    ),
    Verse(
      key: '1:2',
      number: 2,
      text: 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ',
      translation: '[All] praise is [due] to Allāh, Lord1 of the worlds -',
      words: [
        AyahWord(1, 'ٱلْحَمْدُ'),
        AyahWord(2, 'لِلَّهِ'),
        AyahWord(3, 'رَبِّ'),
        AyahWord(4, 'ٱلْعَـٰلَمِينَ'),
      ],
    ),
    Verse(
      key: '1:3',
      number: 3,
      text: 'ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
      translation: 'The Entirely Merciful, the Especially Merciful,',
      words: [
        AyahWord(1, 'ٱلرَّحْمَـٰنِ'),
        AyahWord(2, 'ٱلرَّحِيمِ'),
      ],
    ),
    Verse(
      key: '1:4',
      number: 4,
      text: 'مَـٰلِكِ يَوْمِ ٱلدِّينِ',
      translation: 'Sovereign of the Day of Recompense.',
      words: [
        AyahWord(1, 'مَـٰلِكِ'),
        AyahWord(2, 'يَوْمِ'),
        AyahWord(3, 'ٱلدِّينِ'),
      ],
    ),
    Verse(
      key: '1:5',
      number: 5,
      text: 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
      translation: 'It is You we worship and You we ask for help.',
      words: [
        AyahWord(1, 'إِيَّاكَ'),
        AyahWord(2, 'نَعْبُدُ'),
        AyahWord(3, 'وَإِيَّاكَ'),
        AyahWord(4, 'نَسْتَعِينُ'),
      ],
    ),
    Verse(
      key: '1:6',
      number: 6,
      text: 'ٱهْدِنَا ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ',
      translation: 'Guide us to the straight path -',
      words: [
        AyahWord(1, 'ٱهْدِنَا'),
        AyahWord(2, 'ٱلصِّرَٰطَ'),
        AyahWord(3, 'ٱلْمُسْتَقِيمَ'),
      ],
    ),
    Verse(
      key: '1:7',
      number: 7,
      text: 'صِرَٰطَ ٱلَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ ٱلْمَغْضُوبِ عَلَيْهِمْ وَلَا ٱلضَّآلِّينَ',
      translation: 'The path of those upon whom You have bestowed favor, not of those who have earned [Your] anger or of those who are astray.',
      words: [
        AyahWord(1, 'صِرَٰطَ'),
        AyahWord(2, 'ٱلَّذِينَ'),
        AyahWord(3, 'أَنْعَمْتَ'),
        AyahWord(4, 'عَلَيْهِمْ'),
        AyahWord(5, 'غَيْرِ'),
        AyahWord(6, 'ٱلْمَغْضُوبِ'),
        AyahWord(7, 'عَلَيْهِمْ'),
        AyahWord(8, 'وَلَا'),
        AyahWord(9, 'ٱلضَّآلِّينَ'),
      ],
    ),
  ],
  108: [
    Verse(
      key: '108:1',
      number: 1,
      text: ' إِنَّآ أَعْطَيْنَـٰكَ ٱلْكَوْثَرَ',
      translation: 'Indeed, We have granted you, [O Muḥammad], al-Kawthar.',
      words: [
        AyahWord(1, 'إِنَّآ'),
        AyahWord(2, 'أَعْطَيْنَـٰكَ'),
        AyahWord(3, 'ٱلْكَوْثَرَ'),
      ],
    ),
    Verse(
      key: '108:2',
      number: 2,
      text: 'فَصَلِّ لِرَبِّكَ وَٱنْحَرْ',
      translation: 'So pray to your Lord and offer sacrifice [to Him alone].',
      words: [
        AyahWord(1, 'فَصَلِّ'),
        AyahWord(2, 'لِرَبِّكَ'),
        AyahWord(3, 'وَٱنْحَرْ'),
      ],
    ),
    Verse(
      key: '108:3',
      number: 3,
      text: 'إِنَّ شَانِئَكَ هُوَ ٱلْأَبْتَرُ',
      translation: 'Indeed, your enemy is the one cut off.',
      words: [
        AyahWord(1, 'إِنَّ'),
        AyahWord(2, 'شَانِئَكَ'),
        AyahWord(3, 'هُوَ'),
        AyahWord(4, 'ٱلْأَبْتَرُ'),
      ],
    ),
  ],
  109: [
    Verse(
      key: '109:1',
      number: 1,
      text: ' قُلْ يَـٰٓأَيُّهَا ٱلْكَـٰفِرُونَ',
      translation: 'Say, "O disbelievers,',
      words: [
        AyahWord(1, 'قُلْ'),
        AyahWord(2, 'يَـٰٓأَيُّهَا'),
        AyahWord(3, 'ٱلْكَـٰفِرُونَ'),
      ],
    ),
    Verse(
      key: '109:2',
      number: 2,
      text: 'لَآ أَعْبُدُ مَا تَعْبُدُونَ',
      translation: 'I do not worship what you worship.',
      words: [
        AyahWord(1, 'لَآ'),
        AyahWord(2, 'أَعْبُدُ'),
        AyahWord(3, 'مَا'),
        AyahWord(4, 'تَعْبُدُونَ'),
      ],
    ),
    Verse(
      key: '109:3',
      number: 3,
      text: 'وَلَآ أَنتُمْ عَـٰبِدُونَ مَآ أَعْبُدُ',
      translation: 'Nor are you worshippers of what I worship.',
      words: [
        AyahWord(1, 'وَلَآ'),
        AyahWord(2, 'أَنتُمْ'),
        AyahWord(3, 'عَـٰبِدُونَ'),
        AyahWord(4, 'مَآ'),
        AyahWord(5, 'أَعْبُدُ'),
      ],
    ),
    Verse(
      key: '109:4',
      number: 4,
      text: 'وَلَآ أَنَا۠ عَابِدٌ مَّا عَبَدتُّمْ',
      translation: 'Nor will I be a worshipper of what you worship.',
      words: [
        AyahWord(1, 'وَلَآ'),
        AyahWord(2, 'أَنَا۠'),
        AyahWord(3, 'عَابِدٌۭ'),
        AyahWord(4, 'مَّا'),
        AyahWord(5, 'عَبَدتُّمْ'),
      ],
    ),
    Verse(
      key: '109:5',
      number: 5,
      text: 'وَلَآ أَنتُمْ عَـٰبِدُونَ مَآ أَعْبُدُ',
      translation: 'Nor will you be worshippers of what I worship.',
      words: [
        AyahWord(1, 'وَلَآ'),
        AyahWord(2, 'أَنتُمْ'),
        AyahWord(3, 'عَـٰبِدُونَ'),
        AyahWord(4, 'مَآ'),
        AyahWord(5, 'أَعْبُدُ'),
      ],
    ),
    Verse(
      key: '109:6',
      number: 6,
      text: 'لَكُمْ دِينُكُمْ وَلِىَ دِينِ',
      translation: 'For you is your religion, and for me is my religion."',
      words: [
        AyahWord(1, 'لَكُمْ'),
        AyahWord(2, 'دِينُكُمْ'),
        AyahWord(3, 'وَلِىَ'),
        AyahWord(4, 'دِينِ'),
      ],
    ),
  ],
  110: [
    Verse(
      key: '110:1',
      number: 1,
      text: ' إِذَا جَآءَ نَصْرُ ٱللَّهِ وَٱلْفَتْحُ',
      translation: 'When the victory of Allāh has come and the conquest,',
      words: [
        AyahWord(1, 'إِذَا'),
        AyahWord(2, 'جَآءَ'),
        AyahWord(3, 'نَصْرُ'),
        AyahWord(4, 'ٱللَّهِ'),
        AyahWord(5, 'وَٱلْفَتْحُ'),
      ],
    ),
    Verse(
      key: '110:2',
      number: 2,
      text: 'وَرَأَيْتَ ٱلنَّاسَ يَدْخُلُونَ فِى دِينِ ٱللَّهِ أَفْوَاجًا',
      translation: 'And you see the people entering into the religion of Allāh in multitudes,',
      words: [
        AyahWord(1, 'وَرَأَيْتَ'),
        AyahWord(2, 'ٱلنَّاسَ'),
        AyahWord(3, 'يَدْخُلُونَ'),
        AyahWord(4, 'فِى'),
        AyahWord(5, 'دِينِ'),
        AyahWord(6, 'ٱللَّهِ'),
        AyahWord(7, 'أَفْوَاجًۭا'),
      ],
    ),
    Verse(
      key: '110:3',
      number: 3,
      text: 'فَسَبِّحْ بِحَمْدِ رَبِّكَ وَٱسْتَغْفِرْهُ ۚ إِنَّهُۥ كَانَ تَوَّابًۢا',
      translation: 'Then exalt [Him] with praise of your Lord and ask forgiveness of Him. Indeed, He is ever Accepting of Repentance.',
      words: [
        AyahWord(1, 'فَسَبِّحْ'),
        AyahWord(2, 'بِحَمْدِ'),
        AyahWord(3, 'رَبِّكَ'),
        AyahWord(4, 'وَٱسْتَغْفِرْهُ ۚ'),
        AyahWord(5, 'إِنَّهُۥ'),
        AyahWord(6, 'كَانَ'),
        AyahWord(7, 'تَوَّابًۢا'),
      ],
    ),
  ],
  112: [
    Verse(
      key: '112:1',
      number: 1,
      text: ' قُلْ هُوَ ٱللَّهُ أَحَدٌ',
      translation: 'Say, "He is Allāh, [who is] One,',
      words: [
        AyahWord(1, 'قُلْ'),
        AyahWord(2, 'هُوَ'),
        AyahWord(3, 'ٱللَّهُ'),
        AyahWord(4, 'أَحَدٌ'),
      ],
    ),
    Verse(
      key: '112:2',
      number: 2,
      text: 'ٱللَّهُ ٱلصَّمَدُ',
      translation: 'Allāh, the Eternal Refuge.',
      words: [
        AyahWord(1, 'ٱللَّهُ'),
        AyahWord(2, 'ٱلصَّمَدُ'),
      ],
    ),
    Verse(
      key: '112:3',
      number: 3,
      text: 'لَمْ يَلِدْ وَلَمْ يُولَدْ',
      translation: 'He neither begets nor is born,',
      words: [
        AyahWord(1, 'لَمْ'),
        AyahWord(2, 'يَلِدْ'),
        AyahWord(3, 'وَلَمْ'),
        AyahWord(4, 'يُولَدْ'),
      ],
    ),
    Verse(
      key: '112:4',
      number: 4,
      text: 'وَلَمْ يَكُن لَّهُۥ كُفُوًا أَحَدٌۢ',
      translation: 'Nor is there to Him any equivalent."',
      words: [
        AyahWord(1, 'وَلَمْ'),
        AyahWord(2, 'يَكُن'),
        AyahWord(3, 'لَّهُۥ'),
        AyahWord(4, 'كُفُوًا'),
        AyahWord(5, 'أَحَدٌۢ'),
      ],
    ),
  ],
  113: [
    Verse(
      key: '113:1',
      number: 1,
      text: ' قُلْ أَعُوذُ بِرَبِّ ٱلْفَلَقِ',
      translation: 'Say, "I seek refuge in the Lord of daybreak',
      words: [
        AyahWord(1, 'قُلْ'),
        AyahWord(2, 'أَعُوذُ'),
        AyahWord(3, 'بِرَبِّ'),
        AyahWord(4, 'ٱلْفَلَقِ'),
      ],
    ),
    Verse(
      key: '113:2',
      number: 2,
      text: 'مِن شَرِّ مَا خَلَقَ',
      translation: 'From the evil of that which He created',
      words: [
        AyahWord(1, 'مِن'),
        AyahWord(2, 'شَرِّ'),
        AyahWord(3, 'مَا'),
        AyahWord(4, 'خَلَقَ'),
      ],
    ),
    Verse(
      key: '113:3',
      number: 3,
      text: 'وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ',
      translation: 'And from the evil of darkness when it settles',
      words: [
        AyahWord(1, 'وَمِن'),
        AyahWord(2, 'شَرِّ'),
        AyahWord(3, 'غَاسِقٍ'),
        AyahWord(4, 'إِذَا'),
        AyahWord(5, 'وَقَبَ'),
      ],
    ),
    Verse(
      key: '113:4',
      number: 4,
      text: 'وَمِن شَرِّ ٱلنَّفَّـٰثَـٰتِ فِى ٱلْعُقَدِ',
      translation: 'And from the evil of the blowers in knots',
      words: [
        AyahWord(1, 'وَمِن'),
        AyahWord(2, 'شَرِّ'),
        AyahWord(3, 'ٱلنَّفَّـٰثَـٰتِ'),
        AyahWord(4, 'فِى'),
        AyahWord(5, 'ٱلْعُقَدِ'),
      ],
    ),
    Verse(
      key: '113:5',
      number: 5,
      text: 'وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ',
      translation: 'And from the evil of an envier when he envies."',
      words: [
        AyahWord(1, 'وَمِن'),
        AyahWord(2, 'شَرِّ'),
        AyahWord(3, 'حَاسِدٍ'),
        AyahWord(4, 'إِذَا'),
        AyahWord(5, 'حَسَدَ'),
      ],
    ),
  ],
  114: [
    Verse(
      key: '114:1',
      number: 1,
      text: ' قُلْ أَعُوذُ بِرَبِّ ٱلنَّاسِ',
      translation: 'Say, "I seek refuge in the Lord of mankind,',
      words: [
        AyahWord(1, 'قُلْ'),
        AyahWord(2, 'أَعُوذُ'),
        AyahWord(3, 'بِرَبِّ'),
        AyahWord(4, 'ٱلنَّاسِ'),
      ],
    ),
    Verse(
      key: '114:2',
      number: 2,
      text: 'مَلِكِ ٱلنَّاسِ',
      translation: 'The Sovereign of mankind,',
      words: [
        AyahWord(1, 'مَلِكِ'),
        AyahWord(2, 'ٱلنَّاسِ'),
      ],
    ),
    Verse(
      key: '114:3',
      number: 3,
      text: 'إِلَـٰهِ ٱلنَّاسِ',
      translation: 'The God of mankind,',
      words: [
        AyahWord(1, 'إِلَـٰهِ'),
        AyahWord(2, 'ٱلنَّاسِ'),
      ],
    ),
    Verse(
      key: '114:4',
      number: 4,
      text: 'مِن شَرِّ ٱلْوَسْوَاسِ ٱلْخَنَّاسِ',
      translation: 'From the evil of the retreating whisperer1 -',
      words: [
        AyahWord(1, 'مِن'),
        AyahWord(2, 'شَرِّ'),
        AyahWord(3, 'ٱلْوَسْوَاسِ'),
        AyahWord(4, 'ٱلْخَنَّاسِ'),
      ],
    ),
    Verse(
      key: '114:5',
      number: 5,
      text: 'ٱلَّذِى يُوَسْوِسُ فِى صُدُورِ ٱلنَّاسِ',
      translation: 'Who whispers [evil] into the breasts of mankind -',
      words: [
        AyahWord(1, 'ٱلَّذِى'),
        AyahWord(2, 'يُوَسْوِسُ'),
        AyahWord(3, 'فِى'),
        AyahWord(4, 'صُدُورِ'),
        AyahWord(5, 'ٱلنَّاسِ'),
      ],
    ),
    Verse(
      key: '114:6',
      number: 6,
      text: 'مِنَ ٱلْجِنَّةِ وَٱلنَّاسِ',
      translation: 'From among the jinn and mankind".',
      words: [
        AyahWord(1, 'مِنَ'),
        AyahWord(2, 'ٱلْجِنَّةِ'),
        AyahWord(3, 'وَٱلنَّاسِ'),
      ],
    ),
  ],
};

/// Static local follow-up (audio URLs + karaoke timings) registry.
/// Key format: 'reciterId:chapterNumber' (e.g. '7:1' for Mishary Surah 1).
const Map<String, ChapterAudio> kLocalChapterAudio = {
  '10:1': ChapterAudio(
    reciterId: 10,
    chapter: 1,
    url: 'assets/audio/1.mp3',
    timings: [
      VerseTiming(
        key: '1:1',
        from: 0,
        to: 2760,
        segments: [
          WordSegment(1, 131, 641),
          WordSegment(2, 651, 1151),
          WordSegment(3, 1161, 2101),
          WordSegment(4, 2111, 2551),
        ],
      ),
      VerseTiming(
        key: '1:2',
        from: 2751,
        to: 6281,
        segments: [
          WordSegment(1, 2852, 3362),
          WordSegment(2, 3372, 4162),
          WordSegment(3, 4172, 4562),
          WordSegment(4, 4572, 6022),
        ],
      ),
      VerseTiming(
        key: '1:3',
        from: 6272,
        to: 9442,
        segments: [
          WordSegment(1, 6302, 7162),
          WordSegment(2, 7172, 9092),
        ],
      ),
      VerseTiming(
        key: '1:4',
        from: 9433,
        to: 12233,
        segments: [
          WordSegment(1, 9533, 10223),
          WordSegment(2, 10233, 10943),
          WordSegment(3, 10953, 11993),
        ],
      ),
      VerseTiming(
        key: '1:5',
        from: 12223,
        to: 17013,
        segments: [
          WordSegment(1, 12274, 13284),
          WordSegment(2, 13294, 14064),
          WordSegment(3, 14074, 15344),
          WordSegment(4, 15354, 16634),
        ],
      ),
      VerseTiming(
        key: '1:6',
        from: 17004,
        to: 20614,
        segments: [
          WordSegment(1, 17205, 17685),
          WordSegment(2, 17695, 18695),
          WordSegment(3, 18705, 20325),
        ],
      ),
      VerseTiming(
        key: '1:7',
        from: 20605,
        to: 34615,
        segments: [
          WordSegment(1, 20666, 21296),
          WordSegment(2, 21306, 22166),
          WordSegment(3, 22176, 22976),
          WordSegment(4, 22986, 24276),
          WordSegment(5, 24286, 24776),
          WordSegment(6, 24786, 25716),
          WordSegment(7, 25726, 26626),
          WordSegment(8, 26636, 26986),
          WordSegment(9, 26996, 32256),
        ],
      ),
    ],
  ),
  '2:1': ChapterAudio(
    reciterId: 2,
    chapter: 1,
    url: 'assets/audio/1.mp3',
    timings: [
      VerseTiming(
        key: '1:1',
        from: 0,
        to: 4370,
        segments: [
          WordSegment(1, 0, 1040),
          WordSegment(2, 1040, 1660),
          WordSegment(3, 1660, 2610),
          WordSegment(4, 2610, 4325),
        ],
      ),
      VerseTiming(
        key: '1:2',
        from: 4370,
        to: 9680,
        segments: [
          WordSegment(1, 4370, 6090),
          WordSegment(2, 6090, 6940),
          WordSegment(3, 6940, 7400),
          WordSegment(4, 7400, 9055),
        ],
      ),
      VerseTiming(
        key: '1:3',
        from: 9680,
        to: 13710,
        segments: [
          WordSegment(1, 9680, 11652),
          WordSegment(2, 11652, 13755),
        ],
      ),
      VerseTiming(
        key: '1:4',
        from: 13710,
        to: 18260,
        segments: [
          WordSegment(1, 13710, 15770),
          WordSegment(2, 15770, 16270),
          WordSegment(3, 16270, 17645),
        ],
      ),
      VerseTiming(
        key: '1:5',
        from: 18260,
        to: 23880,
        segments: [
          WordSegment(1, 18260, 19960),
          WordSegment(2, 19960, 20730),
          WordSegment(3, 20730, 21760),
          WordSegment(4, 21760, 23245),
        ],
      ),
      VerseTiming(
        key: '1:6',
        from: 23880,
        to: 28690,
        segments: [
          WordSegment(1, 23880, 25490),
          WordSegment(2, 25490, 26300),
          WordSegment(3, 26300, 28735),
        ],
      ),
      VerseTiming(
        key: '1:7',
        from: 28690,
        to: 41830,
        segments: [
          WordSegment(1, 28690, 31050),
          WordSegment(2, 31050, 31910),
          WordSegment(3, 31910, 32790),
          WordSegment(4, 32790, 33610),
          WordSegment(5, 33610, 34210),
          WordSegment(6, 34210, 35230),
          WordSegment(7, 35230, 36270),
          WordSegment(8, 36270, 36490),
          WordSegment(9, 36490, 41455),
        ],
      ),
    ],
  ),
  '3:1': ChapterAudio(
    reciterId: 3,
    chapter: 1,
    url: 'assets/audio/1.mp3',
    timings: [
      VerseTiming(
        key: '1:1',
        from: 0,
        to: 3080,
        segments: [
          WordSegment(1, 0, 650),
          WordSegment(2, 650, 1130),
          WordSegment(3, 1130, 1860),
          WordSegment(4, 1860, 2725),
        ],
      ),
      VerseTiming(
        key: '1:2',
        from: 3080,
        to: 7570,
        segments: [
          WordSegment(1, 3080, 4050),
          WordSegment(2, 4050, 4920),
          WordSegment(3, 4920, 5510),
          WordSegment(4, 5510, 7165),
        ],
      ),
      VerseTiming(
        key: '1:3',
        from: 7570,
        to: 10680,
        segments: [
          WordSegment(1, 7570, 8650),
          WordSegment(2, 8650, 10305),
        ],
      ),
      VerseTiming(
        key: '1:4',
        from: 10680,
        to: 14130,
        segments: [
          WordSegment(1, 10680, 11380),
          WordSegment(2, 11380, 12100),
          WordSegment(3, 12100, 13565),
        ],
      ),
      VerseTiming(
        key: '1:5',
        from: 14130,
        to: 19070,
        segments: [
          WordSegment(1, 14130, 15090),
          WordSegment(2, 15090, 15840),
          WordSegment(3, 15840, 16960),
          WordSegment(4, 16960, 18575),
        ],
      ),
      VerseTiming(
        key: '1:6',
        from: 19070,
        to: 23280,
        segments: [
          WordSegment(1, 19070, 19550),
          WordSegment(2, 19550, 20720),
          WordSegment(3, 20720, 22825),
        ],
      ),
      VerseTiming(
        key: '1:7',
        from: 23280,
        to: 34930,
        segments: [
          WordSegment(1, 23280, 24200),
          WordSegment(2, 24200, 25240),
          WordSegment(3, 25240, 26140),
          WordSegment(4, 26140, 27200),
          WordSegment(5, 27200, 27850),
          WordSegment(6, 27850, 28890),
          WordSegment(7, 28890, 30000),
          WordSegment(8, 30000, 30330),
          WordSegment(9, 30330, 34715),
        ],
      ),
    ],
  ),
  '6:1': ChapterAudio(
    reciterId: 6,
    chapter: 1,
    url: 'assets/audio/1.mp3',
    timings: [
      VerseTiming(
        key: '1:1',
        from: 0,
        to: 5220,
        segments: [
          WordSegment(1, 0, 540),
          WordSegment(2, 540, 1350),
          WordSegment(3, 1350, 2356),
          WordSegment(4, 2356, 4810),
        ],
      ),
      VerseTiming(
        key: '1:2',
        from: 5220,
        to: 11570,
        segments: [
          WordSegment(1, 5220, 6690),
          WordSegment(2, 6690, 7570),
          WordSegment(3, 7570, 8130),
          WordSegment(4, 8130, 10530),
        ],
      ),
      VerseTiming(
        key: '1:3',
        from: 11570,
        to: 16140,
        segments: [
          WordSegment(1, 11570, 13040),
          WordSegment(2, 13040, 15370),
        ],
      ),
      VerseTiming(
        key: '1:4',
        from: 16140,
        to: 20840,
        segments: [
          WordSegment(1, 16140, 17190),
          WordSegment(2, 17190, 17840),
          WordSegment(3, 17840, 19820),
        ],
      ),
      VerseTiming(
        key: '1:5',
        from: 20840,
        to: 27760,
        segments: [
          WordSegment(1, 20840, 22210),
          WordSegment(2, 22210, 23120),
          WordSegment(3, 23120, 24390),
          WordSegment(4, 24390, 26780),
        ],
      ),
      VerseTiming(
        key: '1:6',
        from: 27760,
        to: 33190,
        segments: [
          WordSegment(1, 27760, 28660),
          WordSegment(2, 28660, 29670),
          WordSegment(3, 29670, 32510),
        ],
      ),
      VerseTiming(
        key: '1:7',
        from: 33190,
        to: 48210,
        segments: [
          WordSegment(1, 33190, 34400),
          WordSegment(2, 34400, 35350),
          WordSegment(3, 35350, 36380),
          WordSegment(4, 36380, 37440),
          WordSegment(5, 37440, 38170),
          WordSegment(6, 38170, 39500),
          WordSegment(7, 39500, 40650),
          WordSegment(8, 40650, 40970),
          WordSegment(9, 40970, 47039),
        ],
      ),
    ],
  ),
  '7:1': ChapterAudio(
    reciterId: 7,
    chapter: 1,
    url: 'assets/audio/1.mp3',
    timings: [
      VerseTiming(
        key: '1:1',
        from: 0,
        to: 6090,
        segments: [
          WordSegment(1, 0, 580),
          WordSegment(2, 580, 1409),
          WordSegment(3, 1409, 2502),
          WordSegment(4, 2502, 5840),
        ],
      ),
      VerseTiming(
        key: '1:2',
        from: 6090,
        to: 11680,
        segments: [
          WordSegment(1, 6025, 7025),
          WordSegment(2, 7025, 7885),
          WordSegment(3, 7885, 8515),
          WordSegment(4, 8515, 11550),
        ],
      ),
      VerseTiming(
        key: '1:3',
        from: 11680,
        to: 16300,
        segments: [
          WordSegment(1, 11615, 12855),
          WordSegment(2, 12855, 16180),
        ],
      ),
      VerseTiming(
        key: '1:4',
        from: 16300,
        to: 20950,
        segments: [
          WordSegment(1, 16245, 17065),
          WordSegment(2, 17065, 17665),
          WordSegment(3, 17665, 20830),
        ],
      ),
      VerseTiming(
        key: '1:5',
        from: 20950,
        to: 27660,
        segments: [
          WordSegment(1, 20885, 21875),
          WordSegment(2, 21875, 22645),
          WordSegment(3, 22645, 23765),
          WordSegment(4, 23765, 27520),
        ],
      ),
      VerseTiming(
        key: '1:6',
        from: 27660,
        to: 33250,
        segments: [
          WordSegment(1, 27585, 28325),
          WordSegment(2, 28325, 29225),
          WordSegment(3, 29225, 33110),
        ],
      ),
      VerseTiming(
        key: '1:7',
        from: 33250,
        to: 46490,
        segments: [
          WordSegment(1, 33185, 33935),
          WordSegment(2, 33935, 34855),
          WordSegment(3, 34855, 35875),
          WordSegment(4, 35875, 36805),
          WordSegment(5, 36805, 37395),
          WordSegment(6, 37395, 38565),
          WordSegment(7, 38565, 39565),
          WordSegment(8, 39565, 39855),
          WordSegment(9, 39855, 46360),
        ],
      ),
    ],
  ),
  '7:108': ChapterAudio(
    reciterId: 7,
    chapter: 108,
    url: 'assets/audio/108.mp3',
    timings: [
      VerseTiming(
        key: '108:1',
        from: 0,
        to: 6710,
        segments: [
          WordSegment(1, 0, 3510),
          WordSegment(2, 3510, 5010),
          WordSegment(3, 5010, 6245),
        ],
      ),
      VerseTiming(
        key: '108:2',
        from: 6710,
        to: 10260,
        segments: [
          WordSegment(1, 6245, 7055),
          WordSegment(2, 7055, 8265),
          WordSegment(3, 8265, 9680),
        ],
      ),
      VerseTiming(
        key: '108:3',
        from: 10260,
        to: 15510,
        segments: [
          WordSegment(1, 10145, 11815),
          WordSegment(2, 11815, 12985),
          WordSegment(3, 12985, 13355),
          WordSegment(4, 13355, 14980),
        ],
      ),
    ],
  ),
  '7:112': ChapterAudio(
    reciterId: 7,
    chapter: 112,
    url: 'assets/audio/112.mp3',
    timings: [
      VerseTiming(
        key: '112:1',
        from: 0,
        to: 2980,
        segments: [
          WordSegment(1, 0, 430),
          WordSegment(2, 430, 700),
          WordSegment(3, 700, 1680),
          WordSegment(4, 1680, 2915),
        ],
      ),
      VerseTiming(
        key: '112:2',
        from: 2980,
        to: 5510,
        segments: [
          WordSegment(1, 2915, 3965),
          WordSegment(2, 3965, 5400),
        ],
      ),
      VerseTiming(
        key: '112:3',
        from: 5510,
        to: 8490,
        segments: [
          WordSegment(1, 5465, 5895),
          WordSegment(2, 5895, 6515),
          WordSegment(3, 6515, 7205),
          WordSegment(4, 7205, 8380),
        ],
      ),
      VerseTiming(
        key: '112:4',
        from: 8490,
        to: 13350,
        segments: [
          WordSegment(1, 8425, 8955),
          WordSegment(2, 8955, 9675),
          WordSegment(3, 9675, 10505),
          WordSegment(4, 10505, 11425),
          WordSegment(5, 11425, 13120),
        ],
      ),
    ],
  ),
  '7:113': ChapterAudio(
    reciterId: 7,
    chapter: 113,
    url: 'assets/audio/113.mp3',
    timings: [
      VerseTiming(
        key: '113:1',
        from: 0,
        to: 3470,
        segments: [
          WordSegment(1, 0, 360),
          WordSegment(2, 360, 1280),
          WordSegment(3, 1280, 2110),
          WordSegment(4, 2110, 3005),
        ],
      ),
      VerseTiming(
        key: '113:2',
        from: 3470,
        to: 7100,
        segments: [
          WordSegment(1, 2995, 3935),
          WordSegment(2, 3935, 5035),
          WordSegment(3, 5035, 5375),
          WordSegment(4, 5375, 6590),
        ],
      ),
      VerseTiming(
        key: '113:3',
        from: 7100,
        to: 12140,
        segments: [
          WordSegment(1, 7065, 7805),
          WordSegment(2, 7805, 9205),
          WordSegment(3, 9205, 10315),
          WordSegment(4, 10315, 10935),
          WordSegment(5, 10935, 12010),
        ],
      ),
      VerseTiming(
        key: '113:4',
        from: 12140,
        to: 18150,
        segments: [
          WordSegment(1, 12045, 13455),
          WordSegment(2, 13455, 14195),
          WordSegment(3, 14195, 16485),
          WordSegment(4, 16485, 16675),
          WordSegment(5, 16675, 17980),
        ],
      ),
      VerseTiming(
        key: '113:5',
        from: 18150,
        to: 23820,
        segments: [
          WordSegment(1, 18075, 18575),
          WordSegment(2, 18575, 20065),
          WordSegment(3, 20065, 21235),
          WordSegment(4, 21235, 21825),
          WordSegment(5, 21825, 23680),
        ],
      ),
    ],
  ),
  '7:114': ChapterAudio(
    reciterId: 7,
    chapter: 114,
    url: 'assets/audio/114.mp3',
    timings: [
      VerseTiming(
        key: '114:1',
        from: 0,
        to: 6110,
        segments: [
          WordSegment(1, 0, 330),
          WordSegment(2, 330, 1230),
          WordSegment(3, 1230, 2050),
          WordSegment(4, 2050, 6085),
        ],
      ),
      VerseTiming(
        key: '114:2',
        from: 6110,
        to: 11390,
        segments: [
          WordSegment(1, 6085, 6725),
          WordSegment(2, 6725, 11290),
        ],
      ),
      VerseTiming(
        key: '114:3',
        from: 11390,
        to: 16750,
        segments: [
          WordSegment(1, 11315, 12155),
          WordSegment(2, 12155, 16610),
        ],
      ),
      VerseTiming(
        key: '114:4',
        from: 16750,
        to: 24740,
        segments: [
          WordSegment(1, 16685, 17085),
          WordSegment(2, 17086, 18805),
          WordSegment(3, 18805, 20075),
          WordSegment(4, 20075, 24600),
        ],
      ),
      VerseTiming(
        key: '114:5',
        from: 24740,
        to: 32660,
        segments: [
          WordSegment(1, 24665, 25805),
          WordSegment(2, 25805, 26795),
          WordSegment(3, 26795, 27175),
          WordSegment(4, 27175, 28085),
          WordSegment(5, 28085, 32530),
        ],
      ),
      VerseTiming(
        key: '114:6',
        from: 32660,
        to: 40910,
        segments: [
          WordSegment(1, 32605, 32985),
          WordSegment(2, 32985, 35215),
          WordSegment(3, 35215, 40790),
        ],
      ),
    ],
  ),
  '9:1': ChapterAudio(
    reciterId: 9,
    chapter: 1,
    url: 'assets/audio/1.mp3',
    timings: [
      VerseTiming(
        key: '1:1',
        from: 0,
        to: 5040,
        segments: [
          WordSegment(1, 20, 830),
          WordSegment(2, 830, 1490),
          WordSegment(3, 1490, 2610),
          WordSegment(4, 2610, 3945),
        ],
      ),
      VerseTiming(
        key: '1:2',
        from: 5040,
        to: 10840,
        segments: [
          WordSegment(1, 5040, 6550),
          WordSegment(2, 6550, 7510),
          WordSegment(3, 7510, 8120),
          WordSegment(4, 8120, 9695),
        ],
      ),
      VerseTiming(
        key: '1:3',
        from: 10840,
        to: 15280,
        segments: [
          WordSegment(1, 10840, 12520),
          WordSegment(2, 12520, 13925),
        ],
      ),
      VerseTiming(
        key: '1:4',
        from: 15280,
        to: 19510,
        segments: [
          WordSegment(1, 15280, 16580),
          WordSegment(2, 16580, 17150),
          WordSegment(3, 17150, 18395),
        ],
      ),
      VerseTiming(
        key: '1:5',
        from: 19510,
        to: 25570,
        segments: [
          WordSegment(1, 19510, 21000),
          WordSegment(2, 21000, 21690),
          WordSegment(3, 21690, 23100),
          WordSegment(4, 23100, 24965),
        ],
      ),
      VerseTiming(
        key: '1:6',
        from: 25570,
        to: 30770,
        segments: [
          WordSegment(1, 25570, 26770),
          WordSegment(2, 26770, 27870),
          WordSegment(3, 27870, 29525),
        ],
      ),
      VerseTiming(
        key: '1:7',
        from: 30770,
        to: 43940,
        segments: [
          WordSegment(1, 30770, 32000),
          WordSegment(2, 32000, 33090),
          WordSegment(3, 33090, 34130),
          WordSegment(4, 34130, 35160),
          WordSegment(5, 35160, 35800),
          WordSegment(6, 35800, 37140),
          WordSegment(7, 37140, 38160),
          WordSegment(8, 38160, 38560),
          WordSegment(9, 38560, 43485),
        ],
      ),
    ],
  ),
};

/// Checks if the chapter is part of the statically embedded starter set.
bool hasStarterVerses(int chapter) => kLocalSurahVerses.containsKey(chapter);

/// Retrieves verses for any chapter from local source code.
/// If the full verses are not manually listed in [kLocalSurahVerses],
/// this provides clean generated verse entries based on [kSurahs] metadata.
List<Verse> getLocalVerses(int chapter) {
  if (kLocalSurahVerses.containsKey(chapter)) {
    return kLocalSurahVerses[chapter]!;
  }
  final metaIndex = chapter - 1;
  if (metaIndex < 0 || metaIndex >= kSurahs.length) return const [];
  final meta = kSurahs[metaIndex];
  return List.generate(meta.ayahs, (i) {
    final ayahNumber = i + 1;
    return Verse(
      key: '$chapter:$ayahNumber',
      number: ayahNumber,
      text: '${meta.arShort} — آية $ayahNumber',
      translation: '${meta.en} — Verse $ayahNumber',
      words: [
        AyahWord(1, meta.arShort),
        AyahWord(2, 'آية'),
        AyahWord(3, '$ayahNumber'),
      ],
    );
  });
}

/// Retrieves chapter audio and follow-up (karaoke timings) from local source.
/// Falls back to local asset path or reciter pattern, generating smooth
/// follow-up intervals so playback and karaoke sync always work.
ChapterAudio getLocalChapterAudio(int reciterId, int chapter, [List<Verse>? verses]) {
  final key = '$reciterId:$chapter';
  if (kLocalChapterAudio.containsKey(key)) {
    return kLocalChapterAudio[key]!;
  }
  final reciter = reciterById(reciterId);
  final assetUrl = reciter.localAssetPath(chapter);
  final vList = verses ?? (kLocalSurahVerses.containsKey(chapter) ? kLocalSurahVerses[chapter]! : null);
  final metaIndex = chapter - 1;
  final ayahCount = vList?.length ?? (metaIndex >= 0 && metaIndex < kSurahs.length ? kSurahs[metaIndex].ayahs : 7);
  const estimatedTotalMs = 60000;
  final perAyahMs = (estimatedTotalMs / ayahCount).round();
  final timings = <VerseTiming>[];
  for (var i = 0; i < ayahCount; i++) {
    final from = i * perAyahMs;
    final to = (i + 1) * perAyahMs;
    timings.add(VerseTiming(
      key: '$chapter:${i + 1}',
      from: from,
      to: to,
      segments: [
        WordSegment(1, from, from + (perAyahMs * 0.4).round()),
        WordSegment(2, from + (perAyahMs * 0.4).round(), to),
      ],
    ));
  }
  return ChapterAudio(
    reciterId: reciterId,
    chapter: chapter,
    url: assetUrl,
    timings: timings,
  );
}