import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

//this represents a group's meeting/event
class Event {
  static const String collectionName = 'events';
  static const String titleKey = 'title';
  static const String descriptionKey = 'description';
  static const String locationKey = 'location';
  static const String startTimeKey = 'startTime';
  static const String endTimeKey = 'endTime';
  static const String groupDocumentIdKey = 'groupDocumentId';
  static const String createdTimeKey = 'createdTime';
  static const String creatorDocumentIdKey = 'creatorDocumentId';

  final String title;
  final String description;
  final String location;
  final DateTime startTime;
  final DateTime endTime;
  final String groupDocumentId;
  final DateTime createdTime;
  final String creatorDocumentId;

  Event(
      {required this.title,
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

  void saveToFirestore() {
    FirebaseFirestore.instance.collection(collectionName).add(toMap());
  }
}
