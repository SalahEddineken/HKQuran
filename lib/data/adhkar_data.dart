enum AdhkarCategory {
  morning,
  evening,
  afterPrayer,
  sleep,
  tasbeeh,
}

class DhikrItem {
  final int id;
  final AdhkarCategory category;
  final String text;
  final String? fadl;
  final int targetCount;
  final String? source;

  const DhikrItem({
    required this.id,
    required this.category,
    required this.text,
    this.fadl,
    this.targetCount = 1,
    this.source,
  });
}

class DhikrNotificationItem {
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String? bodyEn;
  final String? virtueAr;
  final String? virtueEn;
  final AdhkarCategory? category;

  const DhikrNotificationItem({
    required this.titleAr,
    required this.titleEn,
    required this.bodyAr,
    this.bodyEn,
    this.virtueAr,
    this.virtueEn,
    this.category,
  });
}

class AdhkarData {
  static const List<DhikrNotificationItem> notificationReminders = [
    DhikrNotificationItem(
      titleAr: 'تسبيح مبارك 🌿',
      titleEn: 'Glorification & Praise 🌿',
      bodyAr: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
      bodyEn: 'Subhan Allahi wa bihamdihi, Subhan Allahil Azeem',
      virtueAr: 'كلمتان خفيفتان على اللسان، ثقيلتان في الميزان، حبيبتان إلى الرحمن',
      virtueEn: 'Two words light on the tongue, heavy on the balance, beloved to the Most Merciful',
      category: AdhkarCategory.tasbeeh,
    ),
    DhikrNotificationItem(
      titleAr: 'تهليل وتوحيد 💫',
      titleEn: 'Oneness of Allah 💫',
      bodyAr: 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
      bodyEn: 'La ilaha illallahu wahdahu la shareeka lah, lahul-mulku wa lahul-hamdu wa huwa ‘ala kulli shay’in qadeer',
      virtueAr: 'أفضل ما قلت أنا والنبيون من قبلي',
      virtueEn: 'The best supplication I and the prophets before me have said',
      category: AdhkarCategory.tasbeeh,
    ),
    DhikrNotificationItem(
      titleAr: 'صلاة على النبي ﷺ 🌸',
      titleEn: 'Blessings on the Prophet ﷺ 🌸',
      bodyAr: 'اللَّهُمَّ صَلِّ وَسَلِّمْ وَبَارِكْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
      bodyEn: 'Allahumma salli wa sallim wa barik ‘ala Nabiyyina Muhammad',
      virtueAr: 'من صلى عليَّ صلاة صلى الله عليه بها عشراً',
      virtueEn: 'Whoever sends blessings upon me once, Allah sends blessings upon him ten times',
      category: AdhkarCategory.tasbeeh,
    ),
    DhikrNotificationItem(
      titleAr: 'سيد الاستغفار 👑',
      titleEn: 'Chief of Prayers for Forgiveness 👑',
      bodyAr: 'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
      bodyEn: 'Allahumma Anta Rabbi la ilaha illa Anta, khalaqtani wa ana ‘abduka...',
      virtueAr: 'من قالها موقناً بها ومات دخل الجنة',
      virtueEn: 'Whoever says it with certainty and dies will enter Paradise',
      category: AdhkarCategory.morning,
    ),
    DhikrNotificationItem(
      titleAr: 'استغفار جامع 🌧️',
      titleEn: 'Seeking Forgiveness 🌧️',
      bodyAr: 'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ الَّذِي لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ وَأَتُوبُ إِلَيْهِ',
      bodyEn: 'Astaghfirullah al-’Azeem alladhi la ilaha illa Huwal-Hayyul-Qayyum wa atubu ilayh',
      virtueAr: 'غُفرت ذنوبه وإن كان فرَّ من الزحف',
      virtueEn: 'His sins are forgiven even if he fled from battle',
      category: AdhkarCategory.tasbeeh,
    ),
    DhikrNotificationItem(
      titleAr: 'كنز من كنوز الجنة 💎',
      titleEn: 'A Treasure of Paradise 💎',
      bodyAr: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ',
      bodyEn: 'La hawla wa la quwwata illa billahil-’Aliyyil-’Azeem',
      virtueAr: 'كنز من كنوز الجنة وبراءة من الحول والقوة',
      virtueEn: 'A treasure of Paradise and freeing oneself of reliance on all else',
      category: AdhkarCategory.tasbeeh,
    ),
    DhikrNotificationItem(
      titleAr: 'الباقيات الصالحات ✨',
      titleEn: 'The Everlasting Good Deeds ✨',
      bodyAr: 'سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ',
      bodyEn: 'Subhan Allah, wal-hamdu lillah, wa la ilaha illallah, wallahu akbar',
      virtueAr: 'أحب الكلام إلى الله وخير مما طلعت عليه الشمس',
      virtueEn: 'The most beloved speech to Allah and better than all over which the sun rises',
      category: AdhkarCategory.tasbeeh,
    ),
    DhikrNotificationItem(
      titleAr: 'دعاء وتوكل 🤲',
      titleEn: 'Supplication & Reliance 🤲',
      bodyAr: 'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ، وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ',
      bodyEn: 'Ya Hayyu Ya Qayyum, bi-rahmatika astagheeth, aslih li sha’ni kullah wa la takilni ila nafsi tarfata ‘ayn',
      virtueAr: 'دعاء جامع لتفريج الكروب وصلاح الحال',
      virtueEn: 'A comprehensive prayer for relief and rectification',
      category: AdhkarCategory.morning,
    ),
    DhikrNotificationItem(
      titleAr: 'طلب البركة والقبول 🌿',
      titleEn: 'Seeking Knowledge & Provision 🌿',
      bodyAr: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا، وَرِزْقًا طَيِّبًا، وَعَمَلًا مُتَقَبَّلًا',
      bodyEn: 'Allahumma inni as’aluka ‘ilman nafi’an, wa rizqan tayyiban, wa ‘amalan mutaqabbala',
      virtueAr: 'كان يدعو به النبي ﷺ دبر صلاة الصبح',
      virtueEn: 'Recited by the Prophet ﷺ after the dawn prayer',
      category: AdhkarCategory.morning,
    ),
    DhikrNotificationItem(
      titleAr: 'رضا وتوحيد ☀️',
      titleEn: 'Pleasure with Allah ☀️',
      bodyAr: 'رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا وَرَسُولًا',
      bodyEn: 'Radeetu billahi Rabba, wa bil-Islami deena, wa bi-Muhammadin sallallahu ‘alayhi wa sallama Nabiyya',
      virtueAr: 'وجبت له الجنة، وكان حقاً على الله أن يرضيه',
      virtueEn: 'Paradise becomes due for him and Allah will surely please him',
      category: AdhkarCategory.morning,
    ),
    DhikrNotificationItem(
      titleAr: 'كفاية وتوكل 🛡️',
      titleEn: 'Allah is Sufficient 🛡️',
      bodyAr: 'حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ',
      bodyEn: 'Hasbiyallahu la ilaha illa Huwa, ‘alayhi tawakkaltu wa Huwa Rabbul-’Arshil-’Azeem',
      virtueAr: 'من قالها سبعاً كفاه الله ما أهمه من أمر دنياه وآخرته',
      virtueEn: 'Whoever says it 7 times, Allah will suffice him against whatever concerns him',
      category: AdhkarCategory.morning,
    ),
    DhikrNotificationItem(
      titleAr: 'طمأنينة وسكينة 📖',
      titleEn: 'Peace & Serenity 📖',
      bodyAr: '﴿أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ﴾',
      bodyEn: '“Unquestionably, by the remembrance of Allah hearts are assured.” (13:28)',
      virtueAr: 'سورة الرعد — آية 28',
      virtueEn: 'Surah Ar-Ra’d: 28',
    ),
    DhikrNotificationItem(
      titleAr: 'ذكر وشكر 📖',
      titleEn: 'Remembrance & Gratitude 📖',
      bodyAr: '﴿فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ﴾',
      bodyEn: '“So remember Me; I will remember you. And be grateful to Me and do not deny Me.” (2:152)',
      virtueAr: 'سورة البقرة — آية 152',
      virtueEn: 'Surah Al-Baqarah: 152',
    ),
    DhikrNotificationItem(
      titleAr: 'توكل وتسبيح 📖',
      titleEn: 'Trust & Praise 📖',
      bodyAr: '﴿وَتَوَكَّلْ عَلَى الْحَيِّ الَّذِي لَا يَمُوتُ وَسَبِّحْ بِحَمْدِهِ﴾',
      bodyEn: '“And rely upon the Ever-Living who does not die, and exalt [Allah] with His praise.” (25:58)',
      virtueAr: 'سورة الفرقان — آية 58',
      virtueEn: 'Surah Al-Furqan: 58',
    ),
    DhikrNotificationItem(
      titleAr: 'دعاء قرآني جامع 📖',
      titleEn: 'Comprehensive Quranic Dua 📖',
      bodyAr: '﴿رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ﴾',
      bodyEn: '“Our Lord, give us in this world that which is good and in the Hereafter good and protect us from the punishment of the Fire.” (2:201)',
      virtueAr: 'أكثر دعاء كان النبي ﷺ يلهج به',
      virtueEn: 'The most frequent supplication of the Prophet ﷺ',
    ),
    DhikrNotificationItem(
      titleAr: 'انشراح الصدر وتيسير الأمر 📖',
      titleEn: 'Relief of the Heart 📖',
      bodyAr: '﴿رَبِّ اشْرَحْ لِي صَدْرِي ۝ وَيَسِّرْ لِي أَمْرِي﴾',
      bodyEn: '“My Lord, expand for me my breast [with assurance] and ease for me my task.” (20:25-26)',
      virtueAr: 'سورة طه — آية 25-26',
      virtueEn: 'Surah Taha: 25-26',
    ),
    DhikrNotificationItem(
      titleAr: 'افتقار إلى فضل الله 📖',
      titleEn: 'In Need of Allah’s Bounty 📖',
      bodyAr: '﴿رَبِّ إِنِّي لِمَا أَنْزَلْتَ إِلَيَّ مِنْ خَيْرٍ فَقِيرٌ﴾',
      bodyEn: '“My Lord, indeed I am, for whatever good You would send down to me, in need.” (28:24)',
      virtueAr: 'دعاء موسى عليه السلام المستجاب',
      virtueEn: 'The answered prayer of Moses (Musa)',
    ),
    DhikrNotificationItem(
      titleAr: 'طلب الزيادة في العلم 📖',
      titleEn: 'Increase in Knowledge 📖',
      bodyAr: '﴿وَقُلْ رَبِّ زِدْنِي عِلْمًا﴾',
      bodyEn: '“And say: My Lord, increase me in knowledge.” (20:114)',
      virtueAr: 'سورة طه — آية 114',
      virtueEn: 'Surah Taha: 114',
    ),
    DhikrNotificationItem(
      titleAr: 'كفاية وأمان 📖',
      titleEn: 'Sufficiency in Allah 📖',
      bodyAr: '﴿حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ﴾',
      bodyEn: '“Sufficient for us is Allah, and [He is] the best Disposer of affairs.” (3:173)',
      virtueAr: 'قالها إبراهيم حين أُلقي في النار، وقالها محمد ﷺ وأصحابه',
      virtueEn: 'Said by Abraham and by Muhammad ﷺ in times of adversity',
    ),
    DhikrNotificationItem(
      titleAr: 'ثبات على الهداية 📖',
      titleEn: 'Steadfastness in Guidance 📖',
      bodyAr: '﴿رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِنْ لَدُنْكَ رَحْمَةً إِنَّكَ أَنْتَ الْوَهَّابُ﴾',
      bodyEn: '“Our Lord, let not our hearts deviate after You have guided us and grant us from Yourself mercy.” (3:8)',
      virtueAr: 'سورة آل عمران — آية 8',
      virtueEn: 'Surah Ali ‘Imran: 8',
    ),
    DhikrNotificationItem(
      titleAr: 'إجابة الدعاء وقرب الله 📖',
      titleEn: 'Nearness of Allah 📖',
      bodyAr: '﴿وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ أُجِيبُ دَعْوَةَ الدَّاعِ إِذَا دَعَانِ﴾',
      bodyEn: '“And when My servants ask you concerning Me, indeed I am near. I respond to the invocation of the supplicant.” (2:186)',
      virtueAr: 'سورة البقرة — آية 186',
      virtueEn: 'Surah Al-Baqarah: 186',
    ),
    DhikrNotificationItem(
      titleAr: 'توفيق وسداد 📖',
      titleEn: 'Success & Right Conduct 📖',
      bodyAr: '﴿وَقُلْ رَبِّ أَدْخِلْنِي مُدْخَلَ صِدْقٍ وَأَخْرِجْنِي مُخْرَجَ صِدْقٍ وَاجْعَلْ لِي مِنْ لَدُنْكَ سُلْطَانًا نَصِيرًا﴾',
      bodyEn: '“My Lord, cause me to enter a sound entrance and to exit a sound exit and grant me from Yourself a supporting authority.” (17:80)',
      virtueAr: 'سورة الإسراء — آية 80',
      virtueEn: 'Surah Al-Isra: 80',
    ),
    DhikrNotificationItem(
      titleAr: 'شكر النعمة وبر الوالدين 📖',
      titleEn: 'Gratitude for Favors 📖',
      bodyAr: '﴿رَبِّ أَوْزِعْنِي أَنْ أَشْكُرَ نِعْمَتَكَ الَّتِي أَنْعَمْتَ عَلَيَّ وَعَلَى وَالِدَيَّ وَأَنْ أَعْمَلَ صَالِحًا تَرْضَاهُ﴾',
      bodyEn: '“My Lord, enable me to be grateful for Your favor which You have bestowed upon me and upon my parents.” (27:19)',
      virtueAr: 'سورة النمل — آية 19',
      virtueEn: 'Surah An-Naml: 19',
    ),
    DhikrNotificationItem(
      titleAr: 'دعاء ذي النون 🌊',
      titleEn: 'Supplication of Yunus 🌊',
      bodyAr: 'لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
      bodyEn: 'La ilaha illa Anta subhanaka inni kuntu minaz-zalimeen',
      virtueAr: 'لم يدعُ بها مسلم في كربة إلا فرّج الله عنه',
      virtueEn: 'No Muslim calls upon Allah with this in distress except that He relieves him',
      category: AdhkarCategory.tasbeeh,
    ),
    DhikrNotificationItem(
      titleAr: 'وصية نبوية مباركة 🤲',
      titleEn: 'Prophetic Advice 🤲',
      bodyAr: 'اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ',
      bodyEn: 'Allahumma a’inni ‘ala dhikrika wa shukrika wa husni ‘ibadatik',
      virtueAr: 'وصية النبي ﷺ لمعاذ ألا يدعها دبر كل صلاة',
      virtueEn: 'The Prophet’s counsel to Muadh never to omit this after prayer',
      category: AdhkarCategory.afterPrayer,
    ),
    DhikrNotificationItem(
      titleAr: 'ثبات القلوب 🤲',
      titleEn: 'Firmness of Hearts 🤲',
      bodyAr: 'يَا مُقَلِّبَ الْقُلُوبِ ثَبِّتْ قَلْبِي عَلَى دِينِكَ',
      bodyEn: 'Ya Muqallibal-quloob, thabbit qalbi ‘ala deenik',
      virtueAr: 'من أكثر دعاء النبي صلى الله عليه وسلم',
      virtueEn: 'One of the most frequent prayers of the Prophet ﷺ',
      category: AdhkarCategory.tasbeeh,
    ),
    DhikrNotificationItem(
      titleAr: 'طلب الهدى والغنى 🤲',
      titleEn: 'Guidance & Contentment 🤲',
      bodyAr: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى',
      bodyEn: 'Allahumma inni as’alukal-huda wat-tuqa wal-’afafa wal-ghina',
      virtueAr: 'دعاء نبوي جامع لكل خير في الدين والدنيا',
      virtueEn: 'Comprehensive prophetic prayer for spiritual and worldly good',
    ),
    DhikrNotificationItem(
      titleAr: 'استعاذة من الهم 🛡️',
      titleEn: 'Refuge from Grief & Worry 🛡️',
      bodyAr: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَالْعَجْزِ وَالْكَسَلِ، وَالْجُبْنِ وَالْبُخْلِ، وَضَلَعِ الدَّيْنِ وَغَلَبَةِ الرِّجَالِ',
      bodyEn: 'Allahumma inni a’udhu bika minal-hammi wal-hazani...',
      virtueAr: 'تفريج الهم وقضاء الدين وكفاية العجز والكسل',
      virtueEn: 'Protection from grief, laziness, anxiety and debt',
    ),
    DhikrNotificationItem(
      titleAr: 'طلب العفو والعافية 🌿',
      titleEn: 'Seeking Pardon & Well-Being 🌿',
      bodyAr: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ',
      bodyEn: 'Allahumma inni as’alukal-’afwa wal-’afiyata fid-dunya wal-akhirah',
      virtueAr: 'لم يكن النبي ﷺ يدع هؤلاء الكلمات حين يمسي وحين يصبح',
      virtueEn: 'The Prophet ﷺ never omitted these words morning and evening',
      category: AdhkarCategory.morning,
    ),
    DhikrNotificationItem(
      titleAr: 'توجيه القلوب للطاعة 🤲',
      titleEn: 'Directing Hearts to Obedience 🤲',
      bodyAr: 'اللَّهُمَّ مُصَرِّفَ الْقُلُوبِ صَرِّفْ قُلُوبَنَا عَلَى طَاعَتِكَ',
      bodyEn: 'Allahumma musarrifal-quloobi sarrif quloobana ‘ala ta’atik',
      virtueAr: 'رواه مسلم في صحيحه',
      virtueEn: 'Narrated by Muslim in his Sahih',
    ),
    DhikrNotificationItem(
      titleAr: 'دعاء النور 💡',
      titleEn: 'Supplication for Light 💡',
      bodyAr: 'اللَّهُمَّ اجْعَلْ فِي قَلْبِي نُورًا، وَفِي لِسَانِي نُورًا، وَفِي سَمْعِي نُورًا، وَفِي بَصَرِي نُورًا',
      bodyEn: 'Allahumma ij’al fi qalbi noora, wa fi lisani noora, wa fi sam’i noora, wa fi basari noora',
      virtueAr: 'نور الإيمان واليقين والبصيرة',
      virtueEn: 'Light of faith, wisdom, and clarity',
    ),
    DhikrNotificationItem(
      titleAr: 'دعاء كشف الكرب 🤲',
      titleEn: 'Relief from Distress 🤲',
      bodyAr: 'اللَّهُمَّ رَحْمَتَكَ أَرْجُو فَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ، وَأَصْلِحْ لِي شَأْنِي كُلَّهُ، لَا إِلَهَ إِلَّا أَنْتَ',
      bodyEn: 'Allahumma rahmataka arju fala takilni ila nafsi tarfata ‘ayn...',
      virtueAr: 'دعاء المكروب المأثور',
      virtueEn: 'Supplication for the distressed',
    ),
    DhikrNotificationItem(
      titleAr: 'تزكية النفس وتقواها 🤲',
      titleEn: 'Purification of the Soul 🤲',
      bodyAr: 'اللَّهُمَّ آتِ نُفُوسَنَا تَقْوَاهَا، وَزَكِّهَا أَنْتَ خَيْرُ مَنْ زَكَّاهَا، أَنْتَ وَلِيُّهَا وَمَوْلَاهَا',
      bodyEn: 'Allahumma aati nufoosana taqwaha wa zakkiha Anta khayru man zakkaha',
      virtueAr: 'صلاح السريرة وطهارة القلب',
      virtueEn: 'Purity of the heart and inner righteousness',
    ),
    DhikrNotificationItem(
      titleAr: 'حفظ وأمان 🛡️',
      titleEn: 'Protection from Harm 🛡️',
      bodyAr: 'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
      bodyEn: 'Bismillahilladhi la yadurru ma’as-mihi shay’un fil-ardi wa la fis-samaa’i wa Huwas-Samee’ul-’Aleem',
      virtueAr: 'لم يضره شيء أبداً حتى يمسي أو يصبح',
      virtueEn: 'Nothing will harm him morning or evening',
      category: AdhkarCategory.morning,
    ),
    DhikrNotificationItem(
      titleAr: 'حفظ من كل شر 🛡️',
      titleEn: 'Protection from Evil 🛡️',
      bodyAr: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
      bodyEn: 'A’udhu bi-kalimatillahit-tammati min sharri ma khalaq',
      virtueAr: 'حفظ من كل سوء وهوام الأرض',
      virtueEn: 'Protection from all harm and venomous creatures',
      category: AdhkarCategory.morning,
    ),
    DhikrNotificationItem(
      titleAr: 'أذكار الصباح ☀️',
      titleEn: 'Morning Remembrance ☀️',
      bodyAr: 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
      bodyEn: 'Asbahna wa asbahal-mulku lillah, wal-hamdu lillah...',
      virtueAr: 'حفظ في أول النهار وبركة في الرزق والسعي',
      virtueEn: 'Protection throughout the morning and blessings in effort',
      category: AdhkarCategory.morning,
    ),
    DhikrNotificationItem(
      titleAr: 'أذكار الصباح ☀️',
      titleEn: 'Morning Remembrance ☀️',
      bodyAr: 'اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ',
      bodyEn: 'Allahumma bika asbahna wa bika amsayna wa bika nahya wa bika namootu wa ilaykan-nushoor',
      virtueAr: 'من أذكار الصباح الثابتة عن النبي ﷺ',
      virtueEn: 'Authentic morning dhikr from the Prophet ﷺ',
      category: AdhkarCategory.morning,
    ),
    DhikrNotificationItem(
      titleAr: 'أذكار المساء 🌙',
      titleEn: 'Evening Remembrance 🌙',
      bodyAr: 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
      bodyEn: 'Amsayna wa amsal-mulku lillah, wal-hamdu lillah...',
      virtueAr: 'حفظ وأمان وسكينة طوال الليل حتى يصبح',
      virtueEn: 'Peace, safety, and protection throughout the night',
      category: AdhkarCategory.evening,
    ),
    DhikrNotificationItem(
      titleAr: 'أذكار المساء 🌙',
      titleEn: 'Evening Remembrance 🌙',
      bodyAr: 'اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيرُ',
      bodyEn: 'Allahumma bika amsayna wa bika asbahna wa bika nahya wa bika namootu wa ilaykal-maseer',
      virtueAr: 'من أذكار المساء الثابتة عن النبي ﷺ',
      virtueEn: 'Authentic evening dhikr from the Prophet ﷺ',
      category: AdhkarCategory.evening,
    ),
    DhikrNotificationItem(
      titleAr: 'أذكار المساء 🌙',
      titleEn: 'Evening Remembrance 🌙',
      bodyAr: 'أَمْسَيْنَا عَلَى فِطْرَةِ الْإِسْلَامِ، وَعَلَى كَلِمَةِ الْإِخْلَاصِ، وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ ﷺ، وَعَلَى مِلَّةِ أَبِينَا إِبْرَاهِيمَ حَنِيفًا مُسْلِمًا وَمَا كَانَ مِنَ الْمُشْرِكِينَ',
      bodyEn: 'Amsayna ‘ala fitratil-Islam wa ‘ala kalimatil-ikhlas...',
      virtueAr: 'تجديد عهد التوحيد والاستسلام لله تعالى',
      virtueEn: 'Renewing the covenant of pure Islamic monotheism',
      category: AdhkarCategory.evening,
    ),
    DhikrNotificationItem(
      titleAr: 'شكر نعمة المساء 🌙',
      titleEn: 'Evening Gratitude 🌙',
      bodyAr: 'اللَّهُمَّ مَا أَمْسَى بِي مِنْ نِعْمَةٍ أَوْ بِأَحَدٍ مِنْ خَلْقِكَ فَمِنْكَ وَحْدَكَ لَا شَرِيكَ لَكَ، فَلَكَ الْحَمْدُ وَلَكَ الشُّكْرُ',
      bodyEn: 'Allahumma ma amsa bi min ni’matin aw bi-ahadin min khalqika faminka wahdaka...',
      virtueAr: 'من قالها حين يمسي فقد أدى شكر ليلته',
      virtueEn: 'Whoever says it in the evening has discharged the gratitude of his night',
      category: AdhkarCategory.evening,
    ),
    DhikrNotificationItem(
      titleAr: 'جوامع التسبيح 🌿',
      titleEn: 'Comprehensive Glorification 🌿',
      bodyAr: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ',
      bodyEn: 'Subhan Allahi wa bihamdihi, ‘adada khalqihi, wa rida nafsihi, wa zinata ‘arshihi, wa midada kalimatih',
      virtueAr: 'تزن ساعات طويلة من الذكر والعبادة',
      virtueEn: 'Weighs heavier than hours of continuous worship',
      category: AdhkarCategory.tasbeeh,
    ),
    DhikrNotificationItem(
      titleAr: 'غراس الجنة 🌴',
      titleEn: 'Palm of Paradise 🌴',
      bodyAr: 'سُبْحَانَ اللَّهِ الْعَظِيمِ وَبِحَمْدِهِ',
      bodyEn: 'Subhan Allahil-’Azeemi wa bihamdih',
      virtueAr: 'من قالها غُرست له بها نخلة في الجنة',
      virtueEn: 'Whoever says it, a date palm is planted for him in Paradise',
      category: AdhkarCategory.tasbeeh,
    ),
    DhikrNotificationItem(
      titleAr: 'حمد عظيم 🕊️',
      titleEn: 'Exalted Praise 🕊️',
      bodyAr: 'الْحَمْدُ لِلَّهِ حَمْدًا كَثِيرًا طَيِّبًا مُبَارَكًا فِيهِ، كَمَا يُحِبُّ رَبُّنَا وَيَرْضَى',
      bodyEn: 'Alhamdu lillahi hamdan katheeran tayyiban mubarakan feeh...',
      virtueAr: 'ابتدرها بضعة وثلاثون ملَكاً أيهم يكتبها أولاً',
      virtueEn: 'Over thirty angels raced to write it down first',
      category: AdhkarCategory.tasbeeh,
    ),
    DhikrNotificationItem(
      titleAr: 'تكبير وتعظيم 🤍',
      titleEn: 'Magnifying Allah 🤍',
      bodyAr: 'اللَّهُ أَكْبَرُ كَبِيرًا، وَالْحَمْدُ لِلَّهِ كَثِيرًا، وَسُبْحَانَ اللَّهِ بُكْرَةً وَأَصِيلًا',
      bodyEn: 'Allahu akbaru kabeera, wal-hamdu lillahi katheera, wa subhan Allahi bukratan wa aseela',
      virtueAr: 'عَجِبتُ لها، فُتِحَتْ لها أبواب السماء',
      virtueEn: 'The gates of heaven opened for it',
      category: AdhkarCategory.tasbeeh,
    ),
    DhikrNotificationItem(
      titleAr: 'توبة مستمرة 🤲',
      titleEn: 'Continual Repentance 🤲',
      bodyAr: 'رَبِّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ',
      bodyEn: 'Rabbigh-fir li wa tub ‘alayya innaka Antat-Tawwabur-Raheem',
      virtueAr: 'كان يُعَدُّ للنبي ﷺ في المجلس الواحد مائة مرة',
      virtueEn: 'The Prophet ﷺ was heard reciting this a hundred times in one gathering',
      category: AdhkarCategory.tasbeeh,
    ),
    DhikrNotificationItem(
      titleAr: 'الصلاة الإبراهيمية 🌹',
      titleEn: 'As-Salat Al-Ibrahimiyyah 🌹',
      bodyAr: 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ، وَبَارِكْ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ فِي الْعَالَمِينَ إِنَّكَ حَمِيدٌ مَجِيدٌ',
      bodyEn: 'Allahumma salli ‘ala Muhammadin wa ‘ala aali Muhammad...',
      virtueAr: 'أكمل صيغ الصلاة على النبي صلى الله عليه وسلم',
      virtueEn: 'The most comprehensive formula of blessings upon the Prophet ﷺ',
      category: AdhkarCategory.tasbeeh,
    ),
    DhikrNotificationItem(
      titleAr: 'طلب العفو والمغفرة 🌿',
      titleEn: 'Seeking Divine Pardon 🌿',
      bodyAr: 'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي',
      bodyEn: 'Allahumma innaka ‘Afuwwun tuhibbul-’afwa fa’fu ‘anni',
      virtueAr: 'دعاء جامع علّمه النبي ﷺ لأم المؤمنين عائشة',
      virtueEn: 'Supplication taught by the Prophet ﷺ to Aisha',
    ),
    DhikrNotificationItem(
      titleAr: 'تسبيح الملائكة 🌌',
      titleEn: 'Praise of the Angels 🌌',
      bodyAr: 'سُبُّوحٌ قُدُّوسٌ، رَبُّ الْمَلَائِكَةِ وَالرُّوحِ',
      bodyEn: 'Subboohun Quddoos, Rabbul-malaa’ikati war-Rooh',
      virtueAr: 'تسبيح عظيم كان النبي ﷺ يقوله في ركوعه وسجوده',
      virtueEn: 'Exalted praise the Prophet ﷺ recited in ruku and sujud',
      category: AdhkarCategory.tasbeeh,
    ),
    DhikrNotificationItem(
      titleAr: 'شكر النعم 🌟',
      titleEn: 'Gratitude for Favors 🌟',
      bodyAr: 'يَا رَبِّ لَكَ الْحَمْدُ كَمَا يَنْبَغِي لِجَلَالِ وَجْهِكَ وَلِعَظِيمِ سُلْطَانِكَ',
      bodyEn: 'Ya Rabbi lakal-hamdu kama yambaghi li-jalali wajhika wa li-’azeemi sultanik',
      virtueAr: 'حمد رفيع لا يقدر ثوابه إلا الله سبحانه',
      virtueEn: 'Lofty praise whose divine reward is immense',
      category: AdhkarCategory.tasbeeh,
    ),
  ];

  static List<String> get shortReminders =>
      notificationReminders.map((e) => e.bodyAr).toList();

  static const List<DhikrItem> items = [
    // Morning Adhkar
    DhikrItem(
      id: 1,
      category: AdhkarCategory.morning,
      text: 'أَصْبَحْنَا وَأَصْبَحَ المُلْكُ لِلَّهِ، وَالحَمْدُ لِلَّهِ، لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ المُلْكُ وَلَهُ الحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.',
      fadl: 'من قالها حين يصبح حُفظ حتى يمسي.',
      targetCount: 1,
      source: 'رواه مسلم',
    ),
    DhikrItem(
      id: 2,
      category: AdhkarCategory.morning,
      text: 'اللَّهُمَّ أَنْتَ رَبِّي لاَ إِلَهَ إِلاَّ أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لاَ يَغْفِرُ الذُّنُوبَ إِلاَّ أَنْتَ.',
      fadl: 'سيد الاستغفار: من قاله موقناً به ومات دخل الجنة.',
      targetCount: 1,
      source: 'رواه البخاري',
    ),
    DhikrItem(
      id: 3,
      category: AdhkarCategory.morning,
      text: 'بِسْمِ اللَّهِ الَّذِي لاَ يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الأَرْضِ وَلاَ فِي السَّمَاءِ وَهُوَ السَّمِيعُ العَلِيمُ.',
      fadl: 'لم يضره شيء حتى يمسي.',
      targetCount: 3,
      source: 'رواه أبو داود والترمذي',
    ),
    DhikrItem(
      id: 4,
      category: AdhkarCategory.morning,
      text: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ.',
      fadl: 'حفظ من كل شر وهوام الأرض.',
      targetCount: 3,
      source: 'رواه مسلم',
    ),
    DhikrItem(
      id: 5,
      category: AdhkarCategory.morning,
      text: 'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ، وَلاَ تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ.',
      fadl: 'دعاء جامع لتفريج الكروب وصلاح الحال.',
      targetCount: 1,
      source: 'رواه الحاكم وحسنه الألباني',
    ),
    DhikrItem(
      id: 6,
      category: AdhkarCategory.morning,
      text: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ.',
      fadl: 'تزن ساعات طويلة من الذكر والعبادة.',
      targetCount: 3,
      source: 'رواه مسلم',
    ),

    // Evening Adhkar
    DhikrItem(
      id: 10,
      category: AdhkarCategory.evening,
      text: 'أَمْسَيْنَا وَأَمْسَى المُلْكُ لِلَّهِ، وَالحَمْدُ لِلَّهِ، لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ المُلْكُ وَلَهُ الحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.',
      fadl: 'من قالها حين يمسي حُفظ حتى يصبح.',
      targetCount: 1,
      source: 'رواه مسلم',
    ),
    DhikrItem(
      id: 11,
      category: AdhkarCategory.evening,
      text: 'اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ المَصِيرُ.',
      fadl: 'من أذكار المساء الثابتة عن النبي صلى الله عليه وسلم.',
      targetCount: 1,
      source: 'رواه الترمذي',
    ),
    DhikrItem(
      id: 12,
      category: AdhkarCategory.evening,
      text: 'اللَّهُمَّ مَا أَمْسَى بِي مِنْ نِعْمَةٍ أَوْ بِأَحَدٍ مِنْ خَلْقِكَ، فَمِنْكَ وَحْدَكَ لاَ شَرِيكَ لَكَ، فَلَكَ الحَمْدُ وَلَكَ الشُّكْرُ.',
      fadl: 'من قالها حين يمسي فقد أدى شكر ليلته.',
      targetCount: 1,
      source: 'رواه أبو داود',
    ),
    DhikrItem(
      id: 13,
      category: AdhkarCategory.evening,
      text: 'أَمْسَيْنَا عَلَى فِطْرَةِ الإِسْلاَمِ، وَعَلَى كَلِمَةِ الإِخْلاَصِ، وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ، وَعَلَى مِلَّةِ أَبِينَا إِبْرَاهِيمَ حَنِيفاً مُسْلِماً وَمَا كَانَ مِنَ المُشْرِكِينَ.',
      fadl: 'تجديد عهد التوحيد والاستسلام لله تعالى.',
      targetCount: 1,
      source: 'رواه أحمد',
    ),

    // After Prayer Adhkar
    DhikrItem(
      id: 20,
      category: AdhkarCategory.afterPrayer,
      text: 'أَسْتَغْفِرُ اللَّهَ، أَسْتَغْفِرُ اللَّهَ، أَسْتَغْفِرُ اللَّهَ.\nاللَّهُمَّ أَنْتَ السَّلاَمُ وَمِنْكَ السَّلاَمُ، تَبَارَكْتَ يَا ذَا الجَلاَلِ وَالإِكْرَامِ.',
      fadl: 'يستحب بعد كل صلاة مكتوبة.',
      targetCount: 1,
      source: 'رواه مسلم',
    ),
    DhikrItem(
      id: 21,
      category: AdhkarCategory.afterPrayer,
      text: 'لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ المُلْكُ وَلَهُ الحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، اللَّهُمَّ لاَ مَانِعَ لِمَا أَعْطَيْتَ، وَلاَ مُعْطِيَ لِمَا مَنَعْتَ، وَلاَ يَنْفَعُ ذَا الجَدِّ مِنْكَ الجَدُّ.',
      fadl: 'سنة بعد السلام من الصلاة المفروضة.',
      targetCount: 1,
      source: 'رواه البخاري ومسلم',
    ),
    DhikrItem(
      id: 22,
      category: AdhkarCategory.afterPrayer,
      text: 'سُبْحَانَ اللَّهِ (33)، الحَمْدُ لِلَّهِ (33)، اللَّهُ أَكْبَرُ (33)، تَمَامَ المِائَةِ: لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ المُلْكُ وَلَهُ الحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.',
      fadl: 'غُفرت خطاياه وإن كانت مثل زبد البحر.',
      targetCount: 33,
      source: 'رواه مسلم',
    ),

    // Sleep Adhkar
    DhikrItem(
      id: 30,
      category: AdhkarCategory.sleep,
      text: 'بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي، وَبِكَ أَرْفَعُهُ، فَإِنْ أَمْسَكْتَ نَفْسِي فَارْحَمْهَا، وَإِنْ أَرْسَلْتَهَا فَاحْفَظْهَا بِمَا تَحْفَظُ بِهِ عِبَادَكَ الصَّالِحِينَ.',
      fadl: 'من أذكار النوم الصحيحة لحفظ الروح والجسد.',
      targetCount: 1,
      source: 'رواه البخاري ومسلم',
    ),
    DhikrItem(
      id: 31,
      category: AdhkarCategory.sleep,
      text: 'اللَّهُمَّ أَسْلَمْتُ نَفْسِي إِلَيْكَ، وَفَوَّضْتُ أَمْرِي إِلَيْكَ، وَأَلْجَأْتُ ظَهْرِي إِلَيْكَ، رَغْبَةً وَرَهْبَةً إِلَيْكَ، لاَ مَلْجَأَ وَلاَ مَنْجَا مِنْكَ إِلاَّ إِلَيْكَ، آمَنْتُ بِكِتَابِكَ الَّذِي أَنْزَلْتَ، وَبِنَبِيِّكَ الَّذِي أَرْسَلْتَ.',
      fadl: 'إن مت من ليلتك مت على الفطرة.',
      targetCount: 1,
      source: 'رواه البخاري ومسلم',
    ),

    // General Tasbeeh & Sebha
    DhikrItem(
      id: 40,
      category: AdhkarCategory.tasbeeh,
      text: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ العَظِيمِ',
      fadl: 'كلمتان خفيفتان على اللسان، ثقيلتان في الميزان، حبيبتان إلى الرحمن.',
      targetCount: 100,
      source: 'متفق عليه',
    ),
    DhikrItem(
      id: 41,
      category: AdhkarCategory.tasbeeh,
      text: 'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ',
      fadl: 'مفتاح الرزق وتفريج الهموم ومغفرة الذنوب.',
      targetCount: 100,
      source: 'سنة نبوية',
    ),
    DhikrItem(
      id: 42,
      category: AdhkarCategory.tasbeeh,
      text: 'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
      fadl: 'من صلى عليَّ صلاة صلى الله عليه بها عشراً.',
      targetCount: 10,
      source: 'رواه مسلم',
    ),
    DhikrItem(
      id: 43,
      category: AdhkarCategory.tasbeeh,
      text: 'لاَ حَوْلَ وَلاَ قُوَّةَ إِلاَّ بِاللَّهِ العَلِيِّ العَظِيمِ',
      fadl: 'كنز من كنوز الجنة ودواء لتسعة وتسعين داء.',
      targetCount: 100,
      source: 'متفق عليه',
    ),
  ];

  static List<DhikrItem> getByCategory(AdhkarCategory cat) =>
      items.where((i) => i.category == cat).toList();

  static String getCategoryName(AdhkarCategory cat, bool ar) {
    switch (cat) {
      case AdhkarCategory.morning:
        return ar ? 'أذكار الصباح' : 'Morning Adhkar';
      case AdhkarCategory.evening:
        return ar ? 'أذكار المساء' : 'Evening Adhkar';
      case AdhkarCategory.afterPrayer:
        return ar ? 'أذكار بعد الصلاة' : 'After Prayer';
      case AdhkarCategory.sleep:
        return ar ? 'أذكار النوم' : 'Sleep Adhkar';
      case AdhkarCategory.tasbeeh:
        return ar ? 'التسبيح والذكر' : 'Tasbeeh & Dhikr';
    }
  }
}
