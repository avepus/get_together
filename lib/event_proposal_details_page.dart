import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

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
                  child: widget.eventProposal.status == EventProposalStatus.scheduled || widget.eventProposal.status == EventProposalStatus.canceled
                      ? Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            widget.eventProposal.status == EventProposalStatus.scheduled ? 'This proposal has been scheduled and can no longer be modified.' : 'This proposal has been canceled.',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : Text(
                          'Drag and drop to reorder from best (top) to worst (bottom).',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                ),
                Expanded(
                  child: widget.eventProposal.status == EventProposalStatus.scheduled || widget.eventProposal.status == EventProposalStatus.canceled
                      ? ListView.builder(
                          itemCount: _events.length,
                          itemBuilder: (context, index) {
                            final event = _events[index];
                            return ListTile(
                              title: Text(event.location.isNotEmpty ? '${event.title} at ${event.location}' : event.title),
                              subtitle: Text(event.description),
                              trailing: Text(DateFormat.MMMd().add_jm().format(event.startTime)),
                            );
                          },
                        )
                      : ReorderableListView(
                          buildDefaultDragHandles: false,
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.group.admins.contains(_userId))
                        ElevatedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                          onPressed: (widget.eventProposal.status == EventProposalStatus.scheduled || widget.eventProposal.status == EventProposalStatus.canceled)
                              ? null
                              : () {
                                  context.pushNamed(
                                    'updateEventProposal',
                                    pathParameters: {
                                      'eventProposalDocumentId': widget.eventProposal.documentId!,
                                    },
                                    extra: {
                                      'eventProposal': widget.eventProposal,
                                      'group': widget.group,
                                    },
                                  );
                                },
                        ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: Text(
                          'Save Ranking',
                          style: (widget.eventProposal.status == EventProposalStatus.scheduled || widget.eventProposal.status == EventProposalStatus.canceled)
                              ? const TextStyle(decoration: TextDecoration.lineThrough)
                              : null,
                        ),
                        onPressed: (widget.eventProposal.status == EventProposalStatus.scheduled || widget.eventProposal.status == EventProposalStatus.canceled) ? null : _saveRanking,
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.event_available),
                        label: Text(
                          'Schedule',
                          style: (widget.eventProposal.status == EventProposalStatus.scheduled || widget.eventProposal.status == EventProposalStatus.canceled)
                              ? const TextStyle(decoration: TextDecoration.lineThrough)
                              : null,
                        ),
                        onPressed: (widget.eventProposal.status == EventProposalStatus.scheduled || widget.eventProposal.status == EventProposalStatus.canceled)
                            ? null
                            : () async {
                                // Compute total scores for each event
                                Map<String, int> totalScores = {};
                                widget.eventProposal.proposalResponses.forEach((userId, scores) {
                                  scores.forEach((eventId, score) {
                                    totalScores[eventId] = (totalScores[eventId] ?? 0) + score;
                                  });
                                });

                                // Sort events by total score descending
                                List<Event> sortedEvents = List<Event>.from(_events);
                                sortedEvents.sort((a, b) {
                                  int scoreA = totalScores[a.documentId] ?? 0;
                                  int scoreB = totalScores[b.documentId] ?? 0;
                                  return scoreB.compareTo(scoreA);
                                });

                                // Show dialog
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Schedule Event'),
                                      content: SizedBox(
                                        width: double.maxFinite,
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: sortedEvents.length,
                                          itemBuilder: (context, index) {
                                            final event = sortedEvents[index];
                                            final ranking = totalScores[event.documentId] ?? 0;
                                            return ListTile(
                                              title: Text(event.location.isNotEmpty ? '${event.title} at ${event.location}' : event.title),
                                              subtitle: Text(event.description),
                                              trailing: Text('Score: $ranking'),
                                              onTap: () async {
                                                // Update proposal status
                                                final updatedProposal = EventProposal(
                                                  documentId: widget.eventProposal.documentId,
                                                  proposalResponses: widget.eventProposal.proposalResponses,
                                                  groupDocumentId: widget.eventProposal.groupDocumentId,
                                                  status: EventProposalStatus.scheduled,
                                                  createdTime: widget.eventProposal.createdTime,
                                                );
                                                await updatedProposal.saveToFirestore();

                                                if (context.mounted) {
                                                  context.pop(); // Close dialog
                                                  context.pushNamed('event', pathParameters: {
                                                    'eventDocumentId': event.documentId!,
                                                  }, extra: {
                                                    'event': event
                                                  });
                                                }
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('Cancel'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
