import 'package:arabs_guard/region_roadmap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('roadmap covers each of the 22 Arab League countries exactly once', () {
    final countries = arabicRegionRoadmap
        .expand((region) => region.countries)
        .toList();
    final englishNames = countries
        .map((country) => country.englishName)
        .toList();
    final arabicNames = countries.map((country) => country.arabicName).toList();

    expect(countries, hasLength(22));
    expect(englishNames.toSet(), hasLength(22));
    expect(arabicNames.toSet(), hasLength(22));
    expect(
      englishNames,
      containsAll(<String>[
        'Egypt',
        'Saudi Arabia',
        'United Arab Emirates',
        'Palestine',
        'Morocco',
        'Somalia',
        'Comoros',
      ]),
    );
    expect(
      arabicNames,
      containsAll(<String>[
        'مصر',
        'السعودية',
        'فلسطين',
        'المغرب',
        'الصومال',
        'جزر القمر',
      ]),
    );
    for (final country in countries) {
      expect(country.arabicName.trim(), isNotEmpty);
      expect(country.englishName.trim(), isNotEmpty);
    }
  });

  test('every expansion region carries a concrete validation next step', () {
    for (final region in arabicRegionRoadmap) {
      expect(region.arabicName, isNotEmpty);
      expect(region.englishName, isNotEmpty);
      expect(region.countries, isNotEmpty);
      expect(region.nextStepArabic, isNotEmpty);
      expect(region.nextStepEnglish, isNotEmpty);
    }
  });
}
