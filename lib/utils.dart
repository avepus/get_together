import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

String formatTimestamp(Timestamp timestamp) {
  // Convert the Timestamp to DateTime
  DateTime date = timestamp.toDate();
  return DateFormat('yyyy-MM-dd – kk:mm').format(date);
}
