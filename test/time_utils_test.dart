import 'package:test/test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';
import 'package:get_together/time_utils.dart';

void main() {
  tz.initializeTimeZones();

  test('getBeginningOfWeekUTC sanity test Sunday returns the same day', () {
    DateTime date = DateTime.utc(2024, 4, 28);
    DateTime expected = DateTime.utc(2024, 4, 28);

    DateTime actual = getBeginningOfWeekUTC(date);

    expect(actual, expected);
  });
  test(
      'getBeginningOfWeekUTC basic test, 2024-05-01 is a Wednesday, should return 2024-4-28',
      () {
    DateTime date = DateTime.utc(2024, 5, 1);
    DateTime expected = DateTime.utc(2024, 4, 28);

    DateTime actual = getBeginningOfWeekUTC(date);

    expect(actual, expected);
  });

  test(
      'getBeginningOfWeekUTC corner case UTC is next week (Chicago time zone which is utc-6)',
      () {
    final detroit = getLocation('America/Chicago');
    setLocalLocation(detroit);

    //Test a Saturday at 10pm which would actually be the next Sunday day in UTC
    TZDateTime testDateTime = TZDateTime(detroit, 2024, 5, 4, 22, 0, 0);

    DateTime result = getBeginningOfWeekUTC(testDateTime);

    // The beginning of the week should be the previous Sunday at midnight UTC
    DateTime expected = DateTime.utc(2024, 5, 5);

    expect(result, expected);
  });

  test(
      'getBeginningOfWeekUTC corner case where UTC time is last week (Guam time zone is utc+10)',
      () {
    final guam = getLocation('Pacific/Guam');
    setLocalLocation(guam);

    //Test a Sunday at 5am which would actually be the previous Saturday in UTC
    TZDateTime testDateTime = TZDateTime(guam, 2024, 5, 5, 5, 0, 0);

    DateTime result = getBeginningOfWeekUTC(testDateTime);

    // The beginning of the week should be the previous Sunday at midnight UTC
    DateTime expected = DateTime.utc(2024, 4, 28);

    expect(result, expected);
  });

  test('getNextDateTime basic case)', () {
    //this is a Wednesday
    DateTime date = DateTime.utc(2024, 5, 1);

    //this should be Saturday at midnight which is more than 1 day away so it works
    Duration timeSlotAsDuration = Duration(days: 6);

    DateTime result = getNextDateTime(date, timeSlotAsDuration);

    //we expect that Saturday time to work
    DateTime expected = DateTime.utc(2024, 5, 4);

    expect(result, expected);
  });

  test(
      'getNextDateTime case where best time is previous day this week so it goes to next week)',
      () {
    //this is a Wednesday which is after the Monday that's the timeslot
    DateTime date = DateTime.utc(2024, 5, 1);

    //this should be Monday at noon timeslot
    Duration timeSlotAsDuration = Duration(hours: 36);

    DateTime result = getNextDateTime(date, timeSlotAsDuration);

    DateTime expected = DateTime.utc(2024, 5, 6, 12);

    expect(result, expected);
  });
}
