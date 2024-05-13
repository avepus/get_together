import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

enum Days { Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday }

//represents a week of availability in half hour increments
class Availability {
  static const int ArrayLength = 336;
  static const int HalfHoursInADay = 48;
  static const int badValue = -2;
  static const int notSetValue = 0;
  static const int goodValue = 1;
  static const int greatValue = 2;
  static const List<int> validArrayValues = [
    badValue,
    notSetValue,
    goodValue,
    greatValue
  ];
  static const Map<int, String> ValueDefinitions = {
    Availability.badValue: 'Bad',
    Availability.notSetValue: 'Not Set',
    Availability.goodValue: 'Good',
    Availability.greatValue: 'Great',
  };

  //this is the availability for the week in the user's timezone
  //storing in the user's timezone allows for easier calculations because of daylight savings time
  //you only need to convert the user's availability to UTC to compare with the group's availability
  List<int> weekAvailability = List<int>.filled(ArrayLength, 0);

  //timezone name per the Dart Timezone package that can be passed into tz.getLocation
  String timeZoneName;

  Availability({required this.weekAvailability, required this.timeZoneName}) {
    validateArray();
  }

  static List<int> emptyWeekArray() {
    return List<int>.filled(ArrayLength, notSetValue);
  }

  int getTimeSlotValue(int index) {
    return weekAvailability[index];
  }

  void updateArray(List<int> newAvailability) {
    weekAvailability = newAvailability;
    validateArray();
  }

  validateArray() {
    if (weekAvailability.length != ArrayLength) {
      throw Exception('Array must be of length 336');
    }
    for (int i = 0; i < weekAvailability.length; i++) {
      if (!validArrayValues.contains(weekAvailability[i])) {
        throw Exception(
            'Invalid array value of ${weekAvailability[i]} at index $i which is day ${getDayName(i)} timeslot ${getTimeOfDay(i)}');
      }
    }
  }

  static int getDay(int index) {
    return index ~/ HalfHoursInADay;
  }

  static String getDayName(int index) {
    return Days.values[getDay(index)].toString().split('.').last;
  }

  //get the day of week and half hour timeslot based on the index
  static TimeOfDay getTimeOfDay(int index) {
    int halfHour = (index % Availability.HalfHoursInADay);
    int hour = halfHour ~/ 2;
    int minute = halfHour % 2 == 0 ? 0 : 30;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static String getTimeslotName(int index, BuildContext context) {
    return '${getDayName(index)} ${getTimeOfDay(index).format(context)}';
  }

  Availability getUtcAvailability(DateTime anchorDateTime) {
    if (timeZoneName == 'UTC') {
      return this;
    }

    tz.Location location = tz.getLocation(timeZoneName);
    tz.TZDateTime availabilityDateTime =
        tz.TZDateTime.from(anchorDateTime, location);
    int offset = availabilityDateTime.timeZoneOffset.inMinutes;
    int halfHourOffset = offset ~/ 30;
    List<int> adjustedAvailability =
        rollContents(weekAvailability, halfHourOffset);
    return Availability(
        weekAvailability: adjustedAvailability, timeZoneName: 'UTC');
  }

  static List<int> rollContents(List<int> input, int roll) {
    if (roll < 0) roll += input.length;
    return input.sublist(roll)..addAll(input.sublist(0, roll));
  }
}
