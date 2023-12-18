import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupEditPage extends StatelessWidget {
  String groupDocumentId;
  GroupEditPage({super.key, required this.groupDocumentId});

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
              var group = snapshot.data!.docs[index];
              var admins = group['admins'] as List<dynamic>;
              var daysOfWeek = group['days_of_week'] as List<dynamic>;

              return ListTile(
                title: Text(group['name']),
                subtitle: Text(group['description']),
                trailing: Column(
                  children: [
                    const Text('Admins:'),
                    for (var adminId in admins)
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(adminId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          }
                          if (!snapshot.hasData) {
                            return const Text('User Not Found');
                          }
                          var user = snapshot.data!.data() as Map;
                          return Text(user['display_name'] ?? 'No name');
                        },
                      ),
                    Text('Days of Week: $daysOfWeek'),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
