import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_together/app_state.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../classes/event_proposal.dart';
import '../classes/group.dart';
import '../utils.dart';
import '../classes/event.dart';

//this needs special handling when saving to firestore because it may hold a reference to an event that is not in the database yet
//first, every event must be saved to the database
//then, the EventProposal map must be updated with the event document IDs
//then we can save the EventProposal to the database

class EventProposalPage extends StatefulWidget {
  final EventProposal eventProposal;
  final Group group;
  const EventProposalPage({Key? key, required this.eventProposal, required this.group}) : super(key: key);

  @override
  _EventProposalPageState createState() => _EventProposalPageState();
}

class _EventProposalPageState extends State<EventProposalPage> {
  List<Event> _events = []; // List of events for the proposal. This holds the actual Event objects potentially retrieved from the database if this was an existing proposal.
  late Map<String, int> _eventAndScoreMap; // List of events for the proposal
  late EventProposal _eventProposal; // The event proposal being edited or created
  @override
  void initState() {
    super.initState();
    final appState = Provider.of<ApplicationState>(context, listen: false);

    _eventProposal = EventProposal(
        createdTime: widget.eventProposal.createdTime,
        groupDocumentId: widget.eventProposal.groupDocumentId,
        status: widget.eventProposal.status,
        eventAndScoreMap: widget.eventProposal.getEventAndScoreMap,
        documentId: widget.eventProposal.documentId);

    // handle when we're creating a new proposal
    if (_eventProposal.getEventAndScoreMap.isEmpty) {
      // initialize a default event and add to the events list
      addNewBlankEventToPropsal();
    } else {
      // if we have an existing proposal, we need to fetch the events from the database
      populateEventsFromProposal();
    }
  }

  Future<void> populateEventsFromProposal() async {
    var futures = _eventProposal.getEventAndScoreMap.keys.map((eventId) => FirebaseFirestore.instance.collection(Event.collectionName).doc(eventId).get());
    var docs = await Future.wait(futures);
    setState(() {
      _events = docs.map((doc) => Event.fromDocumentSnapshot(doc)).toList();
    });
  }

  //this adds a new default event to the _events list
  //this also adds the new event to the eventAndScoreMap with a default score of 0 mapped to it's location in the _events list. once it's saved in firestore we need to update that id
  addNewBlankEventToPropsal() async {
    final appState = Provider.of<ApplicationState>(context, listen: false);
    Event event = Event(
      documentId: null, // Not saved yet
      title: 'Event ${_events.length + 1}', // Default title
      description: '',
      location: '',
      startTime: DateTime.now(),
      endTime: DateTime.now().add(Duration(hours: 1)),
      groupDocumentId: widget.group.documentId,
      status: EventStatus.proposal,
      createdTime: DateTime.now(),
      creatorDocumentId: appState.loginUserDocumentId!,
      attendanceResponses: {},
    );
    setState(() {
      _events.add(event);
      // add the event to the eventAndScoreMap with a default score of 0
    });
    // Save the new event to Firestore
    await event.saveToFirestore();
    _eventProposal.getEventAndScoreMap[event.documentId!] = 0; // Update the eventAndScoreMap with the new event's document ID
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: EventProposalTitle(eventProposal: widget.eventProposal, group: widget.group),
        ),
        body: ListView(
          children: [
            ..._events.map((event) {
              int index = _events.indexOf(event);
              String title = event.location.isNotEmpty ? '${event.title} at ${event.location}' : event.title;
              return ListTile(
                  title: Text(title),
                  subtitle: Text(event.description),
                  trailing: Text(DateFormat.MMMd().add_jm().format(event.startTime)),
                  onTap: () {
                    context.pushNamed('updateEvent', extra: {'event': _events[index], 'group': widget.group, 'eventProposal': _eventProposal, 'index': index});
                  });
            }).toList(),
            ElevatedButton(
              onPressed: addNewBlankEventToPropsal,
              child: const Text('Add New Event'),
            ),
          ],
        ));
  }
}

class EventProposalTitle extends StatelessWidget {
  final EventProposal eventProposal;
  final Group group;

  const EventProposalTitle({
    super.key,
    required this.eventProposal,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    return Text(makeEventProposalTitle(eventProposal, group));
  }
}

String makeEventProposalTitle(EventProposal eventProposal, Group group) {
  return '${group.name ?? "<No Group Name>"}\'s proposal created on ${formatTimestamp(eventProposal.createdTime)}';
}
