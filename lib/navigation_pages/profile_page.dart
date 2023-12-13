import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../app_state.dart';

class ProfilePage extends StatefulWidget {
  ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final _picker = ImagePicker();

  Stream<DocumentSnapshot> getUserDetails() {
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  Future<void> uploadImage() async {
    final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery, maxWidth: 200, maxHeight: 200);

    if (pickedFile != null) {
      debugPrint(pickedFile.path);

      UploadTask uploadTask;

      Reference ref =
          await FirebaseStorage.instance.ref().child('user_images/$uid');

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'picked-file-path': pickedFile.path},
      );

      if (kIsWeb) {
        uploadTask = ref.putData(await pickedFile.readAsBytes(), metadata);
      } else {
        uploadTask = ref.putFile(File(pickedFile.path), metadata);
      }

      var downloadUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'image_url': downloadUrl});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: getUserDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text("Error: ${snapshot.error}");
          } else if (!snapshot.hasData) {
            return Text("No data found");
          } else {
            var userDocument = snapshot.data!.data() as Map;
            return ListView(
              children: <Widget>[
                InkWell(
                  onTap: uploadImage,
                  splashColor: Colors.white10,
                  child: userDocument['image_url'] != null
                      ? CircleAvatar(
                          backgroundImage:
                              NetworkImage((userDocument['image_url'])),
                          radius: 50)
                      : Icon(Icons.add_a_photo),
                ),
                ListTile(
                    title: Text('Display Name'),
                    subtitle: Text(userDocument['display_name'])),
                ListTile(
                    title: Text('Email'),
                    subtitle:
                        Text(userDocument['email'] ?? 'No email provided')),
                ListTile(
                    title: Text('Phone Number'),
                    subtitle: Text(userDocument['phone_number'] ??
                        'No phone number provided')),
                ListTile(
                    title: Text('Created Time'),
                    subtitle: Text(userDocument['created_time'].toString())),
                ListTile(
                  title: ElevatedButton(
                      child: Text('Sign Out'),
                      onPressed: () {
                        FirebaseAuth.instance.signOut();
                        context.pushReplacement('/sign-in');
                      }),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
