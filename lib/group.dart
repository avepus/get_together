import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'app_user.dart';

import 'abstracts.dart';

class Group implements Tile {
  static const String collectionName = 'groups';
  static const String documentIdKey = 'documentId';
  static const String nameKey = 'name';
  static const String descriptionKey = 'description';
  static const String membersKey = 'members';
  static const String adminsKey = 'admins';
  static const String daysBetweenMeetsKey = 'daysBetweenMeets';
  static const String daysOfWeekKey = 'daysOfWeek';
  static const String createdTimeKey = 'createdTime';
  static const String imageUrlKey = 'imageUrl';

  static const String documentIdLabel = 'Document ID';
  static const String nameLabel = 'Name';
  static const String descriptionLabel = 'Description';
  static const String membersLabel = 'Members';
  static const String adminsLabel = 'Admins';
  static const String daysBetweenMeetsLabel = 'Meeting Frequency';
  static const String daysOfWeekLabel = 'Meeting Days';
  static const String createdTimeLabel = 'Created Time';
  static const String imageUrlLabel = 'Group Picture Link';

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
      documentIdLabel: documentId,
      nameLabel: name,
      descriptionLabel: description,
      membersLabel: members,
      adminsLabel: admins,
      daysBetweenMeetsLabel: daysBetweenMeets,
      daysOfWeekLabel: daysOfWeek,
      createdTimeLabel: createdTime,
      imageUrlLabel: imageUrl,
    };
  }

  ///this gives me a the follwoing error when used
  ///Navigator.onGenerateRoute was null, but the route named "group" was referenced.
  ///TODO; fix this and replace the getTile method in groups_page.dart
  @override
  ListTile getTile(BuildContext context) {
    return ListTile(
        leading: imageUrl != null
            ? Image.network(imageUrl!)
            : Icon(Icons.broken_image_outlined),
        title: Text(name ?? '<No Name>'),
        subtitle: description != null ? Text(description!) : null,
        onTap: () {
          Navigator.of(context).pushNamed('group', arguments: {
            'groupDocumentId': documentId,
          });
        });
  }

  Future<List<AppUser>> fetchMemberUsers() async {
    return _fetchUsers(members, membersKey);
  }

  Future<List<AppUser>> fetchAdminUsers() async {
    return _fetchUsers(admins, adminsKey);
  }

  /// Fetches the users from Firestore using the provided user IDs.
  /// removes the user ID from the input field in Firestore if the user does not exist
  /// returns a list of users
  Future<List<AppUser>> _fetchUsers(List userIds, String fieldKey) async {
    List<AppUser> users = [];

    for (var userId in userIds) {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (snapshot.exists) {
        AppUser user = AppUser.fromDocumentSnapshot(snapshot);
        users.add(user);
      } else {
        // Remove the document ID from the members field in Firestore
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(documentId)
            .update({
          fieldKey: FieldValue.arrayRemove([userId])
        });
      }
    }
    return users;
  }
}
