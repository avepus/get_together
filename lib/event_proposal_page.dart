import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../classes/event_proposal.dart';
import '../classes/group.dart';
import '../utils.dart';

class EventProposalPage extends StatefulWidget {
  final String? eventProposalDocumentId;
  final EventProposal? eventProposal;

  const EventProposalPage({Key? key, this.eventProposalDocumentId, this.eventProposal}) : super(key: key);

  @override
  _EventProposalPageState createState() => _EventProposalPageState();
}

class _EventProposalPageState extends State<EventProposalPage> {
  late final Future<EventProposal?> _futureEventProposal;
  late Future<Group?> _futureGroup;

  @override
  void initState() {
    super.initState();
    fetchEventProposalAndGroup();
  }

  /// Sets the eventProposal if passed in, otherwise fetches it from Firestore
  /// sets the group to the group associated with the eventProposal
  /// This does both in one function because the group document ID is stored in the eventProposal
  Future<void> fetchEventProposalAndGroup() async {
    EventProposal eventProposal;
    if (widget.eventProposal != null) {
      eventProposal = widget.eventProposal!;
    } else if (widget.eventProposalDocumentId != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection(EventProposal.collectionName).doc(widget.eventProposalDocumentId).get();
      eventProposal = EventProposal.fromDocumentSnapshot(doc);
    } else {
      throw ArgumentError('EventProposal object or eventProposalDocumentId must be provided');
    }

    _futureGroup = fetchGroup(eventProposal.groupDocumentId);
  }

  Future<Group?> fetchGroup(String groupDocumentId) async {
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection(Group.collectionName).doc(groupDocumentId).get();
    return Group.fromDocumentSnapshot(doc);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: EventProposalTitle(eventProposal: _futureEventProposal, group: _futureGroup),
        ),
        body: Container());
  }
}

class EventProposalTitle extends StatelessWidget {
  final Future<EventProposal?> eventProposal;
  final Future<Group?> group;

  const EventProposalTitle({
    super.key,
    required this.eventProposal,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EventProposal?>(
        future: eventProposal,
        builder: (context, inEventSnapshot) {
          if (inEventSnapshot.connectionState == ConnectionState.waiting) {
            return const Text('');
          } else if (inEventSnapshot.hasError) {
            return Text("Error: ${inEventSnapshot.error}");
          } else {
            if (!inEventSnapshot.hasData || inEventSnapshot.data == null) {
              return const Text('No data');
            }
            EventProposal eventProposal = inEventSnapshot.data!;

            return FutureBuilder<Group?>(
                future: group,
                builder: (context, inGroupSnapshot) {
                  if (inGroupSnapshot.connectionState == ConnectionState.waiting) {
                    return const Text('');
                  } else if (inGroupSnapshot.hasError) {
                    return Text("Error: ${inGroupSnapshot.error}");
                  } else {
                    if (!inGroupSnapshot.hasData || inGroupSnapshot.data == null) {
                      return const Text('No data');
                    }
                    Group group = inGroupSnapshot.data!;

                    return Text(makeEventProposalTitle(eventProposal, group));
                  }
                });
          }
        });
  }
}

String makeEventProposalTitle(EventProposal eventProposal, Group group) {
  return group.name ?? '<No Group Name>' + "'s proposal created on " + formatTimestamp(eventProposal.createdTime);
}
