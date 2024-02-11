enum Days { Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday }

//represents a week of availability in half hour increments
class Availability {
  static const MaxArrayValue = 3;
  static const MinArrayValue = -1;
  static const int ArrayLength = 336;
  static const ValueDefinitions = {
    -1: 'Not Available',
    0: 'Not Set',
    1: 'Sometimes Available',
    2: 'Usually Available',
    3: 'Preferred Time'
  };

  List<int> weekAvailability = List<int>.filled(ArrayLength, 0);

  Availability(this.weekAvailability) {
    this.weekAvailability = weekAvailability;
    validateArray();
  }

  Availability.notSet() {
    weekAvailability = List<int>.filled(ArrayLength, 0);
  }

  void updateArray(List<int> newAvailability) {
    weekAvailability = newAvailability;
    validateArray();
  }

  //get the day of week and half hour timeslot based on the index
  static get_timeslot_name(int index) {
    int day = index ~/ 48;
    int halfHour = (index % 48);
    int hour = halfHour ~/ 2;
    String amOrPm = hour < 12 ? 'AM' : 'PM';
    hour = (hour + 1) % 13;
    String dayName = Days.values[day].toString().split('.').last;
    String halfHourName = halfHour % 2 == 0 ? '00' : '30';
    return '$dayName $hour:$halfHourName $amOrPm';
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
