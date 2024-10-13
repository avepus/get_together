import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../classes/event_proposal.dart';
import '../classes/group.dart';
import '../utils.dart';

class EventProposalPage extends StatefulWidget {
  final EventProposal eventProposal;
  final Group group;
  const EventProposalPage({Key? key, required this.eventProposal, required this.group}) : super(key: key);

  @override
  _EventProposalPageState createState() => _EventProposalPageState();
}

class _EventProposalPageState extends State<EventProposalPage> {
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
