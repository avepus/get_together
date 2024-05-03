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
    final chicago = getLocation('America/Chicago');
    setLocalLocation(chicago);

    //Test a Saturday at 10pm which would actually be the next Sunday day in UTC
    TZDateTime testDateTime = TZDateTime(chicago, 2024, 5, 4, 22, 0, 0);

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

  test('getNextDateTime case with big buffer)', () {
    //this is a Wednesday which is after the Monday that's the timeslot
    DateTime date = DateTime.utc(2024, 5, 1);

    //this should be Monday at noon timeslot
    Duration timeSlotAsDuration = Duration(hours: 36);

    Duration bigBuffer = Duration(days: 25);

    DateTime result = getNextDateTime(date, timeSlotAsDuration, bigBuffer);

    DateTime expected = DateTime.utc(2024, 5, 27, 12);

    expect(result, expected);
  });

  test(
      'getNextDateTime case where Sunday is a daylight savings start (jump ahead an hour))',
      () {
    //this is a Wednesday which is after the Monday that's the timeslot
    //TODO: implement this test
    final chicago = getLocation('America/Chicago');
    setLocalLocation(chicago);

    //Test a Monday at 10pm on the week of daylight savings start
    TZDateTime date = TZDateTime(chicago, 2024, 3, 11, 22, 0, 0);

    //Friday at midnight
    Duration timeSlotAsDuration = Duration(days: 5);

    DateTime resultOne = getNextDateTime(date, timeSlotAsDuration);

    //Test a Monday at 10pm on the week before daylight savings time change
    date = TZDateTime(chicago, 2024, 3, 4, 22, 0, 0);

    DateTime resultTwo = getNextDateTime(date, timeSlotAsDuration);

    expect(resultOne.toLocal().hour, resultTwo.toLocal().hour);
  });

  test(
      'getNextDateTime case where Sunday is daylight savings end (falls back an hour)',
      () {
    //this is a Wednesday which is after the Monday that's the timeslot
    //TODO: implement this test
    final chicago = getLocation('America/Chicago');
    setLocalLocation(chicago);

    //Test a Monday at 10pm on the week of daylight savings time end
    TZDateTime date = TZDateTime(chicago, 2023, 11, 6, 22, 0, 0);

    //Friday at midnight
    Duration timeSlotAsDuration = Duration(days: 5);

    DateTime resultOne = getNextDateTime(date, timeSlotAsDuration);

    //Test a Monday at 10pm on the week before daylight savings time change
    date = TZDateTime(chicago, 2023, 10, 30, 22, 0, 0);

    DateTime resultTwo = getNextDateTime(date, timeSlotAsDuration);

    expect(resultOne.toLocal().hour, resultTwo.toLocal().hour);
  });
}
