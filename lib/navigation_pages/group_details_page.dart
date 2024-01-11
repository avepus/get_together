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
  late Future<Group> _groupSnapshot;

  @override
  void initState() {
    super.initState();
    _groupSnapshot = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupDocumentId)
        .get()
        .then((snapshot) => Group.fromDocumentSnapshot(
            snapshot)); //TODO: handle document not found
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GroupTitle(futureGroup: _groupSnapshot),
      ),
      body: FutureBuilder<Group>(
          future: _groupSnapshot,
          builder: (context, futureGroup) {
            if (futureGroup.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (futureGroup.hasError) {
              return Text("Error: ${futureGroup.error}");
            } else if (!futureGroup.hasData || futureGroup.data == null) {
              return const Text("No data found");
            } else {
              Group group = futureGroup.data!;
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
  final Future<Group> futureGroup;

  const GroupTitle({
    super.key,
    required this.futureGroup,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Group>(
        future: futureGroup,
        builder: (context, inFutureGroup) {
          if (inFutureGroup.connectionState == ConnectionState.waiting) {
            return const Text('');
          } else if (inFutureGroup.hasError) {
            return Text("Error: ${inFutureGroup.error}");
          } else {
            if (!inFutureGroup.hasData || inFutureGroup.data == null) {
              return const Text('No data');
            }
            return Text(inFutureGroup.data!.name ?? '<No Name>');
          }
        });
  }
}
