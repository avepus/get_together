import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../classes/event_proposal.dart';
import '../classes/group.dart';

class EventProposalPage extends StatefulWidget {
  final String? eventProposalDocumentId;
  final EventProposal? eventProposal;

  const EventProposalPage({Key? key, this.eventProposalDocumentId, this.eventProposal}) : super(key: key);

  @override
  _EventProposalPageState createState() => _EventProposalPageState();
}

class _EventProposalPageState extends State<EventProposalPage> {
  late final Future<EventProposal?> _futureEventProposal = fetchEventProposal();
  late final Future<Group?> _futureGroup;

  Future<EventProposal?> fetchEventProposal() async {
    if (widget.eventProposal == null && widget.eventProposalDocumentId != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection(EventProposal.collectionName).doc(widget.eventProposalDocumentId).get();
      return EventProposal.fromDocumentSnapshot(doc);
    } else {
      return widget.eventProposal;
    }
  }

  Future<Group?> fetchGroup(String groupDocumentId) async {
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection(Group.collectionName).doc(groupDocumentId).get();
    return Group.fromDocumentSnapshot(doc);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: EventProposalTitle(eventProposal: _futureEvent),
        ),
        body: Container());
  }
}



class EventProposalTitle extends StatelessWidget {
  final Future<EventProposal?> eventProposal;

  const EventProposalTitle({
    super.key,
    required this.eventProposal,
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
            return Text(eventProposal.title ?? '<No Event Name>');
          }
        });
  }
}