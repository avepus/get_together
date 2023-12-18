import 'package:cloud_firestore/cloud_firestore.dart';

//holds all the fields stored in firestore for a user.
//label is what the page displays when the data is displayed and needs a label
enum UserFields {
  display_name(label: "Display Name"),
  email(label: "Email"),
  phone_number(label: "Phone Number"),
  created_time(label: "Created Time"),
  image_url(label: "Profile Picture Link");

  const UserFields({
    required this.label,
  });

  final String label;
}

enum GroupFields {
  name(label: "Name"),
  description(label: "Description"),
  members(label: "Members"),
  admins(label: "Admins"),
  days_between_meets(label: "Meeting Frequency"),
  days_of_week(label: "Meeting Days"),
  created_time(label: "Created Time"),
  image_url(label: "Group Picture Link");

  const GroupFields({
    required this.label,
  });

  final String label;
}

Future<void> createFirestoreUser(
    String displayName, String email, String uid) async {
  CollectionReference users = FirebaseFirestore.instance.collection('users');
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  var values = {
    UserFields.display_name.name: displayName,
    UserFields.email.name: email,
    UserFields.created_time.name: timestamp,
  };

  users.doc(uid).set(values);
  return;
}
