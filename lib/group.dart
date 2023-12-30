import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'user.dart';

class Group {
  static const String documentIdKey = 'documentId';
  static const String nameKey = 'name';
  static const String descriptionKey = 'description';
  static const String membersKey = 'members';
  static const String adminsKey = 'admins';
  static const String daysBetweenMeetsKey = 'daysBetweenMeets';
  static const String daysOfWeekKey = 'daysOfWeek';
  static const String createdTimeKey = 'createdTime';
  static const String imageUrlKey = 'imageUrl';

  String documentId;
  String? name;
  String? description;
  List<String> members;
  List<String> admins;
  int? daysBetweenMeets;
  List<int>? daysOfWeek;
  Timestamp? createdTime;
  String? imageUrl;

  Group({
    required this.documentId,
    this.name,
    this.description,
    this.members = const [],
    this.admins = const [],
    this.daysBetweenMeets,
    this.daysOfWeek,
    this.createdTime,
    this.imageUrl,
  });

  factory Group.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return Group(
      documentId: snapshot.id,
      name: data[nameKey],
      description: data[descriptionKey],
      members: data[membersKey].cast<String>(),
      admins: data[adminsKey].cast<String>(),
      daysBetweenMeets: data[daysBetweenMeetsKey],
      daysOfWeek: data[daysOfWeekKey].cast<int>(),
      createdTime: data[createdTimeKey],
      imageUrl: data[imageUrlKey],
    );
  }

  //returns a map which can be used to display the data in the display detail widget
  Map<String, dynamic> toDisplayableMap() {
    return {
      documentIdKey: documentId,
      nameKey: name,
      descriptionKey: description,
      membersKey: members,
      adminsKey: admins,
      daysBetweenMeetsKey: daysBetweenMeets,
      daysOfWeekKey: daysOfWeek,
      createdTimeKey: createdTime,
      imageUrlKey: imageUrl,
    };
  }

  static String getdocumentIdLabel() {
    return 'Document ID';
  }

  static String getNameLabel() {
    return 'Name';
  }

  static String getDescriptionLabel() {
    return 'Description';
  }

  static String getMembersLabel() {
    return 'Members';
  }

  static String getAdminsLabel() {
    return 'Admins';
  }

  static String getDaysBetweenMeetsLabel() {
    return 'Meeting Frequency';
  }

  static String getDaysOfWeekLabel() {
    return 'Meeting Days';
  }

  static String getCreatedTimeLabel() {
    return 'Created Time';
  }

  static String getImageUrlLabel() {
    return 'Group Picture Link';
  }
}
