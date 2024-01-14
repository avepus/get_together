import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../group.dart';
import '../widgets/image_with_null_error_handling.dart';

class GroupsPage extends StatelessWidget {
  GroupsPage({super.key});

  final uid = FirebaseAuth.instance.currentUser!.uid;

  //TODO: Next step is to add floating action button to create new group
  void _showAddGroupDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter new group name'),
          content: TextField(
            controller: controller,
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () => context.pop(),
            ),
            IconButton(
              icon: Icon(Icons.check),
              onPressed: () => _addGroup(context, controller.text),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addGroup(BuildContext context, String groupName) async {
    DocumentReference groupRef =
        await FirebaseFirestore.instance.collection(Group.collectionName).add({
      Group.nameKey: groupName,
      Group.createdTimeKey: Timestamp.fromDate(DateTime.now()),
      Group.adminsKey: [uid],
      Group.membersKey: [uid],
      // add other fields as needed
      //testing to make this not break
    });

    if (context.mounted) {
      context.pop(); // close the dialog
      context.pushNamed('group', pathParameters: {
        'groupDocumentId': groupRef.id,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGroupDialog(context),
        child: Icon(Icons.add),
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
            return const CircularProgressIndicator();
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
              //I tried to extract this as group method to return the ListTile, but I couldn't get the navigfation to work
              return ListTile(
                  leading:
                      ImageWithNullAndErrorHandling(imageUrl: group.imageUrl),
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
