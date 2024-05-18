import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

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
  static const String createdTimeKey = 'createdTime';
  static const String creatorDocumentIdKey = 'creatorDocumentId';

  static const String documentIdLabel = 'Document ID';
  static const String titleLabel = 'Title';
  static const String descriptionLabel = 'Description';
  static const String locationLabel = 'Location';
  static const String startTimeLabel = 'Start Time';
  static const String endTimeLabel = 'End Time';
  static const String groupDocumentIdLabel = 'Group Document ID';
  static const String createdTimeLabel = 'Created Time';
  static const String creatorDocumentIdLabel = 'Creator Document ID';

  //documentId = '' implies that this is not stored in firebase yet. This is not great. Need to figure out a good way to handle this
  String documentId;
  final String title;
  final String description;
  final String location;
  final DateTime startTime;
  final DateTime endTime;
  final String groupDocumentId;
  final DateTime createdTime;
  final String creatorDocumentId;

  Event(
      {required this.documentId,
      required this.title,
      required this.description,
      required this.location,
      required this.startTime,
      required this.endTime,
      required this.groupDocumentId,
      required this.createdTime,
      required this.creatorDocumentId});

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
      createdTime: (data[createdTimeKey] as Timestamp).toDate(),
      creatorDocumentId: data[creatorDocumentIdKey],
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
      createdTimeKey: Timestamp.fromDate(createdTime),
      creatorDocumentIdKey: creatorDocumentId,
    };
  }

  void saveToFirestore() async {
    if (documentId != '') {
      await FirebaseFirestore.instance.collection(collectionName).doc(documentId).set(toMap());
    } else {
      DocumentReference ref = await FirebaseFirestore.instance.collection(collectionName).add(toMap());
      documentId = ref.id;
    }
  }

  void deleteFromFirestore() {
    if (documentId != '') {
      FirebaseFirestore.instance.collection(collectionName).doc(documentId).delete();
    }
  }
}
