import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

String formatTimestamp(Timestamp timestamp) {
  // Convert the Timestamp to DateTime
  return myFormatDateTime(dateTime: timestamp.toDate(), includeTime: false);
}

//central function for formatting dateTimes so I can easily change format if needed
String myFormatDateTime({required DateTime dateTime, required bool includeTime}) {
  if (includeTime) {
    return DateFormat.yMMMd().add_jm().format(dateTime);
  }
  return DateFormat.yMMMd().format(dateTime);
}

///returns true if the passed in uid matches the uid of the logged in user
bool loggedInUidMatches(String uid) {
  if (FirebaseAuth.instance.currentUser == null) {
    return false;
  }
  if (FirebaseAuth.instance.currentUser!.uid != uid) {
    return false;
  }
  return true;
}

bool loggedInUidInArray(List<String> uids) {
  if (FirebaseAuth.instance.currentUser == null) {
    return false;
  }
  if (uids.contains(FirebaseAuth.instance.currentUser!.uid)) {
    return true;
  }
  return false;
}

List<int> rollList(List<int> input, int roll) {
  if (roll < 0) roll += input.length;
  return input.sublist(roll)..addAll(input.sublist(0, roll));
}
