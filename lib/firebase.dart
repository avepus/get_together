import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> createFirestoreUser(String displayName, String uid) async {
  CollectionReference users = FirebaseFirestore.instance.collection('users');
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  var values = {
    'display_name': displayName,
    'uid': uid,
    'created_time': timestamp,
  };

  users.add(values);
  return;
}
