import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_together/classes/app_notification.dart';
import 'package:get_together/firebase.dart';

import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../app_state.dart';
import '../classes/group.dart';
import '../classes/event.dart';
import '../classes/app_user.dart';
import '../utils.dart';
import '../widgets/editable_firestore_field.dart';
import '/widgets/image_with_null_error_handling.dart';

class EventDetailsPage extends StatefulWidget {
  final Event event;

  const EventDetailsPage({Key? key, required this.event}) : super(key: key);

  @override
  _EventDetailsPageState createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  late final Future<Group?> _futureGroup;

  Future<Group?> fetchGroup(String groupDocumentId) async {
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection(Group.collectionName).doc(groupDocumentId).get();
    return Group.fromDocumentSnapshot(doc);
  }

  @override
  void initState() {
    super.initState();
    _futureGroup = fetchGroup(widget.event.groupDocumentId);
  }

  @override
  Widget build(BuildContext context) {
    ApplicationState appState = Provider.of<ApplicationState>(context);
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.event.title ?? '<No Event Name>'),
        ),
        body: FutureBuilder<Group?>(
          future: _futureGroup,
          builder: (context, groupSnapshot) {
            if (groupSnapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (groupSnapshot.hasError) {
              return Text('Error: ${groupSnapshot.error}');
            } else {
              bool eventIsOver = widget.event.endTime.isBefore(DateTime.now());
              Group group = groupSnapshot.data!;
              bool hasEditSecurity = loggedInUidInArray(group.admins, appState) || loggedInUidMatches(widget.event.creatorDocumentId, appState);
              return ListView(
                children: [
                  Visibility(
                    visible: widget.event.isCancelled || eventIsOver,
                    child: Container(
                      width: double.infinity,
                      color: Colors.red,
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        widget.event.isCancelled ? 'Event Cancelled' : 'Event Is Over',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  EditableFirestoreField(
                      collection: Event.collectionName,
                      fieldKey: Event.titleKey,
                      label: Event.titleLabel,
                      //we can assume event document id is not null because we pulled it from firestore
                      documentId: widget.event.documentId!,
                      currentValue: widget.event.title,
                      hasSecurity: false,
                      dataType: String),
                  EditableFirestoreField(
                      collection: Event.collectionName,
                      fieldKey: Event.descriptionKey,
                      label: Event.descriptionLabel,
                      documentId: widget.event.documentId!,
                      currentValue: widget.event.description,
                      hasSecurity: false,
                      dataType: String),
                  EditableFirestoreField(
                      collection: Event.collectionName,
                      fieldKey: Event.locationKey,
                      label: Event.locationLabel,
                      documentId: widget.event.documentId!,
                      currentValue: widget.event.location,
                      hasSecurity: false,
                      dataType: String),
                  EditableFirestoreField(
                      collection: Event.collectionName,
                      fieldKey: Event.endTimeKey,
                      label: 'When',
                      documentId: widget.event.documentId!,
                      currentValue: widget.event.formatMeetingStartAndEnd(),
                      hasSecurity: false,
                      dataType: String),
                  Visibility(
                      visible: hasEditSecurity && !widget.event.isCancelled && !eventIsOver,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton(
                          child: const Text('Edit Event'),
                          onPressed: () {
                            context.pushNamed('updateEvent', extra: {'group': group, 'event': widget.event});
                          },
                        ),
                      )),
                  Visibility(
                      visible: hasEditSecurity && !widget.event.isCancelled && !eventIsOver,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ElevatedButton(
                            child: const Text('Cancel Event'),
                            onPressed: () async {
                              //TODO: warn user to notifiy group members
                              //TODO: future: notify group members via push notification and/or text
                              markEventAsCancelled(widget.event, group);
                              AppNotification notification = AppNotification(
                                title: 'Event Canceled',
                                description: '${group.name}\'s event ${widget.event.title} on ${myFormatDateAndTime(widget.event.startTime)} was canceled.',
                                type: NotificationType.canceledEvent,
                                routeToDocumentId: widget.event.documentId!,
                                createdTime: Timestamp.now(),
                              );
                              for (String memberID in group.members) {
                                await addNotificationToUser(notification, memberID);
                              }
                              context.pushNamed('events');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Event "${widget.event.title}" was canceled'),
                                ),
                              );
                            },
                          ),
                        ),
                      )),
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(Event.attendanceResponsesLabel),
                  ),
                  Container(
                      width: 400,
                      height: 400,
                      child: FutureBuilder<List<AppUser>>(
                          future: group.fetchMemberUsers(),
                          builder: (context, users) {
                            if (users.connectionState == ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            } else if (users.hasError) {
                              return Text('Error: ${users.error}');
                            } else if (users.data == null) {
                              return const Text('No users found');
                            } else {
                              List<AppUser> usersList = users.data!;
                              return ListView.builder(
                                  itemCount: usersList.length,
                                  itemBuilder: (context, index) {
                                    AppUser user = usersList[index];
                                    return ListTile(
                                      leading: ImageWithNullAndErrorHandling(imageUrl: user.imageUrl),
                                      title: Text(user.displayName ?? '<No Name>'),
                                      subtitle: Text(widget.event.attendanceResponses[user.documentId]?.displayText ?? AttendanceResponse.unconfirmedMaybe.displayText),
                                    );
                                  });
                            }
                          })),
                ],
              );
            }
          },
        ));
  }
}
