import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_together/app_state.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../classes/app_user.dart';
import '../widgets/editable_firestore_field.dart';
import '../widgets/editable_document_image.dart';
import '../widgets/users_list_view.dart';
import '../utils.dart';
import '../classes/app_notification.dart';

class ProfilePage extends StatefulWidget {
  final String userDocumentId;
  const ProfilePage({super.key, required this.userDocumentId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _picker = ImagePicker();
  late Stream<DocumentSnapshot> _userSnapshot;
  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _userSnapshot = FirebaseFirestore.instance.collection('users').doc(widget.userDocumentId).snapshots();
  }

  void signOut(BuildContext context) async {
    await auth.signOut();
    if (context.mounted) {
      context.pushReplacement('/sign-in');
    }
  }

  //TODO: implement upload image as profile image
  Future<void> uploadImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 200, maxHeight: 200);

    if (pickedFile != null) {
      debugPrint(pickedFile.path);

      Reference ref = FirebaseStorage.instance.ref().child('user_images/${widget.userDocumentId}');

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

      await FirebaseFirestore.instance.collection('users').doc(widget.userDocumentId).update({AppUser.imageUrlKey: downloadUrl});
    }
  }

  @override
  Widget build(BuildContext context) {
    ApplicationState appState = Provider.of<ApplicationState>(context);
    return Scaffold(
        appBar: AppBar(
          title: AppUserTitle(userSnapshot: _userSnapshot),
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: _userSnapshot,
          builder: (context, appUserSnapshot) {
            if (appUserSnapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(width: 50, child: CircularProgressIndicator());
            } else if (appUserSnapshot.hasError) {
              return Text("Error: ${appUserSnapshot.error}");
            } else if (!appUserSnapshot.hasData || appUserSnapshot.data == null) {
              return const Text("No data found");
            } else {
              AppUser user = AppUser.fromDocumentSnapshot(appUserSnapshot.data!);
              bool isViewingOwnProfile = loggedInUidMatchesOld(user.documentId);
              bool isFriend = user.friends.contains(auth.currentUser!.uid);
              return ListView(
                children: [
                  Center(
                    child: SizedBox(
                        width: 200,
                        height: 200,
                        child: EditableImageField(
                            collectionName: AppUser.collectionName, documentId: user.documentId, fieldKey: AppUser.imageUrlKey, imageUrl: user.imageUrl, canEdit: isViewingOwnProfile)),
                  ),
                  EditableFirestoreField(
                      collection: AppUser.collectionName,
                      fieldKey: AppUser.displayNameKey,
                      label: AppUser.displayNameLabel,
                      documentId: user.documentId,
                      currentValue: user.displayName,
                      hasSecurity: isViewingOwnProfile,
                      //TODO: don't like hard-coded types here
                      dataType: String),
                  EditableFirestoreField(
                      collection: AppUser.collectionName,
                      fieldKey: AppUser.emailKey,
                      label: AppUser.emailLabel,
                      documentId: user.documentId,
                      currentValue: user.email,
                      hasSecurity: isViewingOwnProfile,
                      dataType: String),
                  EditableFirestoreField(
                      collection: AppUser.collectionName,
                      fieldKey: AppUser.phoneNumberKey,
                      label: AppUser.phoneNumberLabel,
                      documentId: user.documentId,
                      currentValue: user.phoneNumber,
                      hasSecurity: isViewingOwnProfile,
                      dataType: int),
                  //TODO: enforce uniqueness of uniqueUserID
                  EditableFirestoreField(
                      collection: AppUser.collectionName,
                      fieldKey: AppUser.uniqueUserIdKey,
                      label: AppUser.uniqueUserIdLabel,
                      documentId: user.documentId,
                      currentValue: user.uniqueUserId,
                      hasSecurity: isViewingOwnProfile,
                      dataType: String),
                  Card(child: ListTile(title: const Text(AppUser.createdTimeLabel), subtitle: Text(user.createdTime != null ? formatTimestamp(user.createdTime!).toString() : ''))),
                  Visibility(
                    visible: isViewingOwnProfile,
                    child: FindUsersButton(),
                  ),
                  Visibility(
                    visible: true, //testing by keeping this as ture. need to replace it with code to the right when done//!isViewingOwnProfile && !isFriend,
                    child: AddFriendButton(requestRecipient: user, requestorDocumentId: appState.loginUserDocumentId!),
                  ),
                ],
              );
            }
          },
        ),
        bottomNavigationBar: BottomAppBar(
          child: Visibility(
            visible: loggedInUidMatchesOld(widget.userDocumentId),
            child: ElevatedButton(
              child: Text('Sign Out'),
              onPressed: () => signOut(context),
            ),
          ),
        ));
  }
}

class AddFriendButton extends StatelessWidget {
  AppUser requestRecipient;
  String requestorDocumentId;

  AddFriendButton({
    required this.requestRecipient,
    required this.requestorDocumentId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (requestRecipient.friends.contains(requestorDocumentId)) {
      return ElevatedButton(
        onPressed: () {
          //left off here. Need to remove friend from both users' friends list
          //need to implement accepting of the friend request
          requestRecipient.friends.remove(requestorDocumentId);
        },
        child: const Text('Unfriend'),
      );
    }

    AppNotification? existingRequestNotification;

    for (var notification in requestRecipient.notifications) {
      AppNotification appNotification = AppNotification.fromNotificationArray(notification);
      if (appNotification.type == NotificationType.friendRequest && appNotification.routeToDocumentId == requestorDocumentId) {
        existingRequestNotification = appNotification;
        break;
      }
    }

    if (existingRequestNotification != null) {
      return ElevatedButton(
        onPressed: () {
          existingRequestNotification!.deleteFromDocument(documentId: requestRecipient.documentId, fieldKey: AppUser.notificationsKey, collection: AppUser.collectionName);
        },
        child: const Text('Cancel Friend Request'),
      );
    }

    return ElevatedButton(
      onPressed: () {
        AppNotification friendRequest = AppNotification(
          type: NotificationType.friendRequest,
          routeToDocumentId: requestorDocumentId,
          title: 'New Friend Request',
          description: '${requestRecipient.displayName} send you a Friend Request.',
          createdTime: Timestamp.now(),
        );

        friendRequest.saveToDocument(documentId: requestRecipient.documentId, fieldKey: AppUser.notificationsKey, collection: AppUser.collectionName);
      },
      child: const Text('Send Friend Request'),
    );
  }
}

class FindUsersButton extends StatefulWidget {
  FindUsersButton({super.key});

  @override
  _FindUsersButton createState() => _FindUsersButton();
}

class _FindUsersButton extends State<FindUsersButton> {
  List<AppUser> _users = <AppUser>[];
  final TextEditingController _userIdController = TextEditingController();

  Future<List<AppUser>> _fetchUsers(String userLookupValue) async {
    QuerySnapshot? querySnapshot;

    //if there's an @, attempt to look up via email field
    if (userLookupValue.contains('@')) {
      querySnapshot = await FirebaseFirestore.instance
          .collection(AppUser.collectionName) // Replace with your collection name
          .where(AppUser.emailKey, isEqualTo: userLookupValue) // Replace 'userId' with your field name
          .get();
    }

    //if the value is a number, attempt to look up via phone number field
    if (int.tryParse(userLookupValue) != null) {
      querySnapshot = await FirebaseFirestore.instance.collection(AppUser.collectionName).where(AppUser.phoneNumberKey, isEqualTo: int.parse(userLookupValue)).get();
    }

    //if we haven't found a user yet, attempt to look up via userId field
    if (querySnapshot == null || querySnapshot.docs.isEmpty) {
      querySnapshot = await FirebaseFirestore.instance.collection(AppUser.collectionName).where(AppUser.uniqueUserIdKey, isEqualTo: userLookupValue).get();
    }

    //not sure if this is necessary because the map below might just do this, but doesn't hurt to have it explicitly here
    if (querySnapshot.docs.isEmpty) {
      return <AppUser>[];
    }

    return querySnapshot.docs.map((doc) => AppUser.fromDocumentSnapshot(doc)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('User Lookup'),
              content: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
                return SizedBox(
                  height: 500,
                  width: 300,
                  child: Column(
                    children: [
                      TextField(
                          controller: _userIdController,
                          decoration: const InputDecoration(
                            labelText: 'User ID/Email/Phone Number',
                          ),
                          onEditingComplete: () async {
                            List<AppUser> newUsersList = await _fetchUsers(_userIdController.text);
                            setState(() => _users = newUsersList);
                          }),
                      ElevatedButton(
                        onPressed: () async {
                          List<AppUser> newUsersList = await _fetchUsers(_userIdController.text);
                          setState(() => _users = newUsersList);
                        },
                        child: const Text('Search'),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: _users.length,
                        itemBuilder: (BuildContext context, int index) {
                          return UsersListView(futureMembers: Future.value(_users));
                        },
                      )
                    ],
                  ),
                );
              }),
            );
          },
        );
      },
      child: const Text('Find Friend'),
    );
  }
}

class AppUserTitle extends StatelessWidget {
  final Stream<DocumentSnapshot> userSnapshot;

  const AppUserTitle({
    super.key,
    required this.userSnapshot,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
        stream: userSnapshot,
        builder: (context, inUserSnapshot) {
          if (inUserSnapshot.connectionState == ConnectionState.waiting) {
            return const Text('');
          } else if (inUserSnapshot.hasError) {
            return Text("Error: ${inUserSnapshot.error}");
          } else {
            if (!inUserSnapshot.hasData || inUserSnapshot.data == null) {
              return const Text('No data');
            }
            AppUser appUser = AppUser.fromDocumentSnapshot(inUserSnapshot.data!);
            return Text(appUser.displayName ?? '<No Name>');
          }
        });
  }
}
