import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/users_list_view.dart';
import '../group.dart';
import '../app_user.dart';
import '../utils.dart';
import '../widgets/editable_firestore_field.dart';

class GroupDetailsPage extends StatefulWidget {
  final String groupDocumentId;
  const GroupDetailsPage({super.key, required this.groupDocumentId});

  @override
  _GroupPageState createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupDetailsPage> {
  late Stream<DocumentSnapshot> _groupSnapshot;

  @override
  void initState() {
    super.initState();
    _groupSnapshot = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupDocumentId)
        .snapshots();
  }

  //TODO: implement upload image as group image

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GroupTitle(groupSnapshot: _groupSnapshot),
      ),
      body: StreamBuilder<DocumentSnapshot>(
          stream: _groupSnapshot,
          builder: (context, groupSnapshot) {
            if (groupSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (groupSnapshot.hasError) {
              return Text("Error: ${groupSnapshot.error}");
            } else if (!groupSnapshot.hasData || groupSnapshot.data == null) {
              return const Text("No data found");
            } else {
              Group group = Group.fromDocumentSnapshot(groupSnapshot.data!);
              Future<List<AppUser>> members = group.fetchMemberUsers();
              Future<List<AppUser>> admins = group.fetchAdminUsers();
              return ListView(
                children: [
                  SizedBox(
                      width: 200,
                      height: 200,
                      child: group.imageUrl != null
                          ? Image.network(group.imageUrl!)
                          : const Icon(Icons.image_not_supported)),
                  EditableFirestoreField(
                      collection: Group.collectionName,
                      fieldKey: Group.nameKey,
                      label: Group.nameLabel,
                      documentId: group.documentId,
                      currentValue: group.name,
                      hasSecurity: loggedInUidInArray(group.admins),
                      dataType: String),
                  EditableFirestoreField(
                      collection: Group.collectionName,
                      fieldKey: Group.descriptionKey,
                      label: Group.descriptionLabel,
                      documentId: group.documentId,
                      currentValue: group.description,
                      hasSecurity: loggedInUidInArray(group.admins),
                      dataType: String),
                  EditableFirestoreField(
                      collection: Group.collectionName,
                      fieldKey: Group.daysBetweenMeetsKey,
                      label: Group.daysBetweenMeetsLabel,
                      documentId: group.documentId,
                      currentValue: group.daysBetweenMeets,
                      hasSecurity: loggedInUidInArray(group.admins),
                      dataType: String),
                  //TODO: implement dyasofweek in an editable way
                  Card(
                      child: ListTile(
                          title: const Text(Group.daysOfWeekLabel),
                          subtitle: Text(group.daysOfWeek.toString()))),
                  Card(
                      child: ListTile(
                          title: const Text(Group.createdTimeLabel),
                          subtitle: Text(group.createdTime != null
                              ? formatTimestamp(group.createdTime!).toString()
                              : ''))),
                  Card(
                      child: ListTile(
                          title: const Text(Group.membersLabel),
                          subtitle: UsersListView(futureMembers: members))),
                  Card(
                      child: ListTile(
                          title: const Text(Group.adminsLabel),
                          subtitle: UsersListView(futureMembers: admins))),
                ],
              );
            }
          }),
    );
  }
}

class GroupTitle extends StatelessWidget {
  final Stream<DocumentSnapshot> groupSnapshot;

  const GroupTitle({
    super.key,
    required this.groupSnapshot,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
        stream: groupSnapshot,
        builder: (context, inGroupSnapshot) {
          if (inGroupSnapshot.connectionState == ConnectionState.waiting) {
            return const Text('');
          } else if (inGroupSnapshot.hasError) {
            return Text("Error: ${inGroupSnapshot.error}");
          } else {
            if (!inGroupSnapshot.hasData || inGroupSnapshot.data == null) {
              return const Text('No data');
            }
            Group group = Group.fromDocumentSnapshot(inGroupSnapshot.data!);
            return Text(group.name ?? '<No Name>');
          }
        });
  }
}
