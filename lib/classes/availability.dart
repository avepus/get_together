import 'package:flutter/material.dart';

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

  List<int> weekAvailability = List<int>.filled(ArrayLength, 0);

  Availability({required this.weekAvailability}) {
    validateArray();
  }

  Availability.notSet() : weekAvailability = List<int>.filled(ArrayLength, 0);

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
}
