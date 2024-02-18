import 'package:flutter/material.dart';

enum Days { Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday }

//represents a week of availability in half hour increments
class Availability {
  static const MaxArrayValue = 3;
  static const MinArrayValue = -1;
  static const int ArrayLength = 336;
  static const int HalfHoursInADay = 48;
  static const Map<int, String> ValueDefinitions = {
    -1: 'Not Available',
    0: 'Not Set',
    1: 'Sometimes Available',
    2: 'Usually Available',
    3: 'Preferred Time',
  };

  List<int> weekAvailability = List<int>.filled(ArrayLength, 0);

  Availability({required this.weekAvailability}) {
    validateArray();
  }

  Availability.pass() : weekAvailability = List<int>.filled(ArrayLength, 0);

  Availability.notSet() : weekAvailability = List<int>.filled(ArrayLength, 0);

  void updateArray(List<int> newAvailability) {
    weekAvailability = newAvailability;
    validateArray();
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

  static String get_timeslot_name(int index, BuildContext context) {
    return '${getDayName(index)} ${getTimeOfDay(index).format(context)}';
  }

  validateArray() {
    if (weekAvailability.length != ArrayLength) {
      throw Exception('Array must be of length 336');
    }
    int minimum =
        weekAvailability.reduce((curr, next) => curr < next ? curr : next);
    if (minimum < MinArrayValue) {
      throw Exception('Minimum Availability array value is $MinArrayValue');
    }
    int maxNumber =
        weekAvailability.reduce((curr, next) => curr > next ? curr : next);
    if (maxNumber > MaxArrayValue) {
      throw Exception('Max Availability array value is $MaxArrayValue');
    }
  }
}
