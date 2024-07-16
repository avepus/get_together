import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_together/classes/availability.dart';
import 'app_user.dart';

class Group {
  static const String collectionName = 'groups';
  static const String documentIdKey = 'documentId';
  static const String nameKey = 'name';
  static const String descriptionKey = 'description';
  static const String membersKey = 'members';
  static const String adminsKey = 'admins';
  static const String daysBetweenMeetsKey = 'daysBetweenMeets';
  static const String meetingDurationKey = 'meetingDuration';
  static const String daysOfWeekKey = 'daysOfWeek';
  static const String createdTimeKey = 'createdTime';
  static const String imageUrlKey = 'imageUrl';
  static const String availabilityKey = 'availability';
  static const String memberTimezonesKey = 'memberTimezones';

  static const String documentIdLabel = 'Document ID';
  static const String nameLabel = 'Name';
  static const String descriptionLabel = 'Description';
  static const String membersLabel = 'Members';
  static const String adminsLabel = 'Admins';
  static const String daysBetweenMeetsLabel = 'Meeting Frequency';
  static const String meetingDurationLabel = 'Meeting Duration (hours)';
  static const String daysOfWeekLabel = 'Meeting Days';
  static const String createdTimeLabel = 'Created Time';
  static const String imageUrlLabel = 'Group Picture Link';
  static const String availabilityLabel = 'Availability';
  static const String memberTimezonesLabel = 'Timezones';

  static const double defaultMeetingDuration = 2; //unit is hours

  String documentId;
  String? name;
  String? description;
  List<String> members;
  List<String> admins;
  int? daysBetweenMeets;
  double? meetingDuration;

  List<int>? daysOfWeek;
  Timestamp? createdTime;
  String? imageUrl;
  Map<String, List<int>>? memberAvailability;
  Map<String, String>? memberTimezones;

  Group({
    required this.documentId,
    //TODO: make name required
    this.name,
    this.description,
    this.members = const <String>[],
    this.admins = const <String>[],
    this.daysBetweenMeets,
    this.meetingDuration,
    this.daysOfWeek = const <int>[],
    this.createdTime,
    this.imageUrl,
    this.memberAvailability,
    this.memberTimezones,
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
        meetingDuration: data[meetingDurationKey],
        daysOfWeek: data[daysOfWeekKey] == null || data[daysOfWeekKey].isEmpty ? null : data[daysOfWeekKey].cast<int>(),
        createdTime: data[createdTimeKey],
        imageUrl: data[imageUrlKey],
        memberAvailability: _convertAvailabilityFromFirestore(data[availabilityKey]),
        memberTimezones: _convertTimezonesFromFirestore(data[memberTimezonesKey]));
  }

  static Map<String, List<int>>? _convertAvailabilityFromFirestore(Map<String, dynamic>? availability) {
    if (availability == null) {
      return null;
    }
    return availability.map((key, value) => MapEntry(key, List<int>.from((value as List<dynamic>).cast<int>())));
  }

  static Map<String, String>? _convertTimezonesFromFirestore(Map<String, dynamic>? timezones) {
    if (timezones == null) {
      return null;
    }
    return timezones.map((key, value) => MapEntry(key, value as String));
  }

  String? getTimeZone(String uid) {
    if (memberTimezones == null || memberTimezones![uid] == null) {
      return null;
    }
    return memberTimezones![uid]!;
  }

  //TODO: this should return null if there is no availability
  Availability? getAvailability(String uid) {
    String? timeZone = getTimeZone(uid);
    if (memberAvailability == null || memberAvailability![uid] == null || timeZone == null) {
      return null;
    }
    return Availability(weekAvailability: memberAvailability![uid]!, timeZoneName: timeZone);
  }

  ///this gives me a the follwoing error when used
  ///Navigator.onGenerateRoute was null, but the route named "group" was referenced.
  ///TODO; fix this and replace the getTile method in groups_page.dart
  ListTile getTile(BuildContext context) {
    return ListTile(
        leading: imageUrl != null ? Image.network(imageUrl!) : const Icon(Icons.broken_image_outlined),
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

  /// Fetches the users from Firestore using the provided user IDs
  /// removes the user ID from the input field in Firestore if the user does not exist to handle cases in which the user is deleted
  /// returns a list of users
  Future<List<AppUser>> _fetchUsers(List<String> userIds, String fieldKey) async {
    List<AppUser> users = [];

    for (var userId in userIds) {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (snapshot.exists) {
        AppUser user = AppUser.fromDocumentSnapshot(snapshot);
        users.add(user);
      } else {
        // Remove the document ID from the members field in Firestore
        await FirebaseFirestore.instance.collection('groups').doc(documentId).update({
          fieldKey: FieldValue.arrayRemove([userId])
        });
      }
    }
    return users;
  }

  ///Gets the default meeting duration in hours and handles null values
  double get meetingDurationHours {
    return meetingDuration == null ? defaultMeetingDuration : meetingDuration!;
  }

  int get meetingDurationMinutes {
    return (meetingDurationHours * 60).toInt();
  }

  ///Gets the default meeting duration in half hours and handles null values
  int get meetingDurationTimeSlots {
    return meetingDurationHours.toInt() * 2;
  }

  ///returns a map of the members' availabilities where the key is the documentID and the value is the availability
  Map<String, Availability> getGroupMemberAvailabilities() {
    Map<String, Availability> memberAvailabilities = {};
    for (String member in members) {
      Availability? availability = getAvailability(member);
      if (availability != null) {
        memberAvailabilities[member] = availability;
      }
    }
    return memberAvailabilities;
  }
}
