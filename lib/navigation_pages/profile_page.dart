import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';

import '../firebase.dart';
import '../app_user.dart';
import '../document_displayers.dart';
import '../widgets/image_with_null_error_handling.dart';
import '../widgets/editable_firestore_field.dart';
import '../utils.dart';

class ProfilePage extends StatefulWidget {
  final String userDocumentId;
  const ProfilePage({Key? key, required this.userDocumentId}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _picker = ImagePicker();
  final _phoneNumberController = TextEditingController();
  late Future<AppUser> _userSnapshot;

  @override
  void initState() {
    super.initState();
    _userSnapshot = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userDocumentId)
        .get()
        .then((snapshot) => AppUser.fromDocumentSnapshot(snapshot));
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    super.dispose();
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
        title: AppUserTitle(futureUser: _userSnapshot),
      ),
      body: FutureBuilder<AppUser>(
        future: _userSnapshot,
        builder: (context, futureAppUser) {
          if (futureAppUser.connectionState == ConnectionState.waiting) {
            return const SizedBox(
                width: 50, child: CircularProgressIndicator());
          } else if (futureAppUser.hasError) {
            return Text("Error: ${futureAppUser.error}");
          } else if (!futureAppUser.hasData || futureAppUser.data == null) {
            return const Text("No data found");
          } else {
            AppUser user = futureAppUser.data!;
            bool hasEditSecurity = loggedInUidMatches(user.documentId);
            return ListView(
              children: [
                SizedBox(
                    width: 200,
                    height: 200,
                    child: ImageWithNullAndErrorHandling(user.imageUrl)),
                EditableFirestoreField(
                    collection: AppUser.collectionName,
                    fieldKey: AppUser.emailKey,
                    label: AppUser.displayNameLabel,
                    documentId: user.documentId,
                    currentValue: user.displayName,
                    hasSecurity: hasEditSecurity,
                    //TODO: don't like hard-coded types here
                    dataType: String),
                EditableFirestoreField(
                    collection: AppUser.collectionName,
                    fieldKey: AppUser.emailKey,
                    label: AppUser.emailLabel,
                    documentId: user.documentId,
                    currentValue: user.email,
                    hasSecurity: hasEditSecurity,
                    dataType: String),
                EditableFirestoreField(
                    collection: AppUser.collectionName,
                    fieldKey: AppUser.phoneNumberKey,
                    label: AppUser.phoneNumberLabel,
                    documentId: user.documentId,
                    currentValue: user.phoneNumber,
                    hasSecurity: hasEditSecurity,
                    dataType: int),
                Card(
                    child: ListTile(
                        title: const Text(AppUser.createdTimeLabel),
                        subtitle: Text(user.createdTime != null
                            ? formatTimestamp(user.createdTime!).toString()
                            : ''))),
              ],
            );
          }
        },
      ),
    );
  }
}

class AppUserTitle extends StatelessWidget {
  final Future<AppUser> futureUser;

  const AppUserTitle({
    Key? key,
    required this.futureUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser>(
        future: futureUser,
        builder: (context, inFutureUser) {
          if (inFutureUser.connectionState == ConnectionState.waiting) {
            return Text('');
          } else if (inFutureUser.hasError) {
            return Text("Error: ${inFutureUser.error}");
          } else {
            if (!inFutureUser.hasData || inFutureUser.data == null) {
              return const Text('No data');
            }
            return Text(inFutureUser.data!.displayName ?? '<No Name>');
          }
        });
  }
}
