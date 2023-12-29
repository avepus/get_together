import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase.dart';
import '../group.dart';
import '../user.dart';
import '../document_displayers.dart';

class GroupDetailsPage extends StatefulWidget {
  final String groupDocumentId;
  const GroupDetailsPage({super.key, required this.groupDocumentId});

  @override
  _GroupPageState createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupDetailsPage> {
  late Future<DocumentSnapshot> _groupSnapshot;

  @override
  void initState() {
    super.initState();
    _groupSnapshot = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupDocumentId)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
          future: _groupSnapshot,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text("Error: ${snapshot.error}");
            } else {
              if (!snapshot.hasData ||
                  snapshot.data == null ||
                  !snapshot.data!.exists) {
                return const Text('No data');
              }

              var group = Group.fromDocumentSnapshot(snapshot.data!);
              List<AppUser> members =
                  getUsersFromDocumentIDs(group.members as List<String>);
              List<AppUser> admins = getUsersFromDocumentIDs(group.admins);

              return getDocumentDetailsWidget(
                  group.toDisplayableMap(), Group.getImageUrlKey());
            }
          }),
    );
  }
}
