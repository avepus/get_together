import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_test/flutter_test.dart';

import 'package:get_together/classes/availability.dart';

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
  });
}
