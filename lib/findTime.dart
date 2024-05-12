import 'classes/availability.dart';
import 'dart:math';
import 'package:timezone/data/latest.dart' as tz;

/// Finds time slots based on user availabilities.
///
/// The function takes a map of user document IDs to availabilities and returns a list the best start times for a meet.
///
/// [userAvailabilities] A map of user availabilities. The keys are user IDs.
/// [timeSlotDuration] The duration of the meeting in half hours. e.g. this would be 4 for a two hour meeting.
/// [numberOfSlots] The number of time slots to return.
///
/// Returns a list of the best timeslots for this group's availabilties
Map<int, int> findTimeSlots(Map<String, Availability> userAvailabilities,
    int timeSlotDuration, int numberOfSlots) {
  List<Availability> availabilities = userAvailabilities.values.toList();
  List<int> convergedAvailability = convergeAvailabilities(availabilities);
  List<int> timeSlotScores =
      calculateTimeSlotScores(convergedAvailability, timeSlotDuration);
  List<int> sortedTimeSlotScores = sortTimeSlotScores(timeSlotScores);
  //using timeSlotDuration as the minimum distance might not be ideal for longer durations. May want to consider using timeSlotDuration/2 or soemthing like that
  //For example suggesting a 4 hour event might have good start times of 6 and 8 but we wouldn't display 8 with the current configuration
  Map<int, int> slotsAndScores = {};

  //We have a minDistance to avoid suggesting times that are too close together
  //we divide by 2 to help avoid one good time slot from hiding another one close by
  int minDistance = max(1, timeSlotDuration ~/ 2);

  List<int> topTimeSlots =
      getTopTimeSlots(sortedTimeSlotScores, minDistance, numberOfSlots);
  for (int i in topTimeSlots) {
    slotsAndScores[i] = timeSlotScores[i];
  }
  return slotsAndScores;
  //TODO: create a version of the function that prioritizes time slots with the most users available rather than the "best" availability. This theoretically should be pretty easy. Flatten any available timeslots to 1 and everything else to 0
}

/// Converges availabilities into a single list equal to the sum of all availabilities values
List<int> convergeAvailabilities(List<Availability> availabilities) {
  List<int> converge = List<int>.filled(Availability.ArrayLength, 0);
  for (Availability availability in availabilities) {
    for (int i = 0; i < Availability.ArrayLength; i++) {
      converge[i] += availability.getTimeSlotValue(i);
    }
  }
  return converge;
}

///calculates a score for each time slot if it was the start time for an event
///It sums the next [timeSlotDuration] availabilities for each timeslot
///
///[convergedAvailability] a list of timeslot availability scores for each user
///[timeSlotDuration] the duration of the meeting in half hours
///
///Returns a the total availability score for each timeslot if the event started at that time
List<int> calculateTimeSlotScores(
    List<int> convergedAvailability, int timeSlotDuration) {
  List<int> timeSlotScores = List<int>.filled(convergedAvailability.length, 0);
  for (int i = 0; i < convergedAvailability.length; i++) {
    for (int j = i; j < i + timeSlotDuration; j++) {
      //note we need to wrap around if availability at the end of the week continues into the next week morning
      int index = j % convergedAvailability.length;
      timeSlotScores[i] += convergedAvailability[index];
    }
  }
  return timeSlotScores;
}

/// Sorts the time slot scores in descending order so the highest scores are first
/// [timeSlotScores] a list of scores for each time slot returned by calculateTimeSlotScores
/// Returns a list of indexes of the sorted scores
List<int> sortTimeSlotScores(List<int> timeSlotScores) {
  // Create a list of indexes
  List<int> indicies =
      List<int>.generate(timeSlotScores.length, (index) => index);

  // Sort the list of indexes based on the values in the scores list
  indicies.sort((a, b) => timeSlotScores[b].compareTo(timeSlotScores[a]));

  return indicies;
}

/// Returns the minimum absolute difference between a number and a list of numbers
int minAbsDifference(List<int> numbers, int num) {
  if (numbers.isEmpty) {
    throw ArgumentError('List must not be empty');
  }

  int minDiff = (numbers[0] - num).abs();
  for (int i = 1; i < numbers.length; i++) {
    int diff = (numbers[i] - num).abs();
    if (diff < minDiff) {
      minDiff = diff;
    }
  }

  return minDiff;
}

///Filters out time slots that would be too close together
///TODO: might want to filter out the lowest scores in case we hit the lowest score and end up suggesting random times
List<int> getTopTimeSlots(
    List<int> sortedIndicies, int minDistance, int slots) {
  List<int> topSlots = [];
  for (int i in sortedIndicies) {
    if (topSlots.isEmpty) {
      topSlots.add(i);
    } else if (minAbsDifference(topSlots, i) >= minDistance) {
      topSlots.add(i);
    }
    if (topSlots.length >= slots) {
      break;
    }
  }
  return topSlots;
}
