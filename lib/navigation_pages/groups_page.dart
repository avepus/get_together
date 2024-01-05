import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../firebase.dart';
import '../group.dart';
import '../user.dart';

class GroupsPage extends StatelessWidget {
  GroupsPage({super.key});

  final uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .where('members', arrayContains: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }

          if (!snapshot.hasData) {
            return const Text('No data');
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var group =
                  Group.fromDocumentSnapshot(snapshot.data!.docs[index]);
              //this code relies on knowing the group structure. would be better if it didn't
              return ListTile(
                  leading: group.imageUrl != null
                      ? Image.network(group.imageUrl!)
                      : Icon(Icons.broken_image_outlined),
                  title: Text(group.name ?? '<No Name>'),
                  subtitle: group.description != null
                      ? Text(group.description!)
                      : null,
                  onTap: () {
                    context.pushNamed('group', pathParameters: {
                      'groupDocumentId': group.documentId,
                    });
                  });
            },
          );
        },
      ),
    );
  }
}
