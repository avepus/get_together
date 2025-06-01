import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_together/app_state.dart';
import 'package:provider/provider.dart';

import '../classes/event_proposal.dart';
import '../classes/group.dart';
import '../utils.dart';
import '../classes/event.dart';

//this needs special handling when saving to firestore because it may hold a reference to an event that is not in the database yet
//first, every event must be saved
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
  late List<Event> _events; // List of events for the proposal. This holds the actual Event objects potentially retrieved from the database if this was an existing proposal.
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
      _events.add(Event(
        documentId: null, // Not saved yet
        title: '',
        description: '',
        location: '',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(Duration(hours: 1)),
        groupDocumentId: widget.group.documentId,
        createdTime: DateTime.now(),
        creatorDocumentId: appState.loginUserDocumentId!,
        attendanceResponses: {},
      ));

      // also add event to eventAndScoreMap with a default score of 0
      // the id will be a placeholder until the event is saved to the database
      // TODO: better handling here than a hardcoded '0' key
      _eventProposal.getEventAndScoreMap['0'] = 0; // Using the last event's documentId as key
    } else {
      // if we have an existing proposal, we need to fetch the events from the database
      _events = widget.eventProposal.getEventAndScoreMap.keys.map((eventId) {
        return Event.fromDocumentSnapshot(FirebaseFirestore.instance.collection(Event.collectionName).doc(eventId).get() as DocumentSnapshot);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: EventProposalTitle(eventProposal: widget.eventProposal, group: widget.group),
        ),
        body: Container());
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
