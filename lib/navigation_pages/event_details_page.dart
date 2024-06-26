import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:get_together/main.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../app_state.dart';
import '../classes/group.dart';
import '../classes/event.dart';
import '../widgets/image_with_null_error_handling.dart';
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
  Future<Event?> fetchEvent() async {
    if (widget.event == null && widget.eventDocumentId != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection(Event.collectionName).doc(widget.eventDocumentId).get();
      return Event.fromDocumentSnapshot(doc);
    } else {
      return widget.event;
    }
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
          title: EventTitle(event: fetchEvent()),
        ),
        body: FutureBuilder<Event?>(
          future: fetchEvent(),
          builder: (context, snapshot) {
            //TODO: check if user is an admin of the group
            bool hasSecurity = true;
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              Event event = snapshot.data!;
              return ListView(
                children: [
                  EditableFirestoreField(
                      collection: Event.collectionName,
                      fieldKey: Event.titleKey,
                      label: Event.titleLabel,
                      documentId: event.documentId,
                      currentValue: event.title,
                      hasSecurity: hasSecurity,
                      dataType: String),
                  EditableFirestoreField(
                      collection: Event.collectionName,
                      fieldKey: Event.descriptionKey,
                      label: Event.descriptionLabel,
                      documentId: event.documentId,
                      currentValue: event.description,
                      hasSecurity: hasSecurity,
                      dataType: String),
                  EditableFirestoreField(
                      collection: Event.collectionName,
                      fieldKey: Event.locationKey,
                      label: Event.locationLabel,
                      documentId: event.documentId,
                      currentValue: event.location,
                      hasSecurity: hasSecurity,
                      dataType: String),

                  Text(myFormatDateTime(dateTime: event.startTime, includeTime: true)),
                  Visibility(
                      visible: hasSecurity,
                      child: ElevatedButton(
                          onPressed: () {
                            //TODO: warn user to notifiy group members
                            //TODO: future: notify group members via push notification and/or text
                            event.deleteFromFirestore();
                            context.pushNamed('events');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Event ${event.title} was canceled'),
                              ),
                            );
                          },
                          child: const Text('Cancel Event')))
                  // Add more details here as needed
                ],
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
