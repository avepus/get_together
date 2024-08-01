import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user in the application.
///
/// Called AppUser because User is already a class in Dart.
/// The documentId is the same as the user's ID in Firebase Auth.
/// The profile image imageUrl is also the same as the user's ID in Firebase Auth.
class AppUser {
  static const String collectionName = 'users';
  static const String documentIdKey = 'documentId';
  static const String uniqueUserIdKey = 'uniqueUserId';
  static const String displayNameKey = 'displayName';
  static const String emailKey = 'email';
  static const String phoneNumberKey = 'phoneNumber';
  static const String createdTimeKey = 'createdTime';
  static const String imageUrlKey = 'imageUrl';
  static const String notificationsKey = 'notifications';
  static const String friendsKey = 'friends';

  static const String documentIdLabel = 'Document ID';
  static const String uniqueUserIdLabel = 'ID';
  static const String displayNameLabel = 'Display Name';
  static const String emailLabel = 'Email';
  static const String phoneNumberLabel = 'Phone Number';
  static const String createdTimeLabel = 'Created Time';
  static const String imageUrlLabel = 'Profile Picture Link';
  static const String notificationsLabel = 'Notifications';
  static const String friendsLabel = 'Friends';

  String documentId;
  String uniqueUserId;
  String? displayName;
  String? email;
  int? phoneNumber;
  Timestamp? createdTime;
  String? imageUrl;
  List<Map<String, dynamic>> notifications;
  List<String> friends;

  AppUser({
    required this.documentId,
    required this.uniqueUserId, //left off here. Need to add to all users and need to update all places users are created to send in documentID as default
    this.displayName,
    this.email,
    this.phoneNumber,
    this.createdTime,
    this.imageUrl,
    this.notifications = const [],
    this.friends = const [],
  });

  factory AppUser.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    // Assuming 'notificationsKey' is the field name in your Firestore document
    var notificationsFromFirestore = data[notificationsKey];

    List<Map<String, dynamic>> notifications = [];
    assert(notificationsFromFirestore == null || notificationsFromFirestore is List,
        'Expected a list in User field \'$notificationsKey\' but found this ${notificationsFromFirestore.runtimeType}: $notificationsFromFirestore');

    if (notificationsFromFirestore is List) {
      notifications = notificationsFromFirestore.map((item) {
        if (item is Map) {
          // Explicitly convert the item to Map<String, dynamic>
          return Map<String, dynamic>.from(item);
        } else {
          // Handle the case where the item is not a Map, perhaps log an error or throw
          assert(false, 'Expected the list in User field \'$notificationsKey\' to hold maps, but found this ${item.runtimeType}: $item');
          throw TypeError();
        }
      }).toList();
    }

    assert(data[friendsKey] != null && data[friendsKey]!! is List, 'Expected a list in User field \'$friendsKey\' but found this ${data[friendsKey].runtimeType}: ${data[friendsKey]}');

    return AppUser(
      documentId: snapshot.id,
      uniqueUserId: data[uniqueUserIdKey],
      displayName: data[displayNameKey],
      email: data[emailKey],
      phoneNumber: data[phoneNumberKey],
      createdTime: data[createdTimeKey],
      imageUrl: data[imageUrlKey],
      notifications: notifications,
      friends: List<String>.from(data[friendsKey] ?? []),
    );
  }

  //returns map in which keys match the field names in firestore and values are the values
  //not convied that I need this actually
  Map<String, dynamic> toMap() {
    return {
      //Dcoument ID is not included because it is the not a field in the firestore document
      //documentIdKey: documentId,
      uniqueUserIdKey: uniqueUserId,
      displayNameKey: displayName,
      emailKey: email,
      phoneNumberKey: phoneNumber,
      createdTimeKey: createdTime,
      imageUrlKey: imageUrl,
      notificationsKey: notifications,
      friendsKey: friends,
    };
  }

  @override
  String toString() {
    return toMap().toString();
  }
}
