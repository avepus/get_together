import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

String formatTimestamp(Timestamp timestamp) {
  // Convert the Timestamp to DateTime
  DateTime date = timestamp.toDate();
  return DateFormat('yyyy-MM-dd – kk:mm').format(date);
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
