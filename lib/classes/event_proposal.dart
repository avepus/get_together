//this represents an event that is being proposed but is not yet scheduled
//this will be used by users to rank timelots to help decide when to have it

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'app_user.dart';

enum EventProposalStatus { draft, proposed, scheduled, canceled }

class EventProposal {
  static const String collectionName = 'event_proposals';

  static const String documentIdKey = 'documentId';

  ///this is the entirty of the class basically
  ///it holds the eventID mapped to the score
  ///the highest score is what will be scheduled
  static const String eventAndScoreMapKey = 'eventAndScoreMap';
  static const String groupKey = 'group';
  static const String statusKey = 'status';

  static const String documentIdLabel = 'Document ID';
  static const String eventAndScoreMapLabel = 'Event and Score Map';
  static const String groupDocumentIdLabel = 'Group Document ID';
  static const String statusLabel = 'Status';

  //documentId = null implies that this is not stored in firebase yet
  String? documentId;
  final Map<String, int> eventAndScoreMap;
  final String groupDocumentId;
  final EventProposalStatus status;

  EventProposal({
    required this.documentId,
    required this.eventAndScoreMap,
    required this.groupDocumentId,
    required this.status,
  });
}
