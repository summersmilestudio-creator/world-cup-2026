import 'package:flutter_test/flutter_test.dart';

import 'package:football_live/i18n/app_strings.dart';

void main() {
  test('all 10 supported languages have translated core strings', () {
    expect(AppStrings.supported.length, 10);
    for (final loc in AppStrings.supported) {
      final s = AppStrings(loc);
      expect(s.t('appName').isNotEmpty, true);
      expect(s.t('tabLive').isNotEmpty, true);
      expect(s.t('tabNews').isNotEmpty, true);
    }
  });
}
