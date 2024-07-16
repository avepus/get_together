import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_together/classes/app_notification.dart';

import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../app_state.dart';
import '../classes/group.dart';
import '../classes/event.dart';
import '../classes/app_user.dart';
import '../utils.dart';
import '../widgets/editable_firestore_field.dart';

class EventDetailsPage extends StatefulWidget {
  final Event? event;
  final String? eventDocumentId;

  const EventDetailsPage({Key? key, this.event, this.eventDocumentId}) : super(key: key);

  @override
  _EventDetailsPageState createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  late final Future<Event?> _futureEvent = fetchEvent();
  late final Future<Group?> _futureGroup;

  Future<Event?> fetchEvent() async {
    if (widget.event == null && widget.eventDocumentId != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection(Event.collectionName).doc(widget.eventDocumentId).get();
      return Event.fromDocumentSnapshot(doc);
    } else {
      return widget.event;
    }
  }

  Future<Group?> fetchGroup(String groupDocumentId) async {
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection(Group.collectionName).doc(groupDocumentId).get();
    return Group.fromDocumentSnapshot(doc);
  }

  @override
  void initState() {
    super.initState();
    _futureEvent.then((event) {
      if (event != null && event.groupDocumentId != null) {
        _futureGroup = fetchGroup(event.groupDocumentId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    //TODO: need to handle this more gracefully
    if (widget.event == null && widget.eventDocumentId == null) {
      return const Text('No event provided');
    }
    ApplicationState appState = Provider.of<ApplicationState>(context);
    return Scaffold(
        appBar: AppBar(
          title: EventTitle(event: _futureEvent),
        ),
        body: FutureBuilder<Event?>(
          future: _futureEvent,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              Event event = snapshot.data!;
              return FutureBuilder<Group?>(
                future: _futureGroup,
                builder: (context, groupSnapshot) {
                  if (groupSnapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (groupSnapshot.hasError) {
                    return Text('Error: ${groupSnapshot.error}');
                  } else {
                    Group group = groupSnapshot.data!;
                    bool hasSecurity = loggedInUidInArray(group.admins, appState) || loggedInUidMatches(event.creatorDocumentId, appState);
                    return ListView(
                      children: [
                        EditableFirestoreField(
                            collection: Event.collectionName,
                            fieldKey: Event.titleKey,
                            label: Event.titleLabel,
                            //we can assume event document id is not null because we pulled it from firestore
                            documentId: event.documentId!,
                            currentValue: event.title,
                            hasSecurity: false,
                            dataType: String),
                        EditableFirestoreField(
                            collection: Event.collectionName,
                            fieldKey: Event.descriptionKey,
                            label: Event.descriptionLabel,
                            documentId: event.documentId!,
                            currentValue: event.description,
                            hasSecurity: false,
                            dataType: String),
                        EditableFirestoreField(
                            collection: Event.collectionName,
                            fieldKey: Event.locationKey,
                            label: Event.locationLabel,
                            documentId: event.documentId!,
                            currentValue: event.location,
                            hasSecurity: false,
                            dataType: String),
                        EditableFirestoreField(
                            collection: Event.collectionName,
                            fieldKey: Event.endTimeKey,
                            label: 'When',
                            documentId: event.documentId!,
                            currentValue: event.formatMeetingStartAndEnd(),
                            hasSecurity: false,
                            dataType: String),
                        Visibility(
                            visible: hasSecurity,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: ElevatedButton(
                                  onPressed: () {
                                    context.pushNamed('updateEvent', extra: {'group': group, 'event': event});
                                  },
                                  child: const Text('Edit Event')),
                            )),
                        Visibility(
                            visible: hasSecurity,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: ElevatedButton(
                                    onPressed: () async {
                                      //TODO: warn user to notifiy group members
                                      //TODO: future: notify group members via push notification and/or text
                                      event.deleteFromFirestore();
                                      AppNotification notification = AppNotification(
                                        title: 'Event Canceled',
                                        description: '${group.name}\'s event ${event.title} on ${myFormatDateAndTime(event.startTime)} was canceled.',
                                        type: NotificationType.canceledEvent,
                                        routeToDocumentId: event.documentId!,
                                        createdTime: Timestamp.now(),
                                      );
                                      for (String memberID in group.members) {
                                        await notification.saveToDocument(documentId: memberID, fieldKey: AppUser.notificationsKey, collection: AppUser.collectionName);
                                      }
                                      context.pushNamed('events');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Event "${event.title}" was canceled'),
                                        ),
                                      );
                                    },
                                    child: const Text('Cancel Event')),
                              ),
                            ))
                      ],
                    );
                  }
                },
              );
            }
          },
        ));
  }
}

class EventTitle extends StatelessWidget {
  final Future<Event?> event;

  const EventTitle({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Event?>(
        future: event,
        builder: (context, inEventSnapshot) {
          if (inEventSnapshot.connectionState == ConnectionState.waiting) {
            return const Text('');
          } else if (inEventSnapshot.hasError) {
            return Text("Error: ${inEventSnapshot.error}");
          } else {
            if (!inEventSnapshot.hasData || inEventSnapshot.data == null) {
              return const Text('No data');
            }
            Event event = inEventSnapshot.data!;
            return Text(event.title ?? '<No Event Name>');
          }
        });
  }
}
