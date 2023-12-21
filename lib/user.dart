import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
      displayName: data['displayName'],
      email: data['email'],
      phoneNumber: data['phoneNumber'],
      createdTime: data['createdTime'],
      imageUrl: data['imageUrl'],
    );
  }

  //returns map in which keys match the field names in firestore and values are the values
  //not convied that I need this actually
  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'displayName': displayName,
      'email': email,
      'phoneNumber': phoneNumber,
      'createdTime': createdTime,
      'imageUrl': imageUrl,
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

  String getdocumentIdLabel() {
    return 'Document ID';
  }

  String getdisplayNameLabel() {
    return 'Display Name';
  }

  String getemailLabel() {
    return 'Email';
  }

  String getphoneNumberLabel() {
    return 'Phone Number';
  }

  String getcreatedTimeLabel() {
    return 'Created Time';
  }

  String getimageUrlLabel() {
    return 'Profile Picture Link';
  }

  @override
  String toString() {
    return toMap().toString();
  }

  ListTile getTile() {
    return ListTile(
      leading: imageUrl != null
          ? Image.network(imageUrl!)
          : const Icon(Icons.image_not_supported),
      title: Text(displayName ?? '<no name>'),
    );
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

Widget getDocumentDetailsWidget(Map<String, dynamic> map, String? imageKey) {
  //remove the image url from the map
  //TODO: make it displayed at the top
  map.remove(imageKey);
  return Expanded(
    child: ListView.builder(
      itemCount: map.length,
      itemBuilder: (context, index) {
        var key = map.keys.elementAt(index);
        dynamic value = map[key];
        if (value is Timestamp) {
          // Convert the Timestamp to DateTime
          DateTime date = value.toDate();

          // Format the DateTime as a string
          value = DateFormat('yyyy-MM-dd – kk:mm').format(date);
        }
        return Card(
          child: ListTile(title: Text(key), subtitle: Text(value ?? '')),
        );
      },
    ),
  );
}
