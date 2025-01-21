import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils.dart';

enum AttendanceResponse { unconfirmedYes, unconfirmedMaybe, unconfirmedNo, confirmedYes, confirmedMaybe, confirmedNo }

//this represents a group's meeting/event
class Event {
  static const String collectionName = 'events';
  static const String documentIdKey = 'documentId';
  static const String titleKey = 'title';
  static const String descriptionKey = 'description';
  static const String locationKey = 'location';
  static const String startTimeKey = 'startTime';
  static const String endTimeKey = 'endTime';
  static const String groupDocumentIdKey = 'groupDocumentId';
  static const String isCancelledKey = 'isCancelled';
  static const String createdTimeKey = 'createdTime';
  static const String creatorDocumentIdKey = 'creatorDocumentId';
  static const String attendanceResponsesKey = 'attendanceResponses';

  static const String documentIdLabel = 'Document ID';
  static const String titleLabel = 'Title';
  static const String descriptionLabel = 'Description';
  static const String locationLabel = 'Location';
  static const String startTimeLabel = 'Start Time';
  static const String endTimeLabel = 'End Time';
  static const String groupDocumentIdLabel = 'Group Document ID';
  static const String isCancelledLabel = 'Cancelled?';
  static const String attendanceResponsesLabel = 'Responses';

  static const String createdTimeLabel = 'Created Time';
  static const String creatorDocumentIdLabel = 'Creator Document ID';

  //documentId = null implies that this is not stored in firebase yet
  String? documentId;
  String title;
  String description;
  String location;
  DateTime startTime; //UTC
  DateTime endTime; //UTC
  final String groupDocumentId;
  final bool isCancelled;
  DateTime createdTime;
  final String creatorDocumentId;
  Map<String, AttendanceResponse> attendanceResponses;

  Event(
      {this.documentId,
      required this.title,
      required this.description,
      required this.location,
      required this.startTime,
      required this.endTime,
      required this.groupDocumentId,
      this.isCancelled = false,
      required this.createdTime,
      required this.creatorDocumentId,
      required this.attendanceResponses});

  static Event fromDocumentSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Event(
      documentId: doc.id,
      title: data[titleKey],
      description: data[descriptionKey],
      location: data[locationKey],
      startTime: (data[startTimeKey] as Timestamp).toDate(),
      endTime: (data[endTimeKey] as Timestamp).toDate(),
      groupDocumentId: data[groupDocumentIdKey],
      isCancelled: data[isCancelledKey] ?? false,
      createdTime: (data[createdTimeKey] as Timestamp).toDate(),
      creatorDocumentId: data[creatorDocumentIdKey],
      attendanceResponses:
          (data[attendanceResponsesKey] as Map<String, dynamic>).map((key, value) => MapEntry(key, AttendanceResponse.values.firstWhere((e) => e.toString().split('.').last == value))),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      //purposefully excluding the document ID since that's not a field it's the literal ID
      titleKey: title,
      descriptionKey: description,
      locationKey: location,
      startTimeKey: Timestamp.fromDate(startTime),
      endTimeKey: Timestamp.fromDate(endTime),
      groupDocumentIdKey: groupDocumentId,
      isCancelledKey: isCancelled,
      createdTimeKey: Timestamp.fromDate(createdTime),
      creatorDocumentIdKey: creatorDocumentId,
      attendanceResponsesKey: attendanceResponses.map((key, value) => MapEntry(key, value.toString().split('.').last)),
    };
  }

  Future<void> saveToFirestore() async {
    if (documentId != null) {
      await FirebaseFirestore.instance.collection(collectionName).doc(documentId).set(toMap());
    } else {
      Map<String, dynamic> map = toMap();
      DocumentReference ref = await FirebaseFirestore.instance.collection(collectionName).add(map);
      documentId = ref.id;
    }
  }

  ///formats the start and end time based on the users current timezone
  ///will show the date of the endTime if on a different day
  String formatMeetingStartAndEnd() {
    DateTime localStart = startTime.toLocal();
    DateTime localEnd = endTime.toLocal();
    if (localStart.day == localEnd.day) {
      return '${myFormatDateAndTime(localStart)} - ${myFormatTime(localEnd)}';
    } else {
      return '${myFormatDateAndTime(localStart)} - ${myFormatDateAndTime(localEnd)}';
    }
  }
}
