import 'availability.dart';
import 'event.dart';

///TODO: create a version of the function that prioritizes time slots with the most users available rather than the "best" availability
///TODO: create a "smoothing" function to expand a converaged availability with nearby timeslots and take the lowest availability score
///TODO: handle edge cases where the best availability spans a very long period of time. For now, there will be no maximum
/// Finds time slots based on user availabilities.
///
/// The function takes a map of user availabilities and returns a list of events representing the time slots.
///
/// [userAvailabilities] A map of user availabilities. The keys are user IDs.
///
/// Returns a list of events representing the time slots.
List findTimeSlots(
    Map<String, Availability> userAvailabilities, int timeSlotDuration) {
  List<Event> events = [];
  List<Availability> availabilities = userAvailabilities.values.toList();
  List<int> convergedAvailability = convergeAvailabilities(availabilities);
  List<int> timeSlotScores =
      calculateTimeSlotScores(convergedAvailability, timeSlotDuration);
  List<int> sortedTimeSlotScores = sortTimeSlotScores(timeSlotScores);
  //TODO: do the rest of the stuff to get events
  return events;
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