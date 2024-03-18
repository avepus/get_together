import 'availability.dart';
import 'event.dart';

/// Finds time slots based on user availabilities.
///
/// The function takes a map of user availabilities and returns a list of events representing the time slots.
///
/// [userAvailabilities] A map of user availabilities. The keys are user IDs.
///
/// Returns a list of events representing the time slots.
List findTimeSlots(Map<String, Availability> userAvailabilities) {
  List<Event> events = [];
  //TOTO; do some calculations on availability to generate events
  return events;
}

/// Converges availabilities into a single list equal to the sume of all availabilities values
List<int> convergeAvailabilities(List<Availability> availabilities) {
  List<int> converge = List<int>.filled(Availability.ArrayLength, 0);
  for (Availability availability in availabilities) {
    for (int i = 0; i < Availability.ArrayLength; i++) {
      converge[i] += availability.weekAvailability[i];
    }
  }
  return converge;
}

List findNonZeroTimeSlots(List<int> convergedAvailability) {
  List<int> bestTimes = [];
  int bestTime = 0;
  int bestTimeLength = 0;
  int currentTime = 0;
  int currentTimeLength = 0;
  for (int i = 0; i < convergedAvailability.length; i++) {
    if (convergedAvailability[i] <= 0) {
      continue;
    }
  }
  bestTimes.add(bestTime);
  bestTimes.add(bestTime + bestTimeLength);
  return bestTimes;
}

///TODO: create a version of the function that prioritizes time slots with the most users available rather than the "best" availability