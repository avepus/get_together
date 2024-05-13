import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/timezone.dart';
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

    test('Get UTC availability should return correct UTC availability', () {
      String timezone = 'Antarctica/Mawson';
      int expectedTimeSlotOffset = -10; //5 hour offset = 10 time slots

      int index1 = 1;
      int updatedIndex1 =
          (index1 + expectedTimeSlotOffset) % Availability.ArrayLength;
      int index1Value = 1;
      int index20 = 20;
      int updatedIndex20 =
          (index20 + expectedTimeSlotOffset) % Availability.ArrayLength;
      int index20Value = -2;
      List<int> weekAvailability = Availability.emptyWeekArray();
      weekAvailability[index1] = index1Value;
      weekAvailability[index20] = index20Value;

      final availability = Availability(
        weekAvailability: weekAvailability.toList(), //use toList to copy
        timeZoneName: timezone,
      );

      //location is +5 from UTC
      List<int> expectedAvailabilityArray = Availability.emptyWeekArray();
      expectedAvailabilityArray[updatedIndex1] = index1Value;
      expectedAvailabilityArray[updatedIndex20] = index20Value;
      final expectedAvailability = Availability(
        weekAvailability: expectedAvailabilityArray,
        timeZoneName: 'UTC',
      );

      tz.initializeTimeZones();
      tz.Location location = tz.getLocation(timezone);
      //date doesn't really matter since this location doesn't do daylight savings
      TZDateTime date = TZDateTime(location, 2023, 11, 20, 22, 0, 0);

      final actualAvailability = availability.getUtcAvailability(date);
      expect(
          actualAvailability.timeZoneName, expectedAvailability.timeZoneName);
      expect(actualAvailability.weekAvailability,
          expectedAvailability.weekAvailability);
    });

    test(
        'getUtcAvailability should return correct UTC availability accounting for after DST time',
        () {
      String timezone = 'America/Chicago';
      int afterDSTExpectedTimeSlotOffset =
          12; //after DST it's -6 from UTC. 6 hour offset = 12 time slots
      int index = 1;
      int indexValue = 2;
      int updatedIndex =
          (index + afterDSTExpectedTimeSlotOffset) % Availability.ArrayLength;

      List<int> weekAvailability = Availability.emptyWeekArray();
      weekAvailability[index] = indexValue;

      final availability = Availability(
        weekAvailability: weekAvailability.toList(), //use toList to copy
        timeZoneName: timezone,
      );

      List<int> expectedAvailabilityArray = Availability.emptyWeekArray();
      expectedAvailabilityArray[updatedIndex] = indexValue;
      final expectedAvailability = Availability(
        weekAvailability: expectedAvailabilityArray,
        timeZoneName: 'UTC',
      );

      tz.initializeTimeZones();
      tz.Location chicago = tz.getLocation(timezone);
      //Monday at 10pm two weeks after daylight savings time ends
      TZDateTime afterDST = TZDateTime(chicago, 2023, 11, 20, 22, 0, 0);

      final actualAvailability = availability.getUtcAvailability(afterDST);
      expect(
          actualAvailability.timeZoneName, expectedAvailability.timeZoneName);
      expect(actualAvailability.weekAvailability,
          expectedAvailability.weekAvailability);
    });

    test(
        'getUtcAvailability should return correct UTC availability accounting for before DST time',
        () {
      String timezone = 'America/Chicago';
      int expectedTimeSlotOffset =
          10; //before DST it's -5 from UTC. 5 hour offset = 10 time slots
      int index = 1;
      int indexValue = 2;
      int beforeDSTIndex =
          (index + expectedTimeSlotOffset) % Availability.ArrayLength;

      List<int> weekAvailability = Availability.emptyWeekArray();
      weekAvailability[index] = indexValue;

      final availability = Availability(
        weekAvailability: weekAvailability.toList(), //use toList to copy
        timeZoneName: timezone,
      );

      List<int> expectedAvailabilityArray = Availability.emptyWeekArray();
      expectedAvailabilityArray[beforeDSTIndex] = indexValue;
      final expectedAvailability = Availability(
        weekAvailability: expectedAvailabilityArray,
        timeZoneName: 'UTC',
      );

      tz.initializeTimeZones();
      tz.Location chicago = tz.getLocation(timezone);
      //Monday at 10pm on the week before daylight savings time change
      TZDateTime beforeDST = TZDateTime(chicago, 2023, 10, 30, 22, 0, 0);

      final actualAvailability = availability.getUtcAvailability(beforeDST);
      expect(
          actualAvailability.timeZoneName, expectedAvailability.timeZoneName);
      expect(actualAvailability.weekAvailability,
          expectedAvailability.weekAvailability);
    });

    test('_rollContents basic tests', () {
      List<int> input = [1, 2, 3, 4, 5];
      List<int> expectedOutput = [5, 1, 2, 3, 4];
      List<int> actualOutput = Availability.rollContents(input, -1);
      expect(actualOutput, expectedOutput);

      List<int> expectedOutputRollBack1 = [2, 3, 4, 5, 1];
      actualOutput = Availability.rollContents(input, 1);
      expect(actualOutput, expectedOutputRollBack1);
    });
  });
}
