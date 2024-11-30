import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_test/flutter_test.dart';

import 'package:get_together/classes/availability.dart';
import 'package:get_together/classes/event.dart';

void main() {
  group('Availability', () {
    test('Empty week array should have length 336', () {
      final emptyWeekArray = Availability.emptyWeekArray();
      expect(emptyWeekArray.length, 336);
    });

    test('Get time slot value should return correct value', () {
      List<int> firstFourSlots = [1, 2, 0, -2];
      final availability = Availability(
        weekAvailability: Availability.emptyWeekArray(),
        timeZoneName: 'America/New_York',
      );
      availability.weekAvailability.setRange(0, 4, firstFourSlots);
      expect(availability.getTimeSlotValue(0), 1);
      expect(availability.getTimeSlotValue(1), 2);
      expect(availability.getTimeSlotValue(2), 0);
      expect(availability.getTimeSlotValue(3), -2);
    });

    test('Invalid array length should throw an exception', () {
      expect(
        () => Availability(
          weekAvailability: [1, 2, 0],
          timeZoneName: 'America/New_York',
        ),
        throwsException,
      );
    });

    test('Invalid array value should throw an exception', () {
      expect(
        () => Availability(
          weekAvailability: [1, 2, 3, 4],
          timeZoneName: 'America/New_York',
        ),
        throwsException,
      );
    });

    test('Get day should return correct day', () {
      expect(Availability.getDay(0), 0);
      expect(Availability.getDay(47), 0);
      expect(Availability.getDay(48), 1);
      expect(Availability.getDay(335), 6);
    });

    test('Get day name should return correct day name', () {
      expect(Availability.getDayName(0), 'Sunday');
      expect(Availability.getDayName(47), 'Sunday');
      expect(Availability.getDayName(48), 'Monday');
      expect(Availability.getDayName(335), 'Saturday');
    });

    test('Get time of day should return correct time of day', () {
      expect(Availability.getTimeOfDay(0), TimeOfDay(hour: 0, minute: 0));
      expect(Availability.getTimeOfDay(1), TimeOfDay(hour: 0, minute: 30));
      expect(Availability.getTimeOfDay(2), TimeOfDay(hour: 1, minute: 0));
      expect(Availability.getTimeOfDay(47), TimeOfDay(hour: 23, minute: 30));
    });

    test('timeZoneOffsetInMinutes test', () {
      tz.initializeTimeZones();
      int chicagoNonDSTOffset = -6 * 60; //6 hours behind UTC
      int chicagoDSTOffset = -5 * 60; //5 hours behind UTC
      int mawsonOffset = 5 * 60; //5 hours ahead of UTC
      tz.Location chicago = tz.getLocation('America/Chicago');
      tz.Location utc = tz.getLocation('UTC');
      tz.Location mawson = tz.getLocation('Antarctica/Mawson');

      //the week before daylight savings time change which is -5 from UTC
      tz.TZDateTime dateBeforeDST = tz.TZDateTime(chicago, 2023, 10, 30, 22, 0, 0);

      //the week before daylight savings time change which is 65 from UTC
      tz.TZDateTime dateAfterDST = tz.TZDateTime(chicago, 2023, 11, 30, 22, 0, 0);

      int chicagoToUTC = Availability.timeZoneOffsetInMinutes(chicago, utc, dateBeforeDST);
      expect(chicagoToUTC, chicagoDSTOffset);

      int chicagoToMawsonBeforeDST = Availability.timeZoneOffsetInMinutes(chicago, mawson, dateBeforeDST);
      expect(chicagoToMawsonBeforeDST, chicagoDSTOffset - mawsonOffset);

      int chicagoToMawsonAfterDST = Availability.timeZoneOffsetInMinutes(chicago, mawson, dateAfterDST);
      expect(chicagoToMawsonAfterDST, chicagoNonDSTOffset - mawsonOffset);
    });

    test('timeZoneOffsetInTimeSlots test', () {
      tz.initializeTimeZones();
      int mawsonOffset = (5 * 60) ~/ Availability.timeSlotDuration; //5 hours ahead of UTC
      tz.Location mawson = tz.getLocation('Antarctica/Mawson');
      tz.Location utc = tz.getLocation('UTC');
      tz.TZDateTime date = tz.TZDateTime(mawson, 2023, 10);

      int mawsoneToUTC = Availability.timeZoneOffsetInTimeSlots(mawson, utc, date);
      expect(mawsoneToUTC, mawsonOffset);
    });

    test('getTimeSlotFromTimeOfDay test', () {
      DateTime time = DateTime(2024, 11, 11, 0, 0, 0); //this is Monday at 12:00 Am
      int timeSlot = Availability.getTimeSlotFromTime(time);
      expect(timeSlot, 0);

      time = DateTime(2024, 11, 11, 1, 0, 0); //this is Monday at 1:00 Am
      timeSlot = Availability.getTimeSlotFromTime(time);
      expect(timeSlot, 2);
    });

    test('getTimeSlotFromDayOfWeek test', () {
      DateTime time = DateTime(2024, 11, 11, 1, 0, 0); //this is Monday at 1:00 Am
      int timeSlot = Availability.getTimeSlotFromDayOfWeek(time);
      expect(timeSlot, 48);
    });

    test('getWeekdayWithSundayStart test', () {
      DateTime sunday = DateTime(2024, 11, 10);
      DateTime monday = DateTime(2024, 11, 11);
      DateTime tuesday = DateTime(2024, 11, 12);
      DateTime wednesday = DateTime(2024, 11, 13);
      DateTime thursday = DateTime(2024, 11, 14);
      DateTime friday = DateTime(2024, 11, 15);
      DateTime saturday = DateTime(2024, 11, 16);
      DateTime sunday2 = DateTime(2024, 11, 17);
      int weekday = Availability.getWeekdayWithSundayStart(sunday);
      expect(weekday, 0);
      weekday = Availability.getWeekdayWithSundayStart(monday);
      expect(weekday, 1);
      weekday = Availability.getWeekdayWithSundayStart(tuesday);
      expect(weekday, 2);
      weekday = Availability.getWeekdayWithSundayStart(wednesday);
      expect(weekday, 3);
      weekday = Availability.getWeekdayWithSundayStart(thursday);
      expect(weekday, 4);
      weekday = Availability.getWeekdayWithSundayStart(friday);
      expect(weekday, 5);
      weekday = Availability.getWeekdayWithSundayStart(saturday);
      expect(weekday, 6);
      weekday = Availability.getWeekdayWithSundayStart(sunday2);
      expect(weekday, 0);
    });

    test('convertDateTimeToTimeslot first timeslot test', () {
      DateTime sundayMidnight = DateTime(2024, 11, 10, 0, 0, 0); //this is Sunday at midnight
      int timeSlot = Availability.convertDateTimeToTimeslot(sundayMidnight);
      expect(timeSlot, 0);
    });

    test('convertDateTimeToTimeslot last timeslot test', () {
      DateTime saturday2330 = DateTime(2024, 11, 16, 23, 30, 0); //this is Monday at midnight
      int timeSlot = Availability.convertDateTimeToTimeslot(saturday2330);
      expect(timeSlot, 335);
    });

    test('convertDateTimeToTimeslot other timeslot tests', () {
      DateTime mondayMidnight = DateTime(2024, 11, 11, 0, 0, 0); //this is Monday at midnight
      int timeSlot = Availability.convertDateTimeToTimeslot(mondayMidnight);
      expect(timeSlot, 48);
    });

    test('sublistWithWrap  tests', () {
      List<int> t1List = [1];
      List<int> result = Availability.sublistWithWrap(t1List, 0, 1);
      expect(result, [1]);

      List<int> t2List = [1, 2, 3, 4, 5];
      result = Availability.sublistWithWrap(t2List, 0, 3);
      expect(result, [1, 2, 3]);

      result = Availability.sublistWithWrap(t2List, 3, 0);
      expect(result, [4, 5]);

      result = Availability.sublistWithWrap(t2List, 3, 1);
      expect(result, [4, 5, 1]);

      result = Availability.sublistWithWrap(t2List, 2);
      expect(result, [3, 4, 5]);

      result = Availability.sublistWithWrap(t2List, 2, 2);
      expect(result, []);
    });

    test('getAvailabilityBetween tests', () {
      String tzName = 'America/New_York';
      tz.initializeTimeZones();
      tz.Location newYork = tz.getLocation(tzName);

      List<int> availabilityList = Availability.emptyWeekArray();

      tz.TZDateTime sundayMidnight = tz.TZDateTime(newYork, 2024, 11, 10, 0, 0, 0); //this is Sunday at midnight
      int sundayMidnightSlot = Availability.convertDateTimeToTimeslot(sundayMidnight);
      availabilityList[sundayMidnightSlot] = Availability.badValue;

      tz.TZDateTime sunday0100 = tz.TZDateTime(newYork, 2024, 11, 10, 1, 0, 0); //this is Sunday at 1:00 am
      int sunday0100Slot = Availability.convertDateTimeToTimeslot(sunday0100);
      availabilityList[sunday0100Slot] = Availability.goodValue;

      tz.TZDateTime sunday0200 = tz.TZDateTime(newYork, 2024, 11, 10, 2, 0, 0); //this is Sunday at 2:00 am

      tz.TZDateTime nextSundayMidnight = tz.TZDateTime(newYork, 2024, 11, 17, 0, 0, 0); //this is next Sunday at midnight

      tz.TZDateTime Saturday2300 = tz.TZDateTime(newYork, 2024, 11, 16, 23, 0, 0); //this is Monday at midnight

      tz.TZDateTime saturday2330 = tz.TZDateTime(newYork, 2024, 11, 16, 23, 30, 0); //this is Monday at midnight
      int saturday2330Slot = Availability.convertDateTimeToTimeslot(saturday2330);
      availabilityList[saturday2330Slot] = Availability.greatValue;

      Availability availability = Availability(
        weekAvailability: availabilityList,
        timeZoneName: tzName,
      );
      //test inclusivity of start on midnight Sunday
      List<int> result = availability.getAvailabilityBetween(sundayMidnight, sunday0200, tzName);

      List<int> expected = [Availability.badValue, Availability.notSetValue, Availability.goodValue, Availability.notSetValue];

      expect(result, expected);

      //test exclusivity of end. i.e. end datetime of Sunday at midnight should return the final 11:30 pm Saturday timeslot
      result = availability.getAvailabilityBetween(Saturday2300, nextSundayMidnight, tzName);

      expected = [Availability.notSetValue, Availability.greatValue];

      expect(result, expected);

      //
    });

    test('getAverageAvailabilityBetween tests', () {
      String tzName = 'America/New_York';
      tz.initializeTimeZones();
      tz.Location newYork = tz.getLocation(tzName);

      List<int> availabilityList = Availability.emptyWeekArray();

      tz.TZDateTime sundayMidnight = tz.TZDateTime(newYork, 2024, 11, 10, 0, 0, 0); //this is Sunday at midnight
      int sundayMidnightSlot = Availability.convertDateTimeToTimeslot(sundayMidnight);
      availabilityList[sundayMidnightSlot] = Availability.greatValue;

      tz.TZDateTime sunday0100 = tz.TZDateTime(newYork, 2024, 11, 10, 1, 0, 0); //this is Sunday at 1:00 am
      int sunday0100Slot = Availability.convertDateTimeToTimeslot(sunday0100);
      availabilityList[sunday0100Slot] = Availability.greatValue;

      tz.TZDateTime sunday0200 = tz.TZDateTime(newYork, 2024, 11, 10, 2, 0, 0); //this is Sunday at 2:00 am

      Availability availability = Availability(
        weekAvailability: availabilityList,
        timeZoneName: tzName,
      );
      //test inclusivity of start on midnight Sunday
      int result = availability.getAverageAvailabilityBetween(sundayMidnight, sunday0200, tzName);

      expect(result, 1);
    });

    test('getAttendanceResponseForEvent test yes', () {
      String tzName = 'America/New_York';
      tz.initializeTimeZones();
      tz.Location newYork = tz.getLocation(tzName);

      List<int> availabilityList = Availability.emptyWeekArray();

      tz.TZDateTime sundayMidnight = tz.TZDateTime(newYork, 2024, 11, 10, 0, 0, 0); //this is Sunday at midnight
      int sundayMidnightSlot = Availability.convertDateTimeToTimeslot(sundayMidnight);
      availabilityList[sundayMidnightSlot] = Availability.greatValue;

      tz.TZDateTime sunday0100 = tz.TZDateTime(newYork, 2024, 11, 10, 1, 0, 0); //this is Sunday at 1:00 am
      int sunday0100Slot = Availability.convertDateTimeToTimeslot(sunday0100);
      availabilityList[sunday0100Slot] = Availability.greatValue;

      tz.TZDateTime sunday0200 = tz.TZDateTime(newYork, 2024, 11, 10, 2, 0, 0); //this is Sunday at 2:00 am

      Availability availability = Availability(
        weekAvailability: availabilityList,
        timeZoneName: tzName,
      );
      //test inclusivity of start on midnight Sunday
      AttendanceResponse result = availability.getAttendanceResponseForEvent(sundayMidnight, sunday0200, tzName);
      expect(result, AttendanceResponse.yes);
    });

    test('getAttendanceResponseForEvent test no', () {
      String tzName = 'America/New_York';
      tz.initializeTimeZones();
      tz.Location newYork = tz.getLocation(tzName);

      List<int> availabilityList = Availability.emptyWeekArray();

      tz.TZDateTime nextSundayMidnight = tz.TZDateTime(newYork, 2024, 11, 17, 0, 0, 0); //this is next Sunday at midnight

      tz.TZDateTime Saturday2300 = tz.TZDateTime(newYork, 2024, 11, 16, 23, 0, 0);

      tz.TZDateTime saturday2330 = tz.TZDateTime(newYork, 2024, 11, 16, 23, 30, 0);
      int saturday2330Slot = Availability.convertDateTimeToTimeslot(saturday2330);
      availabilityList[saturday2330Slot] = Availability.badValue;

      Availability availability = Availability(
        weekAvailability: availabilityList,
        timeZoneName: tzName,
      );

      AttendanceResponse result = availability.getAttendanceResponseForEvent(Saturday2300, nextSundayMidnight, tzName);
      expect(result, AttendanceResponse.no);
    });

    test('getAttendanceResponseForEvent test maybe', () {
      String tzName = 'America/New_York';
      tz.initializeTimeZones();
      tz.Location newYork = tz.getLocation(tzName);

      List<int> availabilityList = Availability.emptyWeekArray();

      tz.TZDateTime nextSundayMidnight = tz.TZDateTime(newYork, 2024, 11, 17, 0, 0, 0); //this is next Sunday at midnight

      tz.TZDateTime Saturday2300 = tz.TZDateTime(newYork, 2024, 11, 16, 23, 0, 0);

      Availability availability = Availability(
        weekAvailability: availabilityList,
        timeZoneName: tzName,
      );

      AttendanceResponse result = availability.getAttendanceResponseForEvent(Saturday2300, nextSundayMidnight, tzName);
      expect(result, AttendanceResponse.maybe);
    });
  });
}
