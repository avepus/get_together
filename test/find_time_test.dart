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
import 'package:get_together/classes/availability.dart';
import 'package:test/test.dart';
import 'package:get_together/findTime.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  test('calculateTimeSlotScores should return correct values base case timeSlotDuration = 1', () {
    int timeSlotDuration = 1;
    List<int> convergedAvailability = [-6, -3, 1, 0, 0, 0, 3, 3, 3, 3, 3, 3, 1, 1, 0, 0];
    List<int> expectedScores = [-6, -3, 1, 0, 0, 0, 3, 3, 3, 3, 3, 3, 1, 1, 0, 0];

    List<int> actualScores = calculateTimeSlotScores(convergedAvailability, timeSlotDuration);

    expect(actualScores, expectedScores);
  });
  test('calculateTimeSlotScores should return correct values timeSlotDuration = 4', () {
    int timeSlotDuration = 4;
    List<int> convergedAvailability = [-6, -3, 1, 0, 0, 0, 3, 3, 3, 3, 3, 3, 1, 1, 0, 0];
    List<int> expectedScores = [-8, -2, 1, 3, 6, 9, 12, 12, 12, 10, 8, 5, 2, -5, -9, -8];

    List<int> actualScores = calculateTimeSlotScores(convergedAvailability, timeSlotDuration);

    expect(actualScores, expectedScores);
  });

  test('convergeAvailabilities base case return input availability when only one availability is given', () {
    String timezone = 'America/Chicago';
    List<Availability> availabilities = [Availability(weekAvailability: List.filled(Availability.ArrayLength, 0), timeZoneName: timezone)];

    List<int> expectedConvergedAvailability = List<int>.filled(Availability.ArrayLength, 0); //all values should be 0

    List<int> converged = convergeAvailabilities(availabilities);

    expect(converged, expectedConvergedAvailability);
  });

  test('convergeAvailabilities add multiple should sum values', () {
    String timezone = 'America/Chicago';
    List<int> allOnesList = List<int>.filled(Availability.ArrayLength, 1);
    Availability allOnesAvailability = Availability(weekAvailability: allOnesList, timeZoneName: timezone);
    List<Availability> availabilities = [allOnesAvailability, allOnesAvailability];

    List<int> expectedConvergedAvailability = List<int>.filled(Availability.ArrayLength, 2);

    List<int> converged = convergeAvailabilities(availabilities);

    expect(converged, expectedConvergedAvailability);
  });

  test('sortTimeSlotScores basic test', () {
    List<int> scores = [1, 2, -2];
    List<int> expectedSortedIndexes = [1, 0, 2];
    List<int> sortedIndexes = sortTimeSlotScores(scores);

    expect(sortedIndexes, expectedSortedIndexes);
  });

  test('sortTimeSlotScores base one item test', () {
    List<int> scores = [1];
    List<int> expectedSortedIndexes = [0];
    List<int> sortedIndexes = sortTimeSlotScores(scores);

    expect(sortedIndexes, expectedSortedIndexes);
  });

  test('sortTimeSlotScores base one item test', () {
    List<int> scores = [1, 2, 4, 5, 9, -1, 3];
    List<int> expectedSortedIndexes = [4, 3, 2, 6, 1, 0, 5];
    List<int> sortedIndexes = sortTimeSlotScores(scores);

    expect(sortedIndexes, expectedSortedIndexes);
  });

  test('sortTimeSlotScores with repeated scores', () {
    ///expectation here for repeated values is that first index with that value is first
    List<int> scores = [1, 2, 2, 3, 2];
    List<int> expectedSortedIndexes = [3, 1, 2, 4, 0];
    List<int> sortedIndexes = sortTimeSlotScores(scores);

    expect(sortedIndexes, expectedSortedIndexes);
  });

  test('minAbsDifference test 1', () {
    ///expectation here for repeated values is that first index with that value is first
    List<int> numbers = [1, 5, 2, 3, 2];
    int num = 1;
    int actual = minAbsDifference(numbers, num);
    int expected = 0;

    expect(actual, expected);
  });

  test('minAbsDifference test 2', () {
    ///expectation here for repeated values is that first index with that value is first
    List<int> numbers = [1, 5, 2, 3, 2];
    int num = 10;
    int actual = minAbsDifference(numbers, num);
    int expected = 5;

    expect(actual, expected);
  });

  test('getTopTimeSlots test base test', () {
    int minDistance = 2;
    List<int> sortedIndicies = [1, 5, 8, 3, 2];
    List<int> expected = [1, 5, 8, 3];
    List<int> actual = getTopTimeSlots(sortedIndicies, minDistance);

    expect(actual, expected);
  });

  test('getTopTimeSlots test exclude one too close together', () {
    int minDistance = 2;
    List<int> sortedIndicies = [1, 2, 8, 3, 5];
    List<int> expected = [1, 8, 3, 5];
    List<int> actual = getTopTimeSlots(sortedIndicies, minDistance);

    expect(actual, expected);
  });

  test('getTopTimeSlots test exclude two too close together', () {
    int minDistance = 2;
    List<int> sortedIndicies = [2, 1, 8, 7, 6];
    List<int> expected = [2, 8, 6];
    List<int> actual = getTopTimeSlots(sortedIndicies, minDistance);

    expect(actual, expected);
  });

  test('getTopTimeSlots test larger minDistance', () {
    int minDistance = 4;
    List<int> sortedIndicies = [1, 2, 6, 4, 5, 3, 7, 8, 12];
    List<int> expected = [1, 6, 12];
    List<int> actual = getTopTimeSlots(sortedIndicies, minDistance);

    expect(actual, expected);
  });

  test('findTimeSlots calculate across timezones correctly', () {
    tz.initializeTimeZones();
    int utcIndex = 20;
    int chicagoTimeSlotOffset = -10; //before DST it's -5 from UTC. 5 hour offset = 10 time slots
    String chicagoTimezone = 'America/Chicago';
    tz.Location chicago = tz.getLocation(chicagoTimezone);
    List<int> chicagoAvailabilityArray = Availability.emptyWeekArray();
    chicagoAvailabilityArray[utcIndex + chicagoTimeSlotOffset] = Availability.greatValue;

    Availability chicagoAvailability = Availability(
      weekAvailability: chicagoAvailabilityArray,
      timeZoneName: chicagoTimezone,
    );

    String mawsonTimezone = 'Antarctica/Mawson';
    int mawsonTimeSlotOffset = 10; //+5 hour offset = 10 time slots
    List<int> mawsonAvailabilityArray = Availability.emptyWeekArray();
    mawsonAvailabilityArray[utcIndex + mawsonTimeSlotOffset] = Availability.greatValue;

    Availability mawsonAvailability = Availability(
      weekAvailability: mawsonAvailabilityArray,
      timeZoneName: mawsonTimezone,
    );

    //Monday at 10pm on the week before daylight savings time change which is -5 from UTC
    tz.TZDateTime anchorDate = tz.TZDateTime(chicago, 2023, 10, 30, 22, 0, 0);

    //note, keys are user document IDs which aren't relevant for this test
    Map<String, Availability> availabilityMap = {'abc': chicagoAvailability, 'def': mawsonAvailability};

    Map<int, int> actual = findTimeSlotsFiltered(availabilityMap, 1, 1, anchorDate);

    //the best and only timeslot returned should be utc index 20 (timeslot 21 technically)
    int actualUtcIndex = actual.keys.first;
    expect(actualUtcIndex, utcIndex);

    //the score should be 4 because both users have great availability
    int actualScore = actual[actualUtcIndex]!;
    expect(actualScore, Availability.greatValue * 2);
  });
}
