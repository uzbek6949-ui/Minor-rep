import 'package:flutter_test/flutter_test.dart';
import 'package:minor_rep/utils/formatters.dart';

void main() {
  group('formatDuration', () {
    test('nol va manfiy qiymatlar', () {
      expect(formatDuration(Duration.zero), '0:00');
      expect(formatDuration(const Duration(milliseconds: -5)), '0:00');
    });

    test('daqiqa va sekund', () {
      expect(formatDuration(const Duration(seconds: 9)), '0:09');
      expect(formatDuration(const Duration(minutes: 3, seconds: 42)), '3:42');
      expect(formatDuration(const Duration(minutes: 12, seconds: 5)), '12:05');
    });

    test('soat bilan', () {
      expect(
        formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03',
      );
    });
  });

  test('songCountLabel', () {
    expect(songCountLabel(0), contains('0'));
    expect(songCountLabel(7), startsWith('7'));
  });
}
