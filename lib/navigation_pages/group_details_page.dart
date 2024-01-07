import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:go_router/go_router.dart';

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
                  MembersList(futureMembers: members)
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

class MembersList extends StatelessWidget {
  final Future<List<AppUser>> futureMembers;

  const MembersList({
    Key? key,
    required this.futureMembers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AppUser>>(
        future: futureMembers,
        builder: (context, inFutureMembers) {
          if (inFutureMembers.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (inFutureMembers.hasError) {
            return Text("Error: ${inFutureMembers.error}");
          } else {
            if (!inFutureMembers.hasData || inFutureMembers.data == null) {
              return const Text('No data');
            }
            List<AppUser> members = inFutureMembers.data!;
            return SizedBox(
              height: min(200, 72.0 * members.length),
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  AppUser member = members[index];
                  return Card(
                    child: ListTile(
                      leading: ImageWithNullAndErrorHandling(member.imageUrl),
                      title: Text(member.displayName ?? '<No Name>'),
                      onTap: () {
                        context.pushNamed('profile', pathParameters: {
                          'userDocumentId': member.documentId,
                        });
                      },
                    ),
                  );
                },
              ),
            );
          }
        });
  }
}

Widget ImageWithNullAndErrorHandling(String? imageUrl) {
  return imageUrl != null
      ? Image.network(
          imageUrl,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.image_not_supported);
          },
        )
      : const Icon(Icons.account_circle);
}

String formatTimestamp(Timestamp timestamp) {
  // Convert the Timestamp to DateTime
  DateTime date = timestamp.toDate();
  return DateFormat('yyyy-MM-dd – kk:mm').format(date);
}
