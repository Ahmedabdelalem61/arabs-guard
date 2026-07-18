class ArabicCountry {
  const ArabicCountry({required this.arabicName, required this.englishName});

  final String arabicName;
  final String englishName;
}

class ArabicRegion {
  const ArabicRegion({
    required this.arabicName,
    required this.englishName,
    required this.countries,
    required this.nextStepArabic,
    required this.nextStepEnglish,
  });

  final String arabicName;
  final String englishName;
  final List<ArabicCountry> countries;
  final String nextStepArabic;
  final String nextStepEnglish;
}

/// Public expansion roadmap covering all 22 Arab League member countries.
///
/// A country appearing here is not a router-support claim. Each market still
/// requires provider inventory research and firmware captures before an
/// automatic adapter can be enabled.
const arabicRegionRoadmap = <ArabicRegion>[
  ArabicRegion(
    arabicName: 'الخليج والجزيرة العربية',
    englishName: 'Gulf & Arabian Peninsula',
    countries: <ArabicCountry>[
      ArabicCountry(arabicName: 'السعودية', englishName: 'Saudi Arabia'),
      ArabicCountry(
        arabicName: 'الإمارات العربية المتحدة',
        englishName: 'United Arab Emirates',
      ),
      ArabicCountry(arabicName: 'الكويت', englishName: 'Kuwait'),
      ArabicCountry(arabicName: 'قطر', englishName: 'Qatar'),
      ArabicCountry(arabicName: 'البحرين', englishName: 'Bahrain'),
      ArabicCountry(arabicName: 'عُمان', englishName: 'Oman'),
      ArabicCountry(arabicName: 'اليمن', englishName: 'Yemen'),
    ],
    nextStepArabic:
        'حصر أجهزة المزوّدين وبناء شبكة شركاء لالتقاط إصدارات البرامج الثابتة',
    nextStepEnglish: 'Provider router inventory and firmware capture partners',
  ),
  ArabicRegion(
    arabicName: 'بلاد الشام والعراق',
    englishName: 'Levant & Iraq',
    countries: <ArabicCountry>[
      ArabicCountry(arabicName: 'الأردن', englishName: 'Jordan'),
      ArabicCountry(arabicName: 'فلسطين', englishName: 'Palestine'),
      ArabicCountry(arabicName: 'لبنان', englishName: 'Lebanon'),
      ArabicCountry(arabicName: 'سوريا', englishName: 'Syria'),
      ArabicCountry(arabicName: 'العراق', englishName: 'Iraq'),
    ],
    nextStepArabic:
        'التحقق من بوابات الإنترنت الثابت والألياف والإنترنت المحمول',
    nextStepEnglish: 'Fixed, fiber, and mobile gateway catalog validation',
  ),
  ArabicRegion(
    arabicName: 'وادي النيل والمغرب العربي',
    englishName: 'Nile Valley & Maghreb',
    countries: <ArabicCountry>[
      ArabicCountry(arabicName: 'مصر', englishName: 'Egypt'),
      ArabicCountry(arabicName: 'السودان', englishName: 'Sudan'),
      ArabicCountry(arabicName: 'ليبيا', englishName: 'Libya'),
      ArabicCountry(arabicName: 'تونس', englishName: 'Tunisia'),
      ArabicCountry(arabicName: 'الجزائر', englishName: 'Algeria'),
      ArabicCountry(arabicName: 'المغرب', englishName: 'Morocco'),
      ArabicCountry(arabicName: 'موريتانيا', englishName: 'Mauritania'),
    ],
    nextStepArabic: 'توسيع نموذج التحقق المصري سوقاً بعد سوق',
    nextStepEnglish: 'Expand the Egyptian validation model market by market',
  ),
  ArabicRegion(
    arabicName: 'القرن الأفريقي والمحيط الهندي',
    englishName: 'Horn of Africa & Indian Ocean',
    countries: <ArabicCountry>[
      ArabicCountry(arabicName: 'الصومال', englishName: 'Somalia'),
      ArabicCountry(arabicName: 'جيبوتي', englishName: 'Djibouti'),
      ArabicCountry(arabicName: 'جزر القمر', englishName: 'Comoros'),
    ],
    nextStepArabic: 'بحث الاتصال وأجهزة الراوتر الموردة محلياً',
    nextStepEnglish: 'Connectivity and locally supplied router research',
  ),
];
