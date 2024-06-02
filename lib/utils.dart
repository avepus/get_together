import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_state.dart';

String formatTimestamp(Timestamp timestamp) {
  // Convert the Timestamp to DateTime
  return myFormatDate(timestamp.toDate());
}

//central function for formatting dateTimes so I can easily change format if needed
String myFormatDateAndTime(DateTime dateTime) {
  return DateFormat.yMMMd().add_jm().format(dateTime);
}

String myFormatDate(DateTime dateTime) {
  return DateFormat.yMMMd().format(dateTime);
}

String myFormatTime(DateTime dateTime) {
  return DateFormat.jm().format(dateTime);
}

///returns true if the passed in uid matches the uid of the logged in user
bool loggedInUidMatchesOld(String uid) {
  if (FirebaseAuth.instance.currentUser == null) {
    return false;
  }
  if (FirebaseAuth.instance.currentUser!.uid != uid) {
    return false;
  }
  return true;
}

bool loggedInUidMatches(String uid, ApplicationState appState) {
  return appState.loginUserDocumentId == uid;
}

bool loggedInUidInArrayOld(List<String> uids) {
  if (FirebaseAuth.instance.currentUser == null) {
    return false;
  }
  if (uids.contains(FirebaseAuth.instance.currentUser!.uid)) {
    return true;
  }
  return false;
}

bool loggedInUidInArray(List<String> uids, ApplicationState appState) {
  if (appState.loginUserDocumentId == '') {
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
