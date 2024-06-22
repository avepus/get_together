import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user in the application.
///
/// Called AppUser because User is already a class in Dart.
/// The documentId is the same as the user's ID in Firebase Auth.
/// The profile image imageUrl is also the same as the user's ID in Firebase Auth.
class AppUser {
  static const String collectionName = 'users';
  static const String documentIdKey = 'documentId';
  static const String displayNameKey = 'displayName';
  static const String emailKey = 'email';
  static const String phoneNumberKey = 'phoneNumber';
  static const String createdTimeKey = 'createdTime';
  static const String imageUrlKey = 'imageUrl';
  static const String notificationsKey = 'notifications';

  static const String documentIdLabel = 'Document ID';
  static const String displayNameLabel = 'Display Name';
  static const String emailLabel = 'Email';
  static const String phoneNumberLabel = 'Phone Number';
  static const String createdTimeLabel = 'Created Time';
  static const String imageUrlLabel = 'Profile Picture Link';

  String documentId;
  String? displayName;
  String? email;
  int? phoneNumber;
  Timestamp? createdTime;
  String? imageUrl;
  List<Map<String, dynamic>>? notifications;

  AppUser({
    required this.documentId,
    this.displayName,
    this.email,
    this.phoneNumber,
    this.createdTime,
    this.imageUrl,
    this.notifications,
  });

  factory AppUser.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return AppUser(
      documentId: snapshot.id,
      displayName: data[displayNameKey],
      email: data[emailKey],
      phoneNumber: data[phoneNumberKey],
      createdTime: data[createdTimeKey],
      imageUrl: data[imageUrlKey],
      notifications: data[notificationsKey],
    );
  }

  //returns map in which keys match the field names in firestore and values are the values
  //not convied that I need this actually
  Map<String, dynamic> toMap() {
    return {
      documentIdKey: documentId,
      displayNameKey: displayName,
      emailKey: email,
      phoneNumberKey: phoneNumber,
      createdTimeKey: createdTime,
      imageUrlKey: imageUrl,
      notificationsKey: notifications,
    };
  }

  @override
  String toString() {
    return toMap().toString();
  }
}
