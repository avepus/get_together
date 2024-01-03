import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../firebase.dart';
import '../user.dart';
import '../document_displayers.dart';

class ProfilePage extends StatefulWidget {
  final String userDocumentId;
  const ProfilePage({Key? key, required this.userDocumentId}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _picker = ImagePicker();
  late Future<DocumentSnapshot> _userSnapshot;

  @override
  void initState() {
    super.initState();
    _userSnapshot = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userDocumentId)
        .get();
  }

  Future<void> uploadImage() async {
    final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery, maxWidth: 200, maxHeight: 200);

    if (pickedFile != null) {
      debugPrint(pickedFile.path);

      Reference ref = await FirebaseStorage.instance
          .ref()
          .child('user_images/${widget.userDocumentId}');

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'picked-file-path': pickedFile.path},
      );

      if (kIsWeb) {
        await ref.putData(await pickedFile.readAsBytes(), metadata);
      } else {
        await ref.putFile(File(pickedFile.path), metadata);
      }

      var downloadUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userDocumentId)
          .update({UserFields.image_url.name: downloadUrl});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _userSnapshot,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text("Error: ${snapshot.error}");
          } else if (!snapshot.hasData) {
            return Text("No data found");
          } else {
            AppUser user = AppUser.fromDocumentSnapshot(snapshot.data!);
            var userDocument = snapshot.data!.data() as Map;
            return getDocumentDetailsWidget(
                user.toDisplayableMap(), AppUser.getimageUrlLabel());
          }
        },
      ),
    );
  }
}
