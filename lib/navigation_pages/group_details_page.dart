import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../widgets/UsersListView.dart';
import '../firebase.dart';
import '../Group.dart';
import '../AppUser.dart';
import '../document_displayers.dart';

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
              return Center(child: CircularProgressIndicator());
            } else if (futureGroup.hasError) {
              return Text("Error: ${futureGroup.error}");
            } else {
              if (!futureGroup.hasData || futureGroup.data == null) {
                return const Text('No data');
              }
              Group group = futureGroup.data!;
              Future<List<AppUser>> members = group.fetchMemberUsers();
              Future<List<AppUser>> admins = group.fetchAdminUsers();
              return ListView(
                children: [
                  Container(
                      width: 200,
                      height: 200,
                      child: group.imageUrl != null
                          ? Image.network(group.imageUrl!)
                          : const Icon(Icons.image_not_supported)),
                  Card(
                    child: ListTile(
                        title: Text(Group.getDescriptionLabel()),
                        subtitle: Text(group.description.toString())),
                  ),
                  Card(
                      child: ListTile(
                          title: Text(Group.getDaysBetweenMeetsLabel()),
                          subtitle: Text(group.daysBetweenMeets.toString()))),
                  Card(
                      child: ListTile(
                          title: Text(Group.getDaysOfWeekLabel()),
                          subtitle: Text(group.daysOfWeek.toString()))),
                  Card(
                      child: ListTile(
                          title: Text(Group.getCreatedTimeLabel()),
                          subtitle: Text(group.createdTime != null
                              ? formatTimestamp(group.createdTime!).toString()
                              : ''))),
                  Card(
                      child: ListTile(
                          title: Text("Members"),
                          subtitle: UsersListView(futureMembers: members))),
                  Card(
                      child: ListTile(
                          title: Text("Admins"),
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
    Key? key,
    required this.futureGroup,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Group>(
        future: futureGroup,
        builder: (context, inFutureGroup) {
          if (inFutureGroup.connectionState == ConnectionState.waiting) {
            return Text('');
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

String formatTimestamp(Timestamp timestamp) {
  // Convert the Timestamp to DateTime
  DateTime date = timestamp.toDate();
  return DateFormat('yyyy-MM-dd – kk:mm').format(date);
}
