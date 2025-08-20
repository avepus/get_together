import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_together/classes/event_proposal.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../widgets/users_list_view.dart';
import '../classes/group.dart';
import '../classes/app_user.dart';
import '../classes/event.dart';
import '../utils.dart';
import '../widgets/editable_firestore_field.dart';
import '../widgets/editable_document_image.dart';
import '../firebase.dart';
import '../widgets/update_availability.dart';
import '../update_event.dart';
import '../findTime.dart';
import '../update_event.dart';
import '../classes/availability.dart';
import '../time_utils.dart';

class GroupDetailsPage extends StatefulWidget {
  final String groupDocumentId;
  const GroupDetailsPage({super.key, required this.groupDocumentId});

  @override
  _GroupDetailsPageState createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  late Stream<DocumentSnapshot> _groupSnapshot;
  late ApplicationState appState;

  @override
  void initState() {
    super.initState();
    _groupSnapshot = FirebaseFirestore.instance.collection('groups').doc(widget.groupDocumentId).snapshots();
    appState = Provider.of<ApplicationState>(context, listen: false);
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
                        Center(
                          child: SizedBox(
                            width: 200,
                            height: 200,
                            child: EditableImageField(
                                collectionName: Group.collectionName,
                                documentId: group.documentId,
                                fieldKey: Group.imageUrlKey,
                                imageUrl: group.imageUrl,
                                canEdit: loggedInUidInArrayOld(group.admins)),
                          ),
                        ),
                        EditableFirestoreField(
                            collection: Group.collectionName,
                            fieldKey: Group.nameKey,
                            label: Group.nameLabel,
                            documentId: group.documentId,
                            currentValue: group.name,
                            hasSecurity: loggedInUidInArrayOld(group.admins),
                            dataType: String),
                        EditableFirestoreField(
                            collection: Group.collectionName,
                            fieldKey: Group.descriptionKey,
                            label: Group.descriptionLabel,
                            documentId: group.documentId,
                            currentValue: group.description,
                            hasSecurity: loggedInUidInArrayOld(group.admins),
                            dataType: String),
                        EditableFirestoreField(
                            collection: Group.collectionName,
                            fieldKey: Group.daysBetweenMeetsKey,
                            label: Group.daysBetweenMeetsLabel,
                            documentId: group.documentId,
                            currentValue: group.daysBetweenMeets,
                            hasSecurity: loggedInUidInArrayOld(group.admins),
                            dataType: int),
                        EditableFirestoreField(
                            collection: Group.collectionName,
                            fieldKey: Group.meetingDurationKey,
                            label: Group.meetingDurationLabel,
                            documentId: group.documentId,
                            currentValue: group.meetingDuration,
                            hasSecurity: loggedInUidInArrayOld(group.admins),
                            dataType: double),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: AvailabilityButton(
                            groupDocumentId: widget.groupDocumentId,
                            availability: group.getAvailability(FirebaseAuth.instance.currentUser!.uid),
                          ),
                        ),
                        //TODO: implement daysofweek in an editable way
                        Card(child: ListTile(title: const Text(Group.daysOfWeekLabel), subtitle: Text(group.daysOfWeek == null ? '' : group.daysOfWeek.toString()))),
                        Card(child: ListTile(title: const Text(Group.createdTimeLabel), subtitle: Text(group.createdTime != null ? formatTimestampAsDate(group.createdTime!).toString() : ''))),
                        Card(child: ListTile(title: const Text(Group.membersLabel), subtitle: UsersListView(futureMembers: members))),
                        Visibility(
                          visible: loggedInUidInArrayOld(group.admins),
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: AddUsersButton(label: 'Add Member', groupDocumentId: group.documentId, members: group.members, fieldKey: Group.membersKey, users: fetchAllUsers())),
                        ),
                        Card(child: ListTile(title: const Text(Group.adminsLabel), subtitle: UsersListView(futureMembers: admins))),
                        Visibility(
                          visible: loggedInUidInArrayOld(group.admins),
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: AddUsersButton(label: 'Add Admin', groupDocumentId: group.documentId, members: group.admins, fieldKey: Group.adminsKey, users: members)),
                        ),
                        //TODO: make magic numbers below into configuragble values
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: GenerateEventButton(group: group, userDocumentId: appState.loginUserDocumentId!, timeSlotDuration: group.meetingDurationTimeSlots, numberOfSlotsToReturn: 3)),
                        ),
                        //TODO: next need to look at this. Suggest times is giving different resutls tan the new event page suggestions
                        Visibility(
                          visible: loggedInUidInArrayOld(group.admins),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5),
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
                                        content: const Text('Are you sure you want to delete this group?'),
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
                                              deleteFirestoreGroup(widget.groupDocumentId);
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

                        ///Left off here: need to add button functionality. Here's sample prompt
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child:
                                  GenerateEventProposalButton(group: group, userDocumentId: appState.loginUserDocumentId!, timeSlotDuration: group.meetingDurationTimeSlots, numberOfSlotsToReturn: 3)),
                        ),
                        Visibility(
                          visible: loggedInUidInArrayOld(group.admins),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              //TODO: style delete button to be red
                              child: ElevatedButton(
                                child: const Text('Propose Event'),
                                onPressed: () {
                                  EventProposal proposal = EventProposal(groupDocumentId: group.documentId, proposalResponses: {}, status: EventProposalStatus.draft, createdTime: Timestamp.now());
                                  context.pushNamed('updateEventProposal', pathParameters: {'eventProposalDocumentId': 'new'}, extra: {'eventProposal': proposal, 'group': group});
                                },
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

//TODO: next up: make add member button that sends an invitation to the user that is stored in their notifications and can accepted to add them to the group

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
                        title: Text(users[index].displayName ?? 'no name'), // Display the user's name
                        onTap: () {
                          if (members.contains(users[index].documentId)) {
                            context.pop();
                            return;
                          }
                          members.add(users[index].documentId);
                          storeUserIdsListInGroup(members, groupDocumentId, fieldKey);
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

class GenerateEventProposalButton extends StatelessWidget {
  final Group group;
  final String userDocumentId;
  final int timeSlotDuration;
  final int numberOfSlotsToReturn;

  const GenerateEventProposalButton({
    required this.group,
    required this.userDocumentId,
    required this.timeSlotDuration,
    required this.numberOfSlotsToReturn,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: const Text('Create Event Proposal'),
      onPressed: () {
        showAddEventProposalDialog(context, group, userDocumentId, timeSlotDuration, numberOfSlotsToReturn);
      },
    );
  }
}

void showAddEventProposalDialog(BuildContext context, Group group, String userDocumentId, int timeSlotDuration, int numberOfSlotsToReturn) {
  ApplicationState appState = Provider.of<ApplicationState>(context, listen: false);
  Map<String, Availability> memberAvailabilities = group.getGroupMemberAvailabilities();
  //TODO: may want to pass in a future DateTime to findTimeSlots to have more accurrate availability calcuations based on the week that it will be planned rather than now
  assert(appState.loginUserTimeZone != null, 'loginUserTimeZone should be populated when the app is initialized but it is null');
  Map<int, int> timeSlotsAndScores = findTimeSlotsFiltered(memberAvailabilities, timeSlotDuration, numberOfSlotsToReturn, appState.loginUserTimeZone!);
  List<int> timeSlots = timeSlotsAndScores.keys.toList();
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Create Suggested Or Blank?\n\nSuggested Times:'),
        content: SizedBox(
            height: 200,
            width: 300,
            child: SuggestedTimesListView(
              timeSlots: timeSlots,
              timeSlotsAndScores: timeSlotsAndScores,
              group: group,
              userDocumentId: userDocumentId,
              linkToEvent: false,
            )),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              context.pop();
            },
          ),
          TextButton(
            child: const Text('Create Blank'),
            onPressed: () {
              context.pop(); //pop first to get out of alert so if you go back you don't go back to alert dialog
              EventProposal proposal = EventProposal(groupDocumentId: group.documentId, proposalResponses: {}, status: EventProposalStatus.draft, createdTime: Timestamp.now());
              context.pushNamed('updateEventProposal', pathParameters: {'eventProposalDocumentId': 'new'}, extra: {'eventProposal': proposal, 'group': group});
            },
          ),
          TextButton(
            child: const Text('Create Suggested'),
            onPressed: () {
              context.pop();
              EventProposal proposal = EventProposal(groupDocumentId: group.documentId, proposalResponses: {}, status: EventProposalStatus.draft, createdTime: Timestamp.now());
              //left off here: need to create an event proposal and add Events for each sugggested time to the propoasl
              //then need to route to the event
              for (int timeslot in timeSlots) {
                DateTime start = getNextDateTimeFromTimeSlotLocal(DateTime.now(), timeslot).toLocal();
                DateTime end = start.add(Duration(minutes: group.meetingDurationMinutes));
                Event event = Event(
                  documentId: null, //this is always used to create a new event so we want the documentId to be null
                  title: '',
                  description: '',
                  location: '',
                  startTime: start,
                  endTime: end,
                  groupDocumentId: group.documentId,
                  status: EventStatus.scheduled,
                  createdTime: DateTime.now(),
                  creatorDocumentId: userDocumentId,
                  attendanceResponses: {},
                );
                //need to save the event
                //need to add to EventProposal
              }
            },
          ),
        ],
      );
    },
  );
}
