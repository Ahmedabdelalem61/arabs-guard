class ArabicRegion {
  const ArabicRegion({
    required this.arabicName,
    required this.englishName,
    required this.countries,
    required this.nextStep,
  });

  final String arabicName;
  final String englishName;
  final List<String> countries;
  final String nextStep;
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
    countries: <String>[
      'Saudi Arabia',
      'United Arab Emirates',
      'Kuwait',
      'Qatar',
      'Bahrain',
      'Oman',
      'Yemen',
    ],
    nextStep: 'Provider router inventory and firmware capture partners',
  ),
  ArabicRegion(
    arabicName: 'بلاد الشام والعراق',
    englishName: 'Levant & Iraq',
    countries: <String>['Jordan', 'Palestine', 'Lebanon', 'Syria', 'Iraq'],
    nextStep: 'Fixed, fiber, and mobile gateway catalog validation',
  ),
  ArabicRegion(
    arabicName: 'وادي النيل والمغرب العربي',
    englishName: 'Nile Valley & Maghreb',
    countries: <String>[
      'Egypt',
      'Sudan',
      'Libya',
      'Tunisia',
      'Algeria',
      'Morocco',
      'Mauritania',
    ],
    nextStep: 'Expand the Egyptian validation model market by market',
  ),
  ArabicRegion(
    arabicName: 'القرن الأفريقي والمحيط الهندي',
    englishName: 'Horn of Africa & Indian Ocean',
    countries: <String>['Somalia', 'Djibouti', 'Comoros'],
    nextStep: 'Connectivity and locally supplied router research',
  ),
];
