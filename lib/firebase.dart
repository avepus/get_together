import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_user.dart';

Future<void> createFirestoreUser(
    String displayName, String email, String uid) async {
  CollectionReference users = FirebaseFirestore.instance.collection('users');
  final timestamp = DateTime.now().millisecondsSinceEpoch;
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
