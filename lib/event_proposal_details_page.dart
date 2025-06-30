import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../classes/event_proposal.dart';
import '../classes/group.dart';
import '../classes/event.dart';
import '../app_state.dart';

class EventProposalDetailsPage extends StatefulWidget {
  final Group group;
  final EventProposal eventProposal;

  const EventProposalDetailsPage({
    Key? key,
    required this.group,
    required this.eventProposal,
  }) : super(key: key);

  @override
  State<EventProposalDetailsPage> createState() => _EventProposalDetailsPageState();
}

class _EventProposalDetailsPageState extends State<EventProposalDetailsPage> {
  List<Event> _events = [];
  late String _userId;
  Map<String, int> _userScores = {};

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<ApplicationState>(context, listen: false);
    _userId = appState.loginUserDocumentId!;
    _userScores = Map<String, int>.from(
      widget.eventProposal.proposalResponses[_userId] ?? {},
    );
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    List<String> eventIds = widget.eventProposal.getAllEventDocumentIds;
    var docs = await Future.wait(eventIds.map((id) => FirebaseFirestore.instance.collection(Event.collectionName).doc(id).get()));
    List<Event> events = docs.map((doc) => Event.fromDocumentSnapshot(doc)).toList();

    // Sort events by user score, highest to lowest
    events.sort((a, b) {
      int scoreA = _userScores[a.documentId] ?? 0;
      int scoreB = _userScores[b.documentId] ?? 0;
      return scoreB.compareTo(scoreA);
    });

    setState(() {
      _events = events;
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final event = _events.removeAt(oldIndex);
      _events.insert(newIndex, event);

      // Assign new scores: highest score to first event, etc.
      int score = _events.length;
      for (var e in _events) {
        _userScores[e.documentId!] = score--;
      }
      widget.eventProposal.proposalResponses[_userId] = Map<String, int>.from(_userScores);
    });
  }

  Future<void> _saveRanking() async {
    await widget.eventProposal.saveToFirestore();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rank Events for ${widget.group.name}'),
      ),
      body: _events.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                  child: Text(
                    'Drag and drop to reorder from best (top) to worst (bottom).',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: ReorderableListView(
                    buildDefaultDragHandles: false, // Add this line
                    onReorder: _onReorder,
                    children: [
                      for (final event in _events)
                        ReorderableDragStartListener(
                          key: ValueKey(event.documentId),
                          index: _events.indexOf(event),
                          child: ListTile(
                            title: Text(event.location.isNotEmpty ? '${event.title} at ${event.location}' : event.title),
                            subtitle: Text(event.description),
                            trailing: Text(DateFormat.MMMd().add_jm().format(event.startTime)),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save Ranking'),
                    onPressed: _saveRanking,
                  ),
                ),
              ],
            ),
    );
  }
}
