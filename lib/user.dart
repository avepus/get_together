import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Represents a user in the application.
///
/// Called AppUser because User is already a class in Dart.
/// The documentId is the same as the user's ID in Firebase Auth.
/// The profile image imageUrl is also the same as the user's ID in Firebase Auth.
class AppUser {
  static const String documentIdKey = 'documentId';
  static const String displayNameKey = 'displayName';
  static const String emailKey = 'email';
  static const String phoneNumberKey = 'phoneNumber';
  static const String createdTimeKey = 'createdTime';
  static const String imageUrlKey = 'imageUrl';

  String documentId;
  String? displayName;
  String? email;
  int? phoneNumber;
  Timestamp? createdTime;
  String? imageUrl;

  AppUser({
    required this.documentId,
    this.displayName,
    this.email,
    this.phoneNumber,
    this.createdTime,
    this.imageUrl,
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
    };
  }

  //returns a map which can be used to display the data in the display detail widget
  Map<String, dynamic> toDisplayableMap() {
    return {
      getdocumentIdLabel(): documentId,
      getdisplayNameLabel(): displayName,
      getemailLabel(): email,
      getphoneNumberLabel(): phoneNumber,
      getcreatedTimeLabel(): createdTime,
      getimageUrlLabel(): imageUrl,
    };
  }

  static String getdocumentIdLabel() {
    return 'Document ID';
  }

  static String getdisplayNameLabel() {
    return 'Display Name';
  }

  static String getemailLabel() {
    return 'Email';
  }

  static String getphoneNumberLabel() {
    return 'Phone Number';
  }

  static String getcreatedTimeLabel() {
    return 'Created Time';
  }

  static String getimageUrlLabel() {
    return 'Profile Picture Link';
  }

  @override
  String toString() {
    return toMap().toString();
  }
}

Future<List<AppUser>> getUsersFromDocumentIDs(List<String> documentIDs) async {
  List<Future<AppUser>> futures = [];
  for (var documentID in documentIDs) {
    futures.add(FirebaseFirestore.instance
        .collection('users')
        .doc(documentID)
        .get()
        .then((snapshot) {
      if (snapshot.exists) {
        return AppUser.fromDocumentSnapshot(snapshot);
      } else {
        throw Exception('Document does not exist');
      }
    }));
  }
  return await Future.wait(futures);
}
