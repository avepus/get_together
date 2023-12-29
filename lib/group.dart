import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'user.dart';

class Group {
  String documentId;
  String? name;
  String? description;
  List<AppUser> members;
  List<AppUser> admins;
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

  String getdocumentIdLabel() {
    return 'Document ID';
  }

  String getNameLabel() {
    return 'Name';
  }

  String getDescriptionLabel() {
    return 'Description';
  }

  String getMembersLabel() {
    return 'Members';
  }

  String getAdminsLabel() {
    return 'Admins';
  }

  String getDaysBetweenMeetsLabel() {
    return 'Meeting Frequency';
  }

  String getDaysOfWeekLabel() {
    return 'Meeting Days';
  }

  String getCreatedTimeLabel() {
    return 'Created Time';
  }

  String getImageUrlLabel() {
    return 'Group Picture Link';
  }

  ListTile getTile() {
    return ListTile(
      leading: imageUrl != null
          ? Image.network(imageUrl!)
          : const Icon(Icons.image_not_supported),
      title: Text(name ?? '<no name>'),
    );
  }
}
