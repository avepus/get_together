DateTime getBeginningOfWeekUTC(DateTime dateTime) {
  DateTime utcDateTime = dateTime.toUtc();
  DateTime sundayMidnight =
      utcDateTime.subtract(Duration(days: utcDateTime.weekday % 7));
  return DateTime.utc(
      sundayMidnight.year, sundayMidnight.month, sundayMidnight.day);
}

Duration maxDuration(Duration a, Duration b) {
  return a.compareTo(b) >= 0 ? a : b;
}

DateTime getNextDateTime(DateTime anchorDateTime, Duration timeSlotAsDuration,
    [Duration buffer = const Duration()]) {
  //there must be a minimum buffer of 1 day to prevent timezone issues grabbing the wrong day
  Duration safeBuffer = maxDuration(buffer, const Duration(days: 1));

  DateTime bufferedAnchor = anchorDateTime.toUtc().add(safeBuffer);
  DateTime midnightSunday = getBeginningOfWeekUTC(bufferedAnchor);
  DateTime nextDateTime = midnightSunday.add(timeSlotAsDuration);
  if (bufferedAnchor.isBefore(nextDateTime)) {
    //this handles the case where daylight savings occurred beteen sunday and nextDateTime
    Duration difference = midnightSunday.toLocal().timeZoneOffset -
        nextDateTime.toLocal().timeZoneOffset;
    return nextDateTime.add(difference);
  }

  DateTime rebufferedAnchor = bufferedAnchor.add(const Duration(days: 7));
  midnightSunday = getBeginningOfWeekUTC(rebufferedAnchor);
  nextDateTime = midnightSunday.add(timeSlotAsDuration);
  if (bufferedAnchor.isBefore(nextDateTime)) {
    Duration difference = midnightSunday.toLocal().timeZoneOffset -
        nextDateTime.toLocal().timeZoneOffset;
    return nextDateTime.add(difference);
  }
  throw Exception(
      'getNextDateTime failed to find a valid time. This should not happen.');
}
