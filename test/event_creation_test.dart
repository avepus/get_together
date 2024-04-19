///need to test event creation
///
///example:
/// 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10,11,12,13,14,15
///
///[0, 0, 1, 0, 0, 0, 3, 3, 3, 3, 3, 3, 1, 1, 0, 0]
///top time should be indices 6-11
///bottom times should be indices 2 and 12-13
///attempting 4 times should only return 3
///having a two timeslot minimum should not return 2
///
///
import 'package:get_together/availability.dart';
import 'package:test/test.dart';
import 'package:get_together/create_event.dart';

void main() {
  test(
      'calculateTimeSlotScores should return correct values base case timeSlotDuration = 1',
      () {
    int timeSlotDuration = 1;
    List<int> convergedAvailability = [
      -6,
      -3,
      1,
      0,
      0,
      0,
      3,
      3,
      3,
      3,
      3,
      3,
      1,
      1,
      0,
      0
    ];
    List<int> expectedScores = [
      -6,
      -3,
      1,
      0,
      0,
      0,
      3,
      3,
      3,
      3,
      3,
      3,
      1,
      1,
      0,
      0
    ];

    List<int> actualScores =
        calculateTimeSlotScores(convergedAvailability, timeSlotDuration);

    expect(actualScores, expectedScores);
  });
  test(
      'calculateTimeSlotScores should return correct values timeSlotDuration = 4',
      () {
    int timeSlotDuration = 4;
    List<int> convergedAvailability = [
      -6,
      -3,
      1,
      0,
      0,
      0,
      3,
      3,
      3,
      3,
      3,
      3,
      1,
      1,
      0,
      0
    ];
    List<int> expectedScores = [
      -8,
      -2,
      1,
      3,
      6,
      9,
      12,
      12,
      12,
      10,
      8,
      5,
      2,
      -5,
      -9,
      -8
    ];

    List<int> actualScores =
        calculateTimeSlotScores(convergedAvailability, timeSlotDuration);

    expect(actualScores, expectedScores);
  });

  test(
      'convergeAvailabilities base case return input availability when only one availability is given',
      () {
    List<Availability> availabilities = [Availability.notSet()];

    List<int> expectedConvergedAvailability =
        List<int>.filled(Availability.ArrayLength, 0); //all values should be 0

    List<int> converged = convergeAvailabilities(availabilities);

    expect(converged, expectedConvergedAvailability);
  });

  test('convergeAvailabilities add multiple should sum values', () {
    List<int> allOnesList = List<int>.filled(Availability.ArrayLength, 1);
    Availability allOnesAvailability =
        Availability(weekAvailability: allOnesList);
    List<Availability> availabilities = [
      allOnesAvailability,
      allOnesAvailability
    ];

    List<int> expectedConvergedAvailability =
        List<int>.filled(Availability.ArrayLength, 2);

    List<int> converged = convergeAvailabilities(availabilities);

    expect(converged, expectedConvergedAvailability);
  });
}
