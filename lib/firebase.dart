import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_user.dart';

import 'group.dart';

Future<List<AppUser>> fetchAllUsers() async {
  CollectionReference users = FirebaseFirestore.instance.collection('users');
  QuerySnapshot querySnapshot = await users.get();
  List<AppUser> userList = [];

  for (var doc in querySnapshot.docs) {
    AppUser user = AppUser.fromDocumentSnapshot(doc);
    userList.add(user);
  }

  return userList;
}

//takes in a list of user documentIds and stores them in the specified group field
Future<void> storeUserIdsListInGroup(List<String> userDocumentIds,
    String groupDocumentId, String fieldKey) async {
  CollectionReference groups =
      FirebaseFirestore.instance.collection(Group.collectionName);

  Map<String, dynamic> data = {
    fieldKey: userDocumentIds,
  };

  await groups.doc(groupDocumentId).update(data);
}

//helper function that takes in list of AppUsers and stores their documentIds in a group
Future<void> storeUserListInGroup(
    List<AppUser> users, String groupDocumentId, String fieldKey) async {
  List<String> userDocumentIds = users.map((user) => user.documentId).toList();
  await storeUserIdsListInGroup(userDocumentIds, groupDocumentId, fieldKey);
}

Future<void> createFirestoreUser(
    String displayName, String email, String uid) async {
  CollectionReference users = FirebaseFirestore.instance.collection('users');
  final timestamp = DateTime.now();
  var values = {
    AppUser.displayNameKey: displayName,
    AppUser.emailKey: email,
    AppUser.createdTimeKey: timestamp,
  };

  users.doc(uid).set(values);
  return;
}

Future<void> deleteFirestoreGroup(String groupDocumentId) async {
  CollectionReference groups = FirebaseFirestore.instance.collection('groups');
  groups.doc(groupDocumentId).delete();
  return;
}
