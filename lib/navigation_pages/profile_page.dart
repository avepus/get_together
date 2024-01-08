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
import '../AppUser.dart';
import '../document_displayers.dart';
import '../widgets/ImageWithNullErrorHandling.dart';
import '../utils.dart';

class ProfilePage extends StatefulWidget {
  final String userDocumentId;
  const ProfilePage({Key? key, required this.userDocumentId}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _picker = ImagePicker();
  bool _isEditing = false;
  final _phoneNumberController = TextEditingController();
  final _phoneNumberInputFormatters = <TextInputFormatter>[
    FilteringTextInputFormatter.digitsOnly
  ];
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
            return Center(child: CircularProgressIndicator());
          } else if (futureAppUser.hasError) {
            return Text("Error: ${futureAppUser.error}");
          } else if (!futureAppUser.hasData || futureAppUser.data == null) {
            return Text("No data found");
          } else {
            AppUser user = futureAppUser.data!;
            return ListView(
              children: [
                Container(
                    width: 200,
                    height: 200,
                    child: ImageWithNullAndErrorHandling(user.imageUrl)),
                Card(
                  child: ListTile(
                      title: Text(AppUser.getdisplayNameLabel()),
                      subtitle: Text(user.displayName.toString())),
                ),
                Card(
                    child: ListTile(
                        title: Text(AppUser.getemailLabel()),
                        subtitle: Text(user.email.toString()))),
                Card(
                    child: ListTile(
                        title: Text(AppUser.getphoneNumberLabel()),
                        subtitle: Text(user.phoneNumber.toString()))),
                Card(
                    child: ListTile(
                        title: Text(AppUser.getcreatedTimeLabel()),
                        subtitle: Text(user.createdTime != null
                            ? formatTimestamp(user.createdTime!).toString()
                            : ''))),
                EditableFirestoreField(
                    collection: AppUser.collectionName,
                    fieldKey: AppUser.emailKey,
                    label: AppUser.getemailLabel(),
                    documentId: user.documentId,
                    currentValue: user.email,
                    hasSecurity: _loggedInUserMatches(user.documentId)),
                EditableFirestoreField(
                    collection: AppUser.collectionName,
                    fieldKey: AppUser.displayNameKey,
                    label: AppUser.getdisplayNameLabel(),
                    documentId: user.documentId,
                    currentValue: user.displayName,
                    hasSecurity: _loggedInUserMatches(user.documentId)),
                Stack(
                  children: <Widget>[
                    Card(
                      child: ListTile(
                        title: Text(AppUser.getcreatedTimeLabel()),
                        subtitle: _isEditing
                            ? TextField(
                                controller: _phoneNumberController,
                                inputFormatters: _phoneNumberInputFormatters,
                              )
                            : Text(user.phoneNumber.toString()),
                      ),
                    ),
                    Visibility(
                      visible: _loggedInUserMatches('user.documentId'),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _isEditing
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.check),
                                    onPressed: () {
                                      int phoneNumber = int.parse(
                                          _phoneNumberController.text);
                                      FirebaseFirestore.instance
                                          .collection(AppUser.collectionName)
                                          .doc(user.documentId)
                                          .update({
                                        AppUser.phoneNumberKey: phoneNumber
                                      });
                                      setState(() {
                                        _isEditing = false;
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close),
                                    onPressed: () {
                                      setState(() {
                                        _isEditing = false;
                                      });
                                    },
                                  ),
                                ],
                              )
                            : IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () {
                                  setState(() {
                                    _isEditing = true;
                                  });
                                },
                              ),
                      ),
                    ),
                  ],
                )
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

class EditableFirestoreField extends StatefulWidget {
  final String collection;
  final String fieldKey;
  final String label;
  final String documentId;
  final dynamic currentValue;
  final bool hasSecurity;
  final List<TextInputFormatter> formatters;
  final TextEditingController textController = TextEditingController();
  bool isEditing = false;

  EditableFirestoreField({
    required this.collection,
    required this.fieldKey,
    required this.label,
    required this.documentId,
    required this.currentValue,
    required this.hasSecurity,
    this.formatters = const <TextInputFormatter>[],
  });

  @override
  _EditableFirestoreFieldState createState() => _EditableFirestoreFieldState();
}

class _EditableFirestoreFieldState extends State<EditableFirestoreField> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Card(
          child: ListTile(
            title: Text(widget.label),
            subtitle: widget.isEditing
                ? TextField(controller: widget.textController)
                : Text(widget.currentValue.toString()),
          ),
        ),
        Visibility(
          visible: widget.hasSecurity, // replace with your own logic
          child: Align(
            alignment: Alignment.topRight,
            child: widget.isEditing
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check),
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection(widget.collection)
                              .doc(widget.documentId)
                              .update({
                            widget.fieldKey: widget.textController.text
                          });
                          setState(() {
                            widget.isEditing = false;
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            widget.isEditing = false;
                          });
                        },
                      ),
                    ],
                  )
                : IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      setState(() {
                        widget.isEditing = true;
                      });
                    },
                  ),
          ),
        ),
      ],
    );
  }

  bool _isCurrentUser(String userId) {
    // replace with your own logic to check if the current user is the logged-in user
    return true;
  }
}

bool _loggedInUserMatches(String uid) {
  if (FirebaseAuth.instance.currentUser == null) {
    return false;
  }
  if (FirebaseAuth.instance.currentUser!.uid != uid) {
    return false;
  }
  return true;
}
