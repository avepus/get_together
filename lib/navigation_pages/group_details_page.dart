import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/users_list_view.dart';
import '../classes/group.dart';
import '../classes/app_user.dart';
import '../utils.dart';
import '../widgets/editable_firestore_field.dart';
import '../widgets/editable_document_image.dart';
import '../firebase.dart';
import '../widgets/update_availability.dart';
import '../classes/availability.dart';
import '../findTime.dart';

class GroupDetailsPage extends StatefulWidget {
  final String groupDocumentId;
  const GroupDetailsPage({super.key, required this.groupDocumentId});

  @override
  _GroupDetailsPageState createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  late Stream<DocumentSnapshot> _groupSnapshot;

  @override
  void initState() {
    super.initState();
    _groupSnapshot = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupDocumentId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GroupTitle(groupSnapshot: _groupSnapshot),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
                stream: _groupSnapshot,
                builder: (context, groupSnapshot) {
                  if (groupSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (groupSnapshot.hasError) {
                    return Text("Error: ${groupSnapshot.error}");
                  } else if (!groupSnapshot.hasData ||
                      groupSnapshot.data == null) {
                    return const Text("No data found");
                  } else {
                    Group group =
                        Group.fromDocumentSnapshot(groupSnapshot.data!);
                    Future<List<AppUser>> members = group.fetchMemberUsers();
                    Future<List<AppUser>> admins = group.fetchAdminUsers();
                    return ListView(
                      children: [
                        Center(
                          child: SizedBox(
                            width: 200,
                            height: 200,
                            child: EditableImageField(
                                collectionName: Group.collectionName,
                                documentId: group.documentId,
                                fieldKey: Group.imageUrlKey,
                                imageUrl: group.imageUrl,
                                canEdit: loggedInUidInArray(group.admins)),
                          ),
                        ),
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
                            dataType: int),
                        EditableFirestoreField(
                            collection: Group.collectionName,
                            fieldKey: Group.meetingDurationKey,
                            label: Group.meetingDurationLabel,
                            documentId: group.documentId,
                            currentValue: group.meetingDuration,
                            hasSecurity: loggedInUidInArray(group.admins),
                            dataType: double),
                        AvailabilityButton(
                          groupDocumentId: widget.groupDocumentId,
                          availability: group.getAvailability(
                              FirebaseAuth.instance.currentUser!.uid),
                        ),
                        //TODO: implement daysofweek in an editable way
                        Card(
                            child: ListTile(
                                title: const Text(Group.daysOfWeekLabel),
                                subtitle: Text(group.daysOfWeek == null
                                    ? ''
                                    : group.daysOfWeek.toString()))),
                        Card(
                            child: ListTile(
                                title: const Text(Group.createdTimeLabel),
                                subtitle: Text(group.createdTime != null
                                    ? formatTimestamp(group.createdTime!)
                                        .toString()
                                    : ''))),
                        Card(
                            child: ListTile(
                                title: const Text(Group.membersLabel),
                                subtitle:
                                    UsersListView(futureMembers: members))),
                        Visibility(
                          visible: loggedInUidInArray(group.admins),
                          child: SizedBox(
                            width: 50,
                            child: Align(
                                alignment: Alignment.centerLeft,
                                child: AddUsersButton(
                                    label: 'Add Member',
                                    groupDocumentId: group.documentId,
                                    members: group.members,
                                    fieldKey: Group.membersKey,
                                    users: fetchAllUsers())),
                          ),
                        ),
                        Card(
                            child: ListTile(
                                title: const Text(Group.adminsLabel),
                                subtitle:
                                    UsersListView(futureMembers: admins))),
                        Visibility(
                          visible: loggedInUidInArray(group.admins),
                          child: SizedBox(
                            width: 50,
                            child: Align(
                                alignment: Alignment.centerLeft,
                                child: AddUsersButton(
                                    label: 'Add Admin',
                                    groupDocumentId: group.documentId,
                                    members: group.admins,
                                    fieldKey: Group.adminsKey,
                                    users: members)),
                          ),
                        ),
                        //TODO: make magic numbers below into configuragble values
                        GenerateEventButten(
                            group: group,
                            timeSlotDuration: group.meetingDurationTimeSlots,
                            numberOfSlotsToReturn: 3),
                        //TODO: next need to look at this. Suggest times is giving different resutls tan the new event page suggestions
                        ElevatedButton(
                            onPressed: () {
                              context.goNamed('newevent',
                                  extra: {'group': group, 'timeSlot': null});
                            },
                            child: Text('Create Event')),
                        Visibility(
                          visible: loggedInUidInArray(group.admins),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: SizedBox(
                              width: 50,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                //TODO: style delete button to be red
                                child: ElevatedButton(
                                  child: const Text('Delete Group'),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Confirm Delete'),
                                          content: const Text(
                                              'Are you sure you want to delete this group?'),
                                          actions: <Widget>[
                                            TextButton(
                                              child: const Text('Cancel'),
                                              onPressed: () {
                                                context.pop();
                                              },
                                            ),
                                            TextButton(
                                              child: const Text('Delete'),
                                              onPressed: () {
                                                deleteFirestoreGroup(
                                                    widget.groupDocumentId);
                                                context.pop();
                                                context.replace('/');
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                }),
          ),
        ],
      ),
    );
  }
}

class GenerateEventButten extends StatelessWidget {
  final Group group;
  final int timeSlotDuration;
  final int numberOfSlotsToReturn;

  const GenerateEventButten({
    required this.group,
    required this.timeSlotDuration,
    required this.numberOfSlotsToReturn,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: const Text('Suggest Times'),
      onPressed: () {
        Map<String, Availability> memberAvailabilities = {};
        for (String member in group.members) {
          Availability? availability = group.getAvailability(member);
          if (availability != null) {
            memberAvailabilities[member] = availability;
          }
        }
        //TODO: may want to pass in a future DateTime to findTimeSlots to have more accurrate availability calcuations based on the week that it will be planned rather than now
        Map<int, int> timeSlotsAndScores = findTimeSlots(
            memberAvailabilities, timeSlotDuration, numberOfSlotsToReturn);
        List<int> timeSlots = timeSlotsAndScores.keys.toList();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Best Times'),
              content: SizedBox(
                  height: 200,
                  width: 300,
                  child: ListView.builder(
                    itemCount:
                        timeSlots.length + 1, // Add one for the header row
                    itemBuilder: (BuildContext context, int index) {
                      if (index == 0) {
                        // This is the header row
                        return ListTile(
                          title: Table(
                            columnWidths: const {
                              0: FractionColumnWidth(0.2),
                              1: FractionColumnWidth(0.6),
                              2: FractionColumnWidth(0.2),
                            },
                            children: const [
                              TableRow(
                                children: [
                                  Text('Rank'),
                                  Text('Start Time'),
                                  Text('Score'),
                                ],
                              ),
                            ],
                          ),
                        );
                      } else {
                        // This is a data row
                        String timeSlotName = Availability.getTimeslotName(
                            timeSlots[index - 1], context);
                        return ListTile(
                          title: Table(
                            columnWidths: const {
                              0: FractionColumnWidth(0.2),
                              1: FractionColumnWidth(0.6),
                              2: FractionColumnWidth(0.2),
                            },
                            children: [
                              TableRow(
                                children: [
                                  Text('$index'),
                                  Text(timeSlotName),
                                  Text(
                                      '${timeSlotsAndScores[timeSlots[index - 1]]}'),
                                ],
                              ),
                            ],
                          ),
                          onTap: () {
                            context.goNamed('newevent', extra: {
                              'group': group,
                              'timeSlot': timeSlots[index - 1]
                            });
                          },
                        );
                      }
                    },
                  )),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    context.pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

///TODO: add a little X to the alert window when adding a user
class AddUsersButton extends StatelessWidget {
  final String label;
  final String groupDocumentId;
  final List<String> members;
  final String fieldKey;
  final Future<List<AppUser>> users;

  const AddUsersButton({
    required this.label,
    required this.groupDocumentId,
    required this.members,
    required this.fieldKey,
    required this.users,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: Text(label),
      onPressed: () async {
        List<AppUser> users = await this.users;

        if (context.mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Select a User'),
                content: Container(
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (BuildContext context, int index) {
                      return ListTile(
                        title: Text(users[index].displayName ??
                            'no name'), // Display the user's name
                        onTap: () {
                          if (members.contains(users[index].documentId)) {
                            context.pop();
                            return;
                          }
                          members.add(users[index].documentId);
                          storeUserIdsListInGroup(
                              members, groupDocumentId, fieldKey);
                          context.pop();
                        },
                      );
                    },
                  ),
                ),
              );
            },
          );
        }
      },
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
