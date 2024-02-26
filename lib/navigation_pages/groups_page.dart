import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../group.dart';
import '../widgets/image_with_null_error_handling.dart';

class GroupsPage extends StatelessWidget {
  GroupsPage({super.key});

  final uid = FirebaseAuth.instance.currentUser!.uid;

  void _showAddGroupDialog(BuildContext context) {
    var myFocusNode = FocusNode();
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        Future.delayed(Duration(milliseconds: 100), () {
          //not sure why I need to check mounted here it was throwing Error: Looking up a deactivated widget's ancestor is unsafe.
          if (context.mounted) {
            FocusScope.of(context).requestFocus(myFocusNode);
          }
        });
        return AlertDialog(
          title: const Text('Enter new group name'),
          content: TextField(
            controller: controller,
            focusNode: myFocusNode,
            textInputAction: TextInputAction.done,
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                context.pop();
                _addGroup(context, controller.text);
              }
            },
          ),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => context.pop(),
            ),
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                context.pop();
                _addGroup(context, controller.text);
              },
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
    });

    if (context.mounted) {
      context.pushNamed('group', pathParameters: {
        'groupDocumentId': groupRef.id,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading:
            false, //prevent back button from displaying, shouldn't be necessary but this is all I could figure out for now
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

          return ListView.separated(
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (context, index) => Divider(height: 10),
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
