import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'user.dart';

class Group {
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
      name: data[getNameKey()],
      description: data[getDescriptionKey()],
      members: data[getMembersKey()],
      admins: data[getAdminsKey()],
      daysBetweenMeets: data[getDaysBetweenMeetsKey()],
      daysOfWeek: data[getDaysOfWeekKey()],
      createdTime: data[getCreatedTimeKey()],
      imageUrl: data[getImageUrlKey()],
    );
  }

  //returns a map which can be used to display the data in the display detail widget
  Map<String, dynamic> toDisplayableMap() {
    return {
      getdocumentIdLabel(): documentId,
      getNameLabel(): name,
      getDescriptionLabel(): description,
      getMembersLabel(): members,
      getAdminsLabel(): admins,
      getDaysBetweenMeetsLabel(): daysBetweenMeets,
      getDaysOfWeekLabel(): daysOfWeek,
      getCreatedTimeLabel(): createdTime,
      getImageUrlLabel(): imageUrl,
    };
  }

  static String getNameKey() {
    return 'name';
  }

  static String getDescriptionKey() {
    return 'description';
  }

  static String getMembersKey() {
    return 'members';
  }

  static String getAdminsKey() {
    return 'admins';
  }

  static String getDaysBetweenMeetsKey() {
    return 'daysBetweenMeets';
  }

  static String getDaysOfWeekKey() {
    return 'daysOfWeek';
  }

  static String getCreatedTimeKey() {
    return 'createdTime';
  }

  static String getImageUrlKey() {
    return 'imageUrl';
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
