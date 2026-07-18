import 'package:arabs_guard/region_roadmap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('roadmap covers each of the 22 Arab League countries exactly once', () {
    final countries = arabicRegionRoadmap
        .expand((region) => region.countries)
        .toList();

    expect(countries, hasLength(22));
    expect(countries.toSet(), hasLength(22));
    expect(
      countries,
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
  });

  test('every expansion region carries a concrete validation next step', () {
    for (final region in arabicRegionRoadmap) {
      expect(region.arabicName, isNotEmpty);
      expect(region.englishName, isNotEmpty);
      expect(region.countries, isNotEmpty);
      expect(region.nextStep, isNotEmpty);
    }
  });
}
