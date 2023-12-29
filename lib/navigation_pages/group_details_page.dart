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
        .collection('users')
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
              if (!snapshot.hasData) {
                return const Text('No data');
              }

              var group = Group.fromDocumentSnapshot(snapshot.data!);
              List<AppUser> members = getUsersFromDocumentIDs(group.members);
              List<AppUser> admins = getUsersFromDocumentIDs(group.admins);

              return getDocumentDetailsWidget(
                  group.toDisplayableMap(), Group.getImageUrlKey());

              return ListView(children: [
                group[GroupFields.image_url.name] != null
                    ? Image.network(group[GroupFields.image_url.name])
                    : Icon(Icons.broken_image_outlined),
                ListTile(
                  title: Text(GroupFields.name.label),
                  subtitle: Text(group[GroupFields.name.name]),
                ),
                ListTile(
                  title: Text(GroupFields.description.label),
                  subtitle: Text(group[GroupFields.description.name]),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: group[GroupFields.members.name].length,
                  itemBuilder: (context, index) {
                    var member = group[GroupFields.members.name][index];
                    return ListTile(
                      //leading: member[UserFields.image_url.name] != null
                      //    ? Image.network(member[UserFields.image_url.name])
                      //    : Icon(Icons.broken_image_outlined),
                      title: Text(member != null
                          ? member[UserFields.display_name.name] ?? '<No name>'
                          : 'Member not found'),
                    );
                  },
                )
              ]);
            }
          }),
    );
  }
}
