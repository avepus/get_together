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
