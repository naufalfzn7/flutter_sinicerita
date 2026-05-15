import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sinicerita/core/utils/home_helpers.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id');
  });
  group('getGreeting', () {
    test('returns "Selamat pagi" for hour 0-10', () {
      expect(getGreeting(0, null), 'Selamat pagi');
      expect(getGreeting(5, null), 'Selamat pagi');
      expect(getGreeting(10, null), 'Selamat pagi');
    });

    test('returns "Selamat siang" for hour 11-14', () {
      expect(getGreeting(11, null), 'Selamat siang');
      expect(getGreeting(12, null), 'Selamat siang');
      expect(getGreeting(14, null), 'Selamat siang');
    });

    test('returns "Selamat sore" for hour 15-17', () {
      expect(getGreeting(15, null), 'Selamat sore');
      expect(getGreeting(16, null), 'Selamat sore');
      expect(getGreeting(17, null), 'Selamat sore');
    });

    test('returns "Selamat malam" for hour 18-23', () {
      expect(getGreeting(18, null), 'Selamat malam');
      expect(getGreeting(21, null), 'Selamat malam');
      expect(getGreeting(23, null), 'Selamat malam');
    });

    test('does not append name when userName is null', () {
      expect(getGreeting(8, null), 'Selamat pagi');
    });

    test('does not append name when userName is empty', () {
      expect(getGreeting(8, ''), 'Selamat pagi');
    });

    test('appends name when userName is provided', () {
      expect(getGreeting(8, 'Budi'), 'Selamat pagi, Budi');
      expect(getGreeting(12, 'Siti'), 'Selamat siang, Siti');
    });

    test('truncates name longer than 30 characters', () {
      final longName = 'A' * 35;
      final result = getGreeting(8, longName);
      expect(result, 'Selamat pagi, ${'A' * 30}...');
    });

    test('does not truncate name exactly 30 characters', () {
      final name30 = 'A' * 30;
      final result = getGreeting(8, name30);
      expect(result, 'Selamat pagi, $name30');
      expect(result.contains('...'), isFalse);
    });

    test('does not truncate name shorter than 30 characters', () {
      final result = getGreeting(8, 'Short Name');
      expect(result, 'Selamat pagi, Short Name');
    });
  });

  group('getDailyTipIndex', () {
    test('returns index within bounds [0, tipsCount)', () {
      final date = DateTime(2024, 6, 15);
      final index = getDailyTipIndex(date, 7);
      expect(index, greaterThanOrEqualTo(0));
      expect(index, lessThan(7));
    });

    test('returns same index for same date (deterministic)', () {
      final date = DateTime(2024, 3, 10);
      final index1 = getDailyTipIndex(date, 7);
      final index2 = getDailyTipIndex(date, 7);
      expect(index1, equals(index2));
    });

    test('returns different index for consecutive days when tipsCount > 1', () {
      final day1 = DateTime(2024, 6, 15);
      final day2 = DateTime(2024, 6, 16);
      final index1 = getDailyTipIndex(day1, 7);
      final index2 = getDailyTipIndex(day2, 7);
      expect(index1, isNot(equals(index2)));
    });

    test('handles tipsCount of 1 (always returns 0)', () {
      final date = DateTime(2024, 6, 15);
      expect(getDailyTipIndex(date, 1), 0);
    });

    test('handles January 1st (day-of-year = 0)', () {
      final jan1 = DateTime(2024, 1, 1);
      final index = getDailyTipIndex(jan1, 7);
      expect(index, 0);
    });

    test('handles December 31st', () {
      final dec31 = DateTime(2024, 12, 31);
      final index = getDailyTipIndex(dec31, 7);
      expect(index, greaterThanOrEqualTo(0));
      expect(index, lessThan(7));
    });
  });

  group('getScoreStatus', () {
    test('returns red category for points 0-39', () {
      final result0 = getScoreStatus(0);
      expect(result0.text, 'Kamu butuh perhatian lebih, yuk cerita');
      expect(result0.colorCategory, 'red');

      final result20 = getScoreStatus(20);
      expect(result20.colorCategory, 'red');

      final result39 = getScoreStatus(39);
      expect(result39.colorCategory, 'red');
    });

    test('returns yellow category for points 40-69', () {
      final result40 = getScoreStatus(40);
      expect(result40.text, 'Keadaanmu cukup stabil, tetap semangat');
      expect(result40.colorCategory, 'yellow');

      final result55 = getScoreStatus(55);
      expect(result55.colorCategory, 'yellow');

      final result69 = getScoreStatus(69);
      expect(result69.colorCategory, 'yellow');
    });

    test('returns green category for points 70-100', () {
      final result70 = getScoreStatus(70);
      expect(result70.text, 'Keadaanmu baik, pertahankan ya!');
      expect(result70.colorCategory, 'green');

      final result85 = getScoreStatus(85);
      expect(result85.colorCategory, 'green');

      final result100 = getScoreStatus(100);
      expect(result100.colorCategory, 'green');
    });

    test('boundary: 39 is red, 40 is yellow', () {
      expect(getScoreStatus(39).colorCategory, 'red');
      expect(getScoreStatus(40).colorCategory, 'yellow');
    });

    test('boundary: 69 is yellow, 70 is green', () {
      expect(getScoreStatus(69).colorCategory, 'yellow');
      expect(getScoreStatus(70).colorCategory, 'green');
    });
  });

  group('formatRelativeTime', () {
    test('returns "Baru saja" for less than 1 minute ago', () {
      final now = DateTime(2024, 6, 15, 10, 30, 0);
      final dateTime = DateTime(2024, 6, 15, 10, 29, 30);
      expect(formatRelativeTime(dateTime, now), 'Baru saja');
    });

    test('returns "X menit lalu" for 1-59 minutes ago', () {
      final now = DateTime(2024, 6, 15, 10, 30, 0);

      final oneMin = DateTime(2024, 6, 15, 10, 29, 0);
      expect(formatRelativeTime(oneMin, now), '1 menit lalu');

      final thirtyMin = DateTime(2024, 6, 15, 10, 0, 0);
      expect(formatRelativeTime(thirtyMin, now), '30 menit lalu');

      final fiftyNineMin = DateTime(2024, 6, 15, 9, 31, 0);
      expect(formatRelativeTime(fiftyNineMin, now), '59 menit lalu');
    });

    test('returns "X jam lalu" for 1-23 hours ago', () {
      final now = DateTime(2024, 6, 15, 10, 30, 0);

      final oneHour = DateTime(2024, 6, 15, 9, 30, 0);
      expect(formatRelativeTime(oneHour, now), '1 jam lalu');

      final fiveHours = DateTime(2024, 6, 15, 5, 30, 0);
      expect(formatRelativeTime(fiveHours, now), '5 jam lalu');

      final twentyThreeHours = DateTime(2024, 6, 14, 11, 30, 0);
      expect(formatRelativeTime(twentyThreeHours, now), '23 jam lalu');
    });

    test('returns formatted date for more than 24 hours ago', () {
      final now = DateTime(2024, 6, 15, 10, 30, 0);
      final twoDaysAgo = DateTime(2024, 6, 13, 10, 30, 0);
      final result = formatRelativeTime(twoDaysAgo, now);
      // Should be formatted as "dd MMM yyyy" in Indonesian locale
      expect(result, contains('13'));
      expect(result, contains('2024'));
    });
  });
}
