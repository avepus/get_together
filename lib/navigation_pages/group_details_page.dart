import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase.dart';

class GroupDetailsPage extends StatelessWidget {
  final String groupDocumentId;
  const GroupDetailsPage({super.key, required this.groupDocumentId});

  Future<Map<String, dynamic>> getGroupDetails() async {
    DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupDocumentId)
        .get();

    var group = groupSnapshot.data() as Map<String, dynamic>;
    var members = group[GroupFields.members.name] as List<dynamic>;
    var admins = group[GroupFields.admins.name] as List<dynamic>;

    // Fetch user details for each member
    for (int i = 0; i < members.length; i++) {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(members[i])
          .get();

      // Replace the member ID with the user details
      members[i] = userSnapshot.data();
    }

    // Fetch user details for each admin
    for (int i = 0; i < admins.length; i++) {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(admins[i])
          .get();
      admins[i] = userSnapshot.data();
    }

    return group;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
          future: getGroupDetails(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text("Error: ${snapshot.error}");
            } else {
              if (!snapshot.hasData) {
                return const Text('No data');
              }

              var group = snapshot.data!;

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
