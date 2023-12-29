import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Represents a user in the application.
///
/// Called AppUser because User is already a class in Dart.
/// The documentId is the same as the user's ID in Firebase Auth.
/// The profile image imageUrl is also the same as the user's ID in Firebase Auth.
class AppUser {
  String documentId;
  String? displayName;
  String? email;
  String? phoneNumber;
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
      displayName: data[getdisplayNameKey()],
      email: data[getemailKey()],
      phoneNumber: data[getphoneNumberKey()],
      createdTime: data[getcreatedTimeKey()],
      imageUrl: data[getimageUrlKey()],
    );
  }

  //returns map in which keys match the field names in firestore and values are the values
  //not convied that I need this actually
  Map<String, dynamic> toMap() {
    return {
      getdocumentIdKey(): documentId,
      getdisplayNameKey(): displayName,
      getemailKey(): email,
      getphoneNumberKey(): phoneNumber,
      getcreatedTimeKey(): createdTime,
      getimageUrlKey(): imageUrl,
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

  static String getdocumentIdKey() {
    return 'documentId';
  }

  static String getdisplayNameKey() {
    return 'displayName';
  }

  static String getemailKey() {
    return 'email';
  }

  static String getphoneNumberKey() {
    return 'phoneNumber';
  }

  static String getcreatedTimeKey() {
    return 'createdTime';
  }

  static String getimageUrlKey() {
    return 'imageUrl';
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

  Widget displayEditable() {
    final displayNameController = TextEditingController(text: displayName);
    final emailController = TextEditingController(text: email);
    final phoneNumberController = TextEditingController(text: phoneNumber);
    final imageUrlController = TextEditingController(text: imageUrl);

    return Column(
      children: [
        imageUrl != null ? Image.network(imageUrl!) : Container(),
        TextField(controller: displayNameController),
        TextField(controller: emailController),
        TextField(controller: phoneNumberController),
        TextField(controller: imageUrlController),
        ElevatedButton(
          onPressed: () {
            // Update Firestore document with new values
            displayName = displayNameController.text;
            email = emailController.text;
            phoneNumber = phoneNumberController.text;
            imageUrl = imageUrlController.text;
            // Save changes to Firestore
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}

List<AppUser> getUsersFromDocumentIDs(List<String> documentIDs) {
  List<AppUser> users = [];
  documentIDs.forEach((documentID) async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(documentID)
        .get();
    if (snapshot.exists) {
      users.add(AppUser.fromDocumentSnapshot(snapshot));
    }
  });
  return users;
}
