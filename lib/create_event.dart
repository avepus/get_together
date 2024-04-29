import 'classes/availability.dart';
import 'classes/event.dart';

///TODO: create a version of the function that prioritizes time slots with the most users available rather than the "best" availability
/// Finds time slots based on user availabilities.
///
/// The function takes a map of user availabilities and returns a list of events representing the time slots.
///
/// [userAvailabilities] A map of user availabilities. The keys are user IDs.
///
/// Returns a list of the best timeslots for this group's availabilties
/// Next - return a map of the best times mapped to the associated scores so the scores can be displayed.
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
  List<int> topTimeSlots =
      getTopTimeSlots(sortedTimeSlotScores, timeSlotDuration, numberOfSlots);
  for (int i in topTimeSlots) {
    slotsAndScores[i] = timeSlotScores[i];
  }
  return slotsAndScores;
}

/// Converges availabilities into a single list equal to the sume of all availabilities values
List<int> convergeAvailabilities(List<Availability> availabilities) {
  List<int> converge = List<int>.filled(Availability.ArrayLength, 0);
  for (Availability availability in availabilities) {
    for (int i = 0; i < Availability.ArrayLength; i++) {
      converge[i] += availability.getTimeSlotValue(i);
    }
  }
  return converge;
}

List<int> calculateTimeSlotScores(
    List<int> convergedAvailability, int timeSlotDuration) {
  List<int> timeSlotScores = List<int>.filled(convergedAvailability.length, 0);
  for (int i = 0; i < convergedAvailability.length; i++) {
    for (int j = i; j < i + timeSlotDuration; j++) {
      int index = j %
          convergedAvailability
              .length; //note we need to wrap around if availability at the end of the week continues into the next week morning
      timeSlotScores[i] += convergedAvailability[index];
    }
  }
  return timeSlotScores;
}

/// Sorts the time slot scores in descending order in a map that maps the time slot index to the score
List<int> sortTimeSlotScores(List<int> timeSlotScores) {
  // Create a list of indexes
  List<int> indicies =
      List<int>.generate(timeSlotScores.length, (index) => index);

  // Sort the list of indexes based on the values in the scores list
  indicies.sort((a, b) => timeSlotScores[b].compareTo(timeSlotScores[a]));

  return indicies;
}

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
