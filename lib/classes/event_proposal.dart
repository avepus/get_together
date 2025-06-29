//this represents an event that is being proposed but is not yet scheduled
//this will be used by users to rank timelots to help decide when to have it

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'app_user.dart';
import '../utils.dart';

enum EventProposalStatus { draft, proposed, scheduled, canceled }

class EventProposal {
  static const String collectionName = 'event_proposals';

  static const String documentIdKey = 'documentId';

  ///this is the entirety of the class basically
  ///it holds the eventID mapped to the score
  ///the highest score is what will be scheduled
  static const String groupKey = 'group';
  static const String statusKey = 'status';
  static const String createdTimeKey = 'createdTime';
  static const String proposalResponsesKey = 'proposalResponses';

  static const String documentIdLabel = 'Document ID';
  static const String groupDocumentIdLabel = 'Group Document ID';
  static const String statusLabel = 'Status';
  static const String createdTimeLabel = 'Created Time';
  static const String proposalResponsesLabel = 'Proposal Responses';

  //documentId = null implies that this is not stored in firebase yet
  String? documentId;
  final String groupDocumentId;
  final EventProposalStatus status;
  final Timestamp createdTime;

  //this is map of user IDs to a map of event ID and ranking that the user gave
  final Map<String, Map<String, int>> proposalResponses;

  EventProposal({
    this.documentId,
    required this.proposalResponses,
    required this.groupDocumentId,
    required this.status,
    required this.createdTime,
  });

  Map<String, Map<String, int>> get getProposalResponses => proposalResponses;

  /// Parses a single user's response map (eventId -> score)
  static Map<String, int> parseUserResponses(Map<String, dynamic> rawUserResponses) {
    return rawUserResponses.map(
      (eventId, score) => MapEntry(eventId, score as int),
    );
  }

  /// Parses the full proposalResponses map (userId -> (eventId -> score))
  static Map<String, Map<String, int>> parseProposalResponses(Map<String, dynamic> rawProposalResponses) {
    return rawProposalResponses.map(
      (userId, responses) => MapEntry(
        userId,
        parseUserResponses(responses as Map<String, dynamic>),
      ),
    );
  }

  static EventProposal fromDocumentSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return EventProposal(
      documentId: doc.id,
      proposalResponses: parseProposalResponses(data[proposalResponsesKey]),
      groupDocumentId: data[groupKey],
      status: enumFromIndexNameString(data[statusKey], EventProposalStatus.values),
      createdTime: data[createdTimeKey],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      proposalResponsesKey: proposalResponses,
      groupKey: groupDocumentId,
      statusKey: enumToIndexNameString(status),
      createdTimeKey: createdTime,
    };
  }

  Future<void> saveToFirestore() async {
    if (documentId != null) {
      await FirebaseFirestore.instance.collection(collectionName).doc(documentId).set(toMap());
    } else {
      DocumentReference ref = await FirebaseFirestore.instance.collection(collectionName).add(toMap());
      documentId = ref.id;
    }
  }
}
