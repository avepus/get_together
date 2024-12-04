import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import '../utils.dart';
import 'event.dart';

enum Days { Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday }

//represents a week of availability in half hour increments
class Availability {
  static const int timeSlotDuration = 30; //minutes
  static const int timeSlotsInADay = (24 * 60) ~/ timeSlotDuration;
  static const int arrayLength = timeSlotsInADay * 7;
  static const int badValue = -2;
  static const int notSetValue = 0;
  static const int goodValue = 1;
  static const int greatValue = 2;
  static const List<int> validArrayValues = [badValue, notSetValue, goodValue, greatValue];
  static const Map<int, String> ValueDefinitions = {
    Availability.badValue: 'Bad',
    Availability.notSetValue: 'Not Set',
    Availability.goodValue: 'Good',
    Availability.greatValue: 'Great',
  };

  //this is the availability for the week in the user's timezone
  //storing in the user's timezone allows for easier calculations because of daylight savings time
  //you only need to convert the user's availability to UTC to compare with the group's availability
  List<int> weekAvailability = List<int>.filled(arrayLength, 0);

  //timezone name per the Dart Timezone package that can be passed into tz.getLocation
  String timeZoneName;

  Availability({required this.weekAvailability, required this.timeZoneName}) {
    validateArray();
  }

  static List<int> emptyWeekArray() {
    return List<int>.filled(arrayLength, notSetValue);
  }

  int getTimeSlotValue(int index) {
    return weekAvailability[index];
  }

  void updateArray(List<int> newAvailability) {
    weekAvailability = newAvailability;
    validateArray();
  }

  validateArray() {
    if (weekAvailability.length != arrayLength) {
      throw Exception('Array must be of length $arrayLength');
    }
    for (int i = 0; i < weekAvailability.length; i++) {
      if (!validArrayValues.contains(weekAvailability[i])) {
        throw Exception('Invalid array value of ${weekAvailability[i]} at index $i which is day ${getDayName(i)} timeslot ${getTimeOfDay(i)}');
      }
    }
  }

  static int getDay(int index) {
    return index ~/ timeSlotsInADay;
  }

  static String getDayName(int index) {
    return Days.values[getDay(index)].toString().split('.').last;
  }

  //get the day of week and half hour timeslot based on the index
  static TimeOfDay getTimeOfDay(int index) {
    int halfHour = (index % Availability.timeSlotsInADay);
    int hour = halfHour ~/ 2;
    int minute = halfHour % 2 == 0 ? 0 : 30;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static String getTimeslotName(int index, BuildContext context) {
    return '${getDayName(index)} ${getTimeOfDay(index).format(context)}';
  }

  /// returns a new availability object with the weekAvailability converted to the input timezone
  Availability getTzAvailability(String timezone, [DateTime? anchorDate]) {
    if (timeZoneName == timezone) {
      return this;
    }
    anchorDate ??= DateTime.now();

    tz.Location currentLocation = tz.getLocation(timeZoneName);
    tz.Location inputLocation = tz.getLocation(timezone);
    int offset = timeZoneOffsetInTimeSlots(currentLocation, inputLocation, anchorDate);
    List<int> adjustedAvailability = rollList(weekAvailability, offset);
    return Availability(weekAvailability: adjustedAvailability, timeZoneName: timezone);
  }

  AttendanceResponse getAttendanceResponseForEvent(DateTime start, DateTime end, String timezone) {
    int averageAvailability = getAverageAvailabilityBetween(start, end, timezone);
    if (averageAvailability >= Availability.goodValue) {
      return AttendanceResponse.unconfirmedYes;
    } else if (averageAvailability >= Availability.notSetValue) {
      return AttendanceResponse.unconfirmedMaybe;
    } else {
      return AttendanceResponse.unconfirmedNo;
    }
  }

  int getAverageAvailabilityBetween(DateTime start, DateTime end, String timezone) {
    List<int> availability = getAvailabilityBetween(start, end, timezone);
    int sum = availability.fold(0, (previousValue, element) => previousValue + element);
    return sum ~/ availability.length;
  }

  List<int> getAvailabilityBetween(DateTime start, DateTime end, String timezone) {
    Availability tzAvailability = getTzAvailability(timezone, start);
    int startSlot = Availability.convertDateTimeToTimeslot(start);
    int endSlot = Availability.convertDateTimeToTimeslot(end);
    return Availability.sublistWithWrap(tzAvailability.weekAvailability, startSlot, endSlot);
  }

  ///gets the timeslot based on the day of the week and the time
  static int convertDateTimeToTimeslot(DateTime datetime) {
    int daySlots = getTimeSlotFromDayOfWeek(datetime);
    int timeSlots = getTimeSlotFromTime(datetime);
    return daySlots + timeSlots;
  }

  static int getTimeSlotFromDayOfWeek(DateTime datetime) {
    return getWeekdayWithSundayStart(datetime) * timeSlotsInADay;
  }

  static int getWeekdayWithSundayStart(DateTime datetime) {
    return (datetime.weekday + 7) % 7;
  }

  static int getTimeSlotFromTime(DateTime datetime) {
    //because the first timeslot is 0, we need to subtract 1
    return (datetime.hour * 2 + (datetime.minute ~/ timeSlotDuration));
  }

  static int timeZoneOffsetInMinutes(tz.Location location1, tz.Location location2, DateTime anchorDate) {
    DateTime time1 = tz.TZDateTime.from(anchorDate, location1);
    DateTime time2 = tz.TZDateTime.from(anchorDate, location2);
    Duration offset1 = time1.timeZoneOffset;
    Duration offset2 = time2.timeZoneOffset;
    return offset1.inMinutes - offset2.inMinutes;
  }

  static int timeZoneOffsetInTimeSlots(tz.Location location1, tz.Location location2, DateTime anchorDate) {
    int offsetMins = timeZoneOffsetInMinutes(location1, location2, anchorDate);
    return offsetMins ~/ Availability.timeSlotDuration;
  }

  static List<T> sublistWithWrap<T>(List<T> list, int start, [int? end]) {
    List<T> result = [];

    //the following line handles a corner case where end is 0. Technically that means we loop but this isn't inclusive so we treat it as grabbing everything from start to the last item in the array
    if (end == null || end == 0) {
      result.addAll(list.sublist(start));
    } else if (start <= end) {
      result.addAll(list.sublist(start, end));
    } else {
      result.addAll(list.sublist(start));
      result.addAll(list.sublist(0, end));
    }

    return result;
  }
}
